use Mix.Config

config :forge_sdk,
  env: Mix.env(),
  config_priorities: [:env, :home, :cwd, :priv]
