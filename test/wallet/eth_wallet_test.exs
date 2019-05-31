defmodule ForgeSdkTest.EthWallet do
  @moduledoc false
  use ExUnit.Case

  alias Mcrypto.Signer.Secp256k1
  alias ForgeSdk.Wallet
  alias ForgeSdk.Wallet.Type.Eth

  @pass "abcd1234"

  test "create a new eth wallet shall return correct data" do
    wallet = Wallet.create(%Eth{})
    did_type = AbtDid.get_did_type(wallet.address)

    assert did_type === %AbtDid.Type{
             key_type: :secp256k1,
             hash_type: :keccak,
             role_type: :account
           }

    assert Mcrypto.sk_to_pk(%Secp256k1{}, wallet.sk) === wallet.pk
  end

  test "sign a tx could be verified" do
    data = "hello world"
    wallet = Wallet.create(%Eth{})
    sig = Wallet.sign!(%Eth{}, wallet, data)
    assert true === Wallet.verify(%Eth{}, wallet, data, sig)
  end
end
