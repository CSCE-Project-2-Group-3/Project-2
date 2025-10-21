class ParserCoordinator
  def initialize(receipt)
    @receipt = receipt
  end

  # returns true/false
  def process!
    # 1) Preprocess image
    prepped_path = ImagePreprocessor.new(@receipt.file).run
    engine = (ENV["USE_GOOGLE_VISION"] == "true") ? :google : :tesseract
    ocr_result = OcrService.new(prepped_path, engine: engine).perform

    # 3) Extract amounts, dates, merchant using basic heuristics
    amounts = AmountExtractor.new(ocr_result).call
    merchant = extract_merchant(ocr_result)
    date = extract_date(ocr_result)

    # compose candidates: amounts enriched with merchant/date/category
    candidates = amounts.map do |a|
      a.merge("merchant" => merchant, "date" => date, "category" => categorize(ocr_result, merchant))
    end

    @receipt.update(ocr_raw: ocr_result[:text], ocr_metadata: ocr_result[:meta], candidates: candidates, status: "processed")
    true
  rescue => e
    Rails.logger.error "ParserCoordinator error: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    @receipt.update(status: "failed")
    false
  end

  private

  # Very simple merchant heuristic: first non-empty line without words "receipt" or "invoice"
  def extract_merchant(ocr)
    lines = (ocr[:text] || "").lines.map(&:strip).reject(&:blank?)
    merchant = lines.first(5).find { |ln| ln.present? && ln.downcase !~ /\b(receipt|invoice|tax|total)\b/ }
    merchant
  end

  def extract_date(ocr)
    text = ocr[:text] || ""
    # common date patterns
    patterns = [
      /\b(\d{4}-\d{2}-\d{2})\b/,        # 2023-10-21
      /\b(\d{2}\/\d{2}\/\d{4})\b/,      # 10/21/2023 or 21/10/2023
      /\b(\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)\b/i,
      /\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}\b/i
    ]
    patterns.each do |pat|
      m = text.match(pat)
      next unless m
      begin
        d = Date.parse(m[0])
        return d
      rescue
        next
      end
    end
    nil
  end

  def categorize(ocr, merchant)
    t = (ocr[:text] || "").downcase
    return Category.find_by(name: "Rent")&.id if t.match?(/rent|lease|apartment|landlord/) || (merchant && merchant.downcase.match?(/rent|lease/))
    return Category.find_by(name: "Utilities")&.id if t.match?(/electric|utility|water|gas|utility bill|account number|amount due/) 
    return Category.find_by(name: "Groceries")&.id if t.match?(/grocery|supermarket|grocery store|produce/)
    return Category.find_by(name: "Dining")&.id if t.match?(/restaurant|dine|cafe|bar|gratuity|tip/)
    return Category.find_by(name: "Travel")&.id if t.match?(/uber|lyft|flight|airlines|hotel|motel/)
    return Category.find_by(name: "Price Tag")&.id if t.match?(/price|tag|sku/)
    nil
  end
end
