## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Diagram

```mermaid
classDiagram
    class OrderExecutor {
        +address userPoints
        +mapping(uint256 => Policy) policies
        +constructor(address _userPoints)
        +execute(address orderHandler, bytes order, bytes signature, bytes appSig)
        -validatePolicy(OrderHeader header, OrderReceipt receipt, bytes appSig)
    }
    
    class IOrderExecutor {
        <<interface>>
        +execute(address orderHandler, bytes order, bytes signature, bytes appSig)
    }
    
    class IOrderHandler {
        <<interface>>
        +execute(address user, bytes order, bytes signature) returns (OrderHeader, OrderReceipt)
    }
    
    class IPolicyValidator {
        <<interface>>
        +validatePolicy(OrderHeader header, bytes appSig) returns (address)
    }
    
    class IUserPoints {
        <<interface>>
        +consumePoints(address user, uint256 points)
    }
    
    class OrderHeader {
        <<struct>>
        +address user
        +uint256 policyId
        +uint256 nonce
        +uint256 deadline
    }
    
    class OrderReceipt {
        <<struct>>
        +uint256 points
    }
    
    class Policy {
        <<struct>>
        +address validator
        +uint256 policyId
    }
    
    OrderExecutor ..|> IOrderExecutor : implements
    OrderExecutor --> IOrderHandler : calls
    OrderExecutor --> IPolicyValidator : calls
    OrderExecutor --> IUserPoints : calls
    IOrderHandler --> OrderHeader : returns
    IOrderHandler --> OrderReceipt : returns
    IPolicyValidator --> OrderHeader : uses
    OrderExecutor o-- Policy : contains
```


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
