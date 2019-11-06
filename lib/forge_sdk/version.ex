defmodule ForgeSdk.Version do
  @moduledoc """
  Check if forge version is upgradable
  """

  @doc """
  Check if the version being upgraded is valid or not.
  * :match - could upgrade without sending UpgradeNodeTx
  * :allow - allow upgrade
  * :deny - do not allow upgrade
  * :invalid - the new version is not a valid version

  Examples:

    iex> ForgeSdk.Version.check("0.1.0", "0.1.100")
    :allow

    iex> ForgeSdk.Version.check("1.2.0", "1.2.100-p3")
    :allow

    iex> ForgeSdk.Version.check("1.2.2", "1.2.1-p3")
    :deny

    iex> ForgeSdk.Version.check("0.5.0", "0.5.0-p2")
    :match

    iex> ForgeSdk.Version.check("1.2.3-p50", "1.2.3-p2")
    :match

    iex> ForgeSdk.Version.check("1.1.1", "1.2.1")
    :deny

    iex> ForgeSdk.Version.check("1.1.1", "1.2.1-p1")
    :deny

    iex> ForgeSdk.Version.check("1.1.1", "1.2.0")
    :allow

    iex> ForgeSdk.Version.check("1.2.100-p1", "1.3.0")
    :allow

    iex> ForgeSdk.Version.check("2.3.0", "3.0.1")
    :deny

    iex> ForgeSdk.Version.check("2.3.0", "3.1.0")
    :deny

    iex> ForgeSdk.Version.check("2.3.0", "3.1.1")
    :deny

    iex> ForgeSdk.Version.check("2.3.0", "3.0.0-p1")
    :allow

    iex> ForgeSdk.Version.check("2.3.0", "3.0.0")
    :allow

    iex> ForgeSdk.Version.check("4.0.0", "3.0.0")
    :deny
  """
  def check(old, new) do
    [ov1, ov2, ov3, _op] = normalize_version(old)
    [nv1, nv2, nv3, _np] = normalize_version(new)

    cond do
      # same consensus version. OK to upgrade without sending UpgradeNodeTx.
      ov1 == nv1 and ov2 == nv2 and ov3 == nv3 -> :match
      # different MR release of same FR. Allow to upgrade.
      ov1 == nv1 and ov2 == nv2 and ov3 < nv3 -> :allow
      # different FR. Only allow to ugprade with consequent FR.
      ov1 == nv1 and ov2 + 1 == nv2 and nv3 == 0 -> :allow
      # different major release. Only allow to upgrade with consequent major release. User must make sure they have already upgraded to the last FR.
      ov1 + 1 == nv1 and nv2 == 0 and nv3 == 0 -> :allow
      true -> :deny
    end
  rescue
    _ -> :invalid
  end

  # private functions
  defp normalize_version(version) do
    [v, p] =
      case String.split(version, "-") do
        [v] -> [v, ""]
        [v, p] -> [v, p]
        _ -> raise "Invalid version"
      end

    [v1, v2, v3] =
      case String.split(v, ".") do
        [v1, v2, v3] -> [String.to_integer(v1), String.to_integer(v2), String.to_integer(v3)]
        _ -> raise "Invalid version"
      end

    [v1, v2, v3, p]
  end
end
