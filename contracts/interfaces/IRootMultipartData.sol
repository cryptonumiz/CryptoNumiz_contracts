pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface IRootMultipartData {
    struct IRootMultipartDataDetails {
        uint256 root_public_key;
        TvmCell multipart_data_code;
    }

    function deployMultipartData(uint8 chunks_count) external returns (address);
    
    function getDetails() external view returns (IRootMultipartDataDetails);
}