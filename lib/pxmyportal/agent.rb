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
require "http-cookie" # Use CGI::Cookie?
require "nokogiri"
require "logger"
require_relative "payslip"
require_relative "error"

class PXMyPortal::Agent
  PAYSLIP_PAGE_PATH_SAMPLE = File.join(PXMyPortal::CLIENT_BASEPATH, "SalaryPayslipSample")
  PAYSLIP_PAGE_PATH_NORMAL = File.join(PXMyPortal::CLIENT_BASEPATH, "SalaryPayslip")
  PAYSLIP_PAGE_PATH_BONUS = File.join(PXMyPortal::CLIENT_BASEPATH, "BonusPayslip")
  CACHE_DIR = File.join(ENV["XDG_CACHE_HOME"], "pxmyportal")

  def let_redirect
    token = request_verification_token
    path = PXMyPortal::BASEPATH
    request = Net::HTTP::Post.new(path)
    provide_cookie(request, url: build_url(path))

    data = { LoginId: @user,
             Password: @password,
             "__RequestVerificationToken" => token }
    request.form_data = data
    response = http.request(request)
    begin
      response => Net::HTTPFound
    rescue => e
      File.write(File.join(CACHE_DIR, "debug", "let_redirect.html"), response.body)
      raise e
    end

    case (location = response["location"])
    when PAYSLIP_PAGE_PATH_SAMPLE
      @phase = :sample
    when PAYSLIP_PAGE_PATH_NORMAL
      @phase = :normal
    when PAYSLIP_PAGE_PATH_BONUS
      @phase = :bonus
    else
      raise PXMyPortal::Error, "unexpected location #{location}"
    end
    accept_cookie(response, url: build_url(payslip_page_path))
    self
  end

  def save_payslips
    existing_payslips = (YAML.load_file(@payslips_path) rescue []) || []
    payslips.each do |payslip|
      if existing_payslips&.find { |candidate| payslip == candidate }
        $stderr.puts "skip #{payslip}"
        next
      end
      path = confirm_pdf_frame_path
      request = Net::HTTP::Post.new(path)
      provide_cookie(request, url: build_url(path))
      request.form_data = payslip.form_data
      response = http.request(request)
      response => Net::HTTPOK

      Dir.mkdir(payslip.directory) unless File.directory?(payslip.directory)
      File.write(payslip.filename, response.body) unless @test
      existing_payslips << payslip.metadata
    end
    
    File.open(@payslips_path, "w") { |file| YAML.dump(existing_payslips, file) } \
      unless @test

    self
  end

  private

  def payslip_page_path
    @payslip_page_path ||= { sample: PAYSLIP_PAGE_PATH_SAMPLE,
                             normal: PAYSLIP_PAGE_PATH_NORMAL,
                             bonus: PAYSLIP_PAGE_PATH_BONUS }[@phase]
  end

  def payslips
    return @payslips if @payslips

    request = Net::HTTP::Get.new(payslip_page_path)
    provide_cookie(request, url: build_url(payslip_page_path))
    response = http.request(request)
    response => Net::HTTPOK

    @payslips = Nokogiri::HTML(response.body)
                  .xpath("//*[@id='ContentPlaceHolder1_PayslipGridView']//tr")
                  .map { |row| PXMyPortal::Payslip.from_row(row, directory: @payslip_dir) }
  end

  def request_verification_token
    return @request_verification_token if @request_verification_token

    @debug and http.set_debug_output($stderr)
    http.start
    path = File.join(PXMyPortal::BASEPATH, "Auth/Login")
    query = @company
    response = http.get("#{path}?#{query}")
    response => Net::HTTPOK

    @jar.load(@cookie_jar_path) if File.exist?(@cookie_jar_path)
    accept_cookie(response, url: build_url(path, query:))

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

  def confirm_pdf_frame_path
    case @phase
    in :sample
      File.join(PXMyPortal::CLIENT_BASEPATH, "ConfirmSamplePDFFrame")
    in :normal
      File.join(PXMyPortal::CLIENT_BASEPATH, "ConfirmPDFFrame")
    end
  end

  def initialize(debug: false,
                 cookie_jar_path: File.join(CACHE_DIR, "cookie-jar"),
                 payslips_path: File.join(ENV["XDG_DATA_HOME"], "pxmyportal", "payslips.yaml"),
                 company:,
                 user:,
                 password:,
                 test: false,
                 payslip_dir: nil,
                 bonus_only: false)

    @company         = company
    @user            = user
    @password        = password
    @cookie_jar_path = cookie_jar_path
    @jar             = HTTP::CookieJar.new
    @debug           = debug
    @payslips_path   = payslips_path
    @test            = test
    @payslip_dir     = payslip_dir
    @bonus_only      = bonus_only

    @logger = Logger.new($stderr)
  end

  def http
    return @http if @http

    http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    http.use_ssl = true
    @http = http
  end

  def accept_cookie(response, url:)
    response.get_fields("Set-Cookie").each { |value| @jar.parse(value, url) }
    @jar.save(cookie_jar_path)
  end

  def cookie_jar_path
    @created_cookie_jar_path and return @created_cookie_jar_path
    unless Dir.exist?(CACHE_DIR)
      @logger.info("creating cache directory")
      Dir.mkdir(CACHE_DIR)
    end
    @created_cookie_jar_path = @cookie_jar_path
  end

  def provide_cookie(request, url:)
    request["Cookie"] = HTTP::Cookie.cookie_value(@jar.cookies(url))
  end
end
