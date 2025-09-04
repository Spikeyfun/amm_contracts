module spike_staking::router_stake {
    use std::string::String;

    native public entry fun unwrap<CoinType>(
        sender: &signer,
        to: address,
        amount: u64
    );

    native public entry fun register_pool_fa(
        pool_owner: &signer,
        stake_addr: address,
        reward_addr: address,
        reward_amount: u64,          
        duration: u64
    );

    native public entry fun register_pool_coin_fa<StakeCoinType>(
        pool_owner: &signer,
        reward_addr: address,
        reward_amount: u64,
        duration: u64
    );

    native public entry fun register_pool_fa_coin<RewardCoinType>(
        pool_owner: &signer,
        stake_addr: address,
        reward_amount: u64,
        duration: u64
    );

    native public entry fun register_pool_from_coins<StakeCoinType, RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        duration: u64
    );

    native public entry fun register_pool_with_collection_fa(
        pool_owner: &signer,
        reward_amount: u64,
        stake_addr: address,
        reward_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    );

    native public entry fun register_pool_with_collection_coin_fa<StakeCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        reward_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    );

    native public entry fun register_pool_with_collection_fa_coin<RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        stake_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    );

    native public entry fun register_pool_with_collection_from_coins<StakeCoinType, RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    );

    native public entry fun stake_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        stake_amount: u64
    );

    native public entry fun stake_coin_fa<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        stake_amount: u64
    );

    native public entry fun stake_fa_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        stake_amount: u64
    );

    native public entry fun stake_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_amount: u64
    );

    native public entry fun stake_and_boost_fa(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        stake_amount: u64,
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    );

    native public entry fun stake_and_boost_coin_fa<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        stake_amount: u64,
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    );

    native public entry fun stake_and_boost_fa_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        stake_amount: u64,
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    );

    native public entry fun stake_and_boost_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_amount: u64,
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    );

    native public entry fun unstake_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        unstake_amount: u64
    );

    native public entry fun unstake_to_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        unstake_amount: u64
    );

    native public entry fun unstake_and_remove_boost(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        unstake_amount: u64
    );

    native public entry fun unstake_and_remove_boost_to_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        unstake_amount: u64
    );
    
    native public entry fun harvest_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address
    );

    native public entry fun harvest_to_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
    );

    native public entry fun deposit_reward_assets(
        depositor: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        reward_amount: u64
    );

    native public entry fun deposit_reward_coins<RewardCoinType>(
        depositor: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_amount: u64
    );

    native public entry fun boost(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    );

    native public entry fun remove_boost(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    );

    native public entry fun enable_emergency(
        admin: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    );

    native public entry fun emergency_unstake(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    );

    native public entry fun emergency_unstake_fa_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
    );

    native public entry fun emergency_unstake_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address
    );

    native public entry fun withdraw_reward_to_treasury(
        treasury: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        amount: u64
    );

    #[view]
    native public fun get_address_BWSUP(): address;

    #[view]
    native public fun get_original_from_address(fa_address: address): String;

}
