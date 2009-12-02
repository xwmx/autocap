##############################################################################
# Rake tasks
##############################################################################

# esc "Run a rake task specified by task="
task :rake, :roles => :app do
  run "cd #{current_path} && rake RAILS_ENV=#{rails_env.to_s} #{ENV['task']}"
end