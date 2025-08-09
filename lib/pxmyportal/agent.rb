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

require "yaml"
require "logger"
require "set"
require_relative "payslip"
require_relative "error"
require_relative "cookie"
require_relative "page"

class PXMyPortal::Agent
  def let_redirect(path: PXMyPortal::Page::BASEPATH)
    @request_verification_token ||= PXMyPortal::RequestVerificationToken.new(
      http: @http,
      company: @company,
      cookie: @cookie,
    ).get

    @page = PXMyPortal::Authentication.new(
      path:,
      cookie: @cookie,
      user: @user,
      password: @password,
      token: @request_verification_token,
      http: @http,
      logger: @logger,
    ).post
  end

  def save_payslips
    let_redirect

    existing_payslips = (YAML.load_file(@payslips_path) rescue []) || []

    pages = Set[PXMyPortal::Page::BONUS]
    unless @bonus_only
      pages << @page
    end

    pages.each do |page|
      let_redirect(path: page.path)
      payslips = payslips_for_page(page)

      payslips.each do |payslip|
        if !@force && existing_payslips&.find { |candidate| payslip == candidate }
          @logger.info("skipping") { payslip }
          next
        end
        path = @page.confirm_path
        data = PXMyPortal::DocumentDownloader.new(
          path:,
          cookie: @cookie,
          form_data: payslip.form_data,
          http: @http,
          logger: @logger,
        ).post

        path = File.join(@payslip_dir, payslip.filename)
        FileUtils.mkdir_p(@payslip_dir)
        @logger.info("saving payslip...") { path }
        File.write(path, data) unless @test
        existing_payslips << payslip.metadata
      end
    end
    
    File.open(payslips_path, "w") { |file| YAML.dump(existing_payslips, file) } \
      unless @test

    self
  end

  private

  def payslips_path
    @created_payslips_path and return @created_payslips_path
    dir = File.dirname(@payslips_path)
    unless Dir.exist?(dir)
      @logger.info("creating payslips path...")
      Dir.mkdir(dir)
    end
    @created_payslips_path = @payslips_path
  end

  def payslips_for_page(page)
    data = PXMyPortal::PayslipList.new(
      path: page.path,
      debug: @debug,
      logger: @logger,
      cookie: @cookie,
      http: @http,
    ).get
    File.write(page.cache_path, data)
    page.rows(data)
      .map { |row| PXMyPortal::Payslip.from_row(row) }
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end

  def initialize(debug: false,
                 cookie_jar_path: nil,
                 payslips_path: File.join(PXMyPortal::XDG::DATA_DIR,
                                          "pxmyportal", "payslips.yaml"),
                 company:,
                 user:,
                 password:,
                 test: false,
                 payslip_dir: PXMyPortal::XDG::DOC_DIR,
                 bonus_only: false,
                 debug_http: false,
                 force: false)

    @company         = company
    @user            = user
    @password        = password
    @debug           = debug
    @payslips_path   = payslips_path
    @test            = test
    @payslip_dir     = payslip_dir
    @bonus_only      = bonus_only
    @debug_http      = debug_http
    @force           = force

    @logger = Logger.new($stderr)
    @cookie = PXMyPortal::Cookie.new(jar_path: cookie_jar_path, logger: @logger)
    @http = PXMyPortal::HTTPClient.new(debug: @debug_http)
  end
end

require_relative "http_client"
require_relative "request_verification_token"
require_relative "document_downloader"
require_relative "authentication"
require_relative "payslip_list"
