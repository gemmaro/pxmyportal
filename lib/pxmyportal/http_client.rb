require "net/http"
require "forwardable"

class PXMyPortal::HTTPClient
  def initialize(debug: false)
    @debug = debug

    @http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    @http.use_ssl = true
  end

  def start
    @http.started? and return
    @debug_http and @http.set_debug_output($stderr)
    @http.start
  end

  extend Forwardable
  def_delegators :@http, :start, :get, :request, :set_debug_output, :started?
end
