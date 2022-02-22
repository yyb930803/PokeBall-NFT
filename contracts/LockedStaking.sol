// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface StakingInterface {
    function votingPowerOf(address acc, uint256 until) external view returns(uint256);
}

contract LockedStaking is Ownable, StakingInterface {
    using SafeMath for uint256;
    IERC20 public BALL;

    bool isClosed = false;

    // quadratic reward curve constants
    // a + b*x + c*x^2
    uint256 public A = 187255; // 1.87255
    uint256 public B = 29854;  // 0.2985466*x
    uint256 public C = 141;    // 0.001419838*x^2

    uint256 public maxDays = 365;
    uint256 public minDays = 6;

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;

    uint256 public earlyExit = 0;

    struct StakeInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }

    mapping (address=>StakeInfo) public stakes;

    constructor(address _BALL) {
        BALL = IERC20(_BALL);
    }

    function stake(uint256 _amount, uint256 _days) public {
        require(_days > minDays, "less than minimum staking period");
        require(_days < maxDays, "more than maximum staking period");
        require(stakes[msg.sender].payday == 0, "already staked");
        require(_amount > 100, "amount to small");
        require(!isClosed, "staking is closed");

        // calculate reward
        uint256 _reward = calculateReward(_amount, _days);

        // contract must have funds to keep this commitment
        require(BALL.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "insufficient contract bal");

        require(BALL.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        stakes[msg.sender].payday = block.timestamp.add(_days * (1 days));
        stakes[msg.sender].reward = _reward;
        stakes[msg.sender].startday = block.timestamp;
        stakes[msg.sender].initial = _amount;

        // update stats
        totalStaked = totalStaked.add(_amount);
        totalRewards = totalRewards.add(_reward);
    }

    function claim() public {
        require(owedBalance(msg.sender) > 0, "nothing to claim");
        require(block.timestamp > stakes[msg.sender].payday.sub(earlyExit), "too early");

        uint256 owed = stakes[msg.sender].reward.add(stakes[msg.sender].initial);

        // update stats
        totalStaked = totalStaked.sub(stakes[msg.sender].initial);
        totalRewards = totalRewards.sub(stakes[msg.sender].reward);

        stakes[msg.sender].initial = 0;
        stakes[msg.sender].reward = 0;
        stakes[msg.sender].payday = 0;
        stakes[msg.sender].startday = 0;

        require(BALL.transfer(msg.sender, owed), "transfer failed");
    }

    function calculateReward(uint256 _amount, uint256 _days) public view returns (uint256) {
        uint256 _multiplier = _quadraticRewardCurveY(_days);
        uint256 _AY = _amount.mul(_multiplier);
        return _AY.div(10000000);

    }

    // a + b*x + c*x^2
    function _quadraticRewardCurveY(uint256 _x) public view returns (uint256) {
        uint256 _bx = _x.mul(B);
        uint256 _x2 = _x.mul(_x);
        uint256 _cx2 = C.mul(_x2);
        return A.add(_bx).add(_cx2);
    }

    // helpers:
    function totalOwedValue() public view returns (uint256) {
        return totalStaked.add(totalRewards);
    }

    function owedBalance(address acc) public view returns(uint256) {
        return stakes[acc].initial.add(stakes[acc].reward);
    }

    function votingPowerOf(address acc, uint256 until) external override view returns(uint256) {
        if (stakes[acc].payday > until) {
            return 0;
        }

        return owedBalance(acc);
    }

    // owner functions:
    function setLimits(uint256 _minDays, uint256 _maxDays) public onlyOwner {
        minDays = _minDays;
        maxDays = _maxDays;
    }

    function setCurve(uint256 _A, uint256 _B, uint256 _C) public onlyOwner {
        A = _A;
        B = _B;
        C = _C;
    }

    function setEarlyExit(uint256 _earlyExit) public onlyOwner {
        require(_earlyExit < 2880000, "too big");
        close(true);
        earlyExit = _earlyExit;
    }

    function close(bool closed) public onlyOwner {
        isClosed = closed;
    }

    function ownerReclaim(uint256 _amount) public onlyOwner {
        require(_amount < BALL.balanceOf(address(this)).sub(totalOwedValue()), "cannot withdraw owed funds");
        BALL.transfer(msg.sender, _amount);
    }

    function flushBNB() public onlyOwner {
        require(address(this).balance >= 1, "should be bigger than 1");
        uint256 bal = address(this).balance.sub(1);
        payable(msg.sender).transfer(bal);
    }

}