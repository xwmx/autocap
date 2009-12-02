##############################################################################
# DB Tasks
##############################################################################

namespace :db do
  desc "Start the mysql db server"
  task :start_mysql, :roles => :db do
    run "sudo mysqld_safe &"
  end
  
  desc "Setup the database"
  task :create, :role => :db do
    run "cd #{current_path} && rake db:create RAILS_ENV=#{rails_env.to_s}"
  end
  
  desc "Drop the database"
  task :drop, :role => :db do
    run "cd #{current_release} && rake RAILS_ENV=#{rails_env.to_s} db:drop"
  end
  
  desc "Migrate"
  task :migrate, :roles => :db do
    run "cd #{current_release}; sudo rake RAILS_ENV=#{rails_env.to_s} db:migrate"
  end
  
  desc "Run script/dbconsole"
  task :console, :roles => :app do
    input = ''
    run "cd #{current_path} && sudo ./script/dbconsole #{rails_env.to_s}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end
end