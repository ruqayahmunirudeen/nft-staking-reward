```markdown
# NFT Staking Reward Contract

A Clarity smart contract on Stacks blockchain for NFT staking with tiered rewards and DAO governance.

##  Quick Start

```bash
git clone https://github.com/yourusername/nft-staking-reward.git
cd nft-staking-reward
npm install

# Configure and deploy
cp settings/Testnet.toml.example Testnet.toml
stacks-cli publish nft-stakng-reward
```

##  Features

- **Single & Batch Staking**: Stake up to 100 NFTs per transaction
- **Tiered Rewards**: Different reward rates per NFT tier (up to 3 tiers)
- **Boost Multipliers**: VIP and long-term staker bonuses
- **Reputation System**: Track staking participation
- **Referral Tracking**: Community growth incentives
- **Cooldown Protection**: 20-block time-lock before unstaking
- **Emergency Unstake**: Withdraw without rewards in crises
- **DAO Controls**: Admin functions for parameter management

##  Installation

### Prerequisites
- Node.js v16+
- Stacks CLI
- STX wallet

### Setup

```bash
npm install
cp settings/Testnet.toml.example settings/Testnet.toml
# Edit with your node endpoint and mnemonic
stacks-cli publish nft-stakng-reward --settings ./settings/Testnet.toml
```

##  Usage

### For Users

```clarity
;; Stake single NFT
(contract-call? .nft-stakng-reward stake-nft u123)

;; Batch stake (up to 100)
(contract-call? .nft-stakng-reward batch-stake (list u1 u2 u3))

;; Stake with referral
(contract-call? .nft-stakng-reward stake-with-referral u123 'ST2PXEAQFYQ32NXPY3PXQB2Z4VSR5RRFWYQ7EXE9)

;; Check rewards
(contract-call? .nft-stakng-reward get-rewards tx-sender)

;; Unstake after cooldown
(contract-call? .nft-stakng-reward unstake-nft u123)

;; Claim all rewards
(contract-call? .nft-stakng-reward claim-rewards)

;; Emergency withdraw (no rewards)
(contract-call? .nft-stakng-reward emergency-unstake u123)
```

### For Admins

```clarity
;; Update reward rate (STX per block per NFT)
(contract-call? .nft-stakng-reward update-reward-rate u20)

;; Set NFT tier (1-3)
(contract-call? .nft-stakng-reward set-nft-tier u123 u2)

;; Set user boost multiplier
(contract-call? .nft-stakng-reward set-boost 'ST2PXEAQFYQ32NXPY3PXQB2Z4VSR5RRFWYQ7EXE9 u150)

;; Update cooldown period
(contract-call? .nft-stakng-reward update-cooldown u30)
```

##  API Reference

### Public Functions

| Function | Parameters | Returns |
|----------|-----------|---------|
| `stake-nft` | `token-id: uint` | `ok bool` |
| `batch-stake` | `token-ids: list 100 uint` | `ok bool` |
| `stake-with-referral` | `token-id: uint, referrer: principal` | `ok bool` |
| `unstake-nft` | `token-id: uint` | `ok uint` |
| `claim-rewards` | — | `ok uint` |
| `emergency-unstake` | `token-id: uint` | `ok bool` |
| `set-nft-tier` | `token-id: uint, tier: uint` | `ok bool` |
| `set-boost` | `user: principal, multiplier: uint` | `ok bool` |
| `update-cooldown` | `blocks: uint` | `ok bool` |
| `update-reward-rate` | `rate: uint` | `ok bool` |

### Read-Only Functions

```clarity
(get-staked-nft token-id)        ;; Get staking info
(get-rewards user)               ;; Get accumulated rewards
(get-reputation user)            ;; Get reputation score
(get-staking-count)              ;; Get total staked NFTs
(get-nft-tier token-id)          ;; Get NFT tier
(get-boost-multiplier user)      ;; Get reward boost
(get-referrer user)              ;; Get referrer address
(get-penalty user)               ;; Get penalties
```

##  Configuration

### Default Settings

```clarity
reward-rate: u10           ;; 10 STX per block per NFT
cooldown-period: u20       ;; 20 blocks (~5 min)
max-tier: u3               ;; Up to tier 3
batch-limit: u100          ;; Max 100 NFTs per batch
```

### Modify Parameters

```clarity
;; Increase rewards
(update-reward-rate u15)

;; Adjust cooldown
(update-cooldown u25)

;; Change tier
(set-nft-tier u123 u2)

;; Boost user rewards
(set-boost 'ST...' u200)
```

##  Architecture

### Data Maps

```clarity
staked-nfts     → {owner: principal, staked-at: uint}
rewards         → principal → uint
reputation      → principal → uint
nft-tier        → uint → uint
boost-multiplier → principal → uint
referrals       → principal → principal
penalties       → principal → uint
```

### State Variables

```clarity
reward-rate      ;; Current reward rate
staking-count    ;; Total staked NFTs
cooldown-period  ;; Unstake delay
max-tier         ;; Max tier level
dao-admin        ;; Admin address
```

##  Reward Calculation

```
Reward = Base Rate × Tier × Boost × Duration

Example:
Base: 10 STX/block
Tier 2 NFT: ×2
VIP Boost: ×1.5
100 blocks: ×100

Total = 10 × 2 × 1.5 × 100 = 3,000 STX
```

##  Error Codes

| Code | Error | Meaning |
|------|-------|---------|
| u400 | ERR-AUTH | Unauthorized |
| u401 | ERR-NOT-FOUND | NFT not found |
| u402 | ERR-STATE | Invalid state |
| u403 | ERR-BALANCE | Insufficient balance |

##  Security

- ✅ Access control on admin functions
- ✅ Input validation on all parameters
- ✅ Safe STX transfers
- ✅ Reentrancy protection
- ⚠️ Recommend external audit before mainnet

##  Contributing

1. Fork repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Implement changes
4. Test in testnet
5. Commit: `git commit -m 'feat: Add feature'`
6. Push & create Pull Request

##  License

MIT License - See LICENSE file

##  Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/nft-staking-reward/issues)
- **Docs**: Full Documentation
- **Email**: support@example.com

## Resources

- [Stacks Docs](https://docs.stacks.co/)
- [Clarity Guide](https://docs.stacks.co/clarity)
- [Smart Contract Best Practices](https://docs.stacks.co/understand-stacks/smart-contracts)

---

**Version**: 1.0.0  
**Network**: Stacks Mainnet & Testnet  
**Last Updated**: January 21, 2026
```

This condensed README maintains all essential information while being much more concise and easier to scan!This condensed README maintains all essential information while being much more concise and easier to scan!
