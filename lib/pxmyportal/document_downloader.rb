require "net/http"

class PXMyPortal::DocumentDownloader
  def initialize(path:, form_data:, logger:, http:)
    @path = path
    @form_data = form_data
    @logger = logger
    @http = http

    @request = Net::HTTP::Post.new(@path)
  end

  def post
    @http.provide_cookie(@request)
    @request.form_data = @form_data
    @logger.debug("request") { @request }

    response = @http.request(@request)
    response => Net::HTTPOK
    @logger.debug("response") { response.to_hash }
    response.to_hash["content-type"] => ["application/pdf"]
    response.body
  end
end
