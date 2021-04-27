pragma ton-solidity >= 0.39.0;

interface ITONTokenWalletNF {
    struct ITONTokenWalletDetails {
        uint256 wallet_public_key;
        uint256 root_public_key;
        address root_address;
        TvmCell code;
    }

    function transfer(address dest, uint256 tokenId, uint128 grams) external;
    function transferFrom(address dest, address to, uint256 tokenId, uint128 grams) external;
    
    // Receive tokens from root
    function accept(uint256 tokenId) external;

    function internalTransfer(uint256 tokenId, uint256 pubkey) external;
    function internalTransferFrom(address to, uint256 tokenId) external;

    // allowance interface
    function approve(address spender, uint256 tokenId) external;
    function disapprove() external;

    function getDetails() external view returns (ITONTokenWalletDetails);
}