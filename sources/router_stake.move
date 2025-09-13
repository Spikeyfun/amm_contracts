/// Collection of entrypoints to handle staking pools using Fungible Assets.
module spike_staking::router_stake {
    use std::option;
    use std::signer;
    use std::string::String;
    use supra_framework::primary_fungible_store;
    use supra_framework::coin::{Self};
    use supra_framework::object::{Self};
    use supra_framework::fungible_asset::{Metadata};
    use supra_framework::supra_coin::SupraCoin;
    use aptos_std::error;
    use aptos_token::token;

    use spike_staking::stake_fa;
    use spike_staking::coin_wrapper;

    const ERR_USE_COIN_FUNCTION_FOR_SUPRA: u64 = 1;

    //wrap coins to FA
    fun wrap_coin<CoinType>(
        sender: &signer,
        to: address,
        amount: u64
    ) {
        let coin = coin::withdraw<CoinType>(sender, amount);
        let fa = coin_wrapper::wrap<CoinType>(coin);

        let fa_metadata_obj = coin_wrapper::get_wrapper<CoinType>();
        if (!primary_fungible_store::primary_store_exists(to, fa_metadata_obj)) {
            primary_fungible_store::create_primary_store(to, fa_metadata_obj);
        };

        primary_fungible_store::deposit(to, fa);
    }
    //uncrap FA to Coins, you need to Specify the Coin
    public entry fun unwrap<CoinType>(
        sender: &signer,
        to: address,
        amount: u64
    ) {
        let supra_object = coin_wrapper::get_wrapper<CoinType>();
        let bwsup = primary_fungible_store::withdraw(sender, supra_object, amount);
        let supra = coin_wrapper::unwrap<CoinType>(bwsup);
        coin::deposit(to, supra);
    }

        /// Register new staking pool for stake asset `stake_metadata_addr` and reward asset `R` without nft boost.
    ///     * `pool_owner` - account which will be used as a pool storage.
    ///     * `stake_metadata_addr` - Metadata address of the asset to be staked.
    ///     * `initial_reward_assets` - Initial reward assets (type R) to fund the pool.
    ///     * `duration` - Initial pool life duration based on `initial_reward_assets`.
    public entry fun register_pool_fa(
        pool_owner: &signer,
        stake_addr: address,
        reward_addr: address,
        reward_amount: u64,          
        duration: u64
    ) {
        stake_fa::register_pool(
            pool_owner,           // Pass the signer
            stake_addr,           // Pass stake metadata address
            reward_addr,          // Pass reward metadata address <<-- NEWLY PASSED
            reward_amount,        // Pass the initial reward amount <<-- NEWLY PASSED
            duration,             // Pass the duration
            option::none()        // Pass None for NFT boost config in this simple version
                                  // (assuming the corrected stake_fa::register_pool now takes Option<NFTBoostConfig>)
        );
    }

    public entry fun register_pool_coin_fa<StakeCoinType>(
        pool_owner: &signer,
        reward_addr: address,
        reward_amount: u64,
        duration: u64
    ) {

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);

        stake_fa::register_pool(
            pool_owner,
            stake_addr,     
            reward_addr,
            reward_amount,
            duration,
            option::none()
        );
    }

    public entry fun register_pool_fa_coin<RewardCoinType>(
        pool_owner: &signer,
        stake_addr: address,
        reward_amount: u64,
        duration: u64
    ) {

        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj); 

        if (reward_amount > 0) {
            let reward_coin = coin::withdraw<RewardCoinType>(pool_owner, reward_amount);
            let reward_fa = coin_wrapper::wrap<RewardCoinType>(reward_coin);

            let owner_addr = signer::address_of(pool_owner);
            if (!primary_fungible_store::primary_store_exists(owner_addr, reward_metadata_obj)) {
                 primary_fungible_store::create_primary_store(owner_addr, reward_metadata_obj);
            };
            primary_fungible_store::deposit(owner_addr, reward_fa);
        };
        
        stake_fa::register_pool(
            pool_owner,
            stake_addr,     
            reward_addr,
            reward_amount,
            duration,
            option::none()
        );
    }

    public entry fun register_pool_from_coins<StakeCoinType, RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        duration: u64
    ) {

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();

        let stake_addr = object::object_address(&stake_metadata_obj);
        let reward_addr = object::object_address(&reward_metadata_obj); 

        if (reward_amount > 0) {
            let reward_coin = coin::withdraw<RewardCoinType>(pool_owner, reward_amount);
            let reward_fa = coin_wrapper::wrap<RewardCoinType>(reward_coin);

            let owner_addr = signer::address_of(pool_owner);
            if (!primary_fungible_store::primary_store_exists(owner_addr, reward_metadata_obj)) {
                 primary_fungible_store::create_primary_store(owner_addr, reward_metadata_obj);
            };
            primary_fungible_store::deposit(owner_addr, reward_fa);
        };
        
        stake_fa::register_pool(
            pool_owner,
            stake_addr,     
            reward_addr,
            reward_amount,
            duration,
            option::none()
        );
    }


    /// Register new staking pool for stake asset `stake_metadata_addr` and reward asset `R` with nft boost.
    ///     * `pool_owner` - account which will be used as a pool storage.
    ///     * `stake_metadata_addr` - Metadata address of the asset to be staked.
    ///     * `initial_reward_assets` - Initial reward assets (type R) to fund the pool.
    ///     * `duration` - Initial pool life duration based on `initial_reward_assets`.
    ///     * `collection_owner` - address of nft collection creator.
    ///     * `collection_name` - nft collection name.
    ///     * `boost_percent` - percentage of increasing user stake "power" after nft stake.
    public entry fun register_pool_with_collection_fa(
        pool_owner: &signer,
        reward_amount: u64,
        stake_addr: address,
        reward_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ) {
        // Pass the FungibleAsset directly.
        let boost_config = stake_fa::create_boost_config(collection_owner, collection_name, boost_percent);
        stake_fa::register_pool(
            pool_owner,
            stake_addr,
            reward_addr,
            reward_amount,
            duration,
            option::some(boost_config)
        );
    }

    public entry fun register_pool_with_collection_coin_fa<StakeCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        reward_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ) {
        // Pass the FungibleAsset directly.
        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);
        let boost_config = stake_fa::create_boost_config(collection_owner, collection_name, boost_percent);
        stake_fa::register_pool(
            pool_owner,
            stake_addr,
            reward_addr,
            reward_amount,
            duration,
            option::some(boost_config)
        );
    }

    public entry fun register_pool_with_collection_fa_coin<RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        stake_addr: address,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ) {
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj); 

        if (reward_amount > 0) {
            let reward_coin = coin::withdraw<RewardCoinType>(pool_owner, reward_amount);
            let reward_fa = coin_wrapper::wrap<RewardCoinType>(reward_coin);

            let owner_addr = signer::address_of(pool_owner);
            if (!primary_fungible_store::primary_store_exists(owner_addr, reward_metadata_obj)) {
                 primary_fungible_store::create_primary_store(owner_addr, reward_metadata_obj);
            };
            primary_fungible_store::deposit(owner_addr, reward_fa);
        };
        // Pass the FungibleAsset directly.
        let boost_config = stake_fa::create_boost_config(collection_owner, collection_name, boost_percent);
        stake_fa::register_pool(
            pool_owner,
            stake_addr,
            reward_addr,
            reward_amount,
            duration,
            option::some(boost_config)
        );
    }

    public entry fun register_pool_with_collection_from_coins<StakeCoinType, RewardCoinType>(
        pool_owner: &signer,
        reward_amount: u64,
        duration: u64,
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ) {
        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();

        let stake_addr = object::object_address(&stake_metadata_obj);
        let reward_addr = object::object_address(&reward_metadata_obj); 

        if (reward_amount > 0) {
            let reward_coin = coin::withdraw<RewardCoinType>(pool_owner, reward_amount);
            let reward_fa = coin_wrapper::wrap<RewardCoinType>(reward_coin);

            let owner_addr = signer::address_of(pool_owner);
            if (!primary_fungible_store::primary_store_exists(owner_addr, reward_metadata_obj)) {
                 primary_fungible_store::create_primary_store(owner_addr, reward_metadata_obj);
            };
            primary_fungible_store::deposit(owner_addr, reward_fa);
        };
        // Pass the FungibleAsset directly.
        let boost_config = stake_fa::create_boost_config(collection_owner, collection_name, boost_percent);
        stake_fa::register_pool(
            pool_owner,
            stake_addr,
            reward_addr,
            reward_amount,
            duration,
            option::some(boost_config)
        );
    }

    /// Stake `assets_to_stake` (type S) to the pool at `pool_key`.
    ///     * `user` - stake owner.
    ///     * `pool_key` - address of the pool to stake into.
    ///     * `assets_to_stake` - FungibleAsset containing the stake tokens (S).
    public entry fun stake_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        stake_amount: u64
        ) {
        // Pass the FungibleAsset directly.
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);
    }

    public entry fun stake_coin_fa<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        stake_amount: u64
    ) {
        let user_addr = signer::address_of(user);
        // 1. Withdraw original Coin from user
        let stake_coin = coin::withdraw<StakeCoinType>(user, stake_amount);

        // 2. Wrap Coin into internal FungibleAsset
        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_fa_wrapped = coin_wrapper::wrap<StakeCoinType>(stake_coin);

        // 3. Get the metadata object and address for the wrapped FA
        let stake_addr = object::object_address(&stake_metadata_obj);

        if (!primary_fungible_store::primary_store_exists(user_addr, stake_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, stake_metadata_obj);
        };

        primary_fungible_store::deposit(user_addr, stake_fa_wrapped);

        let reward_metadata_obj = object::address_to_object<Metadata>(reward_addr);
        if (!primary_fungible_store::primary_store_exists(user_addr, reward_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, reward_metadata_obj);
        };
        // 5. Call the original stake logic which expects the user to have the FA
        //It will internally withdraw the FA from the user's store using stake_addr and stake_amount
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr ,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);
    }

    public entry fun stake_fa_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        stake_amount: u64
    ) {

        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);
        let user_addr = signer::address_of(user);

        if (!primary_fungible_store::primary_store_exists(user_addr, reward_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, reward_metadata_obj);
        };

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);
    }

    public entry fun stake_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_amount: u64
    ) {

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);
        let user_addr = signer::address_of(user);

        if (stake_amount > 0) {
            let stake_coin = coin::withdraw<StakeCoinType>(user, stake_amount);
            let stake_fa = coin_wrapper::wrap<StakeCoinType>(stake_coin);

            if (!primary_fungible_store::primary_store_exists(user_addr, stake_metadata_obj)) {
                 primary_fungible_store::create_primary_store(user_addr, stake_metadata_obj);
            };
            primary_fungible_store::deposit(user_addr, stake_fa);
        };

        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);

        if (!primary_fungible_store::primary_store_exists(user_addr, reward_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, reward_metadata_obj);
        };

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);
    }

    /// Stake `assets_to_stake` (type S) to the pool at `pool_key` and boost with an NFT.
    ///     * `user` - stake owner.
    ///     * `pool_key` - address of the pool to stake into.
    ///     * `assets_to_stake` - FungibleAsset containing the stake tokens (S).
    ///     * `collection_owner` - address of nft collection creator.
    ///     * `collection_name` - nft collection name.
    ///     * `token_name` - token name.
    ///     * `property_version` - token property version.
    public entry fun stake_and_boost_fa(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        stake_amount: u64,
        // NFT parameters
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);

        // Withdraw and boost with the NFT
        let token_id = token::create_token_id_raw(collection_owner, collection_name, token_name, property_version);
        let nft = token::withdraw_token(user, token_id, 1); // Assume amount is 1
        stake_fa::boost(user, pool_key, nft);
    }

    /// Stake coins of type StakeCoinType and boost with an NFT in one transaction.
    public entry fun stake_and_boost_coin_fa<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        stake_amount: u64,
        // NFT parameters
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) {

        stake_coin_fa<StakeCoinType>(
            user,
            pool_creator_address,
            reward_addr,
            stake_amount
        );

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let token_id = token::create_token_id_raw(collection_owner, collection_name, token_name, property_version);

        let nft = token::withdraw_token(user, token_id, 1); // Assume amount is 1
        stake_fa::boost(user, pool_key, nft);
    }

    /// Stake FA, RewardCoinType and boost with an NFT in one transaction.
    public entry fun stake_and_boost_fa_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        stake_amount: u64,
        // NFT parameters
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) {

        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);

        let user_addr = signer::address_of(user);
        if (!primary_fungible_store::primary_store_exists(user_addr, reward_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, reward_metadata_obj);
        };

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::stake(user, pool_key, stake_amount);

        let token_id = token::create_token_id_raw(collection_owner, collection_name, token_name, property_version);

        let nft = token::withdraw_token(user, token_id, 1); // Assume amount is 1
        stake_fa::boost(user, pool_key, nft);
    }

    /// Stake coins of type StakeCoinType and boost with an NFT in one transaction.
    public entry fun stake_and_boost_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_amount: u64,
        // NFT parameters
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) {

        stake_from_coins<StakeCoinType, RewardCoinType>(
            user,
            pool_creator_address,
            stake_amount
        );

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let token_id = token::create_token_id_raw(collection_owner, collection_name, token_name, property_version);

        let nft = token::withdraw_token(user, token_id, 1); // Assume amount is 1
        stake_fa::boost(user, pool_key, nft);
    }

    /// Unstake an `amount` of stake assets (type S) from the pool at `pool_key`.
    ///     * `user` - stake owner.
    ///     * `pool_key` - address of the pool to unstake from.
    ///     * `unstake_amount` - amount of stake assets (S) to unstake.
    public entry fun unstake_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        unstake_amount: u64
    ) {
        let bwsup = get_address_BWSUP();
        assert!(stake_addr != bwsup, error::invalid_argument(ERR_USE_COIN_FUNCTION_FOR_SUPRA));
        assert!(reward_addr != bwsup, error::invalid_argument(ERR_USE_COIN_FUNCTION_FOR_SUPRA));

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        let user_addr = signer::address_of(user);
        let unstaked_fa = stake_fa::unstake(user, pool_key, unstake_amount);
        let stake_fa_metadata_obj = object::address_to_object<Metadata>(stake_addr);

        if (!primary_fungible_store::primary_store_exists(user_addr, stake_fa_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, stake_fa_metadata_obj);
        };
        primary_fungible_store::deposit(user_addr, unstaked_fa);
    }

    /// Unstake assets and receive them as original Coin<StakeCoinType>.
    /// Caller MUST provide the correct StakeCoinType.
    public entry fun unstake_to_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        unstake_amount: u64
    ) {
        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let user_addr = signer::address_of(user);

        // 2. Unwrap the FungibleAsset back into the original Coin
        let unstaked_fa = stake_fa::unstake(user, pool_key, unstake_amount);
        let unstaked_coin = coin_wrapper::unwrap<StakeCoinType>(unstaked_fa);
        coin::deposit(user_addr, unstaked_coin);
    }    

    /// Unstake an `amount` of stake assets (type S) from the pool at `pool_key` and remove boost.
    ///     * `user` - stake owner.
    ///     * `pool_key` - address of the pool to unstake from.
    ///     * `unstake_amount` - amount of stake assets (S) to unstake.
    public entry fun unstake_and_remove_boost(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        unstake_amount: u64
    ) {
        let bwsup = get_address_BWSUP();
        assert!(stake_addr != bwsup, error::invalid_argument(ERR_USE_COIN_FUNCTION_FOR_SUPRA));
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        let user_addr = signer::address_of(user);
        let unstaked_fa = stake_fa::unstake(user, pool_key, unstake_amount); // Recibe FA
        let stake_fa_metadata_obj = object::address_to_object<Metadata>(stake_addr);

        if (!primary_fungible_store::primary_store_exists(user_addr, stake_fa_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, stake_fa_metadata_obj);
        };
        // Unstake assets        
        primary_fungible_store::deposit(user_addr, unstaked_fa);
        
        let nft = stake_fa::remove_boost(user, pool_key);
        token::deposit_token(user, nft);
    }

    /// Unstake assets, remove NFT boost, and receive assets as original Coin<StakeCoinType>.
    /// Caller MUST provide the correct StakeCoinType.
    public entry fun unstake_and_remove_boost_to_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
        unstake_amount: u64
    ) {
        let bwsup = get_address_BWSUP();
        assert!(reward_addr != bwsup, error::invalid_argument(ERR_USE_COIN_FUNCTION_FOR_SUPRA));
        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        // --- Remove Boost Part (same as original) ---
        let nft = stake_fa::remove_boost(user, pool_key);
        token::deposit_token(user, nft);

        unstake_to_coin<StakeCoinType>(
            user,
            pool_creator_address,
            reward_addr,
            unstake_amount
        );
    }
    
    /// Collect `user` rewards (type R) from the pool at `pool_key`.
    ///     * `user` - owner of the stake used to receive the rewards.
    ///     * `pool_key` - address of the pool.
    public entry fun harvest_fa(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address
    ) {
        let bwsup = get_address_BWSUP();
        assert!(reward_addr != bwsup, error::invalid_argument(ERR_USE_COIN_FUNCTION_FOR_SUPRA));
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        let user_addr = signer::address_of(user);
        let (_, reward_fa) = stake_fa::harvest(user, pool_key);
        let reward_fa_metadata_obj = object::address_to_object<Metadata>(reward_addr);
        if (!primary_fungible_store::primary_store_exists(user_addr, reward_fa_metadata_obj)) {
            primary_fungible_store::create_primary_store(user_addr, reward_fa_metadata_obj);
        };
        primary_fungible_store::deposit(user_addr, reward_fa);
    }

    /// Harvest rewards and receive them as original Coin<RewardCoinType>.
    /// Caller MUST provide the correct RewardCoinType.
    public entry fun harvest_to_coin<RewardCoinType>(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
    ) {
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        let user_addr = signer::address_of(user);
        // 1. Call original harvest logic to get the wrapped reward FungibleAsset
        let (_earned_amount, reward_fa) = stake_fa::harvest(user, pool_key); 

        // 2. Unwrap the FungibleAsset back into the original Coin
        let reward_coin = coin_wrapper::unwrap<RewardCoinType>(reward_fa);

        // 3. Deposit the original Coin into the user's account
        coin::deposit(user_addr, reward_coin);
    }

    /// Deposit more reward assets (type R) to the pool.
    ///     * `depositor` - account providing the reward assets.
    ///     * `pool_key` - address of the pool.
    ///     * `reward_assets` - FungibleAsset containing the reward tokens (R) to deposit.
    public entry fun deposit_reward_assets(
        depositor: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        reward_amount: u64
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        // Pass the FungibleAsset directly.
        stake_fa::deposit_reward_assets(depositor, pool_key, reward_amount);
    }

    /// Deposit reward coins of type RewardCoinType directly to the pool.
    public entry fun deposit_reward_coins<RewardCoinType>(
        depositor: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_amount: u64
    ) {
        // 1. Withdraw original Coin from depositor
        let reward_coin = coin::withdraw<RewardCoinType>(depositor, reward_amount);

        // 2. Wrap Coin into internal FungibleAsset
        let reward_fa = coin_wrapper::wrap<RewardCoinType>(reward_coin);

        // 3. Get the metadata object and address for the wrapped FA
        let reward_metadata_obj = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj);

        // 4. Deposit the wrapped FA into the depositor's primary store (needed for the next step)
        let depositor_addr = signer::address_of(depositor);
        if (!primary_fungible_store::primary_store_exists(depositor_addr, reward_metadata_obj)) {
            primary_fungible_store::create_primary_store(depositor_addr, reward_metadata_obj);
        };

        primary_fungible_store::deposit(depositor_addr, reward_fa);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        // 5. Call the original deposit logic. It likely withdraws the FA from the depositor.
        stake_fa::deposit_reward_assets(depositor, pool_key, reward_amount);
    }

    /// Boosts user stake with nft. (Entry point wrapper)
    ///     * `user` - stake owner account.
    ///     * `pool_key` - address under which pool are stored.
    ///     * `collection_owner` - address of nft collection creator.
    ///     * `collection_name` - nft collection name.
    ///     * `token_name` - token name.
    ///     * `property_version` - token property version.
    public entry fun boost(
        user: &signer,
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        //NFT details
        collection_owner: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) {
        // Logic to withdraw NFT remains the same
        let token_id = token::create_token_id_raw(collection_owner, collection_name, token_name, property_version);
        let nft = token::withdraw_token(user, token_id, 1);
        // Call the migrated boost function
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        stake_fa::boost(user, pool_key, nft);
    }

    /// Removes nft boost. (Entry point wrapper)
    ///     * `user` - stake owner account.
    ///     * `pool_key` - address under which pool are stored.
    public entry fun remove_boost(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        // Call the migrated remove_boost function
        let nft = stake_fa::remove_boost(user, pool_key);
        // Logic to deposit NFT remains the same
        token::deposit_token(user, nft);
    }

    /// Enable "emergency state" for a pool at `pool_key`.
    ///     * `admin` - current emergency admin account.
    ///     * `pool_key` - address of the the pool.
    public entry fun enable_emergency(
        admin: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        // Call the migrated enable_emergency function
        stake_fa::enable_emergency(admin, pool_key);
    }

    /// Disable "emergency state" for a pool at `pool_key`.
    ///     * `admin` - current emergency admin account.
    ///     * `pool_key` - address of the the pool.
    public entry fun disable_emergency(
        admin: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        // Call the migrated enable_emergency function
        stake_fa::disable_emergency(admin, pool_key);
    }

    /// Unstake assets and boost NFT (if any) of the user and transfer to user account.
    /// Only callable in "emergency state".
    ///     * `user` - user account which has stake.
    ///     * `pool_key` - address of the pool.
    public entry fun emergency_unstake(
        user: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let user_addr = signer::address_of(user);

        let (_, fa_option, nft_option) = stake_fa::emergency_unstake(user, pool_key);
       
        if (option::is_some(&fa_option)) {
            let unstaked_fa = option::extract(&mut fa_option);
            let stake_metadata_obj = object::address_to_object<Metadata>(stake_addr);

            if (!primary_fungible_store::primary_store_exists(user_addr, stake_metadata_obj)) {
                primary_fungible_store::create_primary_store(user_addr, stake_metadata_obj);
            };
            primary_fungible_store::deposit(user_addr, unstaked_fa);
        };
        option::destroy_none(fa_option);

        if (option::is_some(&nft_option)) {
            token::deposit_token(user, option::extract(&mut nft_option));
        };
        option::destroy_none(nft_option);
    }

    /// Perform emergency unstake and receive assets as original Coin<StakeCoinType>.
    /// Caller MUST provide the correct StakeCoinType.
    public entry fun emergency_unstake_fa_coin<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address,
    ) {

        let stake_metadata_obj = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let user_addr = signer::address_of(user);
        // 1. Call original emergency unstake logic
        let (_amount, fa_option, nft_option) = stake_fa::emergency_unstake(user, pool_key);

        if (option::is_some(&fa_option)) {
            let unstaked_fa = option::extract(&mut fa_option);
            let unstaked_coin = coin_wrapper::unwrap<StakeCoinType>(unstaked_fa);
            coin::deposit(user_addr, unstaked_coin);
        };
        option::destroy_none(fa_option);

        if (option::is_some(&nft_option)) {
            token::deposit_token(user, option::extract(&mut nft_option));
        };
        option::destroy_none(nft_option);
    }

    /// Perform emergency unstake. Stake token was originally Coin<StakeCoinType>,
    /// pool rewards with an existing FungibleAsset (reward_addr).
    /// User receives back original Coin<StakeCoinType> and any boosted NFT.
    public entry fun emergency_unstake_coin_fa<StakeCoinType>(
        user: &signer,
        pool_creator_address: address,
        reward_addr: address, 
    ) {
        let user_addr = signer::address_of(user);

        let stake_metadata_obj_wrapped = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj_wrapped);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let (_amount_unstaked, fa_option, nft_option) = stake_fa::emergency_unstake(user, pool_key);

        if (option::is_some(&fa_option)) {
            let unstaked_fa_wrapped = option::extract(&mut fa_option);
            let unstaked_coin_original = coin_wrapper::unwrap<StakeCoinType>(unstaked_fa_wrapped);
            coin::deposit(user_addr, unstaked_coin_original);
        };
        option::destroy_none(fa_option);

        if (option::is_some(&nft_option)) {
            let returned_nft = option::extract(&mut nft_option);
            token::deposit_token(user, returned_nft);
        };
        option::destroy_none(nft_option);
    }

    public entry fun emergency_unstake_from_coins<StakeCoinType, RewardCoinType>(
        user: &signer,
        pool_creator_address: address
    ) {
        let user_addr = signer::address_of(user);

        let stake_metadata_obj_wrapped = coin_wrapper::create_fungible_asset<StakeCoinType>();
        let stake_addr = object::object_address(&stake_metadata_obj_wrapped);

        let reward_metadata_obj_wrapped = coin_wrapper::create_fungible_asset<RewardCoinType>();
        let reward_addr = object::object_address(&reward_metadata_obj_wrapped);

        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );

        let (_amount_unstaked, fa_option, nft_option) = stake_fa::emergency_unstake(user, pool_key);

        if (option::is_some(&fa_option)) {
            let unstaked_fa_wrapped = option::extract(&mut fa_option);
            let unstaked_coin_original = coin_wrapper::unwrap<StakeCoinType>(unstaked_fa_wrapped);
            coin::deposit(user_addr, unstaked_coin_original);
        };
        option::destroy_none(fa_option);

        if (option::is_some(&nft_option)) {
            let returned_nft = option::extract(&mut nft_option);
            token::deposit_token(user, returned_nft);
        };
        option::destroy_none(nft_option);
    }

    /// Withdraw remaining reward assets and transfer to treasury.
    ///     * `treasury` - treasury account signer.
    ///     * `pool_key` - pool address.
    ///     * `amount` - amount of reward assets to withdraw.

    public entry fun withdraw_reward_to_treasury(
        treasury: &signer, 
        pool_creator_address: address,
        stake_addr: address,
        reward_addr: address,
        amount: u64
    ) {
        let pool_key = stake_fa::new_pool_identifier(
            pool_creator_address,
            stake_addr,
            reward_addr
        );
        let treasury_addr = signer::address_of(treasury);
        let reward_assets = stake_fa::withdraw_to_treasury(treasury, pool_key, amount);
        let reward_fa_metadata_obj = object::address_to_object<Metadata>(reward_addr);
        if (!primary_fungible_store::primary_store_exists(treasury_addr, reward_fa_metadata_obj)) {
            primary_fungible_store::create_primary_store(treasury_addr, reward_fa_metadata_obj);
        };
        primary_fungible_store::deposit(treasury_addr, reward_assets);
    }

    #[view]
    public fun get_address_BWSUP(): address {
        let metadata = coin_wrapper::get_wrapper<SupraCoin>();
        object::object_address(&metadata)
    }

    #[view]
    public fun get_original_from_address(fa_address: address): String {
        let metadata_object = object::address_to_object<Metadata>(fa_address);
        coin_wrapper::get_original(metadata_object)
    }

}
