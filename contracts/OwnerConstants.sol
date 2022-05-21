//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract OwnerConstants {
  uint256 public constant HR48 = 10 minutes; //for testing
  address public owner;
  // daily limit contants
  uint256 public constant MAX_LEVEL = 5;
  uint256[] public OkseStakeAmounts ;
  uint256[] public DailyLimits;
  uint256[] public CashBackPercents;
  // this is validation period after user change his okse balance for this contract, normally is 30 days. we set 10 mnutes for testing.
  uint256 public levelValidationPeriod;

  // this is reward address for user's withdraw and payment for goods.
  address public treasuryAddress;
  // this address should be deposit okse in his balance and users can get cashback from this address.
  address public financialAddress;
  // master address is used to send USDT tokens when user buy goods.
  address public masterAddress;
  // monthly fee rewarded address
  address public monthlyFeeAddress;
  
  address public pendingTreasuryAddress;
  address public pendingFinancialAddress;
  address public pendingMasterAddress;
  address public pendingMonthlyFeeAddress;
  uint256 public requestTimeOfManagerAddressUpdate;

  // staking contract address, which is used to receive 20% of monthly fee, so staked users can be rewarded from this contract
  address public stakeContractAddress;
  // statking amount of monthly fee
  uint256 public stakePercent; // 15 %

  // withdraw fee and payment fee should not exeed this amount, 1% is coresponding to 100.
  uint256 public constant MAX_FEE_AMOUNT = 500; // 5%
  // buy fee setting.
  uint256 public buyFeePercent; // 1%

  
  // withdraw fee setting.
  uint256 public withdrawFeePercent; // 0.1 %
  // unit is usd amount , so decimal is 18
  mapping(address => uint256) public userDailyLimits;
  // Set whether user can use okse as payment asset. normally it is false.
  bool public oksePaymentEnable;
  // Setting for cashback enable or disable
  bool public cashBackEnable;
  // enable or disable for each market
  mapping(address => bool) public _marketEnabled;
  // set monthly fee of user to use card payment, unit is usd amount ( 1e18)
  uint256 public monthlyFeeAmount; // 6.99 USD
  // if user pay monthly fee using okse, then he will pay less amount fro this percent. 0% => 0, 100% => 10000
  uint256 public okseMonthlyProfit; // 10%
  
  bool public emergencyStop;
  
  // events
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  event ManagerAddressChanged(
    address owner,
    address treasuryAddress,
    address financialAddress,
    address masterAddress,
    address monthlyFeeAddress
  );
  // event BuyFeePercentChanged(
  //   address owner,
  //   uint256 newPercent,
  //   uint256 beforePercent
  // );
  // event WithdrawFeePercentChanged(
  //   address owner,
  //   uint256 newPercent,
  //   uint256 beforePercent
  // );
  // event UserDailyLimitChanged(address userAddr, uint256 usdAmount);
  // event CashBackEnableChanged(
  //   address owner,
  //   bool newEnabled,
  //   bool beforeEnabled
  // );
  // event MarketEnableChanged(
  //   address owner,
  //   address market,
  //   bool bEnable,
  //   bool beforeEnabled
  // );
  // event OksePaymentEnabled(
  //   address owner,
  //   bool oksePaymentEnable,
  //   bool bOldEnable
  // );
  // event MonthlyFeeChanged(
  //   address owner,
  //   uint256 monthlyFeeAmount,
  //   uint256 okseMonthlyProfit
  // );
  // event LevelValidationPeriodChanged(
  //   address owner,
  //   uint256 levelValidationPeriod,
  //   uint256 beforeValue
  // );
  // event StakeContractParamChanged(
  //   address stakeContractAddress,
  //   uint256 stakePercent
  // );
  /// modifier functions
  modifier onlyOwner() {
    require(msg.sender == owner, "oo");
    _;
  }
  modifier noEmergency() {
    require(!emergencyStop, "stopped");
    _;
  }
  constructor() {
    owner = msg.sender;
  }

  /**
   * @notice Get user level from his okse balance
   * @param _okseAmount okse token amount
   * @return user's level, 0~5 , 0 => no level
   */
  // verified
  function getLevel(uint256 _okseAmount) public view returns (uint256) {
    if (_okseAmount < OkseStakeAmounts[0]) return 0;
    if (_okseAmount < OkseStakeAmounts[1]) return 1;
    if (_okseAmount < OkseStakeAmounts[2]) return 2;
    if (_okseAmount < OkseStakeAmounts[3]) return 3;
    if (_okseAmount < OkseStakeAmounts[4]) return 4;
    return 5;
  }

  // verified
  function getDailyLimit(uint256 level) public view returns (uint256) {
    require(level <= 5, "level > 5");
    return DailyLimits[level];
  }

  //verified
  function getCashBackPercent(uint256 level) public view returns (uint256) {
    require(level <= 5, "level > 5");
    return CashBackPercents[level];
  }

  function getMonthlyFeeAmount(bool payFromOkse) public view returns (uint256) {
    uint256 result;
    if (payFromOkse) {
      result =
        monthlyFeeAmount -
        (monthlyFeeAmount * okseMonthlyProfit) /
        10000;
    } else {
      result = monthlyFeeAmount;
    }
    return result;
  }

  // Set functions
  // verified
  function transaferOwnership(address newOwner) public onlyOwner {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  // I have to add 48 hours delay in this function
  function setManagerAddresses() public onlyOwner {
    require(block.timestamp > requestTimeOfManagerAddressUpdate + HR48 && requestTimeOfManagerAddressUpdate > 0, "need to wait 48hr");
    treasuryAddress = pendingTreasuryAddress;
    financialAddress = pendingFinancialAddress;
    masterAddress = pendingMasterAddress;
    monthlyFeeAddress = pendingMonthlyFeeAddress;
    requestTimeOfManagerAddressUpdate = 0;
  }
  function requestManagerAddressUpdate(
    address _newTreasuryAddress,
    address _newFinancialAddress,
    address _newMasterAddress,
    address _mothlyFeeAddress
  ) public onlyOwner {
    pendingTreasuryAddress = _newTreasuryAddress;
    pendingFinancialAddress = _newFinancialAddress;
    pendingMasterAddress = _newMasterAddress;
    pendingMonthlyFeeAddress = _mothlyFeeAddress;
    requestTimeOfManagerAddressUpdate = block.timestamp;
  }



  // verified
  function setWithdrawFeePercent(uint256 newPercent) public onlyOwner {
    require(
      newPercent <= MAX_FEE_AMOUNT,
      "mfo"
    );
    // uint256 beforePercent = withdrawFeePercent;
    withdrawFeePercent = newPercent;
    // emit WithdrawFeePercentChanged(owner, newPercent, beforePercent);
  }

  // verified
  function setUserDailyLimits(address userAddr, uint256 usdAmount)
    public
    onlyOwner
  {
    userDailyLimits[userAddr] = usdAmount;
    // emit UserDailyLimitChanged(userAddr, usdAmount);
  }

  // verified
  function setOkseStakeAmount(uint256 index, uint256 _amount) public onlyOwner {
    require(index < MAX_LEVEL, "level<5");
    // require(index == 0 || OkseStakeAmounts[index - 1] < _amount, "should be great than low level");
    // require(index == MAX_LEVEL - 1 || OkseStakeAmounts[index + 1] > _amount, "should be less than high level");
    OkseStakeAmounts[index] = _amount;
  }

  // verified
  function setDailyLimit(uint256 index, uint256 _amount) public onlyOwner {
    require(index <= MAX_LEVEL, "level<=5");
    // require(index == 0 || DailyLimits[index - 1] < _amount, "should be great than low level");
    // require(index == MAX_LEVEL || DailyLimits[index + 1] > _amount, "should be less than high level");
    DailyLimits[index] = _amount;
  }

  // verified
  function setCashBackPercent(uint256 index, uint256 _amount) public onlyOwner {
    require(index <= MAX_LEVEL, "level<=5");
    // require(index == 0 || CashBackPercents[index - 1] < _amount, "should be great than low level");
    // require(index == MAX_LEVEL || CashBackPercents[index + 1] > _amount, "should be less than high level");
    CashBackPercents[index] = _amount;
  }

  // verified
  function setCashBackEnable(bool newEnabled) public onlyOwner {
    // bool beforeEnabled = cashBackEnable;
    cashBackEnable = newEnabled;
    // emit CashBackEnableChanged(owner, newEnabled, beforeEnabled);
  }

  // verified
  function enableMarket(address market, bool bEnable) public onlyOwner {
    // bool beforeEnabled = _marketEnabled[market];
    _marketEnabled[market] = bEnable;
    // emit MarketEnableChanged(owner, market, bEnable, beforeEnabled);
  }

  // verified
  function setOkseAsPayment(bool bEnable) public onlyOwner {
    // bool bOldEnable = oksePaymentEnable;
    oksePaymentEnable = bEnable;
    // emit OksePaymentEnabled(owner, oksePaymentEnable, bOldEnable);
  }

  // verified
  function setMonthlyFee(uint256 usdFeeAmount, uint256 okseProfitPercent)
    public
    onlyOwner
  {
    require(okseProfitPercent <= 10000, "over percent");
    monthlyFeeAmount = usdFeeAmount;
    okseMonthlyProfit = okseProfitPercent;
    // emit MonthlyFeeChanged(owner, monthlyFeeAmount, okseMonthlyProfit);
  }

  // verified
  function setLevelValidationPeriod(uint256 _newValue) public onlyOwner {
    // uint256 beforeValue = levelValidationPeriod;
    levelValidationPeriod = _newValue;
    // emit LevelValidationPeriodChanged(
    //   owner,
    //   levelValidationPeriod,
    //   beforeValue
    // );
  }

  function setStakeContractParams(
    address _stakeContractAddress,
    uint256 _stakePercent
  ) public onlyOwner {
    stakeContractAddress = _stakeContractAddress;
    stakePercent = _stakePercent;
    // emit StakeContractParamChanged(stakeContractAddress, stakePercent);
  }

  function setEmergencyStop(bool _value) public onlyOwner {
    emergencyStop = _value;
  }


}
