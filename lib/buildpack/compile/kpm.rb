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

module AspNet5Buildpack
  class KPM
    def initialize(shell)
      @shell = shell
    end

    def restore(dir, out)
      @shell.env["HOME"] = dir
      @shell.exec("bash -c 'source #{dir}/.k/kvm/kvm.sh; kvm install 1.0.0-beta3; for i in $(find -iname project.json -print0 | xargs -0 -n1 dirname); do kpm restore -s https://www.myget.org/F/aspnetvnext/ ; done'", out)
    end
  end
end
