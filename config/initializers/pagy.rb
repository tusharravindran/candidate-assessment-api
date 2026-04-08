require 'pagy/backend'
require 'pagy/frontend'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:limit]    = 20
Pagy::DEFAULT[:overflow] = :last_page
