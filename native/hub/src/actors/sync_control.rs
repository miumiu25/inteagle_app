use crate::actors::{SyncServiceControl, SyncServiceControlMsgType};
use crate::signals::MyAmazingNumber;
use crate::sync_service::{SyncService, SyncServiceConfig};
use rinf::{debug_print, DartSignal, RustSignal};
use std::time::Duration;
use tokio::time::interval;

struct SyncRunning {
    device_key: String,
    service: SyncService,
}

pub async fn sync_actor() {
    let receiver = SyncServiceControl::get_dart_signal_receiver(); // GENERATED
    let mut sync_running: Option<SyncRunning> = None;

    while let Some(signal_pack) = receiver.recv().await {
        println!("sync_actor: 已收到同步信号");
        let sync_control_data = signal_pack.message;

        let msg_type = sync_control_data.msg_type;
        let dir_path = sync_control_data.database_path;
        let base_api = sync_control_data.base_api;
        let poll_interval = sync_control_data.poll_interval;
        let device_key = format!("{}_{}", dir_path, base_api);

        debug_print!("database_save_path:{:?}", dir_path);
        debug_print!("base_api:{:?}", base_api);

        if let SyncServiceControlMsgType::Stop = msg_type {
            if let Some(sync) = sync_running.take() {
                // Call shutdown method to stop all running tasks
                if let Err(err) = sync.service.shutdown().await {
                    debug_print!("Error shutting down SyncService: {:?}", err);
                }
                debug_print!("Stopped SyncService for device: {}", device_key);
            }
            continue;
        }

        if !std::path::Path::new(&dir_path).exists() {
            debug_print!("db path not exist, creating it");
            match std::fs::create_dir_all(&dir_path) {
                Ok(_) => debug_print!("Created directory successfully"),
                Err(e) => debug_print!("Failed to create directory: {}", e),
            }
        }

        let path = format!("{}/{}", dir_path, "telemetry.db");
        debug_print!("db path: {}", path);

        // Check if we already have a sync service for this device

        if let Some(sync_running_device_key) = sync_running
            .as_ref()
            .map(|sync_services| sync_services.device_key.clone())
        {
            if sync_running_device_key == device_key {
                debug_print!("Using existing SyncService for device: {}", device_key);
                continue;
            } else {
                if let Some(sync) = sync_running.take() {
                    // Call shutdown method to stop all running tasks
                    if let Err(err) = sync.service.shutdown().await {
                        debug_print!("Error shutting down SyncService: {:?}", err);
                    }
                    debug_print!("Stopped SyncService for device: {}", device_key);
                }
            }
        }

        let config = SyncServiceConfig {
            base_url: base_api,
            db_path: path,
            displacement_poll_interval_ms: poll_interval as u64, //1秒钟
            sync_options: Default::default(),
        };

        // Create sync service instance for this device
        match SyncService::new(config).await {
            Ok(app) => {
                debug_print!(
                    "Created new SyncService instance for device: {}",
                    device_key
                );
                sync_running = SyncRunning {
                    device_key,
                    service: app,
                }
                .into();
            }
            Err(e) => {
                debug_print!(
                    "Failed to create SyncService for device {}: {:?}",
                    device_key,
                    e
                );
            }
        };
    }
}

pub async fn stream_amazing_number() {
    let mut current_number: i32 = 1;
    let mut time_interval = interval(Duration::from_secs(1));
    loop {
        time_interval.tick().await;
        MyAmazingNumber { current_number }.send_signal_to_dart(); // GENERATED
        current_number += 1;
    }
}
