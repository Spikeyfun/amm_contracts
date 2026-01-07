module spike_amm::amm_oracle {
  use supra_framework::fungible_asset::{Metadata};
  use supra_framework::object::{Object};
  use spike_amm::amm_pair::{Pair};

  public entry fun initialize(_sender: &signer, _anchor_token: Object<Metadata>) {
      abort 0
  }

  #[view]
  public fun is_initialized(): bool {
      abort 0
  }

  public fun update(_tokenA: Object<Metadata>, _tokenB: Object<Metadata>): bool {
      abort 0
  }

  public fun update_block_info(): bool {
      abort 0
  }

  #[view]
  public fun get_quantity_v2(_token: Object<Metadata>, _amount: u64): u128 {
      abort 0
  }

  #[view]
  public fun get_average_price_v2(_token: Object<Metadata>): u128 {
      abort 0
  }

  #[view]
  public fun get_current_price(_token: Object<Metadata>): u128 {
      abort 0
  }

  #[view]
  public fun get_lp_token_value_v2(_lp_token: Object<Pair>, _amount: u64): u128 {
      abort 0
  }

  #[view]
  public fun get_anchor_token(): Object<Metadata> {
      abort 0
  }

  #[view]
  public fun get_average_block_time(): u64 {
      abort 0
  }

  public entry fun add_router_token(_sender: &signer, _token: Object<Metadata>) {
      abort 0
  }

  public entry fun remove_router_token(_sender: &signer, _token: Object<Metadata>) {
      abort 0
  }

  #[view]
  public fun get_router_token_length(): u64 {
      abort 0
  }

  #[view]
  public fun is_router_token(_token: Object<Metadata>): bool {
      abort 0
  }

  #[view]
  public fun get_router_token(_index: u64): Object<Metadata> {
      abort 0
  }

  #[view]
  public fun get_router_token_address(_index: u64): address {
      abort 0
  }
}