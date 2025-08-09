# Copyright (C) 2025  gemmaro
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require "net/http"
require "forwardable"
require_relative "cookie"

class PXMyPortal::HTTPClient
  def initialize(debug: false, logger:)
    @http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    @http.use_ssl = true
    @http.set_debug_output($stderr) if debug

    @cookie = PXMyPortal::Cookie.new(logger:)
  end

  def start
    @http.started? or @http.start
  end

  extend Forwardable
  def_delegators :@http, :get, :request, :set_debug_output, :started?
  def_delegator :@cookie, :provide, :provide_cookie
  def_delegator :@cookie, :accept, :accept_cookie
end
