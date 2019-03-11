defimpl ForgeSdk.Display, for: ForgeAbi.TransactionInfo do
  @moduledoc """
  Implementation of `Display` protocol for `TransactionInfo`
  """
  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)

    basic =
      case basic.extra_meta do
        nil -> basic
        {k, v} -> Map.put(basic, k, v)
      end

    Map.merge(basic, %{
      tx: Display.display(basic.tx),
      tags: Display.display(basic.tags),
      time: Display.display(basic.time)
    })
  end
end
