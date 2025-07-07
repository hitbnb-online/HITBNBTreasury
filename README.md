# HITBNBTreasury (still in development phase) 🏦

A fully decentralized treasury smart contract designed for the [HITBNB](https://hitbnb.online) ecosystem, enabling secure reserve management, borrowing against staked USDT, LP token tracking, and optional donations — all without token minting.

---

## 🔐 Features

- ✅ **Decentralized Role-Based Access Control**
- ✅ **USDT-Based Staking with Collateralized Borrowing**
- ✅ **No Minting — Treasury Operates from ROI Wallet Only**
- ✅ **Liquidity Pool (LP) Token Support**
- ✅ **Time-Locked Role Assignments for Governance**
- ✅ **Optional Donation System (On/Off Toggleable)**
- ✅ **Upgradeable & Modular (Solidity ^0.8.x)**

---

## 💡 Use Cases

- 📥 Treasury receives reserve tokens or LP tokens.
- 🤝 Users stake USDT into your DApp and use it as **collateral** to borrow HITBNB.
- 💳 Borrowed funds are distributed from ROI wallet (no minting).
- 📈 LP tokens registered and tracked for treasury operations.
- 💸 Support donations to fund platform development, server costs, audits, etc.

---

## 🛠 Deployment

This contract is designed to be deployed via **Remix**, **Hardhat**, or **Foundry**. No constructor arguments needed if using upgradeable pattern.

> Ensure your admin wallet and USDT token address are set after deployment.

---

## ⚙️ Configuration

### Environment Variables (Frontend Integration)
```env
TREASURY_CONTRACT_ADDRESS=0xYourTreasuryAddress
USDT_TOKEN_ADDRESS=0xUSDTTokenAddress
ROI_WALLET_ADDRESS=0xYourROITreasuryWallet
