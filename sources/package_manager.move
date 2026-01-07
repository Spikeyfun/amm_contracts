module spike_amm::package_manager {
    use std::string::String;

    public fun address_exists(_name: String): bool {
        abort 0
    }

    public fun get_address(_name: String): address {
        abort 0
    }
}