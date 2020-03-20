defmodule ForgeSdk.Rpc do
  @moduledoc """
  The very simple version of the RPC
  """

  use ForgeAbi.Unit
  import ForgeSdk.Rpc.Builder, only: [rpc: 2, rpc: 3]
  import ForgeSdk.Tx.Builder, only: [tx: 1, tx: 2]
  require Logger

  @subscription_timeout 900 * 1000

  alias ForgeAbi.{
    # state
    AccountState,
    AssetState,
    DelegateState,
    ForgeState,
    ProtocolState,
    StakeState,
    SwapState,
    SwapStatistics,

    # block
    IndexedBlock,

    # tx
    IndexedTransaction,
    Transaction,
    TransactionInfo,
    UnconfirmedTxs,

    # index state
    IndexedStakeState,
    IndexedAccountState,
    IndexedAssetState,

    # other
    ChainInfo,
    NodeInfo,
    BlockInfo,
    BlockInfoSimple,
    NetInfo,
    ValidatorsInfo,
    WalletInfo,
    PageInfo,

    # chain related
    RequestDeclareNode,
    RequestGetBlock,
    RequestGetBlocks,
    RequestGetConfig,
    RequestGetTx,
    RequestGetUnconfirmedTxs,
    RequestSearch,
    RequestSendTx,

    # state related
    RequestGetAccountState,
    RequestGetAssetState,
    RequestGetDelegateState,
    # RequestGetForgeState,
    RequestGetProtocolState,
    RequestGetStakeState,
    RequestGetSwapState,

    # event related
    RequestSubscribe,
    ResponseSubscribe,
    RequestUnsubscribe,
    ResponseUnsubscribe,

    # stats related
    HealthStatus,
    RequestListAccount,
    RequestListAssets,
    RequestGetForgeStats,
    RequestListStakes,
    RequestListTopAccounts,
    RequestListAssetTransactions,
    RequestListBlocks,
    RequestListTransactions,
    RequestListSwap,
    RequestGetSwapStatistics,
    ForgeStats
  }

  alias ForgeSdk.Wallet.Util, as: WalletUtil
  alias ForgeSdk.Rpc.Protocol.Helper
  alias ForgeAbi.Transaction
  alias Google.Protobuf.Any

  # chain related
  @doc """
  Retrieve Chain information.

    iex> ForgeSdk.get_chain_info()
    %ForgeAbi.ChainInfo{
      address: "DC3ACE418CBD079C564E4D511EE55558B8D67DB3",
      app_hash: "1DC64B35F1E539798E722E87270678F7D0B2EA2E046938F0384F4D4D0D73EA56",
      block_hash: "155E0733D724AC9814261DEB8E039E1F11048C2635A62F4E84B65D77A94BCCF3",
      block_height: 6,
      block_time: %Google.Protobuf.Timestamp{nanos: 0, seconds: 1545964437},
      id: "335edc03d91161caff9267a107a213cbabb954eb",
      moniker: "forge",
      network: "1",
      synced: true,
      version: "0.27.3",
      voting_power: 10
    }
  """
  @spec get_chain_info(String.t() | atom(), Keyword.t()) :: ChainInfo.t() | {:error, term()}
  rpc :get_chain_info, no_params: true do
    res.info
  end

  @spec get_node_info(String.t() | atom(), Keyword.t()) :: NodeInfo.t() | {:error, term()}
  rpc :get_node_info, no_params: true do
    res.info
  end

  @spec multisig(Keyword.t(), String.t()) :: Transaction.t() | {:error, term()}
  def multisig(req, _conn_name \\ "") do
    wallet = req[:wallet]

    case wallet === nil or wallet.sk === "" do
      true -> {:error, :invalid_wallet}
      _ -> WalletUtil.multisig!(wallet, req[:tx], data: req[:data], delegatee: req[:delegatee])
    end
  rescue
    _ -> {:error, :internal}
  end

  @spec send_tx(RequestSendTx.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          String.t() | {:error, term()}
  rpc :send_tx do
    res.hash
  end

  @spec get_tx(
          RequestGetTx.t() | [RequestGetTx.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: TransactionInfo.t() | [TransactionInfo.t()] | {:error, term()}
  rpc :get_tx, request_stream: true do
    res.info
  end

  @spec get_block(
          RequestGetBlock.t() | [RequestGetBlock.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: BlockInfo.t() | [BlockInfo.t()] | {:error, term()}
  rpc :get_block, request_stream: true do
    res.block
  end

  @spec get_blocks(RequestGetBlocks.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          {[BlockInfoSimple.t()], PageInfo.t()} | {:error, term()}
  rpc :get_blocks do
    {res.blocks, res.page}
  end

  @spec search(RequestSearch.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          [Transaction.t()] | {:error, term()}
  rpc :search do
    res.txs
  end

  @spec get_unconfirmed_txs(
          RequestGetUnconfirmedTxs.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {UnconfirmedTxs.t(), PageInfo.t()} | {:error, term()}
  rpc :get_unconfirmed_txs do
    {res.unconfirmed_txs, res.page}
  end

  @spec get_net_info(String.t() | atom(), Keyword.t()) :: NetInfo.t() | {:error, term()}
  rpc :get_net_info, no_params: true do
    res.net_info
  end

  @spec get_validators_info(String.t() | atom(), Keyword.t()) ::
          ValidatorsInfo.t() | {:error, term()}
  rpc :get_validators_info, no_params: true do
    res.validators_info
  end

  @spec get_config(RequestGetConfig.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          String.t() | {:error, term()}
  rpc :get_config do
    res.config
  end

  # wallet related
  @spec create_wallet(Keyword.t(), String.t() | atom()) ::
          WalletInfo.t() | {:error, term()}
  def create_wallet(req, _conn_name \\ "") do
    wallet =
      case req[:type] do
        nil -> WalletUtil.create(ForgeAbi.WalletType.new())
        v -> WalletUtil.create(v)
      end

    ForgeSdk.declare(apply(ForgeAbi.DeclareTx, :new, [%{moniker: req[:moniker] || ""}]),
      wallet: wallet
    )

    wallet
  rescue
    _ -> {:error, :internal}
  end

  @doc """

  Supported optionas:
    - type: ForgeAbi.WalletType
    - moniker: The moniker for the wallet to create.
    - issuer: The address of the issuer.
  """
  @spec prepare_create_wallet(Keyword.t(), String.t() | atom()) ::
          {WalletInfo.t(), Transaction.t()} | {:error, term()}
  def prepare_create_wallet(req, _conn_name \\ "") do
    wallet =
      case req[:type] do
        nil -> WalletUtil.create(ForgeAbi.WalletType.new())
        v -> WalletUtil.create(v)
      end

    moniker = req[:moniker] || ""
    issuer = req[:issuer]
    itx = apply(ForgeAbi.DeclareTx, :new, [%{moniker: moniker, issuer: issuer}])
    tx = ForgeSdk.prepare_declare(itx, wallet: wallet)
    {wallet, tx}
  end

  @spec finalize_create_wallet(Transaction.t(), Keyword.t()) :: {:error, any()} | Transaction.t()
  def finalize_create_wallet(tx, opts), do: ForgeSdk.finalize_declare(tx, opts)

  @spec declare_node(RequestDeclareNode.t(), String.t() | atom(), Keyword.t()) ::
          WalletInfo.t() | {:error, term()}
  rpc :declare_node do
    res.wallet
  end

  @spec prepare_declare_node(RequestDeclareNode.t(), String.t() | atom()) ::
          {WalletInfo.t(), Transaction.t()} | {:error, term()}
  rpc :prepare_declare_node, service: :declare_node do
    {res.wallet, res.tx}
  end

  @spec finalize_declare_node(Transaction.t(), Keyword.t()) :: {:error, any()} | Transaction.t()
  def finalize_declare_node(tx, opts), do: ForgeSdk.finalize_declare(tx, opts)

  # account related
  @spec get_account_state(
          RequestGetAccountState.t() | [RequestGetAccountState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: AccountState.t() | nil | [AccountState.t()] | {:error, term()}
  rpc :get_account_state, request_stream: true do
    res.state
  end

  @spec get_asset_state(
          RequestGetAssetState.t() | [RequestGetAssetState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: AssetState.t() | [AssetState.t()] | {:error, term()}
  rpc :get_asset_state, request_stream: true do
    res.state
  end

  @spec get_protocol_state(
          RequestGetProtocolState.t()
          | [RequestGetProtocolState.t()]
          | Keyword.t()
          | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: ProtocolState.t() | [ProtocolState.t()] | {:error, term()}
  rpc :get_protocol_state, request_stream: true do
    res.state
  end

  @spec get_stake_state(
          RequestGetStakeState.t() | [RequestGetStakeState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: StakeState.t() | [StakeState.t()] | {:error, term()}
  rpc :get_stake_state, request_stream: true do
    res.state
  end

  @spec get_swap_state(
          RequestGetSwapState.t() | [RequestGetSwapState.t()] | Keyword.t() | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: SwapState.t() | [SwapState.t()] | {:error, term()}
  rpc :get_swap_state, request_stream: true do
    res.state
  end

  @spec get_forge_state(String.t() | atom(), Keyword.t()) :: ForgeState.t() | {:error, term()}
  rpc :get_forge_state, no_params: true do
    res.state
  end

  @spec get_delegate_state(
          RequestGetDelegateState.t()
          | [RequestGetDelegateState.t()]
          | Keyword.t()
          | [Keyword.t()],
          String.t() | atom(),
          Keyword.t()
        ) :: DelegateState.t() | [DelegateState.t()] | {:error, term()}
  rpc :get_delegate_state, request_stream: true do
    res.state
  end

  # event rpc
  @doc """
  Subscribe to a specific topic. User must first create their own channel for this.

    iex> conn = ForgeSdk.get_conn()
    iex> req = RequestSubscribe.new()
    iex> stream = ForgeSdk.subscribe(req, conn)
    iex> Enum.take(stream, 1) # this will return the topic id of the subscription
  """
  @spec subscribe(RequestSubscribe.t() | Keyword.t(), String.t() | atom(), Keyword.t()) ::
          [ResponseSubscribe.t()] | {:error, term()}
  rpc :subscribe, opts: [timeout: @subscription_timeout, stream_mode: true] do
    res.value
  end

  @spec unsubscribe(RequestUnsubscribe.t(), String.t() | atom(), Keyword.t()) ::
          ResponseUnsubscribe.t() | {:error, term()}
  rpc :unsubscribe do
    res.code
  end

  # tx helpers

  # account related
  tx :account_migrate
  tx :declare
  tx :prepare_declare, multisig: true

  @spec finalize_declare(Transaction.t(), Keyword.t()) ::
          {:error, any()} | Transaction.t()
  def finalize_declare(tx, opts) do
    wallet = opts[:wallet] || raise "wallet must be provided"
    delegatee = opts[:delegatee] || ""
    data = opts[:data]

    ForgeSdk.multisig(tx: tx, wallet: wallet, data: data, delegatee: delegatee)
  end

  tx :delegate, preprocessor: [Helper, :delegate]
  tx :revoke_delegate, preprocessor: [Helper, :revoke_delegate]

  # asset related
  tx :acquire_asset, preprocessor: [Helper, :acquire_asset]
  tx :create_asset, preprocessor: [Helper, :create_asset]
  tx :update_asset

  @doc """
  Allow user to stake for a node easily
  """
  @spec create_asset_factory(String.t(), map(), Keyword.t()) :: String.t()
  def create_asset_factory(moniker, factory, opts) do
    data = ForgeSdk.encode_any!(apply(ForgeAbi.AssetFactory, :new, [factory]))

    itx =
      apply(ForgeAbi.CreateAssetTx, :new, [
        %{
          moniker: moniker,
          ttl: opts[:ttl] || 0,
          transferrable: opts[:transferrable] || false,
          readonly: opts[:readonly] || false,
          parent: opts[:parent] || "",
          data: data
        }
      ])

    create_asset(Helper.create_asset(itx, opts), opts)
  end

  tx :prepare_consume_asset, multisig: true

  @spec finalize_consume_asset(Transaction.t(), Keyword.t()) ::
          {:error, any()} | Transaction.t()
  def finalize_consume_asset(tx, opts) do
    asset_address = opts[:asset_address] || raise "asset_address must be provided"
    wallet = opts[:wallet] || raise "wallet must be provided"
    delegatee = opts[:delegatee] || ""

    data = Any.new(type_url: "fg:x:address", value: asset_address)
    ForgeSdk.multisig(tx: tx, wallet: wallet, data: data, delegatee: delegatee)
  end

  # governance
  # activate/deactivate/deploy are deprecated
  # tx :activate_protocol
  # tx :deactivate_protocol
  # tx :deploy_protocol # need to auto generate the address by ForgeSdk.Util.to_tx_address(itx)
  tx :update_consensus_params
  tx :update_validator
  tx :upgrade_node

  # misc
  tx :poke

  @doc """
  Allow user to checkin to get reward
  """
  @spec checkin(Keyword.t()) :: String.t() | {:error, term()}
  def checkin(opts) do
    date = Date.to_string(Date.utc_today())

    address =
      get_in(
        ForgeSdk.get_parsed_config(opts[:conn] || ""),
        ~w(forge prime token_holder address)
      )

    itx = apply(ForgeAbi.PokeTx, :new, [[date: date, address: address]])

    poke(itx, [{:nonce, 0} | opts])
  end

  tx :refuel

  @doc """
  Allow user to refuel
  """
  @spec refuel(Keyword.t()) :: String.t() | {:error, term()}
  def refuel(opts) do
    date = Date.to_string(Date.utc_today())
    itx = apply(ForgeAbi.RefuelTx, :new, [[date: date]])
    refuel(itx, [{:nonce, 0} | opts])
  end

  # atomic swap
  tx :retrieve_swap
  tx :revoke_swap
  tx :setup_swap

  # token swap
  tx :approve_withdraw
  tx :deposit_token

  tx :prepare_revoke_withdraw, multisig: true

  @spec finalize_revoke_withdraw(Transaction.t(), Keyword.t()) ::
          {:error, any()} | Transaction.t()
  def finalize_revoke_withdraw(tx, opts) do
    wallet = opts[:wallet] || raise "wallet must be provided"
    delegatee = opts[:delegatee]
    ForgeSdk.multisig(tx: tx, wallet: wallet, delegatee: delegatee)
  end

  tx :prepare_withdraw_token, multisig: true

  @spec finalize_withdraw_token(Transaction.t(), Keyword.t()) ::
          {:error, any()} | Transaction.t()
  def finalize_withdraw_token(tx, opts) do
    wallet = opts[:wallet] || raise "wallet must be provided"
    delegatee = opts[:delegatee]
    ForgeSdk.multisig(tx: tx, wallet: wallet, delegatee: delegatee)
  end

  # trade
  tx :prepare_exchange, multisig: true

  @spec finalize_exchange(Transaction.t(), Keyword.t()) :: {:error, any()} | Transaction.t()
  def finalize_exchange(tx, opts) do
    wallet = opts[:wallet] || raise "wallet must be provided"
    delegatee = opts[:delegatee]
    ForgeSdk.multisig(tx: tx, wallet: wallet, delegatee: delegatee)
  end

  tx :transfer

  defmodule Protocol.Helper do
    def create_asset(itx, _opt) do
      case itx.address === "" do
        true -> %{itx | address: ForgeSdk.Util.to_asset_address(itx)}
        false -> itx
      end
    end

    def acquire_asset(itx, _opt) do
      state = ForgeSdk.get_asset_state(address: itx.to)

      specs = attach_address(itx.specs, state)

      case Enum.any?(specs, &is_nil/1) do
        true -> %{itx | specs: []}
        _ -> %{itx | specs: specs}
      end
    end

    def delegate(itx, opt) do
      wallet = Keyword.get(opt, :wallet)

      case itx.address === "" do
        true -> %{itx | address: ForgeSdk.Util.to_delegate_address(wallet.address, itx.to)}
        false -> itx
      end
    end

    def revoke_delegate(itx, opt) do
      wallet = Keyword.get(opt, :wallet)

      case itx.address === "" do
        true -> %{itx | address: ForgeSdk.Util.to_delegate_address(wallet.address, itx.to)}
        false -> itx
      end
    end

    def attach_address(specs, state) when is_list(specs) do
      specs
      |> Enum.reduce_while([], fn spec, acc ->
        spec = attach_address(spec, state)

        case spec do
          nil -> {:halt, []}
          _ -> {:cont, [spec | acc]}
        end
      end)
      |> Enum.reverse()
    end

    def attach_address(spec, state) do
      case spec.address === "" do
        true ->
          case gen_create_asset_itx(spec, state) do
            nil -> nil
            tmp_itx -> %{spec | address: ForgeSdk.Util.to_asset_address(tmp_itx)}
          end

        false ->
          spec
      end
    end

    def gen_create_asset_itx(spec, state) do
      factory_state = ForgeAbi.decode_any!(state.data)
      mod = Module.concat("ForgeAbi", factory_state.asset_name)

      case Code.ensure_loaded?(mod) do
        false ->
          nil

        true ->
          args = Jason.decode!(spec.data)

          data =
            factory_state.template
            |> :bbmustache.render(args, key_type: :binary)
            |> Jason.decode!(keys: :atoms!)

          itx_data = ForgeAbi.encode_any!(mod.new(data))

          params =
            factory_state.attributes
            |> Map.from_struct()
            |> Map.merge(%{data: itx_data, parent: state.address, readonly: true})

          apply(ForgeAbi.CreateAssetTx, :new, [params])
      end
    rescue
      _ -> nil
    end
  end

  # account related

  @doc """
  Retrieve the nonce for an address, usually used for filling the nonce field of a Tx.
  """
  @spec get_nonce(String.t(), String.t() | atom(), String.t()) :: non_neg_integer()
  def get_nonce(address, name \\ "", app_hash \\ "") do
    req = RequestGetAccountState.new(address: address, key: "nonce", app_hash: app_hash)
    state = get_account_state(req, name)
    Map.get(state || %{}, :nonce, 1)
  rescue
    e ->
      Logger.warn("#{inspect(e)}")
      1
  end

  # stats related
  @spec get_forge_stats(
          RequestGetForgeStats.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: ForgeStats.t() | {:error, term()}
  rpc :get_forge_stats do
    res.forge_stats
  end

  @spec list_transactions(
          RequestListTransactions.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedTransaction.t()], PageInfo.t()} | {:error, term()}
  rpc :list_transactions do
    {res.transactions, res.page}
  end

  @spec list_assets(
          RequestListAssets.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedAssetState.t()], PageInfo.t()} | {:error, term()}
  rpc :list_assets do
    {res.assets, res.page}
  end

  @spec list_stakes(
          RequestListStakes.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedStakeState.t()], PageInfo.t()} | {:error, term()}
  rpc :list_stakes do
    {res.stakes, res.page}
  end

  @spec list_account(
          RequestListAccount.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: IndexedAccountState.t() | nil | {:error, term()}
  rpc :list_account do
    res.account
  end

  @spec list_top_accounts(
          RequestListTopAccounts.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedAccountState.t()], PageInfo.t()} | {:error, term()}
  rpc :list_top_accounts do
    {res.accounts, res.page}
  end

  @spec list_asset_transactions(
          RequestListAssetTransactions.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedTransaction.t()], PageInfo.t()} | {:error, term()}
  rpc :list_asset_transactions do
    {res.transactions, res.page}
  end

  @spec list_blocks(
          RequestListBlocks.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[IndexedBlock.t()], PageInfo.t()} | {:error, term()}
  rpc :list_blocks do
    {res.blocks, res.page}
  end

  @spec list_swap(
          RequestListSwap.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: {[SwapState.t()], PageInfo.t()} | {:error, term()}
  rpc :list_swap do
    {res.swap, res.page}
  end

  @spec get_swap_statistics(
          RequestGetSwapStatistics.t() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: SwapStatistics | {:error, term()}
  rpc :get_swap_statistics do
    res.statistics
  end

  @spec get_health_status(
          map() | Keyword.t(),
          String.t() | atom(),
          Keyword.t()
        ) :: HealthStatus.t() | {:error, term()}
  rpc :get_health_status do
    res.health_status
  end

  # other helpers
  @spec get_address(String.t()) :: String.t() | nil
  def get_address(hash) do
    tx =
      case get_tx(hash: hash) do
        {:error, _} -> nil
        info -> info.tx
      end

    case ForgeSdk.display(tx) do
      nil -> nil
      v -> get_in(v, [:itx, :address])
    end
  end
end
