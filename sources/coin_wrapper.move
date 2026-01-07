module spike_amm::coin_wrapper {
    use supra_framework::fungible_asset::{Metadata};
    use supra_framework::object::{Object};
    use std::string::{String};
    use std::option;

    #[view]
    public fun view_wrapper_by_components(): option::Option<Object<Metadata>> {
        abort 0
    }

    #[view]
    public fun is_initialized(): bool {
        abort 0
    }

    #[view]
    public fun wrapper_address(): address {
        abort 0
    }

    #[view]
    public fun is_supported<CoinType>(): bool {
        abort 0
    }

    #[view]
    public fun is_wrapper(_metadata: Object<Metadata>): bool {
        abort 0
    }

    #[view]
    public fun get_coin_type(_metadata: Object<Metadata>): String {
        abort 0
    }

    #[view]
    public fun get_wrapper<CoinType>(): Object<Metadata> {
        abort 0
    }

    #[view]
    public fun get_original(_fungible_asset: Object<Metadata>): String {
        abort 0
    }

    #[view]
    public fun format_fungible_asset(_fungible_asset: Object<Metadata>): String {
        abort 0
    }

    #[view]
    public fun get_balance<CoinType>(): u64 {
        abort 0
    }
}