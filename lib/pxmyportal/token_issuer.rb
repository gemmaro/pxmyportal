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
