pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "./interfaces/IRootRawUploader.sol";
import "./RawUploader.sol";

contract RootRawUploader is IRootRawUploader {
    // Error codes:
    uint constant ERROR_NO_SENDER = 100;
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    
    uint constant ERROR_CHUNKS_COUNT_GREATER_THAN_MAX = 105;

    // State:
    uint256 m_root_public_key;
    TvmCell m_raw_uploader_code;
    uint8 m_max_chunks_count;

    constructor(uint256 root_public_key, TvmCell raw_uploader_code) public {
        require(root_public_key != 0, ERROR_NO_PUBKEY);
        tvm.accept();

        m_root_public_key = root_public_key;
        m_raw_uploader_code = raw_uploader_code;
        m_max_chunks_count = 11; // ~165kb
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    function deployUploader(uint8 chunks_count) external override returns (address) {
        require(msg.pubkey() != 0, ERROR_NO_PUBKEY);
        require(chunks_count <= m_max_chunks_count, ERROR_CHUNKS_COUNT_GREATER_THAN_MAX);
        tvm.accept();

        uint256 pubkey = msg.pubkey();
        address addr = new RawUploader{
            value: 2 ton,
            code: m_raw_uploader_code,
            pubkey: pubkey,
            varInit: {
                m_root_address: address(this),
                m_creator_pubkey: pubkey,
                m_code: m_raw_uploader_code,
                m_chunks_count: chunks_count
            }
        }();

        return addr;
    }

    function setMaxChunksCount(uint8 max_chunks_count) public onlyOwner {
        tvm.accept();
        m_max_chunks_count = max_chunks_count;
    }

    function getDetails() external override view returns (IRootRawUploaderDetails) {
        return IRootRawUploaderDetails(
            m_root_public_key,
            m_raw_uploader_code
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