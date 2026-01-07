module spike_amm::oracle_library {
  use supra_framework::object::Object;
  use spike_amm::amm_pair::{Pair};

  #[view]
  public fun current_block_timestamp(): u64 {
      abort 0
  }

  #[view]
  public fun current_cumulative_prices(_pair: Object<Pair>): (u128, u128, u64) {
      abort 0
  }
}