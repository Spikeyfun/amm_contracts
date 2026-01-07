module spike_amm::oracle_keepers {

    public entry fun call_update_by_address(
        _sender: &signer,
        _tokenA_address: address,
        _tokenB_address: address
    ) {
        abort 0
    }

    public entry fun call_update_block_info(
        _sender: &signer
    ) {
        abort 0
    }
}