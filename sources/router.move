module spike_amm::amm_router {
    use supra_framework::object::{Object};
    use supra_framework::fungible_asset::{FungibleAsset, Metadata};

    native public entry fun wrap_coin<CoinType>(
        sender: &signer,
        amount: u64
    );

    native public entry fun wrap_supra(
        sender: &signer,
        amount: u64,
    );
 
    native public entry fun unwrap_beta<CoinType>(
        sender: &signer,
        to: address,
        amount: u64
    );

    native public entry fun add_liquidity(
        sender: &signer,
        tokenA: address,
        tokenB: address,
        amountADesired: u64,
        amountBDesired: u64,
        amountAMin: u64,
        amountBMin: u64,
        to: address,
        deadline: u64
    );

    native public fun add_liquidity_aux(
        sender: &signer,
        tokenA: address,
        tokenB: address,
        amountADesired: u64,
        amountBDesired: u64,
        amountAMin: u64,
        amountBMin: u64,
        to: address,
        deadline: u64
    ): (u64, u64, u64, Object<Metadata>);

    native public entry fun add_liquidity_supra(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_supra_desired: u64,
        amount_supra_min: u64,
        to: address,
        deadline: u64
    );

    native public fun add_liquidity_supra_aux(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_supra_desired: u64,
        amount_supra_min: u64,
        to: address,
        deadline: u64
    ): (u64, u64, u64, Object<Metadata>);

    native public entry fun add_liquidity_coin<CoinType>(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_coin_desired: u64,
        amount_coin_min: u64,
        to: address,
        deadline: u64
    );

    native public fun add_liquidity_coin_aux<CoinType>(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_coin_desired: u64,
        amount_coin_min: u64,
        to: address,
        deadline: u64
    ): (u64, u64, u64, Object<Metadata>);

    native public entry fun add_liquidity_coin_beta<CoinType>(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_coin_desired: u64,
        amount_coin_min: u64,
        to: address,
        deadline: u64
    );

    native public fun add_liquidity_coin_aux_beta<CoinType>(
        sender: &signer,
        token: address,
        amount_token_desired: u64,
        amount_token_min: u64,
        amount_coin_desired: u64,
        amount_coin_min: u64,
        to: address,
        deadline: u64
    ) : (u64, u64, u64, Object<Metadata>);

    native public entry fun add_liquidity_coins_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        amountA_coin_desired: u64,
        amountA_coin_min: u64,
        amountB_coin_desired: u64,
        amountB_coin_min: u64,
        to: address,
        deadline: u64
    );
    
    native public fun add_liquidity_coins_aux_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        amountA_coin_desired: u64,
        amountA_coin_min: u64,
        amountB_coin_desired: u64,
        amountB_coin_min: u64,
        to: address,
        deadline: u64
    ) : (u64, u64, u64, Object<Metadata>);

    native public entry fun remove_liquidity(
        sender: &signer,
        tokenA: address,
        tokenB: address,
        liquidity: u64,
        amountAMin: u64,
        amountBMin: u64,
        to: address,
        deadline: u64
    );

    native public fun remove_liquidity_aux(
        sender: &signer,
        tokenA: address,
        tokenB: address,
        liquidity: u64,
        amountAMin: u64,
        amountBMin: u64,
        to: address,
        deadline: u64
    ): (u64, u64);

    native public entry fun remove_liquidity_supra(
        sender: &signer,
        token: address,
        liquidity: u64,
        amount_token_min: u64,
        amount_supra_min: u64,
        to: address,
        deadline: u64
    );

    native public fun remove_liquidity_supra_aux(
        sender: &signer,
        token: address,
        liquidity: u64,
        amount_token_min: u64,
        amount_supra_min: u64,
        to: address,
        deadline: u64
    ): (u64, u64);

    native public entry fun remove_liquidity_coin_beta<CoinType>(
        sender: &signer,
        token: address,
        liquidity: u64,
        amount_token_min: u64,
        amount_coin_min: u64,
    );

    native public fun remove_liquidity_coin_aux_beta<CoinType>(
        sender: &signer,
        token: address,
        liquidity: u64,
        amount_token_min: u64,
        amount_coin_min: u64,
    ): (u64, u64);

    native public entry fun remove_liquidity_coins_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        liquidity: u64,
        amount_coin_A_min: u64,
        amount_coin_B_min: u64,
        deadline: u64
    );
    
    native public fun remove_liquidity_coins_aux_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        liquidity: u64,
        amount_coin_A_min: u64,
        amount_coin_B_min: u64,
        deadline: u64
    ) : (u64, u64);

    // SWAP 

    native public fun swap(
        sender: &signer,
        token_in: FungibleAsset,
        to_token: Object<Metadata>,
        to: address,
    ): FungibleAsset;


    native public entry fun swap_exact_tokens_for_tokens(
        sender: &signer,
        amount_in: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );

    native public entry fun swap_exact_coin_for_tokens_beta<CoinType>(
        sender: &signer,
        amount_in: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );


    native public entry fun swap_tokens_for_exact_tokens(
        sender: &signer,
        amount_out: u64,
        amount_in_coin_max: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );

    native public entry fun swap_coin_for_exact_tokens_beta<CoinType>(
        sender: &signer,
        amount_out: u64,
        amount_in_coin_max: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );


    native public entry fun swap_supra_for_exact_tokens(
        sender: &signer,
        amount_supra_max: u64,
        amount_out: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );

    native public entry fun swap_supra_for_exact_tokens_beta(
        sender: &signer,
        amount_supra_max: u64,
        amount_out: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );


    native public entry fun swap_exact_supra_for_tokens(
        sender: &signer,
        amount_supra: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );

    native public entry fun swap_exact_supra_for_tokens_beta(
        sender: &signer,
        amount_supra: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );


    native public entry fun swap_tokens_for_exact_supra(
        sender: &signer,
        amount_out: u64,
        amount_in_max: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );


    native public entry fun swap_tokens_for_exact_supra_beta(
        sender: &signer,
        amount_out: u64,
        amount_in_max: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );


    native public entry fun swap_exact_tokens_for_supra(
        sender: &signer,
        amount_in: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );

    native public entry fun swap_exact_tokens_for_supra_beta(
        sender: &signer,
        amount_in: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );

    native public entry fun swap_exact_coin_for_tokens<CoinType>(
        sender: &signer,
        amount_coin: u64,
        amount_out_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );

    native public entry fun swap_coin_for_exact_tokens<CoinType>(
        sender: &signer,
        amount_coin_max: u64,
        amount_out: u64,
        path: vector<address>,
        to: address,
        deadline: u64,
    );
    
    native public entry fun swap_exact_coins_for_coins_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        amount_in_coin: u64,
        amount_out_coin_min: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );

    native public entry fun swap_coins_for_exact_coins_beta<CoinType_A, CoinType_B>(
        sender: &signer,
        amount_out_coin: u64,
        amount_in_coin_max: u64,
        path: vector<address>,
        to: address,
        deadline: u64
    );

    #[view]
    native public fun get_address_BWSUP(): address;

    #[view]
    native public fun view_remove_liquidity(
        tokenA: address,
        tokenB: address,
        liquidity: u64
    ): (u64, u64);

    #[view]
    native public fun get_amounts_out(
        amount_in: u64,
        path: vector<Object<Metadata>>,
    ): vector<u64>;

    #[view]
    native public fun get_amounts_in(
        amount_out: u64,
        path: vector<Object<Metadata>>,
    ): vector<u64>;
}
