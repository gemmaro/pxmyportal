require "net/http"

class PXMyPortal::PayslipList
  def initialize(path:, debug:, logger:, cookie:, http:)
    @path = path
    @debug = debug
    @logger = logger
    @cookie = cookie
    @http = http

    @request = Net::HTTP::Get.new(@path)
  end

  def get
    @debug and @logger.debug("request") { @request }

    @cookie.provide(@request, url: build_url(@path))
    response = @http.request(@request)
    @debug and @logger.debug("response") { response }
    response => Net::HTTPOK
    response.body
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end
end
