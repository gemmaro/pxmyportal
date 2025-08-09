require "pstore"
require "forwardable"
require_relative "xdg"

class PXMyPortal::CookieStore
  def initialize
    store_path = File.join(PXMyPortal::XDG::CACHE_DIR, "cookie.pstore")
    @store = PStore.new(store_path)
  end

  extend Forwardable
  def_delegators :@store, :transaction, :[], :[]=, :keys
end
