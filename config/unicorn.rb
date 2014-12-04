require "yaml"
RAILS_ROOT   = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
RAILS_ENV    = ENV['RAILS_ENV'] || 'development'
CONFIG       = YAML.load_file(RAILS_ROOT + "/config/unicorn.yml")[RAILS_ENV]

worker_processes CONFIG["worker_processes"]
preload_app true
timeout 60
listen CONFIG["listen"], :backlog => 64

pid "#{RAILS_ROOT}/tmp/pids/unicorn.pid"

stderr_path "#{RAILS_ROOT}/log/unicorn.log"
stdout_path "#{RAILS_ROOT}/log/unicorn.log"

preload_app true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH

    end
  end
end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{RAILS_ROOT}/Gemfile"
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
