require "net/http"

class PXMyPortal::DocumentDownloader
  def initialize(path:, cookie:, form_data:, logger:, http:)
    @path = path
    @cookie = cookie
    @form_data = form_data
    @logger = logger
    @http = http

    @request = Net::HTTP::Post.new(@path)
  end

  def post
    @cookie.provide(@request, url: build_url(@path))
    @request.form_data = @form_data
    @logger.debug("request") { @request }

    response = @http.request(@request)
    response => Net::HTTPOK
    @logger.debug("response") { response.to_hash }
    response.to_hash["content-type"] => ["application/pdf"]
    response.body
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end
end
