package "ruby"
include_recipe "buildpack"
deploy_revision "app" do
  revision node["app"]["revision"]
  repository node["app"]["repository"]
  deploy_to node["app"]["deploy_to"]
  rollback_on_error true
  symlink_before_migrate({})
  before_symlink do
    buildpack "app" do
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
