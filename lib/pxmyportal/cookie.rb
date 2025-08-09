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

require "set"

class PXMyPortal::Cookie
  def initialize(logger:)
    @set = Set.new
    @logger = logger
  end

  def accept(response)
    fields = Set[*response.get_fields("Set-Cookie"),
      *response.get_fields("set-cookie")]

    fields.each do |field|
      field.split(/; +/).each do |pair|
        case pair
        when "path=/",
          "secure",
          "HttpOnly",
          "SameSite=Lax",
          "selectedPage=pc",
          /\Aexpires=/
          next
        end
        key, = pair.split('=')
        case key
        when "ASP.NET_SessionId",
          ".AspNet.ApplicationCookie",
          "qs",
          /\A__RequestVerificationToken_([A-Za-z0-9]+)/
        else
          raise PXMyPortal::Error, "unknown cookie entry #{pair.inspect}"
        end
        @set << pair
      end
    end
  end

  def provide(request)
    request["Cookie"] = @set.join(';')
  end
end
