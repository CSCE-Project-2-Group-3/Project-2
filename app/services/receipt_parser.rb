class ReceiptParser
  # Entry point
  def self.parse_receipt(image_path)
    ocr = OcrService.new(image_path)
    ocr_result = ocr.perform
    text = ocr_result[:text].to_s

    # Extract all numeric values, fixing decimal issues
    detected_amounts = extract_amounts(text)

    inferred_total = infer_total(text, detected_amounts)

    {
      success: text.present?,
      raw_text: text,
      detected_amounts: detected_amounts,
      inferred_total: inferred_total,
      meta: ocr_result[:meta]
    }
  end

  # -------------------------------------------------------------------------
  # Extract numbers in a robust way (handles OCR decimal errors)
  # -------------------------------------------------------------------------
  def self.extract_amounts(text)
    numbers = []

    text.scan(/\$?\s*(\d+(?:[.,]\d{1,2})?)/).flatten.each do |n|
      num = n.gsub(/[^\d.,]/, "").tr(",", ".")
      num = fix_merged_decimals(num)
      numbers << num.to_f if num.to_f > 0
    end

    numbers.uniq.sort
  end

  def self.fix_merged_decimals(num)
    return num if num.include?(".")
    if num.length > 2
      int_part = num[0..-3]
      dec_part = num[-2..]
      return "#{int_part}.#{dec_part}"
    end
    num
  end

  # -------------------------------------------------------------------------
  # Try to infer the *actual total* from context keywords
  # -------------------------------------------------------------------------
  def self.infer_total(text, detected)
    return nil if detected.empty?

    normalized = text.downcase

    # Split into lines for better context
    lines = normalized.split("\n")

    # Prefer a line that includes "total" but not "subtotal"
    total_line = lines.find { |l| l.include?("total") && !l.include?("subtotal") }

    if total_line
      # Try to extract a number from that specific line
      match = total_line.match(/(\d+[.,]?\d*)/)
      if match
        raw_val = match[1].gsub(",", ".")
        val = fix_merged_decimals(raw_val)
        return val.to_f
      end
    end

    # Try global context match for "total"
    context_match = normalized.match(/(?:total|amount\s*due|balance)[^\d]*(\d+[.,]?\d*)/)
    if context_match
      raw_val = context_match[1].gsub(",", ".")
      val = fix_merged_decimals(raw_val)
      return val.to_f
    end

    # Fallback: choose the highest plausible value
    plausible = detected.select { |a| a > 0.1 && a < 10_000 }
    plausible.max
  end
end
