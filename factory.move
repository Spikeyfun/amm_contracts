module spike_amm::amm_factory {
  use std::vector;
  use std::signer;
  use std::error;

  use aptos_std::smart_vector::{Self, SmartVector};
  use aptos_std::simple_map::{Self, SimpleMap};

  use supra_framework::event;
  use supra_framework::fungible_asset::Metadata;
  use supra_framework::object::{Self, Object};

  use spike_amm::amm_controller;
  use spike_amm::amm_pair::{Self, Pair};

  use razor_libs::sort;

  const ERROR_IDENTICAL_ADDRESSES: u64 = 1;
  const ERROR_PAIR_EXISTS: u64 = 2;

  struct Factory has key {
    all_pairs: SmartVector<address>,
    pair_map: SimpleMap<vector<u8>, address>,
  }

  #[event]
  struct PairCreatedEvent has drop, store {
    pair: address,
    creator: address,
    token0: address,
    token1: address,
  }

  fun init_module(deployer: &signer) {
    move_to(deployer, Factory {
      all_pairs: smart_vector::new(),
      pair_map: simple_map::new(),
    });
  }

  #[view]
  public fun is_initialized(): bool {
    exists<Factory>(@spike_amm)
  }

  public entry fun create_pair(
    sender: &signer,
    tokenA: address,
    tokenB: address,
  ) acquires Factory {
    let token0_object = object::address_to_object<Metadata>(tokenA);
    let token1_object = object::address_to_object<Metadata>(tokenB);
    assert!(tokenA != tokenB, error::invalid_argument(ERROR_IDENTICAL_ADDRESSES));
    let (token0, token1) = sort::sort_two_tokens(token0_object, token1_object);
    assert!(pair_exists(token0, token1) == false, error::invalid_state(ERROR_PAIR_EXISTS));
    let pair = amm_pair::initialize(token0, token1);
    let pair_address = object::object_address(&pair);
    let pair_seed = amm_pair::get_pair_seed(token0, token1);
    let factory = safe_factory_mut();
    smart_vector::push_back(&mut factory.all_pairs, pair_address);
    simple_map::add(&mut factory.pair_map, pair_seed, pair_address);


    let creator = signer::address_of(sender);

    event::emit(PairCreatedEvent {
      pair: pair_address,
      creator: creator,
      token0: object::object_address(&token0),
      token1: object::object_address(&token1),
    })
  }

  #[view]
  public fun all_pairs_length(): u64 acquires Factory {
    smart_vector::length(&safe_factory().all_pairs)
  }

  #[view]
  public fun all_pairs(): vector<address> acquires Factory {
    let all_pairs = &safe_factory().all_pairs;
    let results = vector[];
    let len = smart_vector::length(all_pairs);
    let i = 0;
    while (i < len) {
      vector::push_back(&mut results, *smart_vector::borrow(all_pairs, i));
      i = i + 1;
    };
    results
  }

  #[view]
  public fun all_pairs_paginated(start: u64, limit: u64): vector<address> acquires Factory {
    let factory = safe_factory();
    let all_pairs = &factory.all_pairs;
    let len = smart_vector::length(all_pairs);
    let end = if (start + limit > len) { len } else { start + limit };
        
    let results = vector::empty();
    let i = start;
    while (i < end) {
      vector::push_back(&mut results, *smart_vector::borrow(all_pairs, i));
      i = i + 1;
    };
    results
  }

  #[view]
  public fun get_pair(tokenA: address, tokenB: address): address acquires Factory {
    let token0_object = object::address_to_object<Metadata>(tokenA);
    let token1_object = object::address_to_object<Metadata>(tokenB);
    let (token0, token1) = sort::sort_two_tokens(token0_object, token1_object);
    let pair_seed = amm_pair::get_pair_seed(token0, token1);
    let pair_map = &safe_factory().pair_map;
    if (simple_map::contains_key(pair_map, &pair_seed) == true) {
      return *simple_map::borrow(pair_map, &pair_seed)
    } else {
      return @0x0
    }
  }

  #[view]
  public fun pair_for(
    token_a: Object<Metadata>,
    token_b: Object<Metadata>,
  ): Object<Pair> {
    let (token0, token1) = sort::sort_two_tokens(token_a, token_b);
    amm_pair::liquidity_pool(token0, token1)
  }

  #[view]
  public fun get_reserves(
    token_a: address,
    token_b: address,
  ): (u64, u64) {
    let token_a_metadata = object::address_to_object<Metadata>(token_a);
    let token_b_metadata = object::address_to_object<Metadata>(token_b);
    assert!(token_a != token_b, error::invalid_argument(ERROR_IDENTICAL_ADDRESSES));
    let (token0, token1) = sort::sort_two_tokens(token_a_metadata, token_b_metadata);
    let pair = amm_pair::liquidity_pool(token0, token1);
    let (reserve0, reserve1, _) = amm_pair::get_reserves(pair);
    if (token_a_metadata == token0) {
      (reserve0, reserve1)
    } else {
      (reserve1, reserve0)
    }
  }

  #[view]
  public fun pair_exists(tokenA: Object<Metadata>, tokenB: Object<Metadata>): bool acquires Factory {
    let (token0, token1) = sort::sort_two_tokens(tokenA, tokenB);
    let pair_seed = amm_pair::get_pair_seed(token0, token1);
    let pair_map = &safe_factory().pair_map;
    let pair_exists = simple_map::contains_key(pair_map, &pair_seed);
    return pair_exists
  }

  #[view]
  public fun pair_exists_safe(tokenA: Object<Metadata>, tokenB: Object<Metadata>): bool {
    let (token0, token1) = sort::sort_two_tokens(tokenA, tokenB);
    let (is_exists, _) = amm_pair::liquidity_pool_address_safe(token0, token1);
    is_exists
  }

  #[view]
  public fun pair_exists_for_frontend(pair: address): bool {
    let is_exists = object::object_exists<Pair>(pair);
    is_exists
  }

  public entry fun set_swap_fee(account: &signer, swap_fee: u8) {
    amm_controller::set_swap_fee(account, swap_fee);
  }

  public entry fun pause(account: &signer) {
    amm_controller::pause(account);
  }

  public entry fun unpause(account: &signer) {
    amm_controller::unpause(account);
  }

  public entry fun set_admin(account: &signer, admin: address) {
    amm_controller::set_admin_address(account, admin);
  }

  public entry fun set_fee_to(account: &signer, fee_to: address) {
    amm_controller::set_fee_to(account, fee_to);
  }

  public entry fun claim_admin(account: &signer) {
    amm_controller::claim_admin(account);
  }

  inline fun safe_factory(): &Factory acquires Factory {
    borrow_global<Factory>(@spike_amm)
  }

  inline fun safe_factory_mut(): &mut Factory acquires Factory {
    borrow_global_mut<Factory>(@spike_amm)
  }
}