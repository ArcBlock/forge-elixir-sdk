defimpl ForgeSdk.Display, for: ForgeAbi.ChainInfo do
  @moduledoc """
  Implementation of `Display` protocol for `BigSint`
  """
  use ForgeAbi.Arc

  def display(data, _expand? \\ false) do
    %{
      data
      | app_hash: Base.encode16(data.app_hash, case: :lower),
        block_hash: Base.encode16(data.block_hash, case: :lower),
        block_time: ForgeSdk.display(data.block_time)
    }
  end
end
