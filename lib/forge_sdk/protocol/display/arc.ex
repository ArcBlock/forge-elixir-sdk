defimpl ForgeSdk.Display, for: ForgeAbi.BigUint do
  @moduledoc """
  Implementation of `Display` protocol for `BigUint`
  """
  use ForgeAbi.Unit

  def display(data, expand?) do
    v = to_int(data)

    case expand? do
      true -> Integer.to_string(v)
      _ -> v
    end
  end
end

defimpl ForgeSdk.Display, for: ForgeAbi.BigSint do
  @moduledoc """
  Implementation of `Display` protocol for `BigSint`
  """
  use ForgeAbi.Unit

  def display(data, expand?) do
    v = to_int(data)

    case expand? do
      true -> Integer.to_string(v)
      _ -> v
    end
  end
end
