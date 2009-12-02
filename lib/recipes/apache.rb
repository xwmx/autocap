namespace :deploy do
  ############################################################################
  # Apache Tasks
  ############################################################################
  
  namespace :apache do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} apache"
      task t, :roles => :app do
        send(run_method, "apache2ctl #{t.to_s}")
      end
    end
  end
end