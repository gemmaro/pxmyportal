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
require "nokogiri"
require_relative "http_client"
require_relative "page"

class PXMyPortal::TokenIssuer
  def initialize(http:, company:)
    @http = http
    @company = company
  end

  def get
    @http.start

    path = File.join(PXMyPortal::Page::BASEPATH, "Auth/Login")
    query = @company
    response = @http.get("#{path}?#{query}")
    response => Net::HTTPOK

    @http.accept_cookie(response)

    document = Nokogiri::HTML(response.body)
    token = <<~XPATH
      //form//input[     @type='hidden'
                     and @name='__RequestVerificationToken' ]
      /@value
    XPATH
    document.xpath(token) => [token]
    token or raise Error, token
  end
end
