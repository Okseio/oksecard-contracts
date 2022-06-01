//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
import "./MultiSigOwner.sol";
import "./Manager.sol";
import "./interfaces/ILevelManager.sol";
import "./libraries/SafeMath.sol";

contract LimitManager is MultiSigOwner, Manager {
    using SafeMath for uint256;
    address public immutable levelManager;
    uint256 public constant MAX_LEVEL = 5;
    // user's sepnd amount in a day.
    mapping(address => uint256) public usersSpendAmountDay;
    // user's spend date
    // it is needed to calculate how much assets user sold in a day.
    mapping(address => uint256) public usersSpendTime;
    // unit is usd amount , so decimal is 18
    mapping(address => uint256) public userDailyLimits;
    uint256[] public DailyLimits;
    uint256 public timeDiff;

    constructor(address _cardContract, address _levelManager)
        Manager(_cardContract)
    {
        DailyLimits = [
            100 ether,
            250 ether,
            500 ether,
            2500 ether,
            5000 ether,
            10000 ether
        ];
        levelManager = _levelManager;
        timeDiff = 4 hours;
    }

    function getUserLimit(address userAddr) public view returns (uint256) {
        uint256 dailyLimit = userDailyLimits[userAddr];
        if (dailyLimit != 0) return dailyLimit;
        uint256 userLevel = ILevelManager(levelManager).getUserLevel(userAddr);
        return getDailyLimit(userLevel);
    }

    // verified
    function getDailyLimit(uint256 level) public view returns (uint256) {
        require(level <= 5, "level > 5");
        return DailyLimits[level];
    }

    // verified
    function setDailyLimit(uint256 index, uint256 _amount) public onlyOwner {
        require(index <= MAX_LEVEL, "level<=5");
        DailyLimits[index] = _amount;
    }

    // decimal of usdAmount is 18
    function withinLimits(address userAddr, uint256 usdAmount)
        public
        view
        returns (bool)
    {
        if (usdAmount <= getUserLimit(userAddr)) return true;
        return false;
    }

    function getSpendAmountToday(address userAddr)
        public
        view
        returns (uint256)
    {
        uint256 currentDate = (block.timestamp + timeDiff) / 1 days; // UTC -> PST time zone 12 PM
        if (usersSpendTime[userAddr] != currentDate) {
            return 0;
        }
        return usersSpendAmountDay[userAddr];
    }

    function updateUserSpendAmount(address userAddr, uint256 usdAmount)
        public
        onlyFromCardContract
    {
        uint256 currentDate = (block.timestamp + timeDiff) / 1 days; // UTC -> PST time zone 12 PM
        uint256 totalSpendAmount;

        if (usersSpendTime[userAddr] != currentDate) {
            usersSpendTime[userAddr] = currentDate;
            totalSpendAmount = usdAmount;
        } else {
            totalSpendAmount = usersSpendAmountDay[userAddr].add(usdAmount);
        }

        require(withinLimits(userAddr, totalSpendAmount), "odl");
        // cashBack(userAddr, spendAmount);
        usersSpendAmountDay[userAddr] = totalSpendAmount;
    }

    // verified
    function setUserDailyLimits(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setUserDailyLimits")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (address userAddr, uint256 usdAmount) = abi.decode(
            params,
            (address, uint256)
        );
        userDailyLimits[userAddr] = usdAmount;
        // emit UserDailyLimitChanged(userAddr, usdAmount);
    }

    function setTimeDiff(bytes calldata signData, bytes calldata keys)
        external
        onlyOwner
        validSignOfOwner(signData, keys, "setTimeDiff")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        uint256 _value = abi.decode(params, (uint256));
        timeDiff = _value;
    }
}
