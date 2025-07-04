use reqwest::Client;
use libsql::{params, Builder, Connection};
use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fs;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};
use rinf::{debug_print, RustSignal};
use crate::db_mgr::{create_pool, DbConnection, DbPool};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Response<T> {
    code: String,
    msg: String,
    data: Option<T>,
}

// 位移记录数据模型
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Displacement {
    pub target_id: String,
    pub ts: i64,
    pub sigma_x: f32,
    pub sigma_y: f32,
    pub x: f32,
    pub y: f32,
    pub r: f32,
    pub filtered: bool,
    pub inserted: bool,
}

// 同步参数，可从UI设置
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SyncParams {
    pub start_ts: i64,          // 开始时间戳
    pub end_ts: Option<i64>,    // 可选的结束时间戳，None表示使用当前时间
    pub batch_size: usize,      // 每批次同步的记录数量
    pub force_sync: bool,       // 是否强制同步（忽略上次同步时间）
    pub time_window: Option<i64>, // 时间窗口大小（毫秒），用于增量同步
}

impl Default for SyncParams {
    fn default() -> Self {
        // 计算默认的6个月前时间戳
        let six_months_in_ms: i64 = 180 * 24 * 60 * 60 * 1000;
        let current_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as i64;

        let start_ts = current_time - six_months_in_ms;

        Self {
            start_ts,            // 默认从6个月前开始
            end_ts: None,        // 默认到当前时间
            batch_size: 1000,    // 默认批次大小增加到1000
            force_sync: false,   // 默认不强制同步
            time_window: Some(3 * 60 * 60 * 1000), // 默认时间窗口为3小时
        }
    }
}

// 同步配置
#[derive(Clone, Debug)]
struct SyncConfig {
    base_url: String,
    batch_size: usize,
    poll_interval_ms: u64,
    db_path: String,
    max_retries: usize,
    retry_delay_ms: u64,
    max_initial_sync_days: i64,
    time_window_size_ms: i64,
}

// 表示单个同步任务的配置
#[derive(Clone, Debug)]
struct SyncTaskConfig {
    model_name: String,
    api_endpoint: String,
    create_table_sql: String,
    upsert_sql: String,
    poll_interval_ms: u64,
    last_sync_ts: i64,
}

// 同步管理器，管理多个同步任务
struct SyncManager {
    config: SyncConfig,
    db_path: String,
    client: Client,
    sync_tasks: HashMap<String, Arc<Mutex<i64>>>,
    shutdown_signals: HashMap<String, Arc<AtomicBool>>,
    db_pool: DbPool,
}

// 同步任务接口
trait SyncTaskTrait: Send + Sync {
    fn get_model_name(&self) -> &str;
    fn sync_once(&self, params: SyncParams) -> tokio::task::JoinHandle<Result<i64, Box<dyn Error + Send + Sync>>>;
    fn start_task(self: Arc<Self>) -> tokio::task::JoinHandle<()>;
    fn stop_task(&self) -> bool;
}

// 具体的同步任务实现
struct DisplacementSyncTask {
    manager: Arc<SyncManager>,
    config: SyncTaskConfig,
    last_sync_ts: Arc<Mutex<i64>>,
    sync_start_time: i64,
    shutdown_signal: Arc<AtomicBool>,
}

impl SyncManager {


    async fn get_connection(&self) -> Result<DbConnection, Box<dyn Error + Send + Sync>> {
        Ok(self.db_pool.get().await?)
    }

    // 创建新的同步管理器
    async fn new(config: SyncConfig) -> Result<Self, Box<dyn Error + Send + Sync>> {
        // 确保数据库目录存在
        if let Some(parent) = Path::new(&config.db_path).parent() {
            fs::create_dir_all(parent)?;
        }
        let db_pool = create_pool(&config.db_path).await?;

        // 初始化数据库结构
        let con = db_pool.get().await?;
        Self::initialize_sync_state_table(&con).await?;

        // 创建HTTP客户端
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .build()?;

        Ok(Self {
            config: config.clone(),
            db_path: config.db_path.clone(),
            client,
            sync_tasks: HashMap::new(),
            shutdown_signals: HashMap::new(), // 初始化停止信号映射
            db_pool,
        })
    }

    // 停止所有同步任务
    pub fn stop_all_tasks(&self) -> Vec<String> {
        let mut stopped_tasks = Vec::new();

        for (model_name, signal) in &self.shutdown_signals {
            debug_print!("Stopping task: {}", model_name);
            signal.store(true, Ordering::SeqCst);
            stopped_tasks.push(model_name.clone());
            debug_print!("Stop signal sent to task: {}", model_name);
        }

        stopped_tasks
    }

    // 停止特定的同步任务
    pub fn stop_task(&self, model_name: &str) -> bool {
        if let Some(signal) = self.shutdown_signals.get(model_name) {
            signal.store(true, Ordering::SeqCst);
            debug_print!("Stop signal sent to task: {}", model_name);
            true
        } else {
            debug_print!("No task found to stop for model: {}", model_name);
            false
        }
    }

    // 初始化同步状态表
    async fn initialize_sync_state_table(conn: &Connection) -> Result<(), Box<dyn Error + Send + Sync>> {
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_state (
                model_name TEXT PRIMARY KEY,
                last_sync_ts INTEGER NOT NULL
            )",
            (),
        ).await?;

        Ok(())
    }

    // 获取或初始化最后同步的时间戳，限制初始同步范围
    async fn get_or_init_last_sync_ts(&self, model_name: &str) -> Result<i64, Box<dyn Error + Send + Sync>> {
        let conn = self.get_connection().await?;

        let result = conn.query(
            "SELECT last_sync_ts FROM sync_state WHERE model_name = ?1",
            params![model_name],
        ).await;

        match result {
            Ok(mut rows) => {
                if let Some(row) = rows.next().await? {
                    let ts: i64 = row.get::<i64>(0)?;
                    debug_print!("Retrieved last sync timestamp for {}: {}", model_name, ts);
                    Ok(ts)
                } else {
                    // 计算最早允许的同步时间戳
                    let max_initial_ms = self.config.max_initial_sync_days * 24 * 60 * 60 * 1000;
                    let current_time = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_millis() as i64;

                    let start_ts = current_time - max_initial_ms;

                    // 插入初始同步时间戳
                    conn.execute(
                        "INSERT INTO sync_state (model_name, last_sync_ts) VALUES (?1, ?2)",
                        params![model_name, start_ts],
                    ).await?;

                    debug_print!("Initialized first sync timestamp for {} to {} ({} days ago)",
                                model_name, start_ts, self.config.max_initial_sync_days);

                    Ok(start_ts)
                }
            }
            Err(e) => {
                debug_print!("Failed to query last sync timestamp: {}", e);
                // 如果查询失败，返回有限范围的默认值
                let max_initial_ms = self.config.max_initial_sync_days * 24 * 60 * 60 * 1000;
                let current_time = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as i64;

                let default_ts = current_time - max_initial_ms;
                debug_print!("Using default timestamp due to query error: {}", default_ts);
                Ok(default_ts)
            }
        }
    }

    // 更新最后同步的时间戳
    async fn update_last_sync_ts(&self, model_name: &str, ts: i64) -> Result<(), Box<dyn Error + Send + Sync>> {
        debug_print!("Updating last_sync_ts for {} to {}", model_name, ts);
        let conn = self.get_connection().await?;
        // 先检查当前值
        let mut rows = conn.query(
            "SELECT last_sync_ts FROM sync_state WHERE model_name = ?1",
            params![model_name],
        ).await?;

        let mut current_ts = 0;
        let mut current = rows.next().await?;

        if let Some(row) = current {
            current_ts = row.get::<i64>(0)?;
        }

        // 只有当新时间戳大于当前时间戳时才更新
        if ts > current_ts {
            conn.execute(
                "UPDATE sync_state SET last_sync_ts = ?1 WHERE model_name = ?2",
                params![ts, model_name],
            ).await?;
            debug_print!("Successfully updated last_sync_ts for {} from {} to {}", model_name, current_ts, ts);
        } else {
            debug_print!("Skipped timestamp update for {}: new({}) <= current({})", model_name, ts, current_ts);
        }
        Ok(())
    }

    // 获取数据 - 支持用户自定义参数，只使用时间窗口
    async fn fetch_data<T: for<'de> Deserialize<'de> + Send + Sync>(&self,
                                                                    api_endpoint: &str,
                                                                    params: SyncParams) -> Result<Vec<T>, Box<dyn Error + Send + Sync>> {
        // 确定结束时间戳
        let end_ts = params.end_ts.unwrap_or_else(||
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_millis() as i64
        );

        // 构建请求URL，使用时间范围参数
        let url = format!(
            "{}/{}?startTs={}&endTs={}&limit={}",
            self.config.base_url,
            api_endpoint,
            params.start_ts,
            end_ts,
            params.batch_size
        );

        debug_print!("Fetching data from URL: {}", url);

        self.fetch_data_with_retry::<T>(&url).await
    }

    // 带重试的数据获取
    async fn fetch_data_with_retry<T: for<'de> Deserialize<'de>>(&self, url: &str) -> Result<Vec<T>, Box<dyn Error + Send + Sync>> {
        let mut attempts = 0;

        loop {
            attempts += 1;

            match self.client.get(url).send().await {
                Ok(response) => {
                    if response.status().is_success() {
                        let text = response.text().await?;
                        let response = serde_json::from_str::<Response<Vec<T>>>(&text)
                            .map_err(|e| format!("Failed to parse response: {}", e))?;

                        let records = response.data.unwrap_or_else(|| Vec::new());
                        debug_print!("Fetched {} records", records.len());
                        return Ok(records);
                    } else {
                        let status = response.status();
                        debug_print!("HTTP error: {}", status);

                        if !status.is_server_error() || attempts >= self.config.max_retries {
                            return Err(format!("HTTP error: {}", status).into());
                        }
                    }
                },
                Err(e) => {
                    debug_print!("Request error: {}", e);

                    if attempts >= self.config.max_retries {
                        return Err(Box::new(e));
                    }
                }
            }

            debug_print!("Retry attempt {} of {}", attempts, self.config.max_retries);
            sleep(Duration::from_millis(self.config.retry_delay_ms)).await;
        }
    }

    // 创建位移同步任务
    async fn create_displacement_task(&mut self, poll_interval_ms: u64) -> Result<Arc<DisplacementSyncTask>, Box<dyn Error + Send + Sync>> {
        let model_name = "displacement";

        // 初始化表结构
        let conn = self.get_connection().await?;

        conn.execute(
            "CREATE TABLE IF NOT EXISTS displacement (
                target_id TEXT NOT NULL,
                ts INTEGER NOT NULL,
                sigma_x REAL NOT NULL,
                sigma_y REAL NOT NULL,
                x REAL NOT NULL,
                y REAL NOT NULL,
                r REAL NOT NULL,
                filtered INTEGER NOT NULL,
                inserted INTEGER NOT NULL,
                PRIMARY KEY (target_id, ts)
            )",
            (),
        ).await?;

        // 获取或初始化最后同步时间戳，但限制初始同步的时间范围
        let last_sync_ts = self.get_or_init_last_sync_ts(model_name).await?;
        let last_sync_ts_arc = Arc::new(Mutex::new(last_sync_ts));

        let shutdown_signal = Arc::new(AtomicBool::new(false));

        // 保存任务引用
        self.sync_tasks.insert(model_name.to_string(), last_sync_ts_arc.clone());
        self.shutdown_signals.insert(model_name.to_string(), shutdown_signal.clone());

        // 创建任务配置
        let config = SyncTaskConfig {
            model_name: model_name.to_string(),
            api_endpoint: "api/telemetry/displacement".to_string(),
            create_table_sql: "".to_string(), // 已经在上面执行过了
            upsert_sql: "INSERT OR REPLACE INTO displacement (
                target_id, ts, sigma_x, sigma_y, x, y, r, filtered, inserted
            ) VALUES (
                ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9
            )".to_string(),
            poll_interval_ms,
            last_sync_ts,
        };


        // 获取当前时间作为同步开始时间
        let current_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as i64;

        // 创建同步任务
        Ok(Arc::new(DisplacementSyncTask {
            manager: Arc::new(self.clone()),
            config,
            last_sync_ts: last_sync_ts_arc,
            sync_start_time: current_time,
            shutdown_signal,
        }))
    }

    // 添加快照/备份当前同步状态的功能，以便于调试和恢复
    async fn snapshot_sync_state(&self) -> Result<(), Box<dyn Error + Send + Sync>> {
        let db = Builder::new_local(&self.db_path).build().await?;
        let conn = db.connect()?;

        // 创建同步状态快照表（如果不存在）
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_state_snapshots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                model_name TEXT NOT NULL,
                last_sync_ts INTEGER NOT NULL,
                snapshot_time INTEGER NOT NULL
            )",
            (),
        ).await?;

        // 查询当前所有同步状态
        let result = conn.query(
            "SELECT model_name, last_sync_ts FROM sync_state",
            (),
        ).await?;


        let mut rows = result;
        let current_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as i64;

        // 备份每个模型的同步状态
        while let Some(row) = rows.next().await? {
            let model_name: String = row.get(0)?;
            let last_sync_ts: i64 = row.get(1)?;

            conn.execute(
                "INSERT INTO sync_state_snapshots (model_name, last_sync_ts, snapshot_time)
        VALUES (?1, ?2, ?3)",
                params![model_name.clone(), last_sync_ts, current_time],
            ).await?;

            debug_print!("Created snapshot for {}: timestamp {}", model_name, last_sync_ts);
        }

        Ok(())
    }

    // 添加诊断功能，用于排查同步问题
    pub async fn diagnose_sync_issues(&self, model_name: &str) -> Result<HashMap<String, String>, Box<dyn Error + Send + Sync>> {
        let mut diagnostics = HashMap::new();

        // 检查表是否存在
        let conn = self.get_connection().await?;


        let table_check = conn.query(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?1",
            params![model_name],
        ).await?;

        let mut rows = table_check;
        let table_exists = rows.next().await?.is_some();
        diagnostics.insert("table_exists".to_string(), table_exists.to_string());

        // 检查同步状态
        let mut sync_state = conn.query(
            "SELECT last_sync_ts FROM sync_state WHERE model_name = ?1",
            params![model_name],
        ).await?;

        let mut last_sync_ts = 0;
        if let Some(row) = sync_state.next().await? {
            last_sync_ts = row.get::<i64>(0)?;
            diagnostics.insert("sync_state_exists".to_string(), "true".to_string());
        } else {
            diagnostics.insert("sync_state_exists".to_string(), "false".to_string());
        }

        diagnostics.insert("last_sync_ts".to_string(), last_sync_ts.to_string());

        // 如果表存在，检查记录情况
        if table_exists {
            let record_count_query = format!("SELECT COUNT(*) as count FROM {}", model_name);
            let mut count_result = conn.query(&record_count_query, ()).await?;

            if let Some(row) = count_result.next().await? {
                let count: i64 = row.get(0)?;
                diagnostics.insert("record_count".to_string(), count.to_string());
            }

            // 获取最新记录的时间戳
            let latest_ts_query = format!("SELECT MAX(ts) as max_ts FROM {}", model_name);
            let mut latest_result = conn.query(&latest_ts_query, ()).await?;

            if let Some(row) = latest_result.next().await? {
                if let Ok(max_ts) = row.get::<i64>(0) {
                    diagnostics.insert("latest_record_ts".to_string(), max_ts.to_string());

                    // 检查是否有时间戳不一致问题
                    if max_ts > last_sync_ts {
                        diagnostics.insert("timestamp_issue".to_string(),
                                           format!("Latest record timestamp ({}) is greater than last sync timestamp ({})",
                                                   max_ts, last_sync_ts));
                    }
                }
            }
        }

        // 检查快照历史
        let mut snapshots = conn.query(
            "SELECT COUNT(*) as count FROM sync_state_snapshots WHERE model_name = ?1",
            params![model_name],
        ).await?;

        if let Some(row) = snapshots.next().await? {
            let count: i64 = row.get(0)?;
            diagnostics.insert("snapshot_count".to_string(), count.to_string());
        }

        Ok(diagnostics)
    }
}

// 让SyncManager可以被克隆，用于在线程间共享
impl Clone for SyncManager {
    fn clone(&self) -> Self {
        Self {
            config: self.config.clone(),
            db_path: self.db_path.clone(),
            client: self.client.clone(),
            sync_tasks: self.sync_tasks.clone(),
            shutdown_signals: self.shutdown_signals.clone(),
            db_pool: self.db_pool.clone(), // Pool 已经实现了 Clone
        }
    }
}

// 同步进度报告
#[derive(Debug, Clone, Serialize, Deserialize,RustSignal)]
pub struct SyncProgress {
    pub total_time_span_ms: i64,
    pub processed_time_span_ms: i64,
    pub progress_percentage: f64,
    pub total_records_synced: u64,
    pub current_window_start: i64,
    pub current_window_end: i64,
    pub estimated_remaining_time_ms: i64,
}

impl DisplacementSyncTask {
    // 更新同步进度
    fn update_sync_progress(&self, start_ts: i64, current_ts: i64, end_ts: i64, total_records: u64) -> SyncProgress {
        let total_span = end_ts - start_ts;
        let processed_span = current_ts - start_ts;

        let progress = if total_span > 0 {
            (processed_span as f64 / total_span as f64) * 100.0
        } else {
            100.0
        };

        // 估计剩余时间 (基于当前进度和已用时间进行简单估算)
        let elapsed_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as i64 - self.sync_start_time;

        let estimated_total_time = if processed_span > 0 {
            (elapsed_time as f64 / processed_span as f64) * total_span as f64
        } else {
            0.0
        };

        let estimated_remaining = estimated_total_time as i64 - elapsed_time;

        SyncProgress {
            total_time_span_ms: total_span,
            processed_time_span_ms: processed_span,
            progress_percentage: progress,
            total_records_synced: total_records,
            current_window_start: current_ts,
            current_window_end: end_ts,
            estimated_remaining_time_ms: estimated_remaining.max(0),
        }
    }

    async fn sync_with_params(&self, mut params: SyncParams) -> Result<i64, Box<dyn Error + Send + Sync>> {
        // 检查停止信号
        if self.shutdown_signal.load(Ordering::SeqCst) {
            return Err("Task shutdown requested".into());
        }

        // 获取当前同步状态
        let current_ts = {
            if params.force_sync {
                params.start_ts // 如果强制同步，使用指定的开始时间
            } else {
                *self.last_sync_ts.lock().await // 否则使用上次同步时间
            }
        };

        debug_print!("Syncing {} from ts {}", self.config.model_name, current_ts);

        // 确定结束时间
        let end_ts = params.end_ts.unwrap_or_else(||
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_millis() as i64
        );

        // 获取时间窗口，如果没有指定，使用配置中的默认值
        let time_window = params.time_window.unwrap_or(self.manager.config.time_window_size_ms);

        // 计算需要同步的时间范围
        let total_time_span = end_ts - current_ts;

        // 始终使用增量同步模式，即使是小时间跨度
        // 这确保了一致的同步行为，同时允许在必要时处理大时间范围
        debug_print!("Using incremental sync with window size {}ms, total timespan: {}ms",
                time_window, total_time_span);

        // 分批次同步数据
        let mut window_start_ts = current_ts;
        let mut final_max_ts = current_ts;
        let mut total_records = 0;

        // 即使是小范围也至少执行一个窗口同步
        while window_start_ts < end_ts {
            // 检查是否收到停止信号
            if self.shutdown_signal.load(Ordering::SeqCst) {
                debug_print!("Sync interrupted by shutdown signal at window start: {}", window_start_ts);
                break;
            }

            // 计算当前窗口的结束时间
            // 如果剩余时间小于窗口大小，直接使用 end_ts
            let window_end_ts = std::cmp::min(window_start_ts + time_window, end_ts);

            debug_print!("Processing time window: {} to {} ({} hours)",
                    window_start_ts, window_end_ts, (window_end_ts - window_start_ts) / (60 * 60 * 1000));

            // 执行单个时间窗口的同步
            match self.sync_single_window(window_start_ts, window_end_ts, params.batch_size).await {
                Ok((max_ts, records_count)) => {
                    total_records += records_count as u64;

                    // 更新最大时间戳
                    if max_ts > final_max_ts {
                        final_max_ts = max_ts;
                    }

                    // 更新窗口起始时间
                    // 如果窗口中有数据且最大时间戳小于窗口结束时间，从下一毫秒开始
                    // 否则使用窗口结束时间作为下一窗口的起始
                    if records_count > 0 {
                        // 如果有数据，使用获取到的最大时间戳+1作为下一个窗口的起点
                        window_start_ts = max_ts + 1;
                    } else {
                        // 如果没有数据，使用当前窗口的结束时间作为下一个窗口的起点
                        window_start_ts = window_end_ts;
                    }

                    // 更新同步状态，这样即使中断也能从最后同步点继续
                    // 只在窗口有数据或已处理完当前窗口时更新
                    if (records_count > 0 || window_start_ts == window_end_ts) && window_start_ts > current_ts {
                        let mut last_ts = self.last_sync_ts.lock().await;
                        *last_ts = window_start_ts;

                        // 更新数据库中的同步时间戳

                        self.manager.update_last_sync_ts( &self.config.model_name, window_start_ts).await?;

                        debug_print!("Updated sync checkpoint for {}, ts: {}", self.config.model_name, window_start_ts);
                    }

                    if records_count > 0 {
                        // 更新同步进度
                        let progress = self.update_sync_progress(current_ts, window_start_ts, end_ts, total_records);
                        progress.send_signal_to_dart();
                        debug_print!("Sync progress: {:.2}% ({}/{} ms), estimated remaining time: {} ms",
                            progress.progress_percentage, progress.processed_time_span_ms,
                            progress.total_time_span_ms, progress.estimated_remaining_time_ms);
                    }
                },
                Err(e) => {
                    // 如果同步失败，记录错误并继续下一个窗口
                    debug_print!("Error syncing window {}-{}: {}", window_start_ts, window_end_ts, e);

                    // 如果发生网络错误，可以在这里添加重试逻辑或适当延迟
                    sleep(Duration::from_millis(1000)).await;

                    // 移动到下一个窗口，跳过当前失败的窗口
                    window_start_ts = window_end_ts;
                }
            }

            // 再次检查是否需要终止同步
            if self.shutdown_signal.load(Ordering::SeqCst) {
                debug_print!("Sync loop terminated by shutdown signal after window completion");
                break;
            }
        }

        debug_print!("Incremental sync completed for {}, total records: {}, final timestamp: {}",
                self.config.model_name, total_records, final_max_ts);

        // 确保最终时间戳被更新
        if final_max_ts > current_ts {
            let mut last_ts = self.last_sync_ts.lock().await;
            *last_ts = final_max_ts;

            // 确保数据库中的最后同步时间戳也被更新
            self.manager.update_last_sync_ts(&self.config.model_name, final_max_ts).await?;

            debug_print!("Final sync timestamp updated for {}: {}", self.config.model_name, final_max_ts);
        }

        Ok(final_max_ts)
    }
    async fn sync_single_window(&self, start_ts: i64, end_ts: i64, batch_size: usize)
                                -> Result<(i64, usize), Box<dyn Error + Send + Sync>> {
        // 检查停止信号
        if self.shutdown_signal.load(Ordering::SeqCst) {
            return Err("Task shutdown requested".into());
        }

        // 构建同步参数
        let sync_params = SyncParams {
            start_ts,
            end_ts: Some(end_ts),
            batch_size,
            force_sync: false,
            time_window: None,
        };

        // 获取数据
        let records: Vec<Displacement> = self.manager.fetch_data(
            &self.config.api_endpoint,
            sync_params
        ).await?;

        let records_count = records.len();
        debug_print!("Fetched {} records from {} to {}", records_count, start_ts, end_ts);

        if records.is_empty() {
            debug_print!("No records in window {}-{}", start_ts, end_ts);
            // 返回窗口结束时间作为同步时间戳，表示该时间段已同步
            return Ok((end_ts, 0));
        }

        debug_print!("Window {}-{}: Fetched {} records", start_ts, end_ts, records_count);

        // 如果返回的记录数量等于批次大小，说明可能还有更多数据
        if records_count >= batch_size {
            debug_print!("WARNING: Fetched record count ({}) equals batch size, there might be more data in this time window",
                   records_count);
        }

        // 再次检查停止信号，避免在长时间网络请求后继续执行
        if self.shutdown_signal.load(Ordering::SeqCst) {
            return Err("Task shutdown requested after data fetch".into());
        }

        // 找出最大的时间戳，用于增量同步
        let max_record_ts = records.iter()
            .map(|r| r.ts)
            .max()
            .unwrap_or(start_ts);

        // 取最大时间戳和窗口结束时间的较大值
        // 这确保了我们总是向前推进，即使一个窗口内最新记录的时间戳小于窗口结束时间
        let max_ts = std::cmp::max(max_record_ts, end_ts);

        // 获取数据库连接
        let conn =  self.manager.get_connection().await?;

        // 开始事务
        let tx = conn.transaction().await?;

        for record in records {
            tx.execute(
                &self.config.upsert_sql,
                params![
                record.target_id,
                record.ts,
                record.sigma_x,
                record.sigma_y,
                record.x,
                record.y,
                record.r,
                record.filtered as i32,
                record.inserted as i32
            ],
            ).await?;
        }

        // 在提交事务前再次检查停止信号
        if self.shutdown_signal.load(Ordering::SeqCst) {
            return Err("Task shutdown requested before transaction commit".into());
        }

        // 提交事务
        tx.commit().await?;

        Ok((max_ts, records_count))
    }
    // 执行同步 - 使用默认参数
    async fn sync(&self) -> Result<i64, Box<dyn Error + Send + Sync>> {
        // 使用默认参数同步，但时间窗口使用配置中的值
        let params = SyncParams {
            time_window: Some(self.manager.config.time_window_size_ms),
            ..SyncParams::default()
        };

        self.sync_with_params(params).await
    }

    async fn start(&self) {
        debug_print!("Starting sync task for {} with poll interval {} ms",
          self.config.model_name, self.config.poll_interval_ms);

        loop {


            // 每次循环开始时立即检查停止信号
            if self.shutdown_signal.load(Ordering::SeqCst) {
                debug_print!("Received shutdown signal for task: {}", self.config.model_name);
                break;
            }


            // 执行同步操作
            match self.sync().await {
                Ok(max_ts) => {
                    debug_print!("Sync for {} completed successfully, new last_sync_ts: {}",
                          self.config.model_name, max_ts);

                    // 再次检查停止信号
                    if self.shutdown_signal.load(Ordering::SeqCst) {
                        debug_print!("Received shutdown signal after sync for task: {}", self.config.model_name);
                        break;
                    }

                    // 确保更新内存中的时间戳
                    let mut last_ts = self.last_sync_ts.lock().await;
                    if max_ts >= *last_ts {
                        *last_ts = max_ts;

                        // 更新数据库中的时间戳
                        if let Err(e) = self.manager.update_last_sync_ts(&self.config.model_name, max_ts).await {
                            debug_print!("Failed to update sync timestamp in database: {}", e);
                        }
                    }
                },
                Err(e) => debug_print!("Sync error for {}: {}", self.config.model_name, e),
            }
            sleep(Duration::from_millis(self.config.poll_interval_ms)).await;

        }

        debug_print!("Sync task {} stopped", self.config.model_name);
    }
}

impl SyncTaskTrait for DisplacementSyncTask {
    fn get_model_name(&self) -> &str {
        &self.config.model_name
    }

    fn stop_task(&self) -> bool {
        self.shutdown_signal.store(true, Ordering::SeqCst);
        true
    }

    fn sync_once(&self, params: SyncParams) -> tokio::task::JoinHandle<Result<i64, Box<dyn Error + Send + Sync>>> {
        let task_clone = self.clone();
        tokio::spawn(async move {
            // 更新同步开始时间
            let current_time = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as i64;

            let mut task = task_clone.clone();
            task.sync_start_time = current_time;

            task.sync_with_params(params).await
        })
    }

    fn start_task(self: Arc<Self>) -> tokio::task::JoinHandle<()> {
        tokio::spawn(async move {
            self.start().await;
        })
    }
}

// 同步任务需要能被克隆
impl Clone for DisplacementSyncTask {
    fn clone(&self) -> Self {
        Self {
            manager: self.manager.clone(),
            config: self.config.clone(),
            last_sync_ts: self.last_sync_ts.clone(),
            sync_start_time: self.sync_start_time,
            shutdown_signal: self.shutdown_signal.clone(),
        }
    }
}

// 同步状态
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub model_name: String,
    pub last_sync_ts: i64,
    pub records_count: i64,
    pub last_sync_error: Option<String>,
    pub is_syncing: bool,
}

// 同步选项
#[derive(Clone, Debug)]
pub struct SyncOptions {
    pub time_window_size_ms: i64,    // 时间窗口大小，默认3小时
    pub max_batch_size: usize,       // 最大批次大小
    pub max_initial_sync_days: i64,  // 首次同步的最大天数
}

impl Default for SyncOptions {
    fn default() -> Self {
        Self {
            time_window_size_ms: 3 * 60 * 60 * 1000, // 3小时
            max_batch_size: 1000,
            max_initial_sync_days: 180, // 最多同步6个月的数据
        }
    }
}

// 应用程序配置
pub struct SyncServiceConfig {
    pub base_url: String,
    pub db_path: String,
    pub displacement_poll_interval_ms: u64,
    pub sync_options: SyncOptions,
}

// 应用程序入口
pub struct SyncService {
    manager: Arc<SyncManager>,
    tasks: Vec<tokio::task::JoinHandle<()>>,
    sync_controllers: HashMap<String, Arc<dyn SyncTaskTrait>>,
}

impl SyncService {
    // 创建新的应用程序实例
    pub async fn new(config: SyncServiceConfig) -> Result<Self, Box<dyn Error + Send + Sync>> {
        let sync_config = SyncConfig {
            base_url: config.base_url,
            batch_size: config.sync_options.max_batch_size,
            poll_interval_ms: 2000, // 默认值，会被每个任务覆盖
            db_path: config.db_path,
            max_retries: 3,
            retry_delay_ms: 1000,
            max_initial_sync_days: config.sync_options.max_initial_sync_days,
            time_window_size_ms: config.sync_options.time_window_size_ms,
        };

        let mut manager = SyncManager::new(sync_config).await?;
        let manager_arc = Arc::new(manager.clone());
        let mut tasks = Vec::new();
        let mut sync_controllers = HashMap::new();

        // 注册位移记录同步任务
        let displacement_task = manager.create_displacement_task(
            config.displacement_poll_interval_ms
        ).await?;


        // 添加控制器
        sync_controllers.insert(
            displacement_task.get_model_name().to_string(),
            displacement_task.clone() as Arc<dyn SyncTaskTrait>
        );

        // 启动位移记录同步任务
        let handle = displacement_task.start_task();
        tasks.push(handle);

        // 如果需要添加更多任务类型，可以继续添加...

        Ok(Self {
            manager: manager_arc,
            tasks,
            sync_controllers,
        })
    }

    // 等待所有任务完成
    pub async fn wait_for_completion(self) -> Result<(), Box<dyn Error + Send + Sync>> {
        for task in self.tasks {
            task.await?;
        }
        Ok(())
    }

    // 获取同步控制器，用于从Flutter UI调用
    pub fn get_sync_controller(&self, model_name: &str) -> Option<Arc<dyn SyncTaskTrait>> {
        self.sync_controllers.get(model_name).cloned()
    }

    // 获取所有同步控制器
    pub fn get_all_sync_controllers(&self) -> Vec<Arc<dyn SyncTaskTrait>> {
        self.sync_controllers.values().cloned().collect()
    }

    // 获取特定模型的同步状态
    pub async fn get_sync_status(&self, model_name: &str) -> Result<SyncStatus, Box<dyn Error + Send + Sync>> {
        // 获取控制器
        let controller = self.get_sync_controller(model_name)
            .ok_or_else(|| format!("Controller not found for model: {}", model_name))?;

        // 获取最后同步时间
        let last_sync_ts = match self.manager.get_or_init_last_sync_ts(model_name).await {
            Ok(ts) => ts,
            Err(e) => {
                debug_print!("Error getting last sync time: {}", e);
                0
            }
        };

        // 获取记录数量
        let conn = self.manager.get_connection().await?;


        let count_query = format!("SELECT COUNT(*) FROM {}", model_name);
        let result = conn.query(&count_query, ()).await;

        let count = match result {
            Ok(mut rows) => {
                if let Some(row) = rows.next().await? {
                    row.get::<i64>(0)?
                } else {
                    0
                }
            },
            Err(e) => {
                debug_print!("Error counting records: {}", e);
                0
            }
        };

        Ok(SyncStatus {
            model_name: model_name.to_string(),
            last_sync_ts,
            records_count: count,
            last_sync_error: None,
            is_syncing: false,
        })
    }

    // 手动触发同步
    pub async fn sync_now(&self, model_name: &str, params: SyncParams) -> Result<i64, Box<dyn Error + Send + Sync>> {
        // 获取控制器
        let controller = self.get_sync_controller(model_name)
            .ok_or_else(|| format!("Controller not found for model: {}", model_name))?;

        // 执行同步
        let handle = controller.sync_once(params);
        handle.await?
    }

    // 停止特定的同步任务
    pub fn stop_task(&self, model_name: &str) -> bool {
        self.manager.stop_task(model_name)
    }

    // 停止所有任务
    pub fn stop_all_tasks(&self) -> Vec<String> {
        for (_, controller) in &self.sync_controllers {
            controller.stop_task();
        }
        self.manager.stop_all_tasks()
    }

    // 添加一个优雅关闭方法，等待任务完成
    pub async fn shutdown(self) -> Result<(), Box<dyn Error + Send + Sync>> {
        // 停止所有任务
        let stopped_tasks = self.stop_all_tasks();
        debug_print!("Stopping {} tasks during shutdown", stopped_tasks.len());

        // 给任务一点时间完成当前操作
        sleep(Duration::from_millis(500)).await;


        debug_print!("All sync tasks have been shut down");
        Ok(())
    }

    // 创建同步状态快照
    pub async fn create_sync_snapshot(&self) -> Result<(), Box<dyn Error + Send + Sync>> {
        self.manager.snapshot_sync_state().await
    }

    // 诊断同步问题
    pub async fn diagnose_sync(&self, model_name: &str) -> Result<HashMap<String, String>, Box<dyn Error + Send + Sync>> {
        self.manager.diagnose_sync_issues(model_name).await
    }

    // 重置同步状态（用于问题排查）
    pub async fn reset_sync_timestamp(&self, model_name: &str, new_ts: i64) -> Result<(), Box<dyn Error + Send + Sync>> {
        // 先创建快照
        self.create_sync_snapshot().await?;

        let db = Builder::new_local(&self.manager.db_path).build().await?;
        let conn = db.connect()?;

        // 更新时间戳
        conn.execute(
            "UPDATE sync_state SET last_sync_ts = ?1 WHERE model_name = ?2",
            params![new_ts, model_name],
        ).await?;

        // 更新内存中的时间戳
        if let Some(ts_mutex) = self.manager.sync_tasks.get(model_name) {
            let mut ts = ts_mutex.lock().await;
            *ts = new_ts;
        }

        debug_print!("Reset sync timestamp for {} to {}", model_name, new_ts);
        Ok(())
    }

    // 强制同步（从指定时间开始）
    pub async fn force_sync_from(&self, model_name: &str, start_ts: i64) -> Result<i64, Box<dyn Error + Send + Sync>> {
        let params = SyncParams {
            start_ts,
            force_sync: true,
            ..SyncParams::default()
        };

        self.sync_now(model_name, params).await
    }
}
