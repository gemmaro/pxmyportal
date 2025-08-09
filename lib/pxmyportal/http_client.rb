require "net/http"
require "forwardable"
require_relative "cookie"

class PXMyPortal::HTTPClient
  def initialize(debug: false, logger:, cookie_jar_path:)
    @http = Net::HTTP.new(PXMyPortal::HOST, Net::HTTP.https_default_port)
    @http.use_ssl = true
    @http.set_debug_output($stderr) if debug

    @cookie = PXMyPortal::Cookie.new(jar_path: cookie_jar_path, logger:)
  end

  def start
    @http.started? or @http.start
  end

  extend Forwardable
  def_delegators :@http, :get, :request, :set_debug_output, :started?
  def_delegator :@cookie, :provide, :provide_cookie
  def_delegator :@cookie, :accept, :accept_cookie
  def_delegator :@cookie, :load, :load_cookie
end
