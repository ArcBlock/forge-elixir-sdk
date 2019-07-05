![Forge Elixir SDK](https://www.arcblock.io/.netlify/functions/badge/?text=Forge%20Elixir%20SDK)

This is the Elixir / Erlang version of the SDK for Forge framework.

## What is Forge framework?

Forge is a full fledge blockchain framework for developers to build decentralized applications easily. Unlike other public chain solutions (e.g. Ethereum), forge gives the developers / operators the freedom to launch their own customized chains with their own application logic. For example, one can easily build a chain on top of forge to allow their users to host events and sell event tickets - although centralized services can do this kind of requirements perfectly, giving that data is not owned by centralized service, people can easily exchange tickets freely, without the permission of the original service.

For non-blockchain developers, Forge opened a door to build services that give you the following unique benefits:

* authenticated storage: data could be trusted from the input (transaction) all the way down to the storage (state)
* authenticated computation: the software would execute in a trust-worthy manner.
* fault tolerance: the software could resist from CFT (crash fault tolerance) to BFT (byzantine fault tolerance).
* built-in payment support: without any extra effort developer could build a system with payment support. For example, a bidding system that is open and transparent; a trading system for digital assets that you can trust.

## What have Forge provided?

In a very high level, a typical blockchain app consists of:

* networking: for secure p2p connectivity and data replication.
* mempool: for broadcasting tx.
* consensus: for agreeing on most recent block.
* storage: account states.
* VM: for executing transactions.
* app logic: for specific business logic, e.g. create event and sell tickets.
* RPC: for providing functionalities for user to interact with the chain.

Forge provides these functionalities:

* A diversified wallet system. User / developers can choose their favorite algorithms that supported by [Mcrypto](https://github.com/ArcBlock/mcrypto) to generate their wallet. And keep the wallet safe by constantly migrate the wallet to a new set of keys or even algorithm.
* A fat tx protocol layer. Forge ships with many common tx protocols for you to build the application, including but not limited to:
  * declare / migrate: declare a wallet, a node, an app, or anything backed by a wallet to the chain. Migrate a wallet to another one - as simple as password rotation.
  * create_asset / update_asset / consume_asset / create_asset_factory / acquire_asset: you can create non-fungible tokens easily and transfer / exchange them or consume them.
  * transfer / exchange: you can transfer both fungible and non-fungible assets to others or you can request assets from others. You can even mark your non-fungible asset with a price and anyone who will pay for the price would get the asset (trade), you can even put your asset in a market and everyone else can big for your asset and you choose one bid that satisfy you and finish the transaction.
  * stake / unstake: you can stake tokens for various purpose, e.g. promote a node to be a validator, participant in a vote, etc (currently in beta).
  * create_poll / vote: vote for on-chain governance or other purpose (will be released soon).
* a blockchain backend. Forge separate the storage engine and consensus engine from upper layer, and currently built on top of [tendermint](https://github.com/tendermint/tendermint) for the consensus engine and [ipfs](https://github.com/ipfs/go-ipfs) for the storage engine. The consensus engine is for mempool synchronization and reaching agreement on next block (PBFT consensus at the moment, in future we may introduce PoW); the storage engine will store big files across the network, which could be used for various purpose (currently in private alpha). For all the states tenerated by the execution of transactions, Forge will store them in rocksdb in an authenticated way by using [merkle patricia tree](https://github.com/ethereum/wiki/wiki/Patricia-Tree)(MPT). At the moment we separated the data into several column families: default, account, asset, receipt.
* A rich developer interface. Forge ship with GRPC and GraphQL RPC for developers to use it in different situation. If you aim on building a web application, GraphQL RPCs will be your friends; if you're building a forge app that extend the capability of the forge (e.g. adding new tx protocols), GRPC shall be used. Normally the GRPC interface for a node shall not be accessible externally. Inside forge, GraphQL RPC is just a user friendly wrap to GRPC interface, thus they share almost the same capabilities.
* Multiple language support. Forge is made to be universally available for various languages. Besides erlang / elixir, we provided nodejs / python SDK, so that you can use nodejs / python to build forge applications. Our forge cli and forge web are built on top of the nodejs SDK.
* A rich UI. In the forge ecosystem, we provided forge cli for general purpose administration (for developers), forge web (aka AMC - Arcblock Management Console) for node admin.

## Installation

For every new release we ship osx and ubuntu binaries. If you're using these two platforms, you can install latest forge-cli:

```bash
$ npm install -g @arcblock/forge-cli
```

And then run:

```bash
$ forge init
$ forge start
$ forge web start
```

Once forge is started, you can open `http://localhost:8210` in your browser. Since there's no any data in your chain (if it is your first run), you can run our simulator to inject some random data:

```bash
$ forge simulator start
```

## Forge SDK

To develop applications on top of the forge, you shall pick up a SDK. Forge SDK is intended to make the interaction with the chain built by Forge as easy as possible. All SDK APIs are organized into the following categories:

- chain APIs: provide the client wrapper for chain related gRPC
- wallet APIs: provide the client wrapper for wallet related gRPC
- state APIs: provide the client wrapper for state related gRPC
- subscription APIs: provide the client wrapper for subscription related gRPC
- transaction APIs: the gRPC for transaction is send_tx, this set of APIs provide helper functions to make building and sending a tx easy.
- misc APIs: parsing configuration, initialize sdk and more.

For more information, please see: [Forge SDK overview](https://docs.arcblock.io/forge/latest/sdk/)

## Guide for other SDK

### Send TX

All common protocol buffers are defined in [forge-abi](https://github.com/arcblock/forge-abi). For example, a general tx structure (defined in https://github.com/ArcBlock/forge-abi/blob/v1.4.0/lib/protobuf/type.proto#L128):

```proto
message Transaction {
  string from = 1;
  uint64 nonce = 2;
  string chain_id = 3;
  bytes pk = 4;
  bytes signature = 13;
  repeated Multisig signatures = 14;
  google.protobuf.Any itx = 15;
}
```

`itx` means inner transaction. In forge, we supports various itx, including: declare, transfer, exchange, stake, etc. For itx definition, please go to [tx.proto](https://github.com/ArcBlock/forge-abi/blob/v1.4.0/lib/protobuf/tx.proto#L67). Here's an example of declare:

```proto
message DeclareTx {
  string moniker = 1;
  string issuer = 2;
  google.protobuf.Any data = 15;
}
```

Once you filled in an itx, you shall wrap it with a `google.protobuf.Any`. The type_urls defined in forge are:

```
{:account_migrate, "fg:t:account_migrate", AccountMigrateTx},
{:poke, "fg:t:poke", PokeTx},
{:consume_asset, "fg:t:consume_asset", ConsumeAssetTx},
{:create_asset, "fg:t:create_asset", CreateAssetTx},
{:consensus_upgrade, "fg:t:consensus_upgrade", ConsensusUpgradeTx},
{:declare, "fg:t:declare", DeclareTx},
{:declare_file, "fg:t:declare_file", DeclareFileTx},
{:exchange, "fg:t:exchange", ExchangeTx},
{:stake, "fg:t:stake", StakeTx},
{:sys_upgrade, "fg:t:sys_upgrade", SysUpgradeTx},
{:transfer, "fg:t:transfer", TransferTx},
{:update_asset, "fg:t:update_asset", UpdateAssetTx},
```

which could be found in [here](https://github.com/ArcBlock/forge-abi/blob/v1.4.0/lib/forge_abi/util/type_url.ex#L59) (later on we will extract it into a text file).

For declare itx, the itx is `fg:t:declare`. Note that the type url in forge use the format simular to urn, with 3 parts:

- 1st part is the namespace, `fg` stands for forge
- 2nd part is type, `t` means transaction
- 3rd part is name of the tx, here is `declare`. We use acronym just to save space

So once you filled in declare tx, you shall do `Google.Protobuf.Any.new(type_url: "fg:t:declare", value: ForgeAbi.DeclareTx.encode(itx))`, which `ForgeAbi.DeclareTx.encode/1` is the protobuf compiled functionality in your language.

Then you can put the itx into the tx, and provide `from`, `nonce` (you can just increment this value for now, later on we will deprecate it), `chain_id` (e.g. `forge`). Please leave `signature` and `signatures` as protobuf default value. Then you can sign the tx with the following algo:

1. Do `ForgeAbi.Transaction.encode(tx)`, this will get the bytes of the tx;
2. Calculate the hash of the encoded tx by using the hash algorithm defined in wallet type;
3. Sign the hash with the private key;
4. Do url base64 encode for the signature, and attach it to the tx;
5. Json encode the tx. And then send it with send_tx graphql API.

### Exchange itx

Most of the itx only required single signature, which shall be the sender's signature, to fulfill the transaction. However, transactions like exchange required multiple signature. To properly sign an exchange tx, we need to follow the simular guide as `declare`, which, the sender need to attach its signature into the `signature` field. However, before sending the tx to the chain, the receiver shall attach her signature as well. We have a `signatures` field, which is a `KVPair` for this purpose. Receiver first shall verify the signature of the sender is correct (look up the sender state in the chain and verify the signature with its PK from sender's account state), then sign the entire tx with receiver's sk (the sign flow is the same, here we use receiver's wallet type). Then receiver generate a `KVPair`, with her address as the key, and the signature as the value, and put the pair to the `signatures` list.

Currently for exchange we just need receiver's signature. In future, 3rd party may also need to attach its signature into this tx.
