class PXMyPortal::XDG
  CACHE_DIR = File.join(ENV["XDG_CACHE_HOME"], "pxmyportal")
  DOC_DIR = File.join(ENV["XDG_DOCUMENTS_DIR"] || File.join(Dir.home, "Documents"),
                      "pxmyportal")
end
