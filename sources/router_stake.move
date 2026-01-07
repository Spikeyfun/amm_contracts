module spike_staking::router_stake {
    use std::string::String;

    public entry fun unwrap<CoinType>(
        _sender: &signer,
        _to: address,
        _amount: u64
    ) {
        abort 0
    }

    public entry fun register_pool_fa(
        _pool_owner: &signer,
        _stake_addr: address,
        _reward_addr: address,
        _reward_amount: u64,          
        _duration: u64
    ) {
        abort 0
    }

    public entry fun register_pool_coin_fa<StakeCoinType>(
        _pool_owner: &signer,
        _reward_addr: address,
        _reward_amount: u64,
        _duration: u64
    ) {
        abort 0
    }

    public entry fun register_pool_fa_coin<RewardCoinType>(
        _pool_owner: &signer,
        _stake_addr: address,
        _reward_amount: u64,
        _duration: u64
    ) {
        abort 0
    }

    public entry fun register_pool_from_coins<StakeCoinType, RewardCoinType>(
        _pool_owner: &signer,
        _reward_amount: u64,
        _duration: u64
    ) {
        abort 0
    }

    public entry fun register_pool_with_collection_fa(
        _pool_owner: &signer,
        _reward_amount: u64,
        _stake_addr: address,
        _reward_addr: address,
        _duration: u64,
        _collection_owner: address,
        _collection_name: String,
        _boost_percent: u128
    ) {
        abort 0
    }

    public entry fun register_pool_with_collection_coin_fa<StakeCoinType>(
        _pool_owner: &signer,
        _reward_amount: u64,
        _reward_addr: address,
        _duration: u64,
        _collection_owner: address,
        _collection_name: String,
        _boost_percent: u128
    ) {
        abort 0
    }

    public entry fun register_pool_with_collection_fa_coin<RewardCoinType>(
        _pool_owner: &signer,
        _reward_amount: u64,
        _stake_addr: address,
        _duration: u64,
        _collection_owner: address,
        _collection_name: String,
        _boost_percent: u128
    ) {
        abort 0
    }

    public entry fun register_pool_with_collection_from_coins<StakeCoinType, RewardCoinType>(
        _pool_owner: &signer,
        _reward_amount: u64,
        _duration: u64,
        _collection_owner: address,
        _collection_name: String,
        _boost_percent: u128
    ) {
        abort 0
    }

    public entry fun stake_fa(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _stake_amount: u64
    ) {
        abort 0
    }

    public entry fun stake_coin_fa<StakeCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _reward_addr: address,
        _stake_amount: u64
    ) {
        abort 0
    }

    public entry fun stake_fa_coin<RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
        _stake_amount: u64
    ) {
        abort 0
    }

    public entry fun stake_from_coins<StakeCoinType, RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _stake_amount: u64
    ) {
        abort 0
    }

    public entry fun stake_and_boost_fa(
        _user: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _stake_amount: u64,
        _collection_owner: address,
        _collection_name: String,
        _token_name: String,
        _property_version: u64,
    ) {
        abort 0
    }

    public entry fun stake_and_boost_coin_fa<StakeCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _reward_addr: address,
        _stake_amount: u64,
        _collection_owner: address,
        _collection_name: String,
        _token_name: String,
        _property_version: u64,
    ) {
        abort 0
    }

    public entry fun stake_and_boost_fa_coin<RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
        _stake_amount: u64,
        _collection_owner: address,
        _collection_name: String,
        _token_name: String,
        _property_version: u64,
    ) {
        abort 0
    }

    public entry fun stake_and_boost_from_coins<StakeCoinType, RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _stake_amount: u64,
        _collection_owner: address,
        _collection_name: String,
        _token_name: String,
        _property_version: u64,
    ) {
        abort 0
    }

    public entry fun unstake_fa(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _unstake_amount: u64
    ) {
        abort 0
    }

    public entry fun unstake_to_coin<StakeCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _reward_addr: address,
        _unstake_amount: u64
    ) {
        abort 0
    }

    public entry fun unstake_and_remove_boost(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _unstake_amount: u64
    ) {
        abort 0
    }

    public entry fun unstake_and_remove_boost_to_coin<StakeCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _reward_addr: address,
        _unstake_amount: u64
    ) {
        abort 0
    }
    
    public entry fun harvest_fa(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address
    ) {
        abort 0
    }

    public entry fun harvest_to_coin<RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
    ) {
        abort 0
    }

    public entry fun deposit_reward_assets(
        _depositor: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _reward_amount: u64
    ) {
        abort 0
    }

    public entry fun deposit_reward_coins<RewardCoinType>(
        _depositor: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_amount: u64
    ) {
        abort 0
    }

    public entry fun boost(
        _user: &signer,
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _collection_owner: address,
        _collection_name: String,
        _token_name: String,
        _property_version: u64,
    ) {
        abort 0
    }

    public entry fun remove_boost(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
    ) {
        abort 0
    }

    public entry fun enable_emergency(
        _admin: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
    ) {
        abort 0
    }

    public entry fun emergency_unstake(
        _user: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
    ) {
        abort 0
    }

    public entry fun emergency_unstake_fa_coin<StakeCoinType>(
        _user: &signer,
        _pool_creator_address: address,
        _reward_addr: address,
    ) {
        abort 0
    }

    public entry fun emergency_unstake_from_coins<StakeCoinType, RewardCoinType>(
        _user: &signer,
        _pool_creator_address: address
    ) {
        abort 0
    }

    public entry fun withdraw_reward_to_treasury(
        _treasury: &signer, 
        _pool_creator_address: address,
        _stake_addr: address,
        _reward_addr: address,
        _amount: u64
    ) {
        abort 0
    }

    #[view]
    public fun get_address_BWSUP(): address {
        abort 0
    }

    #[view]
    public fun get_original_from_address(_fa_address: address): String {
        abort 0
    }
}