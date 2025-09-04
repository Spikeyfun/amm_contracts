module spike_staking::stake_fa {
    use std::option::{Option};
    use std::string::{String};

    use supra_framework::fungible_asset::{FungibleAsset};
    use aptos_token::token::{Token};


    struct PoolIdentifier has copy, drop, store {
        creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    }

    struct NFTBoostConfig has store {
        boost_percent: u128,
        collection_owner: address,
        collection_name: String,
    }


    // create_boost_config (sin cambios)
    native public fun create_boost_config(
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ): NFTBoostConfig;

    /// Registering pool for specific fungible assets.
    ///     * `owner` - pool creator account, under which the pool will be stored.
    ///     * `stake_metadata_addr` - Metadata address of the asset to be staked (S).
    ///     * `initial_reward_assets` - FungibleAsset of reward tokens (R) to initialize the pool distribution.
    ///     * `duration` - Initial pool life duration based on `initial_reward_assets`.
    ///     * `nft_boost_config` - Optional boost configuration.
    native public fun register_pool(
        caller: &signer,
        stake_addr: address,
        reward_addr: address,     
        initial_reward_amount: u64,         
        duration: u64,                      
        nft_boost_config: Option<NFTBoostConfig>
    );

    native public fun register_dynamic_pool(
        caller: &signer,
        stake_addr: address,
        reward_addr: address,
        nft_boost_config: Option<NFTBoostConfig>,
    );
    
    /// Depositing reward assets to specific pool, updates pool duration.
    ///     * `depositor` - rewards depositor account.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `assets` - FungibleAsset of reward tokens (R) to deposit.
    native public fun deposit_reward_assets(
        depositor: &signer,
        pool_key: PoolIdentifier,
        deposit_amount: u64
    );

    /// Stakes user assets in pool.
    ///     * `user` - account that making a stake.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `assets` - FungibleAsset of stake tokens (S) to be staked.
    native public fun stake(
        user: &signer,
        pool_key: PoolIdentifier,
        stake_amount: u64
    );

    /// Unstakes user assets from pool.
    ///     * `user` - account that owns stake.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `amount` - a number of stake assets (S) to unstake.
    /// Returns FungibleAsset of stake tokens: `FungibleAsset`.
    native public fun unstake(
        user: &signer,
        pool_key: PoolIdentifier,
        amount: u64
    ): FungibleAsset;

    /// Harvests user reward.
    ///     * `user` - stake owner account.
    ///     * `pool_addr` - address under which pool are stored.
    /// Returns FungibleAsset of reward tokens: `FungibleAsset`.
    native public fun harvest(
        user: &signer,
        pool_key: PoolIdentifier
    ): (u64, FungibleAsset);

    /// Boosts user stake with nft.
    native public fun boost(
        user: &signer, 
        pool_key: PoolIdentifier,
        nft: Token
    );

    /// Removes nft boost.
    native public fun remove_boost(
        user: &signer, 
        pool_key: PoolIdentifier
    ): Token;

    /// Finalizes dynamic pool and deposits reward assets to the pool.
    native public fun finalize_dynamic_pool_rewards(
        caller_signer: &signer,
        pool_key: PoolIdentifier,
        total_reward_amount: u64
    );


        /// Enables local "emergency state" for the specific pool at `pool_addr`.
    native public fun enable_emergency(
        admin: &signer, 
        pool_key: PoolIdentifier
    );


    /// Withdraws all the user stake and nft from the pool in "emergency state".
    native public fun emergency_unstake(
        user: &signer, 
        pool_key: PoolIdentifier
    ): (u64, Option<FungibleAsset>, Option<Token>);


    /// Withdraws remaining rewards using treasury account after cooldown or in emergency.
    native public fun withdraw_to_treasury(
        treasury_signer: &signer,
        pool_key: PoolIdentifier,
        amount: u64
    ): FungibleAsset;

    ////////ADMIN FUNCTIONS//////////////
    native public entry fun set_normal_pool_lockup_duration(
        admin_signer: &signer,
        new_duration: u64
    );

    native public entry fun set_treasury_withdraw_grace_period(
        admin_signer: &signer,
        new_period: u64
    );

    native public entry fun set_pool_registration_fee(
        admin_signer: &signer,
        new_fee_amount: u64,
        new_fee_treasury_address: address
    );

    native public entry fun propose_new_admin(
        current_admin_signer: &signer,
        new_candidate_addr: address
    );

    native public entry fun accept_admin_role(
        candidate_signer: &signer
    );

    // --- Getter functions ---
    #[view]
    native public fun get_start_timestamp(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address
    ): u64;

    #[view]
    /// Checks if a specific pool is configured for NFT boosting.
    native public fun is_boostable(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool;

    #[view]
    /// Panics if the pool is not boostable or does not exist.
    native public fun get_boost_config(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): (address, String, u128);

    #[view]
    /// Checks if reward distribution has finished for a specific pool.
    native public fun is_finished(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool;

    #[view]
    /// Gets timestamp when reward distribution will be finished for a specific pool.
    native public fun get_end_timestamp(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u64;

    #[view]
    /// Checks if a pool with the given `PoolIdentifier` exists under the `resource_addr`.
    native public fun pool_exists(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool;

    #[view]
    /// Checks if a stake exists for a user in a specific pool.
    native public fun stake_exists(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool;

    #[view]
    native public fun get_pool_total_stake(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u64;

    #[view]
    native public fun get_pool_total_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u128;

    #[view]
    native public fun get_user_stake_or_zero(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64;

    #[view]
    /// Panics if pool or stake does not exist.
    native public fun is_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool;
    
    #[view]
    /// Panics if pool or stake does not exist.
    native public fun get_user_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u128;

    #[view]
    /// Checks current pending user reward in specific pool.
    native public fun get_pending_user_rewards(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64;

    #[view]
    /// Checks stake unlock time in specific pool.
    native public fun get_unlock_time(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64;

    #[view]
    /// Checks if stake is unlocked.
    native public fun is_unlocked(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool;

    #[view]
    /// Checks whether a specific pool is in an "emergency state" (local or global).
    native public fun is_emergency(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool;

    #[view]
    /// Checks whether a specific pool has its local "emergency state" enabled.
    native public fun is_local_emergency(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool;

    #[view]
    native public fun get_module_resource_address(): address;

    #[view]
    native public fun new_pool_identifier(
        creator_addr: address,
        stake_addr: address,
        reward_addr: address
    ): PoolIdentifier;

    #[view]
    native public fun get_normal_pool_lockup_duration(): u64;

    #[view]
    native public fun get_dynamic_pool_lockup_duration(): u64;

    #[view]
    native public fun get_treasury_withdraw_grace_period(): u64;

    #[view]
    native public fun get_current_admin(): address;

    #[view]
    native public fun get_pending_admin_candidate(): Option<address>;

    #[view]
    native public fun get_pool_registration_fee_config(): (u64, address);

    #[view]
    native public fun get_metadata(address: address): (String, String, u8);

}
