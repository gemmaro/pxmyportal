require "fileutils"

# Previously @phase.
class PXMyPortal::Page
  BASEPATH = "/pmpwps/"
  CLIENT_BASEPATH = File.join(BASEPATH, "pc/")

  SAMPLE_PATH = File.join(CLIENT_BASEPATH, "SalaryPayslipSample")
  NORMAL_PATH = File.join(CLIENT_BASEPATH, "SalaryPayslip")
  BONUS_PATH = File.join(CLIENT_BASEPATH, "BonusPayslip")

  attr_reader :path, :confirm_path

  def initialize(path:, confirm_path:, cache_filename:, row_xpath:)
    @path = path

    # Previously confirm_pdf_frame_path.
    @confirm_path = confirm_path

    @cache_filename = cache_filename
    @row_xpath = row_xpath
  end

  def cache_path
    @cache_path and return @cache_path
    @cache_path = File.join(PXMyPortal::XDG::CACHE_DIR, "debug", "page", "#{@cache_filename}.html")

    dir = File.dirname(@cache_path)
    unless Dir.exist?(dir)
      FileUtils.mkdir_p(dir)
    end
    @cache_path
  end

  def rows(source)
    Nokogiri::HTML(source).xpath(@row_xpath)
  end

  def inspect
    "#<Page #{@cache_filename}>"
  end

  normal_row_xpath = "//*[@id='ContentPlaceHolder1_PayslipGridView']//tr"

  # Previously PAYSLIP_PAGE_PATH_SAMPLE.
  SAMPLE = new(
    path: SAMPLE_PATH,
    confirm_path: File.join(CLIENT_BASEPATH, "ConfirmSamplePDFFrame"),
    cache_filename: "sample", row_xpath: normal_row_xpath)

  production_confirm_path = "ConfirmPDFFrame"

  # Previously PAYSLIP_PAGE_PATH_NORMAL.
  NORMAL = new(path: NORMAL_PATH,
               confirm_path: File.join(CLIENT_BASEPATH, production_confirm_path),
               cache_filename: "normal", row_xpath: normal_row_xpath)

  # Previously PAYSLIP_PAGE_PATH_BONUS.
  BONUS = new(path: BONUS_PATH, confirm_path: production_confirm_path,
              cache_filename: "bonus",
              row_xpath: "//*[@id='ContentPlaceHolder1_BonusPayslipGridView']//tr")

  def self.from_path(path)
    { SAMPLE_PATH => SAMPLE, NORMAL_PATH => NORMAL, BONUS_PATH => NORMAL }[path]
  end
end
