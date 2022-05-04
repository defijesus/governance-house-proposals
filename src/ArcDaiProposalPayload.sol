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
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    address public constant FEED_DAI_USD =
        0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

    /// @notice AAVE ARC timelock
    IArcTimelock constant arcTimelock = IArcTimelock(0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218);
    
    /// @notice Aave default implementations
    address public constant ATOKEN_IMPL =
        0x6faeE7AaC498326660aC2B7207B9f67666073111;
    address public constant VARIABLE_DEBT_IMPL =
        0x2386694b2696015dB1a511AB9cD310e800F93055;
    address public constant STABLE_DEBT_IMPL =
        0x5746b5b6650Dd8d9B1d9D1bbf5E7f23e9761183F;
    address public constant INTEREST_RATE_STRATEGY =
        0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

    /// @notice DAI token
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 public constant DAI_DECIMALS = 18;

    uint256 public constant RESERVE_FACTOR = 2000;
    uint256 public constant LTV = 6500;
    uint256 public constant LIQUIDATION_THRESHOLD = 7000;
    uint256 public constant LIQUIDATION_BONUS = 10750;

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

        // address, ltv, liqthresh, bonus
        configurator.initReserve(
            ATOKEN_IMPL,
            STABLE_DEBT_IMPL,
            VARIABLE_DEBT_IMPL,
            DAI_DECIMALS,
            INTEREST_RATE_STRATEGY
        );
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
