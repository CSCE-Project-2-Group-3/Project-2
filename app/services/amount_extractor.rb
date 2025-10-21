class AmountExtractor
  AMOUNT_RE = /
    (?:USD|EUR|\$|£|€|\¥)?\s*
    (?:
      \d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})
      |
      \d+(?:[.,]\d{2})
    )
  /x

  KEYWORDS = %w[total amount due balance due grand total amt subtotal]

  def initialize(ocr_hash)
    @text = ocr_hash[:text] || ""
    @words = ocr_hash[:words_with_boxes] || []
  end

  def call
    candidates = []
    # scan with regex
    @text.scan(AMOUNT_RE) do
      token = Regexp.last_match[0]
      ln = find_line_for_token(token)
      bbox = nil
      score = baseline_score(token, ln)
      candidates << {
        "raw" => token.strip,
        "normalized" => normalize_amount(token),
        "currency" => detect_currency(token),
        "bbox" => bbox,
        "context_line" => ln,
        "score" => score
      }
    end

    # boost lines with keywords
    candidates.each do |c|
      if c["context_line"] && c["context_line"].downcase.match?(/\b(#{KEYWORDS.join("|")})\b/)
        c["score"] = (c["score"] || 0) + 3
      end
    end

    # dedupe by normalized
    uniq = {}
    candidates.each do |c|
      key = c["normalized"].to_s
      if key.present?
        uniq[key] ||= c
        uniq[key]["score"] = [uniq[key]["score"], c["score"]].max
      end
    end

    uniq.values.sort_by { |c| -(c["score"] || 0) }.first(6)
  end

  private

  def find_line_for_token(token)
    @text.lines.find { |ln| ln.include?(token) }
  end

  def normalize_amount(token)
    s = token.gsub(/[^\d.,-]/, '')
    # if both comma and dot => assume comma is thousands
    if s.count(",") > 0 && s.count(".") > 0
      s = s.gsub(',', '')
    elsif s.count(",") > 0 && s.count(".") == 0
      # if comma has exactly two trailing digits assume decimal
      if s.match(/,\d{2}$/)
        s = s.tr(',', '.')
      else
        s = s.gsub(',', '')
      end
    end
    BigDecimal(s)
  rescue
    nil
  end

  def detect_currency(token)
    return "USD" if token.include?("$")
    return "EUR" if token.include?("€") || token.match?(/\beuro/i)
    return "GBP" if token.include?("£")
    "USD"
  end

  def baseline_score(token, line)
    score = 0
    score += 1 if line && (@text.lines.index(line) || 0) >= (@text.lines.size * 0.5)
    score += 1 if token.length < 12
    score
  end
end
