/// # Spike Price Aggregator
///
/// This module leverages the **Supra Oracle** to fetch reliable USD price data.  
/// It is designed to work seamlessly with both **legacy tokens** and the **AMM tokens of Spike (amm.spikey.fun)**.
///
/// ## Return values
/// Each function returns a **tuple (u128, u16)**:
/// - The first value (`u128`) is the **raw price** provided directly by the oracle.  
/// - The second value (`u16`) represents the **number of decimals** of the token,  
///   which must be applied to properly scale the raw price.
///
/// With this structure, developers can easily compute the final USD value by  
/// adjusting the `raw` price according to the provided decimals.
///
/// This ensures accurate and consistent pricing across both legacy assets  
/// and Spike’s AMM ecosystem.
///
module spike_amm::price_aggregator {

    #[view]
    public fun get_token_price_in_usd(_token_address: address): (u128, u16) {
        abort 0
    }

    #[view]
    public fun get_coin_price_in_usd<CoinType>(): (u128, u16) {
        abort 0
    }
}
