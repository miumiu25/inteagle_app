use rinf::SignalPiece;
use serde::{Deserialize, Serialize};
// 位移记录数据模型
#[derive(Clone, Debug, Serialize, Deserialize, SignalPiece)]
#[serde(rename_all = "camelCase")]
pub struct DisplacementRecordModel {
    pub target_id: String,
    pub ts: i64,
    pub sigma_x: f64,
    pub sigma_y: f64,
    pub x: f64,
    pub y: f64,
    pub r: f64,
    pub filtered: bool,
    pub inserted: bool,
}
