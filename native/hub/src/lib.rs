//! This `hub` crate is the
//! entry point of the Rust logic.

mod actors;
mod signals;
mod sync_service;
mod model;
mod db_mgr;
mod export_data;

use std::fmt;
use actors::create_actors;
use rinf::{dart_shutdown, write_interface};
use tokio::spawn;
use crate::signals::tell_treasure;
use actors::sync_control::{stream_amazing_number, sync_actor};
use actors::measurement_query_service::measurement_query_service;
use crate::export_data::export_actor;
// Uncomment below to target the web.
// use tokio_with_wasm::alias as tokio;

write_interface!();

// You can go with any async library, not just `tokio`.
#[tokio::main(flavor = "current_thread")]
async fn main() {

    // Spawn concurrent tasks.
    // Always use non-blocking async functions like `tokio::fs::File::open`.
    // If you must use blocking code, use `tokio::task::spawn_blocking`
    // or the equivalent provided by your async library.
    spawn(create_actors());
    spawn(sync_actor());
    spawn(export_actor());
    spawn(stream_amazing_number());
    spawn(tell_treasure());
    spawn(measurement_query_service());

    // Keep the main function running until Dart shutdown.
    dart_shutdown().await;
}
