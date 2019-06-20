defmodule ForgeSdk.Tx.Builder.Helper do
  @moduledoc """
  Helper function for building tx rpc.
  """
  alias ForgeAbi.{RequestCreateTx, RequestSendTx, Transaction}
  alias ForgeSdk.Wallet.Util, as: WalletUtil

  # credo:disable-for-lines:40
  def build(itx, opts) do
    type_url = ForgeAbi.get_type_url(itx.__struct__)
    any = ForgeAbi.encode_any!(itx, type_url)

    wallet = opts[:wallet]
    token = Keyword.get(opts, :token, "")

    sign? = Keyword.get(opts, :sign, true)
    conn = ForgeSdk.Util.get_conn(opts[:conn] || "")

    if wallet === nil do
      raise "wallet shall be provided in opts"
    end

    if wallet.sk === "" and token === "" and sign? do
      raise "Tx requires signature but no sk or valid token found"
    end

    # TODO: here we need to rethink this
    nonce =
      case type_url in ["fg:t:poke", "fg:t:deploy_protocol"] do
        true -> 0
        false -> Enum.random(1..10_000_000_000)
      end

    "fg:t:" <> type = type_url
    gas = Map.get(conn.gas, type, 0)

    case sign? do
      true ->
        case create_tx(any, nonce, gas, wallet, token, conn) do
          {:error, _} = error ->
            error

          tx ->
            case Keyword.get(opts, :send, :broadcast) do
              :broadcast -> send_tx(RequestSendTx.new(tx: tx), conn)
              :commit -> send_tx(RequestSendTx.new(tx: tx, commit: true), conn)
              :nosend -> tx
            end
        end

      false ->
        create_unsigned_tx(any, nonce, gas, wallet, conn)
    end
  end

  # private functions
  defp create_unsigned_tx(any, nonce, gas, wallet, conn) do
    Transaction.new(
      itx: any,
      from: wallet.address,
      nonce: nonce,
      gas: gas,
      chain_id: conn.chain_id,
      pk: wallet.pk
    )
  end

  defp create_tx(any, nonce, _gas, %{sk: ""} = wallet, token, conn) do
    req =
      RequestCreateTx.new(
        itx: any,
        from: wallet.address,
        nonce: nonce,
        wallet: wallet,
        token: token
      )

    ForgeSdk.create_tx(req, conn.chan)
  end

  defp create_tx(any, nonce, gas, wallet, _token, conn) do
    do_create_tx(any, nonce, gas, wallet, conn.chain_id)
  end

  defp do_create_tx(any, nonce, gas, wallet, chain_id) do
    tx =
      Transaction.new(
        itx: any,
        from: wallet.address,
        nonce: nonce,
        gas: gas,
        chain_id: chain_id,
        pk: wallet.pk
      )

    tx = %Transaction{tx | signature: <<>>}
    signature = WalletUtil.sign!(wallet, Transaction.encode(tx))
    %Transaction{tx | signature: signature}
  end

  defp send_tx(req, conn) do
    case ForgeSdk.send_tx(req, conn.name) do
      {:error, _} = error -> error
      res -> res
    end
  end
end
