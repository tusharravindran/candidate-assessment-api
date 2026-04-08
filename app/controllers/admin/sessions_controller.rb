class Admin::SessionsController < Devise::SessionsController
  # RailsAdmin uses the standard Devise HTML session flow.
  # This controller inherits default Devise behavior — just ensures
  # we don't pull in any API-only concerns.
end
