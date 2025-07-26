require "net/http"
require "forwardable"

class PXMyPortal::HTTPClient
  def initialize
    @http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    @http.use_ssl = true
  end

  extend Forwardable
  def_delegators :@http, :start, :get, :request, :set_debug_output
end
