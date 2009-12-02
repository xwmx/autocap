namespace :deploy do
  ############################################################################
  # Nginx Tasks
  ############################################################################
  
  namespace :nginx do
    [ :stop, :start ].each do |t|
      desc "#{t.to_s.capitalize} nginx"
      task t, :roles => :app do
        send(run_method, "/etc/init.d/nginx #{t.to_s}")
      end
    end
    desc "restart nginx"
    task :restart, :roles => :app do
      send(run_method, "/etc/init.d/nginx stop")
      send(run_method, "/etc/init.d/nginx start")
    end
  end
end