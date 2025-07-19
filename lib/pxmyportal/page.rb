# Previously @phase.
class PXMyPortal::Page
  BASEPATH = "/pmpwps/"
  CLIENT_BASEPATH = File.join(BASEPATH, "pc/")

  SAMPLE_PATH = File.join(CLIENT_BASEPATH, "SalaryPayslipSample")
  NORMAL_PATH = File.join(CLIENT_BASEPATH, "SalaryPayslip")
  BONUS_PATH = File.join(CLIENT_BASEPATH, "BonusPayslip")

  attr_reader :path, :confirm_path

  def initialize(path:, confirm_path:)
    @path = path

    # Previously confirm_pdf_frame_path.
    @confirm_path = confirm_path
  end

  # Previously PAYSLIP_PAGE_PATH_SAMPLE.
  SAMPLE = new(
    path: SAMPLE_PATH,
    confirm_path: File.join(CLIENT_BASEPATH, "ConfirmSamplePDFFrame"))

  # Previously PAYSLIP_PAGE_PATH_NORMAL.
  NORMAL = new(path: NORMAL_PATH,
               confirm_path: File.join(CLIENT_BASEPATH, "ConfirmPDFFrame"))

  # Previously PAYSLIP_PAGE_PATH_BONUS.
  BONUS = new(path: BONUS_PATH, confirm_path: :TODO)

  def self.from_path(path)
    { SAMPLE_PATH => SAMPLE, NORMAL_PATH => NORMAL, BONUS_PATH => NORMAL }[path]
  end
end
