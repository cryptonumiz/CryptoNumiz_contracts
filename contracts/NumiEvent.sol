pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/INumiEvent.sol";

interface IRawUploader {
    function sendData(string payload) external;
}

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
    bytes[] public m_cover_image;
    bytes[] public m_substrate_image;

    address m_receiver_address;
    bytes[] m_received_data;

    TvmCell static m_code;

    constructor(string description, uint64 start_date, uint64 end_date) public {
        require(tvm.pubkey() != 0, ERROR_NO_PUBKEY);
        require(msg.sender == m_root_address, ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();

        m_description = description;
        m_start_date = start_date;
        m_end_date = end_date;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function setCoverImage(address uploader_addr) external override onlyOwner {
        tvm.accept();
        m_receiver_address = uploader_addr;
        IRawUploader(m_receiver_address).sendData("cover");
    }

    function setSubstrateImage(address uploader_addr) external override onlyOwner {
        tvm.accept();
        m_receiver_address = uploader_addr;
        IRawUploader(m_receiver_address).sendData("substrate");
    }

    function receiveData(bytes[] _data, string payload) external override {
        require(msg.sender == m_receiver_address, ERROR_NOT_ALLOWED_SENDER);
        tvm.accept();
        
        if (payload == "cover") {
            m_cover_image = _data;
        } else if (payload == "substrate") {
            m_substrate_image = _data;
        } else {
            // do nothing
        }
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