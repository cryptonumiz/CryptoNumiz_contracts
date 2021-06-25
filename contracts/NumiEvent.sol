pragma ton-solidity >= 0.46.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "NumizCollectionRoot.sol";

contract NumiEvent {
    // Error codes:
    uint constant ERROR_NO_SALT = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_ROOT = 102;
    uint constant ERROR_TITLE_IS_EMPTY = 103;
    uint constant ERROR_NO_SENDER = 104;

    // State:
    address static public m_ownerAddress;
    address static m_rootAddress;
    string static public m_title;
    string public m_description;
    uint64 public m_startTimestamp;
    uint64 public m_endTimestamp;
    address public m_coverImage;
    address public m_substrateImage;

    // Structs:
    struct NumiEventDetails {
        address ownerAddress;
        string title;
        string description;
        uint64 startTimestamp;
        uint64 endTimestamp;
        address coverImage;
        address substrateImage;
    }

    constructor(
        string description,
        uint64 startTimestamp,
        uint64 endTimestamp,
        address coverImage,
        address substrateImage
    ) public {
        require(msg.sender == m_rootAddress, ERROR_SENDER_IS_NOT_MY_ROOT);
        require(!m_title.empty(), ERROR_TITLE_IS_EMPTY);
        
        m_description = description;
        m_startTimestamp = startTimestamp;
        m_endTimestamp = endTimestamp;
        m_coverImage = coverImage;
        m_substrateImage = substrateImage;
    }

    function deployNumizCollectionRoot(TvmCell numizCollectionRootImage) public view {
        require(msg.sender != address(0), ERROR_NO_SENDER);

        TvmBuilder saltBuilder;
        saltBuilder.store(sender);
        TvmCell code = tvm.setCodeSalt(
            numizCollectionRootImage.toSlice().loadRef(),
            saltBuilder.toCell()
        );

        new NumiEvent{
            value: 0,
            flag: 64,
            code: code,
            pubkey: tvm.pubkey(),
            varInit: {
                m_collectionName: m_title,
                m_eventAddress: address(this)
            }
        }();
    }

    function getDetails() public view returns (NumiEventDetails) {
        return NumiEventDetails(
            m_ownerAddress,
            m_title,
            m_description,
            m_startTimestamp,
            m_endTimestamp,
            m_coverImage,
            m_substrateImage
        );
    }
}