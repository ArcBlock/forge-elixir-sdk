defimpl ForgeSdk.Display, for: Google.Protobuf.Timestamp do
  @moduledoc """
  Implementation of `Display` protocol for `Timestamp`
  """

  alias ForgeSdk.DateTimeUtils

  def display(%{seconds: seconds}, expand? \\ false) do
    dt =
      case DateTime.from_unix(seconds) do
        {:ok, date} -> date
        _ -> DateTime.from_unix!(0)
      end

    case expand? do
      true -> DateTimeUtils.format_date(dt)
      _ -> dt
    end
  end
end

defimpl ForgeSdk.Display, for: DateTime do
  @moduledoc """
  Implementation of `Display` protocol for `Timestamp`
  """

  alias ForgeSdk.DateTimeUtils

  def display(data, true), do: DateTimeUtils.format_date(data)
  def display(data, _), do: data
end

defmodule ForgeSdk.DateTimeUtils do
  @moduledoc """
  Convert date time to human readable formation
  """

  @min 60
  @hour @min * 60
  @day @hour * 24

  def format_date(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime)

    cond do
      diff < 0 -> DateTime.to_string(datetime)
      diff < @min -> "#{seconds(diff)} seconds ago"
      diff < @hour -> "#{minutes(diff)} minutes #{seconds(diff)} seconds ago"
      diff < @day -> "#{hours(diff)} hours #{minutes(diff)} minutes ago"
      diff < @day * 30 -> "#{days(diff)} days #{hours(diff)} ago"
      true -> DateTime.to_string(datetime)
    end
  end

  defp days(seconds), do: div(seconds, @day)
  defp hours(seconds), do: seconds |> rem(@day) |> div(@hour)
  defp minutes(seconds), do: seconds |> rem(@hour) |> div(@min)
  defp seconds(seconds), do: rem(seconds, @min)
end
