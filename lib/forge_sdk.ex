defmodule ForgeSdk do
  @moduledoc """

  Forge is a full fledge blockchain framework for developers to build decentralized applications easily. Forge gives the developers / operators the freedom to launch their own customized chains with their own application logic.

  This is the Elixir / Erlang version of the SDK for Forge framework. To develop applications on top of the forge, you shall pick up a SDK. Forge SDK is intended to make the interaction with the chain built by Forge as easy as possible. All SDK APIs are organized into the following categories:

  - chain APIs: provide the client wrapper for `chain` related gRPC
  - wallet APIs: provide the client wrapper for `wallet` related gRPC
  - state APIs: provide the client wrapper for `state` related gRPC
  - subscription APIs: provide the client wrapper for `subscription` related gRPC
  - transaction APIs: the gRPC for transaction is `send_tx`, this set of APIs provide helper functions to make building and sending a tx easy.
  - misc APIs: parsing `configuration`, initialize sdk and more.

  """
  alias ForgeAbi.{
    # other
    AccountState,
    AssetState,
    BlockInfo,
    BlockInfoSimple,
    ChainInfo,
    ForgeState,
    NetInfo,
    NodeInfo,
    PageInfo,
    ProtocolState,
    Transaction,
    TransactionInfo,
    ValidatorsInfo,
    WalletInfo,

    # request response
    RequestCreateTx,
    RequestCreateWallet,
    RequestGetAccountState,
    RequestGetAssetState,
    RequestGetBlock,
    RequestGetBlocks,
    RequestGetTx,
    RequestLoadWallet,
    RequestMultisig,
    RequestGetProtocolState,
    RequestRecoverWallet,
    RequestRemoveWallet,
    RequestSendTx,
    RequestSubscribe,
    RequestUnsubscribe,
    ResponseSubscribe
  }

  alias ForgeSdk.{Display, Loader, Rpc, Util, Wallet}

  @doc """
  Migrate a `wallet` from old address (as well as pk, sk) to a new address.

  ## Example

      old_wallet = ForgeSdk.create_wallet()
      declare_tx = ForgeAbi.DeclareTx.new(moniker: "sisyphus")
      ForgeSdk.declare(declare_tx, wallet: old_wallet)
      new_wallet = ForgeSdk.create_wallet()
      itx = ForgeAbi.AccountMigrateTx.new(pk: new_wallet.pk, address: new_wallet.address)
      ForgeSdk.account_migrate(itx, wallet: old_wallet)

  """
  @spec account_migrate(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate account_migrate(itx, opts), to: Rpc

  @doc """
  Acquire an `asset` from an existing asset factory.

  ## Example

      w = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "theater"), wallet: w)
      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "tyr"), wallet: w1)

      # Note application shall already registered `Ticket` into Forge via `deploy_protocol`.
      factory = %{
      description: "movie ticket factory",
      limit: 5,
      price: ForgeAbi.token_to_unit(1),
      template: ~s({
          "row": "{{ row }}",
          "seat": "{{ seat }}",
          "time": "11:00am 04/30/2019",
          "room": "4"
        }),
      allowed_spec_args: ["row", "seat"],
      asset_name: "Ticket",
      attributes: %ForgeAbi.AssetAttributes{
        transferrable: true,
        ttl: 3600 * 3
        }
      }

      ForgeSdk.create_asset_factory("Avenerages: Endgame", factory, wallet: w)

      specs =
        Enum.map(["0", "2"], fn seat ->
          apply(ForgeAbi.AssetSpec, :new, [%{data: ~s({"row": "15", "seat": "\#{seat}"})}])
        end)

      itx = ForgeAbi.AcquireAssetTx.new(to: address, specs: specs)

      ForgeSdk.acquire_asset(itx, wallet: w1)

  """
  @spec acquire_asset(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate acquire_asset(itx, opts), to: Rpc
  # defdelegate consensus_upgrade(itx, opts), to: Rpc

  @spec prepare_consume_asset(map(), Keyword.t()) :: Transaction.t() | {:error, term()}
  defdelegate prepare_consume_asset(itx, opts), to: Rpc

  @spec finalize_consume_asset(Transaction.t(), Keyword.t()) ::
          {:error, any()} | Transaction.t()
  defdelegate finalize_consume_asset(tx, opts), to: Rpc

  @doc """
  Create a new `asset`.

  ## Example

      wallet = ForgeSdk.create_wallet()
      declare_tx = ForgeAbi.DeclareTx.new(moniker: "sisyphus")
      ForgeSdk.declare(declare_tx, wallet: wallet)
      ticket = ForgeAbi.Ticket.new(row: "K", seat: "22", room: "3A", time: "03/04/2019 11:00am PST",
      name: "Avengers: Endgame")
      itx = ForgeAbi.CreateAsset.new(data: ForgeSdk.encode_any!(ticket), readonly: true,
      transferrable: true, ttl: 7200)
      ForgeSdk.create_asset(itx, wallet: wallet)

  """
  @spec create_asset(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate create_asset(itx, opts), to: Rpc

  @doc """
  Create a new `asset factory`.

  ## Example

      w = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "theater"), wallet: w)
      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "tyr"), wallet: w)

      # Note application shall already registered `Ticket` into Forge via `deploy_protocol`.
      factory = %{
        description: "movie ticket factory",
        limit: 5,
        price: ForgeAbi.token_to_unit(1),
        template: ~s({
            "row": "{{ row }}",
            "seat": "{{ seat }}",
            "time": "11:00am 04/30/2019",
            "room": "4"
          }),
        allowed_spec_args: ["row", "seat"],
        asset_name: "Ticket",
        attributes: %ForgeAbi.AssetAttributes{
          transferrable: true,
          ttl: 3600 * 3
        }
      }

      ForgeSdk.create_asset_factory("Avenerages: Endgame", factory, wallet: w)

  """
  @spec create_asset_factory(String.t(), map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate create_asset_factory(moniker, factory, opts), to: Rpc

  @doc """
  Declare a `wallet` to the chain.

  ## Example

      wallet = ForgeSdk.create_wallet()
      declare_tx = ForgeAbi.DeclareTx.new(moniker: "sisyphus")
      ForgeSdk.declare(declare_tx, wallet: wallet)

  """
  @spec declare(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate declare(itx, opts), to: Rpc
  # defdelegate declare_file(itx, opts), to: Rpc

  @doc """
  Deploy a `new protocol` into the chain at a given `block height`.

  ## Example

      itx = data |> Base.url_decode64!(padding: false) |> ForgeAbi.DeployProtocolTx.decode()
      ForgeSdk.deploy_protocol(itx, wallet: wallet)

  """
  @spec deploy_protocol(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate deploy_protocol(itx, opts), to: Rpc
  defdelegate deposit_tether(itx, opts), to: Rpc

  @spec prepare_exchange(map(), Keyword.t()) :: Transaction.t() | {:error, term()}
  defdelegate prepare_exchange(itx, opts), to: Rpc

  @spec finalize_exchange(Transaction.t(), Keyword.t()) :: {:error, term()} | Transaction.t()
  defdelegate finalize_exchange(tx, opts), to: Rpc

  defdelegate exchange_tether(itx, opts), to: Rpc

  # defdelegate sys_upgrade(itx, opts), to: Rpc

  @doc """
  One wallet can poke in a **daily basis** to get some free tokens (for test chains only), `nonce` should be 0.

  ## Example

      w = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w)
      itx = ForgeAbi.PokeTx.new(date: "2019-03-13", address: "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")
      req = ForgeAbi.RequestCreateTx.new(from: w.address, itx: ForgeAbi.encode_any!(:poke, itx),
      nonce: 0, token: t, wallet: w)
      tx = ForgeSdk.create_tx(req)
      hash = ForgeSdk.send_tx(tx: tx)

  """
  defdelegate poke(itx, opts), to: Rpc

  defdelegate stake(itx, opts), to: Rpc
  # defdelegate sys_upgrade(itx, opts), to: Rpc

  @doc """
  Transfer `tokens or/and assets` from one wallet to another.

  ## Example

      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w1)
      w2 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "bob"), wallet: w2)
      data = Google.Protobuf.Any.new(type_url: "test_asset", value: "hello world")
      itx = ForgeSdk.encode_any!(TransferTx.new(to: w2.address, value: new_unit(100)))
      ForgeSdk.transfer(req, wallet: w1)

  """
  @spec transfer(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate transfer(itx, opts), to: Rpc

  @doc """
  Update an existing `asset`.

  ## Example

      wallet = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: wallet)
      post = ForgeAbi.Post.new(title: "a new post", content: "hello world!")
      itx = ForgeAbi.CreateAsset.new(itx: ForgeSdk.encode_any!(post))
      hash = ForgeSdk.create_asset(itx, wallet: wallet)
      address = ForgeSdk.get_address(hash)
      new_post = ForgeAbi.Post.new(title: "a new post", content: "Yeah!")
      itx = ForgeAbi.UpdateAssetTx.new(data: ForgeSdk.encode_any!(post), address: address)
      ForgeSdk.get_asset_state(address: address)

  """
  @spec update_asset(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate update_asset(itx, opts), to: Rpc

  @doc """
  Upgrade the `node` to a new version at a given `block height`.

  ## Example

      itx = ForgeAbi.UpgradeNodeTx.new(version: "0.26.0", height: 12000)
      ForgeSdk.upgrade_node(itx, wallet: wallet)

  """
  @spec upgrade_node(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate upgrade_node(itx, opts), to: Rpc

  @spec activate_protocol(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate activate_protocol(itx, opts), to: Rpc

  @spec deactivate_protocol(map(), Keyword.t()) :: String.t() | {:error, term()}
  defdelegate deactivate_protocol(itx, opts), to: Rpc

  # defdelegate upgrade_task(itx, opts), to: Rpc

  defdelegate withdraw_tether(itx, opts), to: Rpc

  defdelegate approve_tether(itx, opts), to: Rpc

  defdelegate revoke_tether(itx, opts), to: Rpc

  defdelegate setup_swap(itx, opts), to: Rpc

  defdelegate retrieve_swap(itx, opts), to: Rpc

  defdelegate revoke_swap(itx, opts), to: Rpc

  defdelegate delegate(itx, opts), to: Rpc

  defdelegate deposit_token(itx, opts), to: Rpc

  defdelegate prepare_withdraw_token(itx, opts), to: Rpc

  defdelegate finalize_withdraw_token(itx, opts), to: Rpc

  defdelegate approve_withdraw(itx, opts), to: Rpc

  defdelegate revoke_withdraw(itx, opts), to: Rpc

  # extended tx helper
  defdelegate stake_for_node(address, amount, opts), to: Rpc

  # chain related
  @doc """
  One wallet can check in a daily basis to get some free tokens (for test chains only), `nonce` should be 0.

  ## Example
      w = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w)
      ForgeSdk.checkin(wallet: w)

  """
  @spec checkin(Keyword.t()) :: String.t() | {:error, term()}
  defdelegate checkin(opts), to: Rpc

  # RPC

  # chain related
  @doc """
  Retrieve the current status of the chain.

  ## Example

      ForgeSdk.get_chain_info()

  """
  @spec get_chain_info(String.t()) :: ChainInfo.t() | {:error, term()}
  defdelegate get_chain_info(conn_name \\ ""), to: Rpc

  @doc """
  Retrive the current status of the node.

  ## Example

      ForgeSdk.get_node_info()

  """
  @spec get_node_info(String.t()) :: NodeInfo.t() | {:error, term()}
  defdelegate get_node_info(conn_name \\ ""), to: Rpc

  @doc """
  Retrieve the `network info`.

  ## Example

      ForgeSdk.get_net_info()

  """
  @spec get_net_info(String.t()) :: NetInfo.t() | {:error, term()}
  defdelegate get_net_info(conn_name \\ ""), to: Rpc

  @doc """
  Retrieve the current validator info.

  ## Example

      ForgeSdk.get_validators_info()

  """
  @spec get_validators_info(String.t()) :: ValidatorsInfo.t() | {:error, term()}
  defdelegate get_validators_info(conn_name \\ ""), to: Rpc

  @doc """
  Create tx.

  ## Example

      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w1)
      w2 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "bob"), wallet: w2)
      data = Google.Protobuf.Any.new(type_url: "test_asset", value: "hello world")
      itx = ForgeSdk.encode_any!(TransferTx.new(to: w2.address, value: new_unit(100)))
      req = RequestCreateTx.new(itx: itx, from: w1.address, nonce: 2, walllet: w1)
      tx = ForgeSdk.create_tx(req)

  """
  @spec create_tx(RequestCreateTx.t() | Keyword.t(), String.t() | atom()) ::
          Transaction.t() | {:error, term()}
  defdelegate create_tx(request, conn_name \\ ""), to: Rpc

  @doc """
  Forge we support `multisig` for a tx, you can use this to endorse an already signed tx.
  **ExchangeTx, ConsumeAssetTx and some other txs** are using multisig technology.

  ## Example

      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w1)
      w2 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "bob"), wallet: w2)
      data = Google.Protobuf.Any.new(type_url: "test_asset", value: "hello world")
      hash = ForgeSdk.create_asset(ForgeAbi.CreateAssetTx.new(data: asset_data), wallet: w2)
      asset_address = ForgeSdk.get_address(hash)
      sender_info = ForgeAbi.ExchangeInfo.new(value: ForgeSdk.token_to_unit(1))
      receiver_info = ForgeAbi.ExchangeInfo.new(assets: [asset_address])
      itx = ForgeAbi.ExchangeTx.new(to: w2.address, sender: sender_info, receiver: receiver_info)
      tx = ForgeSdk.prepare_exchange(itx, wallet: w1)
      tx1 = ForgeSdk.multisig(tx, w2)
      ForgeSdk.send_tx(tx: tx1)

  """
  @spec multisig(RequestMultisig.t() | Keyword.t(), String.t() | atom()) ::
          Transaction.t() | {:error, term()}
  defdelegate multisig(request, conn_name \\ ""), to: Rpc

  @doc """
  Send tx.

  ## Example

      w1 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "alice"), wallet: w1)
      w2 = ForgeSdk.create_wallet()
      ForgeSdk.declare(ForgeAbi.DeclareTx.new(moniker: "bob"), wallet: w2)
      data = Google.Protobuf.Any.new(type_url: "test_asset", value: "hello world")
      itx = ForgeSdk.encode_any!(TransferTx.new(to: w2.address, value: new_unit(100)))
      req = RequestCreateTx.new(itx: itx, from: w1.address, nonce: 2, walllet: w1, token: t)
      tx = ForgeSdk.create_tx(req)
      hash = ForgeSdk.send_tx(tx: tx)

  """
  @spec send_tx(RequestSendTx.t() | Keyword.t(), String.t() | atom()) ::
          String.t() | {:error, term()}
  defdelegate send_tx(request, conn_name \\ ""), to: Rpc

  @doc """
  Return an already processed `transaction` by its `hash`. If this API returns `nil`, mostly your tx hasn't been.

  ## Example

      hash = ForgeSdk.send_tx(tx: tx)
      ForgeSdk.get_tx(hash: hash)

  """
  @spec get_tx(
          RequestGetTx.t() | [RequestGetTx.t()] | Keyword.t() | [Keyword.t()],
          String.t()
        ) :: TransactionInfo.t() | [TransactionInfo.t()] | {:error, term()}
  defdelegate get_tx(requests, conn_name \\ ""), to: Rpc

  defdelegate get_unconfirmed_txs(request, conn_name \\ ""), to: Rpc

  @doc """
  Get a block by its `height`. All txs included in this block will be returned.

  ## Example

      req = ForgeAbi.RequestGetBlock.new(height: 1000)
      ForgeSdk.get_block(req)

  """
  @spec get_block(
          RequestGetBlock.t() | [RequestGetBlock.t()] | Keyword.t() | [Keyword.t()],
          String.t()
        ) :: BlockInfo.t() | [BlockInfo.t()] | {:error, term()}
  defdelegate get_block(requests, conn_name \\ ""), to: Rpc

  @doc """
  Get a `list` of blocks between a range.

  ## Example

      page_info = ForgeAbi.PageInfo.new
      range_filter = ForgeAbi.RangeFilter.new(from: 1000, to: 1015)
      req = ForgeAbi.RequestGetBlocks.new(empty_excluded: true, height_filter: range_filter,
      paging: page_info)
      ForgeSdk.get_blocks(req)

  """
  @spec get_blocks(RequestGetBlocks.t() | Keyword.t(), String.t() | atom()) ::
          {[BlockInfoSimple.t()], PageInfo.t()} | {:error, term()}
  defdelegate get_blocks(request, conn_name \\ ""), to: Rpc
  defdelegate search(request, conn_name \\ ""), to: Rpc
  defdelegate get_config(request, conn_name \\ ""), to: Rpc

  # wallet related

  @doc """
  This will generate a wallet with default DID type: public key type is `ED25519`, hash type is `sha3(256)`, and DID role type is account.

  ## Example

      ForgeSdk.create_wallet()

  """
  @spec create_wallet :: WalletInfo.t()
  def create_wallet, do: Wallet.create(%Wallet.Type.Forge{})

  @doc """
  You can pass in your own `DID` type in a map once you want to create a wallet with different settings.

  ## Example

      w1 = ForgeSdk.create_wallet()
      ForgeSdk.create_wallet(moniker: "alice", passphrase: "abcd1234")

  """
  @spec create_wallet(RequestCreateWallet.t() | Keyword.t(), String.t() | atom()) ::
          {WalletInfo.t(), String.t()} | {:error, term()}
  defdelegate create_wallet(request, conn_name \\ ""), to: Rpc

  @doc """
  Load a node managed wallet by its `address` and `passphrase` from the keystore.

  ## Example

      {w, t} = ForgeSdk.create_wallet(moniker: "alice", passphrase: "abcd1234")
      req = ForgeAbi.RequestLoadWallet.new(address: w.address, passphrase: "abcd1234")
      ForgeSdk.load_wallet(req)

  """
  @spec load_wallet(RequestLoadWallet.t() | Keyword.t(), String.t() | atom()) ::
          String.t() | {:error, term()}
  defdelegate load_wallet(request, conn_name \\ ""), to: Rpc

  @doc """
  If you know the `type` and the `secret key` of the wallet, you can recover it into the current forge node.
  This is useful when you want to switch your wallet from one node to another.
  This will generate a keystore file.

  ## Example

      {w, t} = ForgeSdk.create_wallet(moniker: "alice", passphrase: "abcd1234")
      request = RequestRecoverWallet.new(data: w.sk, type: w.type, passphrase: "abcd1234")
      ForgeSdk.recover_wallet(req)

  """
  @spec recover_wallet(RequestRecoverWallet.t(), String.t()) ::
          {WalletInfo.t(), String.t()} | {:error, term()}
  defdelegate recover_wallet(request, conn_name \\ ""), to: Rpc

  @doc """
  Display the `wallet addresses` that current forge node hosts.

  ## Example

      ForgeSdk.list_wallet()

  """
  @spec list_wallet(String.t() | atom()) :: String.t() | {:error, term()}
  defdelegate list_wallet(conn_name \\ ""), to: Rpc

  @doc """
  Delete the `keystore` for a given `wallet address`. This is useful when you finished your work on the forge node and you'd remove the footprint for your wallet.

  ## Example

      {w, t} = ForgeSdk.create_wallet(moniker: "alice", passphrase: "abcd1234")
      request = RequestRemoveWallet.new(address: w.address)
      ForgeSdk.remove_wallet(request)

  """
  @spec remove_wallet(RequestRemoveWallet.t() | Keyword.t(), String.t() | atom()) ::
          :ok | {:error, term()}
  defdelegate remove_wallet(request, conn_name \\ ""), to: Rpc
  defdelegate declare_node(request, conn_name \\ ""), to: Rpc

  # state related

  @doc """
  Return the `state` for an account, node, validator or application address.

  ## Example

      req = ForgeAbi.RequestGetAccountState.new(address: "z1QNTPxDUCbh68q6ci6zUmtnT2Cj8nbLw75")
      ForgeSdk.get_account_state(req)

  """
  @spec get_account_state(
          RequestGetAccountState.t() | [RequestGetAccountState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom()
        ) :: AccountState.t() | nil | [AccountState.t()] | {:error, term()}
  defdelegate get_account_state(request, conn_name \\ ""), to: Rpc

  @doc """
  Return the `state` for an asset.

  ## Example

      req = ForgeAbi.RequestGetAssetState.new(address: "zjdjh65vHxvvWfj3xPrDoUDYp1aY6xUCV21b")
      ForgeSdk.get_asset_state(req)

  """
  @spec get_asset_state(
          RequestGetAssetState.t() | [RequestGetAssetState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom()
        ) :: AssetState.t() | [AssetState.t()] | {:error, term()}
  defdelegate get_asset_state(request, conn_name \\ ""), to: Rpc

  @doc """
  Return global state for forge.

  ## Example

      ForgeSdk.get_forge_state()

  """
  @spec get_forge_state(String.t() | atom()) :: ForgeState.t() | {:error, term()}
  defdelegate get_forge_state(conn_name \\ ""), to: Rpc

  @doc """
  Return installed protocol state.

  ## Example

      req = ForgeAbi.RequestGetProtocolState.new(address: "z2E3zCQTx5dPQeimQvJWz3vJvcDv9Ad6YgaPn")
      ForgeSdk.get_protocol_state(req)

  """
  @spec get_protocol_state(
          RequestGetProtocolState.t()
          | [RequestGetProtocolState.t()]
          | Keyword.t()
          | [Keyword.t()],
          String.t()
        ) :: ProtocolState.t() | [ProtocolState.t()] | {:error, term()}
  defdelegate get_protocol_state(request, conn_name \\ ""), to: Rpc
  defdelegate get_stake_state(request, conn_name \\ ""), to: Rpc
  defdelegate get_tether_state(request, conn_name \\ ""), to: Rpc
  defdelegate get_swap_state(request, conn_name \\ ""), to: Rpc
  defdelegate get_delegate_state(request, conn_name \\ ""), to: Rpc

  # filesystem related
  # defdelegate store_file(request, conn_name \\ ""), to: File
  # defdelegate load_file(request, conn_name \\ ""), to: File
  # defdelegate pin_file(request, conn_name \\ ""), to: Rpc

  # subscription related

  @doc """
  Subscribe to a `topic`. You can event set a filter for the event that you'd listen.

  ## Example

      req = ForgeAbi.RequestSubscribe.new(topic: "fg:t:declare")
      ForgeSdk.Rpc.subscribe(req)

  """
  @spec subscribe(RequestSubscribe.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          [ResponseSubscribe.t()] | {:error, term()}
  defdelegate subscribe(request, conn_name \\ "", opts \\ []), to: Rpc

  @doc """
  Terminate the subscription by the topic `id`.

  ## Example

      req = ForgeAbi.RequestSubscribe.new(topic: "fg:t:declare")
      stream_declare = ForgeSdk.Rpc.subscribe(req)
      [topic: topic] = Enum.take(stream_declare, 1)
      req = ForgeAbi.RequestUnsubscribe.new(topic: topic)
      ForgeSdk.Rpc.unsubscribe(req)

  """
  @spec unsubscribe(RequestUnsubscribe.t(), String.t() | atom(), Keyword.t()) ::
          :ok | {:error, term()}
  defdelegate unsubscribe(request, conn_name \\ "", opts \\ []), to: Rpc

  # extended
  # defdelegate get_nonce(address, conn_name \\ "", app_hash \\ ""), to: Rpc

  # display a data structure

  @doc """
  Provide a display friendly result for a data structure.

  ## Examples

      req = ForgeAbi.RequestGetAccountState.new(address: "z1QNTPxDUCbh68q6ci6zUmtnT2Cj8nbLw75")
      account_state = ForgeSdk.get_account_state(req)
      ForgeSdk.display(account_state)

  """
  @spec display(any(), boolean()) :: any()
  defdelegate display(data, expand? \\ false), to: Display

  defdelegate connect(hostname, opts), to: Util
  defdelegate get_conn(name \\ ""), to: Util
  defdelegate get_parsed_config(name \\ ""), to: Util
  defdelegate datetime_to_proto(dt), to: Util
  defdelegate proto_to_datetime(ts), to: Util
  defdelegate update_type_url(forge_state), to: Loader
  defdelegate get_tx_protocols(forge_state, address), to: Loader
  defdelegate get_address(hash), to: Rpc
  defdelegate encode_any(data, type_url \\ nil), to: ForgeAbi
  defdelegate encode_any!(data, type_url \\ nil), to: ForgeAbi
  defdelegate decode_any(data), to: ForgeAbi
  defdelegate decode_any!(data), to: ForgeAbi
  defdelegate token_to_unit(tokens, name \\ ""), to: Util
  defdelegate unit_to_token(units, name \\ ""), to: Util
  defdelegate one_token(name \\ ""), to: Util
  defdelegate verify_sig(tx), to: Util
  defdelegate verify_multi_sig(tx), to: Util

  # stats
  defdelegate get_forge_stats(requests, conn_name \\ ""), to: Rpc
  defdelegate list_transactions(request, conn_name \\ ""), to: Rpc
  defdelegate list_assets(request, conn_name \\ ""), to: Rpc
  defdelegate list_stakes(request, conn_name \\ ""), to: Rpc
  defdelegate list_account(request, conn_name \\ ""), to: Rpc
  defdelegate list_top_accounts(request, conn_name \\ ""), to: Rpc
  defdelegate list_asset_transactions(request, conn_name \\ ""), to: Rpc
  defdelegate list_blocks(request, conn_name \\ ""), to: Rpc
  defdelegate list_tethers(request, conn_name \\ ""), to: Rpc
  defdelegate list_swap(request, conn_name \\ ""), to: Rpc
  defdelegate get_health_status(request, conn_name \\ ""), to: Rpc
end
