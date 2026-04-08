source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem 'rails', '~> 7.1.0'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.4'
gem 'rack-cors'
gem 'devise'
gem 'devise-jwt'
gem 'aasm'
gem 'sidekiq', '~> 7.2'
gem 'redis', '>= 4.0.1'
gem 'connection_pool', '~> 2.4'  # 3.x changed pop() signature; incompatible with sidekiq 7.3 scheduler
gem 'pundit'
gem 'blueprinter'
gem 'pagy', '~> 8.4'
gem 'elasticsearch-model', '~> 7.2'
gem 'elasticsearch-rails', '~> 7.2'
gem 'elasticsearch', '>= 7.13.0', '< 7.14'  # 7.14+ rejects OpenSearch (Bonsai)
gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', require: false
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'jwt'

# Platform admin UI
gem 'rails_admin', '~> 3.1'
gem 'sprockets-rails'
gem 'sassc-rails'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
end
