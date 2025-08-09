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

require "http-cookie"
require_relative "xdg"
require_relative "cookie_store"

class PXMyPortal::Cookie
  def initialize(jar_path: nil, logger:)
    @jar_path = jar_path || File.join(PXMyPortal::XDG::CACHE_DIR, "cookie-jar")
    @logger = logger

    @jar             = HTTP::CookieJar.new
    @debug_store = PXMyPortal::CookieStore.new
  end

  def load
    @jar.load(@jar_path) if File.exist?(@jar_path)
  end

  # Previously accept_cookie.
  def accept(response, url:)
    fields = [*response.get_fields("Set-Cookie"), *response.get_fields("set-cookie")]
    @debug_store.transaction do
      @debug_store[url] ||= []
      @debug_store[url].concat(fields)
    end

    fields.each { |value| @jar.parse(value, url) }
    @jar.save(jar_path)
  end

  # Previously cookie_jar_path.
  def jar_path
    @created_jar_path and return @created_jar_path
    dir = File.dirname(@jar_path)
    unless Dir.exist?(dir)
      @logger.info("creating cache directory")
      Dir.mkdir(dir)
    end
    @created_jar_path = @jar_path
  end

  # Previously provide_cookie.
  def provide(request, url:)
    request["Cookie"] = HTTP::Cookie.cookie_value(@jar.cookies(url))
  end
end
