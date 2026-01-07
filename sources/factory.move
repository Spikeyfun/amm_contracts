module spike_amm::amm_factory {
  use supra_framework::fungible_asset::Metadata;
  use supra_framework::object::{Object};

  use spike_amm::amm_pair::{Pair};

  #[view]
  native public fun is_initialized(): bool;

  native public entry fun create_pair(
    sender: &signer,
    tokenA: address,
    tokenB: address,
  );

  #[view]
  native public fun all_pairs_length(): u64;

  #[view]
  native public fun all_pairs(): vector<address>;

  #[view]
  native public fun all_pairs_paginated(start: u64, limit: u64): vector<address>;

  #[view]
  native public fun get_pair(tokenA: address, tokenB: address): address;

  #[view]
  native public fun pair_for(
    token_a: Object<Metadata>,
    token_b: Object<Metadata>,
  ): Object<Pair>;

  #[view]
  native public fun get_reserves(
    token_a: address,
    token_b: address,
  ): (u64, u64);

  #[view]
  native public fun pair_exists(tokenA: Object<Metadata>, tokenB: Object<Metadata>): bool;

  #[view]
  native public fun pair_exists_safe(tokenA: Object<Metadata>, tokenB: Object<Metadata>): bool;

  #[view]
  native public fun pair_exists_for_frontend(pair: address): bool;

  native public entry fun set_swap_fee(account: &signer, swap_fee: u8);

  native public entry fun set_flash_loan_fee(account: &signer, new_fee_bps: u64);

  native public entry fun pause(account: &signer);

  native public entry fun unpause(account: &signer);

  native public entry fun set_admin(account: &signer, admin: address);

  native public entry fun set_fee_to(account: &signer, fee_to: address);

  native public entry fun claim_admin(account: &signer);

  native public entry fun initialize_launchpad_feature(admin: &signer);

  native public entry fun add_launcher_to_whitelist(admin: &signer, creator_to_add: address);

  native public entry fun remove_launcher_from_whitelist(admin: &signer, creator_to_remove: address);

  #[view]
  native public fun is_whitelisted(creator: address): bool;

  #[view]
  native public fun get_creator_for_pair(pair_address: address): address;

}