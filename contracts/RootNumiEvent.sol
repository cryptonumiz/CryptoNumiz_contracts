pragma ton-solidity >= 0.46.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "NumiEvent.sol";

contract RootNumiEvent {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_SENDER_IS_NOT_MY_ROOT = 103;
    uint constant ERROR_HAVE_NO_SALT = 104;

    // State:
    TvmCell m_eventImage;
    TvmCell static m_code;

    // Structs:
    struct NumiEventDetails {
        string title;
        string description;
        uint64 startTimestamp;
        uint64 endTimestamp;
        address coverImage;
        address substrateImage;
    }

    modifier onlyOwner {
        require(msg.sender == _getOwner(), ERROR_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    constructor(TvmCell eventImage) public {
        optional(TvmCell) optSalt = tvm.codeSalt(m_code);
        require(optSalt.hasValue(), ERROR_HAVE_NO_SALT);
        (address sender, ) = optSalt.get().toSlice().decode(address, address);
        require(sender == msg.sender, ERROR_SENDER_IS_NOT_MY_ROOT);
        
        m_eventImage = eventImage;
    }

    function deployEvent(NumiEventDetails newEvent) external view onlyOwner {
        optional(TvmCell) optSalt = tvm.codeSalt(m_code);
        require(optSalt.hasValue(), ERROR_HAVE_NO_SALT);
        (address sender, address ownerAddress) = optSalt.get().toSlice().decode(address, address);
        
        TvmBuilder saltBuilder;
        saltBuilder.store(sender);
        TvmCell code = tvm.setCodeSalt(
            m_eventImage.toSlice().loadRef(),
            saltBuilder.toCell()
        );

        new NumiEvent{
            value: 0,
            flag: 64,
            code: code,
            pubkey: tvm.pubkey(),
            varInit: {
                m_title: newEvent.title,
                m_rootAddress: address(this),
                m_ownerAddress: ownerAddress,
                m_code: code
            }
        }(
            newEvent.description,
            newEvent.startTimestamp,
            newEvent.endTimestamp,
            newEvent.coverImage,
            newEvent.substrateImage
        );
    }

    function _getOwner() private inline view returns(address) {
        //TvmCell code = tvm.code();
        optional(TvmCell) optSalt = tvm.codeSalt(m_code);
        require(optSalt.hasValue(), ERROR_HAVE_NO_SALT);
        (, address ownerAddress) = optSalt.get().toSlice().decode(address, address);
        
        return ownerAddress;
    }

    fallback() external {
        
    }
}