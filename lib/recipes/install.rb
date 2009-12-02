##############################################################################
# Gem tasks
##############################################################################

namespace :gems do
  desc <<-DESC
    Installs the gem specified by GEM=
  DESC
  task :install, :roles => :app do
    run <<-CMD
      sudo gem install #{ENV['GEM']}
    CMD
  end
  
  namespace :build do
    task :initial, :roles => :app do
      # rake gems:install doesn't currently work
      # run "cd #{current_path} && rake RAILS_ENV=#{rails_env.to_s} gems:install"
      run "sudo gem install tzinfo graticule rake rubyforge mocha image_science aws-s3 diff-lcs RedCloth"
      run <<-CMD
        cd ~/source &&
        git clone git://github.com/nex3/haml.git &&
        cd haml && 
        sudo rake install &&
        
        sudo gem install rubyist-aasm --source=http://gems.github.com
        sudo gem install mbleigh-subdomain-fu --source=http://gems.github.com
      CMD
    end
  end
  
  desc <<-DESC
    If called with optional GEM= argument, the specified gem will be \
    updated, otherwise all gems are updated.
  DESC
  task :update, :roles => :app do
    run <<-CMD
      sudo gem update #{ENV['GEM']}
    CMD
  end
end