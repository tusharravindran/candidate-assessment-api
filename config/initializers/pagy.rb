require 'pagy/backend'
require 'pagy/frontend'
require 'pagy/extras/items'    # allows per_page/limit param from request
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items]       = 20         # default page size
Pagy::DEFAULT[:items_param] = :per_page  # frontend/tests send per_page=N
Pagy::DEFAULT[:max_items]   = 200        # allow per_page=100 from frontend
Pagy::DEFAULT[:overflow]    = :last_page
