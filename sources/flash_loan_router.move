module spike_amm::flash_loan_router {
    use supra_framework::coin::{Coin};
    use supra_framework::fungible_asset::{FungibleAsset, Metadata};
    use supra_framework::object::{Object};
    
    use spike_amm::amm_pair;
    use spike_amm::coin_wrapper;
    use spike_amm::amm_controller;

    // --- STRUCTS ---
    
    struct FlashLoanFromPoolAsCoinReceipt<phantom CoinType> {
        pair_receipt: amm_pair::FlashLoanReceipt,
        loan_amount: u64
    }
    
    // ===================================================================
    // 1. "WHALE" SCENARIO: Withdrawal from Wrapper (Staking + AMM Liquidity)
    // Type: Coin Legacy / Native
    // =================================================================

    public fun borrow_from_vault<CoinType>(
        amount: u64
    ): (Coin<CoinType>, coin_wrapper::FlashLoanReceipt<CoinType>) {
        coin_wrapper::flash_loan<CoinType>(amount)
    }

    public fun repay_to_vault<CoinType>(
        payment: Coin<CoinType>,
        receipt: coin_wrapper::FlashLoanReceipt<CoinType>
    ) {
        coin_wrapper::repay_flash_loan(payment, receipt);
    }

    public fun borrow_from_pool_as_coin<CoinType>(
        pair: Object<amm_pair::Pair>,
        amount: u64
    ): (Coin<CoinType>, FlashLoanFromPoolAsCoinReceipt<CoinType>) {
        
        let wrapper_metadata = coin_wrapper::get_wrapper<CoinType>();
        let (loaned_fa, pair_receipt) = amm_pair::flash_loan(pair, wrapper_metadata, amount);
        let native_coin = coin_wrapper::unwrap<CoinType>(loaned_fa);

        let router_receipt = FlashLoanFromPoolAsCoinReceipt {
            pair_receipt,
            loan_amount: amount
        };

        (native_coin, router_receipt)
    }

    public fun repay_to_pool_as_coin<CoinType>(
        payment: Coin<CoinType>,
        receipt: FlashLoanFromPoolAsCoinReceipt<CoinType>,
        pair: Object<amm_pair::Pair>
    ) {
        let FlashLoanFromPoolAsCoinReceipt { pair_receipt, loan_amount: _ } = receipt;
        let fa_payment = coin_wrapper::wrap<CoinType>(payment);
        amm_pair::repay_flash_loan(pair, fa_payment, pair_receipt);
    }

    // ===================================================================
    // 2. "POOL" SCENARIO: Withdrawal from AMM Pool
    // Type: Fungible Asset (FA)
    // =================================================================

    public fun borrow_fa_from_pool(
        pair: Object<amm_pair::Pair>,
        token: Object<Metadata>,
        amount: u64
    ): (FungibleAsset, amm_pair::FlashLoanReceipt) {
        amm_pair::flash_loan(pair, token, amount)
    }

    public fun repay_fa_to_pool(
        pair: Object<amm_pair::Pair>,
        payment: FungibleAsset,
        receipt: amm_pair::FlashLoanReceipt
    ) {
        amm_pair::repay_flash_loan(pair, payment, receipt);
    }

    #[view]
    public fun expected_fee(amount: u64): u64 {
        let bps = amm_controller::get_flash_loan_fee_bps();
        (amount * bps) / 10000
    }

    #[view]
    public fun max_flash_loan_vault<CoinType>(): u64 {
        coin_wrapper::get_balance<CoinType>()
    }

    #[view]
    public fun max_flash_loan_pool(pair: Object<amm_pair::Pair>, token: Object<Metadata>): u64 {
        amm_pair::balance_of(pair, token)
    }
}