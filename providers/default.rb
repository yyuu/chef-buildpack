require "chef/mixin/shell_out"
require "shellwords"

include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

def buildpack_info(name, buildpack_url, buildpack_dir = nil)
  buildpack_root = ::File.join(Chef::Config[:file_cache_path], "buildpacks")
  case buildpack_url
  when /\.tar\.gz$/
    {
      :format => :tgz,
      :buildpack_url => buildpack_url,
      :buildpack_dir => buildpack_dir || ::File.join(buildpack_root, name),
    }
  else
    if buildpack_url.index("#")
      repository, revision = buildpack_url.split("#", 2)
    else
      repository = buildpack_url
      revision = "HEAD"
    end
    {
      :format => :git,
      :buildpack_url => repository,
      :revision => revision,
      :buildpack_dir => buildpack_dir || ::File.join(buildpack_root, name),
    }
  end
end

def provision(info)
  case info[:format]
  when :git
    provision_git(info)
  when :tgz
    provision_tgz(info)
  else
    fail("Unknown buildpack format: #{info[:format].inspect}")
  end
end

def provision_tgz(info)
  buildpack_dir = info[:buildpack_dir]
  buildpack_url = info[:buildpack_url]
  bash "buildpack #{buildpack_dir}" do
    code <<-SH
      set -e
      set -x
      set -o pipefail
      tmpdir="$(mktemp -d /tmp/buildpack.XXXXXXXX)"
      on_exit() { rm -fr "${tmpdir}"; }
      trap on_exit EXIT
      cd "${tmpdir}"
      curl -L --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time 30 #{::Shellwords.shellescape(buildpack_url)} -s -o - | tar zxf -
      mkdir -p #{::Shellwords.shellescape(::File.dirname(buildpack_dir))}
      rm -fr #{::Shellwords.shellescape(buildpack_dir)}
      mv -f * #{::Shellwords.shellescape(buildpack_dir)}
    SH
  end
end

def provision_git(info)
  buildpack_dir = info[:buildpack_dir]
  buildpack_url = info[:buildpack_url]
  bash "buildpack #{buildpack_dir}" do
    code <<-SH
      set -e
      set -x
      mkdir -p #{::Shellwords.shellescape(::File.dirname(buildpack_dir))}
      if [ -e #{::Shellwords.shellescape(::File.join(buildpack_dir, ".git"))} ]; then
        if [ -e #{::Shellwords.shellescape(::File.join(buildpack_dir, ".git", "shallow"))} ]; then
          rm -fr #{::Shellwords.shellescape(buildpack_dir)}
        fi
      else
        rm -fr #{::Shellwords.shellescape(buildpack_dir)}
      fi
      if [ -d #{::Shellwords.shellescape(buildpack_dir)} ]; then
        cd #{::Shellwords.shellescape(buildpack_dir)}
        git config remote.origin.url #{::Shellwords.shellescape(buildpack_url)}
        git config remote.origin.fetch "+refs/heads/*:refs/remote/origin/*"
        git fetch
      else
        git clone #{::Shellwords.shellescape(buildpack_url)} #{::Shellwords.shellescape(buildpack_dir)}
        cd #{::Shellwords.shellescape(buildpack_dir)}
      fi
      if git show-ref -q --verify #{::Shellwords.shellescape("refs/tags/#{info[:revision]}")}; then
        git reset --hard #{::Shellwords.shellescape("refs/tags/#{info[:revision]}")}
      else
        if git show-ref -q --verify #{::Shellwords.shellescape("refs/remotes/origin/#{info[:revision]}")}; then
          git reset --hard #{::Shellwords.shellescape("refs/remotes/origin/#{info[:revision]}")}
        else
          git reset --hard #{::Shellwords.shellescape(info[:revision])}
        fi
      fi
      git clean -d -f -x
    SH
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
  info = buildpack_info(new_resource.name, new_resource.buildpack_url, new_resource.buildpack_dir)
  provision(info)
  detect(info[:buildpack_dir], new_resource.build_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end

action :compile do
  info = buildpack_info(new_resource.name, new_resource.buildpack_url, new_resource.buildpack_dir)
  provision(info)
  if new_resource.activate_file
    if new_resource.activate_runner
      Chef::Log.warn("activate_runner has been deprecated and is not supported anymore.")
    end
    template ::File.join(new_resource.build_dir, new_resource.activate_file) do
      cookbook "buildpack"
      mode "0755"
      source "activate.erb"
      variables({
        :home => new_resource.build_dir,
      })
    end
    Chef::Log.info("Created \`activate' script at #{new_resource.build_dir.inspect}.")
  end
  compile(info[:buildpack_dir], new_resource.build_dir, new_resource.cache_dir, new_resource.env_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end

action :release do
  info = buildpack_info(new_resource.name, new_resource.buildpack_url, new_resource.buildpack_dir)
  provision(info)
  release(info[:buildpack_dir], new_resource.build_dir, new_resource.environment)
  new_resource.updated_by_last_action(true)
end
