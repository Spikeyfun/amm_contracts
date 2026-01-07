module spike_amm::amm_pair {
  use supra_framework::fungible_asset::{FungibleStore, FungibleAsset, MintRef, BurnRef, TransferRef, Metadata};
  use supra_framework::object::{Object};
  
  struct LPTokenRefs has store {
    burn_ref: BurnRef,
    mint_ref: MintRef,
    transfer_ref: TransferRef,
  }

  /// Hot Potato struct (no abilities), forces repayment of the loan.
  struct FlashLoanReceipt {
    amount_loaned: u64,
    fee: u64,
    token_borrowed: Object<Metadata>
  }

  #[resource_group_member(group = supra_framework::object::ObjectGroup)]
  struct Pair has key {
    token0: Object<FungibleStore>,
    token1: Object<FungibleStore>,
    lp_token_refs: LPTokenRefs,
    block_timestamp_last: u64,
    price_0_cumulative_last: u128,
    price_1_cumulative_last: u128,
    k_last: u128,
    locked: bool,
  }

  public fun flash_loan(
    _pair: Object<Pair>, 
    _token_to_borrow: Object<Metadata>, 
    _amount: u64
  ): (FungibleAsset, FlashLoanReceipt) {
      abort 0
  }

  public fun repay_flash_loan(
    _pair: Object<Pair>, 
    _payment: FungibleAsset, 
    _receipt: FlashLoanReceipt
  ) {
      abort 0
  }

  #[view]
  public fun get_reserves(_pair: Object<Pair>): (u64, u64, u64) {
      abort 0
  }

  #[view]
  public fun get_k_last(_pair: Object<Pair>): u128 {
      abort 0
  }

  #[view]
  public fun get_cumulative_prices(_pair: Object<Pair>): (u128, u128) {
      abort 0
  }

  #[view]
  public fun price_0_cumulative_last(_pair: Object<Pair>): u128 {
      abort 0
  }

  #[view]
  public fun price_1_cumulative_last(_pair: Object<Pair>): u128 {
      abort 0
  }

  #[view]
  public fun balance0(_pair: Object<Pair>): u64 {
      abort 0
  }
  
  #[view]
  public fun balance1(_pair: Object<Pair>): u64 {
      abort 0
  }

  #[view]
  public fun token0(_pair: Object<Pair>): Object<Metadata> {
      abort 0
  }

  #[view]
  public fun token1(_pair: Object<Pair>): Object<Metadata> {
      abort 0
  }

  #[view]
  public fun balance_of(_pair: Object<Pair>, _token: Object<Metadata>): u64 {
      abort 0
  }

  #[view]
  public fun unpack_pair(_pair: Object<Pair>): (Object<Metadata>, Object<Metadata>) {
      abort 0
  }

  #[view]
  public fun lp_token_supply(_pair: Object<Pair>): u128 {
      abort 0
  }

  #[view]
  public fun lp_balance_of(_account: address, _pair: Object<Pair>): u64 {
      abort 0
  }

  #[view]
  public fun liquidity_pool(
    _token0: Object<Metadata>,
    _token1: Object<Metadata>,
  ): Object<Pair> {
      abort 0
  }

  #[view]
  public fun liquidity_pool_address_safe(
    _token0: Object<Metadata>,
    _token1: Object<Metadata>,
  ): (bool, address) {
      abort 0
  }

  #[view]
  public fun liquidity_pool_address(
    _token0: Object<Metadata>,
    _token1: Object<Metadata>
  ): address {
      abort 0
  }
}