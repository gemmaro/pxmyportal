# PXMyPortal

このgemは[PXまいポータル](https://www.tkc.jp/pxmyportal/)のコマンドラインツールpxmyportalを提供します。
現時点で給与明細書のダウンロードを行えます。

## Installation

Install the gem and add to the application's `Gemfile` by executing:

    $ bundle add pxmyportal

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install pxmyportal

## Usage

環境変数`PXMYPORTAL_COMPANY`、`PXMYPORTAL_USER`、`PXMYPORTAL_PASSWORD`の指定が必要です。
必要に応じて`.env`ファイルや設定ファイルを作成してください。

## Development

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/gemmaro/pxmyportal).

## License

Copyright (C) 2025  gemmaro

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
