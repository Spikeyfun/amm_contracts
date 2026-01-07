module spike_amm::amm_controller {

  #[view]
  public fun get_signer_address(): address {
      abort 0
  }

  #[view]
  public fun get_swap_fee(): u8 {
      abort 0
  }

  #[view]
  public fun get_fee_to(): address {
      abort 0
  }

  #[view]
  public fun get_admin(): address {
      abort 0
  }

  #[view]
  public fun get_fee_on(): address {
      abort 0
  }

  #[view]
  public fun get_flash_loan_fee_bps(): u64 {
      abort 0
  }

  public fun assert_paused() {
      abort 0
  }

  public fun assert_unpaused() {
      abort 0
  }

}