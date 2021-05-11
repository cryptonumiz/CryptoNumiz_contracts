pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface INumiUser {
    struct INumiUserDetails {
        address root_address;
        address owner_address;
        uint256 owner_pubkey;
        string username;
        string bio;
        uint128 balance;
        TvmCell code;
    }

    function setUsername(string _username) external;
    function setBio(string _bio) external;

    function getDetails() external view returns (INumiUserDetails);
}