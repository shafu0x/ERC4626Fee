// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/mixins/ERC4626.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

contract ERC4626Fee is ERC4626 {
  using SafeTransferLib for ERC20;

  constructor(
      ERC20 _asset,
      string memory _name,
      string memory _symbol
  ) ERC4626(_asset, _name, _symbol) {}

  function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
      uint balancePre = asset.balanceOf(receiver);
      // Need to transfer before minting or ERC777s could reenter.
      asset.safeTransferFrom(msg.sender, address(this), assets);
      uint actualAmount = asset.balanceOf(receiver) - balancePre;

      // Check for rounding error since we round down in previewDeposit.
      require((shares = previewDeposit(actualAmount)) != 0, "ZERO_SHARES");

      _mint(receiver, shares);

      emit Deposit(msg.sender, receiver, actualAmount, shares);

      afterDeposit(actualAmount, shares);
  }

  function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
    require(false, "NOT_IMPLEMENTED");
  }

  function withdraw(
      uint256 assets,
      address receiver,
      address owner
  ) public override returns (uint256 shares) {
      uint balancePre = asset.balanceOf(receiver);
      // Need to transfer before minting or ERC777s could reenter.
      asset.safeTransferFrom(msg.sender, address(this), assets);
      uint actualAmount = asset.balanceOf(receiver) - balancePre;

      shares = previewWithdraw(actualAmount); // No need to check for rounding error, previewWithdraw rounds up.

      if (msg.sender != owner) {
          uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

          if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
      }

      beforeWithdraw(actualAmount, shares);

      _burn(owner, shares);

      emit Withdraw(msg.sender, receiver, owner, actualAmount, shares);

      asset.safeTransfer(receiver, actualAmount);
  }

  function redeem(
      uint256 shares,
      address receiver,
      address owner
  ) public override returns (uint256 assets) {
    require(false, "NOT_IMPLEMENTED");
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this));
  }
}
