defimpl ForgeSdk.Display, for: ForgeAbi.Multisig do
  @moduledoc """
  Implementation of `Display` protocol for `KVPair`
  """
  alias ForgeSdk.Display

  def display(
        %{signer: addr, delegator: delegator, pk: pk, signature: sig, data: data},
        _expand? \\ false
      ) do
    addr = if String.valid?(addr), do: addr, else: Base.url_encode64(addr, padding: false)
    sig = Base.url_encode64(sig, padding: false)

    %{
      signer: addr,
      delegator: delegator,
      pk: Base.url_encode64(pk, padding: false),
      signature: sig,
      data: Display.display(data)
    }
  end
end
