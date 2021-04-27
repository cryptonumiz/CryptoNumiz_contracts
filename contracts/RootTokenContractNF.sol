pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/IRootTokenContractNF.sol";
import "./interfaces/ITONTokenWalletNF.sol";
import "./TONTokenWalletNF.sol";

contract RootTokenContract is IRootTokenContractNF {
    // Error codes:
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant TOKEN_NOT_MINTED = 101;
    uint constant WRONG_BOUNCED_HEADER = 102;
    uint constant WRONG_BOUNCED_ARGS = 103;
    uint constant WRONG_MINT_TOKEN_ID = 104;
    uint constant DEFINE_PUBKEY = 106;
    uint constant DEFINE_ADDRESS = 107;

    // State variables:
    bytes public m_name;
    bytes public m_symbol;
    uint8 public m_decimals;
    string public m_front_side_image;
    string m_back_side_media;

    address public m_curator;
    address public m_creator_address;
    uint8 public m_curator_percent;
    uint8 public m_creator_percent;
    address public m_numi_event;

    TvmCell public m_wallet_code;

    uint256 m_root_public_key;
    uint256 m_total_supply;
    uint256 m_total_granted;
    uint128 m_start_balance;

    mapping(uint256 => bool) tokens;

    constructor(bytes name, bytes symbol, uint8 decimals, string front_side_image, string back_side_media, address curator, address creator, uint8 creator_percent, address numi_event, uint256 root_public_key, TvmCell wallet_code) public {
        require(root_public_key != 0, DEFINE_PUBKEY);
        tvm.accept();

        m_name = name;
        m_symbol = symbol;
        m_decimals = decimals;
        m_front_side_image = front_side_image;
        m_back_side_media = back_side_media;

        m_curator = curator;
        m_creator_address = creator;
        m_curator_percent = 10;
        m_creator_percent = creator_percent;
        m_numi_event = numi_event;

        m_wallet_code = wallet_code;

        m_root_public_key = root_public_key;
        m_total_supply = uint256(0);
        m_total_granted = uint256(0);
        m_start_balance = address(this).balance;
    }

    function deployWallet(uint256 pubkey, uint256 tokenId, uint128 grams) override external returns(address) {
        require(tvm.pubkey() == m_root_public_key, MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(tokenId != uint256(0) || tokens.exists(tokenId), TOKEN_NOT_MINTED);
        tvm.accept();

        address wallet = new TONTokenWalletNF{
            value: grams,
            flag: 1,
            code: m_wallet_code,
            pubkey: pubkey,
            varInit: {
                m_name: m_name,
                m_symbol: m_symbol,
                m_decimals: m_decimals,
                m_creator_address: m_creator_address,
                m_root_address: address(this),
                m_creator_public_key: pubkey,
                m_root_public_key: m_root_public_key,
                m_code: m_wallet_code
            }
        }(m_front_side_image,m_back_side_media,m_curator,m_curator_percent,m_creator_percent,m_numi_event);

        ITONTokenWalletNF(wallet).accept(tokenId);
        ++m_total_granted;

        return wallet;
    }

    function deployEmptyWallet(uint256 pubkey, uint128 grams) override external returns (address) {
        require(tvm.pubkey() == m_root_public_key, MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(pubkey != uint(0), DEFINE_PUBKEY);
        tvm.accept();

        address wallet = new TONTokenWalletNF{
            value: grams,
            flag: 1,
            code: m_wallet_code,
            pubkey: pubkey,
            varInit: {
                m_name: m_name,
                m_symbol: m_symbol,
                m_decimals: m_decimals,
                m_creator_address: m_creator_address,
                m_root_address: address(this),
                m_creator_public_key: pubkey,
                m_root_public_key: m_root_public_key,
                m_code: m_wallet_code
            }
        }(m_front_side_image,m_back_side_media,m_curator,m_curator_percent,m_creator_percent,m_numi_event);

        return wallet;
    }

    function grant(address dest, uint256 tokenId, uint128 grams) override external {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(tokenId != uint256(0) || tokens.exists(tokenId), TOKEN_NOT_MINTED);
        tvm.accept();

        ITONTokenWalletNF(dest).accept{value: grams, bounce: false, flag: 1}(tokenId);

        ++m_total_granted;
    }

    function mint(uint256 tokenId) override external returns (uint256) {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(!tokens.exists(tokenId), WRONG_MINT_TOKEN_ID);
        tvm.accept();

        tokens.add(tokenId, true);
        ++m_total_supply;

        return tokenId;
    }

    function getWalletAddress(uint256 creator_public_key, address creator_address) external override view returns (address) {
        require(creator_public_key != 0, DEFINE_PUBKEY);
        require(creator_address.value != 0, DEFINE_ADDRESS);

        return getExpectedWalletAddress(creator_public_key, creator_address);
    }

    function getExpectedWalletAddress(uint256 creator_public_key, address creator_address) private inline view returns (address) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: TONTokenWalletNF,
            varInit: {
                m_name: m_name,
                m_symbol: m_symbol,
                m_decimals: m_decimals,
                m_creator_address: creator_address,
                m_root_address: address(this),
                m_creator_public_key: creator_public_key,
                m_root_public_key: m_root_public_key,
                m_code: m_wallet_code
            },
            pubkey: creator_public_key,
            code: m_wallet_code
        });

        return address(tvm.hash(stateInit));
    }

    function getLastMintedToken() public view returns (uint256 tokenId) {
        return m_total_supply;
    }

    function getBackSide() public view returns (string) {
        return m_back_side_media;
    }

    function getDetails() override external view returns (IRootTokenContractDetails) {
        return IRootTokenContractDetails(
            m_name,
            m_symbol,
            m_decimals,
            m_front_side_image,
            m_curator,
            m_creator_address,
            m_curator_percent,
            m_creator_percent,
            m_numi_event,
            m_root_public_key,
            m_total_supply,
            m_total_granted,
            m_wallet_code
        );
    }

    onBounce(TvmSlice slice) external {
        //
    }

    fallback() external {
    }
}