//SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;
import "./MultiSigOwner.sol";

contract OwnerConstants is MultiSigOwner {
    uint256 public constant HR48 = 10 minutes; //for testing
    // address public owner;

    // daily limit contants
    uint256 public constant MAX_LEVEL = 5;

    // this is reward address for user's withdraw and payment for goods.
    address public treasuryAddress;
    // this address should be deposit okse in his balance and users can get cashback from this address.
    address public financialAddress;
    // master address is used to send USDC tokens when user buy goods.
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

    // set monthly fee of user to use card payment, unit is usd amount ( 1e18)
    uint256 public monthlyFeeAmount; // 6.99 USD
    // if user pay monthly fee using okse, then he will pay less amount fro this percent. 0% => 0, 100% => 10000
    uint256 public okseMonthlyProfit; // 10%

    bool public emergencyStop;

    event ManagerAddressChanged(
        address owner,
        address treasuryAddress,
        address financialAddress,
        address masterAddress,
        address monthlyFeeAddress
    );

    modifier noEmergency() {
        require(!emergencyStop, "stopped");
        _;
    }

    constructor() {
        // owner = msg.sender;
    }

    function getMonthlyFeeAmount(bool payFromOkse)
        public
        view
        returns (uint256)
    {
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

    // I have to add 48 hours delay in this function
    function setManagerAddresses(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setManagerAddresses")
    {
        require(
            block.timestamp > requestTimeOfManagerAddressUpdate + HR48 &&
                requestTimeOfManagerAddressUpdate > 0,
            "need to wait 48hr"
        );
        treasuryAddress = pendingTreasuryAddress;
        financialAddress = pendingFinancialAddress;
        masterAddress = pendingMasterAddress;
        monthlyFeeAddress = pendingMonthlyFeeAddress;
        requestTimeOfManagerAddressUpdate = 0;
    }

    function requestManagerAddressUpdate(
        bytes calldata signData,
        bytes calldata keys
    )
        public
        validSignOfOwner(signData, keys, "requestManagerAddressUpdate")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (
            address _newTreasuryAddress,
            address _newFinancialAddress,
            address _newMasterAddress,
            address _mothlyFeeAddress
        ) = abi.decode(params, (address, address, address, address));

        pendingTreasuryAddress = _newTreasuryAddress;
        pendingFinancialAddress = _newFinancialAddress;
        pendingMasterAddress = _newMasterAddress;
        pendingMonthlyFeeAddress = _mothlyFeeAddress;
        requestTimeOfManagerAddressUpdate = block.timestamp;
    }

    // verified
    function setWithdrawFeePercent(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setWithdrawFeePercent")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        uint256 newPercent = abi.decode(params, (uint256));
        require(newPercent <= MAX_FEE_AMOUNT, "mfo");
        // uint256 beforePercent = withdrawFeePercent;
        withdrawFeePercent = newPercent;
        // emit WithdrawFeePercentChanged(owner, newPercent, beforePercent);
    }


    // verified
    function setMonthlyFee(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setMonthlyFee")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (uint256 usdFeeAmount, uint256 okseProfitPercent) = abi.decode(
            params,
            (uint256, uint256)
        );
        require(okseProfitPercent <= 10000, "over percent");
        monthlyFeeAmount = usdFeeAmount;
        okseMonthlyProfit = okseProfitPercent;
    }

    function setStakeContractParams(
        bytes calldata signData,
        bytes calldata keys
    )
        public
        validSignOfOwner(signData, keys, "setStakeContractParams")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (address _stakeContractAddress, uint256 _stakePercent) = abi.decode(
            params,
            (address, uint256)
        );
        stakeContractAddress = _stakeContractAddress;
        stakePercent = _stakePercent;
    }

    function setEmergencyStop(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setEmergencyStop")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        bool _value = abi.decode(params, (bool));
        emergencyStop = _value;
    }
}
