/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';

contract PokeBallNFT is ERC721Enumerable, Ownable, ERC721Pausable, ERC721Burnable  {
    using SafeMath for uint256;
    IERC20 public BALL;

    struct Ball {
        uint256 id;
        string hash_value;      // ipfs CID for art
        string name;            // item name
        uint256 price;          // item price with decimal
        uint256 createdAt;      // block stamp
    }

    event BallUpdated(
        uint256 indexed id,
        string hash_value,
        string name,
        uint256 price,
        uint256 updatedAt
    );

    event Spawn(uint256 indexed ballId, string name, string hash_val, uint256 price, uint256 createdAt);
    event Mint(uint256 indexed tokenId, address to, uint256 ballId);

    uint256 public latestTokenId;
    uint256 public latestBallId;
    
    uint256 public MIN_PRICE = 1 * 10**9;
    uint256 public MAX_MINTBY = 10;
    uint256 public MAX_ELEMENTS = 10**18;
    address public creatorAddress;
    address public devAddress;

    string public baseURI;

    mapping(uint256 => Ball) internal balls;    // category of balls
    mapping(uint256 => Ball) internal tokensInfo;   // tokenInfo according to tokenId
    mapping(address => bool) public spawners;
    mapping(uint256 => bool) public tokensLock;
    mapping(address => bool) public usersLock;
    mapping(uint256 => bool) public ballsLock;

    address public migrator;

    constructor(string memory _name, string memory _symbol, address _BALL)
        ERC721(_name, _symbol)
    {
        _setBaseURI("ipfs://");

        BALL = IERC20(_BALL);

        creatorAddress = msg.sender;
        devAddress = msg.sender;
        pause(true);
    }


    modifier saleIsOpen {
        require(totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal {
        baseURI = baseURI_;
    }
    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);

        _incrementTokenId();
    }

    // This is main mint function
    function spawn(
        string memory _hash_value,
        string memory _name,
        uint256 _price
    ) public onlyOwner {
        require(_price >= MIN_PRICE, "Price belows under MIN_PRICE");

        uint256 nextBallId = latestBallId.add(1);
        uint256 _createdAt = block.timestamp;

        balls[nextBallId] = Ball({
            id: nextBallId,
            hash_value: _hash_value,
            name: _name,
            price: _price,
            createdAt: _createdAt
        });
        
        latestBallId++;

        emit Spawn(nextBallId, _name, _hash_value, _price, _createdAt);
    }

    // This is main mint function
    function mint(address to, uint256 _ballId) internal {
        require(!ballsLock[_ballId], "This ball was blocked");
        require(!usersLock[to], "User Locked");
        require(_ballId <= latestBallId, "The ball does not exist");

        uint256 nextTokenId = _getNextTokenId();
        _mint(to, nextTokenId);

        tokensInfo[nextTokenId] = balls[_ballId];

        emit Mint(nextTokenId, to, _ballId);
    }

    // This is multi mint
    function multiMint(address to, uint256 _ballId, uint256 _count, uint256 _amount) public saleIsOpen{
        require(to != address(0), "No contracts permitted");
        require(MAX_MINTBY >= _count, "You limited the max mint amount");
        require(balls[_ballId].price.mul(_count) == _amount, "Payment is not correct");
        
        BALL.transferFrom(msg.sender, address(this), _amount);

        for (uint256 i = 0; i < _count; i++) {
            mint(to, _ballId);
        }
    }

    function migrate(
        uint256 _ballId,
        string memory _hash_value,
        string memory _name,
        uint256 _price
    ) public onlyOwner {
        require(_price >= MIN_PRICE, "Price belows under MIN_PRICE");
        require(_ballId <= latestBallId, "Outbound of array");
        require(!ballsLock[_ballId], "This ball was locked");

        Ball storage ball = balls[_ballId];

        ball.hash_value = _hash_value;
        ball.name = _name;
        ball.price = _price;

        emit BallUpdated(_ballId, _hash_value, _name, _price, block.timestamp);
    }

    function setLockBall(uint256 _ballId, bool _bool) public onlyOwner {
        require(latestBallId >= _ballId, "Ball doesn't exist");
        require(ballsLock[_ballId] != _bool, "Already set");
        ballsLock[_ballId] = _bool;
    }

    function setTokenLock(uint256 _tokenId, bool _bool) public onlyOwner {
        tokensLock[_tokenId] = _bool;
    }

    function setTokensLock(uint256[] memory _tokensId, bool _bool)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _tokensId.length; index++) {
            tokensLock[_tokensId[index]] = _bool;
        }
    }

    function setUserLock(address _user, bool _bool) public onlyOwner {
        usersLock[_user] = _bool;
    }

    function setMaxMintAmount(uint256 _amount) public onlyOwner {
        require(MAX_MINTBY != _amount, "Already set");
        MAX_MINTBY = _amount;
    }

    function setMaxElemsAmount(uint256 _amount) public onlyOwner {
        require(MAX_ELEMENTS != _amount, "Already set");
        MAX_ELEMENTS = _amount;
    }

    function _getNextTokenId() private view returns (uint256) {
        return latestTokenId.add(1);
    }

    function _incrementTokenId() private {
        latestTokenId++;
    }

    function getBallInfo(uint256 _id) public view returns (Ball memory) {
        require(latestBallId > _id, "Out bound of array");
        return balls[_id];
    }

    function getTokenInfo(uint256 _tokenId) public view returns (Ball memory) {
        require(latestTokenId >= _tokenId, "Token not exist");
        return tokensInfo[_tokenId];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (usersLock[to] || tokensLock[tokenId]) {
            revert("locked.");
        }

        return super._transfer(from, to, tokenId);
    }

    function setMinPrice(uint256 _count) public onlyOwner {
        require(MIN_PRICE != _count, "This value was already set");
        MIN_PRICE = _count;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(25).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }


    function setDevWallet(address _new_dev) public onlyOwner {
        devAddress = _new_dev;
    }

    function setCreatorWallet(address _new_creator) public onlyOwner {
        creatorAddress = _new_creator;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isApproved(uint256 _tokenId, address _spender) external view returns (bool){
        return super._isApprovedOrOwner(_spender, _tokenId);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        if(ballsLock[_tokenId] == true) return false;
        return super._exists(_tokenId);
    }
}