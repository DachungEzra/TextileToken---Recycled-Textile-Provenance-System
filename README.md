## 🌍 Overview

TextileToken is a blockchain-based smart contract system built on Stacks that creates a transparent registry for recycled textile origins. The platform incentivizes textile recycling through token rewards and enables sustainable fashion brands to verify their supply chain compliance.

## ✨ Key Features

- 🏷️ **Recycled Batch NFTs**: Create unique tokens representing batches of recycled textiles with origin tracking
- 🌱 **Eco-Reward Tokens**: Earn fungible tokens for verified textile recycling activities
- 🛒 **Sustainable Marketplace**: Buy and sell recycled textile batches using eco-tokens
- 💰 **Batch Royalty System**: Automatic royalty payments to original recyclers on batch sales
- 🎖️ **Compliance Badges**: Certify manufacturers using verified recycled materials
- 📊 **Carbon Offset Tracking**: Calculate environmental impact of recycled textiles
- 🔀 **Batch Splitting**: Divide large textile batches into smaller units for flexible management
- 🔄 **Batch Merging**: Consolidate multiple textile batches into a single optimized batch
- 💝 **Eco-Donation System**: Enable users to donate eco-tokens to support environmental initiatives

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks Wallet](https://www.hiro.so/wallet) for testnet/mainnet deployment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/DachungEzra/TextileToken---Recycled-Textile-Provenance-System.git
cd TextileToken---Recycled-Textile-Provenance-System
```

2. Check the project:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

## 📋 Usage Instructions

### 👤 For Recyclers

#### 1. Register as a Recycler
```clarity
(contract-call? .textile-token register-recycler "EcoRecycle Corp")
```

#### 2. Create Textile Batch
```clarity
(contract-call? .textile-token create-textile-batch 
  "Mumbai Textile District" 
  "Cotton" 
  u100)
```

#### 3. Check Your Balance
```clarity
(contract-call? .textile-token get-eco-token-balance tx-sender)
```

### 🏭 For Manufacturers

#### 1. Buy Recycled Batches
```clarity
(contract-call? .textile-token buy-batch u1)
```

This purchases the listed batch, automatically distributing 5% of the sale price as royalty to the original recycler, with the remainder going to the seller.

#### 2. Check Compliance Status
```clarity
(contract-call? .textile-token is-badge-valid tx-sender)
```

### 🏪 For Marketplace Operations

#### 1. List Batch for Sale
```clarity
(contract-call? .textile-token list-batch-for-sale u1 u500)
```

#### 2. View Listing
```clarity
(contract-call? .textile-token get-listing-info u1)
```

### 🔀 For Batch Management

#### 1. Split Textile Batch
```clarity
(contract-call? .textile-token split-batch u1 u50 u50)
```

This splits batch 1 into two new batches of 50kg each, provided the original batch weighs 100kg and is owned by the caller.

#### 2. Merge Textile Batches
```clarity
(contract-call? .textile-token merge-batches (list u1 u2))
```

This merges batches 1 and 2 into a new consolidated batch, provided they have the same origin and textile type, and are owned by the caller.

### 💝 For Eco-Donations

#### 1. Donate Eco-Tokens
```clarity
(contract-call? .textile-token donate-eco-tokens u100)
```

This allows users to contribute their eco-tokens to support environmental initiatives, with the total donations tracked transparently on-chain.

#### 2. Check Total Donations
```clarity
(contract-call? .textile-token get-total-donations)
```

### �‍💼 For Contract Owner

#### 1. Certify Recycler
```clarity
(contract-call? .textile-token certify-recycler 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### 2. Issue Compliance Badge
```clarity
(contract-call? .textile-token issue-compliance-badge 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
  "Sustainable Manufacturer" 
  u12)
```

## 🔍 Smart Contract Functions

### Read-Only Functions
- `get-batch-info` - Retrieve textile batch details
- `get-recycler-info` - Get recycler registration data
- `get-listing-info` - View marketplace listing details
- `get-compliance-badge` - Check manufacturer compliance status
- `get-eco-token-balance` - View token balance
- `is-badge-valid` - Verify badge validity
- `get-recycler-rating` - Calculate recycler trust score
- `calculate-carbon-offset` - Estimate environmental impact
- `get-total-donations` - View total eco-tokens donated to environmental causes

### Public Functions
- `register-recycler` - Register as certified recycler
- `create-textile-batch` - Mint new batch NFT and earn tokens
- `list-batch-for-sale` - Create marketplace listing
- `buy-batch` - Purchase batch with eco-tokens, including automatic royalty distribution
- `transfer-eco-tokens` - Send tokens to another user
- `burn-eco-tokens` - Remove tokens from circulation
- `split-batch` - Divide a textile batch into two smaller batches
- `merge-batches` - Combine multiple textile batches into one consolidated batch
- `donate-eco-tokens` - Contribute eco-tokens to environmental initiatives

### Owner Functions
- `certify-recycler` - Approve recycler certification
- `certify-batch` - Verify batch authenticity
- `issue-compliance-badge` - Grant manufacturer compliance

## 💰 Token Economics

- **Eco-Reward Tokens**: Fungible tokens earned for recycling
- **Base Reward**: 10 tokens per kg of recycled textile
- **Certification Bonus**: Additional 5 tokens per kg for certified batches
- **Marketplace**: Use tokens to buy/sell recycled textile batches
- **Royalty System**: 5% of sale price automatically paid to original recycler
- **Merging Reward**: 10 tokens per kg for the total weight of merged batches

## 🛡️ Security Features

- Owner-only administrative functions
- Balance verification for token transfers
- NFT ownership validation for marketplace operations
- Input validation for all user data
- Time-based badge expiration system

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

## 🌐 Deployment

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For questions and support, please open an issue in the GitHub repository.

---

Built with ❤️ for sustainable fashion and environmental impact. 🌱
