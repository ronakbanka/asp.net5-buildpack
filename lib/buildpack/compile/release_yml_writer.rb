# Encoding: utf-8
# ASP.NET 5 Buildpack
# Copyright 2014-2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fileutils"

module AspNet5Buildpack
  class ReleaseYmlWriter
    def write_release_yml(build_dir, out)
      dirs = Dirs.new(build_dir)
      write_startup_script(dirs.startup_script_path)
      write_yml(dirs)
    end

    private

    def write_yml(dirs)
      unless dirs.with_existing_cfweb.empty?
        write_yml_for(dirs.release_yml_path, dirs.with_existing_cfweb.first, "cf-web")
        return
      end

      unless dirs.with_project_json.empty?
        add_cfweb_command(dirs.project_json(dirs.with_project_json.first))
        write_yml_for(dirs.release_yml_path, dirs.with_project_json.first, "cf-web")
        return
      end

      write_yml_for(dirs.release_yml_path, ".", "cf-web")
    end

    def add_cfweb_command(project_json)
      json = JSON.parse(IO.read(project_json))
      json["dependencies"] ||= {}
      json["dependencies"]["Nowin.vNext"] = "1.0.0-*" unless json["dependencies"]["Nowin.vNext"]
      json["commands"] ||= {}
      json["commands"]["cf-web"] = "Microsoft.AspNet.Hosting --server Nowin.vNext"
      IO.write(project_json, json.to_json)
    end

    def write_startup_script(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.write "export PATH=/app/mono/bin:$PATH;"
        f.write "export HOME=/app;"
        f.write "source /app/.k/kvm/kvm.sh; kvm use 1.0.0-beta3;"
      end
    end

    def write_yml_for(ymlPath, web_dir, cmd)
      File.open(ymlPath, 'w') do |f|
        f.write <<EOT
---
default_process_types:
  web: cd #{web_dir}; sleep 999999 | k #{cmd}
EOT
      end
    end

    class Dirs
      def initialize(dir)
        @dir = dir
      end

      def release_yml_path
        File.join(@dir, "aspnet5-buildpack-release.yml")
      end

      def startup_script_path
        File.join(@dir, ".profile.d", "startup.sh")
      end

      def with_web_commands
        with_command("web")
      end

      def with_existing_cfweb
        with_command("cf-web")
      end

      def with_command(cmd)
        with_project_json.select { |d| commands(d)[cmd] != nil && commands(d)[cmd] != "" }
      end

      def with_project_json
        Dir.glob(File.join(@dir, "**", "project.json")).map do |d|
          relative_path_to(File.dirname(d))
        end.reject do |d|
          d.fnmatch?("src/Nowin.vNext")
        end.sort do |d|
          commands(d)["web"] ? 0 : 1
        end
      end

      def commands(dir)
        JSON.load(IO.read(project_json(dir))).fetch("commands", {})
      end

      def project_json(dir)
        File.join(@dir, dir, "project.json")
      end

      def relative_path_to(d)
        Pathname.new(d).relative_path_from(Pathname.new(@dir))
      end
    end
  end
end
