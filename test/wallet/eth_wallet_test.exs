defmodule ForgeSdkTest.EthWallet do
  @moduledoc false
  use ExUnit.Case

  alias Mcrypto.Signer.Secp256k1
  alias ForgeSdk.Wallet
  alias ForgeSdk.Wallet.Type.Eth

  @pass "abcd1234"

  test "create a new eth wallet shall return correct data" do
    wallet = Wallet.create(%Eth{}, @pass)
    did_type = AbtDid.get_did_type(wallet.address)

    assert did_type === %AbtDid.Type{
             key_type: :secp256k1,
             hash_type: :keccak,
             role_type: :account
           }

    assert Mcrypto.sk_to_pk(%Secp256k1{}, wallet.sk) === wallet.pk
  end

  test "create a new eth wallet shall create keystore" do
    wallet = Wallet.create(%Eth{}, @pass)
    assert true === ForgeSdkTest.Utils.keystore_exists?(wallet.address)
  end

  test "create a new eth wallet shall be loaded" do
    wallet = Wallet.create(%Eth{}, @pass)
    wallet1 = Wallet.load(%Eth{}, wallet.address, @pass)
    assert wallet === wallet1
  end

  test "sign a tx could be verified" do
    data = "hello world"
    wallet = Wallet.create(%Eth{}, @pass)
    sig = Wallet.sign!(%Eth{}, wallet, data)
    assert true === Wallet.verify(%Eth{}, wallet, data, sig)
  end

  test "recover a wallet by sk shall create a keystore" do
    sk = :crypto.strong_rand_bytes(32)
    wallet = Wallet.recover(%Eth{}, sk, @pass)
    assert wallet.sk === sk
    assert Mcrypto.sk_to_pk(%Secp256k1{}, wallet.sk) === wallet.pk
    assert true === ForgeSdkTest.Utils.keystore_exists?(wallet.address)
  end
end
