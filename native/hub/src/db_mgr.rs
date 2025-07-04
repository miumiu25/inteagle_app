use async_trait::async_trait;
use libsql::{Builder, Connection};
use mobc::{Manager};
use std::error::Error;
use mobc::{Pool, Connection as MobcConnection};
use std::time::Duration;

// 定义连接管理器
pub struct LibsqlConnectionManager {
    database: libsql::Database,
}

impl LibsqlConnectionManager {

    pub async fn new(db_path: String) -> Result<Self, Box<dyn Error + Send + Sync>> {
        let database = Builder::new_local(&db_path).build().await?;
        Ok(Self { database })
    }

}

#[async_trait]
impl Manager for LibsqlConnectionManager {
    type Connection = Connection;
    type Error = Box<dyn Error + Send + Sync>;

    async fn connect(&self) -> Result<Self::Connection, Self::Error> {
        let conn = self.database.connect()?;
        Ok(conn)
    }

    async fn check(&self, conn: Self::Connection) -> Result<Self::Connection, Self::Error> {
        // 执行一个简单查询来检查连接是否有效
        match conn.query("SELECT 1", ()).await {
            Ok(_) => Ok(conn),
            Err(_) => {
                // 连接不可用，让 mobc 创建新连接
                Err("Connection is not valid".into())
            }
        }
    }
}



// 定义池类型别名以简化代码
pub type DbPool = Pool<LibsqlConnectionManager>;
pub type DbConnection = MobcConnection<LibsqlConnectionManager>;

// 创建连接池
pub async fn create_pool(db_path: &str) -> Result<DbPool, Box<dyn Error + Send + Sync>> {
    let manager = LibsqlConnectionManager::new(db_path.to_string()).await?;

    Ok(Pool::builder()
        .max_open(20)                         // 最大连接数
        .max_idle(10)                         // 最大空闲连接数
        .get_timeout(Some(Duration::from_secs(10))) // 获取连接超时
        .max_lifetime(Some(Duration::from_secs(3600))) // 连接最大生存时间
        .build(manager))
}