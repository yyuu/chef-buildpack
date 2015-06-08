actions :detect, :compile, :release
default_action [:detect, :compile]

attribute :buildpack_url, :kind_of => String, :default => "https://github.com/heroku/heroku-buildpack-ruby.git"
attribute :buildpack_dir, :kind_of => String, :required => true
attribute :environment, :kind_of => Hash, :default => {}

attribute :build_dir, :kind_of => String, :required => true
attribute :cache_dir, :kind_of => String, :default => nil
attribute :env_dir, :kind_of => String, :default => nil
