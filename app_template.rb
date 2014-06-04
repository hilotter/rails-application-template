#
# Rails Application Template
#

repo_url = 'https://raw.githubusercontent.com/hilotter/rails-application-template/master'
gems = {}

# gems
# ==================================================
gem_group :test, :development do
  gem 'pry-rails'
  gem 'rails-erd'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end

gem_group :test do
  gem 'fuubar'
  gem 'faker'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
end

gem_group :development do
  gem 'bullet'
  gem 'rack-mini-profiler'
end

gem 'rails_config'
uncomment_lines 'Gemfile', "gem 'unicorn'"
gem 'execjs'
uncomment_lines 'Gemfile', "gem 'therubyracer'"
gem 'god', require: false
uncomment_lines 'Gemfile', "gem 'capistrano'"

if yes?('create mock?(bootstrap)')
  gem 'simple_form'
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
end

gems['twitter'] = yes?('use twitter login?')
if gems['twitter']
  gem 'omniauth'
  gem 'omniauth-twitter'

  if yes?('use twitter api?')
    gem 'twitter'
  end
end

gems['facebook'] = yes?('use facebook login?')
if gems['facebook']
  gem 'omniauth'
  gem 'omniauth-facebook'

  if yes?('use facebook api?')
    gem 'koala'
  end
end

if yes?('use carrierwave ?')
  gem 'carrierwave'
  gem 'rmagick', :require => false
end

gems['whenever'] = yes?('use whenever?')
if gems['whenever']
  gem 'whenever'
end

if yes?('use nokogiri?')
  gem 'nokogiri'
end

if yes?('use kaminari?')
  gem 'kaminari'
end

if yes?('use jpmobile?')
  gem 'jpmobile'
end

gems['redis'] = yes?('use redis?')
if gems['redis']
    gem 'redis'

    gems['redis-rails'] = yes?('use redis-rails? (redis session)')
    if gems['redis-rails']
      gem 'redis-rails'
    end
end

if yes?('bundle install to vendor/bundler?')
run 'bundle install -j5 --path=vendor/bundler'
else
run 'bundle install -j5'
end

# generate base_controller
# ==================================================
generate(:controller, 'api::application')

# install spec_helper.rb
# ==================================================
generate 'rspec:install'
run 'rm -rf test'

# add rails_config
# ==================================================
generate('rails_config:install')
rails_config = <<-CODE
s3:
  bucket: <bucket>
  endpoint_url: <s 3url>
cloud_front:
  endpoint_url: <cl url>
use_cloud_front: false
CODE
if gems['twitter']
  rails_config.concat <<-CODE
twitter:
  consumer_key: <CONSUMER KEY>
  consumer_secret: <CONSUMER SECRET>
CODE
end
if gems['facebook']
  rails_config.concat <<-CODE
facebook:
  app_id: <APP ID>
  app_secret: <APP SECRET>
CODE
end
file 'config/settings.yml', rails_config

# add omniauth config
# ==================================================
omniauth = ''
if gems['twitter']
  omniauth.concat <<-CODE
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
end
CODE
end
if gems['facebook']
  omniauth.concat <<-CODE
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret
end
CODE
end
if gems['twitter'] || gems['facebook']
  omniauth.concat <<-CODE
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
CODE
  initializer 'omniauth.rb', omniauth
end

# setting omniauth
# ==================================================
if gems['twitter'] || gems['facebook']
generate(:model, 'user provider:string uid:string name:string')
generate(:controller, 'sessions')
remove_file 'app/models/user.rb'
get "#{repo_url}/app/models/user.rb", 'app/models/user.rb'
remove_file 'app/controllers/sessions_controller.rb'
get "#{repo_url}/app/controllers/sessions_controller.rb", 'app/controllers/sessions_controller.rb'
route "get '/auth/:provider/callback', :to => 'sessions#callback'"
route "post '/auth/:provider/callback', :to => 'sessions#callback'"
route "get '/logout' => 'sessions#destroy', :as => :logout"
end

# setting whenever
# ==================================================
if gems['whenever']
  run 'bundle exec wheneverize'
end

# helpers
# ==================================================
remove_file 'app/helpers/application_helper.rb'
get "#{repo_url}/app/helpers/application_helper.rb", 'app/helpers/application_helper.rb'

# setting .gitignore
# ==================================================
gitignore = <<-CODE
db/schema.rb
vendor/bundler
coverage
CODE
File.open('.gitignore', 'a') do |file|
  file.write gitignore
end

