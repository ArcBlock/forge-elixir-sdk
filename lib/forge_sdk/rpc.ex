defmodule ForgeSdk.Rpc do
  @moduledoc """
  The very simple version of the RPC
  """

  use ForgeAbi.Unit
  import ForgeSdk.Rpc.Builder, only: [rpc: 2, rpc: 3]
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
    ForgeStats
  }

  alias ForgeSdk.Wallet.Util, as: WalletUtil

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

  def account_migrate(itx, opts),
    do: apply(CoreTx.AccountMigrate.Rpc, :account_migrate, [itx, opts])

  def acquire_asset(itx, opts), do: apply(CoreTx.AcquireAsset.Rpc, :acquire_asset, [itx, opts])
  def create_asset(itx, opts), do: apply(CoreTx.CreateAsset.Rpc, :create_asset, [itx, opts])

  def create_asset_factory(moniker, factory, opts),
    do: apply(CoreTx.CreateAsset.Rpc, :create_asset_factory, [moniker, factory, opts])

  def prepare_consume_asset(itx, opts),
    do: apply(CoreTx.ConsumeAsset.Rpc, :prepare_consume_asset, [itx, opts])

  def finalize_consume_asset(tx, opts),
    do: apply(CoreTx.ConsumeAsset.Rpc, :finalize_consume_asset, [tx, opts])

  def declare(itx, opts), do: apply(CoreTx.Declare.Rpc, :declare, [itx, opts])

  def prepare_declare(itx, opts),
    do: apply(CoreTx.Declare.Rpc, :prepare_declare, [itx, opts])

  def finalize_declare(tx, opts),
    do: apply(CoreTx.Declare.Rpc, :finalize_declare, [tx, opts])

  # def declare_file(itx, opts), do: apply(CoreTx.DeclareFile.Rpc, :declare_file, [itx, opts])

  def deploy_protocol(itx, opts),
    do: apply(CoreTx.DeployProtocol.Rpc, :deploy_protocol, [itx, opts])

  def prepare_exchange(itx, opts), do: apply(CoreTx.Exchange.Rpc, :prepare_exchange, [itx, opts])

  def finalize_exchange(tx, opts),
    do: apply(CoreTx.Exchange.Rpc, :finalize_exchange, [tx, opts])

  def poke(itx, opts), do: apply(CoreTx.Poke.Rpc, :poke, [itx, opts])
  def checkin(opts), do: apply(CoreTx.Poke.Rpc, :checkin, [opts])
  def stake(itx, opts), do: apply(CoreTx.Stake.Rpc, :stake, [itx, opts])

  def stake_for_node(address, value, opts),
    do: apply(CoreTx.Stake.Rpc, :stake_for_node, [address, value, opts])

  def transfer(itx, opts), do: apply(CoreTx.Transfer.Rpc, :transfer, [itx, opts])
  def update_asset(itx, opts), do: apply(CoreTx.UpdateAsset.Rpc, :update_asset, [itx, opts])
  def upgrade_node(itx, opts), do: apply(CoreTx.UpgradeNode.Rpc, :upgrade_node, [itx, opts])

  def refuel(opts), do: apply(CoreTx.Refuel.Rpc, :refuel, [opts])
  def refuel(itx, opts), do: apply(CoreTx.Refuel.Rpc, :refuel, [itx, opts])

  def update_validator(itx, opts),
    do: apply(CoreTx.UpdateValidator.Rpc, :update_validator, [itx, opts])

  def setup_swap(itx, opts), do: apply(CoreTx.SetupSwap.Rpc, :setup_swap, [itx, opts])

  def retrieve_swap(itx, opts), do: apply(CoreTx.RetrieveSwap.Rpc, :retrieve_swap, [itx, opts])

  def revoke_swap(itx, opts), do: apply(CoreTx.RevokeSwap.Rpc, :revoke_swap, [itx, opts])

  def delegate(itx, opts), do: apply(CoreTx.Delegate.Rpc, :delegate, [itx, opts])

  def revoke_delegate(itx, opts),
    do: apply(CoreTx.RevokeDelegate.Rpc, :revoke_delegate, [itx, opts])

  def deposit_token(itx, opts), do: apply(CoreTx.DepositToken.Rpc, :deposit_token, [itx, opts])

  def prepare_withdraw_token(itx, opts),
    do: apply(CoreTx.WithdrawToken.Rpc, :prepare_withdraw_token, [itx, opts])

  def finalize_withdraw_token(itx, opts),
    do: apply(CoreTx.WithdrawToken.Rpc, :finalize_withdraw_token, [itx, opts])

  def approve_withdraw(itx, opts),
    do: apply(CoreTx.ApproveWithdraw.Rpc, :approve_withdraw, [itx, opts])

  def revoke_withdraw(itx, opts),
    do: apply(CoreTx.RevokeWithdraw.Rpc, :revoke_withdraw, [itx, opts])

  def activate_protocol(itx, opts),
    do: apply(CoreTx.ActivateProtocol.Rpc, :activate_protocol, [itx, opts])

  def deactivate_protocol(itx, opts),
    do: apply(CoreTx.DeactivateProtocol.Rpc, :deactivate_protocol, [itx, opts])

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
