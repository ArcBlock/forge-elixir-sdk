defmodule ForgeSdkTest.WalletUtils do
  @moduledoc false
  use ExUnit.Case
  use ExUnitProperties

  alias Mcrypto.Signer.{Ed25519, Secp256k1}

  alias ForgeSdk.Wallet.Util
  alias ForgeAbi.{KeyType, HashType, EncodingType, WalletType}

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

      wallet = Util.create(type)

      case pk_type do
        0 -> assert Mcrypto.sk_to_pk(%Ed25519{}, wallet.sk) === wallet.pk
        1 -> assert Mcrypto.sk_to_pk(%Secp256k1{}, wallet.sk) === wallet.pk
      end

      # sign data could be verified
      data = "arcblock to the moon"
      sig = Util.sign!(wallet, data)
      assert true === Util.verify(wallet, data, sig)
    end
  end
end
