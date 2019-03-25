defimpl ForgeSdk.Display, for: ForgeAbi.Multisig do
  @moduledoc """
  Implementation of `Display` protocol for `KVPair`
  """

  def display(%{signer: addr, pk: pk, signature: sig, data: data}, _expand? \\ false) do
    addr = if String.valid?(addr), do: addr, else: Base.url_encode64(addr, padding: false)
    sig = Base.url_encode64(sig, padding: false)

    %{
      signer: addr,
      pk: Base.url_encode64(pk, padding: false),
      signature: sig,
      data: data
    }
  end
end
