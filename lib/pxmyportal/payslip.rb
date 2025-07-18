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

class PXMyPortal::Payslip
  attr_reader :year_month, :description, :directory

  def initialize(year_month:, description:, key1:, key2:, key3:,
                 directory: File.join(ENV["XDG_DOCUMENTS_DIR"], "pxmyportal"))
    @year_month  = year_month
    @description = description
    @key1        = key1
    @key2        = key2
    @key3        = key3
    @directory   = directory
  end

  def filename
    @filename ||= File.join(@directory, "#{@key1}-#{@key2}-#{@key3}.pdf")
  end

  def form_data
    { key1: @key1, key2: @key2, key3: @key3 }
  end

  def metadata
    { year_month: @year_month, description: @description,
      filename: @filename }
  end

  def ==(other)
    other => Hash
    @year_month == other[:year_month] \
      && @description == other[:description]
  end

  def to_s
    "#<Payslip #{year_month.inspect} #{description.inspect}>"
  end

  def self.from_row(row, directory: nil)
    row.xpath("./td") => [year_month, description, button]
    year_month.xpath(".//text()") => [year_month]
    description.xpath(".//text()") => [description]

    button.xpath(".//@onclick") => [listener]
    listener = listener.value

    keys = /\AOpenPdf\('(?<key1>\d+)','(?<key2>\d+)',(?<key3>\d+)\);\z/
    match = listener.match(keys) or raise Error, listener.inspect

    key1 = match[:key1]
    key2 = match[:key2]
    key3 = match[:key3]

    options = {}
    directory and options[:directory] = directory

    new(year_month: year_month.content,
        description: description.content,
        key1:, key2:, key3:,
        **options)
  end
end
