defmodule ForgeSdk.Tx.Builder.Helper do
  @moduledoc """
  Helper function for building tx rpc.
  """
  alias ForgeAbi.{RequestSendTx, Transaction}
  alias ForgeSdk.Wallet.Util, as: WalletUtil

  # credo:disable-for-lines:40
  def build(itx, opts) do
    type_url = ForgeAbi.get_type_url(itx.__struct__)
    any = ForgeAbi.encode_any!(itx, type_url)

    wallet = opts[:wallet]
    delegatee = opts[:delegatee]

    sign? = Keyword.get(opts, :sign, true)
    conn = ForgeSdk.Util.get_conn(opts[:conn] || "")

    if wallet === nil do
      raise "wallet shall be provided in opts"
    end

    if wallet.sk === "" and sign? do
      raise "Tx requires signature but no sk found"
    end

    nonce =
      case opts[:nonce] do
        v when is_integer(v) -> v
        _ -> Enum.random(1..10_000_000_000)
      end

    gas = Map.get(conn.gas, type_url, 0)

    case sign? do
      true ->
        case do_create_tx(any, nonce, gas, wallet, delegatee, conn.chain_id) do
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
        create_unsigned_tx(any, nonce, gas, wallet, delegatee, conn)
    end
  end

  # private functions
  defp create_unsigned_tx(any, nonce, gas, wallet, nil, conn) do
    Transaction.new(
      itx: any,
      from: wallet.address,
      nonce: nonce,
      gas: gas,
      chain_id: conn.chain_id,
      pk: wallet.pk
    )
  end

  defp create_unsigned_tx(any, nonce, gas, wallet, delegatee, conn) do
    Transaction.new(
      itx: any,
      delegator: wallet.address,
      from: delegatee,
      nonce: nonce,
      gas: gas,
      chain_id: conn.chain_id,
      pk: wallet.pk
    )
  end

  defp do_create_tx(any, nonce, gas, wallet, delegatee, chain_id) do
    tx =
      case delegatee do
        nil ->
          Transaction.new(
            itx: any,
            from: wallet.address,
            nonce: nonce,
            gas: gas,
            chain_id: chain_id,
            pk: wallet.pk
          )

        _ ->
          Transaction.new(
            itx: any,
            from: delegatee,
            delegator: wallet.address,
            nonce: nonce,
            gas: gas,
            chain_id: chain_id,
            pk: wallet.pk
          )
      end

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
