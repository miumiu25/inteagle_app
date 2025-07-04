use crate::actors::SyncServiceControl;
use crate::signals::MeasurementQueryType;
use crate::sync_service::{SyncService, SyncServiceConfig};
use anyhow::anyhow;
use chrono::{DateTime, Local};
use futures::Stream;
use futures::stream::{self, StreamExt};
use futures_util::{FutureExt, TryStreamExt};
use libsql::{Connection, Error, Row, Transaction, TransactionBehavior, params};
use rinf::{DartSignal, RustSignal, SignalPiece, debug_print};
use rust_xlsxwriter::Workbook;
use serde::{Deserialize, Serialize};
use std::cmp::max;
use std::collections::HashMap;
use std::fs::File;
use std::future;
use std::ops::Deref;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::sync::mpsc::Receiver;
use std::time::{Duration, UNIX_EPOCH};
use tokio::io::AsyncWriteExt;
use tokio::runtime::Handle;
use tokio::sync::oneshot;
use tokio::sync::oneshot::error::TryRecvError;
use tokio::task::JoinHandle;
use tokio::{pin, spawn};

#[derive(Deserialize, Serialize, DartSignal, Debug)]
pub enum ExportCommand {
    Start(ExportRequest),
    Stop,
}

#[derive(Deserialize, Serialize, SignalPiece, Debug)]
pub struct ExportRequest {
    pub format: ExportFormat,
    pub database_path: String,
    pub output_file_path: String,
    pub targets: Vec<String>,
    pub start_ts: Option<i64>,
    pub end_ts: Option<i64>,
}

#[derive(Deserialize, Serialize, SignalPiece, Debug)]
pub enum ExportFormat {
    CSV = 0,
    XLSX = 1,
}

#[derive(Debug, Clone, Serialize, Deserialize, SignalPiece)]
pub enum ExportState {
    Running,
    Stop,
    Finished,
}
#[derive(Debug, Clone, Serialize, Deserialize, RustSignal)]
pub struct ExportProgress {
    pub state: ExportState,
    pub total_rows: i64,
    pub processed_rows: i64,
}

struct ExportService {
    stop_signal_sender: oneshot::Sender<()>,
    handle: JoinHandle<anyhow::Result<()>>,
}

pub async fn export_actor() {
    let receiver = ExportCommand::get_dart_signal_receiver(); // GENERATED
    let mut service: Option<ExportService> = None;

    while let Some(signal_pack) = receiver.recv().await {
        match signal_pack.message {
            ExportCommand::Start(request) => {
                if let Some(service) = service.take() {
                    let _ = service.stop_signal_sender.send(());
                    let _ = service.handle.await;
                }
                let (sender, receiver) = oneshot::channel();
                debug_print!("Export request: {:?}", request);
                service = Some(ExportService {
                    stop_signal_sender: sender,
                    handle: spawn(export_data(request, receiver)),
                });
            }
            ExportCommand::Stop => {
                debug_print!("Export stop request");
                if let Some(service) = service.take() {
                    let _ = service.stop_signal_sender.send(());
                    let _ = service.handle.await;
                }
            }
        }
    }
}

pub async fn export_data(
    request: ExportRequest,
    stop_signal: oneshot::Receiver<()>,
) -> anyhow::Result<()> {
    debug_print!("export_data,database path:{}", &request.database_path);
    let result = match request.format {
        ExportFormat::CSV => export_data_to_csv(request, stop_signal).await,
        ExportFormat::XLSX => export_data_to_xlsx(request, stop_signal).await,
    };
    if let Err(err) = result.as_ref() {
        debug_print!("export_data error:{}", err);
    }
    result
}

async fn export_data_to_csv(
    request: ExportRequest,
    mut stop_signal: oneshot::Receiver<()>,
) -> anyhow::Result<()> {
    let connection =
        libsql::Builder::new_local(PathBuf::from(&request.database_path).join("telemetry.db"))
            .build()
            .await?;
    let conn = connection.connect()?;

    let target_map = get_target_map(&request.database_path).await?;
    let mut output = tokio::fs::File::create(request.output_file_path)
        .await
        .map_err(|e| anyhow!("Could not create output csv file: {}", e))?;

    output
        .write_all(b"target_id,name,ts,sigma_x,sigma_y,x,y,r\n")
        .await?;

    let total_rows = get_displacement_count(
        &conn,
        request.targets.clone(),
        request.start_ts,
        request.end_ts,
    )
    .await?;
    let mut processed_rows = 0;

    let txn = conn
        .transaction_with_behavior(TransactionBehavior::ReadOnly)
        .await?;
    let query_stream =
        query_displacement(&txn, request.targets, request.start_ts, request.end_ts).await?;
    pin!(query_stream);

    let mut buffer = String::new();
    while let Some(row) = query_stream.next().await {
        //tokio::time::sleep(Duration::from_nanos(1)).await;
        tokio::task::yield_now().await;
        // get_value or close
        if stop_signal.try_recv() != Err(TryRecvError::Empty) {
            ExportProgress {
                state: ExportState::Stop,
                total_rows: total_rows as i64,
                processed_rows: processed_rows as i64,
            }
            .send_signal_to_dart();
            return Ok(());
        }
        if buffer.len() > 100 * 1024 {
            output.write_all(buffer.as_bytes()).await?;
            buffer.clear();
        }
        let target_name = target_map.get(&row.target_id).unwrap_or(&row.target_id);
        buffer.push_str(&format!(
            "{},{},{},{},{},{},{},{}\n",
            row.target_id, target_name, row.ts, row.sigma_x, row.sigma_y, row.x, row.y, row.r,
        ));
        processed_rows += 1;
        if processed_rows % max(total_rows / 1000, 1) == 0 {
            debug_print!("发送导出进度");
            ExportProgress {
                state: ExportState::Running,
                total_rows: total_rows as i64,
                processed_rows: processed_rows as i64,
            }
            .send_signal_to_dart();
        }
    }

    output.write_all(buffer.as_bytes()).await?;
    output.flush().await?;
    ExportProgress {
        state: ExportState::Finished,
        total_rows: total_rows as i64,
        processed_rows: processed_rows as i64,
    }
    .send_signal_to_dart();
    Ok(())
}

async fn export_data_to_xlsx(
    request: ExportRequest,
    mut stop_signal: oneshot::Receiver<()>,
) -> anyhow::Result<()> {
    let connection =
        libsql::Builder::new_local(PathBuf::from(&request.database_path).join("telemetry.db"))
            .build()
            .await?;
    let conn = connection.connect()?;
    let target_map = get_target_map(&request.database_path).await?;

    let total_rows = get_displacement_count(
        &conn,
        request.targets.clone(),
        request.start_ts,
        request.end_ts,
    )
    .await?;
    let mut processed_rows = 0;

    let txn = conn
        .transaction_with_behavior(TransactionBehavior::ReadOnly)
        .await?;
    let query_stream =
        query_displacement(&txn, request.targets, request.start_ts, request.end_ts).await?;
    pin!(query_stream);

    let mut workbook = Workbook::new();
    let mut worksheet = workbook.add_worksheet();
    worksheet.write(0, 0, "target_id")?;
    worksheet.write(0, 1, "name")?;
    worksheet.write(0, 2, "ts")?;
    worksheet.write(0, 3, "sigma_x")?;
    worksheet.write(0, 4, "sigma_y")?;
    worksheet.write(0, 5, "x")?;
    worksheet.write(0, 6, "y")?;
    worksheet.write(0, 7, "r")?;
    let mut workbook_row_count = 1;
    while let Some(row) = query_stream.next().await {
        // get_value or close
        if stop_signal.try_recv() != Err(TryRecvError::Empty) {
            ExportProgress {
                state: ExportState::Stop,
                total_rows: total_rows as i64,
                processed_rows: processed_rows as i64,
            }
            .send_signal_to_dart();
            return Ok(());
        }
        // 1048576 为表格最大行数
        if workbook_row_count >= 1048576 {
            worksheet = workbook.add_worksheet();
            worksheet.write(0, 0, "target_id")?;
            worksheet.write(0, 1, "name")?;
            worksheet.write(0, 2, "ts")?;
            worksheet.write(0, 3, "sigma_x")?;
            worksheet.write(0, 4, "sigma_y")?;
            worksheet.write(0, 5, "x")?;
            worksheet.write(0, 6, "y")?;
            worksheet.write(0, 7, "r")?;
            workbook_row_count = 1;
        }

        let target_name = target_map.get(&row.target_id).unwrap_or(&row.target_id);
        worksheet.write(workbook_row_count, 0, &row.target_id)?;
        worksheet.write(workbook_row_count, 1, target_name)?;
        worksheet.write(workbook_row_count, 2, row.ts)?;
        worksheet.write(workbook_row_count, 3, row.sigma_x)?;
        worksheet.write(workbook_row_count, 4, row.sigma_y)?;
        worksheet.write(workbook_row_count, 5, row.x)?;
        worksheet.write(workbook_row_count, 6, row.y)?;
        worksheet.write(workbook_row_count, 7, row.r)?;
        workbook_row_count = workbook_row_count + 1;

        processed_rows += 1;
        if processed_rows % max(total_rows / 1000, 1) == 0 {
            ExportProgress {
                state: ExportState::Running,
                total_rows: total_rows as i64,
                processed_rows: processed_rows as i64,
            }
            .send_signal_to_dart();
        }
    }
    workbook
        .save(request.output_file_path)
        .map_err(|e| anyhow!("Could not create output xlsx file: {}", e))?;
    ExportProgress {
        state: ExportState::Finished,
        total_rows: total_rows as i64,
        processed_rows: processed_rows as i64,
    }
    .send_signal_to_dart();
    Ok(())
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DisplacementRow {
    pub target_id: String,
    pub ts: i64,
    pub sigma_x: f64,
    pub sigma_y: f64,
    pub x: f64,
    pub y: f64,
    pub r: f64,
    pub filtered: i64,
    pub inserted: i64,
}

pub async fn get_displacement_count(
    db: &Connection,
    targets: Vec<String>,
    start_ts: Option<i64>,
    end_ts: Option<i64>,
) -> anyhow::Result<u64> {
    let mut query = String::from("SELECT COUNT(*) AS total_rows FROM displacement WHERE 1=1");
    let mut params: Vec<libsql::Value> = Vec::new();

    let mut target_iter = targets.into_iter();
    query.push_str(" AND ( target_id = ?");
    params.push(
        target_iter
            .next()
            .ok_or(anyhow!("targets 不能为空"))?
            .into(),
    );
    for target_id in target_iter {
        query.push_str(" OR target_id = ?");
        params.push(target_id.into());
    }
    query.push_str(" )");

    if let Some(start) = start_ts {
        query.push_str(" AND ts >= ?");
        params.push(start.into());
    }

    if let Some(end) = end_ts {
        query.push_str(" AND ts <= ?");
        params.push(end.into());
    }

    let mut rows = db.query(&query, params).await?;

    let row = rows
        .next()
        .await?
        .ok_or(anyhow!("failed to get the displacement count"))?;
    // sqlite has not unsigned int
    let count = row.get::<i64>(0)?;
    Ok(count as u64)
}

pub async fn query_displacement(
    txn: &Transaction,
    targets: Vec<String>,
    start_ts: Option<i64>,
    end_ts: Option<i64>,
) -> anyhow::Result<impl Stream<Item = DisplacementRow>> {
    let total_rows = get_displacement_count(txn.deref(), targets.clone(), start_ts, end_ts).await?;

    let mut query = String::from("SELECT * FROM displacement WHERE 1=1");
    let mut params: Vec<libsql::Value> = Vec::new();

    let mut target_iter = targets.into_iter();
    query.push_str(" AND ( target_id = ?");
    params.push(
        target_iter
            .next()
            .ok_or(anyhow!("targets 不能为空"))?
            .into(),
    );
    for target_id in target_iter {
        query.push_str(" OR target_id = ?");
        params.push(target_id.into());
    }
    query.push_str(" )");

    if let Some(start) = start_ts {
        query.push_str(" AND ts >= ?");
        params.push(start.into());
    }

    if let Some(end) = end_ts {
        query.push_str(" AND ts <= ?");
        params.push(end.into());
    }

    query.push_str(" ORDER BY ts DESC");

    // todo:fix 小米手机
    // 一次性查询的行数太多有可能会报 SQLite failure: `disk I/O error`
    // 分页查询导出超过13k后也可能会报错
    // 但是以上问题在 AVD 里面没有

    // take_while 写了错误处理 filter_map 就不用写了
    let page_size = 1000;
    let stream = stream::iter((0..(total_rows / page_size) + 1))
        .then(move |page_idx| {
            let mut query = query.clone();
            let mut params = params.clone();
            query.push_str(&format!(" LIMIT {page_size} OFFSET ?"));
            params.push(((page_size * page_idx) as i64).into());
            async move {
                let rows = txn.query(&query, params);
                let row_iter = anyhow::Ok(
                    rows.await?
                        .into_stream()
                        .take_while(|row| {
                            future::ready(match row.as_ref() {
                                Ok(_) => true,
                                Err(err) => {
                                    debug_print!("query_displacement get row error:{}", err);
                                    false
                                }
                            })
                        })
                        .filter_map(|row| future::ready(row.ok()))
                        .map(|row| {
                            anyhow::Ok(DisplacementRow {
                                target_id: row.get(0)?,
                                ts: row.get(1)?,
                                sigma_x: row.get(2)?,
                                sigma_y: row.get(3)?,
                                x: row.get(4)?,
                                y: row.get(5)?,
                                r: row.get(6)?,
                                filtered: row.get(7)?,
                                inserted: row.get(8)?,
                            })
                        })
                        .take_while(|row| {
                            future::ready(match row.as_ref() {
                                Ok(_) => true,
                                Err(err) => {
                                    debug_print!("query_displacement read column error:{}", err);
                                    false
                                }
                            })
                        })
                        .filter_map(|row| future::ready(row.ok())),
                );
                row_iter
            }
        })
        .take_while(|stream| {
            future::ready(match stream.as_ref() {
                Ok(_) => true,
                Err(err) => {
                    debug_print!("query_displacement stream error:{}", err);
                    false
                }
            })
        })
        .filter_map(|stream| future::ready(stream.ok()))
        .flatten();

    Ok(stream)
}

pub type TargetId = String;
pub type TargetName = String;
pub async fn get_target_map(
    database_path: impl AsRef<str>,
) -> anyhow::Result<HashMap<TargetId, TargetName>> {
    let connection =
        libsql::Builder::new_local(PathBuf::from(database_path.as_ref()).join("target.db"))
            .build()
            .await?;
    let db = connection.connect()?;

    let query = String::from("SELECT * FROM target");
    let rows = db.query(&query, Vec::<libsql::Value>::new()).await?;

    Ok(rows
        .into_stream()
        .filter_map(|row| async {
            let row = row.ok()?;
            Some((row.get::<String>(0).ok()?, row.get::<String>(2).ok()?))
        })
        .collect::<HashMap<TargetId, TargetName>>()
        .await)
}
