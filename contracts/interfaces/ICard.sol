// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ICard {
    function getUserOkseBalance(address userAddr)
        external
        view
        returns (uint256);

    function getUserAssetAmount(address userAddr, address market)
        external
        view
        returns (uint256);

    function allMarkets() external view returns (address[] memory);

    function usersBalances(address userAddr, address market)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

    function getUserMainMarket(address userAddr) external view returns (address);
}
