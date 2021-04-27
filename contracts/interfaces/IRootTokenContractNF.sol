pragma ton-solidity >= 0.39.0;

interface IRootTokenContractNF {
    struct IRootTokenContractDetails {
        bytes name;
        bytes symbol;
        uint8 decimals;
        string front_side_image;
        address curator;
        address creator;
        uint8 curator_percent;
        uint8 creator_percent;
        address numi_event;
        uint256 root_public_key;
        uint256 total_supply;
        uint256 total_granted;
        TvmCell wallet_code;
    }

    function deployWallet(uint256 pubkey, uint256 tokenId, uint128 grams) external returns (address);
    function deployEmptyWallet(uint256 pubkey, uint128 grams) external returns (address);
    function getWalletAddress(uint256 creator_public_key, address creator_addres) external view returns (address);
    function grant(address dest, uint256 tokenId, uint128 grams) external;
    function mint(uint256 tokenId) external returns (uint256);

    function getDetails() external view returns (IRootTokenContractDetails);
}