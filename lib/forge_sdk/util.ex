defmodule ForgeSdk.Util do
  @moduledoc """
  Get configuration, server setup, etc.
  """

  use ForgeAbi.Unit

  alias ForgeAbi.{CreateAssetTx, ForgeState, WalletType}
  alias ForgeSdk.{AbiServer, Configuration}
  alias Configuration.{Cache, Forge, ForgeApp, Ipfs, Tendermint}
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

  def get_chan do
    case ForgeSdk.Rpc.Conn.get_chan() do
      nil ->
        config = ForgeSdk.get_env(:forge_config)

        addr =
          case config["sock_grpc"] do
            "unix://" <> v -> v
            "tcp://" <> v -> v
            v -> v
          end

        {:ok, chan} = GRPC.Stub.connect(addr)
        chan

      v ->
        v
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
    content = "forge_release.toml.eex" |> get_priv_file() |> File.read!()
    params = Keyword.new(params, fn {k, v} -> {:"#{k}", v} end)
    validators = EEx.eval_string(content, params)
    toml = ForgeSdk.get_env(:toml)

    case String.contains?(toml, "### begin validators") do
      true -> String.replace(toml, ~r/### begin validators.*?### end validators/s, validators)
      false -> String.replace(toml, "[[tendermint.genesis.validators]]", validators)
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

  @doc """
  Generate address for asset. Use owner's address + owner's nonce when creating this asset.
  """
  @spec to_asset_address(String.t(), CreateAssetTx.t(), WalletType.t() | nil) :: String.t()
  def to_asset_address(address, itx, _) do
    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, CreateAssetTx.encode(itx))
    data = address <> hash
    did_type = address |> AbtDid.get_did_type() |> Map.put(:role_type, :asset)
    ForgeSdk.Wallet.Util.to_address(data, did_type)
  end

  @doc """
  Generate stake address. Use sender's address + receiver's address as pseudo public key.
  Use `ed25519` as pseudo key type. Use sha3 and base58 by default.
  """
  @spec to_stake_address(String.t(), String.t()) :: String.t()
  def to_stake_address(addr1, addr2) do
    pk =
      case addr1 < addr2 do
        true -> addr1 <> addr2
        _ -> addr2 <> addr1
      end

    # complex address uses :sha3 and :base58
    type = WalletType.new(role: :role_stake, pk: :ed25519, address: :base58, hash: :sha3)
    ForgeSdk.Wallet.Util.to_address(pk, type)
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
  def update_config do
    case ForgeSdk.get_forge_state() do
      %ForgeState{} = forge_state ->
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

      _ ->
        # for the first time forge started, there's no forge state yet
        # hence we cache the config from forge_config

        config = ForgeSdk.get_env(:forge_config)
        token = Enum.into(config["token"], %{}, fn {k, v} -> {String.to_atom(k), v} end)

        tx_config = Enum.into(config["transaction"], %{}, fn {k, v} -> {String.to_atom(k), v} end)

        stake_config =
          config
          |> get_in(["stake", "timeout"])
          |> Enum.into(%{}, fn {k, v} -> {String.to_atom("timeout_#{k}"), v} end)

        poke_config = Enum.into(config["poke"], %{}, fn {k, v} -> {String.to_atom(k), v} end)

        Application.put_env(:forge_abi, :decimal, token.decimal)
        ForgeSdk.put_env(:token, token)
        ForgeSdk.put_env(:tx_config, tx_config)
        ForgeSdk.put_env(:stake_config, stake_config)
        ForgeSdk.put_env(:poke_config, poke_config)
    end
  end

  # private function

  defp get_servers(config) do
    forge_config = parse(:forge, config)
    forge_app_config = parse(:forge_app, config)

    tcp_addr = forge_app_config["sock_tcp"]
    grpc_addr = forge_config["sock_grpc"]

    get_abi_server_spec(tcp_addr) ++ get_rpc_conn_spec(grpc_addr)
  end

  defp get_abi_server_spec(""), do: []

  defp get_abi_server_spec(addr) do
    case Process.whereis(AbiServer) do
      nil -> [do_get_abi_server_spec(addr)]
      _ -> []
    end
  end

  defp do_get_abi_server_spec("tcp://" <> addr) do
    [_ip, port] = String.split(addr, ":")
    AbiServer.child_spec(port: String.to_integer(port))
  end

  defp do_get_abi_server_spec("unix://" <> name) do
    AbiServer.child_spec(port: 0, ip: {:local, String.to_charlist(name)})
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
end
