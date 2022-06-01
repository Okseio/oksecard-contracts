//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
pragma abicoder v2;
import "./interfaces/ERC20Interface.sol";
import "./interfaces/ICard.sol";
import "./libraries/Converter.sol";
import "./MultiSigOwner.sol";
import "./Manager.sol";

contract MarketManager is MultiSigOwner, Manager {
    // default market , which is used when user didn't select any market for his main market
    address public defaultMarket;
    /// @notice A list of all assets
    address[] public allMarkets;
    // enable or disable for each market
    mapping(address => bool) public marketEnable;
    // store user's main asset used when user make payment.
    mapping(address => address) public userMainMarket;
    event MarketAdded(address market);

    address public WETH;
    // // this is main currency for master wallet, master wallet will get always this token. normally we use USDC for this token.
    address public USDC;
    // // this is okse token address, which is used for setting of user's daily level and cashback.
    address public OKSE;
    // Set whether user can use okse as payment asset. normally it is false.
    bool public oksePaymentEnable;

    modifier marketSupported(address market) {
        require(isMarketExist(market), "mns");
        _;
    }
    // verified
    modifier marketEnabled(address market) {
        require(marketEnable[market], "mdnd");
        _;
    }
    event UserMainMarketChanged(
        uint256 id,
        address userAddr,
        address market,
        address beforeMarket
    );

    constructor(
        address _cardContract,
        address _WETH,
        address _usdcAddress,
        address _okseAddress
    ) Manager(_cardContract) {
        WETH = _WETH;
        USDC = _usdcAddress;
        OKSE = _okseAddress;
        _addMarketInternal(WETH);
        _addMarketInternal(USDC);
        _addMarketInternal(OKSE);
        defaultMarket = WETH;
    }

    //verified
    function _addMarketInternal(address assetAddr) internal {
        for (uint256 i = 0; i < allMarkets.length; i++) {
            require(allMarkets[i] != assetAddr, "maa");
        }
        allMarkets.push(assetAddr);
        marketEnable[assetAddr] = true;
        emit MarketAdded(assetAddr);
    }

    function isMarketExist(address market) public returns (bool) {
        bool marketExist = false;
        for (uint256 i = 0; i < allMarkets.length; i++) {
            if (allMarkets[i] == market) {
                marketExist = true;
            }
        }
        return marketExist;
    }

    function getBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserMainMarket(address userAddr) public view returns (address) {
        if (userMainMarket[userAddr] == address(0)) {
            return defaultMarket; // return default market
        }
        address market = userMainMarket[userAddr];
        if (marketEnable[market] == false) {
            return defaultMarket; // return default market
        }
        return market;
    }

    function setUserMainMakret(
        address userAddr,
        address market,
        uint256 id
    ) public onlyFromCardContract {
        if (getUserMainMarket(userAddr) == market) return;
        address beforeMarket = getUserMainMarket(userAddr);
        userMainMarket[userAddr] = market;
        emit UserMainMarketChanged(id, userAddr, market, beforeMarket);
    }

    function getBatchUserAssetAmount(address userAddr)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory allMarkets = ICard(cardContract).allMarkets();
        uint256[] memory assets = new uint256[](allMarkets.length);
        uint256[] memory decimals = new uint256[](allMarkets.length);

        for (uint256 i = 0; i < allMarkets.length; i++) {
            assets[i] = ICard(cardContract).usersBalances(
                userAddr,
                allMarkets[i]
            );
            ERC20Interface token = ERC20Interface(allMarkets[i]);
            uint256 tokenDecimal = uint256(token.decimals());
            decimals[i] = tokenDecimal;
        }
        return (allMarkets, assets, decimals);
    }

    function getBatchUserBalanceInUsd(address userAddr)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory allMarkets = ICard(cardContract).allMarkets();
        uint256[] memory assets = new uint256[](allMarkets.length);

        for (uint256 i = 0; i < allMarkets.length; i++) {
            assets[i] = Converter.getUsdAmount(
                allMarkets[i],
                ICard(cardContract).usersBalances(userAddr, allMarkets[i]),
                ICard(cardContract).priceOracle()
            );
        }
        return (allMarkets, assets);
    }

    function getUserBalanceInUsd(address userAddr)
        public
        view
        returns (uint256)
    {
        address market = ICard(cardContract).getUserMainMarket(userAddr);
        uint256 assetAmount = ICard(cardContract).usersBalances(
            userAddr,
            market
        );
        uint256 usdAmount = Converter.getUsdAmount(
            market,
            assetAmount,
            ICard(cardContract).priceOracle()
        );
        return usdAmount;
    }

    // verified
    function addMarket(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "addMarket")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        address market = abi.decode(params, (address));
        _addMarketInternal(market);
    }

    function setDefaultMarket(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setDefaultMarket")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        address market = abi.decode(params, (address));
        require(isMarketExist(market), "me");
        require(marketEnable[market], "mn");
        defaultMarket = market;
    }

    // verified
    function enableMarket(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "enableMarket")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (address market, bool bEnable) = abi.decode(params, (address, bool));
        marketEnable[market] = bEnable;
    }

    function setParams(bytes calldata signData, bytes calldata keys)
        external
        onlyOwner
        validSignOfOwner(signData, keys, "setParams")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (address _newOkse, address _newUSDT) = abi.decode(
            params,
            (address, address)
        );
        OKSE = _newOkse;
        USDC = _newUSDT;
    }

    // verified
    function setOkseAsPayment(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setOkseAsPayment")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        bool bEnable = abi.decode(params, (bool));
        oksePaymentEnable = bEnable;
    }
}
