pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/INumiUser.sol";

contract NumiUser is INumiUser {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_OWNER = 102;

    uint constant ERROR_USERNAME_IS_TOO_LONG = 200;
    uint constant ERROR_BIO_IS_TOO_LONG = 201;

    // State:
    address static public m_root_address;
    address static public m_owner_address;
    uint256 static m_owner_pubkey;
    TvmCell static m_code;

    string public m_username;
    string public m_bio;

    // Constants:
    uint constant USERNAME_MAX_LENGTH = 60;
    uint constant BIO_MAX_LENGTH = 500;

    constructor(string username, string bio) public {
        require(tvm.pubkey() != 0, ERROR_NO_PUBKEY);
        require(msg.sender == m_root_address, ERROR_SENDER_IS_NOT_OWNER);
        tvm.accept();

        m_username = username;
        m_bio = bio;
    }

    modifier onlyOwner {
        require(msg.pubkey() == m_owner_pubkey, ERROR_SENDER_IS_NOT_OWNER);
        _;
    }

    function setUsername(string _username) external override onlyOwner {
        require(_username.byteLength() <= USERNAME_MAX_LENGTH, ERROR_USERNAME_IS_TOO_LONG);
        tvm.accept();
        m_username = _username;
    }

    function setBio(string _bio) external override onlyOwner {
        require(_bio.byteLength() <= BIO_MAX_LENGTH, ERROR_BIO_IS_TOO_LONG);
        tvm.accept();
        m_bio = _bio;
    }

    function getDetails() external override view returns (INumiUserDetails) {
        return INumiUserDetails(
            m_root_address,
            m_owner_address,
            m_owner_pubkey,
            m_username,
            m_bio,
            address(this).balance,
            m_code
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
    fallback() external pure {
    }
}