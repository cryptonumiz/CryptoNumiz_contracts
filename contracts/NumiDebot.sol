pragma ton-solidity >= 0.46.0;
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
import "./interfaces/debot/SigningBoxInput.sol";

import "NumiUser.sol";
import "RootNumiEvent.sol";

struct CustodianInfo {
    uint8 index;
    uint256 pubkey;
}

struct INumiUserDetails {
    address owner_address;
    uint256 owner_pubkey;
    string username;
    string bio;
    uint128 balance;
}

interface IMsig {
    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
    function getCustodians() external returns (CustodianInfo[] custodians);
}

contract NumiDebot is Debot, Upgradable {
    // Error codes:
    uint constant ERROR_NO_PUBKEY = 101;
    uint constant ERROR_SENDER_IS_NOT_MY_OWNER = 102;
    uint constant ERROR_NO_SENDER = 103;

    uint constant USERNAME_MAX_LENGTH = 15;
    uint constant BIO_MAX_LENGTH = 300;

    // State:
    address m_userOwnerAddress;
    uint256 m_userOwnerPubkey;

    address m_userAddress;
    uint32 m_userSB;
    mapping(uint => string) m_userEventsTitle;

    uint32 m_gotoId;

    bytes m_icon;

    TvmCell m_userImage;
    TvmCell m_eventRootImage;
    TvmCell m_eventImage;

    optional(NumiEventDetails) newEvent;

    function setIcon(bytes icon) public {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        m_icon = icon;
    }

    function setUserImage(TvmCell image) public {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        m_userImage = image;
    }

    function setEventRootImage(TvmCell image) public {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        m_eventRootImage = image;
    }

    function setEventImage(TvmCell image) public {
        require(msg.pubkey() == tvm.pubkey(), ERROR_SENDER_IS_NOT_MY_OWNER);
        tvm.accept();
        m_eventImage = image;
    }

    ///////////////////////////////////////////

    function fillNewEventDetails(string title, string description, uint64 startTimestamp, uint64 endTimestamp, address coverImage, address substrateImage) public {
        newEvent.set(NumiEventDetails(
            title,
            description,
            startTimestamp,
            endTimestamp,
            coverImage,
            substrateImage
        ));

        m_gotoId = tvm.functionId(startCreatingEvent);

        _start();
    }

    /// @notice Entry point function for DeBot.
    function start() public override {
        _start();
    }

    function _start() private {
        if (m_userOwnerAddress != address(0) && m_userOwnerPubkey != uint256(0) && m_userSB != uint32(0) && m_userAddress != address(0)) {
            Sdk.getAccountType(tvm.functionId(checkUserAccountType), m_userAddress);
        } else {
            Menu.select("Hello, it's CryptoNumiz DeBot. I will help you interact with our services!", "", [
                MenuItem("Connect my wallet","",tvm.functionId(connectWallet))
            ]);
        }
    }

    function connectWallet(uint32 index) public {
        index;
        AddressInput.get(tvm.functionId(setUserOwnerAddress), format("Please, select your Main account:"));
    }

    function setUserOwnerAddress(address value) public {
        m_userOwnerAddress = value;
        Sdk.getAccountCodeHash(tvm.functionId(checkWalletHash), m_userOwnerAddress);
    }

    function checkWalletHash(uint256 code_hash) public {
        if (code_hash != 0x207dc560c5956de1a2c1479356f8f3ee70a59767db2bf4788b1d61ad42cdad82 &&
            code_hash != 0x80d6c47c4a25543c9b397b71716f3fae1e2c5d247174c52e2c19bd896442b105) {
                Terminal.print(tvm.functionId(Debot.start),"Wallet is not valid!");
            } else {
                _getCustodians(m_userOwnerAddress, tvm.functionId(setUserOwnerPubkey));
            }
    }

    function setUserOwnerPubkey(CustodianInfo[] custodians) public {
        (, uint256 pubkey) = custodians[0].unpack();
        m_userOwnerPubkey = pubkey;
        m_userAddress = address(tvm.hash(buildUserState(m_userOwnerAddress, m_userOwnerPubkey)));

        getSigningBox();
    }

    function getSigningBox() public {
        uint256[] keys = [m_userOwnerPubkey];
        SigningBoxInput.get(tvm.functionId(setSigningBoxHandle), "Sign for confirmation:", keys);
    }

    function setSigningBoxHandle(uint32 handle) public {
        m_userSB = handle;
        
        Sdk.getAccountType(tvm.functionId(checkUserAccountType), m_userAddress);
    }

    function _getAccountType(address dest, uint32 answerId) private {
        Sdk.getAccountType(answerId, dest);
    }

    function checkUserAccountType(int8 acc_type) public {
        if (acc_type == 1) {
            mainMenu();
        } else if (acc_type == -1) {
            startRegister();
        } else if (acc_type == 0) {
            askToPayForDeployUser();
        } else if (acc_type == 2) {
            Terminal.print(tvm.functionId(Debot.start), "Account is frozen!");
        } else {
            Terminal.print(tvm.functionId(Debot.start), "Terminated!");
        }
    }

    function startRegister() public {
        Terminal.print(tvm.functionId(askToPayForDeployUser), "First of all, you need to create an account!\nIt is not necessary to fill in your account details, you can do it later!");
        //ConfirmInput.get(tvm.functionId(needEnteryProfileData), format("Do you want to enter your username and bio?"));
    }

    function askToPayForDeployUser() public {
        ConfirmInput.get(tvm.functionId(createUser),format("Do you want to send 0.15 TON for create account?"));
    }

    function createUser(bool value) public {
        if (value) {
            TvmCell body = tvm.encodeBody(NumiDebot.deployUser, m_userOwnerAddress, m_userOwnerPubkey);
            callMsig(address(this), body, 0.15 ton, tvm.functionId(onDeployUserSuccess), tvm.functionId(onDeployUserError));
        } else {
            Terminal.print(tvm.functionId(startRegister), "Try again..");
        }
    }

    function onDeployUserSuccess() public {
        checkUserAccountStatus(0);
    }

    function checkUserAccountStatus(uint32 index) public {
        index;
        Sdk.getAccountType(tvm.functionId(waitForDeployAccount), m_userAddress);
    }

    function onDeployUserError(uint32 sdkError, uint32 exitCode) public {
        if (sdkError == uint32(812)) {
            Terminal.print(tvm.functionId(askToPayForDeployUser), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
        } else {
            Terminal.print(tvm.functionId(Debot.start), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
        }
    }

    function waitForDeployAccount(int8 acc_type) public {
        if (acc_type != 1) {
            Menu.select("Waiting for the account creating...", "", [ MenuItem("Check again", "", tvm.functionId(checkUserAccountStatus)) ]);
        } else {
            Terminal.print(tvm.functionId(mainMenu), "Account has been successfully created!");
        }
    }

    function _mainMenu(uint32 index) public {
        index = 0;
        mainMenu();
    }

    function mainMenu() public {
        if (m_gotoId == tvm.functionId(startCreatingEvent)) {
            startCreatingEvent();
        } else {
            Menu.select("Let's get started!", "", [
                MenuItem("My Profile","",tvm.functionId(menuShowProfile)),
                MenuItem("My Numiz","",tvm.functionId(_mainMenu)),
                MenuItem("My Events","",tvm.functionId(menuMyEvents))
            ]);
        }
    }

    //
    // My profile menu
    //

    function gotoMenuShowProfile() public view {
        menuShowProfile(0);
    }

    function menuShowProfile(uint32 index) public view {
        index;
        _getDetails(m_userAddress, tvm.functionId(showProfile));
    }

    function showProfile(INumiUserDetails user) public {
        string strBalance = format("\nBalance: {:t}", user.balance);
        string strUsername = user.username.empty() ? "" : format("\nUsername: {}", user.username);
        string strBio = user.bio.empty() ? "" : format("\nBio: {}", user.bio);
        string strLink = format("\n\nhttps://auction.cryptonumiz.org/user/{}", m_userAddress);

        string strProfile = format("Your profile{}{}{}{}", strBalance, strUsername, strBio, strLink);

        Terminal.print(0, strProfile);
        Menu.select("Actions:", "", [
            MenuItem("Edit profile","",tvm.functionId(menuEditProfile)),
            MenuItem("Main menu","",tvm.functionId(_mainMenu))
        ]);
    }

    function menuEditProfile(uint32 index) public {
        index = 0;
        Menu.select("What do you want to edit?", "", [
            MenuItem("Edit username","",tvm.functionId(menuEditUsername)),
            MenuItem("Edit bio","",tvm.functionId(menuEditBio)),
            MenuItem("Back","",tvm.functionId(menuShowProfile))
        ]);
    }

    function menuEditUsername(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(setUsername),"Enter your new username:", false);
    }

    function setUsername(string value) public {
        if (value.byteLength() > USERNAME_MAX_LENGTH) {
            ConfirmInput.get(tvm.functionId(retrySetUsername), format("Username too long! (max length {}).\nTry again?", USERNAME_MAX_LENGTH));
        } else {
            TvmCell body = tvm.encodeBody(NumiUser.setUsername, value);
            callMsig(m_userAddress, body, 0.01 ton, tvm.functionId(onSetUsernameSuccess), tvm.functionId(onSetUsernameError));
        }
    }

    function retrySetUsername(bool value) public {
        if (value) {
            menuEditUsername(0);
        } else {
            menuShowProfile(0);
        }
    }

    function onSetUsernameSuccess() public {
        Terminal.print(tvm.functionId(gotoMenuShowProfile), "Username changed successfully!");
    }

    function onSetUsernameError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(tvm.functionId(gotoMenuShowProfile), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
    }

    function menuEditBio(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(setBio),"Enter your new bio:", false);
    }

    function setBio(string value) public {
        if (value.byteLength() > BIO_MAX_LENGTH) {
            ConfirmInput.get(tvm.functionId(retrySetBio), format("Bio too long! (max length {}).\nTry again?", BIO_MAX_LENGTH));
        } else {
            TvmCell body = tvm.encodeBody(NumiUser.setBio, value);
            callMsig(m_userAddress, body, 0.01 ton, tvm.functionId(onSetBioSuccess), tvm.functionId(onSetBioError));
        }
    }

    function retrySetBio(bool value) public {
        if (value) {
            menuEditBio(0);
        } else {
            menuShowProfile(0);
        }
    }

    function onSetBioSuccess() public {
        Terminal.print(tvm.functionId(gotoMenuShowProfile), "Bio changed successfully!");
    }

    function onSetBioError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(tvm.functionId(gotoMenuShowProfile), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
    }

    //
    // My Numiz menu
    //

    //
    //  My Events menu
    //

    function _menuMyEvents() public {
        menuMyEvents(0);
    }

    function menuMyEvents(uint32 index) public {
        index = 0;

        Menu.select("Managing your events:", "", [
            MenuItem("Show my events","",tvm.functionId(menuShowMyEvents)),
            MenuItem("Create event","",tvm.functionId(menuCreateEvent)),
            MenuItem("Back","",tvm.functionId(_mainMenu))
        ]);
    }

    function menuShowMyEvents(uint32 index) public {
        index;
        Sdk.getAccountsDataByHash(
            tvm.functionId(setMyEvents),
            tvm.hash(buildEventCode()),
            address.makeAddrStd(-1, 0)
        );
    }

    function setMyEvents(AccData[] accounts) public {
        MenuItem[] items;

        for (uint i = 0; i < accounts.length; i++) {
            (, , ,address eventOwner) = accounts[i].data.toSlice().decode(uint256, uint64, bool, address);
            if (eventOwner == m_userAddress) {
                TvmSlice slice = accounts[i].data.toSlice().loadRefAsSlice();
                (, string eventTitle) = slice.decode(address, string);
                m_userEventsTitle[i] = eventTitle;

                items.push(MenuItem(format("{}", eventTitle), "", tvm.functionId(showMyEvent)) );
            }
        }

        items.push( MenuItem("Back", "", tvm.functionId(menuMyEvents)) );
        Menu.select("Your events:", "", items);
    }

    function showMyEvent(uint32 index) public {
        address eventAddress = calcEventAddress(m_userEventsTitle[index], m_userAddress, m_userOwnerPubkey);

        Menu.select(format("https://auction.cryptonumiz.org/event/{}", eventAddress), "", [
            MenuItem("Back","",tvm.functionId(menuMyEvents))
        ]);
    }

    function menuCreateEvent(uint32 index) public {
        index = 0;

        /*newEvent.set(NumiEventDetails(
            "Test title",
            "Test description",
            uint64(now),
            uint64(now) + uint64(30000),
            address(0),
            address(0)
        ));*/

        startCreatingEvent();
    }

    function startCreatingEvent() public {
        if (!newEvent.hasValue()) {
            delete m_gotoId;
            newEvent.reset();
            
            menuMyEvents(0);
            return;
        }

        if (m_userAddress == address(0)) {
            delete m_gotoId;
            newEvent.reset();

            _start();
            return;
        }

        Sdk.getAccountType(tvm.functionId(checkEventRootType), calcEventRootAddress(m_userAddress, m_userOwnerPubkey));      
    }

    function checkEventRootType(int8 acc_type) public {
        if (acc_type != 1) {
            ConfirmInput.get(tvm.functionId(createEventRoot), format("Needs to deploy Event Root to manage your events!"));
        } else {
            askToStartCreateEvent();
        }
    }

    function createEventRoot(bool value) public {
        if (value) {
            TvmCell body = tvm.encodeBody(NumiDebot.deployEventRoot, m_userAddress, m_userOwnerPubkey);
            callMsig(address(this), body, 0.1 ton, tvm.functionId(onDeployEventRootSuccess), tvm.functionId(onDeployEventRootError));
        } else {
            Terminal.print(tvm.functionId(_menuMyEvents), "Terminated!");
        }
    }

    function onDeployEventRootError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(tvm.functionId(_menuMyEvents), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
    }

    function onDeployEventRootSuccess() public {
        checkEventRootStatus(0);
    }

    function checkEventRootStatus(uint32 index) public {
        index;
        Sdk.getAccountType(tvm.functionId(waitForDeployEventRoot), calcEventRootAddress(m_userAddress, m_userOwnerPubkey)); 
    }

    function waitForDeployEventRoot(int8 acc_type) public {
        if (acc_type != 1) {
            Menu.select("Waiting for the Event Root creating...", "", [ MenuItem("Check again", "", tvm.functionId(checkEventRootStatus)) ]);
        } else {
            Terminal.print(tvm.functionId(askToStartCreateEvent), "Event Root has been successfully created. Now ready to create event!");
        }
    }

    function askToStartCreateEvent() public {
        ConfirmInput.get(
            tvm.functionId(createEvent),
            format(
                "Your new event:\n\nTitle: {}\nDescription: {}\nStart time: {}\nEnd time: {}\n\nCreate event for 0.1 TON?",
                newEvent.get().title,
                newEvent.get().description,
                newEvent.get().startTimestamp,
                newEvent.get().endTimestamp
            ));
    }

    function createEvent(bool value) public {
        if (value) {
            TvmCell body = tvm.encodeBody(NumiUser.createEvent, newEvent.get());
            callMsig(m_userAddress, body, 0.1 ton, tvm.functionId(onDeployEventSuccess), tvm.functionId(onDeployEventError));
        } else {
            delete m_gotoId;
            newEvent.reset();

            Terminal.print(tvm.functionId(_menuMyEvents), "Canceled!");
        }
    }

    function onDeployEventSuccess() public {
        delete m_gotoId;
        newEvent.reset();

        Terminal.print(tvm.functionId(_menuMyEvents), "Event successfully created!");
    }

    function onDeployEventError(uint32 sdkError, uint32 exitCode) public {
        delete m_gotoId;
        newEvent.reset();

        Terminal.print(tvm.functionId(menuMyEvents), format("Error: sdk code = {}, exit code = {}", sdkError, exitCode));
    }

    ///////////////////

    function _getDetails(address userAddr, uint32 answerId) private pure {
        optional(uint256) none;
        INumiUser(userAddr).getDetails{
            abiVer: 2,
            extMsg: true,
            callbackId: answerId,
            onErrorId: 0,
            time: uint64(now),
            expire: 0,
            sign: false,
            pubkey: none
        }();
    }

    function _getCustodians(address dest, uint32 answerId) private pure {
        optional(uint256) none;
        IMsig(dest).getCustodians{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    //
    // Helpers
    //

    function callMsig(address dest, TvmCell payload, uint128 value, uint32 answerId, uint32 errorHandler) private returns (bool){
        optional(uint256) pubkey = m_userOwnerPubkey;
        optional(uint32) userSigningBox = m_userSB;

        if (dest != address(this) && dest != m_userAddress) {
            Terminal.print(tvm.functionId(Debot.start), "Terminated!");
        } else {
            IMsig(m_userOwnerAddress).sendTransaction{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: 0,
                expire: 0,
                signBoxHandle: userSigningBox,
                callbackId: answerId,
                onErrorId: errorHandler
            }(dest, value, true, 2, payload);
        }
    }

    function buildUserState(address ownerAddress, uint256 ownerPubkey) private view returns (TvmCell image) {
        TvmBuilder saltBuilder;
        saltBuilder.store(address(this));
        TvmCell code = tvm.setCodeSalt(m_userImage.toSlice().loadRef(), saltBuilder.toCell());

        TvmCell newImage = tvm.buildStateInit({
            code: code,
            pubkey: ownerPubkey,
            varInit: {
                m_owner_address: ownerAddress,
                m_owner_pubkey: ownerPubkey,
                m_code: code
            },
            contr: NumiUser
        });

        image = newImage;
    }

    function calcUserAddress(address ownerAddress, uint256 ownerPubkey) private view returns (address) {
        return address(tvm.hash(buildUserState(ownerAddress, ownerPubkey)));
    }

    function buildRootEventState(address ownerAddress, uint256 ownerPubkey) private view returns (TvmCell image) {
        TvmBuilder saltBuilder;
        saltBuilder.store(address(this), ownerAddress);
        TvmCell code = tvm.setCodeSalt(
            m_eventRootImage.toSlice().loadRef(), 
            saltBuilder.toCell()
        );

        TvmCell newImage = tvm.buildStateInit({
            code: code,
            pubkey: ownerPubkey,
            varInit: {
                m_code: code
            },
            contr: RootNumiEvent
        });

        image = newImage;
    }

    function calcEventRootAddress(address ownerAddress, uint256 ownerPubkey) private view returns (address) {
        return address(tvm.hash(buildRootEventState(ownerAddress, ownerPubkey)));
    }

    function buildEventCode() private view returns (TvmCell) {
        TvmBuilder saltBuilder;
        saltBuilder.store(address(this));
        TvmCell code = tvm.setCodeSalt(
            m_eventImage.toSlice().loadRef(), 
            saltBuilder.toCell()
        );

        return code;
    }

    function calcEventAddress(bytes title, address ownerAddress, uint256 ownerPubkey) private view returns (address) {
        TvmCell code = buildEventCode();
        address rootAddr = calcEventRootAddress(ownerAddress, ownerPubkey);
        TvmCell newImage = tvm.buildStateInit({
            code: code,
            pubkey: ownerPubkey,
            varInit: {
                m_title: title,
                m_rootAddress: rootAddr,
                m_ownerAddress: ownerAddress,
                m_code: code
            },
            contr: NumiEvent
        });

        return address(tvm.hash(newImage));
    }

    //
    // Onchain functions
    //

    function deployUser(address ownerAddress, uint256 ownerPubkey) public view {
        require(msg.sender == ownerAddress, ERROR_SENDER_IS_NOT_MY_OWNER);
        require(ownerPubkey != uint256(0), ERROR_NO_PUBKEY);
        
        TvmCell state = buildUserState(ownerAddress, ownerPubkey);
        address eventRoot = calcEventRootAddress(address(tvm.hash(state)), ownerPubkey);
        
        new NumiUser{value: 0, flag: 64, stateInit: state}(eventRoot);
    }

    function deployEventRoot(address ownerAddress, uint256 ownerPubkey) public view {
        require(calcUserAddress(msg.sender, ownerPubkey) == ownerAddress, ERROR_SENDER_IS_NOT_MY_OWNER);

        TvmCell state = buildRootEventState(ownerAddress, ownerPubkey);
        new RootNumiEvent{value: 0, flag: 64, stateInit: state}(m_eventImage);
    }


    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "CryptoNumiz";
        version = "0.1.0";
        publisher = "CryptoNumiz";
        caption = "I will help you interact with our services!";
        author = "CryptoNumiz";
        support = address.makeAddrStd(0, 0x885e6fc88469145c7ed78b153bb57c8501c811558ca3f471c2c559f0cee0d447);
        hello = "Hello, it's CryptoNumiz DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, ConfirmInput.ID, AddressInput.ID, SigningBoxInput.ID ];
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}