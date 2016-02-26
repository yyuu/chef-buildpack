package "ruby"
include_recipe "buildpack"

deploy_revision "app" do
  revision "v3.0.0"
  repository "https://github.com/yyuu/myapp.git"
  deploy_to "/srv/app"
  rollback_on_error true
  symlink_before_migrate({})
  before_symlink do
    buildpack "heroku-buildpack-ruby" do
      buildpack_url node["app"]["buildpack_url"]
      build_dir release_path
      cache_dir ::File.join(shared_path, "cache")
      env_dir ::File.join(shared_path, "env")
      environment({
        "STACK" => "cedar-14",
      })
    end
  end
end
