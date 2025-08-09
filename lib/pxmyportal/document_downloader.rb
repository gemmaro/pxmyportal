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

class PXMyPortal::DocumentDownloader
  def initialize(path:, form_data:, logger:, http:)
    @path = path
    @form_data = form_data
    @logger = logger
    @http = http

    @request = Net::HTTP::Post.new(@path)
  end

  def post
    @http.provide_cookie(@request)
    @request.form_data = @form_data
    @logger.debug("request") { @request }

    response = @http.request(@request)
    response => Net::HTTPOK
    @logger.debug("response") { response.to_hash }
    response.to_hash["content-type"] => ["application/pdf"]
    response.body
  end
end
