defmodule ForgeSdk.Loader do
  @moduledoc """
   Load type urls and various protobufs in sdk
  """
  require Logger

  alias ForgeAbi.{ForgeState, TransactionInfo}
  alias ForgeSdk.Rpc

  @spec update_type_url(ForgeState.t()) :: :ok
  def update_type_url(forge_state) do
    forge_state
    |> get_tx_protocols()
    |> Enum.each(fn itx ->
      load_code(itx.code)
      load_type_urls(itx.type_urls)
    end)
  end

  @spec get_tx_protocols(ForgeState.t(), String.t()) :: [map()]
  def get_tx_protocols(forge_state, address \\ "") do
    forge_state
    |> Map.get(:protocols, [])
    |> Enum.filter(fn %{address: protocol_address} ->
      case address === "" do
        true -> true
        false -> protocol_address === address
      end
    end)
    |> Task.async_stream(fn %{address: address} -> get_one_tx_protocol(address) end)
    |> Enum.map(fn {:ok, res} -> res end)
  end

  defp get_one_tx_protocol(address) do
    %{tx_hash: tx_hash, context: context} = Rpc.get_protocol_state(address: address)
    %TransactionInfo{tx: tx} = Rpc.get_tx(hash: tx_hash)
    protocol_meta = ForgeAbi.decode_any!(tx.itx)
    Map.put(protocol_meta, :installed_at, context.genesis_time)
  end

  defp load_code(code) do
    code
    |> Enum.each(fn %{binary: binary} ->
      {:ok, {mod, _}} = :beam_lib.md5(binary)
      name = Atom.to_string(mod)

      if need_load?(name) do
        # purge old code
        purge_result = :code.soft_purge(mod)
        load_result = :code.load_binary(mod, '', binary)

        Logger.info(
          "#{} - Purged old code: #{inspect(purge_result)}, and loaded new code: #{
            inspect(load_result)
          }"
        )
      end
    end)
  end

  defp need_load?(name) do
    String.starts_with?(name, "Elixir.ForgeAbi") or String.ends_with?(name, ".Rpc")
  end

  defp load_type_urls(urls) do
    type_urls =
      Enum.map(urls, fn %{url: url, module: module} ->
        mod = Module.concat("Elixir", module)
        {url, mod}
      end)

    ForgeAbi.add_type_urls(type_urls)
  end
end
