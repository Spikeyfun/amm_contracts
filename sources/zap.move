module spike_amm::amm_zap {

  #[view]
  public fun is_initialized(): bool {
      abort 0
  }

  /*
  * @notice Zap SUPRA in a SUPRA pool (e.g. SUPRA/token)
  * @param _lpToken: LP token address (e.g. RZR/SUPRA)
  * @param _tokenAmountOutMin: minimum token amount (e.g. RZR) to receive in the intermediary swap (e.g. SUPRA --> RZR)
  */
  public entry fun zap_in_supra(
    _sender: &signer,
    _lp_token: address,
    _amount_in: u64,
    _token_amount_out_min: u64,
  ) {
      abort 0
  }

  /*
  * @notice Zap a token in (e.g. token/other token)
  * @param _tokenToZap: token to zap
  * @param _tokenAmountIn: amount of token to swap
  * @param _lpToken: LP token address (e.g. RZR/USDT)
  * @param _tokenAmountOutMin: minimum token to receive (e.g. RZR) in the intermediary swap (e.g. USDT --> RZR)
  */
  public entry fun zap_in_token(
    _sender: &signer,
    _token_to_zap: address,
    _token_amount_in: u64,
    _lp_token: address,
    _token_amount_out_min: u64,
  ) {
      abort 0
  }

  /*
  * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
  * @param _token0ToZap: address of token0 to zap
  * @param _token1ToZap: address of token1 to zap
  * @param _token0AmountIn: amount of token0 to zap
  * @param _token1AmountIn: amount of token1 to zap
  * @param _lpToken: LP token address (token0/token1)
  * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
  * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
  * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
  */
  public entry fun zap_in_token_rebalancing(
    _sender: &signer,
    _token0_to_zap: address,
    _token1_to_zap: address,
    _token0_amount_in: u64,
    _token1_amount_in: u64,
    _lp_token: address,
    _token_amount_in_max: u64,
    _token_amount_out_min: u64,
    _is_token0_sold: bool,
  ) {
      abort 0
  }

  public entry fun zap_in_supra_rebalancing(
    _sender: &signer,
    _token1_to_zap: address,
    _supra_amount_in: u64,
    _token1_amount_in: u64,
    _lp_token: address,
    _token_amount_in_max: u64,
    _token_amount_out_min: u64,
    _is_token0_sold: bool,
  ) {
      abort 0
  }

  public entry fun zap_out_supra(
    _sender: &signer,
    _lp_token: address,
    _lp_token_amount: u64,
    _token_amount_out_min: u64,
  ) {
      abort 0
  }

  public entry fun zap_out_token(
    _sender: &signer,
    _lp_token: address,
    _token_to_receive: address,
    _lp_token_amount: u64,
    _token_amount_out_min: u64,
  ) {
      abort 0
  }

  public entry fun update_max_zap_reserve_ratio(
    _sender: &signer,
    _max_zap_reserve_ratio: u64,
  ) {
      abort 0
  }

  #[view]
  public fun estimate_zap_in_swap(
    _token_to_zap: address,
    _token_amount_in: u64,
    _lp_token: address
  ): (u64, u64, address) {
      abort 0
  }

  #[view]
  public fun estimate_zap_in_rebalancing_swap(
    _token0_to_zap: address,
    _token1_to_zap: address,
    _token0_amount_in: u64,
    _token1_amount_in: u64,
    _lp_token: address,
  ): (u64, u64, bool) {
      abort 0
  }

  #[view]
  public fun estimate_zap_out_swap(
    _lp_token: address,
    _lp_token_amount: u64,
    _token_to_receive: address,
  ): (u64, u64, address) {
      abort 0
  }

}