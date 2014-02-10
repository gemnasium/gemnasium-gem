namespace :gemnasium do
  require 'gemnasium'

  desc "Push dependency files to gemnasium"
  task :push do
    Gemnasium.push project_path: File.expand_path(".")
  end

  desc "Create project on gemnasium"
  task :create do
    Gemnasium.create_project project_path: File.expand_path(".")
  end

  desc "Resolve project name on gemnasium"
  task :resolve do
    Gemnasium.resolve_project project_path: File.expand_path(".")
  end

end
