pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface INumiEvent {
    struct INumiEventDetails {
        address root_address;
        address creator_address;
        string title;
        string description;
        uint64 start_date;
        uint64 end_date;
        address cover_image;
        address substrate_image;
    }

    function getDetails() external view returns (INumiEventDetails);
}