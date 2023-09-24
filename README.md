# Foundry DAO Governance

A Foundry DAO Governance Project that is part of Cyfrin Solidity Blockchain Course.

### About

1. A contract controlled by a DAO.
2. Every transaction that the DAO wants to send has to be voted on.
3. Use ERC20 tokens for voting.

## Getting Started

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

### Quick Start

```
git clone https://github.com/dannweeeee/foundry-upgrades-f23
cd foundry-upgrades-f23
forge build
```

## Usage

### Test

```
forge test
```

### Deploy

I did not write deploy scripts for this project, you can if you'd like!

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see and output file called `.gas-snapshot`

## Formatting

To run code formatting:

```
forge fmt
```
