//SPDX-License-Identifier: LICENSED

pragma solidity ^0.7.0;
import "../interfaces/AggregatorV3Interface.sol";
import "../Swapper/uniswapv2/interfaces/IUniswapV2Router01.sol";
import "../interfaces/ERC20Interface.sol";

contract CustomPriceFeed is AggregatorV3Interface {
  address public immutable USDT;
  address public immutable router;
  address public immutable token;
  uint256 public testAmountsIn;
  address public owner;
  uint8 _decimals;
  string  _description;
  uint256 _version;
  // events
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  modifier onlyOwner() {
    require(msg.sender == owner, "oo");
    _;
  }

  function transaferOwnership(address newOwner) public onlyOwner {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  constructor(
    address _token,
    address _usdt,
    address _router
  ) {
    token = _token;
    USDT = _usdt;
    router = _router;
    testAmountsIn = 1 ether;
    owner = msg.sender;
    _decimals = 8;
    _description = "custom price feed";
    _version = 1;
  }
  function setDecimals(uint8 _value) public onlyOwner {
    _decimals = _value;
  }
  function setDescription(string memory _value) public onlyOwner {
    _description = _value;
  }
  function setVersion(uint256 _value) public onlyOwner {
    _version = _value;
  }
  function decimals() external view override returns (uint8) {
    return _decimals;
  }
  function description() external view override returns (string memory) {
    return _description;
  }
  function version() external view override returns (uint256) {
    return _version;
  }
  function setTestAmount(uint256 _value) public onlyOwner {
    testAmountsIn = _value;
  }
  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = _roundId;
    answer = getPrice();
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = uint80(block.number);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = uint80(block.number);
    answer = getPrice();
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = uint80(block.number);
  }

  function getPrice() public view returns (int256) {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = USDT;
    uint256 amountIn = testAmountsIn;
    uint256[] memory amounts = IUniswapV2Router01(router).getAmountsOut(
      amountIn,
      path
    );
    int256 _dec = _decimals +
      ERC20Interface(token).decimals() -
      ERC20Interface(USDT).decimals();
    int256 price;
    if (_dec >= 0) {
      price = int256((amounts[1] * uint256(10**uint256(_dec))) / testAmountsIn);
    } else {
      price = int256(amounts[1] / uint256(10**uint256(-_dec)) / testAmountsIn);
    }
    return price;
  }
}
