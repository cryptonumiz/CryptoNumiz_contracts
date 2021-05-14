pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/INumiEvent.sol";

contract NumiEvent is INumiEvent {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_NOT_ALLOWED_SENDER = 103;

    // State:
    address static m_root_address;
    address public static m_creator_address;
    string public static m_title;
    string public m_description;
    uint64 public m_start_date;
    uint64 public m_end_date;

    address public m_cover_image;
    address public m_substrate_image;

    TvmCell static m_code;

    constructor(string description, uint64 start_date, uint64 end_date, address cover_image, address substrate_image) public {
        require(tvm.pubkey() != 0, ERROR_NO_PUBKEY);
        require(msg.sender == m_root_address, ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();

        m_description = description;
        m_start_date = start_date;
        m_end_date = end_date;
        m_cover_image = cover_image;
        m_substrate_image = substrate_image;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function getDetails() external override view returns (INumiEventDetails) {
        return INumiEventDetails(
            m_root_address,
            m_creator_address,
            m_title,
            m_description,
            m_start_date,
            m_end_date,
            m_cover_image,
            m_substrate_image
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