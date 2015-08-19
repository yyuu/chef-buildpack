require "chef/mixin/shell_out"
require "shellwords"

include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

def provision(buildpack_url, buildpack_dir)
  execute = []
  if buildpack_url.index("#")
    repository, revision = buildpack_url.split("#", 2)
  else
    repository = buildpack_url
  end
  buildpack_dir ||= ::File.join(Chef::Config[:file_cache_path], "buildpacks", ::File.basename(repository, ".git"))
  execute << "rm -fr #{Shellwords.shellescape(buildpack_dir)}"
  execute << "mkdir -p #{Shellwords.shellescape(::File.dirname(buildpack_dir))}"
  checkout_options = []
  checkout_options << "--branch" << Shellwords.shellescape(revision) if revision
  checkout_options << "--depth" << "1"
  checkout_options << "--quiet"
  execute << "git clone #{checkout_options.join(" ")} #{Shellwords.shellescape(repository)} #{Shellwords.shellescape(buildpack_dir)}"
  converge_by("Provisioning #{buildpack_url} at #{buildpack_dir}") do
    shell_out!(execute.join(" && "))
  end
  buildpack_dir
end

def invoke(buildpack_dir, command, args=[], environment={})
  executable = ::File.join(buildpack_dir, "bin", command)
  cmdline = Shellwords.shelljoin([executable] + args)
  execute cmdline do
    environment environment
    only_if { ::File.exist?(executable) }
  end
end

def detect(buildpack_dir, build_dir, environment={})
  invoke(buildpack_dir, "detect", [build_dir], environment)
end

def compile(buildpack_dir, build_dir, cache_dir, env_dir, environment={})
  raise(ArgumentError.new("missing CACHE_DIR")) if cache_dir.nil?
  raise(ArgumentError.new("missing ENV_DIR")) if env_dir.nil?
  invoke(buildpack_dir, "compile", [build_dir, cache_dir, env_dir], environment)
end

def release(buildpack_dir, build_dir, environment={})
  invoke(buildpack_dir, "release", [build_dir], environment)
end

action :detect do
  buildpack_dir = provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  detect(buildpack_dir, new_resource.build_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end

action :compile do
  buildpack_dir = provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  compile(buildpack_dir, new_resource.build_dir, new_resource.cache_dir, new_resource.env_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end

action :release do
  buildpack_dir = provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  release(buildpack_dir, new_resource.build_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end
