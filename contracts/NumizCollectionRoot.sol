pragma ton-solidity >= 0.46.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "NumizNFT.sol";

contract NumizCollectionRoot {
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant TOKEN_NOT_MINTED = 101;
    uint constant WRONG_MINT_TOKEN_ID = 104;
    uint constant DEFINE_PUBKEY = 106;
    uint constant DEFINE_SENDER = 107;

    string public static m_collectionName;
    address public static m_eventAddress;
    uint256 public m_totalSupply;
    uint256 public m_totalGranted;

    mapping (uint256 => NftItem) nftItems;

    TvmCell static m_nftCode;

    constructor() public {
        require(msg.sender != address(0), 100);
        tvm.accept();

        m_totalSupply = uint256(0);
        m_totalGranted = uint256(0);

        TvmBuilder b;
        b.store(address(this));
        m_nftCode = tvm.setCodeSalt(m_nftCode, b.toCell());
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        _;
    }

    function deployEmptyWallet(address creatorAddress) external view returns (address) {
        require(msg.pubkey() != 0, DEFINE_PUBKEY);
        tvm.accept();
        
        address wallet = new NumizNFT{
            value: 0.5 ton,
            flag: 1,
            code: m_nftCode,
            pubkey: msg.pubkey(),
            varInit: {
                m_creatorAddress: creatorAddress,
                m_creatorPubkey: msg.pubkey()
            }
        }();

        return wallet;
    }

    function mint(
        string name,
        string description,
        address frontSideStorage,
        address backSideStorage,
        address creatorAddress,
        uint8 creatorPercent,
        address curatorAddress,
        uint8 curatorPercent,
        address numiEventAddress,
        bool isForSale,
        bool isForAuction
    ) external onlyOwner returns (uint256) {
        NftItem item = NftItem({
            name: name,
            description: description,
            frontSideStorage: frontSideStorage,
            backSideStorage: backSideStorage,
            creatorAddress: creatorAddress,
            creatorPercent: creatorPercent,
            curatorAddress: curatorAddress,
            curatorPercent: curatorPercent,
            numiEventAddress: numiEventAddress,
            isForSale: isForSale,
            isForAuction: isForAuction
        });
        
        uint256 nftHash = _buildItemHash(item);

        require(!nftItems.exists(nftHash), WRONG_MINT_TOKEN_ID);
        tvm.accept();
        
        nftItems[nftHash] = item;
        ++m_totalSupply;
        
        return nftHash;
    }

    function grant(address dest, uint256 nftHash) external {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(nftItems.exists(nftHash), TOKEN_NOT_MINTED);
        tvm.accept();

        NftAcceptable(dest).accept{value: 1 ton, bounce: false, flag: 1}(nftItems[nftHash]);

        ++m_totalGranted;
        delete nftItems[nftHash];
    }

    function getExpectedAddress(address _creatorAddress, uint256 _creatorPubkey) public view returns(address) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: NumizNFT,
            varInit: {
                m_creatorAddress: _creatorAddress,
                m_creatorPubkey: _creatorPubkey,
                m_code: m_nftCode
            },
            pubkey: _creatorPubkey,
            code: m_nftCode
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
}