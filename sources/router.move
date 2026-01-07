module spike_amm::amm_router {
    use supra_framework::object::{Object};
    use supra_framework::fungible_asset::{FungibleAsset, Metadata};

    public entry fun wrap_coin<CoinType>(
        _sender: &signer,
        _amount: u64
    ) {
        abort 0
    }

    public entry fun wrap_supra(
        _sender: &signer,
        _amount: u64,
    ) {
        abort 0
    }
 
    public entry fun unwrap_beta<CoinType>(
        _sender: &signer,
        _to: address,
        _amount: u64
    ) {
        abort 0
    }
    
    public fun create_locked_pair_for_launchpad(
        _sender: &signer,
        _tokenA: address,
        _tokenB: address
    ) {
        abort 0
    }

    public fun add_liquidity_from_launchpad_aux_beta(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_supra_desired: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    fun add_liquidity_from_launchpad_beta(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_supra_desired: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public entry fun add_liquidity(
        _sender: &signer,
        _tokenA: address,
        _tokenB: address,
        _amountADesired: u64,
        _amountBDesired: u64,
        _amountAMin: u64,
        _amountBMin: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun add_liquidity_aux(
        _sender: &signer,
        _tokenA: address,
        _tokenB: address,
        _amountADesired: u64,
        _amountBDesired: u64,
        _amountAMin: u64,
        _amountBMin: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    public entry fun add_liquidity_supra(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_supra_desired: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun add_liquidity_supra_aux(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_supra_desired: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    public entry fun add_liquidity_coin<CoinType>(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_coin_desired: u64,
        _amount_coin_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun add_liquidity_coin_aux<CoinType>(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_coin_desired: u64,
        _amount_coin_min: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    public entry fun add_liquidity_coin_beta<CoinType>(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_coin_desired: u64,
        _amount_coin_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun add_liquidity_coin_aux_beta<CoinType>(
        _sender: &signer,
        _token: address,
        _amount_token_desired: u64,
        _amount_token_min: u64,
        _amount_coin_desired: u64,
        _amount_coin_min: u64,
        _to: address,
        _deadline: u64
    ) : (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    public entry fun add_liquidity_coins_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _amountA_coin_desired: u64,
        _amountA_coin_min: u64,
        _amountB_coin_desired: u64,
        _amountB_coin_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }
    
    public fun add_liquidity_coins_aux_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _amountA_coin_desired: u64,
        _amountA_coin_min: u64,
        _amountB_coin_desired: u64,
        _amountB_coin_min: u64,
        _to: address,
        _deadline: u64
    ) : (u64, u64, u64, Object<Metadata>) {
        abort 0
    }

    public entry fun remove_liquidity(
        _sender: &signer,
        _tokenA: address,
        _tokenB: address,
        _liquidity: u64,
        _amountAMin: u64,
        _amountBMin: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun remove_liquidity_aux(
        _sender: &signer,
        _tokenA: address,
        _tokenB: address,
        _liquidity: u64,
        _amountAMin: u64,
        _amountBMin: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64) {
        abort 0
    }

    public entry fun remove_liquidity_supra(
        _sender: &signer,
        _token: address,
        _liquidity: u64,
        _amount_token_min: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public fun remove_liquidity_supra_aux(
        _sender: &signer,
        _token: address,
        _liquidity: u64,
        _amount_token_min: u64,
        _amount_supra_min: u64,
        _to: address,
        _deadline: u64
    ): (u64, u64) {
        abort 0
    }

    public entry fun remove_liquidity_coin_beta<CoinType>(
        _sender: &signer,
        _token: address,
        _liquidity: u64,
        _amount_token_min: u64,
        _amount_coin_min: u64,
    ) {
        abort 0
    }

    public fun remove_liquidity_coin_aux_beta<CoinType>(
        _sender: &signer,
        _token: address,
        _liquidity: u64,
        _amount_token_min: u64,
        _amount_coin_min: u64,
    ): (u64, u64) {
        abort 0
    }

    public entry fun remove_liquidity_coins_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _liquidity: u64,
        _amount_coin_A_min: u64,
        _amount_coin_B_min: u64,
        _deadline: u64
    ) {
        abort 0
    }
    
    public fun remove_liquidity_coins_aux_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _liquidity: u64,
        _amount_coin_A_min: u64,
        _amount_coin_B_min: u64,
        _deadline: u64
    ) : (u64, u64) {
        abort 0
    }

    //MASTER SWAP FUNCTION
    public fun swap(
        _sender: &signer,
        _token_in: FungibleAsset,
        _to_token: Object<Metadata>,
        _to: address,
    ): FungibleAsset {
        abort 0
    }

    //SWAP FUNCTIONS FUNGIBLE ASSETS
    public entry fun swap_exact_tokens_for_tokens(
        _sender: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public entry fun swap_exact_coin_for_tokens_beta<CoinType>(
        _sender: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }


    public entry fun swap_tokens_for_exact_tokens(
        _sender: &signer,
        _amount_out: u64,
        _amount_in_coin_max: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public entry fun swap_coin_for_exact_tokens_beta<CoinType>(
        _sender: &signer,
        _amount_out: u64,
        _amount_in_coin_max: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }


    public entry fun swap_supra_for_exact_tokens(
        _sender: &signer,
        _amount_supra_max: u64,
        _amount_out: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }

    public entry fun swap_supra_for_exact_tokens_beta(
        _sender: &signer,
        _amount_supra_max: u64,
        _amount_out: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }


    public entry fun swap_exact_supra_for_tokens(
        _sender: &signer,
        _amount_supra: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }

    public entry fun swap_exact_supra_for_tokens_beta(
        _sender: &signer,
        _amount_supra: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }


    public entry fun swap_tokens_for_exact_supra(
        _sender: &signer,
        _amount_out: u64,
        _amount_in_max: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }


    public entry fun swap_tokens_for_exact_supra_beta(
        _sender: &signer,
        _amount_out: u64,
        _amount_in_max: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }


    public entry fun swap_exact_tokens_for_supra(
        _sender: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }

    public entry fun swap_exact_tokens_for_supra_beta(
        _sender: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }

    public entry fun swap_exact_coin_for_tokens<CoinType>(
        _sender: &signer,
        _amount_coin: u64,
        _amount_out_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }

    public entry fun swap_coin_for_exact_tokens<CoinType>(
        _sender: &signer,
        _amount_coin_max: u64,
        _amount_out: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64,
    ) {
        abort 0
    }
    
    public entry fun swap_exact_coins_for_coins_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _amount_in_coin: u64,
        _amount_out_coin_min: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    public entry fun swap_coins_for_exact_coins_beta<CoinType_A, CoinType_B>(
        _sender: &signer,
        _amount_out_coin: u64,
        _amount_in_coin_max: u64,
        _path: vector<address>,
        _to: address,
        _deadline: u64
    ) {
        abort 0
    }

    #[view]
    public fun get_address_BWSUP(): address {
        abort 0
    }

    #[view]
    public fun view_remove_liquidity(
        _tokenA: address,
        _tokenB: address,
        _liquidity: u64
    ): (u64, u64) {
        abort 0
    }

    #[view]
    public fun get_amounts_out(
        _amount_in: u64,
        _path: vector<Object<Metadata>>,
    ): vector<u64> {
        abort 0
    }

    #[view]
    public fun get_amounts_in(
        _amount_out: u64,
        _path: vector<Object<Metadata>>,
    ): vector<u64> {
        abort 0
    }
}