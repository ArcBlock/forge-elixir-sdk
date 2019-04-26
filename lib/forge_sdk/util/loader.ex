defmodule ForgeSdk.Loader do
  @moduledoc """
   Load type urls and various protobufs in sdk
  """
  require Logger

  alias ForgeSdk.Rpc

  def update_type_url(forge_state) do
    forge_state
    |> get_protocols()
    |> Enum.each(fn itx ->
      load_code(itx.code)
      load_type_urls(itx.type_urls)
    end)
  end

  def get_protocols(forge_state, address \\ "") do
    forge_state
    |> Map.get(:protocols, [])
    |> Enum.filter(fn %{address: protocol_address} ->
      case address === "" do
        true -> true
        false -> protocol_address === address
      end
    end)
    |> Task.async_stream(fn %{address: address} -> get_one_protocol(address) end)
    |> Enum.map(fn {:ok, res} -> res end)
  end

  defp get_one_protocol(address) do
    %{tx_hash: tx_hash} = Rpc.get_protocol_state(address: address)
    %{tx: tx} = Rpc.get_tx(hash: tx_hash)
    ForgeAbi.decode_any!(tx.itx)
  end

  defp load_code(code) do
    code
    |> Enum.each(fn %{binary: binary} ->
      {:ok, {mod, _}} = :beam_lib.md5(binary)

      if String.starts_with?(Atom.to_string(mod), "Elixir.ForgeAbi") do
        # purge old code
        purge_result = :code.soft_purge(mod)
        load_result = :code.load_binary(mod, '', binary)

        Logger.info(
          "#{Atom.to_string(mod)} - Purged old code: #{inspect(purge_result)}, and loaded new code: #{
            inspect(load_result)
          }"
        )
      end
    end)
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
