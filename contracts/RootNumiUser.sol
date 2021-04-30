pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/IRootNumiUser.sol";
import "./NumiUser.sol";

contract RootNumiUser is IRootNumiUser {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 100;
    uint constant ERROR_NO_WALLET = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;

    uint constant ERROR_USERNAME_IS_TOO_LONG = 200;
    uint constant ERROR_BIO_IS_TOO_LONG = 201;

    // State:
    uint256 m_root_public_key;
    TvmCell m_user_code;

    // Constants:
    uint constant USERNAME_MAX_LENGTH = 60;
    uint constant BIO_MAX_LENGTH = 500;

    constructor(uint256 root_public_key, TvmCell user_code) public {
        require(root_public_key != 0, ERROR_NO_PUBKEY);
        tvm.accept();

        m_root_public_key = root_public_key;
        m_user_code = user_code;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function deployUser(address _owner_address, string _username, string _bio, uint128 grams) external override returns (address) {
        require(msg.pubkey() != 0, ERROR_NO_PUBKEY);
        require(_username.byteLength() <= USERNAME_MAX_LENGTH, ERROR_USERNAME_IS_TOO_LONG);
        require(_bio.byteLength() <= BIO_MAX_LENGTH, ERROR_BIO_IS_TOO_LONG);
        tvm.accept();

        uint256 pubkey = msg.pubkey();
        address addr = new NumiUser{
            value: grams,
            flag: 1,
            code: m_user_code,
            pubkey: pubkey,
            varInit: {
                m_root_address: address(this),
                m_owner_address: _owner_address,
                m_owner_pubkey: pubkey,
                m_code: m_user_code
            }
        }(_username,_bio);

        return addr;
    }

    function getExpectedAddress(address _owner_address, uint256 _owner_pubkey) external override view returns (address value) {
        require(_owner_address != address(0), ERROR_NO_WALLET);
        require(_owner_pubkey != 0, ERROR_NO_PUBKEY);
        
        TvmCell stateInit = tvm.buildStateInit({
            contr: NumiUser,
            varInit: {
                m_root_address: address(this),
                m_owner_address: _owner_address,
                m_owner_pubkey: _owner_pubkey,
                m_code: m_user_code
            },
            pubkey: _owner_pubkey,
            code: m_user_code
        });

        return address(tvm.hash(stateInit));
    }

    function getDetails() external override view returns (IRootNumiUserDetails) {
        return IRootNumiUserDetails(
            m_root_public_key,
            m_user_code
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