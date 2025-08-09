require "net/http"

class PXMyPortal::PayslipList
  def initialize(path:, logger:, http:)
    @path = path
    @logger = logger
    @http = http

    @request = Net::HTTP::Get.new(@path)
  end

  def get
    @logger.debug("request") { @request }

    @http.provide_cookie(@request, url: build_url(@path))
    response = @http.request(@request)
    @logger.debug("response") { response }
    response => Net::HTTPOK
    response.body
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end
end
