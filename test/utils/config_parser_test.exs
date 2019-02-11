defmodule ForgeSdkTest.ConfigParser do
  use ExUnit.Case

  @config """
          [app]
          path = "~/.forge/app"
          executable = ""
          logfile = "logs/app.log"
          sock_grpc = "unix://socks/abi.sock"
          sock_tcp = ""

          [forge]
          path = "~/.forge/core"
          db = "data"
          keystore = "keystore"
          logfile = "logs/forge.log"

          sock_grpc = "unix://socks/forge_grpc.sock"

          consensus_engine = "tendermint"
          storage_engine = "ipfs"

          [tendermint]
          path = "~/.forge/tendermint"

          # relative paths to "path"
          executable = "bin/tendermint_0.27.0"
          logfile = "logs/tendermint.log"

          sock_proxy_app = "unix://socks/tm_proxy_app.sock"
          sock_rpc = "unix://socks/tm_rpc.sock"
          sock_grpc = "unix://socks/tm_grpc.sock"
          sock_p2p = "tcp://0.0.0.0:26656"
          sock_prof = ""

          [ipfs]
          executable = "bin/ipfs_0.4.18"
          path = "~/.forge/ipfs"
          logfile = "logs/ipfs.log"
          """
          |> Toml.decode!()

  test "tendermint config parser works" do
    config = ForgeSdk.parse_config(:tendermint, @config)

    assert config["path"] !== "~/.forge/tendermint"
    assert true === File.exists?(config["path"])
    assert config["sock_prof"] === ""
    assert config["sock_grpc"] === "unix://" <> config["path"] <> "/socks/tm_grpc.sock"
    assert config["sock_p2p"] === "tcp://0.0.0.0:26656"
  end

  test "ipfs config parser works" do
    config = ForgeSdk.parse_config(:ipfs, @config)

    assert config["path"] !== "~/.forge/ipfs"
    assert config["executable"] === Path.join(config["path"], "bin/ipfs_0.4.18")
    assert config["logfile"] === Path.join(config["path"], "logs/ipfs.log")
  end

  test "app config parser works" do
    config = ForgeSdk.parse_config(:forge_app, @config)

    assert config["path"] !== "~/.forge/app"
    assert config["executable"] === ""
  end

  test "forge and forge core config parser works" do
    [:forge]
    |> Enum.each(fn t ->
      config = ForgeSdk.parse_config(t, @config)

      assert config["path"] !== "~/.forge/core"
      assert config["logfile"] === Path.join(config["path"], "logs/forge.log")
    end)
  end
end
