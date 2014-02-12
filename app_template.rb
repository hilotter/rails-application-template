def echo(text); run "echo #{text}"; end
is_twitter = false
is_facebook = false
is_whenever = false

# gems
# ==================================================
echo "Add gem file"

gem_group :test, :development do
  gem "pry-rails"
  gem "rails-erd"
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end

gem 'settingslogic'

if yes?('create mock?(bootstrap)')
  gem 'simple_form'
  gem 'therubyracer'
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
end

if yes?("use twitter login?")
  is_twitter = true
  gem 'omniauth'
  gem 'omniauth-twitter'
end

if yes?("use twitter api?")
  gem 'twitter'
end

if yes?("use facebook login?")
  is_facebook = true
  gem 'omniauth'
  gem 'omniauth-facebook'
end

if yes?("use facebook api?")
  gem 'koala'
end

if yes?("use carrierwave ?")
  gem 'carrierwave'
  gem 'rmagick', :require => false
end

if yes?('use cron?')
  is_whenever = true
  gem 'whenever'
end

if yes?('use nokogiri?')
  gem 'nokogiri'
end

if yes?('use kaminari?')
  gem 'kaminari'
end

if yes?("use jpmobile?")
  gem 'jpmobile'
end

run "bundle install -j5 --path=vendor/bundler"

# generate base_controller
# ==================================================
generate(:controller, "base")
generate(:controller, "api::base")

# install spec_helper.rb
# ==================================================
generate "rspec:install"
run "rm -rf test"

# add settingslogic config
# ==================================================
if is_twitter && is_facebook
file 'config/settings.yml', <<-CODE
  defaults: &defaults
    twitter:
      consumer_key: <CONSUMER KEY>
      consumer_secret: <CONSUMER SECRET>>
    facebook:
      app_id: <APP ID>
      app_secret: <APP SECRET>>
  
  development:
    <<: *defaults
  
  test:
    <<: *defaults
  
  production:
    <<: *defaults
CODE
elsif is_twitter
file 'config/settings.yml', <<-CODE
  defaults: &defaults
    twitter:
      consumer_key: <CONSUMER KEY>
      consumer_secret: <CONSUMER SECRET>>
  
  development:
    <<: *defaults
  
  test:
    <<: *defaults
  
  production:
    <<: *defaults
CODE
elsif is_facebook
file 'config/settings.yml', <<-CODE
  defaults: &defaults
    facebook:
      app_id: <APP ID>
      app_secret: <APP SECRET>>
  
  development:
    <<: *defaults
  
  test:
    <<: *defaults
  
  production:
    <<: *defaults
CODE
else
file 'config/settings.yml', <<-CODE
  defaults: &defaults
  
  development:
    <<: *defaults
  
  test:
    <<: *defaults
  
  production:
    <<: *defaults
CODE
end

initializer '0_settings.rb', <<-CODE
  class Settings < Settingslogic
    source "#\{Rails.root\}/config/settings.yml"
    namespace Rails.env
  end
CODE

# add omniauth config
# ==================================================
if is_twitter && is_facebook
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
    provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret
  end
CODE
elsif is_twitter
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
  end
CODE
elsif is_facebook
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret
  end
CODE
end

# setting whenever
# ==================================================
if is_whenever
  run "bundle exec wheneverize"
end

# setting omniauth
# ==================================================
if is_twitter || is_facebook
generate(:controller, "sessions")
route "get '/auth/:provider/callback', :to => 'sessions#callback'"
route "post '/auth/:provider/callback', :to => 'sessions#callback'"
route "get '/logout' => 'sessions#destroy', :as => :logout"
end

# setting .gitignore
# ==================================================
file '.gitignore', <<-CODE
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
db/schema.rb
vendor/bundle
coverage
CODE


