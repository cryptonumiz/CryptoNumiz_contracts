pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

// import required DeBot interfaces and basic DeBot contract.
import "./interfaces/debot/Debot.sol";
import "./interfaces/debot/Terminal.sol";
import "./interfaces/debot/Menu.sol";
import "./interfaces/debot/ConfirmInput.sol";
import "./interfaces/debot/AddressInput.sol";
import "./interfaces/debot/Sdk.sol";
import "./interfaces/debot/Upgradable.sol";

import "./interfaces/IRootNumiUser.sol";
import "./interfaces/INumiUser.sol";

interface IMsig {
    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}


contract NumiDebot is Debot, Upgradable {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_NUMI_USER_ROOT_NOT_SET = 103;

    // State:
    address m_root_address;

    address m_creator_address;
    uint256 m_creator_pubkey;

    address m_user_address;
    string m_username;
    string m_bio;
    uint128 m_balance;

    // Struct:

    struct INumiUserDetails {
        address root_address;
        address owner_address;
        uint256 owner_pubkey;
        string username;
        string bio;
        uint128 balance;
        TvmCell code;
    }

    function setNumiUserRoot(address _root_address) public {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        m_root_address = _root_address;
    }

    /// @notice Entry point function for DeBot.
    function start() public override {
        if (m_root_address == address(0)) {
            Terminal.print(0,format("Debot is temporarily unavailable.\nError code: {}\nPlease contact with developer!", ERROR_NUMI_USER_ROOT_NOT_SET));
        } else {
            Menu.select("Hello, it's CryptoNumiz DeBot. I will help you interact with our services!", "", [
                MenuItem("Connect my wallet","",tvm.functionId(menuConnectMyWallet))
            ]);
        }
    }

    function menuConnectMyWallet(uint32 index) public {
        AddressInput.get(tvm.functionId(setCreatorAddress), format("Please, select your Main account:"));
    }

    function setCreatorAddress(address value) public {
        m_creator_address = value;
        menuConnectMyPubkey(0);
    }

    function menuConnectMyPubkey(uint32 index) public {
        Terminal.input(tvm.functionId(checkAccountStep1),"Enter public key attached to your account:",false);
    }

    function checkAccountStep1(string value) public {
        (uint256 res, bool status) = stoi("0x"+value);
        
        if (status) {        
            m_creator_pubkey = res;    

            optional(uint256) none;
            IRootNumiUser(m_root_address).getExpectedAddress{
                abiVer: 2,
                extMsg: true,
                callbackId: tvm.functionId(checkAccountStep2),
                onErrorId: 0,
                time: 0,
                expire: 0,
                sign: false,
                pubkey: none
            }(m_creator_address, m_creator_pubkey);
        } else {
            Terminal.input(tvm.functionId(checkAccountStep1),"Wrong public key. Try again!\nEnter public key attached to your account:",false);
        }
    }

    function checkAccountStep2(address value) public {
        m_user_address = value;
        Sdk.getAccountType(tvm.functionId(checkAccountStep3), m_user_address);
    }

    function checkAccountStep3(int8 acc_type) public {
        if ((acc_type == 0) || (acc_type == -1)) {
            ConfirmInput.get(tvm.functionId(registerStep1),format("Do you want to enter your username and bio?"));
        } else if (acc_type == 1) {
            optional(uint256) none;
            INumiUser(m_user_address).getDetails{
                abiVer: 2,
                extMsg: true,
                callbackId: tvm.functionId(menuMainProxy),
                onErrorId: 0,
                time: 0,
                expire: 0,
                sign: false,
                pubkey: none
            }();
        } else if (acc_type == 2) {
            Terminal.print(tvm.functionId(Debot.start),"Account is frozen!");
        }
    }

    function registerStep1(bool value) public {
        if (value) {
            menuSetUsername(0);
        } else {
            m_username = "";
            m_bio = "";
            createUserStep1(0);
        }
    }

    function menuSetUsername(uint32 index) public {
        Terminal.input(tvm.functionId(setUsername),"Enter your username:", false);
    }

    function setUsername(string value) public {
        m_username = value;
        menuSetBio(0);
    }

    function menuSetBio(uint32 index) public {
        Terminal.input(tvm.functionId(setBio),"Enter your bio:", false);
    }

    function setBio(string value) public {
        m_bio = value;
        createUserStep1(0);
    }

    function createUserStep1(int32 index) public {
        ConfirmInput.get(tvm.functionId(createUserStep2),format("Do you want to send 0.1 TON for create account?"));
    }

    function createUserStep2(bool value) public {
        if (value) {
        optional(uint256) pubkey = 0;
        TvmCell empty;

        IMsig(m_creator_address).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(createUserStep3),
            onErrorId: tvm.functionId(onSendTransactionError)
        }(m_root_address, 100000000, false, 1, empty);
        } else {
            Terminal.input(tvm.functionId(Debot.start),"Terminated!",false);
        }
    }

    function onSendTransactionError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Transaction sent failed. Sdk error = {}, Error code = {}", sdkError, exitCode));
        Terminal.print(0, "Retrying..");
        createUserStep1(0);
    }

    function createUserStep3() public {
        Terminal.print(0, "Transaction sent successfully!\nCreating account....");
        createUser(0);
    }

    function createUser(uint32 index) public view {
        _deployUser();
    }

    function _deployUser() private view {
        optional(uint256) pubkey = 0;
        IRootNumiUser(m_root_address).deployUser{
            abiVer: 2,
            extMsg: true,
            callbackId: tvm.functionId(menuAfterCreate),
            onErrorId: tvm.functionId(onDeployUserError),
            time: uint64(now),
            expire: 0,
            sign: true,
            pubkey: pubkey
        }(m_creator_address, m_username, m_bio, 50000000);
    }

    function onDeployUserError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Deploy failed. Sdk error = {}, Error code = {}", sdkError, exitCode));
        Terminal.print(tvm.functionId(Debot.start), "Terminated!");
    }

    function menuAfterCreate(address value) public {
        if (m_user_address == value) {
            Terminal.print(0, "Account has been successfully created!");
            menuMain(0);
        } else {
            Terminal.print(tvm.functionId(Debot.start), "The expected address does not match the actual one!");
        }
    }

    function menuMain(uint32 index) public {
        Menu.select("Let's get started!", "", [
            MenuItem("My profile","",tvm.functionId(menuShowProfileProxy)),
            MenuItem("My Numiz","",tvm.functionId(menuMain)),
            MenuItem("Show events","",tvm.functionId(menuMain))
        ]);
    }

    function menuMainProxy(INumiUserDetails user) public {
        m_username =  user.username;
        m_bio = user.bio;
        m_balance = user.balance;

        menuMain(0);
    }

    function menuShowProfileProxy(uint32 index) public {
        if (m_user_address != address (0)) {
            _getUserDetails(tvm.functionId(menuShowProfile));
        } else {
            Terminal.print(tvm.functionId(Debot.start), "Terminated!");
        }
    }
 
    function menuShowProfile(INumiUserDetails user) public {
        Terminal.print(0, format("Your profile\nAddress: {}\nBalance: {:t} TON\nUsername: {}\nBio: {}", m_user_address, user.balance, user.username, user.bio)); 
        Menu.select("\nActions:", "", [
            MenuItem("Edit profile","",tvm.functionId(menuMain)),
            MenuItem("Back","",tvm.functionId(menuMain))
        ]);
    }

    function _getUserDetails(uint32 callbackFuncId) private view {
        optional(uint256) none;
        INumiUser(m_user_address).getDetails{
            abiVer: 2,
            extMsg: true,
            callbackId: callbackFuncId,
            onErrorId: 0,
            time: 0,
            expire: 0,
            sign: false,
            pubkey: none
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }

    function getVersion() public override returns (string name, uint24 semver) {
        (name, semver) = ("CryptoNumiz DeBot", _version(0,1,0));
    }

    function _version(uint24 major, uint24 minor, uint24 fix) private pure inline returns (uint24) {
        return (major << 16) | (minor << 8) | (fix);
    }
}
