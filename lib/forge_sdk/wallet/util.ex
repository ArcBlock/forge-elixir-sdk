defmodule ForgeSdk.Wallet.Util do
  @moduledoc """
  Helper functiosn for wallet. Moved from old "utils/wallet.ex". Shall refactor in future.
  """
  require Logger

  alias AbtDid
  alias AbtDid.Type, as: DidType
  alias ForgeSdk.Util.Validator
  alias ForgeAbi.{KeyType, HashType, RoleType, Transaction, WalletInfo, WalletType}
  alias AbciVendor.KVPair
  alias Mcrypto.Crypter.AES
  alias Mcrypto.Hasher.{Keccak, Sha3, Sha2}
  alias Mcrypto.Signer.{Ed25519, Secp256k1}

  @spec create(WalletType.t(), String.t()) :: WalletInfo.t() | {:error, term()}
  def create(type, passphrase \\ "") do
    case passphrase == "" or Validator.valid_passphrase?(passphrase) do
      true ->
        {pk, sk} = do_keypair(KeyType.key(type.pk))
        to_keystore(type, sk, pk, passphrase)

      _ ->
        {:error, "cannot create the wallet. Passphrase is not strong enough"}
    end
  end

  @spec sign!(WalletInfo.t(), binary()) :: binary()
  def sign!(wallet, data) do
    type = wallet.type

    hash = do_hash(HashType.key(type.hash), data)
    do_sign!(KeyType.key(type.pk), hash, wallet.sk)
  end

  @spec verify(WalletInfo.t(), binary(), binary()) :: boolean()
  def verify(%{pk: ""}, _data, _signature), do: false
  def verify(%{type: nil}, _data, _signature), do: false

  def verify(wallet, data, signature) do
    type = wallet.type

    hash = do_hash(HashType.key(type.hash), data)
    valid_sig?(KeyType.key(type.pk), hash, signature, wallet.pk)
  end

  @doc """
  Sign the transaction with extra private key, usually used for exchange and other transactions that requires involvment for multiple party. Note this is not for multisig wallet, but for a multisig transaction.
  """
  @spec multisig!(WalletInfo.t(), Transaction.t()) :: Transaction.t()
  def multisig!(%{signature: ""} = tx, _), do: tx

  def multisig!(wallet, tx) do
    sig = sign!(wallet, Transaction.encode(tx))
    signatures = tx.signatures
    new_sig = KVPair.new(key: wallet.address, value: sig)
    %Transaction{tx | signatures: [new_sig | signatures]}
  end

  @spec save(WalletInfo.t(), binary()) :: :ok
  def save(wallet, passphrase) do
    path = get_keystore()

    filename = get_filename(path, wallet.address)
    File.mkdir_p!(Path.dirname(filename))

    [iv: iv, ciphertext: cipher] = Mcrypto.encrypt(%AES{}, wallet.sk, passphrase)

    type = wallet.type |> WalletType.encode() |> Base.encode64()
    data = %{iv: iv, wallet: %{wallet | sk: cipher, pk: Base.encode64(wallet.pk), type: type}}
    File.write!(filename, Jason.encode!(data))
  end

  @spec list :: Enum.t()
  def list do
    get_keystore()
    |> Path.join("???")
    |> Path.wildcard()
    |> Stream.flat_map(fn p ->
      prefix = Path.basename(p)

      p
      |> Path.join("*.key")
      |> Path.wildcard()
      |> Enum.map(fn name ->
        fname = name |> Path.basename(name) |> String.trim_trailing(".key")
        prefix <> fname
      end)
    end)
  end

  @spec remove(String.t()) :: :ok | {:error, term()}
  def remove(address) do
    get_keystore()
    |> get_filename(address)
    |> File.rm()
  end

  @spec load(binary() | map() | any(), binary()) :: WalletInfo.t() | {:error, term()}
  def load(address, passphrase) when is_binary(address) do
    path = get_keystore()
    filename = get_filename(path, address)

    case File.exists?(filename) do
      true ->
        content = filename |> File.read!() |> Jason.decode!(keys: :atoms!)
        load(content, passphrase)

      _ ->
        {:error, "Cannot load keystore #{filename}"}
    end
  end

  def load(content, passphrase) when is_map(content) do
    %{wallet: wallet, iv: iv} = content
    sk = Mcrypto.decrypt(%AES{}, wallet.sk, passphrase, iv)

    case sk do
      :error ->
        {:error, "Cannot decrypt wallet with content: #{inspect(wallet)}"}

      _ ->
        type = wallet.type |> Base.decode64!() |> WalletType.decode()

        WalletInfo.new(%{
          type:
            WalletType.new(%{
              pk: type.pk,
              hash: type.hash,
              address: type.address
            }),
          sk: sk,
          pk: Base.decode64!(wallet.pk),
          address: wallet.address
        })
    end
  rescue
    e -> {:error, e}
  end

  def load(wallet, _), do: {:error, "invalid wallet: #{inspect(wallet)}"}

  @spec recover(WalletType.t(), binary(), String.t()) :: WalletInfo.t() | {:error, term()}
  def recover(type, sk, passphrase \\ "") do
    case passphrase === "" or Validator.valid_passphrase?(passphrase) do
      true ->
        pk_type = KeyType.key(type.pk)
        pk = sk_to_pk(pk_type, sk)
        to_keystore(type, sk, pk, passphrase)

      _ ->
        {:error, "cannot recover the wallet. Passphrase is not strong enough"}
    end
  end

  @doc """
  Converts a (pseudo) publick key to address.
  """
  @spec to_address(binary(), WalletType.t()) :: String.t()
  def to_address(data, wallet_type) do
    did_type = to_did_type(wallet_type)
    AbtDid.pk_to_did(did_type, data, encode: true, form: :short)
  end

  @spec get_filename(String.t(), String.t()) :: String.t()
  def get_filename(path, address) do
    <<dir::binary-size(3), rest::binary>> = address

    Path.join([path, dir, "#{rest}.key"])
  end

  def serialize(wallet) do
    %{
      type: Map.from_struct(wallet.type),
      pk: Base.encode64(wallet.pk),
      sk: Base.encode64(wallet.sk),
      address: wallet.address
    }
    |> Jason.encode!()
  end

  def deserialize(data) do
    data
    |> Jason.decode!(keys: :atoms)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      cond do
        k == :address -> Map.put(acc, k, v)
        k in [:pk, :sk] -> Map.put(acc, k, Base.decode64!(v))
        k == :type -> Map.put(acc, k, WalletType.new(v))
      end
    end)
    |> WalletInfo.new()
  end

  # private function
  defp to_keystore(type, sk, pk, passphrase) do
    wallet =
      WalletInfo.new(%{
        type: type,
        sk: sk,
        pk: pk,
        address: to_address(pk, type)
      })

    if passphrase !== "" do
      save(wallet, passphrase)
    end

    wallet
  end

  defp do_hash(:keccak, data), do: Mcrypto.hash(%Keccak{}, data)
  defp do_hash(:sha2, data), do: Mcrypto.hash(%Sha2{}, data)
  defp do_hash(:sha3, data), do: Mcrypto.hash(%Sha3{}, data)

  defp do_hash(:keccak_384, data), do: Mcrypto.hash(%Keccak{size: 384}, data)
  defp do_hash(:sha2_384, data), do: Mcrypto.hash(%Sha2{size: 384}, data)
  defp do_hash(:sha3_384, data), do: Mcrypto.hash(%Sha3{size: 384}, data)

  defp do_keypair(:ed25519), do: Mcrypto.keypair(%Ed25519{})
  defp do_keypair(:secp256k1), do: Mcrypto.keypair(%Secp256k1{})

  defp sk_to_pk(:ed25519, sk), do: Mcrypto.sk_to_pk(%Ed25519{}, sk)
  defp sk_to_pk(:secp256k1, sk), do: Mcrypto.sk_to_pk(%Secp256k1{}, sk)

  defp do_sign!(:ed25519, data, sk), do: Mcrypto.sign!(%Ed25519{}, data, sk)
  defp do_sign!(:secp256k1, data, sk), do: Mcrypto.sign!(%Secp256k1{}, data, sk)

  defp valid_sig?(:ed25519, data, sig, pk), do: Mcrypto.verify(%Ed25519{}, data, sig, pk)
  defp valid_sig?(:secp256k1, data, sig, pk), do: Mcrypto.verify(%Secp256k1{}, data, sig, pk)

  defp get_keystore, do: :forge_config |> ForgeSdk.get_env() |> Map.get("keystore")

  defp to_did_type(wallet_type) do
    %DidType{
      role_type: to_did_type(wallet_type.role, RoleType, "role_"),
      key_type: to_did_type(wallet_type.pk, KeyType, ""),
      hash_type: to_did_type(wallet_type.hash, HashType, "")
    }
  end

  defp to_did_type(wallet_type, _module, "") when is_atom(wallet_type), do: wallet_type

  defp to_did_type(wallet_type, _module, prefix) when is_atom(wallet_type) do
    wallet_type
    |> to_string()
    |> String.trim_leading(prefix)
    |> String.to_atom()
  end

  defp to_did_type(wallet_type, module, prefix) do
    wallet_type
    |> module.key()
    |> to_did_type(module, prefix)
  end
end
