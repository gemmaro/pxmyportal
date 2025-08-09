# Copyright (C) 2025  gemmaro

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require "optparse"
require "pstore"
require_relative "agent"
require_relative "cookie_store"

class PXMyPortal::Command
  def run
    options = { company: ENV["PXMYPORTAL_COMPANY"],
                user: ENV["PXMYPORTAL_USER"],
                password: ENV["PXMYPORTAL_PASSWORD"],
                test: ENV["PXMYPORTAL_TEST"] }
    debug_cookie = false

    parser = OptionParser.new
    parser.on("--debug") { options[:debug] = true }
    parser.on("--cookie-jar=PATH") { |path| options[:cookie_jar_path] = path }
    parser.on("--payslips=PATH",
              "database file for previously stored payslips") { |path|
      options[:payslips_path] = path }
    parser.on("--payslip-dir=PATH") { |path| options[:payslip_dir] = path }
    parser.on("--bonus-only") { options[:bonus_only] = true }
    parser.on("--debug-http") { options[:debug_http] = true }
    parser.on("--force") { options[:force] = true }
    parser.on("--debug-cookie") { debug_cookie = true }
    parser.parse!

    if debug_cookie
      store = PXMyPortal::CookieStore.new
      store.transaction do
        store.keys.each do |key|
          puts "--- #{key}"
          pp store[key]
        end
      end
      return
    end

    agent = PXMyPortal::Agent.new(**options)
    agent.save_payslips
  end
end
