# app/services/receipt_parser.rb
class ReceiptParser
  # Smarter price pattern that catches: $12.99, 12,99, 12.99, Total: 12.99, etc.
  PRICE_REGEX = /
    (?:total\s*[:\-]?\s*)?   # optional label
    \$?\s*                   # optional dollar sign
    (\d{1,6}(?:[.,]\d{2})?)  # main number with optional decimals
  /ix.freeze

  def self.extract_amounts(text)
    return [] if text.blank?
    text.scan(PRICE_REGEX)
        .flatten
        .map { |m| m.tr(",", ".").gsub(/[^\d.]/, "").to_f }
        .reject(&:zero?)
        .uniq
  end

  def self.infer_total(amounts)
    return nil if amounts.empty?
    # Heuristic: totals are often the largest value but < $10,000
    amounts.reject { |a| a > 10000 }.max
  end

  def self.parse_receipt(image_path)
    # Run OCR (auto-picks Google Vision if available)
    ocr = OcrService.new(image_path)
    result = ocr.perform
    text = result[:text]

    return { success: false, message: "OCR returned empty text" } if text.blank?

    amounts = extract_amounts(text)
    total = infer_total(amounts)

    {
      success: true,
      raw_text: text,
      detected_amounts: amounts,
      inferred_total: total,
      meta: result[:meta]
    }
  rescue => e
    Rails.logger.error("[ReceiptParser] Error: #{e.message}")
    { success: false, message: e.message }
  end
end
