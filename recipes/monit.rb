namespace :deploy do
  namespace :monit do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the monit appserver"
      task t, :roles => :app do
        invoke_command "/etc/init.d/monit #{t.to_s}", :via => run_method
      end
    end
  end
end