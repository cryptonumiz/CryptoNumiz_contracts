pragma ton-solidity >= 0.46.0;

struct NumiEventDetails {
        string title;
        string description;
        uint64 startTimestamp;
        uint64 endTimestamp;
        address coverImage;
        address substrateImage;
    }

interface INumiUser {
    struct INumiUserDetails {
        address owner_address;
        uint256 owner_pubkey;
        string username;
        string bio;
        uint128 balance;
    }

    function setUsername(string _username) external;
    function setBio(string _bio) external;

    function createEvent(NumiEventDetails newEvent) external view;

    function getDetails() external view returns (INumiUserDetails);
}