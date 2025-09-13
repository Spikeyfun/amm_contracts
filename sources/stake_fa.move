module spike_staking::stake_fa {
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};

    use aptos_std::event::{Self, EventHandle};
    use aptos_std::math64;
    use aptos_std::math128;
    use aptos_std::error;

    use supra_framework::account;
    use supra_framework::object::{Self, Object};
    use supra_framework::fungible_asset::{Self, Metadata, FungibleStore, FungibleAsset};
    use supra_framework::primary_fungible_store; 
    use supra_framework::timestamp;
    use supra_framework::table::{Self, Table};
    use aptos_token::token::{Self, Token};
    use supra_framework::supra_coin::SupraCoin;
    use supra_framework::coin::{Self};
    use spike_staking::stake_fa_config;

    // ===== INVALID_ARGUMENT =====
    const ERR_REWARD_CANNOT_BE_ZERO: u64 = 1;
    const ERR_AMOUNT_CANNOT_BE_ZERO: u64 = 2;
    const ERR_DURATION_CANNOT_BE_ZERO: u64 = 3;
    const ERR_INVALID_BOOST_PERCENT: u64 = 4;
    const ERR_WRONG_TOKEN_COLLECTION: u64 = 5;
    const ERR_INITIAL_REWARD_AMOUNT_ZERO: u64 = 6;
    const ERR_REWARD_RATE_ZERO: u64 = 7;
    const ERR_INVALID_INITIAL_SETUP_FOR_DYNAMIC_POOL: u64 = 8;
    const ERR_NFT_AMOUNT_MORE_THAN_ONE: u64 = 9;
    const ERR_INVALID_CONFIG_DURATION: u64 = 10;
    const ERR_INVALID_CONFIG_VALUE: u64 = 11;

    // ===== INVALID_STATE =====
    const ERR_NOTHING_TO_HARVEST: u64 = 21;
    const ERR_TOO_EARLY_UNSTAKE: u64 = 22;
    const ERR_EMERGENCY: u64 = 23;
    const ERR_NO_EMERGENCY: u64 = 24;
    const ERR_HARVEST_FINISHED: u64 = 25;
    const ERR_NOT_WITHDRAW_PERIOD: u64 = 26;
    const ERR_NON_BOOST_POOL: u64 = 27;
    const ERR_ALREADY_BOOSTED: u64 = 28;
    const ERR_NO_BOOST: u64 = 29;
    const ERR_STAKES_ALREADY_CLOSED: u64 = 30;
    const ERR_CANNOT_DEPOSIT_REWARD_TO_DYNAMIC_POOL: u64 = 31;
    const ERR_DYNAMIC_POOL_NOT_FINALIZED_FOR_HARVEST: u64 = 22;
    const ERR_OPERATION_NOT_ALLOWED_FOR_POOL_TYPE: u64 = 33;
    const ERR_NEGATIVE_PENDING_REWARD: u64 = 14;

    // ===== PERMISSION_DENIED =====
    const ERR_NOT_ENOUGH_PERMISSIONS_FOR_EMERGENCY: u64 = 41;
    const ERR_NOT_TREASURY: u64 = 42;
    const ERR_NOT_AUTHORIZED: u64 = 43;

    // ===== NOT_FOUND =====
    const ERR_NO_POOL: u64 = 51;
    const ERR_NO_STAKE: u64 = 52;
    const ERR_NO_COLLECTION: u64 = 53;

    // ===== ALREADY_EXISTS =====
    const ERR_POOL_ID_ALREADY_EXISTS: u64 = 61;
    const ERR_REGISTRY_ALREADY_EXISTS_FOR_INITIALIZE: u64 = 62;

    // ===== OUT_OF_RANGE =====
    const ERR_NOT_ENOUGH_S_BALANCE: u64 = 71;
    const ERR_DURATION_OVERFLOW: u64 = 72;
    const ERR_MUL_OVERFLOW_IN_ACCUM_REWARD_UPDATE: u64 = 73;
    const ERR_ACCUM_REWARD_ADD_OVERFLOW: u64 = 74;        
    const ERR_REWARD_DEBT_CALC_OVERFLOW: u64 = 75;

    // ===== ADMIN =====
    const ERR_NO_PENDING_ADMIN_TRANSFER: u64 = 81;
    const ERR_NOT_THE_PENDING_ADMIN: u64 = 82;
    const ERR_CANNOT_TRANSFER_TO_SELF: u64 = 83;
    const ERR_INSUFFICIENT_SUPRA_FOR_FEE: u64 = 84;
    
    const MAX_U64: u64 = 0xFFFFFFFFFFFFFFFFu64;
    const MAX_U128: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    const MIN_NORMAL_POOL_LOCKUP_SECONDS: u64 = 24 * 60 * 60; // 1 day
    const MAX_NORMAL_POOL_LOCKUP_SECONDS: u64 = 90 * 24 * 60 * 60; // 90 days
    const MIN_NFT_BOOST_PRECENT: u128 = 1;
    const MAX_NFT_BOOST_PERCENT: u128 = 100;
    const MIN_TREASURY_GRACE_PERIOD_SECONDS: u64 = 7 * 24 * 60 * 60; // 7 days
    const MAX_TREASURY_GRACE_PERIOD_SECONDS: u64 = 365 * 24 * 60 * 60;  // 1 year
    const ACCUM_REWARD_SCALE: u128 = 1000000000000;
    const MODULE_RESOURCE_ACCOUNT_SEED: vector<u8> = b"spike_staking_module_resource_v1";
    const MODULE_ADMIN_ACCOUNT: address = @spike_staking;

    struct GlobalConfig has key {
        normal_pool_lockup_seconds: u64,
        dynamic_pool_lockup_seconds: u64,
        treasury_withdraw_grace_period_seconds: u64,
        pool_registration_fee_amount: u64,
        fee_treasury_address: address,
    }

    struct AdminConfig has key {
        current_admin: address,
        pending_admin_candidate: Option<address>,
    }

    struct ConfigParameterUpdatedEvent has drop, store {
        admin_address: address,
        parameter_name: String,
        new_value_u64: u64,
        new_value_address: Option<address>,
    }

    struct PoolRegistrationFeePaidEvent has drop, store {
        caller_address: address,
        pool_key: PoolIdentifier,
        fee_amount: u64,
        fee_treasury_address: address,
    }

    struct AdminProposedEvent has drop, store {
        old_admin: address,
        new_admin_candidate: address,
    }

    struct AdminTransferredEvent has drop, store {
        old_admin: address,
        new_admin: address,
    }

    struct ModuleSignerStorage has key {
        resource_address: address,
        signer_cap: account::SignerCapability,
        config_parameter_updated_events: EventHandle<ConfigParameterUpdatedEvent>,
        admin_proposed_events: EventHandle<AdminProposedEvent>,
        admin_transferred_events: EventHandle<AdminTransferredEvent>,
        pool_registration_fee_paid_events: EventHandle<PoolRegistrationFeePaidEvent>,
    }

    struct PoolIdentifier has copy, drop, store {
        creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    }

    struct PoolsManager has key {
        pools: Table<PoolIdentifier, StakePoolData>
    }


    /// Stake pool, stores stake, reward assets and related info.
    struct StakePoolData has store { 
        pool_creator: address,        
        is_dynamic_pool: bool,
        stake_metadata: Object<Metadata>,
        reward_metadata: Object<Metadata>,
        reward_per_sec: u128,
        accum_reward: u128,
        last_updated: u64,
        start_timestamp: u64,
        end_timestamp: u64,
        stakes: table::Table<address, UserStake>,
        stake_store: Object<FungibleStore>,
        reward_store: Object<FungibleStore>,
        total_boosted: u128,
        nft_boost_config: Option<NFTBoostConfig>,
        emergency_locked: bool,
        stakes_closed: bool,

        stake_events: EventHandle<StakeEvent>,
        unstake_events: EventHandle<UnstakeEvent>,
        deposit_events: EventHandle<DepositRewardEvent>,
        harvest_events: EventHandle<HarvestEvent>,
        boost_events: EventHandle<BoostEvent>,
        remove_boost_events: EventHandle<RemoveBoostEvent>,
        pool_registered_event: EventHandle<PoolRegisteredEvent>,
        dynamic_pool_finalized_event: EventHandle<DynamicPoolFinalizedEvent>,
        emergency_enabled_event: EventHandle<EmergencyEnabledEvent>,
        emergency_unstake_event: EventHandle<EmergencyUnstakeEvent>,
        treasury_withdrawal_event: EventHandle<TreasuryWithdrawalEvent>,
    }


    struct NFTBoostConfig has store {
        boost_percent: u128,
        collection_owner: address,
        collection_name: String,
    }

    struct UserStake has store {
        amount: u64, // Amount of the stake asset (S)
        reward_points_debt: u128,
        earned_reward: u64, // Amount of reward asset (R) earned but not harvested
        unlock_time: u64,
        nft: Option<Token>,
        boosted_amount: u128, // Additional virtual stake amount from boost
    }

    //---Events---
        
    struct StakeEvent has drop, store {
        user_address: address,
        pool_key: PoolIdentifier,
        amount: u64,
    }
    struct UnstakeEvent has drop, store {
        user_address: address,
        pool_key: PoolIdentifier,
        amount: u64,
    }

    struct BoostEvent has drop, store {
        user_address: address,
        pool_key: PoolIdentifier, // <-- ADDED for context
        token_id: token::TokenId, // <-- ADDED specific token info
    }

    struct RemoveBoostEvent has drop, store {
        user_address: address,
        pool_key: PoolIdentifier, // <-- ADDED for context
        token_id: token::TokenId, // <-- ADDED specific token info
    }

    struct DepositRewardEvent has drop, store {
        depositor_address: address, // Renamed for clarity
        pool_key: PoolIdentifier,   // <-- ADDED for context
        amount: u64,
        new_end_timestamp: u64,
    }

    struct HarvestEvent has drop, store {
        user_address: address,
        pool_key: PoolIdentifier, // <-- ADDED for context
        amount: u64,
    }
    
    struct PoolRegisteredEvent has copy, drop, store {
        pool_key: PoolIdentifier,
        is_dynamic: bool,
        start_timestamp: u64,
        initial_end_timestamp: u64, // Will be MAX_U64 for dynamic pools initially
        initial_reward_per_sec: u128, // Will be 0 for dynamic pools initially
        boost_enabled: bool,
        boost_config_collection_owner: Option<address>,
        boost_config_collection_name: Option<String>,
        boost_config_percent: Option<u128>,
    }

    struct DynamicPoolFinalizedEvent has drop, store {
        pool_key: PoolIdentifier,
        finalized_by: address,
        end_timestamp: u64, // = finalization_timestamp
        total_reward_amount: u64,
        calculated_duration: u64,
        reward_per_sec: u128,
    }

    struct EmergencyEnabledEvent has drop, store {
        pool_key: PoolIdentifier,
        triggered_by: address,
    }

    struct EmergencyUnstakeEvent has drop, store {
        pool_key: PoolIdentifier,
        user_address: address,
        unstaked_amount: u64,
        nft_withdrawn: bool,
    }

    struct TreasuryWithdrawalEvent has drop, store {
        pool_key: PoolIdentifier,
        treasury_address: address,
        amount: u64,
    }

    // create_boost_config (sin cambios)
    public fun create_boost_config(
        collection_owner: address,
        collection_name: String,
        boost_percent: u128
    ): NFTBoostConfig {
        assert!(token::check_collection_exists(collection_owner, collection_name), error::not_found(ERR_NO_COLLECTION));
        assert!(boost_percent >= MIN_NFT_BOOST_PRECENT && boost_percent <= MAX_NFT_BOOST_PERCENT,  error::invalid_argument(ERR_INVALID_BOOST_PERCENT));

        NFTBoostConfig {
            boost_percent,
            collection_owner,
            collection_name,
        }
    }

    fun init_module(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        assert!(deployer_addr == MODULE_ADMIN_ACCOUNT, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(!exists<ModuleSignerStorage>(deployer_addr), error::already_exists(ERR_REGISTRY_ALREADY_EXISTS_FOR_INITIALIZE));
        let (resource_signer, signer_cap) = account::create_resource_account(deployer, MODULE_RESOURCE_ACCOUNT_SEED);
        let resource_addr = signer::address_of(&resource_signer);
        let config_updated_handle = account::new_event_handle<ConfigParameterUpdatedEvent>(&resource_signer);
        let admin_proposed_handle = account::new_event_handle<AdminProposedEvent>(&resource_signer);
        let admin_transferred_handle = account::new_event_handle<AdminTransferredEvent>(&resource_signer);
        let pool_reg_fee_paid_handle = account::new_event_handle<PoolRegistrationFeePaidEvent>(&resource_signer);

        move_to(&resource_signer, GlobalConfig {
            normal_pool_lockup_seconds: 604800,
            dynamic_pool_lockup_seconds: 30 * 24 * 60 * 60,
            treasury_withdraw_grace_period_seconds: 7257600,
            pool_registration_fee_amount: 137_000_000,
            fee_treasury_address: deployer_addr,
        });
        
        if (!exists<AdminConfig>(resource_addr)) {
            move_to(&resource_signer, AdminConfig {
                current_admin: deployer_addr,
                pending_admin_candidate: option::none(),
            });
        };

        move_to(deployer, ModuleSignerStorage {
            resource_address: resource_addr,
            signer_cap: signer_cap,
            config_parameter_updated_events: config_updated_handle,
            admin_proposed_events: admin_proposed_handle,
            admin_transferred_events: admin_transferred_handle,
            pool_registration_fee_paid_events: pool_reg_fee_paid_handle,
        });

        move_to(&resource_signer, PoolsManager { 
            pools: table::new() 
        });
    }

    /// Registering pool for specific fungible assets.
    ///     * `owner` - pool creator account, under which the pool will be stored.
    ///     * `stake_metadata_addr` - Metadata address of the asset to be staked (S).
    ///     * `initial_reward_assets` - FungibleAsset of reward tokens (R) to initialize the pool distribution.
    ///     * `duration` - Initial pool life duration based on `initial_reward_assets`.
    ///     * `nft_boost_config` - Optional boost configuration.
    public fun register_pool(
        caller: &signer,
        stake_addr: address,
        reward_addr: address,     
        initial_reward_amount: u64,         
        duration: u64,                      
        nft_boost_config: Option<NFTBoostConfig>
    ) acquires PoolsManager, ModuleSignerStorage, GlobalConfig {
        let caller_addr = signer::address_of(caller);
        let resource_signer = get_module_resource_signer();

        let resource_addr = signer::address_of(&resource_signer);
        let module_config = borrow_global<GlobalConfig>(resource_addr);
        let fee_amount = module_config.pool_registration_fee_amount;
        let fee_treasury = module_config.fee_treasury_address;

        if (fee_amount > 0) {
            assert!(coin::balance<SupraCoin>(caller_addr) >= fee_amount, error::permission_denied(ERR_INSUFFICIENT_SUPRA_FOR_FEE));
            coin::transfer<SupraCoin>(caller, fee_treasury, fee_amount);
            let module_storage = borrow_global_mut<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT);
            event::emit_event<PoolRegistrationFeePaidEvent>(
                &mut module_storage.pool_registration_fee_paid_events,
                PoolRegistrationFeePaidEvent {
                    caller_address: caller_addr,
                    pool_key: PoolIdentifier {
                        creator_addr: caller_addr,
                        stake_addr,
                        reward_addr
                    },
                    fee_amount,
                    fee_treasury_address: fee_treasury,
                }
            );
        };

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        let pool_key = PoolIdentifier { 
            creator_addr: caller_addr,
            stake_addr, 
            reward_addr 
        };

        assert!(!table::contains(&pools_manager.pools, pool_key), error::already_exists(ERR_POOL_ID_ALREADY_EXISTS));

        assert!(duration > 0, error::invalid_argument(ERR_DURATION_CANNOT_BE_ZERO));
        assert!(initial_reward_amount > 0, error::invalid_argument(ERR_INITIAL_REWARD_AMOUNT_ZERO));
        let boost_enabled = option::is_some(&nft_boost_config);

        let stake_metadata: Object<Metadata> = object::address_to_object<Metadata>(stake_addr);
        let reward_metadata: Object<Metadata> = object::address_to_object<Metadata>(reward_addr);

        let reward_per_sec = (initial_reward_amount as u128) * ACCUM_REWARD_SCALE / (duration as u128);
        assert!(reward_per_sec > 0, error::invalid_argument(ERR_REWARD_RATE_ZERO));

        let caller_primary_reward_store = primary_fungible_store::primary_store(caller_addr, reward_metadata);
        let initial_reward_asset = fungible_asset::withdraw(
            caller,
            caller_primary_reward_store,
            initial_reward_amount
        );

        let current_time = timestamp::now_seconds();
        let end_timestamp = current_time + duration;
        assert!(end_timestamp > current_time && end_timestamp != MAX_U64, error::out_of_range(ERR_DURATION_OVERFLOW));

        let stake_store_obj_ref = object::create_object_from_account(&resource_signer);
        let pool_stake_store = fungible_asset::create_store(&stake_store_obj_ref, stake_metadata);

        let reward_store_obj_ref = object::create_object_from_account(&resource_signer);
        let pool_reward_store = fungible_asset::create_store(&reward_store_obj_ref, reward_metadata);

        fungible_asset::deposit(pool_reward_store, initial_reward_asset);

        let event_boost_owner_opt: Option<address> = option::none();
        let event_boost_name_opt: Option<String> = option::none();
        let event_boost_percent_opt: Option<u128> = option::none();

        if (boost_enabled) {
            let config_ref = option::borrow(&nft_boost_config); 
            event_boost_owner_opt = option::some(config_ref.collection_owner);
            event_boost_name_opt = option::some(config_ref.collection_name);
            event_boost_percent_opt = option::some(config_ref.boost_percent);
        };

        let stake_events_handle = account::new_event_handle<StakeEvent>(&resource_signer);
        let unstake_events_handle = account::new_event_handle<UnstakeEvent>(&resource_signer);
        let deposit_events_handle = account::new_event_handle<DepositRewardEvent>(&resource_signer);
        let harvest_events_handle = account::new_event_handle<HarvestEvent>(&resource_signer);
        let boost_events_handle = account::new_event_handle<BoostEvent>(&resource_signer);
        let remove_boost_events_handle = account::new_event_handle<RemoveBoostEvent>(&resource_signer);
        let pool_registered_event_handle = account::new_event_handle<PoolRegisteredEvent>(&resource_signer);
        let dynamic_pool_finalized_event_handle = account::new_event_handle<DynamicPoolFinalizedEvent>(&resource_signer);
        let emergency_enabled_event_handle = account::new_event_handle<EmergencyEnabledEvent>(&resource_signer);
        let emergency_unstake_event_handle = account::new_event_handle<EmergencyUnstakeEvent>(&resource_signer);
        let treasury_withdrawal_event_handle = account::new_event_handle<TreasuryWithdrawalEvent>(&resource_signer);

        let new_pool_data = StakePoolData {
            pool_creator: caller_addr,
            is_dynamic_pool: false,
            stake_metadata, // Objeto Metadata
            reward_metadata, // Objeto Metadata
            reward_per_sec, 
            accum_reward: 0u128,
            last_updated: current_time,
            start_timestamp: current_time,
            end_timestamp,
            stakes: table::new(),
            stake_store: pool_stake_store, // El Object<FungibleStore> creado
            reward_store: pool_reward_store, // El Object<FungibleStore> creado
            total_boosted: 0,
            nft_boost_config,
            emergency_locked: false,
            stakes_closed: false,
            stake_events: stake_events_handle,
            unstake_events: unstake_events_handle,
            deposit_events: deposit_events_handle,
            harvest_events: harvest_events_handle,
            boost_events: boost_events_handle,
            remove_boost_events: remove_boost_events_handle,
            pool_registered_event: pool_registered_event_handle,
            dynamic_pool_finalized_event: dynamic_pool_finalized_event_handle,
            emergency_enabled_event: emergency_enabled_event_handle,
            emergency_unstake_event: emergency_unstake_event_handle,
            treasury_withdrawal_event: treasury_withdrawal_event_handle,
        };

        event::emit_event<PoolRegisteredEvent>(
            &mut new_pool_data.pool_registered_event, // Use handle from the data to be added
            PoolRegisteredEvent {
                pool_key,
                is_dynamic: false,
                start_timestamp: current_time,
                initial_end_timestamp: end_timestamp,
                initial_reward_per_sec: reward_per_sec,
                boost_enabled,
                boost_config_collection_owner: event_boost_owner_opt,
                boost_config_collection_name: event_boost_name_opt,
                boost_config_percent: event_boost_percent_opt,
            },
        );

        table::add(&mut pools_manager.pools, pool_key, new_pool_data);
    }

    public fun register_dynamic_pool(
        caller: &signer,
        stake_addr: address,
        reward_addr: address,
        nft_boost_config: Option<NFTBoostConfig>,
    ) acquires PoolsManager, ModuleSignerStorage, GlobalConfig {
        let caller_addr = signer::address_of(caller);
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let module_config = borrow_global<GlobalConfig>(resource_addr);
        let fee_amount = module_config.pool_registration_fee_amount;
        let fee_treasury = module_config.fee_treasury_address;

        if (fee_amount > 0) {

            assert!(coin::balance<SupraCoin>(caller_addr) >= fee_amount, error::permission_denied(ERR_INSUFFICIENT_SUPRA_FOR_FEE));
            coin::transfer<SupraCoin>(caller, fee_treasury, fee_amount);

            let module_storage = borrow_global_mut<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT);
            event::emit_event<PoolRegistrationFeePaidEvent>(
                &mut module_storage.pool_registration_fee_paid_events,
                PoolRegistrationFeePaidEvent {
                    caller_address: caller_addr,
                    pool_key: PoolIdentifier {
                        creator_addr: caller_addr,
                        stake_addr,
                        reward_addr
                    },
                    fee_amount,
                    fee_treasury_address: fee_treasury,
                }
            );
        };

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        
        let pool_key = PoolIdentifier {
            creator_addr: caller_addr,
            stake_addr,
            reward_addr
        };
        assert!(!table::contains(&pools_manager.pools, pool_key), error::already_exists(ERR_POOL_ID_ALREADY_EXISTS));

        let stake_metadata = object::address_to_object(stake_addr);
        let reward_metadata = object::address_to_object(reward_addr);
    
        let current_time = timestamp::now_seconds();

        let boost_enabled = option::is_some(&nft_boost_config);

        let stake_store_obj = object::create_object_from_account(&resource_signer);
        let pool_stake_store = fungible_asset::create_store(&stake_store_obj, stake_metadata);

        let reward_store_obj = object::create_object_from_account(&resource_signer);
        let pool_reward_store = fungible_asset::create_store(&reward_store_obj, reward_metadata);

        let event_boost_owner_opt: Option<address> = option::none();
        let event_boost_name_opt: Option<String> = option::none();
        let event_boost_percent_opt: Option<u128> = option::none();

        if (boost_enabled) {
            let config_ref = option::borrow(&nft_boost_config);
            event_boost_owner_opt = option::some(config_ref.collection_owner);
            event_boost_name_opt = option::some(config_ref.collection_name);
            event_boost_percent_opt = option::some(config_ref.boost_percent);
        };

        let stake_events_handle = account::new_event_handle<StakeEvent>(&resource_signer);
        let unstake_events_handle = account::new_event_handle<UnstakeEvent>(&resource_signer);
        let deposit_events_handle = account::new_event_handle<DepositRewardEvent>(&resource_signer);
        let harvest_events_handle = account::new_event_handle<HarvestEvent>(&resource_signer);
        let boost_events_handle = account::new_event_handle<BoostEvent>(&resource_signer);
        let remove_boost_events_handle = account::new_event_handle<RemoveBoostEvent>(&resource_signer);
        let pool_registered_event_handle = account::new_event_handle<PoolRegisteredEvent>(&resource_signer);
        let dynamic_pool_finalized_event_handle = account::new_event_handle<DynamicPoolFinalizedEvent>(&resource_signer);
        let emergency_enabled_event_handle = account::new_event_handle<EmergencyEnabledEvent>(&resource_signer);
        let emergency_unstake_event_handle = account::new_event_handle<EmergencyUnstakeEvent>(&resource_signer);
        let treasury_withdrawal_event_handle = account::new_event_handle<TreasuryWithdrawalEvent>(&resource_signer);

        let new_pool_data = StakePoolData {
            pool_creator: caller_addr,
            is_dynamic_pool: true,
            stake_metadata, // Objeto Metadata
            reward_metadata, // Objeto Metadata
            reward_per_sec: 0, 
            accum_reward: 0, // Inicia en 0
            last_updated: current_time,
            start_timestamp: current_time,
            end_timestamp: MAX_U64,
            stakes: table::new(),
            stake_store: pool_stake_store, // El Object<FungibleStore> creado
            reward_store: pool_reward_store, // El Object<FungibleStore> creado
            total_boosted: 0,
            nft_boost_config,
            emergency_locked: false,
            stakes_closed: false,
            stake_events: stake_events_handle,
            unstake_events: unstake_events_handle,
            deposit_events: deposit_events_handle,
            harvest_events: harvest_events_handle,
            boost_events: boost_events_handle, 
            remove_boost_events: remove_boost_events_handle, 
            pool_registered_event: pool_registered_event_handle,
            dynamic_pool_finalized_event: dynamic_pool_finalized_event_handle,
            emergency_enabled_event: emergency_enabled_event_handle,
            emergency_unstake_event: emergency_unstake_event_handle,
            treasury_withdrawal_event: treasury_withdrawal_event_handle,
        };

        event::emit_event<PoolRegisteredEvent>(
            &mut new_pool_data.pool_registered_event,
            PoolRegisteredEvent {
                pool_key,
                is_dynamic: true,
                start_timestamp: current_time,
                initial_end_timestamp: MAX_U64, // Emit MAX_U64
                initial_reward_per_sec: 0,     // Emit 0
                boost_enabled,
                boost_config_collection_owner: event_boost_owner_opt,
                boost_config_collection_name: event_boost_name_opt,
                boost_config_percent: event_boost_percent_opt,
            },
        );
        
        table::add(&mut pools_manager.pools, pool_key, new_pool_data);
    }
    
    /// Depositing reward assets to specific pool, updates pool duration.
    ///     * `depositor` - rewards depositor account.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `assets` - FungibleAsset of reward tokens (R) to deposit.
    public fun deposit_reward_assets(
        depositor: &signer,
        pool_key: PoolIdentifier,
        deposit_amount: u64
    ) acquires PoolsManager, ModuleSignerStorage {
        assert!(deposit_amount > 0, error::invalid_argument(ERR_AMOUNT_CANNOT_BE_ZERO));
        let resource_addr = get_module_resource_address();

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));

        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(!pool.is_dynamic_pool, error::invalid_state(ERR_CANNOT_DEPOSIT_REWARD_TO_DYNAMIC_POOL));
        assert!(!is_finished_inner(pool), error::invalid_state(ERR_HARVEST_FINISHED));

        let depositor_addr = signer::address_of(depositor);
        let depositor_primary_store = primary_fungible_store::primary_store(depositor_addr, pool.reward_metadata);

        let assets_to_deposit = fungible_asset::withdraw(
            depositor, 
            depositor_primary_store,
            deposit_amount
        );

        // --- Recalculate reward_per_sec and end_timestamp ---
        // First, update the pool to account for rewards accrued until now
        update_accum_reward(pool);

        // Current remaining reward amount + new deposit amount
        //let current_reward_balance = fungible_asset::balance(pool.reward_store);
        //let total_new_reward_balance = current_reward_balance + amount;

        // Total duration based on the new total rewards
        // Use 128-bit math for potentially large intermediate values
        let additional_duration_u128 = if (pool.reward_per_sec > 0) {
            math128::mul_div((deposit_amount as u128), ACCUM_REWARD_SCALE, pool.reward_per_sec)
        } else {
            abort error::invalid_state(ERR_REWARD_RATE_ZERO)
        };

        if (additional_duration_u128 > 0) {
            assert!(additional_duration_u128 <= (MAX_U64 as u128), error::out_of_range(ERR_DURATION_OVERFLOW));
            let additional_duration_u64 = (additional_duration_u128 as u64);
            let new_end_timestamp = pool.end_timestamp + additional_duration_u64;
            assert!(new_end_timestamp > pool.end_timestamp && new_end_timestamp != MAX_U64, error::out_of_range(ERR_DURATION_OVERFLOW));
            pool.end_timestamp = new_end_timestamp;
        };


        // Merge the deposited assets
        fungible_asset::deposit(pool.reward_store, assets_to_deposit);

        event::emit_event<DepositRewardEvent>(
            &mut pool.deposit_events,
            DepositRewardEvent {
                depositor_address: depositor_addr,
                pool_key: pool_key,
                amount: deposit_amount,
                new_end_timestamp: pool.end_timestamp,
            },
        );
    }

    /// Stakes user assets in pool.
    ///     * `user` - account that making a stake.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `assets` - FungibleAsset of stake tokens (S) to be staked.
    public fun stake(
        user: &signer,
        pool_key: PoolIdentifier,
        stake_amount: u64
    ) acquires PoolsManager, ModuleSignerStorage, GlobalConfig {
        assert!(stake_amount > 0, error::invalid_argument(ERR_AMOUNT_CANNOT_BE_ZERO));
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let user_addr = signer::address_of(user);
        let config = borrow_global<GlobalConfig>(resource_addr);

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);

        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(!pool.stakes_closed, error::invalid_state(ERR_STAKES_ALREADY_CLOSED));

        let user_primary_stake_store = primary_fungible_store::primary_store(user_addr, pool.stake_metadata);
        let assets_to_deposit = fungible_asset::withdraw(user, user_primary_stake_store, stake_amount);

        update_accum_reward(pool);

        let current_time = timestamp::now_seconds();
        let lockup_duration = if (pool.is_dynamic_pool) {
            config.dynamic_pool_lockup_seconds
        } else {
            config.normal_pool_lockup_seconds 
        };

        if (!table::contains(&pool.stakes, user_addr)) {
            let user_effective_stake_after_new_deposit = (stake_amount as u128);

            assert!(pool.accum_reward == 0 || user_effective_stake_after_new_deposit <= MAX_U128 / pool.accum_reward, error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));

            let initial_reward_points_debt = pool.accum_reward * user_effective_stake_after_new_deposit;

            let new_stake = UserStake {
                amount: stake_amount,
                reward_points_debt: initial_reward_points_debt,
                earned_reward: 0,
                unlock_time: current_time + lockup_duration,
                nft: option::none(),
                boosted_amount: 0, 
            };
            table::add(&mut pool.stakes, user_addr, new_stake);
        } else {
            let user_stake = table::borrow_mut(&mut pool.stakes, user_addr);

            update_user_reward_state(pool.accum_reward, user_stake);

            user_stake.amount = user_stake.amount + stake_amount;
            user_stake.unlock_time = current_time + lockup_duration;

            if (option::is_some(&user_stake.nft)) {
                assert!(option::is_some(&pool.nft_boost_config), error::invalid_state(ERR_NON_BOOST_POOL));
                let boost_config_val = option::borrow(&pool.nft_boost_config);
                let boost_percent = boost_config_val.boost_percent;

                pool.total_boosted = pool.total_boosted - user_stake.boosted_amount; 
                user_stake.boosted_amount = ((user_stake.amount as u128) * boost_percent) / 100; 
                pool.total_boosted = pool.total_boosted + user_stake.boosted_amount; 
            };

            let user_new_total_effective_stake = user_stake_amount_with_boosted(user_stake);
            assert!( !(user_new_total_effective_stake > 0 && pool.accum_reward > 0 && (MAX_U128 / pool.accum_reward < user_new_total_effective_stake)), error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));
            user_stake.reward_points_debt = pool.accum_reward * user_new_total_effective_stake;
        };

        fungible_asset::deposit(pool.stake_store, assets_to_deposit);
        event::emit_event<StakeEvent>(
            &mut pool.stake_events, StakeEvent { 
                user_address: user_addr, 
                pool_key, amount: 
                stake_amount 
            }
        );
    }

    /// Unstakes user assets from pool.
    ///     * `user` - account that owns stake.
    ///     * `pool_addr` - address under which pool are stored.
    ///     * `amount` - a number of stake assets (S) to unstake.
    /// Returns FungibleAsset of stake tokens: `FungibleAsset`.
    public fun unstake(
        user: &signer,
        pool_key: PoolIdentifier,
        amount: u64
    ): FungibleAsset acquires PoolsManager, ModuleSignerStorage {
        assert!(amount > 0, error::invalid_argument(ERR_AMOUNT_CANNOT_BE_ZERO));
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let user_addr = signer::address_of(user);

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);

        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        update_accum_reward(pool);

        let user_stake = table::borrow_mut(&mut pool.stakes, user_addr);

        let current_time = timestamp::now_seconds();
        let effective_unlock = math64::min(pool.end_timestamp, user_stake.unlock_time);
        assert!(current_time >= effective_unlock, error::invalid_state(ERR_TOO_EARLY_UNSTAKE));

        assert!(amount <= user_stake.amount, error::out_of_range(ERR_NOT_ENOUGH_S_BALANCE));

        update_user_reward_state(pool.accum_reward, user_stake);

        // 2. Actualizar cantidad de stake
        let old_boosted_amount = user_stake.boosted_amount;
        user_stake.amount = user_stake.amount - amount;

        if (option::is_some(&user_stake.nft)) {
            assert!(option::is_some(&pool.nft_boost_config), error::invalid_state(ERR_NON_BOOST_POOL));
            let boost_config_val = option::borrow(&pool.nft_boost_config);
            let boost_percent = boost_config_val.boost_percent;

            pool.total_boosted = pool.total_boosted - old_boosted_amount;
            if (user_stake.amount > 0) {
                user_stake.boosted_amount = ((user_stake.amount as u128) * boost_percent) / 100;
                pool.total_boosted = pool.total_boosted + user_stake.boosted_amount;
            } else {
                user_stake.boosted_amount = 0;
            }
        } else {
            user_stake.boosted_amount = 0;
        };

        let user_new_total_effective_stake = user_stake_amount_with_boosted(user_stake);
        if (user_new_total_effective_stake > 0 && pool.accum_reward > 0 && (MAX_U128 / pool.accum_reward < user_new_total_effective_stake)) {
            assert!(false, error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));
        };
        user_stake.reward_points_debt = pool.accum_reward * user_new_total_effective_stake;

        let withdrawn_assets_from_pool = fungible_asset::withdraw(&resource_signer, pool.stake_store, amount);
        event::emit_event<UnstakeEvent>(
            &mut pool.unstake_events, UnstakeEvent { 
                user_address: user_addr, 
                pool_key, amount 
                }
            );
        withdrawn_assets_from_pool
    }

    /// Harvests user reward.
    ///     * `user` - stake owner account.
    ///     * `pool_addr` - address under which pool are stored.
    /// Returns FungibleAsset of reward tokens: `FungibleAsset`.
    public fun harvest(
        user: &signer,
        pool_key: PoolIdentifier
    ): (u64, FungibleAsset) acquires PoolsManager, ModuleSignerStorage {
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let user_addr = signer::address_of(user);

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);

        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        if (pool.is_dynamic_pool) {
            assert!(pool.stakes_closed && pool.reward_per_sec > 0, error::invalid_state(ERR_DYNAMIC_POOL_NOT_FINALIZED_FOR_HARVEST));
        } else {
            //let user_stake_ref_for_check = table::borrow(&pool.stakes, user_addr);
            //let effective_unlock = math64::min(pool.end_timestamp, user_stake_ref_for_check.unlock_time);
            //assert!(timestamp::now_seconds() >= effective_unlock, error::invalid_state(ERR_TOO_EARLY_UNSTAKE));
            //Now users can harvest anytime
        };

        update_accum_reward(pool); 

        let user_stake = table::borrow_mut(&mut pool.stakes, user_addr);

        update_user_reward_state(pool.accum_reward, user_stake);

        let amount_to_harvest = user_stake.earned_reward;
        assert!(amount_to_harvest > 0, error::invalid_state(ERR_NOTHING_TO_HARVEST));

        user_stake.earned_reward = 0;

        let withdrawn_rewards_from_pool = fungible_asset::withdraw(&resource_signer, pool.reward_store, amount_to_harvest);
        event::emit_event<HarvestEvent>(
            &mut pool.harvest_events, HarvestEvent { 
                user_address: user_addr, 
                pool_key, 
                amount: amount_to_harvest 
            }
        );
        (amount_to_harvest, withdrawn_rewards_from_pool)
    }

    /// Boosts user stake with nft.
    public fun boost(
        user: &signer, 
        pool_key: PoolIdentifier,
        nft: Token
    ) acquires PoolsManager, ModuleSignerStorage {
        let resource_addr = get_module_resource_address();
        let user_addr = signer::address_of(user);
        
        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));

        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(option::is_some(&pool.nft_boost_config), error::invalid_state(ERR_NON_BOOST_POOL));

        let boost_config_ref = option::borrow(&pool.nft_boost_config);
        let pool_collection_owner = boost_config_ref.collection_owner;
        let pool_collection_name: String = boost_config_ref.collection_name;
        
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));
        assert!(token::get_token_amount(&nft) == 1, error::invalid_argument(ERR_NFT_AMOUNT_MORE_THAN_ONE));

        let token_id = token::get_token_id(&nft);
        let (nft_collection_owner, nft_collection_name_ref, _, _) = token::get_token_id_fields(&token_id);
        assert!(nft_collection_owner == pool_collection_owner, error::invalid_argument(ERR_WRONG_TOKEN_COLLECTION));
        assert!(nft_collection_name_ref == pool_collection_name, error::invalid_argument(ERR_WRONG_TOKEN_COLLECTION));
        
        update_accum_reward(pool);

        let user_stake = table::borrow_mut(&mut pool.stakes, user_addr);
        update_user_reward_state(pool.accum_reward, user_stake);
        assert!(option::is_none(&user_stake.nft), error::invalid_state(ERR_ALREADY_BOOSTED));

        option::fill(&mut user_stake.nft, nft);
        let boost_config_val = option::borrow(&pool.nft_boost_config);
        let boost_percent = boost_config_val.boost_percent;
        user_stake.boosted_amount = ((user_stake.amount as u128) * boost_percent) / 100;
        pool.total_boosted = pool.total_boosted + user_stake.boosted_amount;

        let user_new_total_effective_stake = user_stake_amount_with_boosted(user_stake);
        if (user_new_total_effective_stake > 0 && pool.accum_reward > 0 && (MAX_U128 / pool.accum_reward < user_new_total_effective_stake)) {
            assert!(false, error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));
        };
        
        user_stake.reward_points_debt = pool.accum_reward * user_new_total_effective_stake;
        event::emit_event<BoostEvent>(
            &mut pool.boost_events,
            BoostEvent {
                user_address: user_addr,
                pool_key,
                token_id 
            }
        );
    }

    /// Removes nft boost.
    public fun remove_boost(
        user: &signer, 
        pool_key: PoolIdentifier
    ): Token acquires PoolsManager, ModuleSignerStorage {
        let resource_addr = get_module_resource_address();
        let user_addr = signer::address_of(user);

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        
        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        update_accum_reward(pool);

        let user_stake = table::borrow_mut(&mut pool.stakes, user_addr);
        assert!(option::is_some(&user_stake.nft), error::invalid_state(ERR_NO_BOOST));

        update_user_reward_state(pool.accum_reward, user_stake);

        pool.total_boosted = pool.total_boosted - user_stake.boosted_amount;
        user_stake.boosted_amount = 0;
        let extracted_nft = option::extract(&mut user_stake.nft);
        let token_id = token::get_token_id(&extracted_nft);

        let user_new_total_effective_stake = user_stake_amount_with_boosted(user_stake); 
        if (user_new_total_effective_stake > 0 && pool.accum_reward > 0 && (MAX_U128 / pool.accum_reward < user_new_total_effective_stake)) {
            assert!(false, error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));
        };
        user_stake.reward_points_debt = pool.accum_reward * user_new_total_effective_stake;

        event::emit_event<RemoveBoostEvent>(
            &mut pool.remove_boost_events,
            RemoveBoostEvent {
                user_address: user_addr,
                pool_key,
                token_id
            }
        );
        extracted_nft
    }

    /// Finalizes dynamic pool and deposits reward assets to the pool.
    public fun finalize_dynamic_pool_rewards(
        caller_signer: &signer,
        pool_key: PoolIdentifier,
        total_reward_amount: u64
    ) acquires PoolsManager, ModuleSignerStorage {
        let caller_addr = signer::address_of(caller_signer);
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));

        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        assert!(caller_addr == pool.pool_creator, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(pool.is_dynamic_pool, error::invalid_state(ERR_OPERATION_NOT_ALLOWED_FOR_POOL_TYPE));
        assert!(!pool.stakes_closed, error::invalid_state(ERR_STAKES_ALREADY_CLOSED));
        assert!(total_reward_amount > 0, error::invalid_argument(ERR_REWARD_CANNOT_BE_ZERO));

        update_accum_reward(pool);

        let finalization_time = timestamp::now_seconds();

        assert!(finalization_time >= pool.start_timestamp, error::invalid_argument(ERR_DURATION_CANNOT_BE_ZERO));
        pool.end_timestamp = finalization_time;

        let duration = if (finalization_time > pool.start_timestamp) {
            finalization_time - pool.start_timestamp
        } else {
            0
        };
        assert!(duration > 0, error::invalid_argument(ERR_DURATION_CANNOT_BE_ZERO));
        pool.stakes_closed = true;
        
        pool.reward_per_sec = math128::mul_div(
            (total_reward_amount as u128),
            ACCUM_REWARD_SCALE,
            (duration as u128)
        );
        assert!(pool.reward_per_sec > 0, error::invalid_argument(ERR_REWARD_RATE_ZERO));

        let caller_primary_reward_store = primary_fungible_store::primary_store(caller_addr, pool.reward_metadata);
        let reward_assets_to_deposit = fungible_asset::withdraw(
            caller_signer,
            caller_primary_reward_store,
            total_reward_amount
        );
        fungible_asset::deposit(pool.reward_store, reward_assets_to_deposit);

        // Update accum_reward. Since last_updated was start_timestamp and reward_per_sec
        // was just defined, this will calculate the accum_reward for the entire period.
        // The update_accum_reward function internally uses get_time_for_last_update, which
        // will consider the newly set pool.end_timestamp.
        pool.accum_reward = 0;
        pool.last_updated = pool.start_timestamp;
        update_accum_reward(pool);
        // After this, pool.last_updated will be equal to pool.end_timestamp.
        // Emit an event if necessary
        event::emit_event<DynamicPoolFinalizedEvent>(
            &mut pool.dynamic_pool_finalized_event,
            DynamicPoolFinalizedEvent {
                pool_key,
                finalized_by: caller_addr,
                end_timestamp: pool.end_timestamp, // Use the final end_timestamp
                total_reward_amount,
                calculated_duration: duration, // Use captured duration
                reward_per_sec: pool.reward_per_sec, // Usar el valor final del pool
            }
        );
    }

        /// Enables local "emergency state" for the specific pool at `pool_addr`.
    public fun enable_emergency(
        admin: &signer, 
        pool_key: PoolIdentifier
    ) acquires PoolsManager, ModuleSignerStorage {
        assert!(signer::address_of(admin) == stake_fa_config::get_emergency_admin_address(), error::permission_denied(ERR_NOT_ENOUGH_PERMISSIONS_FOR_EMERGENCY));
        let admin_addr = signer::address_of(admin);
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        assert!(!is_emergency_inner(pool), error::invalid_state(ERR_EMERGENCY));
        pool.emergency_locked = true;

        event::emit_event<EmergencyEnabledEvent>(
            &mut pool.emergency_enabled_event,
            EmergencyEnabledEvent {
                pool_key,
                triggered_by: admin_addr,
            }
        );
    }

    public fun disable_emergency(
        admin: &signer, 
        pool_key: PoolIdentifier
    ) acquires PoolsManager, ModuleSignerStorage {
        assert!(signer::address_of(admin) == stake_fa_config::get_emergency_admin_address(), error::permission_denied(ERR_NOT_ENOUGH_PERMISSIONS_FOR_EMERGENCY));
        
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));

        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        
        assert!(pool.emergency_locked, error::invalid_state(ERR_NO_EMERGENCY));

        pool.emergency_locked = false;
    }


    /// Withdraws all the user stake and nft from the pool in "emergency state".
    public fun emergency_unstake(
        user: &signer, 
        pool_key: PoolIdentifier
    ): (u64, Option<FungibleAsset>, Option<Token>) acquires PoolsManager, ModuleSignerStorage {
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let user_addr = signer::address_of(user);
        
        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);
        
        assert!(is_emergency_inner(pool), error::invalid_state(ERR_NO_EMERGENCY));
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        
        let user_stake = table::remove(&mut pool.stakes, user_addr);
        let UserStake { amount, reward_points_debt: _, earned_reward: _, unlock_time: _, nft, boosted_amount } = user_stake;
        let nft_was_present = option::is_some(&nft);

        if (boosted_amount > 0) {
            pool.total_boosted = if (pool.total_boosted >= boosted_amount) {
                pool.total_boosted - boosted_amount 
            } else { 
                0 
            };
        };

        let maybe_withdrawn_fa: Option<FungibleAsset> = if (amount > 0) {
            let withdrawn_stake_assets = fungible_asset::withdraw(
                &resource_signer,
                pool.stake_store,
                amount
            );
            option::some(withdrawn_stake_assets)
        } else {
            option::none()
        };

        // Emit NEW Event
        event::emit_event<EmergencyUnstakeEvent>(
            &mut pool.emergency_unstake_event,
            EmergencyUnstakeEvent {
                pool_key,
                user_address: user_addr,
                unstaked_amount: amount,
                nft_withdrawn: nft_was_present,
            }
        );

        (amount, maybe_withdrawn_fa, nft)
    }


    /// Withdraws remaining rewards using treasury account after cooldown or in emergency.
    public fun withdraw_to_treasury(
        treasury_signer: &signer,
        pool_key: PoolIdentifier,
        amount: u64
    ): FungibleAsset acquires PoolsManager, ModuleSignerStorage, GlobalConfig {
        assert!(amount > 0, error::invalid_argument(ERR_AMOUNT_CANNOT_BE_ZERO));
        let treasury_addr = signer::address_of(treasury_signer);
        assert!(treasury_addr == stake_fa_config::get_treasury_admin_address(), error::permission_denied(ERR_NOT_TREASURY));
        
        let resource_signer = get_module_resource_signer();
        let resource_addr = signer::address_of(&resource_signer);
        let config = borrow_global<GlobalConfig>(resource_addr); 

        let pools_manager = borrow_global_mut<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow_mut(&mut pools_manager.pools, pool_key);

        if (!is_emergency_inner(pool)) {
            assert!(is_finished_inner(pool), error::invalid_state(ERR_NOT_WITHDRAW_PERIOD));
            let withdraw_allowed_after = pool.end_timestamp + config.treasury_withdraw_grace_period_seconds;
            assert!(withdraw_allowed_after > pool.end_timestamp, error::out_of_range(ERR_DURATION_OVERFLOW));
            assert!(timestamp::now_seconds() >= withdraw_allowed_after, error::invalid_state(ERR_NOT_WITHDRAW_PERIOD));
        };

        let withdrawn_reward_assets = fungible_asset::withdraw(
            &resource_signer,
            pool.reward_store,
            amount
        );

        event::emit_event<TreasuryWithdrawalEvent>(
            &mut pool.treasury_withdrawal_event,
            TreasuryWithdrawalEvent {
                pool_key,
                treasury_address: treasury_addr,
                amount,
            }
        );

        withdrawn_reward_assets
    }
    
    ////////ADMIN FUNCTIONS//////////////
    public entry fun set_normal_pool_lockup_duration(
        admin_signer: &signer,
        new_duration: u64
    ) acquires GlobalConfig, AdminConfig, ModuleSignerStorage {
        assert_is_current_admin(admin_signer);
        assert!(
            new_duration >= MIN_NORMAL_POOL_LOCKUP_SECONDS && new_duration <= MAX_NORMAL_POOL_LOCKUP_SECONDS,
            error::invalid_argument(ERR_INVALID_CONFIG_VALUE)
        );

        let module_admin_account_addr = MODULE_ADMIN_ACCOUNT;
        let module_storage = borrow_global_mut<ModuleSignerStorage>(module_admin_account_addr);
        let resource_addr = module_storage.resource_address;

        let config = borrow_global_mut<GlobalConfig>(resource_addr);
        config.normal_pool_lockup_seconds = new_duration;

        event::emit_event<ConfigParameterUpdatedEvent>(
            &mut module_storage.config_parameter_updated_events,
            ConfigParameterUpdatedEvent  {
                admin_address: signer::address_of(admin_signer),
                parameter_name: string::utf8(b"normal_pool_lockup_seconds"),
                new_value_u64: new_duration,
                new_value_address: option::none(),
            }
        );
    }

    public entry fun set_treasury_withdraw_grace_period(
        admin_signer: &signer,
        new_period: u64
    ) acquires GlobalConfig, ModuleSignerStorage, AdminConfig {
        assert_is_current_admin(admin_signer);
        assert!(
            new_period >= MIN_TREASURY_GRACE_PERIOD_SECONDS && new_period <= MAX_TREASURY_GRACE_PERIOD_SECONDS,
            error::invalid_argument(ERR_INVALID_CONFIG_VALUE) 
        );

        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        let config = borrow_global_mut<GlobalConfig>(resource_addr);
        config.treasury_withdraw_grace_period_seconds = new_period;

        let module_signer_storage = borrow_global_mut<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT);
        event::emit_event<ConfigParameterUpdatedEvent>(
            &mut module_signer_storage.config_parameter_updated_events,
            ConfigParameterUpdatedEvent {
                admin_address: signer::address_of(admin_signer),
                parameter_name: string::utf8(b"treasury_withdraw_grace_period_seconds"),
                new_value_u64: new_period,
                new_value_address: option::none(),
             }
        );
    }

    public entry fun set_pool_registration_fee(
        admin_signer: &signer,
        new_fee_amount: u64,
        new_fee_treasury_address: address
    ) acquires GlobalConfig, AdminConfig, ModuleSignerStorage {
 
        assert_is_current_admin(admin_signer);

        let module_admin_account_addr = MODULE_ADMIN_ACCOUNT;
        let module_storage = borrow_global_mut<ModuleSignerStorage>(module_admin_account_addr);
        let resource_addr = module_storage.resource_address;

        let config = borrow_global_mut<GlobalConfig>(resource_addr);
        config.pool_registration_fee_amount = new_fee_amount;
        config.fee_treasury_address = new_fee_treasury_address;

        event::emit_event<ConfigParameterUpdatedEvent>(
            &mut module_storage.config_parameter_updated_events,
            ConfigParameterUpdatedEvent  {
                admin_address: signer::address_of(admin_signer),
                parameter_name: string::utf8(b"pool_registration_fee"),
                new_value_u64: new_fee_amount,
                new_value_address: option::some(new_fee_treasury_address),
            }
        );
    }

    public entry fun propose_new_admin(
        current_admin_signer: &signer,
        new_candidate_addr: address
    ) acquires AdminConfig, ModuleSignerStorage {
        assert_is_current_admin(current_admin_signer);

        let module_admin_account_addr = MODULE_ADMIN_ACCOUNT;
        let module_storage = borrow_global_mut<ModuleSignerStorage>(module_admin_account_addr);
        let resource_addr = module_storage.resource_address;

        let admin_config = borrow_global_mut<AdminConfig>(resource_addr);

        assert!(new_candidate_addr != admin_config.current_admin, error::invalid_argument(ERR_CANNOT_TRANSFER_TO_SELF));
        assert!(new_candidate_addr != @0x0, error::invalid_argument(ERR_INVALID_CONFIG_VALUE));

        let old_admin_val = admin_config.current_admin;
        admin_config.pending_admin_candidate = option::some(new_candidate_addr);

        event::emit_event<AdminProposedEvent>(
            &mut module_storage.admin_proposed_events,
            AdminProposedEvent {
                old_admin: old_admin_val,
                new_admin_candidate: new_candidate_addr,
            }
        );
    }

    public entry fun accept_admin_role(
        candidate_signer: &signer
    ) acquires AdminConfig, ModuleSignerStorage {
        let candidate_addr = signer::address_of(candidate_signer);
        let module_admin_account_addr = MODULE_ADMIN_ACCOUNT;
        let module_storage = borrow_global_mut<ModuleSignerStorage>(module_admin_account_addr);
        let resource_addr = module_storage.resource_address;

        let admin_config = borrow_global_mut<AdminConfig>(resource_addr);

        assert!(option::is_some(&admin_config.pending_admin_candidate), error::invalid_state(ERR_NO_PENDING_ADMIN_TRANSFER));
        let pending_admin = *option::borrow(&admin_config.pending_admin_candidate); 
        assert!(candidate_addr == pending_admin, error::permission_denied(ERR_NOT_THE_PENDING_ADMIN));

        let old_admin = admin_config.current_admin;
        admin_config.current_admin = candidate_addr;
        admin_config.pending_admin_candidate = option::none();

        event::emit_event<AdminTransferredEvent>(
            &mut module_storage.admin_transferred_events,
            AdminTransferredEvent {
                old_admin: old_admin,
                new_admin: candidate_addr,
            }
        );
    }

    // --- Getter functions ---
    #[view]
    public fun get_start_timestamp(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        // Construir PoolIdentifier localmente
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        pool.start_timestamp
    }

    #[view]
    /// Checks if a specific pool is configured for NFT boosting.
    public fun is_boostable(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        ); 
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        
        let pool = table::borrow(&pools_manager.pools, pool_key);
        option::is_some(&pool.nft_boost_config)
    }

    #[view]
    /// Panics if the pool is not boostable or does not exist.
    public fun get_boost_config(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): (address, String, u128) acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);

        assert!(option::is_some(&pool.nft_boost_config), ERR_NON_BOOST_POOL);
        let boost_config = option::borrow(&pool.nft_boost_config);
        (boost_config.collection_owner, boost_config.collection_name, boost_config.boost_percent)
    }

    #[view]
    /// Checks if reward distribution has finished for a specific pool.
    public fun is_finished(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        is_finished_inner(pool)
    }

    #[view]
    /// Gets timestamp when reward distribution will be finished for a specific pool.
    public fun get_end_timestamp(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        pool.end_timestamp
    }

    #[view]
    /// Checks if a pool with the given `PoolIdentifier` exists under the `resource_addr`.
    public fun pool_exists(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        if (!exists<PoolsManager>(resource_addr)) {
            return false
        };
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        table::contains(&pools_manager.pools, pool_key)
    }

    #[view]
    /// Checks if a stake exists for a user in a specific pool.
    public fun stake_exists(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        if (!exists<PoolsManager>(resource_addr)) {
            return false
        };
        if (!table::contains(&pools_manager.pools, pool_key)) {
            return false
        };
        let pool = table::borrow(&pools_manager.pools, pool_key);
        table::contains(&pool.stakes, user_addr)
    }

    #[view]
    public fun get_pool_total_stake(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        fungible_asset::balance(pool.stake_store)
    }

    #[view]
    public fun get_pool_total_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): u128 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        pool.total_boosted
    }

    #[view]
    public fun get_user_stake_or_zero(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        if (!exists<PoolsManager>(resource_addr)) {
            return 0
        };
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        if (!table::contains(&pools_manager.pools, pool_key)) {
            return 0
        };
        let pool = table::borrow(&pools_manager.pools, pool_key);
        if (!table::contains(&pool.stakes, user_addr)) {
            return 0
        };
        let user_stake = table::borrow(&pool.stakes, user_addr);
        user_stake.amount
    }

    #[view]
    /// Panics if pool or stake does not exist.
    public fun is_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));
        let user_stake = table::borrow(&pool.stakes, user_addr);
        option::is_some(&user_stake.nft)
    }
    
    #[view]
    /// Panics if pool or stake does not exist.
    public fun get_user_boosted(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u128 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));
        let user_stake = table::borrow(&pool.stakes, user_addr);
        user_stake.boosted_amount
    }

    #[view]
    /// Checks current pending user reward in specific pool.
    public fun get_pending_user_rewards(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        let user_stake = table::borrow(&pool.stakes, user_addr);
        
        let current_pool_accum_reward = pool.accum_reward;
        let time_now_for_calc = get_time_for_last_update(pool);
        if (time_now_for_calc > pool.last_updated) {
            let delta_accum = accum_rewards_since_last_updated(pool, time_now_for_calc);
            if (delta_accum > 0) {
                if (current_pool_accum_reward > MAX_U128 - delta_accum) {
                    current_pool_accum_reward = MAX_U128
                } else {
                    current_pool_accum_reward = current_pool_accum_reward + delta_accum;
                };
            };
        };
        let user_current_stake_raw_with_boost = user_stake_amount_with_boosted(user_stake);
        let pending_scaled_points = 0u128;

        if (user_current_stake_raw_with_boost > 0) {
            if (current_pool_accum_reward > 0 && (MAX_U128 / current_pool_accum_reward < user_current_stake_raw_with_boost)) {
                return MAX_U64
            };
            let total_entitlement_points = current_pool_accum_reward * user_current_stake_raw_with_boost;

            if (total_entitlement_points >= user_stake.reward_points_debt) {
                pending_scaled_points = total_entitlement_points - user_stake.reward_points_debt;
            }
        };

        let already_earned_unscaled_u128 = (user_stake.earned_reward as u128);
        let newly_pending_unscaled_u128 = pending_scaled_points / ACCUM_REWARD_SCALE;
        let total_pending_unscaled_u128 = already_earned_unscaled_u128 + newly_pending_unscaled_u128;

        if (total_pending_unscaled_u128 >= (MAX_U64 as u128)) {
            MAX_U64
        } else {
            (total_pending_unscaled_u128 as u64)
        }
    }

    #[view]
    /// Checks stake unlock time in specific pool.
    public fun get_unlock_time(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): u64 acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        assert!(table::contains(&pool.stakes, user_addr), error::not_found(ERR_NO_STAKE));

        let user_stake = table::borrow(&pool.stakes, user_addr);
        math64::min(pool.end_timestamp, user_stake.unlock_time)
    }

    #[view]
    /// Checks if stake is unlocked.
    public fun is_unlocked(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
        user_addr: address
    ): bool acquires PoolsManager, ModuleSignerStorage {
        timestamp::now_seconds() >= get_unlock_time(
            pool_creator_addr,
            stake_addr,
            reward_addr,
            user_addr
        )
    }

    #[view]
    /// Checks whether a specific pool is in an "emergency state" (local or global).
    public fun is_emergency(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        is_emergency_inner(pool)
    }

    #[view]
    /// Checks whether a specific pool has its local "emergency state" enabled.
    public fun is_local_emergency(
        pool_creator_addr: address,
        stake_addr: address,
        reward_addr: address,
    ): bool acquires PoolsManager, ModuleSignerStorage {
        let pool_key = new_pool_identifier(
            pool_creator_addr,
            stake_addr,
            reward_addr
        );
        let resource_addr = get_module_resource_address();
        let pools_manager = borrow_global<PoolsManager>(resource_addr);
        assert!(table::contains(&pools_manager.pools, pool_key), error::not_found(ERR_NO_POOL));
        let pool = table::borrow(&pools_manager.pools, pool_key);
        pool.emergency_locked
    }

    #[view]
    public fun get_module_resource_address(): address acquires ModuleSignerStorage {
        borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address
    }

    #[view]
    public fun new_pool_identifier(
        creator_addr: address,
        stake_addr: address,
        reward_addr: address
    ): PoolIdentifier {
        PoolIdentifier {
            creator_addr,
            stake_addr,
            reward_addr,
        }
    }

    #[view]
    public fun get_normal_pool_lockup_duration(): u64 acquires GlobalConfig, ModuleSignerStorage {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        borrow_global<GlobalConfig>(resource_addr).normal_pool_lockup_seconds
    }

    #[view]
    public fun get_dynamic_pool_lockup_duration(): u64 acquires GlobalConfig, ModuleSignerStorage {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        borrow_global<GlobalConfig>(resource_addr).dynamic_pool_lockup_seconds
    }

    #[view]
    public fun get_treasury_withdraw_grace_period(): u64 acquires GlobalConfig, ModuleSignerStorage {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        borrow_global<GlobalConfig>(resource_addr).treasury_withdraw_grace_period_seconds
    }

    #[view]
    public fun get_current_admin(): address acquires AdminConfig, ModuleSignerStorage {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        borrow_global<AdminConfig>(resource_addr).current_admin
    }

    #[view]
    public fun get_pending_admin_candidate(): Option<address> acquires AdminConfig, ModuleSignerStorage {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        let admin_config = borrow_global<AdminConfig>(resource_addr);
        if (option::is_some(&admin_config.pending_admin_candidate)) {
            option::some(*option::borrow(&admin_config.pending_admin_candidate))
        } else {
            option::none()
        }
    }

    #[view]
    public fun get_pool_registration_fee_config(): (u64, address)
        acquires GlobalConfig, ModuleSignerStorage
    {
        let resource_addr = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT).resource_address;
        let config = borrow_global<GlobalConfig>(resource_addr);
        (config.pool_registration_fee_amount, config.fee_treasury_address)
    }

    #[view]
    public fun get_metadata(address: address): (String, String, u8) {
        assert!(object::is_object(address), 1);
        let metadata = object::address_to_object<fungible_asset::Metadata>(address);
        (
            fungible_asset::name(metadata),
            fungible_asset::symbol(metadata),
            fungible_asset::decimals(metadata)
        )
    }

    // PRIVATE FUNCTIONS
    /// Checks if the caller is the current admin.
    fun get_module_resource_signer(): signer acquires ModuleSignerStorage {
        let signer_storage = borrow_global<ModuleSignerStorage>(MODULE_ADMIN_ACCOUNT);
        account::create_signer_with_capability(&signer_storage.signer_cap)
    }

    /// Checks if local pool or global emergency enabled.
    fun is_emergency_inner(pool: &StakePoolData): bool {
        pool.emergency_locked || stake_fa_config::is_global_emergency()
    }

    /// Internal function to check if harvest finished on the pool.
    fun is_finished_inner(pool: &StakePoolData): bool {
        timestamp::now_seconds() >= pool.end_timestamp
    }

    /// Calculates pool accumulated reward points, updating pool state.
    fun update_accum_reward(pool: &mut StakePoolData) {
        let current_time = get_time_for_last_update(pool);
        if (current_time <= pool.last_updated) {
            return
        };

        let new_accum_rewards = accum_rewards_since_last_updated(pool, current_time);
        pool.last_updated = current_time;
        if (new_accum_rewards > 0) {
            assert!(pool.accum_reward <= MAX_U128 - new_accum_rewards, error::out_of_range(ERR_ACCUM_REWARD_ADD_OVERFLOW));
            pool.accum_reward = pool.accum_reward + new_accum_rewards;
        };
    }

    /// Calculates accumulated reward points since last update without modifying the pool.
    fun accum_rewards_since_last_updated(pool: &StakePoolData, current_time: u64): u128 {
        if (current_time <= pool.last_updated) return 0;
        let seconds_passed = current_time - pool.last_updated;
        if (seconds_passed == 0) return 0;

        let total_effective_stake = pool_total_staked_with_boosted(pool);
        
        if (total_effective_stake == 0 || pool.reward_per_sec == 0) {
            return 0
        };

        if (seconds_passed > 0 && pool.reward_per_sec > 0 && (MAX_U128 / pool.reward_per_sec < (seconds_passed as u128) )) {
             assert!(false, error::out_of_range(ERR_MUL_OVERFLOW_IN_ACCUM_REWARD_UPDATE));
        };
        //let total_rewards_emission = (pool.reward_per_sec as u128) * (seconds_passed as u128);
        //(total_rewards_emission * pool.scale) / total_effective_stake
        math128::mul_div(pool.reward_per_sec, (seconds_passed as u128), total_effective_stake)
    }

    fun update_user_reward_state(pool_accum_reward: u128, user_stake: &mut UserStake): u128 {
        let user_current_stake_raw_with_boost = user_stake_amount_with_boosted(user_stake);
        let pending_scaled_points = 0u128;
        let current_total_entitlement_points = 0u128;

        if (user_current_stake_raw_with_boost > 0) {
            if (pool_accum_reward > 0 && (MAX_U128 / pool_accum_reward < user_current_stake_raw_with_boost)) {
                assert!(false, error::out_of_range(ERR_REWARD_DEBT_CALC_OVERFLOW));
            };
            current_total_entitlement_points = pool_accum_reward * user_current_stake_raw_with_boost;

            assert!(current_total_entitlement_points >= user_stake.reward_points_debt, error::invalid_state(ERR_NEGATIVE_PENDING_REWARD));
            pending_scaled_points = current_total_entitlement_points - user_stake.reward_points_debt;
        };

        if (pending_scaled_points > 0) {
            let reward_to_add_unscaled = pending_scaled_points / ACCUM_REWARD_SCALE;
            if (reward_to_add_unscaled > 0) {
                let new_total_earned_u128 = (user_stake.earned_reward as u128) + reward_to_add_unscaled;
                user_stake.earned_reward = if (new_total_earned_u128 >= (MAX_U64 as u128)) {
                    MAX_U64
                } else {
                    (new_total_earned_u128 as u64)
                };
            }
        };

        user_stake.reward_points_debt = current_total_entitlement_points;
        pending_scaled_points
    }

    /// Get effective time for last pool update (capped at end_timestamp).
    fun get_time_for_last_update(pool: &StakePoolData): u64 {
        math64::min(pool.end_timestamp, timestamp::now_seconds())
    }

    /// Get total effective staked amount (staked assets + virtual boosted amount) in the pool.
    fun pool_total_staked_with_boosted(pool: &StakePoolData): u128 {
        (fungible_asset::balance(pool.stake_store) as u128) + pool.total_boosted
    }

    /// Get user's effective stake amount (staked assets + virtual boosted amount).
    fun user_stake_amount_with_boosted(user_stake: &UserStake): u128 {
        (user_stake.amount as u128) + user_stake.boosted_amount
    }

    fun get_effective_unlock_time(pool: &StakePoolData, user_stake: &UserStake): u64 {
        math64::min(pool.end_timestamp, user_stake.unlock_time)
    }

    fun assert_is_current_admin(admin_signer: &signer) acquires AdminConfig, ModuleSignerStorage {
        let module_admin_account_addr = MODULE_ADMIN_ACCOUNT;
        let resource_addr = borrow_global<ModuleSignerStorage>(module_admin_account_addr).resource_address;
        let admin_config = borrow_global<AdminConfig>(resource_addr);
        assert!(signer::address_of(admin_signer) == admin_config.current_admin, error::permission_denied(ERR_NOT_AUTHORIZED));
    }
}

