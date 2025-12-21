use tracing::info;

pub mod ledger;
pub mod handlers;

pub use ledger::{Block, TransactionData, seal_transaction, verify_chain_integrity, get_user_transaction_history};
pub use handlers::{
    seal_transaction_handler,
    verify_chain_handler,
    user_transaction_history_handler,
    SealTransactionRequest,
    SealTransactionResponse,
};

/// Initialize finance subsystem (USDT payments + ledger).
#[allow(dead_code)]
pub fn init() {
    info!("finance module initialized");
}
