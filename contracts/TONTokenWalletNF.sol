pragma ton-solidity >= 0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/ITONTokenWalletNF.sol";

contract TONTokenWalletNF is ITONTokenWalletNF {

    // Error codes:
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant NOT_ENOUGH_BALANCE = 101;
    uint constant MESSAGE_SENDER_IS_NOT_MY_ROOT = 102;
    uint constant MESSAGE_SENDER_IS_NOT_GOOD_WALLET = 103;
    uint constant WRONG_BOUNCED_HEADER = 104;
    uint constant WRONG_BOUNCED_ARGS = 105;
    uint constant NO_ALLOWANCE_SET = 106;
    uint constant WRONG_SPENDER = 107;
    uint constant NOT_ENOUGH_ALLOWANCE = 108;
    uint constant ALREADY_HAVE_THIS_TOKEN = 109;
    uint constant ZERO_TOKEN_ID = 110;
    uint constant ZERO_DEST_ADDR = 111;

    // Structs:
    struct AllowanceInfo {
        address spender;
        uint256 tokenId;
    }
    
    // State variables:
    bytes static m_name;
    bytes static m_symbol;
    uint8 static m_decimals;
    
    address static m_creator_address;
    address static m_root_address;
    uint256 static m_creator_public_key;
    uint256 static m_root_public_key;

    TvmCell static m_code;

    string m_front_side_image;
    string m_back_side_media;

    address m_curator;
    uint8 m_curator_percent;
    uint8 m_creator_percent;
    
    address m_numi_event;

    optional(AllowanceInfo) m_allowance;
    mapping(uint256 => bool) tokens;


    constructor(string front_side_image, string back_side_media, address curator, uint8 curator_percent, uint8 creator_percent, address numi_event) public {
        require(msg.sender == m_root_address, MESSAGE_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();

        m_front_side_image = front_side_image;
        m_back_side_media = back_side_media;
        m_curator = curator;
        m_curator_percent = curator_percent;
        m_creator_percent = creator_percent;
        m_numi_event = numi_event;
    }

    function accept(uint256 tokenId) external override {
        require(m_root_address == msg.sender, MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(!tokens.exists(tokenId), ALREADY_HAVE_THIS_TOKEN);
        require(tokenId > uint256(0), ZERO_TOKEN_ID);
        tvm.accept();

        tokens.add(tokenId, true);
    }

    function transfer(address dest, uint256 tokenId, uint128 grams) override external {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(dest != address(0), ZERO_DEST_ADDR);
        require(tokens.exists(tokenId), NOT_ENOUGH_BALANCE);
        tvm.accept();

        ITONTokenWalletNF(dest).internalTransfer{value: grams, bounce: false, flag: 1}(tokenId, m_creator_public_key);

        delete tokens[tokenId];
    }

    function internalTransfer(uint256 tokenId, uint256 pubkey) external override {
        address expected_address = getExpectedAddress(pubkey);
        address sender = msg.sender;

        require(sender == expected_address, MESSAGE_SENDER_IS_NOT_GOOD_WALLET);
        require(tokenId > uint256(0), ZERO_TOKEN_ID);
        require(!tokens.exists(tokenId), ALREADY_HAVE_THIS_TOKEN);

        tokens.add(tokenId, true);
    }

    function approve(address spender, uint256 tokenId) external override {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(tokenId > uint256(0), ZERO_TOKEN_ID);
        require(tokens.exists(tokenId), NOT_ENOUGH_BALANCE);
        tvm.accept();

        m_allowance.set(AllowanceInfo(spender, tokenId));
    }

    function transferFrom(address dest, address to, uint256 tokenId, uint128 grams) external override {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        require(tokenId > uint256(0), ZERO_TOKEN_ID);
        tvm.accept();

        ITONTokenWalletNF(dest).internalTransferFrom{value: grams, flag: 1}(to, tokenId);
    }

    function internalTransferFrom(address to, uint256 tokenId) external override {
        require(m_allowance.hasValue(), NO_ALLOWANCE_SET);
        require(msg.sender == m_allowance.get().spender, WRONG_SPENDER);
        require(tokenId > uint256(0), ZERO_TOKEN_ID);
        require(tokenId == m_allowance.get().tokenId, NOT_ENOUGH_ALLOWANCE);
        require(tokens.exists(tokenId), NOT_ENOUGH_BALANCE);

        ITONTokenWalletNF(to).internalTransfer{value: 0, bounce: true, flag: 128}(tokenId, m_creator_public_key);
        
        m_allowance.set(AllowanceInfo(address(0), uint256(0)));

        delete tokens[tokenId];
    }

    function getTokenByIndex(uint256 tokenId) public view returns (uint256) {
        require (tokens.exists(tokenId), NOT_ENOUGH_BALANCE);
        return tokenId;
    }

    function disapprove() external override {
        require(tvm.pubkey() == msg.pubkey(), MESSAGE_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();

        m_allowance.set(AllowanceInfo(address(0), uint256(0)));
    }

    function getExpectedAddress(uint256 sender_public_key) private inline view returns(address){
        TvmCell stateInit = tvm.buildStateInit({
            contr: TONTokenWalletNF,
            varInit: {
                m_name: m_name,
                m_symbol: m_symbol,
                m_decimals: m_decimals,
                m_creator_address: m_creator_address,
                m_root_public_key: m_root_public_key,
                m_creator_public_key: sender_public_key,
                m_root_address: m_root_address,
                m_code: m_code
            },
            pubkey: sender_public_key,
            code: m_code
        });

        return address(tvm.hash(stateInit));
    }

    function getDetails() override external view returns (ITONTokenWalletDetails) {
        return ITONTokenWalletDetails(
            m_creator_public_key,
            m_root_public_key,
            m_root_address,
            m_code
        );
    }

    onBounce(TvmSlice slice) external {
        //
    } 

    fallback() external {
    }
}