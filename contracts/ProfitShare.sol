//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./interfaces/ERC20Interface.sol";
import "./libraries/TransferHelper.sol";

contract ProfitShare {
  struct Investor {
    address addr;
    uint256 percent;
  }
  address public owner;
  Investor[] public investors;
  address public token;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  modifier onlyOwner() {
    require(msg.sender == owner, "oo");
    _;
  }
  modifier notInvestor(address addr) {
    uint256 length = investors.length;
    bool bExist = false;
    for (uint256 _id = 0; _id < length; _id++) {
      if (investors[_id].addr == addr) {
        bExist = true;
      }
    }
    require(bExist == false, "already added investor list");
    _;
  }
  modifier investor(address addr) {
    uint256 length = investors.length;
    bool bExist = false;
    for (uint256 _id = 0; _id < length; _id++) {
      if (investors[_id].addr == addr) {
        bExist = true;
      }
    }
    require(bExist == true, "not investor");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  // verified
  function transaferOwnership(address newOwner) public onlyOwner {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function investorCount() external view returns (uint256) {
    return investors.length;
  }

  function addInvestor(address addr, uint256 percent)
    external
    onlyOwner
    notInvestor(addr)
  {
    investors.push(Investor(addr, percent));
  }

  function updateInfo(
    uint256 _id,
    address addr,
    uint256 percent
  ) external onlyOwner {
    uint256 length = investors.length;
    require(_id < length, "invalid id");
    investors[_id].addr = addr;
    investors[_id].percent = percent;
  }

  function removeInvestor(uint256 _id) external onlyOwner {
    uint256 length = investors.length;
    require(_id < length, "invalid id");
    investors[_id] = investors[length - 1];
    investors.pop();
  }

  function setToken(address _token) external onlyOwner {
    token = _token;
  }

  function divide() external {
    uint256 totalShare = 0;
    uint256 length = investors.length;
    uint256 _id;
    uint256 sendAmount;
    for (_id = 0; _id < length; _id++) {
      totalShare += investors[_id].percent;
    }
    require(totalShare > 0, "invalid share");

    uint256 tokenBlance = getBalance();
    for (_id = 0; _id < length; _id++) {
      sendAmount = (tokenBlance * investors[_id].percent) / totalShare;
      sendToken(investors[_id].addr, sendAmount);
    }
  }

  function getBalance() public view returns (uint256) {
    uint256 balance;
    if (token == address(0)) {
      address payable self = payable(address(this));
      balance = self.balance;
    } else {
      balance = ERC20Interface(token).balanceOf(address(this));
    }
    return balance;
  }

  function sendToken(address addr, uint256 amount) private {
    uint256 curBalance = getBalance();
    if (amount > curBalance) {
      amount = curBalance;
    }
    if (token == address(0)) {
      TransferHelper.safeTransferETH(addr, amount);
    } else {
      TransferHelper.safeTransfer(token, addr, amount);
    }
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
}
