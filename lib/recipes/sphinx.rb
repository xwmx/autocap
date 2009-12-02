namespace :thinking_sphinx do
  desc "Generate the ThinkingSphinx configuration file"
  task :configure, :roles => :app do
    run "cd #{release_path} && rake RAILS_ENV=#{rails.env.to_s} thinking_sphinx:configure"
  end
  
  desc "Run the ThinkingSphinx indexer"
  task :index, :roles => :app do
    run "cd #{release_path} && rake AILS_ENV=#{rails.env.to_s} thinking_sphinx:index"
  end
  
  [ :stop, :start, :restart ].each do |t|
    desc "#{t.to_s.capitalize} the ThinkingSphinx daemon"
    task t, :roles => :app do
      run "cd #{release_path} && rake AILS_ENV=#{rails.env.to_s} thinking_sphinx:index"
    end
  end
end