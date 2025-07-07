
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HITBNB Treasury V2
 * @notice A decentralized treasury that allows users to stake USDT as collateral, borrow HITBNB/USDT, receive donations, and manage LP tokens.
 */
contract HITBNBTreasuryV2 is AccessControl, ReentrancyGuard {
    using Address for address;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public immutable usdt;
    IERC20 public immutable hitbnb;

    address public roiWallet;
    uint256 public borrowRatio = 70; // 70% of stake

    struct StakeInfo {
        uint256 staked;
        uint256 borrowed;
    }

    mapping(address => StakeInfo) public stakeData;

    event Staked(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, address token);
    event Repaid(address indexed user, uint256 amount, address token);
    event Withdrawn(address indexed user, uint256 amount);
    event Donated(address indexed user, uint256 amount, address token);

    constructor(address _usdt, address _hitbnb, address _roiWallet) {
        require(_usdt != address(0) && _hitbnb != address(0) && _roiWallet != address(0), "Zero address");
        usdt = IERC20(_usdt);
        hitbnb = IERC20(_hitbnb);
        roiWallet = _roiWallet;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNOR_ROLE, msg.sender);
    }

    // ============ USER FUNCTIONS ============

    function stakeUSDT(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        usdt.transferFrom(msg.sender, address(this), amount);
        stakeData[msg.sender].staked += amount;
        emit Staked(msg.sender, amount);
    }

    function borrow(uint256 amount, bool inHitbnb) external nonReentrant {
        StakeInfo storage user = stakeData[msg.sender];
        uint256 maxBorrow = (user.staked * borrowRatio) / 100;
        require(user.borrowed + amount <= maxBorrow, "Exceeds borrow limit");

        user.borrowed += amount;

        if (inHitbnb) {
            hitbnb.transferFrom(roiWallet, msg.sender, amount);
            emit Borrowed(msg.sender, amount, address(hitbnb));
        } else {
            usdt.transferFrom(roiWallet, msg.sender, amount);
            emit Borrowed(msg.sender, amount, address(usdt));
        }
    }

    function repay(uint256 amount, bool inHitbnb) external nonReentrant {
        require(amount > 0, "Zero amount");
        StakeInfo storage user = stakeData[msg.sender];
        require(user.borrowed >= amount, "Repay exceeds debt");

        user.borrowed -= amount;

        if (inHitbnb) {
            hitbnb.transferFrom(msg.sender, roiWallet, amount);
            emit Repaid(msg.sender, amount, address(hitbnb));
        } else {
            usdt.transferFrom(msg.sender, roiWallet, amount);
            emit Repaid(msg.sender, amount, address(usdt));
        }
    }

    function withdrawStake(uint256 amount) external nonReentrant {
        StakeInfo storage user = stakeData[msg.sender];
        require(user.staked >= amount, "Insufficient stake");
        require(user.staked - amount >= (user.borrowed * 100) / borrowRatio, "Collateral too low");

        user.staked -= amount;
        usdt.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // ============ ADMIN FUNCTIONS ============

    function setBorrowRatio(uint256 ratio) external onlyRole(GOVERNOR_ROLE) {
        require(ratio <= 90, "Too high");
        borrowRatio = ratio;
    }

    function setRoiWallet(address newWallet) external onlyRole(GOVERNOR_ROLE) {
        require(newWallet != address(0), "Invalid wallet");
        roiWallet = newWallet;
    }

    function rescueToken(address token, address to, uint256 amount) external onlyRole(GOVERNOR_ROLE) {
        IERC20(token).transfer(to, amount);
    }

    // ============ OPTIONAL: DONATIONS ============

    function donate(address token, uint256 amount) external {
        require(amount > 0, "Zero donation");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Donated(msg.sender, amount, token);
    }

    // ============ OPTIONAL: LP SUPPORT ============

    struct LPInfo {
        bool accepted;
        address calculator;
    }

    mapping(address => LPInfo) public lpTokens;

    function registerLP(address lp, address calculator) external onlyRole(GOVERNOR_ROLE) {
        require(lp != address(0), "Zero address");
        lpTokens[lp] = LPInfo({accepted: true, calculator: calculator});
    }

    function disableLP(address lp) external onlyRole(GOVERNOR_ROLE) {
        lpTokens[lp].accepted = false;
    }

    function isCollateralSufficient(address userAddr) external view returns (bool) {
        StakeInfo memory user = stakeData[userAddr];
        return user.staked * borrowRatio >= user.borrowed * 100;
    }
}
