## 🌍 Overview

TextileToken is a blockchain-based smart contract system built on Stacks that creates a transparent registry for recycled textile origins. The platform incentivizes textile recycling through token rewards and enables sustainable fashion brands to verify their supply chain compliance.

## ✨ Key Features

- 🏷️ **Recycled Batch NFTs**: Create unique tokens representing batches of recycled textiles with origin tracking
- 🌱 **Eco-Reward Tokens**: Earn fungible tokens for verified textile recycling activities  
- 🛒 **Sustainable Marketplace**: Buy and sell recycled textile batches using eco-tokens
- 🎖️ **Compliance Badges**: Certify manufacturers using verified recycled materials
- 📊 **Carbon Offset Tracking**: Calculate environmental impact of recycled textiles

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

### 👨‍💼 For Contract Owner

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

### Public Functions
- `register-recycler` - Register as certified recycler
- `create-textile-batch` - Mint new batch NFT and earn tokens
- `list-batch-for-sale` - Create marketplace listing
- `buy-batch` - Purchase batch with eco-tokens
- `transfer-eco-tokens` - Send tokens to another user
- `burn-eco-tokens` - Remove tokens from circulation

### Owner Functions
- `certify-recycler` - Approve recycler certification
- `certify-batch` - Verify batch authenticity
- `issue-compliance-badge` - Grant manufacturer compliance

## 💰 Token Economics

- **Eco-Reward Tokens**: Fungible tokens earned for recycling
- **Base Reward**: 10 tokens per kg of recycled textile
- **Certification Bonus**: Additional 5 tokens per kg for certified batches
- **Marketplace**: Use tokens to buy/sell recycled textile batches

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
