# Unicorn configuration for the containerized clinic-day deployment.
#
# Why unicorn instead of `rails server`: on Rails 4.1 with no puma or thin in
# the Gemfile, `rails server` falls back to WEBrick, which serves exactly one
# request at a time -- every clinic station queues behind every other one.
#
# Why processes and not threads: in development mode cache_classes is false, so
# Rails inserts Rack::Lock (railties-4.1.16 default_middleware_stack.rb:29).
# That lock is a per-process mutex, so threads would just serialize behind it.
# Separate worker processes each get their own, and run genuinely in parallel.
#
# The older config/unicorn.rb is the Capistrano-era one and still points at
# /home/deploy/momma; it is not used by the container.

worker_processes Integer(ENV.fetch("WEB_CONCURRENCY", 4))

working_directory "/root/app"

# nginx reaches this over app-network, so bind all interfaces.
listen "0.0.0.0:3000", :backlog => 64

# Chart PDF rendering (prawn) is the slowest request; give it room.
timeout 60

pid "/root/app/tmp/pids/unicorn.pid"

# Log to the container's stdout/stderr so `docker compose logs -f web` works.
stderr_path "/dev/stderr"
stdout_path "/dev/stdout"

# preload_app is deliberately off. Development mode reloads code per request,
# and a non-preloaded worker owns its database connection from boot, so there
# is no fork-time ActiveRecord reconnect dance to get wrong on the day.
preload_app false
