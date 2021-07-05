pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/INftData.sol';

contract NftData is INftData {
    address _addrRoot;
    address _addrOwner;
    address _addrAuthor;
    address _addrCurator;
    address _addrEvent;
    uint256 static _id;

    string _name;
    string _description;
    address _frontSideStorage;
    address _backSideStorage;
    uint8 _authorPercentageOfSale;
    uint8 _curatorPercentageOfSale;
    bool _isForSale;
    bool _isForAuction;
    uint64 _creationDate;

    constructor(
        address addrOwner,
        address addrAuthor,
        address addrCurator,
        address addrEvent,
        string name,
        string description,
        address frontSideStorage,
        address backSideStorage,
        uint8 authorPercentageOfSale,
        uint8 curatorPercentageOfSale,
        bool isForSale,
        bool isForAuction,
        uint64 creationDate,
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 102);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, 100);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
        _addrCurator = addrCurator;
        _addrEvent = addrEvent;
        _name = name;
        _description = description;
        _frontSideStorage = frontSideStorage;
        _backSideStorage = backSideStorage;
        _authorPercentageOfSale = authorPercentageOfSale;
        _curatorPercentageOfSale = curatorPercentageOfSale;
        _isForSale = isForSale;
        _isForAuction = isForAuction;
        _creationDate = creationDate;
    }

    function setOwner(address addrOwner) public override {
        require(msg.sender == _addrRoot, 100);
        _addrOwner = addrOwner;
    }

    function getOwner() public view returns(address addrOwner, address addrNftData) {
        addrOwner = _addrOwner;
        addrNftData = address(this);
    }

    function getInfo() public view
    returns(
        address owner,
        address author,
        address curator,
        address addrEvent,
        string name,
        string description,
        address frontSideStorage,
        address backSideStorage,
        uint8 authorPercentageOfSale,
        uint8 curatorPercentageOfSale,
        bool isForSale;
        bool isForAuction;
        uint64 creationDate
    ) {
        tvm.accept();
        owner = _addrOwner;
        author = _addrAutho;
        curator = _addrCurator;
        addrEvent = _addrEvent;
        name = _name;
        description = _description;
        frontSideStorage = _frontSideStorage;
        backSideStorage = _backSideStorage;
        authorPercentageOfSale = _authorPercentageOfSale;
        curatorPercentageOfSale = _curatorPercentageOfSale;
        isForSale = _isForSale;
        isForAuction = _isForAuction;
        creationDate = _creationDate;
    }

    function destruct(address recipient) public {
        require(msg.sender == _addrRoot, 100);

        recipient.transfer(0, false, 64);
        selfdestruct(recipient);
    }

}
