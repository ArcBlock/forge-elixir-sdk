defimpl ForgeSdk.Display, for: ForgeAbi.BigUint do
  @moduledoc """
  Implementation of `Display` protocol for `BigUint`
  """
  use ForgeAbi.Arc

  def display(data, _expand? \\ false), do: to_int(data)
end

defimpl ForgeSdk.Display, for: ForgeAbi.BigSint do
  @moduledoc """
  Implementation of `Display` protocol for `BigSint`
  """
  use ForgeAbi.Arc

  def display(data, _expand? \\ false), do: to_int(data)
end
