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
  def let_redirect
    token = request_verification_token
    request = Net::HTTP::Post.new(PXMyPortal::Page::BASEPATH)
    @cookie.provide(request, url: build_url(PXMyPortal::Page::BASEPATH))

    data = { LoginId: @user,
             Password: @password,
             "__RequestVerificationToken" => token }
    request.form_data = data
    response = http.request(request)
    begin
      response => Net::HTTPFound
    rescue => e
      File.write(File.join(PXMyPortal::XDG::CACHE_DIR, "debug", "let_redirect.html"),
                 response.body)
      raise e
    end

    @page = PXMyPortal::Page.from_path(response["location"]) \
      or raise PXMyPortal::Error, "unexpected location #{location}"
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

        response = http.request(request)
        response => Net::HTTPOK
        @logger.debug("response") { response.to_hash }
        # response.to_hash["content-type"] => ["application/pdf"]

        FileUtils.mkdir_p(payslip.directory)
        @logger.info("saving payslip...") { payslip.filename }
        File.write(payslip.filename, response.body) unless @test
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
    response = http.request(request)
    @debug and @logger.debug("response") { response }
    response => Net::HTTPOK

    File.write(page.cache_path, response.body)
    page.rows(response.body)
      .map { |row| PXMyPortal::Payslip.from_row(row, directory: @payslip_dir) }
  end

  def request_verification_token
    return @request_verification_token if @request_verification_token

    @debug_http and http.set_debug_output($stderr)
    http.start
    path = File.join(PXMyPortal::Page::BASEPATH, "Auth/Login")
    query = @company
    response = http.get("#{path}?#{query}")
    response => Net::HTTPOK

    @cookie.load
    @cookie.accept(response, url: build_url(path, query:))

    document = Nokogiri::HTML(response.body)
    token = <<~XPATH
      //form//input[     @type='hidden'
                     and @name='__RequestVerificationToken' ]
      /@value
    XPATH
    document.xpath(token) => [token]
    token or raise Error, token
    @request_verification_token = token
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
                 payslip_dir: nil,
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
  end

  def http
    return @http if @http

    http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    http.use_ssl = true
    @http = http
  end
end
