// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { IArcTimelock } from  "./interfaces/IArcTimelock.sol";
import { ILendingPoolConfigurator } from "./interfaces/ILendingPoolConfigurator.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";

/// @title ArcDaiProposalPayload
/// @author Governance House
/// @notice Add DAI as Collateral on the Aave ARC Market
contract ArcDaiProposalPayload {

    /// @notice AAVE ARC LendingPoolConfigurator
    ILendingPoolConfigurator constant configurator = ILendingPoolConfigurator(0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA);

    ILendingPoolAddressesProvider
        public constant LENDING_POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0x6FdfafB66d39cD72CFE7984D3Bbcc76632faAb00
        );

    address public constant FEED_DAI_USD =
        0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

    /// @notice AAVE ARC timelock
    IArcTimelock constant arcTimelock = IArcTimelock(0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218);
    
    /// @notice AAVE treasury
    address public constant TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    /// @notice Aave default implementations
    address public constant ATOKEN_IMPL =
        0x6faeE7AaC498326660aC2B7207B9f67666073111;
    address public constant VARIABLE_DEBT_IMPL =
        0x82b488281aeF001dAcF106b085cc59EEf0995131;
    address public constant STABLE_DEBT_IMPL =
        0x71c60e94C10d90D0386BaC547378c136cb6aD2b4;
    address public constant INTEREST_RATE_STRATEGY =
        0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

    /// @notice DAI token
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 public constant DAI_DECIMALS = 18;

    uint256 public constant RESERVE_FACTOR = 1000;
    uint256 public constant LTV = 7700;
    uint256 public constant LIQUIDATION_THRESHOLD = 8000;
    uint256 public constant LIQUIDATION_BONUS = 10500;

    /// @notice address of current contract
    address immutable self;

    constructor() {
        self = address(this);
    }
    
    /// @notice The AAVE governance contract calls this to queue up an
    /// @notice action to the AAVE ARC timelock
    function executeQueueTimelock() external {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        string[] memory signatures = new string[](1);
        bytes[] memory calldatas = new bytes[](1);
        bool[] memory withDelegatecalls = new bool[](1);

        targets[0] = self;
        signatures[0] = "execute()";
        withDelegatecalls[0] = true;

        arcTimelock.queue(targets, values, signatures, calldatas, withDelegatecalls);
    }

    /// @notice The AAVE ARC timelock delegateCalls this
    function execute() external {
        IPriceOracle PRICE_ORACLE = IPriceOracle(
            LENDING_POOL_ADDRESSES_PROVIDER.getPriceOracle()
        );
        address[] memory assets = new address[](1);
        assets[0] = DAI;
        address[] memory sources = new address[](1);
        sources[0] = FEED_DAI_USD;

        PRICE_ORACLE.setAssetSources(assets, sources);

        // // address, ltv, liqthresh, bonus
        ILendingPoolConfigurator.InitReserveInput memory input;
        input.aTokenImpl = ATOKEN_IMPL;
        input.stableDebtTokenImpl = STABLE_DEBT_IMPL;
        input.variableDebtTokenImpl = VARIABLE_DEBT_IMPL;
        input.underlyingAssetDecimals = DAI_DECIMALS;
        input.interestRateStrategyAddress = INTEREST_RATE_STRATEGY;
        input.underlyingAsset = DAI;
        input.treasury = TREASURY;
        input.underlyingAssetName = "DAI";
        input.aTokenName = "Aave Arc market DAI";
        input.aTokenSymbol = "aDAI";
        input.variableDebtTokenName = "Aave Arc variable debt DAI";
        input.variableDebtTokenSymbol = "variableDebtDAI";
        input.stableDebtTokenName = "Aave Arc stable debt DAI";
        input.stableDebtTokenSymbol = "stableDebtDAI";
        ILendingPoolConfigurator.InitReserveInput[] memory inputs = new ILendingPoolConfigurator.InitReserveInput[](1);
        inputs[0] = input;
        configurator.batchInitReserve(inputs);
        configurator.enableBorrowingOnReserve(DAI, false);
        configurator.setReserveFactor(DAI, RESERVE_FACTOR);
        configurator.configureReserveAsCollateral(
            DAI,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );
    }
}
