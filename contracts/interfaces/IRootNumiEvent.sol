pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface IRootNumiEvent {
    struct IRootNumiEventDetails {
        uint256 root_public_key;
        TvmCell event_code;
    }

    function deployEvent(address creator_address, string title, string description, uint64 start_date, uint64 end_date, address cover_image, address substrate_image) external returns (address);
    
    function getDetails() external view returns (IRootNumiEventDetails);
}