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
require "net/http"
require "nokogiri"
require "logger"
require "set"
require_relative "payslip"
require_relative "error"
require_relative "cookie"
require_relative "page"

class PXMyPortal::Agent
  def let_redirect(path: PXMyPortal::Page::BASEPATH)
    token = request_verification_token
    request = Net::HTTP::Post.new(path)
    @cookie.provide(request, url: build_url(path))

    data = { LoginId: @user,
             Password: @password,
             "__RequestVerificationToken" => token }
    request.form_data = data
    response = @http.request(request)
    begin
      response => Net::HTTPFound | Net::HTTPOK
    rescue => e
      File.write(File.join(PXMyPortal::XDG::CACHE_DIR, "debug", "let_redirect.html"),
                 response.body)
      raise e
    end

    @logger.debug("response") { response.to_hash }
    @page = PXMyPortal::Page.from_path(response["location"] || path)
    unless @page
      @logger.error("location") { response["location"] }
      raise PXMyPortal::Error, "unexpected location"
    end
    @cookie.accept(response, url: build_url(@page.path))
    self
  end

  def save_payslips
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
        request = Net::HTTP::Post.new(path)
        @cookie.provide(request, url: build_url(path))
        request.form_data = payslip.form_data
        @logger.debug("request") { request }

        response = @http.request(request)
        response => Net::HTTPOK
        @logger.debug("response") { response.to_hash }
        # response.to_hash["content-type"] => ["application/pdf"]

        path = File.join(@payslip_dir, payslip.filename)
        FileUtils.mkdir_p(@payslip_dir)
        @logger.info("saving payslip...") { path }
        File.write(path, response.body) unless @test
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
    request = Net::HTTP::Get.new(page.path)
    @debug and @logger.debug("request") { request }

    @cookie.provide(request, url: build_url(page.path))
    response = @http.request(request)
    @debug and @logger.debug("response") { response }
    response => Net::HTTPOK

    File.write(page.cache_path, response.body)
    page.rows(response.body)
      .map { |row| PXMyPortal::Payslip.from_row(row) }
  end

  def request_verification_token
    @request_verification_token ||= PXMyPortal::RequestVerificationToken.new(
      http: @http,
      company: @company,
      cookie: @cookie,
    ).get
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end

  def initialize(debug: false,
                 cookie_jar_path: nil,
                 payslips_path: File.join(ENV["XDG_DATA_HOME"],
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
