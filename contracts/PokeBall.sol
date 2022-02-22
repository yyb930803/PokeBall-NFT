// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract PokeBall is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public maxSupply = 10**9 * 10**9;

    address public feeAddress;
    uint256 public transferFeeRate;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), maxSupply);
        transferFeeRate = 5; // 5% buy, 1% sell: transaction fee
        feeAddress = _msgSender();
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        transferFeeRate = _feeRate;
    }

    /**
     * transfer override method to implement transaction fee
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            transferFeeRate > 0 &&
            recipient != address(0) &&
            feeAddress != address(0)
        ) {
            // sell fee
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            // buy fee
            // uint256 _buyfee = amount.div(100);
            // super._transfer(sender, feeAddress, _fee.add(_buyfee)); // TransferFee
            // amount = amount.sub(_fee);

            super._transfer(sender, feeAddress, _fee); // TransferFee
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function estimateTotalTransferValue(uint256 sendAmount) external pure returns (uint256) {
        // buy fee 1%
        uint256 _buyfee = sendAmount.div(100);
        return sendAmount.add(_buyfee);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "0x is not accepted here");

        feeAddress = _feeAddress;
    }
}