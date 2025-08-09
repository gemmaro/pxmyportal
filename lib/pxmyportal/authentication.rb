require "net/http"
require_relative "xdg"
require_relative "page"

class PXMyPortal::Authentication
  def initialize(path:, cookie:, user:, password:, token:, http:, logger:)
    @path = path
    @cookie = cookie
    @user = user
    @password = password
    @token = token
    @http = http
    @logger = logger

    @request = Net::HTTP::Post.new(@path)
  end

  def post
    @cookie.provide(@request, url: build_url(@path))

    @request.form_data = {
      LoginId: @user,
      Password: @password,
      "__RequestVerificationToken" => @token,
    }
    response = @http.request(@request)
    begin
      response => Net::HTTPFound | Net::HTTPOK
    rescue => e
      File.write(File.join(PXMyPortal::XDG::CACHE_DIR, "authentication.html"),
                 response.body)
      raise e
    end

    @logger.debug("response") { response.to_hash }
    page = PXMyPortal::Page.from_path(response["location"] || @path)
    unless page
      @logger.error("location") { response["location"] }
      raise PXMyPortal::Error, "unexpected location"
    end
    @cookie.accept(response, url: build_url(page.path))
    page
  end

  def build_url(path, query: nil)
    URI::HTTPS.build(host: PXMyPortal::HOST, path:, query:)
  end
end
