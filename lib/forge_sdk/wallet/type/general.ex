defimpl ForgeSdk.Wallet, for: ForgeAbi.WalletType do
  use ForgeSdk.Wallet.Builder, mod: ForgeAbi.WalletType
end
