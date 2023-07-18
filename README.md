# Fix Issues in Flexible Staking

## Story
You have excelled in a lot of developers competitions and have become a proficient Smart Contracts Developer. Your first commercial project involves developing a flexible staking smart contract. After quickly coding the contract and preparing for deployment, an independent Smart Contracts Auditor contacted you with the following message:

> Your contract is vulnerable to front-running attacks when the staked liquidity amount is low (High severity issue). Additionally, there is an inconsistency in the rewards calculation algorithm (Medium severity issue).
>
> If you're interested in the details, I can share them, but not for free.

Eager to prove yourself, you decide to identify and fix these bugs on your own. Your task is to find the issues, write corresponding tests, and rectify the problems.

## Quest
Review the smart contract and identify the following issues:

- Front-Running Attack

    This vulnerability can occur when the staked liquidity amount is low. User funds attached to the front-run transaction can be drained partially or entirely.

- Convert Rate Manipulation

    The convert rate could be artificially pumped (increase of `ShareCoin` price) or dumped (decrease of `ShareCoin` price). If the convert rate is excessively high, users may encounter difficulties staking small amounts of funds. Dumping the convert rate may influence off-chain system logic.

Your task is to write tests that demonstrate the existence of these issues by causing test failures in the `flex_staking_custom_tests` module.

Afterward, modify the smart contract (the `flex_staking` module) to address the issues. Try to make minimal changes to the code.

## Submission Criteria
- The smart contract should be fully consistent with the requirements below.
- Users should not lose more than `1 StakeCoin` after a `deposit - withdraw` round, independently of other actors.
- The convert rate should be initially `1 ShareCoin : 1 StakeCoin`, and it should not be possible to pump the `ShareCoin` price more than `10_000` times by a single attacker (considering the attacker would not like to lose more than `50_000 * 10^decimals StakeCoin`).
- It should not be possible to dump the `ShareCoin` price.
- The code should not fail due to integer overflows or underflows, independently of the user balance (considering the total supply of `StakeCoin` does not exceed the maximum user balance `u64::MAX`).
- The smart contract should not be influenced by flash-loaning of `StakeCoin`.
- The code coverage of the submission should be `100%`. Use `aptos move test --coverage` command to validate it.

## Smart Contract Requirements
The smart contract is an integral part of a large system. It should facilitate the acceptance of `StakeCoin` (currently `AptosCoin`) transfers from various profitable system components and distribute funds proportionally among all stakers based on their shares. Users should receive `ShareCoin` for their deposits.

### Deposit
This function allows users to stake funds and receive share tokens.

Signature: `entry public`
- `user: &signer` - caller
- `amount: u64` - amount of coins to deposit

### Withdraw
This function enables users to return share tokens and receive stake tokens with rewards.

Signature: `entry public`
- `user: &signer` - caller
- `amount: u64` - amount of coins to withdraw

### Burn
This function permits users to burn their share tokens. The burned value should be distributed among other share token holders.

Signature: `entry public`
- `user: &signer` - caller
- `amount: u64` - amount of coins to burn

### Get Converted
This function allows users to predict the token amount after conversion.

Signature: `entry public`
- `amount: u64` - amount of coins to convert
- `reverse: bool` - converting from share to stake tokens or vice versa

Returns `converted_amount: u64`

## Interaction Flow Examples

### Rewards received from incoming transfers
1. User A deposits `100 StakeCoin` and receives `100 ShareCoin` | `100 : 100`
2. User B deposits `100 StakeCoin` and receives `100 ShareCoin` | `200 : 200`
3. User C deposits `100 StakeCoin` and receives `100 ShareCoin` | `300 : 300`
4. An incoming transaction brings `90 StakeCoin` and increases the value of `ShareCoin` | `300 : 390`
5. User B withdraws `100 ShareCoin` and receives `130 StakeCoin` | `200 : 260`
6. User C withdraws `50 ShareCoin` and receives `195 StakeCoin` | `150 : 195`
7. User B deposits `1000 StakeCoin` and receives `769 ShareCoin` | `919 : 1195`

### Rewards received from shares burning
1. User A deposits `100 StakeCoin` and receives `100 ShareCoin` | `100 : 100`
2. User B deposits `100 StakeCoin` and receives `100 ShareCoin` | `200 : 200`
3. User C deposits `200 StakeCoin` and receives `200 ShareCoin` | `400 : 400`
4. User B burns `50 ShareCoin` and increases the value of `ShareCoin` | `350 : 400`
5. User C withdraws `200 ShareCoin` and receives `228 StakeCoin` | `150 : 172`
6. User B deposits `1000 StakeCoin` and receives `872 ShareCoin` | `1022 : 1172`
