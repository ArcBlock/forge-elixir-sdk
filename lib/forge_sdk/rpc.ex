defmodule ForgeSdk.Rpc do
  @moduledoc """
  The very simple version of the RPC
  """

  use ForgeAbi.Arc
  import ForgeSdk.Rpc.Builder, only: [rpc: 2, rpc: 3]
  import ForgeSdk.Rpc.Tx.Builder, only: [tx: 1, tx: 2]
  require Logger

  @subscription_timeout 900 * 1000

  alias ForgeAbi.{
    # state
    AccountState,
    AssetState,
    ForgeState,
    StakeState,

    # tx
    Transaction,
    UnconfirmedTxs,

    # other
    ChainInfo,
    BlockInfo,
    NetInfo,
    ValidatorsInfo,
    WalletInfo,

    # chain related

    RequestCreateTx,
    RequestGetBlock,
    RequestGetBlocks,
    RequestGetTx,
    RequestGetUnconfirmedTxs,
    RequestMultisig,
    RequestSearch,
    RequestSendTx,

    # wallet related
    RequestCreateWallet,
    RequestLoadWallet,
    RequestRecoverWallet,
    RequestRemoveWallet,

    # state related
    RequestGetAccountState,
    RequestGetAssetState,
    # RequestGetForgeState,
    RequestGetStakeState,

    # filesystem related
    RequestStoreFile,
    RequestLoadFile,
    RequestPinFile,

    # event related
    RequestSubscribe,
    ResponseSubscribe,
    RequestUnsubscribe,
    ResponseUnsubscribe,

    # statistics related
    RequestGetForgeStatistics,
    ForgeStatistics
  }

  alias GRPC.Channel

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
  @spec get_chain_info(Channel.t() | nil, Keyword.t()) :: ChainInfo.t() | {:error, term()}
  rpc :get_chain_info, no_params: true do
    res.info
  end

  @doc """
  Create a transaction

    iex> {wallet, _token} = ForgeSdk.create_wallet(RequestCreateWallet.new(passphrase: "abcd1234"))
    {%ForgeAbi.WalletInfo{
      address: "f8a5b784376a3ca9119eded5f53edec75a7575975",
      pk: <<233, 139, 217, 205, 219, 102, 84, 238, 185, 77, 11, 69, 127, 85, 205,
        32, 225, 110, 43, 37, 21, 184, 184, 86, 69, 238, 50, 142, 212, 216, 237,
        99>>,
      sk: <<111, 149, 26, 101, 189, 95, 253, 194, 136, 143, 44, 231, 32, 88, 165,
        120, 163, 50, 11, 199, 150, 29, 162, 241, 219, 176, 172, 135, 137, 20, 16,
        222, 233, 139, 217, 205, 219, 102, 84, 238, 185, 77, 11, 69, 127, 85,
        ...>>,
      type: %ForgeAbi.WalletType{address: 0, hash: 0, pk: 0}
    }, ""}
    iex>
  """
  @spec create_tx(RequestCreateTx.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          Transaction.t() | {:error, term()}
  rpc :create_tx do
    res.tx
  end

  @spec multisig(RequestMultisig.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          Transaction.t() | {:error, term()}
  rpc :multisig do
    res.tx
  end

  @spec send_tx(RequestSendTx.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          String.t() | {:error, term()}
  rpc :send_tx do
    res.hash
  end

  @spec get_tx(
          RequestGetTx.t() | [RequestGetTx.t()] | Keyword.t() | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: Transaction.t() | [Transaction.t()] | {:error, term()}
  rpc :get_tx, request_stream: true do
    res.info
  end

  @spec get_block(
          RequestGetBlock.t() | [RequestGetBlock.t()] | Keyword.t() | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: BlockInfo.t() | [BlockInfo.t()] | {:error, term()}
  rpc :get_block, request_stream: true do
    res.block
  end

  @spec get_blocks(RequestGetBlocks.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          [BlockInfo.t()] | {:error, term()}
  rpc :get_blocks do
    res.blocks
  end

  @spec search(RequestSearch.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          [Transaction.t()] | {:error, term()}
  rpc :search do
    res.txs
  end

  @spec get_unconfirmed_txs(
          RequestGetUnconfirmedTxs.t() | Keyword.t(),
          Channel.t() | nil,
          Keyword.t()
        ) :: UnconfirmedTxs.t() | {:error, term()}
  rpc :get_unconfirmed_txs do
    res.unconfirmed_txs
  end

  @spec get_net_info(Channel.t() | nil, Keyword.t()) :: NetInfo.t() | {:error, term()}
  rpc :get_net_info, no_params: true do
    res.net_info
  end

  @spec get_validators_info(Channel.t() | nil, Keyword.t()) ::
          ValidatorsInfo.t() | {:error, term()}
  rpc :get_validators_info, no_params: true do
    res.validators_info
  end

  @spec get_config(Channel.t() | nil, Keyword.t()) :: String.t() | {:error, term()}
  rpc :get_config, no_params: true do
    res.config
  end

  # wallet
  @spec create_wallet(RequestCreateWallet.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          {WalletInfo.t(), String.t()} | {:error, term()}
  rpc :create_wallet do
    {res.wallet, res.token}
  end

  @spec load_wallet(RequestLoadWallet.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          String.t() | {:error, term()}
  rpc :load_wallet do
    {res.wallet, res.token}
  end

  @spec recover_wallet(RequestRecoverWallet.t(), Channel.t() | nil, Keyword.t()) ::
          {WalletInfo.t(), String.t()} | {:error, term()}
  rpc :recover_wallet do
    {res.wallet, res.token}
  end

  @spec list_wallet(Channel.t() | nil, Keyword.t()) :: String.t() | {:error, term()}
  rpc :list_wallet, response_stream: true, no_params: true do
    res.address
  end

  @spec remove_wallet(RequestRemoveWallet.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          :ok | {:error, term()}
  rpc :remove_wallet do
    # just to disable compiler warning
    _res = res
    :ok
  end

  @spec declare_node(Channel.t() | nil, Keyword.t()) :: WalletInfo.t() | {:error, term()}
  rpc :declare_node, no_params: true do
    res.wallet
  end

  # account related
  @spec get_account_state(
          RequestGetAccountState.t() | [RequestGetAccountState.t()] | Keyword.t() | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: AccountState.t() | nil | [AccountState.t()] | {:error, term()}
  rpc :get_account_state, request_stream: true do
    res.state
  end

  @spec get_asset_state(
          RequestGetAssetState.t() | [RequestGetAssetState.t()] | Keyword.t() | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: AssetState.t() | [AssetState.t()] | {:error, term()}
  rpc :get_asset_state, request_stream: true do
    res.state
  end

  @spec get_stake_state(
          RequestGetStakeState.t() | [RequestGetStakeState.t()] | Keyword.t() | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: StakeState.t() | [StakeState.t()] | {:error, term()}
  rpc :get_stake_state, request_stream: true do
    res.state
  end

  @spec get_forge_state(Channel.t() | nil, Keyword.t()) :: ForgeState.t() | {:error, term()}
  rpc :get_forge_state, no_params: true do
    res.state
  end

  # file system related
  @spec store_file(
          Enumerable.t()
          | RequestStoreFile.t()
          | [RequestStoreFile.t()]
          | Keyword.t()
          | [Keyword.t()],
          Channel.t() | nil,
          Keyword.t()
        ) :: String.t() | {:error, term()}
  rpc :store_file, request_stream: true do
    res.hash
  end

  @spec load_file(RequestLoadFile.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          [binary()] | [error: term()] | {:error, term()}
  rpc :load_file, response_stream: true do
    res.chunk
  end

  @spec pin_file(RequestPinFile.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          :ok | {:error, term()}
  rpc :pin_file do
    ForgeAbi.StatusCode.key(res.code)
  end

  # event rpc
  @doc """
  Subscribe to a specific topic. User must first create their own channel for this.

    iex> chan = ForgeSdk.get_chan()
    iex> req = RequestSubscribe.new()
    iex> stream = ForgeSdk.subscribe(req, chan)
    iex> Enum.take(stream, 1) # this will return the topic id of the subscription
  """
  @spec subscribe(RequestSubscribe.t() | Keyword.t(), Channel.t() | nil, Keyword.t()) ::
          [ResponseSubscribe.t()] | {:error, term()}
  rpc :subscribe, opts: [timeout: @subscription_timeout, stream_mode: true] do
    res.value
  end

  @spec unsubscribe(RequestUnsubscribe.t(), Channel.t() | nil, Keyword.t()) ::
          ResponseUnsubscribe.t() | {:error, term()}
  rpc :unsubscribe do
    res.code
  end

  tx :account_migrate
  tx :create_asset
  tx :consensus_upgrade
  tx :declare
  tx :declare_file
  tx :exchange, multisig: true
  tx :stake
  tx :sys_upgrade
  tx :transfer
  tx :update_asset
  tx :upgrade_task

  # account related

  @doc """
  Retrieve the nonce for an address, usually used for filling the nonce field of a Tx.
  """
  @spec get_nonce(String.t(), Channel.t() | nil, String.t()) :: non_neg_integer()
  def get_nonce(address, chan \\ nil, app_hash \\ "") do
    req = RequestGetAccountState.new(address: address, key: "nonce", app_hash: app_hash)
    state = get_account_state(req, chan)
    Map.get(state || %{}, :nonce, 1)
  rescue
    e ->
      Logger.warn("#{inspect(e)}")
      1
  end

  # stake related

  @doc """
  Allow user to stake for a node easily
  """
  @spec stake_for_node(String.t(), integer(), Keyword.t()) :: String.t()
  def stake_for_node(address, amount, opts) do
    wallet = opts[:wallet]
    message = opts[:message] || ""
    data = ForgeAbi.encode_any!(:stake_for_node, ForgeAbi.StakeForNode.new())

    itx =
      ForgeAbi.StakeTx.new(
        to: address,
        from: wallet.address,
        value: bigsint(amount * ForgeAbi.one_token()),
        data: data,
        message: message
      )

    stake(itx, opts)
  end

  # statistics related
  @spec get_forge_statistics(
          RequestGetForgeStatistics.t() | Keyword.t(),
          Channel.t() | nil,
          Keyword.t()
        ) :: ForgeStatistics.t() | {:error, term()}
  rpc :get_forge_statistics do
    res.forge_statistics
  end
end
