defimpl ForgeSdk.Display, for: ForgeAbi.IndexedTransaction do
  @moduledoc """
  Implementation of `Display` protocol for `IndexedTransaction`
  """
  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)

    basic =
      case basic.value do
        nil -> basic
        {k, v} -> Map.put(basic, k, v)
      end

    Map.merge(basic, %{
      tx: Display.display(basic.tx)
    })
  end
end
