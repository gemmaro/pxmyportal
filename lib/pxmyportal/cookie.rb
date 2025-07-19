require "http-cookie" # Use CGI::Cookie?
require_relative "xdg"

class PXMyPortal::Cookie
  def initialize(jar_path: nil, logger:)
    @jar_path = jar_path || File.join(PXMyPortal::XDG::CACHE_DIR, "cookie-jar")
    @logger = logger

    @jar             = HTTP::CookieJar.new
  end

  def load
    @jar.load(@jar_path) if File.exist?(@jar_path)
  end

  # Previously accept_cookie.
  def accept(response, url:)
    [*response.get_fields("Set-Cookie"), *response.get_fields("set-cookie")].each { |value| @jar.parse(value, url) }
    @jar.save(jar_path)
  end

  # Previously cookie_jar_path.
  def jar_path
    @created_jar_path and return @created_jar_path
    dir = File.dirname(@jar_path)
    unless Dir.exist?(dir)
      @logger.info("creating cache directory")
      Dir.mkdir(dir)
    end
    @created_jar_path = @jar_path
  end

  # Previously provide_cookie.
  def provide(request, url:)
    request["Cookie"] = HTTP::Cookie.cookie_value(@jar.cookies(url))
  end
end
