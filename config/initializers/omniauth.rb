OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.full_host = Rails.env.production? ? "https://[ADD-HEROKU-APPNAME].herokuapp.com" : "http://localhost:3000"
