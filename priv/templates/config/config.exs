# -- Veil Configuration    Don't remove this line
config :veil,
  site_name: "Your Website Name",
  email_from_name: "Your Name",
  email_from_address: "yourname@example.com",
  sign_in_link_expiry: 3_600,
  session_expiry: 86_400 * 30,
  refresh_expiry_interval: 86_400

config :veil,Veil.Scheduler,
  jobs: [
    # Runs every midnight to delete all expired requests and sessions
    {"@daily", {<%= main_module %>.Veil.Clean, :expired, []}}
  ]

config :veil, <%= web_module %>.Veil.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your-api-key"

# -- End Veil Configuration
