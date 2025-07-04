use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};
use crate::model::DisplacementRecordModel;

/// To send data from Dart to Rust, use `DartSignal`.
#[derive(Deserialize, DartSignal)]
pub struct SmallText {
    pub text: String,
}

/// To send data from Rust to Dart, use `RustSignal`.
#[derive(Serialize, RustSignal)]
pub struct SmallNumber {
    pub number: i32,
}

/// A signal can be nested inside another signal.
#[derive(Serialize, RustSignal)]
pub struct BigBool {
    pub member: bool,
    pub nested: SmallBool,
}

/// To nest a signal inside other signal, use `SignalPiece`.
#[derive(Serialize, SignalPiece)]
pub struct SmallBool(pub bool);


#[derive(Serialize, RustSignal)]
pub struct MyAmazingNumber {
    pub current_number: i32,
}

#[derive(Deserialize, DartSignal)]
pub struct MyTreasureInput {}

#[derive(Serialize, RustSignal)]
pub struct MyTreasureOutput {
    pub current_value: i32,
}


pub async fn tell_treasure() {
    let mut current_value: i32 = 1;

    let receiver = MyTreasureInput::get_dart_signal_receiver(); // GENERATED
    while let Some(_) = receiver.recv().await {
        MyTreasureOutput { current_value }.send_signal_to_dart(); // GENERATED
        current_value += 1;
    }
}

#[derive(Serialize, RustSignal)]
pub struct DisplacementRecord{
    pub record: Vec<DisplacementRecordModel>
}

#[derive(Deserialize, Serialize, DartSignal, Debug)]
pub struct MeasurementQuery {
    pub database_path: String,
    pub query_type: MeasurementQueryType,
    pub start_ts: Option<i64>,
    pub end_ts: Option<i64>,
    pub limit: Option<i32>,
}

#[derive(Deserialize,Serialize, Debug, SignalPiece)]
pub enum MeasurementQueryType{
    Displacement{
        target_id: Option<String>
    },
    Environment,
}