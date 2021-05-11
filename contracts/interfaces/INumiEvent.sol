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
        bytes[] cover_image;
        bytes[] substrate_image;
    }

    function setCoverImage(address uploader_addr) external;
    function setSubstrateImage(address uploader_addr) external;

    function receiveData(bytes[] _data, string payload) external;

    function getDetails() external view returns (INumiEventDetails);
}