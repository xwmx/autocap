namespace :deploy do
  namespace :passenger do
    ############################################################################
    # Passenger Restart Tasks
    ############################################################################
    desc "Restarting mod_rails with restart.txt"
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end
  end
end