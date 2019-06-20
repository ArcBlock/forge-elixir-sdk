defmodule ForgeSdk.Util do
  @moduledoc """
  Get configuration, server setup, etc.
  """

  use ForgeAbi.Unit
  alias ForgeSdk.ConnSupervisor
  alias ForgeSdk.Conn

  alias Google.Protobuf.Timestamp

  @doc """
  Upon initialization, forge client can call this function to make a gRPC connection to forge node.
  """
  @spec connect(String.t(), Keyword.t()) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def connect(host, opts) do
    name = String.to_atom(opts[:name])

    case opts[:default] do
      true -> Application.put_env(:forge_sdk, :default_conn, name)
      _ -> nil
    end

    result = ConnSupervisor.add(name, host, nil)
    forge_state = ForgeSdk.get_forge_state(name)

    case name do
      :forge_server_node -> nil
      _ -> ForgeSdk.update_type_url(forge_state)
    end

    config = ForgeSdk.get_config([parsed: true], name)
    ForgeSdk.RpcConn.update_config(name, config)
    ForgeSdk.RpcConn.update_gas(name, forge_state.gas)

    result
  end

  @doc """
  Get the gRPC connection channel.
  """
  @spec get_conn(String.t() | atom()) :: Conn.t()
  def get_conn(name \\ "")

  def get_conn(""), do: get_conn(Application.get_env(:forge_sdk, :default_conn))
  def get_conn(name) when is_binary(name), do: get_conn(String.to_existing_atom(name))
  def get_conn(name), do: ForgeSdk.RpcConn.get_conn(name)

  @doc """
  Get the configuration for the conn.
  """
  @spec get_parsed_config(String.t() | atom()) :: String.t()
  def get_parsed_config(name \\ "")

  def get_parsed_config(""), do: get_parsed_config(Application.get_env(:forge_sdk, :default_conn))

  def get_parsed_config(name) when is_binary(name),
    do: get_parsed_config(String.to_existing_atom(name))

  def get_parsed_config(name), do: ForgeSdk.RpcConn.get_config(name)

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
    AbtDid.hash_to_did(:tether, hash, form: :short)
  end

  @doc """
  Generate address for asset. We only use itx.data to generate asset address. Thus same itx.data would be treated as duplicate asset.
  """
  @spec to_asset_address(map()) :: String.t()
  def to_asset_address(itx) do
    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, itx.__struct__.encode(itx))
    AbtDid.hash_to_did(:asset, hash, form: :short)
  end

  @doc """
  Generate address for tx.
  """
  @spec to_tx_address(map()) :: String.t()
  def to_tx_address(itx) do
    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, itx.__struct__.encode(itx))
    AbtDid.hash_to_did(:tx, hash, form: :short)
  end

  @doc """
  Generate stake address. Use sender's address + receiver's address as pseudo public key.
  Use `ed25519` as pseudo key type. Use sha3 and base58 by default.
  """
  @spec to_stake_address(String.t(), String.t()) :: String.t()
  def to_stake_address(addr1, addr2) do
    data = addr1 <> addr2

    hash = Mcrypto.hash(%Mcrypto.Hasher.Sha3{}, data)
    AbtDid.hash_to_did(:stake, hash, form: :short)
  end

  def datetime_to_proto(dt), do: Google.Protobuf.Timestamp.new(seconds: DateTime.to_unix(dt))

  def proto_to_datetime(%{seconds: seconds}), do: DateTime.from_unix!(seconds)

  def token_to_unit(n, name \\ "") do
    conn = ForgeSdk.get_conn(name)
    ForgeAbi.token_to_unit(n, conn.decimal)
  end

  def unit_to_token(v, name \\ "") do
    conn = ForgeSdk.get_conn(name)
    ForgeAbi.unit_to_token(v, conn.decimal)
  end

  def one_token(name \\ "") do
    conn = ForgeSdk.get_conn(name)
    ForgeAbi.one_token(conn.decimal)
  end
end
