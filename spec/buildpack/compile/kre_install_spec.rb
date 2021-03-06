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

require "rspec"
require_relative "../../../lib/buildpack.rb"

describe AspNet5Buildpack::KreInstaller do
  let(:shell) do
    double(:shell, :exec => nil)
  end

  let(:out) do
    double(:out)
  end

  subject(:installer) do
    AspNet5Buildpack::KreInstaller.new(shell)
  end

  it "sources the kvm script" do
    expect(shell).to receive(:exec).with(match("^bash -c 'source the-app-dir/.k/kvm/kvm.sh"), out)
    installer.install("the-app-dir", out)
  end

  it "runs the kvm web installer" do
    expect(shell).to receive(:exec).with(match("kvm install 1.0.0-beta3"), out)
    installer.install("the-app-dir", out)
  end
end
