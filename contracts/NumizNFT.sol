pragma ton-solidity >= 0.46.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct NftItem {
    string name;
    string description;
    address frontSideStorage;
    address backSideStorage;
    address creatorAddress;
    uint8 creatorPercent;
    address curatorAddress;
    uint8 curatorPercent;
    address numiEventAddress;
    bool isForSale;
    bool isForAuction;
}

interface NftAcceptable {
    function accept(NftItem item) external;
}

interface NftTranferable {
    struct AllowanceInfo {
        address spender;
        uint256 nftHash;
    }

    function approve(address spender, uint256 nftHash) external;
    function disapprove() external;

    function transfer(uint256 nftHash, address dest) external;
    function internalTransfer(NftItem item, address creatorAddress, uint256 creatorPubkeyy) external;
    function transferFrom(address from, address to, NftItem item) external;
    function internalTransferFrom(address to, NftItem item) external;
}

contract NumizNFT is NftTranferable, NftAcceptable {

    // Error codes:
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant CANNOT_SEND_TO_YOURSELF = 103;
    uint constant NOT_ENOUGH_BALANCE = 104;
    uint constant MESSAGE_SENDER_IS_NOT_GOOD_WALLET = 105;
    uint constant NO_ALLOWANCE_SET = 106;
    uint constant WRONG_SPENDER = 107;
    uint constant NOT_ENOUGH_ALLOWANCE = 108;
    uint constant ALREADY_HAVE_THIS_TOKEN = 109;
    uint constant ZERO_DEST_ADDR = 111;

    // State:
    address public static m_creatorAddress;
    uint256 public static m_creatorPubkey;

    optional(AllowanceInfo) m_allowance;

    mapping (uint256 => NftItem) public nftItems;

    // Modifiers:
    modifier onlyRoot {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        TvmCell salt = optSalt.get();
        require(salt.toSlice().decode(address) == msg.sender, 102);
        _;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        _;
    }

    constructor() public onlyRoot {
        // TODO: init some vars if needed.
    }

    // NftAcceptable
    function accept(NftItem item) external override onlyRoot {
        uint256 nftHash = _buildItemHash(item);
        nftItems[nftHash] = item;
        msg.sender.transfer({value: 0, flag: 64, bounce: false});
    }

    // NftTranferable
    function approve(address spender, uint256 nftHash) external override onlyOwner {
        require(nftItems.exists(nftHash), NOT_ENOUGH_BALANCE);
        tvm.accept();

        m_allowance.set(AllowanceInfo(spender, nftHash));
    }

    function disapprove() external override onlyOwner {
        tvm.accept();

        m_allowance.reset();
    }

    function transfer(uint256 nftHash, address dest) external override onlyOwner {
        require(dest != address(0), ZERO_DEST_ADDR);
        require(dest != address(this), CANNOT_SEND_TO_YOURSELF);
        require(nftItems.exists(nftHash), NOT_ENOUGH_BALANCE);
        tvm.accept();

        NftTranferable(dest).internalTransfer{value: 0.05 ton, bounce: false, flag: 1}(nftItems[nftHash], m_creatorAddress, m_creatorPubkey);

        delete nftItems[nftHash];
    }

    function internalTransfer(NftItem item, address creatorAddress, uint256 creatorPubkey) external override {
        address expected_address = getExpectedAddress(creatorAddress, creatorPubkey);
        address sender = msg.sender;

        uint256 nftHash = _buildItemHash(item);
        
        require(sender == expected_address, MESSAGE_SENDER_IS_NOT_GOOD_WALLET);
        require(!nftItems.exists(nftHash), ALREADY_HAVE_THIS_TOKEN);

        nftItems[nftHash] = item;
    }

    function transferFrom(address from, address to, NftItem item) external override onlyOwner {
        tvm.accept();
        NftTranferable(from).internalTransferFrom{value: 0.01 ton, flag: 1}(to, item);
    }

    function internalTransferFrom(address to, NftItem item) external override {
        require(m_allowance.hasValue(), NO_ALLOWANCE_SET);
        require(msg.sender == m_allowance.get().spender, WRONG_SPENDER);

        uint256 nftHash = _buildItemHash(item);

        require(nftHash == m_allowance.get().nftHash, NOT_ENOUGH_ALLOWANCE);
        
        NftTranferable(to).internalTransfer{value: 0, bounce: true, flag: 128}(item, m_creatorAddress, m_creatorPubkey);
        
        m_allowance.reset();
    }

    function getExpectedAddress(address _creatorAddress, uint256 _creatorPubkey) private inline view returns(address){
        TvmCell stateInit = tvm.buildStateInit({
            contr: NumizNFT,
            varInit: {
                m_creatorAddress: _creatorAddress,
                m_creatorPubkey: _creatorPubkey,
                m_code: tvm.code()
            },
            pubkey: _creatorPubkey,
            code: tvm.code()
        });

        return address(tvm.hash(stateInit));
    }

    function _buildItemHash(NftItem item) private inline pure returns (uint256 nftHash) {
        TvmBuilder builder1;
        builder1.store(item.name, item.description);

        TvmBuilder builder2;
        builder2.store(item.frontSideStorage, item.backSideStorage);

        TvmBuilder builder3;
        builder3.store(
            item.creatorAddress, 
            item.creatorPercent, 
            item.curatorAddress, 
            item.curatorPercent, 
            item.numiEventAddress,
            item.isForSale,
            item.isForAuction
        );

        builder3.storeRef(builder1);
        builder3.storeRef(builder2);

        return tvm.hash(builder3.toCell());
    }

    onBounce(TvmSlice slice) external {
        //
    } 

    fallback() external {
    }
}