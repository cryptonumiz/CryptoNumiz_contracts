pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/IRootMultipartData.sol";
import "./MultipartData.sol";

contract RootMultipartData is IRootMultipartData {
    // Error codes:
    uint constant ERROR_NO_SENDER = 100;
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    
    uint constant ERROR_CHUNKS_COUNT_GREATER_THAN_MAX = 105;

    // State:
    uint256 m_root_public_key;
    TvmCell m_multipart_data_code;
    uint8 m_max_chunks_count;

    constructor(uint256 root_public_key, TvmCell multipart_data_code) public {
        require(root_public_key != 0, ERROR_NO_PUBKEY);
        tvm.accept();

        m_root_public_key = root_public_key;
        m_multipart_data_code = multipart_data_code;
        m_max_chunks_count = 13; // ~195kb
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function deployMultipartData(uint8 chunks_count) external override returns (address) {
        require(msg.pubkey() != 0, ERROR_NO_PUBKEY);
        require(chunks_count <= m_max_chunks_count, ERROR_CHUNKS_COUNT_GREATER_THAN_MAX);
        tvm.accept();

        uint256 pubkey = msg.pubkey();
        address addr = new MultipartData{
            value: 2 ton,
            code: m_multipart_data_code,
            pubkey: pubkey,
            varInit: {
                m_root_address: address(this),
                m_owner_pubkey: pubkey,
                m_code: m_multipart_data_code,
                m_chunks_count: chunks_count
            }
        }();

        return addr;
    }

    function setMaxChunksCount(uint8 max_chunks_count) public onlyOwner {
        tvm.accept();
        m_max_chunks_count = max_chunks_count;
    }

    function getDetails() external override view returns (IRootMultipartDataDetails) {
        return IRootMultipartDataDetails(
            m_root_public_key,
            m_multipart_data_code
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