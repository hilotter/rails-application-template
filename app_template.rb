#
# Rails Application Template
#

repo_url = 'https://raw.githubusercontent.com/hilotter/rails-application-template/master'
gems = {}

# gems
# ==================================================
comment_lines 'Gemfile', "gem 'spring'"
uncomment_lines 'Gemfile', "gem 'unicorn'"
uncomment_lines 'Gemfile', "gem 'therubyracer'"

gem_group :test, :development do
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'guard-rspec', require: false
  gem 'bullet'
  gem 'rack-mini-profiler', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'rails-erd'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'simplecov', require: false
  gem 'simplecov-rcov', require: false
  gem 'fuubar'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'faker'
  gem 'faker-japanese'
  gem 'timecop'
  gem 'brakeman', require: false
  gem 'rails_best_practices'
end

gem_group :development do
  gem 'capistrano', '~> 3.2.1', require: false
  gem 'capistrano-rails',       require: false
  gem 'capistrano-rbenv',       require: false
  gem 'capistrano-bundler',     require: false
  gem 'capistrano3-unicorn',    require: false
end

gem 'annotate'
gem 'config'
gems['bootstrap'] = yes?('create mock ? (bootstrap)')
if gems['bootstrap']
  gem 'simple_form'
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
end

gems['slim-rails'] = yes?('use slim ?')
if gems['slim-rails']
  gem 'slim-rails'
end

gems['twitter'] = yes?('use twitter login ?')
if gems['twitter']
  gem 'omniauth'
  gem 'omniauth-twitter'

  if yes?('use twitter api ?')
    gem 'twitter'
  end
end

gems['facebook'] = yes?('use facebook login ?')
if gems['facebook']
  gem 'omniauth'
  gem 'omniauth-facebook'

  if yes?('use facebook api?')
    gem 'koala'
  end
end

if yes?('use carrierwave ?')
  gem 'carrierwave'
  gem 'fog'
  gem 'rmagick', :require => false
end

gems['activeadmin'] = yes?('use activeadmin ?')
if gems['activeadmin']
  gem 'devise'
  gem 'activeadmin', github: 'activeadmin'
end

gems['whenever'] = yes?('use whenever ?')
if gems['whenever']
  gem 'whenever'
end

gems['sidekiq'] = yes?('use sidekiq ?')
if gems['sidekiq']
  gem "sidekiq"
  gem "sidekiq-unique-jobs"
end

if yes?('use nokogiri ?')
  gem 'nokogiri'
end

if yes?('use kaminari ?')
  gem 'kaminari'
end

if yes?('use jpmobile ?')
  gem 'jpmobile'
end

if yes?('use bulk insert ?')
  gem "activerecord-import"
end

if yes?('bundle install to vendor/bundler?')
  run 'bundle install -j4 --path=vendor/bundler'
else
  run 'bundle install -j4'
end

# setting bootstrap
# ==================================================
if gems['bootstrap']
  generate('simple_form:install --bootstrap')
  generate('bootstrap:install static')
  generate('bootstrap:layout application fluid')
end

# general settings
# ==================================================
run 'cp config/database.yml config/database.yml.sample'

# refs http://qiita.com/hnakamur/items/762db1a764fcf3583214
gsub_file 'config/database.yml', /^  encoding: utf8$/, "\\0\n  collation: utf8_general_ci"

if yes?('create home controller ?')
  generate(:controller, 'home index')
  route "root to: 'home#index'"
end

if yes?('create api application controller ?')
  generate(:controller, 'api::application')
end

# setting env
# ==================================================
application_setting = <<-CODE
config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    I18n.enforce_available_locales = false
    config.i18n.default_locale = :ja

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end
CODE
environment application_setting

if gems['slim-rails']
  slim_application_setting = <<-CODE
    config.generators.template_engine = :slim
  CODE
  environment slim_application_setting
end

bullet_setting = <<-CODE
config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
CODE
environment bullet_setting, env: 'development'

# setting annotate
# ==================================================
generate('annotate:install')

# setting unicorn
# ==================================================
get "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'
get "#{repo_url}/config/unicorn.yml", 'config/unicorn.yml'

# setting rspec
# ==================================================
generate 'rspec:install'
run 'bundle exec guard init rspec'
run 'rm -rf test'
uncomment_lines 'spec/rails_helper.rb', /Dir\[Rails\.root\.join/
get "#{repo_url}/spec/support/factory_girl.rb", 'spec/support/factory_girl.rb'
get "#{repo_url}/spec/support/database_cleaner.rb", 'spec/support/database_cleaner.rb'

# setting rails_config
# ==================================================
generate('rails_config:install')
rails_config = ''
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
  permissions:
    required: []
    optional: []
CODE
end
file 'config/settings.yml', rails_config

# setting omniauth
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
  facebook_permissions = Settings.facebook.permissions.required + Settings.facebook.permissions.optional
  provider :facebook, Settings.facebook.app_id, Settings.facebook.app_secret,
           :scope => facebook_permissions.join(','),
           :locale => 'ja_JP'
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
  route "get 'auth/failure' => 'session#failure'"
end

# setting whenever
# ==================================================
if gems['whenever']
  run 'bundle exec wheneverize'
end

# setting capistrano
# ==================================================
run 'bundle exec cap install STAGES=staging,production'

# setting .gitignore
# ==================================================
gitignore = <<-CODE
db/schema.rb
vendor/bundler
coverage
config/database.yml
public/uploads
.rubocop.yml
.DS_Store
Gemfile.lock.tags
tags
CODE
File.open('.gitignore', 'a') do |file|
  file.write gitignore
end

if yes?('run migrate ?')
  rake "db:create"
  rake "db:migrate"
end
