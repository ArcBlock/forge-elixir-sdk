defmodule ForgeSdkTest.WalletUtils do
  @moduledoc false
  use ExUnit.Case
  use ExUnitProperties

  alias Mcrypto.Signer.{Ed25519, Secp256k1}

  alias ForgeSdk.Wallet.Util
  alias ForgeAbi.{KeyType, HashType, EncodingType, WalletType}

  @pass "abcd1234"

  property "create a new wallet shall return correct data" do
    check all pk_type <- integer(0..1),
              hash_type <- integer(0..1),
              encoding_type <- integer(0..1) do
      type =
        WalletType.new(
          address: EncodingType.key(encoding_type),
          hash: HashType.key(hash_type),
          pk: KeyType.key(pk_type)
        )

      wallet = Util.create(type, @pass)

      case pk_type do
        0 -> assert Mcrypto.sk_to_pk(%Ed25519{}, wallet.sk) === wallet.pk
        1 -> assert Mcrypto.sk_to_pk(%Secp256k1{}, wallet.sk) === wallet.pk
      end

      # any wallet can be loaded
      wallet1 = Util.load(wallet.address, @pass)
      assert wallet === wallet1

      # sign data could be verified
      data = "arcblock to the moon"
      sig = Util.sign!(wallet, data)
      assert true === Util.verify(wallet, data, sig)
    end
  end

  test "recover a wallet by sk shall create a keystore" do
    w1 = Util.create(WalletType.new(address: :base58, hash: :sha3, pk: :ed25519), @pass)
    did_type = AbtDid.get_did_type(w1.address)
    wallet = Util.recover(did_type, w1.sk, @pass)
    assert w1 === wallet
  end

  test "remove a wallet shall remove keystore" do
    w1 = Util.create(WalletType.new(address: :base58, hash: :sha3, pk: :ed25519), @pass)

    assert true === ForgeSdkTest.Utils.keystore_exists?(w1.address)
    Util.remove(w1.address)
    assert false === ForgeSdkTest.Utils.keystore_exists?(w1.address)
  end
end
