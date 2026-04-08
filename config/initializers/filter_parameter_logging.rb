# Configure parameters that should be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :current_password,
  :token,
  :authorization
]
