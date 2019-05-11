defmodule ForgeSdk.Util do
  @moduledoc """
  Get configuration, server setup, etc.
  """

  use ForgeAbi.Unit

  alias ForgeSdk.Configuration
  alias Configuration.{Cache, Forge, ForgeApp, Ipfs, Tendermint}

  alias ForgeSdk.Wallet.Util, as: WalletUtil

  alias Google.Protobuf.Timestamp

  @config_priorities [:env, :home, :priv]

  @doc """
  Initialize the ForgeSdk.

  Setting up basic config and return child spec for:

    - ABI server
    - RPC client conn

  For a forge app build with Elixir sdk, application shall put these servers
  into their supervision tree.

      filename = "/path/to/forge.toml"
      servers = ForgeSdk.init(:app_name, app_hash, filename)
      children = servers ++ other_children
      Supervisor.start_link(children, opts)
  """
  @spec init(atom(), String.t(), String.t() | nil) :: [module() | {module(), term()}]
  def init(otp_app, app_hash \\ "", filename \\ nil)

  def init(otp_app, app_hash, nil), do: init(otp_app, app_hash, find_config_file!())

  def init(otp_app, app_hash, filename) do
    Application.put_env(:forge_sdk, :otp_app, otp_app)
    Application.put_env(:forge_sdk, :forge_app_hash, app_hash)

    filename
    |> load_config_file!()
    |> get_servers()
  end

  @doc """
  Get the gRPC connection channel.
  """
  @spec get_chan() :: GRPC.Channel.t() | {:error, any}
  def get_chan do
    case Process.whereis(ForgeSdk.Rpc.Conn) do
      nil ->
        config = ForgeSdk.get_env(:forge_config)

        addr =
          case config["sock_grpc"] do
            "unix://" <> v -> v
            "tcp://" <> v -> v
            v -> v
          end

        GRPC.Stub.connect(addr)

      _pid ->
        ForgeSdk.Rpc.Conn.get_chan()
    end
  end

  @spec parse(atom(), String.t() | map()) :: map()
  def parse(type, file \\ "")

  def parse(type, ""), do: parse(type, find_config_file!())
  def parse(type, file) when is_binary(file), do: parse(type, load_config_file!(file))

  def parse(:forge, content), do: Configuration.parse(%Forge{}, content)
  def parse(:forge_app, content), do: Configuration.parse(%ForgeApp{}, content["app"])
  def parse(:tendermint, content), do: Configuration.parse(%Tendermint{}, content["tendermint"])
  def parse(:ipfs, content), do: Configuration.parse(%Ipfs{}, content["ipfs"])
  def parse(:cache, content), do: Configuration.parse(%Cache{}, content["cache"])

  @doc """
  Find the first configuration file in the following locations:

    - system env `FORGE_CONFIG`
    - `~/.forge/forge.toml`
    - `forge-elixir-sdk/priv/forge[_test].toml`
  """
  @spec find_config_file! :: String.t()
  def find_config_file! do
    @config_priorities
    |> Stream.map(&to_file/1)
    |> Stream.filter(&File.exists?/1)
    |> Enum.at(0)
    |> case do
      nil -> exit("Cannot find configuration files in env `FORGE_CONFIG` or home folder.")
      v -> v
    end
  end

  @doc """
  Load the configuration file and merge it with default configuration `forge_default.toml`.
  """
  @spec load_config_file!(String.t() | nil) :: map()
  def load_config_file!(nil) do
    find_config_file!()
    |> load_config_file!()
  end

  def load_config_file!(filename) do
    default_config = "forge_default.toml" |> get_priv_file() |> Toml.decode_file!()
    content = File.read!(filename)
    ForgeSdk.put_env(:toml, content)
    config = Toml.decode!(content)
    DeepMerge.deep_merge(default_config, config)
  end

  @spec gen_config(map()) :: String.t()
  def gen_config(params) do
    toml = ForgeSdk.get_env(:toml)

    case String.contains?(toml, "### begin validators") do
      true ->
        content = "forge_release.toml.eex" |> get_priv_file() |> File.read!()
        params = Keyword.new(params, fn {k, v} -> {:"#{k}", v} end)
        validators = EEx.eval_string(content, params)
        String.replace(toml, ~r/### begin validators.*?### end validators/s, validators)

      false ->
        toml
    end
  end

  @doc """
  Convert datetime or iso8601 datetime string to google protobuf timestamp.
  """
  @spec to_proto_ts(String.t() | DateTime.t()) :: Timestamp.t()
  def to_proto_ts(s) when is_binary(s) do
    {:ok, dt, _} = DateTime.from_iso8601(s)
    to_proto_ts(dt)
  rescue
    _ -> to_proto_ts(DateTime.utc_now())
  end

  def to_proto_ts(dt) do
    Timestamp.new(seconds: DateTime.to_unix(dt))
  end

  @spec to_tether_address(String.t()) :: String.t()
  def to_tether_address(hash) do
    <<pk_hash::binary-size(40), _::binary-size(24)>> = hash
    AbtDid.pkhash_to_did(:tether, pk_hash, form: :short)
  end

  @doc """
  Generate address for asset. Use owner's address + owner's nonce when creating this asset.
  """
  @spec to_asset_address(String.t(), map()) :: String.t()
  def to_asset_address("", itx) do
    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, itx.__struct__.encode(itx))
    did_type = %AbtDid.Type{hash_type: :sha3, key_type: :ed25519, role_type: :asset}
    WalletUtil.to_address(hash, did_type)
  end

  def to_asset_address(address, itx) do
    # TODO: in future we shall just use itx to generate asset address. Thus one cannot generate duplicate asset with different wallet.
    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, itx.__struct__.encode(itx))
    data = address <> hash
    did_type = address |> AbtDid.get_did_type() |> Map.put(:role_type, :asset)
    WalletUtil.to_address(data, did_type)
  end

  @doc """
  Generate address for tx.
  """
  @spec to_tx_address(map()) :: String.t()
  def to_tx_address(itx) do
    data = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, itx.__struct__.encode(itx))
    did_type = %AbtDid.Type{role_type: :tx, key_type: :ed25519, hash_type: :sha3}
    WalletUtil.to_address(data, did_type)
  end

  @doc """
  Generate stake address. Use sender's address + receiver's address as pseudo public key.
  Use `ed25519` as pseudo key type. Use sha3 and base58 by default.
  """
  @spec to_stake_address(String.t(), String.t()) :: String.t()
  def to_stake_address(addr1, addr2) do
    data =
      case addr1 < addr2 do
        true -> addr1 <> addr2
        _ -> addr2 <> addr1
      end

    # complex address uses :sha3 and :base58
    did_type = %AbtDid.Type{role_type: :stake, key_type: :ed25519, hash_type: :sha3}
    ForgeSdk.Wallet.Util.to_address(data, did_type)
  end

  def datetime_to_proto(dt), do: Google.Protobuf.Timestamp.new(seconds: DateTime.to_unix(dt))

  def proto_to_datetime(%{seconds: seconds}), do: DateTime.from_unix!(seconds)

  @doc """
    Update few config env from forge state.

      - token
      - tx_config
      - stake_config
      - poke_config

    This function needs to be called after ForgeSdk.init was called.
  """

  def update_config(nil) do
    # for the first time forge started, there's no forge state yet
    # hence we cache the config from forge_config
    # TODO: we shall parse configuration as atom keys during initialization. Thus this conversion is not needed

    config = ForgeSdk.get_env(:forge_config)
    token = to_atom_map(config["token"])

    tx_config = to_atom_map(config["transaction"])
    tx_config = %{tx_config | declare: to_atom_map(tx_config.declare)}

    stake_config =
      config
      |> get_in(["stake", "timeout"])
      |> to_atom_map("timeout")

    poke_config = to_atom_map(config["poke"])

    Application.put_env(:forge_abi, :decimal, token.decimal)
    ForgeSdk.put_env(:token, token)
    ForgeSdk.put_env(:tx_config, tx_config)
    ForgeSdk.put_env(:stake_config, stake_config)
    ForgeSdk.put_env(:poke_config, poke_config)
  end

  def update_config(forge_state) do
    # for the rest time, we cache the configs from forge state

    token = Map.from_struct(forge_state.token)
    tx_config = Map.from_struct(forge_state.tx_config)
    stake_config = Map.from_struct(forge_state.stake_config)
    poke_config = Map.from_struct(forge_state.poke_config)

    Application.put_env(:forge_abi, :decimal, token.decimal)
    ForgeSdk.put_env(:token, token)
    ForgeSdk.put_env(:tx_config, tx_config)
    ForgeSdk.put_env(:stake_config, stake_config)
    ForgeSdk.put_env(:poke_config, poke_config)
  end

  # private function

  defp get_servers(config) do
    forge_config = parse(:forge, config)

    grpc_addr = forge_config["sock_grpc"]

    get_rpc_conn_spec(grpc_addr)
  end

  defp get_rpc_conn_spec(addr) do
    case Process.whereis(ForgeSdk.Rpc.Conn) do
      nil -> [{ForgeSdk.Rpc.Conn, addr}]
      _ -> []
    end
  end

  defp to_file(:env), do: System.get_env("FORGE_CONFIG") || ""
  defp to_file(:home), do: Path.expand("~/.forge/forge.toml")

  defp to_file(:priv) do
    case Application.get_env(:forge_sdk, :env) in [:test, :integration] do
      true -> get_priv_file("forge_test.toml")
      false -> get_priv_file("forge.toml")
    end
  end

  defp get_priv_file(name), do: :forge_sdk |> :code.priv_dir() |> Path.join(name)

  defp to_atom_map(map),
    do: Enum.into(map, %{}, fn {k, v} -> {String.to_atom(k), v} end)

  defp to_atom_map(map, prefix),
    do: Enum.into(map, %{}, fn {k, v} -> {String.to_atom("#{prefix}_#{k}"), v} end)
end
