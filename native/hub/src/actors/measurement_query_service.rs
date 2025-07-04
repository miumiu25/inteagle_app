use std::collections::HashMap;
use std::sync::{LazyLock};
use futures_util::stream::StreamExt;
use libsql::Builder;
use rinf::{DartSignal, debug_print, RustSignal};
use tokio::sync::Mutex;
use crate::db_mgr::{create_pool, DbConnection, DbPool};
use crate::model::DisplacementRecordModel;
use crate::signals::{DisplacementRecord, MeasurementQuery, MeasurementQueryType};


static DB_POOLS: LazyLock<Mutex<HashMap<String, DbPool>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

pub async fn measurement_query_service() {
    let receiver = MeasurementQuery::get_dart_signal_receiver(); // GENERATED

    while let Some(signal_pack) = receiver.recv().await {
        let signal_pack = signal_pack.message;
        debug_print!("query_params: {:?}", signal_pack);

        let path = format!("{}/{}", signal_pack.database_path, "telemetry.db");
        let records = query_displacement(&path, signal_pack).await.unwrap_or_else(|err| {
            debug_print!("Error querying displacement: {:?}", err);
            vec![]
        });


        let send = DisplacementRecord{
            record: records
        };
        send.send_signal_to_dart();

    }
}


pub async fn get_or_create_pool(db_path: &str) -> Result<DbPool, Box<dyn std::error::Error + Send + Sync>> {
    let mut pools = DB_POOLS.lock().await;

    if let Some(pool) = pools.get(db_path) {
        Ok(pool.clone())
    } else {
        let pool = create_pool(db_path).await?;
        pools.insert(db_path.to_string(), pool.clone());
        Ok(pool)
    }
}

pub async fn query_displacement(db_path: &str, query: MeasurementQuery) -> Result<Vec<DisplacementRecordModel>, Box<dyn std::error::Error + Send + Sync>> {
    let pool = get_or_create_pool(db_path).await?;
    let conn: DbConnection = pool.get().await?;

    // 先检查表是否存在
    let rows = conn.query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='displacement'",
        ()
    ).await?;

    let rows_stream = rows.into_stream();
    tokio::pin!(rows_stream);

    // 表不存在，直接返回空记录集
    if rows_stream.next().await.is_none() {
        debug_print!("table 'displacement' not exist");
        return Ok(Vec::new());
    }

    // 表存在，查询数据
    // 根据查询类型构建 SQL 语句
    let start_ts = query.start_ts;
    let end_ts = query.end_ts;
    let query_type = query.query_type;
    let mut sql = String::from("SELECT target_id,ts,sigma_x,sigma_y,x,y,r,filtered,inserted FROM displacement");
    let mut params = Vec::new();
    let mut has_where = false;

    if let MeasurementQueryType::Displacement { target_id } = query_type {
        if let Some(target_id) = target_id {
            sql.push_str(" WHERE target_id = ?");
            params.push(target_id);
            has_where = true;
        }
    }

    if let Some(start_ts) = start_ts {
        if has_where {
            sql.push_str(" AND ts >= ?");
        } else {
            sql.push_str(" WHERE ts >= ?");
            has_where = true;
        }
        params.push(start_ts.to_string());
    }

    if let Some(end_ts) = end_ts {
        if has_where {
            sql.push_str(" AND ts <= ?");
        } else {
            sql.push_str(" WHERE ts <= ?");
            has_where = true;
        }
        params.push(end_ts.to_string());
    }

    if let Some(limit) = query.limit {
        sql.push_str(" LIMIT ?");
        params.push(limit.to_string());
    }

    debug_print!("sql: {:?}", sql);
    let query_result = conn.query(
        sql.as_str(),
        params
    ).await?;

    let result_stream = query_result.into_stream();
    tokio::pin!(result_stream);

    let mut records = Vec::new();
    while let Some(row_result) = result_stream.next().await {
        let row = row_result?;
        let record = DisplacementRecordModel {
            target_id: row.get::<String>(0)?,
            ts: row.get::<i64>(1)?,
            sigma_x: row.get::<f64>(2)?,
            sigma_y: row.get::<f64>(3)?,
            x: row.get(4)?,
            y: row.get(5)?,
            r: row.get(6)?,
            filtered: row.get(7)?,
            inserted: row.get(8)?,
        };
        records.push(record);
    }

    Ok(records)
}