# -- Veil Configuration    Don't remove this line
config :veil,
  site_name: "Your Website Name",
  email_from_name: "Your Name",
  email_from_address: "yourname@example.com",
  sign_in_link_expiry: 12 * 3_600, # How long should emailed sign-in links be valid for?
  session_expiry: 86_400 * 30, # How long should sessions be valid for?
  refresh_expiry_interval: 86_400,  # How often should existing sessions be extended to session_expiry
  sessions_cache_limit: 250, # How many recent sessions to keep in cache (to reduce database operations)
  users_cache_limit: 100 # How many recent users to keep in cache

config :veil, Veil.Scheduler,
  jobs: [
    # Runs every midnight to delete all expired requests and sessions
    {"@daily", {<%= main_module %>.Veil.Clean, :expired, []}}
  ]

config :veil, <%= web_module %>.Veil.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your-api-key"

# -- End Veil Configuration
