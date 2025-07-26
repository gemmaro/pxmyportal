require "net/http"
require "nokogiri"
require_relative "http_client"
require_relative "page"

class PXMyPortal::RequestVerificationToken
  def initialize(http:, company:, cookie:)
    @http = http
    @company = company
    @cookie = cookie
  end

  def get
    @http.start

    path = File.join(PXMyPortal::Page::BASEPATH, "Auth/Login")
    query = @company
    response = @http.get("#{path}?#{query}")
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
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end
end
