#
# Rails Application Template
#

repo_url = "https://raw2.github.com/hilotter/rails-application-template/master"
gems = {}

# gems
# ==================================================
gem_group :test, :development do
  gem "pry-rails"
  gem "rails-erd"
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end

gem 'settingslogic'
uncomment_lines 'Gemfile', "gem 'unicorn'"

if yes?('create mock?(bootstrap)')
  gem 'simple_form'
  uncomment_lines 'Gemfile', "gem 'therubyracer'"
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
end

gems['twitter'] = yes?("use twitter login?")
if gems['twitter']
  gem 'omniauth'
  gem 'omniauth-twitter'

  if yes?("use twitter api?")
    gem 'twitter'
  end
end

gems['facebook'] = yes?("use facebook login?")
if gems['facebook']
  gem 'omniauth'
  gem 'omniauth-facebook'

  if yes?("use facebook api?")
    gem 'koala'
  end
end

if yes?("use carrierwave ?")
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
generate(:controller, "base")
generate(:controller, "api::base")

# install spec_helper.rb
# ==================================================
generate "rspec:install"
run "rm -rf test"

# add settingslogic config
# ==================================================
if gems['twitter'] && gems['facebook']
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
elsif gems['twitter']
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
elsif gems['facebook']
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
if gems['twitter'] && gems['facebook']
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
    provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret
  end
CODE
elsif gems['twitter']
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, Settings.twitter.consumer_key, Settings.twitter.consumer_secret
  end
CODE
elsif gems['facebook']
initializer 'omniauth.rb', <<-CODE
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret
  end
CODE
end

# setting omniauth
# ==================================================
if gems['twitter'] || gems['facebook']
generate(:controller, "sessions")
route "get '/auth/:provider/callback', :to => 'sessions#callback'"
route "post '/auth/:provider/callback', :to => 'sessions#callback'"
route "get '/logout' => 'sessions#destroy', :as => :logout"
end

# setting whenever
# ==================================================
if gems['whenever']
  run "bundle exec wheneverize"
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
vendor/bundler
coverage
CODE

