pragma ton-solidity >= 0.46.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/INumiUser.sol";

interface IRootNumiEvent {
    function deployEvent(NumiEventDetails newEvent) external;
}

interface INumiEvent {
    function deployNumizCollectionRoot(TvmCell m_numizCollectionRootImage) external;
}

contract NumiUser is INumiUser {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_SENDER_IS_NOT_MY_ROOT = 103;
    uint constant ERROR_HAVE_NO_SALT = 104;

    uint constant ERROR_USERNAME_IS_TOO_LONG = 200;
    uint constant ERROR_BIO_IS_TOO_LONG = 201;

    // State:
    address static public m_owner_address;
    uint256 static m_owner_pubkey;

    address public m_eventRoot;

    string public m_username;
    string public m_bio;

    TvmCell static m_numizCollectionRootCode;

    // Constants:
    uint constant USERNAME_MAX_LENGTH = 15;
    uint constant BIO_MAX_LENGTH = 300;

    modifier onlyRoot {
        require(msg.sender == _calcRoot(), ERROR_SENDER_IS_NOT_MY_ROOT);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == m_owner_address, ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    constructor(address eventRoot) public onlyRoot {
        m_eventRoot = eventRoot;
    }

    function setUsername(string _username) external override onlyOwner {
        m_username = _username;
    }

    function setBio(string _bio) external override onlyOwner {
        m_bio = _bio;
    }

    function createEvent(NumiEventDetails newEvent) external override view onlyOwner {
        IRootNumiEvent(m_eventRoot).deployEvent{value: 0, flag: 64}(newEvent);
    }

    function createNumizCollectionRoot() external override view onlyOwner {
        INumiEvent(m_eventRoot).deployNumizCollectionRoot{value: 0, flag: 64}(m_numizCollectionRootImage);
    }

    function _calcRoot() private inline pure returns (address) {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), ERROR_HAVE_NO_SALT);
        return optSalt.get().toSlice().decode(address);
    }

    function getDetails() external override view returns (INumiUserDetails) {
        return INumiUserDetails(
            m_owner_address,
            m_owner_pubkey,
            m_username,
            m_bio,
            address(this).balance
        );
    }

    // Function that changes the code of current contract.
	function setCode(TvmCell newcode) public pure onlyOwner {
		tvm.setcode(newcode);
		tvm.setCurrentCode(newcode);
		onCodeUpgrade();
	}

	function onCodeUpgrade() private pure {
	}

    // fallback function
    fallback() external {
    }
}