namespace :deploy do
  ############################################################################
  # Mongrel Tasks
  ############################################################################
  set(:mongrel_conf) { "#{current_path}/config/mongrel_cluster.yml" }
  namespace :mongrel do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the mongrel appserver"
      task t, :roles => :app do
        invoke_command "mongrel_rails cluster::#{t.to_s} -C #{mongrel_conf}", :via => run_method
      end
    end
  end
  
end