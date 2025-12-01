# PILI Documentation

Welcome to the **PILI (Privacy-preserving Impermanent Loss Insurance)** documentation! This folder contains comprehensive documentation for the FHE-Protected IL Insurance Hook for Uniswap v4.

---

## 📚 Documentation Structure

### 1. [PRD.md](./PRD.md) - Product Requirements Document
**The complete technical specification**

This is the main PRD containing:
- Executive summary and problem statement
- Detailed functional requirements (FR-IL-001 through FR-PB-007)
- Non-functional requirements (performance, security, privacy)
- Technical architecture and smart contract specifications
- User interface mockups
- Development roadmap
- Success metrics and KPIs

**Best for:** Product managers, developers, stakeholders who need complete technical details

---

### 2. [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Deep Dive Analysis
**Understanding the concepts behind the PRD**

This document breaks down:
- What impermanent loss is (with real examples)
- How FHE (Fully Homomorphic Encryption) works
- Detailed user experience flows
- Privacy and security deep dive
- Business model and economics
- Go-to-market strategy
- Technical concepts explained (IL formula, basis points, FHE operations)

**Best for:** Anyone who wants to deeply understand the product, business stakeholders, investors

---

### 3. [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - Visual Reference
**Quick reference with diagrams and charts**

This document provides:
- System architecture diagrams (Mermaid)
- User journey sequence diagrams
- Impermanent loss visualization
- Privacy comparison charts
- Risk assessment matrix
- Technology stack overview
- Development timeline
- Quick reference cheat sheets

**Best for:** Quick understanding, presentations, visual learners, executives

---

## 🎯 Quick Start Guide

### New to the Project?
**Start here:** [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) → [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) → [PRD.md](./PRD.md)

### Need Technical Specs?
**Go to:** [PRD.md](./PRD.md) - Section 2.3 (Functional Requirements) and Section 4 (Technical Specifications)

### Want to Understand IL?
**Read:** [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "What Problem Does This Solve?"

### Looking for Business Case?
**Check:** [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "Business Model & Economics"

### Need Diagrams for Presentation?
**Use:** [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - All sections with Mermaid diagrams

---

## 🔑 Key Concepts

### What is PILI?
**PILI** (Privacy-preserving Impermanent Loss Insurance) is a Uniswap v4 hook that provides automated, privacy-preserving protection against impermanent loss for liquidity providers.

### Core Features
1. **Automated IL Protection** - Set your max acceptable IL, auto-exit when breached
2. **Privacy via FHE** - Your risk parameters are encrypted, invisible to MEV bots
3. **Price Bounds Protection** - Optional upper/lower price limits
4. **Gas Optimized** - ~$3-5/month per protected position
5. **Trustless** - No centralized intermediaries

### How It Works (30-Second Version)
1. LP deposits liquidity + sets encrypted IL threshold (e.g., 5%)
2. After each swap, hook calculates current IL
3. Compares encrypted current IL vs encrypted threshold using FHE
4. If threshold breached → automatic withdrawal
5. Privacy maintained throughout (no one knows your 5% threshold)

---

## 📖 Document Summaries

### PRD.md Highlights
- **Section 1:** Problem statement and solution overview
- **Section 2:** IL Protection Hook (12 functional requirements)
- **Section 3:** Price Bounds Hook (7 functional requirements)
- **Section 4:** Technical specifications (smart contracts, FHE integration)
- **Section 5:** User experience flows
- **Section 6:** 9-month development roadmap
- **Section 7:** Success criteria and KPIs
- **Section 8:** Risk assessment and mitigations

### PRD_ANALYSIS.md Highlights
- **Impermanent Loss Explained:** Real-world examples with numbers
- **FHE Deep Dive:** How encryption enables private computation
- **User Journey:** Alice's complete experience from deposit to auto-exit
- **Privacy & Security:** Why FHE matters, attack vectors, mitigations
- **Economics:** Revenue models, cost structure, break-even analysis
- **Go-to-Market:** Target audience, marketing channels, launch strategy

### VISUAL_GUIDE.md Highlights
- **System Architecture:** Complete flow from frontend to blockchain
- **User Journey:** Sequence diagram showing all interactions
- **IL Visualization:** Graph showing HODL vs LP value
- **Privacy Comparison:** With FHE vs without FHE
- **Risk Matrix:** Impact vs probability quadrant chart
- **Technology Stack:** All layers and components
- **Cheat Sheets:** Quick reference for formulas and conversions

---

## 🎓 Learning Paths

### For Developers
1. Read [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - System Architecture
2. Study [PRD.md](./PRD.md) - Section 4 (Technical Specifications)
3. Review [PRD.md](./PRD.md) - Section 2.3 (Functional Requirements)
4. Check [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Key Technical Concepts
5. Explore [PRD.md](./PRD.md) - Section 2.5 (Technical Architecture)

### For Product Managers
1. Start with [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - One-Minute Summary
2. Read [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Problem Statement
3. Review [PRD.md](./PRD.md) - Section 1 (Product Overview)
4. Study [PRD.md](./PRD.md) - Section 2.2 (User Stories)
5. Check [PRD.md](./PRD.md) - Section 6 (Development Roadmap)

### For Business Stakeholders
1. Read [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - One-Minute Summary
2. Review [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Business Model & Economics
3. Check [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Go-to-Market Strategy
4. Study [PRD.md](./PRD.md) - Section 1.3 (Success Metrics)
5. Review [PRD.md](./PRD.md) - Section 8 (Risks & Mitigations)

### For Investors
1. Start with [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - One-Minute Summary
2. Read [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Key Takeaways (For Investors)
3. Review [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Business Model & Economics
4. Check [PRD.md](./PRD.md) - Section 1.3 (Success Metrics)
5. Study [PRD.md](./PRD.md) - Section 8 (Risks & Mitigations)

---

## 🔍 Find Information Fast

### Questions & Answers

**"What is impermanent loss?"**
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "The Core Problem: Impermanent Loss"

**"How does FHE work?"**
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "What is FHE?"

**"What are the functional requirements?"**
→ [PRD.md](./PRD.md) - Section 2.3 (IL Protection) and 3.3 (Price Bounds)

**"How much will it cost to use?"**
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "Business Model & Economics"

**"What's the development timeline?"**
→ [PRD.md](./PRD.md) - Section 6 (Development Roadmap)  
→ [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - Development Roadmap diagram

**"How does the user experience work?"**
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "User Experience Flow"  
→ [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - User Journey Flow diagram

**"What are the security risks?"**
→ [PRD.md](./PRD.md) - Section 4.4 (Security Considerations)  
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "Privacy & Security Deep Dive"

**"What's the tech stack?"**
→ [PRD.md](./PRD.md) - Section 4.1 (Smart Contract Architecture)  
→ [VISUAL_GUIDE.md](./VISUAL_GUIDE.md) - Technology Stack diagram

**"How do we measure success?"**
→ [PRD.md](./PRD.md) - Section 1.3 (Success Metrics) and Section 7 (Success Criteria)

**"What's the go-to-market strategy?"**
→ [PRD_ANALYSIS.md](./PRD_ANALYSIS.md) - Section "Go-to-Market Strategy"

---

## 📊 Document Statistics

| Document | Pages | Word Count | Best For |
|----------|-------|------------|----------|
| PRD.md | ~25 | ~6,500 | Complete technical reference |
| PRD_ANALYSIS.md | ~35 | ~9,000 | Deep understanding |
| VISUAL_GUIDE.md | ~20 | ~3,500 | Quick reference, presentations |

---

## 🛠️ Technical Reference

### Key Formulas

**Impermanent Loss:**
```
IL = 2 × √(priceRatio) / (1 + priceRatio) - 1
```

**Price Ratio:**
```
priceRatio = currentPrice / entryPrice
```

**Basis Points Conversion:**
```
percentage × 100 = basis points
5% × 100 = 500 bp
```

### Smart Contract Functions

**IL Protection Hook:**
- `beforeAddLiquidity()` - Register LP position with encrypted threshold
- `afterSwap()` - Check IL and trigger withdrawal if needed
- `calculateIL()` - Compute current impermanent loss
- `compareThreshold()` - FHE comparison of current IL vs threshold

**Price Bounds Hook:**
- `beforeAddLiquidity()` - Register price bounds
- `afterSwap()` - Check if price exceeds bounds
- `checkPriceBounds()` - FHE comparison of current price vs bounds

### FHE Operations

```solidity
// Encrypt value
euint32 encrypted = FHE.asEuint32(value);

// Compare (greater than)
ebool result = FHE.gt(encryptedA, encryptedB);

// Enforce condition
FHE.req(result); // Reverts if false
```

---

## 🔗 External Resources

### Uniswap v4
- [Official Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [Hooks Guide](https://docs.uniswap.org/contracts/v4/concepts/hooks)
- [GitHub Repository](https://github.com/Uniswap/v4-core)

### Fhenix (FHE)
- [Fhenix Documentation](https://docs.fhenix.io/)
- [Fhenix.js SDK](https://github.com/fhenixprotocol/fhenix.js)
- [FHE Explained](https://www.fhenix.io/fhe-explained)

### Impermanent Loss
- [Uniswap IL Guide](https://uniswap.org/docs/v2/concepts/advanced-topics/understanding-returns/)
- [IL Calculator](https://dailydefi.org/tools/impermanent-loss-calculator/)
- [Binance Academy: IL Explained](https://academy.binance.com/en/articles/impermanent-loss-explained)

### DeFi Security
- [Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [MEV Explained](https://ethereum.org/en/developers/docs/mev/)
- [DeFi Security Standards](https://defisafety.com/)

---

## 📝 Contributing to Documentation

### Updating Documents

When updating these documents, please:

1. **Maintain consistency** across all three files
2. **Update version numbers** at the bottom of each document
3. **Add to version history** table in PRD.md
4. **Keep diagrams in sync** with technical specifications
5. **Test all Mermaid diagrams** to ensure they render correctly

### Document Conventions

- **File naming:** Use UPPERCASE_WITH_UNDERSCORES.md
- **Section headers:** Use sentence case with emoji prefixes
- **Code blocks:** Always specify language for syntax highlighting
- **Links:** Use relative paths for internal docs, absolute for external
- **Diagrams:** Use Mermaid for all diagrams (consistency)

---

## 📞 Contact & Support

### Project Team
- **Product Lead:** TBD
- **Tech Lead:** TBD
- **Security Lead:** TBD
- **Documentation:** TBD

### Community
- **Discord:** [Join Server](#)
- **Telegram:** [Join Group](#)
- **Twitter:** [@PILI_Protocol](#)
- **GitHub:** [PILI Repository](#)

---

## 📅 Document Version History

| Version | Date | Changes | Updated By |
|---------|------|---------|------------|
| 1.0 | 2025-11-26 | Initial documentation suite created | Product Team |

---

## 📄 License

This documentation is part of the PILI project. All rights reserved.

---

**Last Updated:** November 26, 2025  
**Documentation Version:** 1.0
