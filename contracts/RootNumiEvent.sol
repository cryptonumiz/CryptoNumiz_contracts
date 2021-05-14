pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/IRootNumiEvent.sol";
import "./NumiEvent.sol";

contract RootNumiEvent is IRootNumiEvent {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;

    uint constant ERROR_NO_TITLE = 105;
    uint constant ERROR_NO_DESCRIPTION = 106;
    uint constant ERROR_NO_START_DATE = 107;
    uint constant ERROR_END_DATE_NOT_GREATER_THEN_START_DATE = 108;
    uint constant ERROR_NO_COVER_IMAGE = 109;
    uint constant ERROR_NO_SUBSTRATE_IMAGE = 110;

    // State:
    uint256 m_root_public_key;
    TvmCell m_event_code;

    constructor(uint256 root_public_key, TvmCell event_code) public {
        require(root_public_key != 0, ERROR_NO_PUBKEY);
        tvm.accept();

        m_root_public_key = root_public_key;
        m_event_code = event_code;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function deployEvent(address creator_address, string title, string description, uint64 start_date, uint64 end_date, address cover_image, address substrate_image) external override onlyOwner returns (address) {
        require(msg.pubkey() != 0, ERROR_NO_PUBKEY);
        require(title.byteLength() > 0, ERROR_NO_TITLE);
        require(description.byteLength() > 0, ERROR_NO_DESCRIPTION);
        require(start_date > uint64(0), ERROR_NO_START_DATE);
        require(end_date > start_date, ERROR_END_DATE_NOT_GREATER_THEN_START_DATE);
        tvm.accept();

        uint256 pubkey = msg.pubkey();
        address addr = new NumiEvent{
            value: 0.05 ton,
            code: m_event_code,
            pubkey: pubkey,
            varInit: {
                m_root_address: address(this),
                m_creator_address: creator_address,
                m_title: title,
                m_code: m_event_code
            }
        }(description,start_date,end_date,cover_image,substrate_image);

        return addr;
    }

    function getDetails() external override view returns (IRootNumiEventDetails) {
        return IRootNumiEventDetails(
            m_root_public_key,
            m_event_code
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