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
    // buy tx fee in usd
    uint256 public buyTxFee; // 0.7 usd
    event ManagerAddressChanged(
        address treasuryAddress,
        address financialAddress,
        address masterAddress,
        address monthlyFeeAddress
    );
    event FeeValuesChanged(
        uint256 monthlyFeeAmount,
        uint256 okseMonthlyProfit,
        uint256 withdrawFeePercent,
        uint256 buyTxFee,
        uint256 buyFeePercent
    );
    event StakeContractParamChanged(
        address stakeContractAddress,
        uint256 stakePercent
    );

    constructor() {}

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
        emit ManagerAddressChanged(
            treasuryAddress,
            financialAddress,
            masterAddress,
            monthlyFeeAddress
        );
    }

    function requestManagerAddressUpdate(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "requestManagerAddressUpdate") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
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
    function setFeeValues(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setFeeValues")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (
            uint256 _monthlyFeeAmount,
            uint256 _okseMonthlyProfit,
            uint256 _withdrawFeePercent,
            uint256 newBuyFeePercent,
            uint256 newBuyTxFee
        ) = abi.decode(params, (uint256, uint256, uint256, uint256, uint256));
        require(_okseMonthlyProfit <= 10000, "over percent");
        require(_withdrawFeePercent <= MAX_FEE_AMOUNT, "mfo");
        monthlyFeeAmount = _monthlyFeeAmount;
        okseMonthlyProfit = _okseMonthlyProfit;
        withdrawFeePercent = _withdrawFeePercent;
        require(newBuyFeePercent <= MAX_FEE_AMOUNT, "mpo");
        buyFeePercent = newBuyFeePercent;
        buyTxFee = newBuyTxFee;
        emit FeeValuesChanged(
            monthlyFeeAmount,
            okseMonthlyProfit,
            withdrawFeePercent,
            buyTxFee,
            buyFeePercent
        );
    }

    function setStakeContractParams(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "setStakeContractParams") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address _stakeContractAddress, uint256 _stakePercent) = abi.decode(
            params,
            (address, uint256)
        );
        stakeContractAddress = _stakeContractAddress;
        stakePercent = _stakePercent;
        emit StakeContractParamChanged(stakeContractAddress, stakePercent);
    }
}
