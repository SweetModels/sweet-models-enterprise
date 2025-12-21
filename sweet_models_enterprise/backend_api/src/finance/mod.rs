use tracing::info;

pub mod ledger;
pub mod handlers;
pub mod treasury;
pub mod calculate_payout;
pub mod payroll;
pub mod penalties;

pub use ledger::{Block, TransactionData, seal_transaction, verify_chain_integrity, get_user_transaction_history};
pub use handlers::{
    seal_transaction_handler,
    verify_chain_handler,
    user_transaction_history_handler,
    SealTransactionRequest,
    SealTransactionResponse,
    get_admin_rate_handler,
    GetAdminRateResponse,
    update_admin_rate_handler,
    UpdateAdminRateRequest,
    UpdateAdminRateResponse,
};
pub use payroll::{
    pending_payroll_handler,
    mark_paid_handler,
    PendingPayrollResponse,
    MarkPaidRequest,
    MarkPaidResponse,
};
pub use treasury::{
    get_balance,
    create_transaction,
    request_payout,
    get_balance_handler,
    request_withdraw_handler,
    list_withdrawals_handler,
};
pub use penalties::{
    downgrade_user_week,
    create_penalty,
    apply_group_shortfall_penalty,
    apply_dirty_room_penalty,
};
pub use calculate_payout::{
    calculate_payout,
    PayoutInput,
    PayoutResult,
    PaymentMethod,
    SPREAD_COP,
    MODEL_SHARE,
    DEFAULT_TOKEN_USD_VALUE,
};

/// Initialize finance subsystem (USDT payments + ledger).
#[allow(dead_code)]
pub fn init() {
    info!("finance module initialized");
}
