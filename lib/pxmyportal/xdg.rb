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

class PXMyPortal::XDG
  CACHE_DIR = File.join(ENV["XDG_CACHE_HOME"] || File.join(Dir.home, ".cache"),
                        "pxmyportal")
  DOC_DIR = File.join(ENV["XDG_DOCUMENTS_DIR"] || File.join(Dir.home, "Documents"),
                      "pxmyportal")
end
