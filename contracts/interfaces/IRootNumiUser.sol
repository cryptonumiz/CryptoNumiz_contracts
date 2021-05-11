pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface IRootNumiUser {
    struct IRootNumiUserDetails {
        uint256 root_public_key;
        TvmCell user_code;
    }

    function deployUser(address _owner_address, string _username, string _bio, uint128 grams) external returns (address value);
    function getExpectedAddress(address _owner_address, uint256 _owner_pubkey) external view returns (address value);
    function getAddressBySign() external returns(address addr, uint256 pubkey);

    function getDetails() external view returns (IRootNumiUserDetails);
}