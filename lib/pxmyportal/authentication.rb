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
require_relative "xdg"
require_relative "page"

class PXMyPortal::Authentication
  def initialize(path:, user:, password:, token:, http:, logger:)
    @path = path
    @user = user
    @password = password
    @token = token
    @http = http
    @logger = logger

    @request = Net::HTTP::Post.new(@path)
  end

  def post
    @http.provide_cookie(@request)

    @request.form_data = {
      LoginId: @user,
      Password: @password,
      "__RequestVerificationToken" => @token,
    }
    response = @http.request(@request)
    begin
      response => Net::HTTPFound | Net::HTTPOK
    rescue => e
      File.write(File.join(PXMyPortal::XDG::CACHE_DIR, "authentication.html"),
                 response.body)
      raise e
    end

    @logger.debug("response") { response.to_hash }
    page = PXMyPortal::Page.from_path(response["location"] || @path)
    unless page
      @logger.error("location") { response["location"] }
      raise PXMyPortal::Error, "unexpected location"
    end
    @http.accept_cookie(response)
    page
  end
end
