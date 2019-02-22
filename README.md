# ForgeSdk

Elixir SDK for Forge.


## Guide for other SDK

### Send TX

All protos are defined in [forge-abi](https://github.com/arcblock/forge-abi). For example, a general tx structure (defined in https://github.com/ArcBlock/forge-abi/blob/master/lib/protobuf/type.proto#L94):

```proto
message Transaction {
  string from = 1;
  uint64 nonce = 2;
  bytes signature = 3;
  // use DID for the chain. "did:" prefix is omitted
  string chain_id = 4;
  // we will support multiple signatures in case of certain tx need multiple
  // parties' signature.
  repeated abci_vendor.KVPair signatures = 5;

  google.protobuf.Any itx = 7;
```

itx means inner transaction, in forge, we supports various itx, including: declare, transfer, exchange, stake, etc. For itx definition, please go to [tx.proto](https://github.com/ArcBlock/forge-abi/blob/master/lib/protobuf/tx.proto). Here's an example of declare:

```proto
message DeclareTx {
  string moniker = 1;
  bytes pk = 2;
  WalletType type = 3;

  // forge won't update data into state if app is interested in this tx.
  google.protobuf.Any data = 15;
}
```

moniker / pk / type are required. For `type`, please provide fields described in https://github.com/ArcBlock/forge-abi/blob/master/lib/protobuf/type.proto#L17.

Once you filled in an itx, you shall wrap it with a `google.protobuf.Any`. The type_urls defined in forge are:

```
{:account_migrate, "fg:t:account_migrate", AccountMigrateTx},
{:create_asset, "fg:t:create_asset", CreateAssetTx},
{:consensus_upgrade, "fg:t:consensus_upgrade", ConsensusUpgradeTx},
{:declare, "fg:t:declare", DeclareTx},
{:declare_file, "fg:t:declare_file", DeclareFileTx},
{:exchange, "fg:t:exchange", ExchangeTx},
{:stake, "fg:t:stake", StakeTx},
{:sys_upgrade, "fg:t:sys_upgrade", SysUpgradeTx},
{:transfer, "fg:t:transfer", TransferTx},
{:update_asset, "fg:t:update_asset", UpdateAssetTx}
```

which could be found in https://github.com/ArcBlock/forge-abi/blob/master/lib/forge_abi/util/type_url.ex#L57 (later on we will extract it into a text file).

So for declare itx, the itx is `fg:t:declare`. Note that the type url in forge use the format simular to urn, with 3 parts: 1st part is the namespace, `fg` stands for forge, the 2nd part is type, `t` means transaction, the last part is name of the tx, here is `declare`. We use acronym just to save space.

So once you filled in declare tx, you shall do `Any.new(type_url: "fg:t:declare", value: Transfer.encode(itx))`, which `Transfer.encode` is the protobuf compiled functionality in your language.

Then you can put the itx into the tx, and provide `from`, `nonce` (you can just increment this value for now, later on we will deprecate it), `chain_id` (e.g. `forge`). Please leave `signature` and `signatures` as protobuf default value. Then you can sign the tx with the following algo:

1. Do `Transaction.encode(tx)`, this will get the bytes of the tx.
2. Calculate the hash of the encoded tx by using the hash algorithm defined in wallet type.
3. Sign the hash with the private key.
4. do url base64 encode for the signature, and attach it to the tx.
5. Json encode the tx. And then send it with send_tx graphql API.
