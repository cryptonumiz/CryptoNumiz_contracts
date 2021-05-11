pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;

interface IRootRawUploader {
    struct IRootRawUploaderDetails {
        uint256 root_public_key;
        TvmCell uploader_code;
    }

    function deployUploader(uint8 chunks_count) external returns (address);
    
    function getDetails() external view returns (IRootRawUploaderDetails);
}