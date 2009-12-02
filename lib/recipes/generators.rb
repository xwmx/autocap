require 'aws/s3'

set(:templates_dir) {File.join(File.dirname(__FILE__), '..', 'templates')}
set(:rails_root) {File.join(File.dirname(__FILE__), "..", "..", "..", "..", "..")}
set(:mongrel_config) do
  if File.exist?(File.join(rails_root, "config", "staged_mongrel_cluster.yml"))
    YAML::load_file(File.join(rails_root, "config", "staged_mongrel_cluster.yml"))[rails_env.to_s]
  else
    YAML::load_file File.join(templates_dir, "mongrel_cluster.yml")
  end
end


##############################################################################
# Generators
##############################################################################

namespace :generate do
  
  namespace :app do
    desc <<-DESC
      Generates a new config.yml. Takes an optional #{application.upcase}_APP_EMAIL_PASSWORD \
      environment variable or will prompt for input. Example usage:
      
      $ cap staging app=my_app generate:app:config \\
            #{application.upcase}_APP_EMAIL_PASSWORD=some_pass
    DESC
    task :config, :roles => :db do
      set(:app_config_install_path) { "#{shared_path}/config/config.yml" }
      
      require "yaml"
      app_config = YAML::load_file('config/config.yml')
      set :default_mail_pass, ENV["#{application.upcase}_APP_EMAIL_PASSWORD"] || 
            proc { Capistrano::CLI.password_prompt("Default mail user password for application: ") }
      
      app_config[rails_env.to_s]['domain'] = domain
      app_config[rails_env.to_s]['mail_user_password'] = default_mail_pass

      put YAML::dump(app_config), "#{app_config_install_path}", :mode => 0664
    end
  end
  
  

  
  namespace :db do
    task :mysql, :roles => :db do
      set(:db_adapter) { "mysql" }
      generate.db.config
    end

    task :postgresql, :roles => :db do
      set(:db_adapter) { "postgresql" }
      generate.db.config
    end
    
    desc <<-DESC
      Generates a new database.yml. Takes an optional #{application.upcase}_DB_PASSWORD \
      environment variable or will prompt for input. Example usage:
      
      $ cap staging app=my_app generate:db:config \\
            #{application.upcase}_DB_PASSWORD=some_pass
    DESC
    task :config, :roles => :db do
      set(:db_config_install_path) { "#{shared_path}/config/database.yml" }
      
      require "yaml"
      set(:database_password) { ENV["#{application.upcase}_DB_PASSWORD"] || Capistrano::CLI.password_prompt("#{rails_env.to_s.capitalize} database remote Password : ") }

      buffer = YAML::load_file(File.join(templates_dir, "database.example.yml"))
      # get rid of uneeded configurations
      buffer.delete('test')
      buffer.delete('development')
      (['staging', 'production', 'defaults', 'demo'] - [rails_env.to_s]).each {|stage| buffer.delete(stage) }

      # Populate production element
      buffer[rails_env.to_s]['adapter']   = db_adapter || "mysql"
      buffer[rails_env.to_s]['database']  = "#{application}_#{stage}"
      buffer[rails_env.to_s]['username']  = "deploy"
      buffer[rails_env.to_s]['password']  = database_password
      buffer[rails_env.to_s]['host']      = "localhost"

      put YAML::dump(buffer), "#{db_config_install_path}", :mode => 0664
    end
  end
  
  namespace :monit do
    namespace :config do
      desc <<-DESC
        Generates a monit config for this application. Requires an existing \
        monitrc.erb template. Takes an optional #{application.upcase}_MONIT_EMAIL_PASSWORD  \
        environment variable or will prompt for input. Example usage:
        
        $ cap staging app=my_app generate:monit:config:system \\
              #{application.upcase}_MONIT_EMAIL_PASSWORD=some_pass
      DESC
      task :sys, :roles => :web do
        set :monit_sys_config_install_path, "/etc/monit/monitrc"
        set :monitrc_mail_user_email, "monit@#{domain}"
        set :monitrc_alert_email_recipient, "admin@#{domain}"
        set(:monitrc_mail_password) { ENV["#{application.upcase}_MONIT_EMAIL_PASSWORD"] || 
              proc { Capistrano::CLI.password_prompt("#{application.to_s} #{rails_env.to_s} monitrc mail password: ") } }
        set(:monitrc_web_user) { ENV["#{application.upcase}_MONIT_WEB_USER"] || 
              proc { Capistrano::CLI.password_prompt("#{application.to_s} #{rails_env.to_s} monitrc web user: ") } }
        set(:monitrc_web_password) { ENV["#{application.upcase}_MONIT_WEB_PASSWORD"] || 
              proc { Capistrano::CLI.password_prompt("#{application.to_s} #{rails_env.to_s} monitrc web password: ") } }
              
        template = File.read(File.join(templates_dir, "monit", "monitrc.erb"))
        result = ERB.new(template).result(binding)
        
        install_processed_template(result, "#{monit_sys_config_install_path}", :mode => '0600')
      end
      
      desc <<-DESC
        Generates a monit mongrel config for this application. Requires an existing \
        monit mongrel.erb template. Example usage:
        
        $ cap staging app=my_app generate:monit:config:mongrel
      DESC
      task :mongrel, :roles => :app do
        set :monit_mongrel_config_install_path, "/etc/monit.d/#{application}_#{stage}_mongrel"
        
        set :mongrel_start_port, (mongrel_config['port'].to_i)
        set :mongrel_end_port, (mongrel_config['port'].to_i + (mongrel_config['servers'].to_i - 1))
              
        template = File.read(File.join(templates_dir, "monit", "mongrel.erb"))
        result = ERB.new(template).result(binding)
        install_processed_template(result, "#{monit_mongrel_config_install_path}", :mode => '0600')
      end
      
      desc <<-DESC
        Generates a monit mongrel config for this application. Requires an existing \
        monit mongrel.erb template. Example usage:
        
        $ cap staging app=my_app generate:monit:config:mongrel
      DESC
      task :subdomain_mongrel, :roles => :app do
        set :monit_mongrel_config_install_path, "/etc/monit.d/#{application}_#{stage}_mongrel"
        
        set :mongrel_start_port, (mongrel_config['port'].to_i)
        set :mongrel_end_port, (mongrel_config['port'].to_i + (mongrel_config['servers'].to_i - 1))
              
        template = File.read(File.join(templates_dir, "monit", "subdomain_mongrel.erb"))
        result = ERB.new(template).result(binding)
        install_processed_template(result, "#{monit_mongrel_config_install_path}", :mode => '0600')
      end
      
      desc <<-DESC
        Generates a monit nginx config for this application. Requires an existing \
        nginx template. Example usage:
        
        $ cap staging app=my_app generate:monit:config:nginx
      DESC
      task :nginx, :roles => :web do
        set :monit_nginx_config_install_path, "/etc/monit.d/#{application}_#{stage}_nginx"
        
        template = File.read(File.join(templates_dir, "monit", "nginx.erb"))
        result = ERB.new(template).result(binding)
        install_processed_template(result, "#{monit_nginx_config_install_path}", :mode => '0600')
      end
    end
  end
  
  
  namespace :mongrel do
    desc <<-DESC
      Generates a new mongrel_cluster.yml for a specified environment. Assumes
      an existing template file exists.
    DESC
    task :config, :roles => :app do
      
      set(:mongrel_config_install_path) { "#{shared_path}/config/mongrel_cluster.yml" }
      # Set the environment in mongrel_cluster.yml
      buffer = mongrel_config
      buffer['cwd'] = "#{current_path}"
      buffer['environment']  = "#{rails_env.to_s}"
      invoke_command "sudo rm -f #{mongrel_config_install_path}", :via => run_method
      put YAML::dump(buffer), "#{mongrel_config_install_path}", :mode => 0664
    end
  end
  
  namespace :apache do
    desc "Generates a new apache vhost config"
    task :config, :roles => :web do
      set(:apache_config_install_path) { "/etc/apache2/sites-available/#{application}_#{stage}" }
      
      template = File.read(File.join(templates_dir, "apache", "vhost.erb"))
      result = ERB.new(template).result(binding)
      install_processed_template(result, "#{apache_config_install_path}", :mode => '0644')
      run <<-CMD
        if ! [ -f /etc/apache2/sites-available/name_vhost ]; then sudo echo 'NameVirtualHost *:80' > name_vhost; fi &&
        if ! [ -f /etc/apache2/sites-enabled/name_vhost ]; then sudo ln -s /etc/apache2/sites-available/name_vhost /etc/apache2/sites-enabled/name_vhost; fi &&
      
        if [ -f /etc/apache2/sites-enabled/#{application}_#{stage} ]; then sudo rm -r /etc/apache2/sites-enabled/#{application}_#{stage}; fi &&
        sudo ln -s /etc/apache2/sites-available/#{application}_#{stage} /etc/apache2/sites-enabled/#{application}_#{stage}
      CMD
    end
  end
  
  
  namespace :nginx do
    desc <<-DESC
      Generates a new nginx config.
    DESC
    task :config, :roles => :web do
      set :nginx_config_install_path, "/etc/nginx/nginx.conf"
      
      
      template = File.read(File.join(templates_dir, "nginx", "nginx.conf.erb"))
      result = ERB.new(template).result(binding)
      
      install_processed_template(result, "#{nginx_config_install_path}", :mode => '0644')
    end
    
    desc <<-DESC
      Generates a new nginx vhost for the specified application.
    DESC
    task :vhost, :roles => :web do
      set(:nginx_vhost_config_install_path) { "/etc/nginx/sites-available/#{application}_#{stage}.conf" }
      
      # mongrel_config = YAML::load_file(File.join(templates_dir, "mongrel_cluster.yml"))
      
      set :mongrel_start_port, (mongrel_config['port'].to_i)
      set :mongrel_end_port, (mongrel_config['port'].to_i + (mongrel_config['servers'].to_i - 1))
      set :vhost_domain, domain
      
      template = File.read(File.join(templates_dir, "nginx", "nginx.rails_vhost.conf.erb"))
      result = ERB.new(template).result(binding)
      run <<-CMD
        if ! [ -d /etc/nginx/sites-enabled/ ]; then sudo mkdir -p /etc/nginx/sites-enabled; fi &&
        if ! [ -d /etc/nginx/sites-available/ ]; then sudo mkdir -p /etc/nginx/sites-available; fi
      CMD
      install_processed_template(result, "#{nginx_vhost_config_install_path}", :mode => '0644')
      run <<-CMD
        if [ -f /etc/nginx/sites-enabled/#{application}_#{stage}.conf ]; then sudo rm -r /etc/nginx/sites-enabled/#{application}_#{stage}.conf; fi &&
        sudo ln -s /etc/nginx/sites-available/#{application}_#{stage}.conf /etc/nginx/sites-enabled/#{application}_#{stage}.conf
      CMD
    end
    
    desc <<-DESC
      Generates a new nginx monit vhost for the specified application.
    DESC
    task :monit, :roles => :web do
      set(:nginx_monit_vhost_config_install_path) { "/etc/nginx/sites-available/monit_#{application}_#{stage}.conf" }
      
      set :mongrel_start_port, (mongrel_config['port'].to_i)
      set :mongrel_end_port, (mongrel_config['port'].to_i + (mongrel_config['servers'].to_i - 1))
      set :vhost_domain, domain
      
      template = File.read(File.join(templates_dir, "nginx", "nginx.monit_vhost.conf.erb"))
      result = ERB.new(template).result(binding)
      run <<-CMD
        if ! [ -d /etc/nginx/sites-enabled/ ]; then sudo mkdir -p /etc/nginx/sites-enabled; fi &&
        if ! [ -d /etc/nginx/sites-available/ ]; then sudo mkdir -p /etc/nginx/sites-available; fi
      CMD
      install_processed_template(result, "#{nginx_monit_vhost_config_install_path}", :mode => '0644')
      run <<-CMD
        if [ -f /etc/nginx/sites-enabled/monit_#{application}_#{stage}.conf ]; then sudo rm -r /etc/nginx/sites-enabled/monit_#{application}_#{stage}.conf; fi &&
        sudo ln -s #{nginx_monit_vhost_config_install_path} /etc/nginx/sites-enabled/monit_#{application}_#{stage}.conf
      CMD
    end
  end
  
  namespace :backup_fu do
    set(:backup_fu_config_install_path) { "#{shared_path}/config/backup_fu.yml" }
    
    desc <<-DESC
      Generates a new backup_fu.yml. Requires two env variables, \
      AMAZON_ACCESS_KEY_ID and AMAZON_SECRET_ACCESS_KEY. Example usage:
      
      $ cap staging app=my_app generate:monit:config \\
            AMAZON_ACCESS_KEY_ID=your_access_key_id \\
            AMAZON_SECRET_ACCESS_KEY=your_secret_access_key
    DESC
    task :config, :roles => :web do
      bucket_name = create_backup_bucket_for(application)
      buffer = YAML::load_file(File.join(templates_dir, "backup_fu.example.yml"))
      
      buffer[rails_env.to_s]['app_name'] = application
      buffer[rails_env.to_s]['s3_bucket'] = bucket_name
      buffer[rails_env.to_s]['aws_access_key_id'] = ENV['AMAZON_ACCESS_KEY_ID']
      buffer[rails_env.to_s]['aws_secret_access_key'] = ENV['AMAZON_SECRET_ACCESS_KEY']
      buffer[rails_env.to_s]['static_paths'] = "#{current_path}/public"
      
      put YAML::dump(buffer), "#{backup_fu_config_install_path}", :mode => 0664
    end
  end
  
  namespace :config do
    namespace :check do
      [ :app, :db, :monit_sys, :monit_mongrel, :monit_nginx, :mongrel, :nginx, :backup_fu, :cron, :logrotate ].each do |t|
        desc "cat #{t.to_s.capitalize} config file"
        task t, :roles => :app do
          invoke_command "sudo cat #{send("#{t.to_s}_config_install_path")}", :via => run_method
        end
      end
    end
  end
  
  namespace :sys do
    set(:cron_config_install_path) { "/etc/cron.d/#{application}_#{stage}" }
    desc <<-DESC
      Generates a new cron.d file for this application.
    DESC
    task :cron, :roles => :app do
      template = File.read(File.join(templates_dir, "cron.erb"))
      result = ERB.new(template).result(binding)
      install_processed_template(result, "#{cron_config_install_path}", :mode => '0644')
    end
    
    set(:logrotate_config_install_path) { "/etc/logrotate.d/#{application}_#{stage}" }
    desc <<-DESC
      Generates a new logrotate.d file for this application.
    DESC
    task :logrotate, :roles => :app do
      template = File.read(File.join(templates_dir, "logrotate.erb"))
      result = ERB.new(template).result(binding)
      install_processed_template(result, "#{logrotate_config_install_path}", :mode => '0644')
    end
  end
  
end

# Load template and install it.
# Removes temporary files during transfer.
# Derived from capitate: http://capitate.rubyforge.org
#
# ==== Options
# +processed_template+:: The Template to be installed
# +destination+:: Remote path to evaluated template
# +options+:: Options (see Install template options)
#
# ==== Install template options
# +user+:: User to install (-o). Defaults to *root*.
# +mode+:: Mode to install file (-m)
#
# ==== Example
#   utils.install_template("monit/memcached.monitrc.erb", "/etc/monit/memcached.monitrc", :user => "root", :mode => "600")
#
def install_processed_template(processed_template, destination, options = {})
  # Truncate extension
  tmp_file_path = destination.gsub("/", "_").gsub(/.erb$/, "")
  tmp_path = "/tmp/#{tmp_file_path}"
  
  options[:user] ||= "root"
  
  install_options = []
  install_options << "-o #{options[:user]}"
  install_options << "-m #{options[:mode]}" if options.has_key?(:mode)
  
  put processed_template, tmp_path    
  # TOOD: Ensure directory exists? mkdir -p #{File.dirname(destination)}
  invoke_command "sudo install #{install_options.join(" ")} #{tmp_path} #{destination} && rm -f #{tmp_path}"
end


def create_backup_bucket_for(application)
  AWS::S3::Base.establish_connection!(
    :access_key_id     => ENV['AMAZON_ACCESS_KEY_ID'], 
    :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
  )
  AWS::S3::Bucket.create("#{application}_#{stage}_backup_fu")
  return "#{application}_#{stage}_backup_fu"
end