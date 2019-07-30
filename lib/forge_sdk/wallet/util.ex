defmodule ForgeSdk.Wallet.Util do
  @moduledoc """
  Helper functions for wallet.
  """
  require Logger

  alias AbtDid
  alias AbtDid.Type, as: DidType

  alias ForgeAbi.{Multisig, Transaction, WalletInfo, WalletType}

  alias Mcrypto.Hasher.{Keccak, Sha2, Sha3}
  alias Mcrypto.Signer.{Ed25519, Secp256k1}

  @spec create(WalletType.t()) :: WalletInfo.t() | {:error, term()}
  def create(type) do
    {pk, sk} = do_keypair(type.pk)
    did_type = to_did_type(type)

    WalletInfo.new(%{
      sk: sk,
      pk: pk,
      address: AbtDid.pk_to_did(did_type, pk, form: :short)
    })
  rescue
    e -> {:error, "#{inspect(e)}"}
  end

  @spec sign!(WalletInfo.t(), binary()) :: binary()
  def sign!(wallet, data) do
    did_type = AbtDid.get_did_type(wallet.address)

    hash = do_hash(did_type.hash_type, data)
    do_sign!(did_type.key_type, hash, wallet.sk)
  end

  @spec verify(WalletInfo.t(), binary(), binary()) :: boolean()
  def verify(%{pk: ""}, _data, _signature), do: false
  def verify(%{address: ""}, _data, _signature), do: false

  def verify(wallet, data, signature) do
    did_type = AbtDid.get_did_type(wallet.address)

    hash = do_hash(did_type.hash_type, data)
    valid_sig?(did_type.key_type, hash, signature, wallet.pk)
  end

  @doc """
  Sign the transaction with extra private key, usually used for exchange and other transactions that requires involvment for multiple party. Note this is not for multisig wallet, but for a multisig transaction.
  """
  @spec multisig!(WalletInfo.t(), Transaction.t(), Keyword.t()) :: Transaction.t()
  def multisig!(wallet, tx, opts)
  def multisig!(_, %{signature: ""}, _), do: {:error, :invalid_signature}

  def multisig!(wallet, tx, opts) do
    data = opts[:data]
    delegatee = opts[:delegatee] || ""

    sigs =
      case delegatee do
        "" ->
          [Multisig.new(signer: wallet.address, pk: wallet.pk, data: data) | tx.signatures]

        delegatee ->
          [
            Multisig.new(signer: delegatee, delegator: wallet.address, pk: wallet.pk, data: data)
            | tx.signatures
          ]
      end

    tx_data = Transaction.encode(%{tx | signature: ""})

    sender_wallet =
      case tx.delegator do
        "" -> WalletInfo.new(address: tx.from, pk: tx.pk)
        d -> WalletInfo.new(address: d, pk: tx.pk)
      end

    case verify(sender_wallet, tx_data, tx.signature) do
      true ->
        tx = %{tx | signatures: sigs}
        sig = sign!(wallet, Transaction.encode(tx))
        [data | sigs] = tx.signatures
        data = %{data | signature: sig}
        %Transaction{tx | signatures: [data | sigs]}

      _ ->
        {:error, :invalid_signature}
    end
  end

  @doc """
  Converts a (pseudo) publick key to address.
  """
  @spec to_address(binary(), WalletType.t()) :: String.t()
  def to_address(data, %WalletType{} = wallet_type) do
    did_type = to_did_type(wallet_type)
    AbtDid.pk_to_did(did_type, data, encode: true, form: :short)
  end

  @spec to_address(binary(), AbtDid.Type.t()) :: String.t()
  def to_address(data, %AbtDid.Type{} = did_type) do
    AbtDid.pk_to_did(did_type, data, encode: true, form: :short)
  end

  def serialize(wallet) do
    %{
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
        k in [:sk, :pk] -> Map.put(acc, k, Base.decode64!(v))
        true -> acc
      end
    end)
    |> WalletInfo.new()
  end

  @spec to_did_type(WalletType.t()) :: AbtDid.Type.t()
  def to_did_type(wallet_type) do
    %DidType{
      role_type: to_did_type(wallet_type.role, "role_"),
      key_type: to_did_type(wallet_type.pk, ""),
      hash_type: to_did_type(wallet_type.hash, "")
    }
  end

  @spec to_wallet_type(AbtDid.Type.t()) :: WalletType.t()
  def to_wallet_type(did_type) do
    %ForgeAbi.WalletType{
      address: :base58,
      pk: did_type.key_type,
      hash: did_type.hash_type,
      role:
        ("role_" <> Atom.to_string(did_type.role_type))
        |> String.to_atom()
    }
  end

  # private function

  defp do_hash(:keccak, data), do: Mcrypto.hash(%Keccak{}, data)
  defp do_hash(:sha2, data), do: Mcrypto.hash(%Sha2{round: 1}, data)
  defp do_hash(:sha3, data), do: Mcrypto.hash(%Sha3{}, data)
  defp do_hash(:keccak_384, data), do: Mcrypto.hash(%Keccak{size: 384}, data)
  defp do_hash(:sha3_384, data), do: Mcrypto.hash(%Sha3{size: 384}, data)

  defp do_keypair(:ed25519), do: Mcrypto.keypair(%Ed25519{})
  defp do_keypair(:secp256k1), do: Mcrypto.keypair(%Secp256k1{})

  defp do_sign!(:ed25519, data, sk), do: Mcrypto.sign!(%Ed25519{}, data, sk)
  defp do_sign!(:secp256k1, data, sk), do: Mcrypto.sign!(%Secp256k1{}, data, sk)

  defp valid_sig?(:ed25519, data, sig, pk), do: Mcrypto.verify(%Ed25519{}, data, sig, pk)
  defp valid_sig?(:secp256k1, data, sig, pk), do: Mcrypto.verify(%Secp256k1{}, data, sig, pk)

  defp to_did_type(wallet_type, "") when is_atom(wallet_type), do: wallet_type

  defp to_did_type(wallet_type, prefix) when is_atom(wallet_type) do
    wallet_type
    |> to_string()
    |> String.trim_leading(prefix)
    |> String.to_atom()
  end
end
