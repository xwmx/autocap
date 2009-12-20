##############################################################################
# System tasks
##############################################################################

namespace :sys do
  namespace :tail do
    desc "Runs tail -f on the rails log"
    task :rails, :roles => :app do 
      stream "tail -n 300 -f #{shared_path}/log/#{rails_env.to_s}.log#{ENV['last'] ? '.1' : ''}" 
    end
  
    desc "Runs tail -f on a mongrel log. Specify which one with p=n where n is the port"
    task :mongrel, :roles => :app do
      unless ENV['p']
        puts "\nError: Must specify port with p=port_number\n\n"
      else
        stream "tail -n 300 -f #{shared_path}/log/mongrel.#{ENV['p']}.log#{ENV['last'] ? '.1' : ''}"
      end
    end
    
    desc <<-DESC
      Runs tail -f on a log relative to /var/log specified by \
      log=path/to/log and options with args=arguments
    DESC
    task :log, :roles => :app do
      unless ENV['log']
        puts "\nError: Must specify log with log=path/to/log\n\n"
      else
        stream "cd /var/log; sudo tail #{ENV['args'] || '-n 300 -f'} #{ENV['log']}"
      end
    end
  end
  
  desc "Runs free -m. use s=n to stream with n interval"
  task :free, :roles => :app do
    ENV['s'] ? stream("free -m -s #{ENV['s']}") : run("free -m")
  end
  
  desc "Runs df -h or df with arguments using args=arguments"
  task :df, :roles => :app do
    run "df #{ENV['args'] || '-h'}"
  end
  
  
  desc <<-DESC
    Runs du -h --max-depth=1 on a dir *relative to #{deploy_to}* using \
    path=path/to/dir or df with arguments using args=arguments
  DESC
  task :du, :roles => :app do
    if ENV['args']
      invoke_command "du #{ENV['args']}"
    else
      path = (ENV['path'] || '').gsub(/^\//,'')
      invoke_command "cd #{deploy_to}/#{path}; du --max-depth=1 . | sort -nr | cut -f 2- | while read a; do du -sh \"$a\"; done"
    end
  end
  
  desc "Runs ls -lah on a dir *relative to #{deploy_to}* using path=path/to/dir or ls with argument using args=arguments"
  task :ls, :roles => :app do
    if ENV['args']
      invoke_command "ls #{ENV['args']}"
    else
      path = (ENV['path'] || '').gsub(/^\//,'')
      invoke_command "cd #{deploy_to}/#{path}; ls -lah"
    end
  end
  
  desc "Runs 'ps ax | egrep process_name'. Use p=process_name"
  task :ps_grep, :roles => :app do
    unless ENV['p']
      puts "\nError: Please provide a process name using p=process_name"
    else
      invoke_command "ps axu | egrep \"PID|#{ENV['p']}\""
    end
  end
  
  desc "Runs ps with arguments using args=arguments"
  task :ps, :roles => :app do
    unless ENV['args']
      puts "\nError: Please provide arguments using args=arguments"
    else
      invoke_command "ps #{ENV['args']}"
    end
  end
  
  desc "Runs vmstat with arguments using args=arguments"
  task :vmstat, :roles => :app do
    invoke_command "vmstat #{ENV['args']}"
  end
  
  desc "Runs 'kill pid'. Use pid=process_id to specify pid and options= to specify options"
  task :kill, :roles => :app do
    unless ENV['pid']
      puts "\nError: Please provide a pid using pid=process_id"
    else
      invoke_command "kill #{ENV['options'] || '' } #{ENV['pid']}"
    end
  end
  
  desc "Removes a file at a path specified by path= and options specified by options="
  task :rm, :roles => :app do
    unless ENV['path']
      puts "\nError: Please provide a path using path=/path/to/delete"
    else
      invoke_command "sudo rm #{ENV['options'] || '' } #{ENV['path']}"
    end
  end
end