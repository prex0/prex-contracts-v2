## Prex V2

**Prex V2 is a new version of Prex that is more flexible and powerful.**


### Overview
Prex V2 is a comprehensive smart contract system designed to facilitate secure and efficient order execution, policy validation, and token management on the Ethereum blockchain. It leverages modular architecture and integrates with OpenZeppelin's libraries to ensure robust governance and access control.

### Features
- Order Execution: Execute orders with integrated policy validation to ensure compliance with predefined rules.
- Policy Management: Utilize various policy primitives, including counter and whitelist policies, to enforce execution limits and access control.
- Token Management: Create and manage tokens with the ability to mint up to a maximum supply.
- Lottery System: Manage lotteries with multiple prizes, allowing for creation and drawing of lotteries.
- Governance: Implement governance functionalities for managing proposals and voting.
- Access Control: Manage permissions and roles to ensure only authorized actions are performed.


## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
