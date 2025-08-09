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

class PXMyPortal::PayslipList
  def initialize(path:, logger:, http:)
    @path = path
    @logger = logger
    @http = http

    @request = Net::HTTP::Get.new(@path)
  end

  def get
    @logger.debug("request") { @request }

    @http.provide_cookie(@request)
    response = @http.request(@request)
    @logger.debug("response") { response }
    response => Net::HTTPOK
    response.body
  end
end
