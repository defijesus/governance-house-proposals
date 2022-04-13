// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { IArcTimelock } from  "./interfaces/IArcTimelock.sol";
import { ILendingPoolConfigurator } from "./interfaces/ILendingPoolConfigurator.sol";

/// @title ArcDpiProposalPayload
/// @author Governance House
/// @notice Add DPI as Collateral on the Aave ARC Market
contract ArcDpiProposalPayload {

    /// @notice AAVE ARC LendingPoolConfigurator
    ILendingPoolConfigurator constant configurator = ILendingPoolConfigurator(0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA);

    /// @notice AAVE ARC timelock
    IArcTimelock constant arcTimelock = IArcTimelock(0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218);
    
    /// @notice Aave default implementations
    address public constant ATOKEN_IMPL =
        0xB2f4Fb41F01CdeF7c10F0e8aFbeB3cFA79d1686F;
    address public constant VARIABLE_DEBT_IMPL =
        0x2386694b2696015dB1a511AB9cD310e800F93055;
    address public constant STABLE_DEBT_IMPL =
        0x5746b5b6650Dd8d9B1d9D1bbf5E7f23e9761183F;
    address public constant INTEREST_RATE_STRATEGY =
        0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

    /// @notice DPI token
    address constant DPI = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;
    uint8 public constant DPI_DECIMALS = 18;

    uint256 public constant RESERVE_FACTOR = 2000;
    uint256 public constant LTV = 6500;
    uint256 public constant LIQUIDATION_THRESHOLD = 7000;
    uint256 public constant LIQUIDATION_BONUS = 10750;

    /// @notice address of current contract
    address immutable self;

    constructor() public {
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
        // address, ltv, liqthresh, bonus
        configurator.initReserve(
            ATOKEN_IMPL,
            STABLE_DEBT_IMPL,
            VARIABLE_DEBT_IMPL,
            DPI_DECIMALS,
            INTEREST_RATE_STRATEGY
        );
        configurator.enableBorrowingOnReserve(DPI, false);
        configurator.setReserveFactor(DPI, RESERVE_FACTOR);
        configurator.configureReserveAsCollateral(
            DPI,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );
    }
}
