import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :frontend, FrontendWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MEb2mlndqguKdHN5zhMgqAXV4fq7t6OE7+Dl+T7OIbxJKqPH/zwBViHF84WEuFz3",
  server: false

# In test we don't send emails
config :frontend, Frontend.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, ApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "KdH0rpRrzeJUnKOuazekipA3QQQN/n8ytV/jA1+1N5/vhZcfncaXXG78V3s66N4B",
  server: false

# In test we don't send emails
config :api, Api.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
