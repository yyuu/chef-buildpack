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
  execute << "rm -fr #{Shellwords.shellescape(buildpack_dir)}"
  checkout_options = []
  checkout_options << "--branch" << Shellwords.shellescape(revision) if revision
  checkout_options << "--depth" << "1"
  checkout_options << "--quiet"
  execute << "git clone #{checkout_options.join(" ")} #{Shellwords.shellescape(repository)} #{Shellwords.shellescape(buildpack_dir)}"
  converge_by("Provisioning #{buildpack_url} at #{buildpack_dir}") do
    shell_out!(execute.join(" && "))
  end
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
  provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  detect(new_resource.buildpack_dir, new_resource.build_dir, new_resource.environment)
end

action :compile do
  provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  compile(new_resource.buildpack_dir, new_resource.build_dir, new_resource.cache_dir, new_resource.env_dir, new_resource.environment)
end

action :release do
  provision(new_resource.buildpack_url, new_resource.buildpack_dir)
  release(new_resource.buildpack_dir, new_resource.build_dir, new_resource.environment)
end
