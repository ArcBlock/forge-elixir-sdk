defmodule ForgeSdkTest.Utils do
  @moduledoc false

  def keystore_exists?(address) do
    config = ForgeSdk.get_env(:forge_config)
    config["keystore"] |> ForgeSdk.Wallet.Util.get_filename(address) |> File.exists?()
  end
end
