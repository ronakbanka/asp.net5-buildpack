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

require_relative 'compile/mozroots.rb'
require_relative 'compile/mono_installer.rb'
require_relative 'compile/kre_installer.rb'
require_relative 'compile/kvm_installer.rb'
require_relative 'compile/kpm.rb'
require_relative 'compile/release_yml_writer.rb'

require 'json'
require 'pathname'

module AspNet5Buildpack
  class Compiler
    WARNING_MESSAGE = "This is an experimental buildpack. It is not supported.   Do not expect it to work reliably. Please, do not         contact support about issues with this buildpack."

    def initialize(build_dir, cache_dir, mono_binary, nowin_dir, kvm_installer, mozroots, kre_installer, kpm, release_yml_writer, copier, out)
      @build_dir = build_dir
      @cache_dir = cache_dir
      @mono_binary = mono_binary
      @nowin_dir = nowin_dir
      @kvm_installer = kvm_installer
      @kre_installer = kre_installer
      @mozroots = mozroots
      @kpm = kpm
      @release_yml_writer = release_yml_writer
      @copier = copier
      @out = out
    end

    def compile
      out.warn(WARNING_MESSAGE) unless WARNING_MESSAGE.nil?
      step("Restoring files from buildpack cache" , method(:restore_cache))
      step("Extracting mono", method(:extract_mono))
      step("Adding Nowin.vNext", method(:copy_nowin))
      step("Importing Mozilla Root Certificates", method(:install_mozroot_certs))
      step("Installing KVM", method(:install_kvm))
      step("Installing KRE with KVM", method(:install_kre))
      step("Restoring dependencies with KPM", method(:restore_dependencies))
      step("Moving files in to place", method(:move_to_app_dir))
      step("Saving to buildpack cache", method(:save_cache))
      step("Writing Release YML", method(:write_release_yml))
      return true
    rescue StepFailedError => e
      out.fail(e.message)
      puts ".\n"
      out.warn(WARNING_MESSAGE)
      sleep 2 # otherwise the warning message gets lost and you have to do logs --recent to see it
      return false
    end

    private

    def extract_mono(out)
      mono_binary.extract(File.join("/", "app"), out) unless File.exist? File.join("/app", "mono")
    end

    def copy_nowin(out)
      dest_dir = File.join(build_dir, "src")
      copier.cp(nowin_dir, dest_dir, out) unless File.exist? File.join(dest_dir, "Nowin.vNext")
    end

    def install_mozroot_certs(out)
      mozroots.import(out)
    end

    def restore_cache(out)
      copier.cp(File.join(cache_dir, ".k"), build_dir, out) if File.exist? File.join(cache_dir, ".k")
      copier.cp(File.join(cache_dir, "mono"), File.join("/", "app"), out) if File.exist? File.join(cache_dir, "mono")
    end

    def install_kvm(out)
      kvm_installer.install(build_dir, out)
    end

    def install_kre(out)
      kre_installer.install(build_dir, out)
    end

    def restore_dependencies(out)
      kpm.restore(build_dir, out)
    end

    def move_to_app_dir(out)
      copier.cp(File.join("/app", "mono"), build_dir, out)
    end

    def save_cache(out)
      copier.cp(File.join(build_dir, ".k"), cache_dir, out)
      copier.cp(File.join("/app", "mono"), cache_dir, out) unless File.exists? File.join(cache_dir, "mono")
    end

    def write_release_yml(out)
      release_yml_writer.write_release_yml(build_dir, out)
    end

    def step(description, method)
      s = out.step(description)
      begin
        method.call(s)
      rescue => e
        s.fail(e.message)
        raise StepFailedError, "#{description} failed, #{e.message}"
      end

      s.succeed
    end

    attr_reader :build_dir
    attr_reader :cache_dir
    attr_reader :mono_binary
    attr_reader :nowin_dir
    attr_reader :kvm_installer
    attr_reader :kre_installer
    attr_reader :mozroots
    attr_reader :kpm
    attr_reader :release_yml_writer
    attr_reader :copier
    attr_reader :out
  end

  class StepFailedError < StandardError
  end
end

