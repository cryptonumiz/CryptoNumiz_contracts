pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

contract MultipartData {
    // Error codes:
    uint constant ERROR_NO_WALLET = 100;
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_NO_ROOT_ADDRESS = 103;
    uint constant ERROR_CHUNKS_COUNT_MUST_BE_ABOVE_THAN_ZERO = 104;

    uint constant ERROR_UPLOAD_IN_PROCCESS = 105;
    uint constant ERROR_INCORRECT_INDEX = 106;
    uint constant ERROR_CHUNK_ALREADY_EXISTS = 107;
    uint constant ERROR_INCORRECT_CHUNKS_COUNT = 108;
    uint constant ERROR_SENDER_IS_NOT_ALLOWED = 109;

    // State:
    address static m_root_address;
    uint256 static m_owner_pubkey;
    TvmCell static m_code;

    uint8 static m_chunks_count;
    uint8 m_cur_chunk_count;
    address allowance_dest;

    bytes[] public m_raw_data_chunks;

    constructor() public {
        require(m_root_address != address(0), ERROR_NO_ROOT_ADDRESS);
        require(m_owner_pubkey != 0, ERROR_NO_PUBKEY);
        require(m_chunks_count > 0, ERROR_CHUNKS_COUNT_MUST_BE_ABOVE_THAN_ZERO);
        tvm.accept();
        
        m_raw_data_chunks = new bytes[](m_chunks_count);
    }

    function writeData(uint8 index, string chunk) public {
        require(msg.pubkey() == m_owner_pubkey, ERROR_SENDER_IS_NOT_MY_OWNER);
        require(m_raw_data_chunks[index].length == uint(0), ERROR_CHUNK_ALREADY_EXISTS);
        require(index <= m_chunks_count, ERROR_INCORRECT_INDEX);
        require(m_cur_chunk_count <= m_chunks_count, ERROR_INCORRECT_CHUNKS_COUNT);
        tvm.accept();

        m_raw_data_chunks[index] = chunk;

        ++m_cur_chunk_count;
    }

    function getDetails() public view returns (uint8 chunks_count, uint8 cur_chunk_count, uint256 creator_pubkey, bytes[] chunks) {
        return (
            m_chunks_count,
            m_cur_chunk_count,
            m_owner_pubkey,
            m_raw_data_chunks
        );
    }

    fallback() external {

    }
}