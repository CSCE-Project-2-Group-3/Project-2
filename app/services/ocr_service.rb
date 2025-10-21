# app/services/ocr_service.rb
require "mini_magick"
require "rtesseract"

class OcrService
  # Automatically choose engine: Google if credentials are set, otherwise Tesseract.
  def initialize(image_path, engine: nil)
    @image_path = image_path
    @engine =
      engine ||
      (ENV["GOOGLE_APPLICATION_CREDENTIALS"].present? ? :google : :tesseract)
  end

  # Run OCR and return normalized result
  # => { text: "...", words_with_boxes: [...], meta: { engine: "google" } }
  def perform
    case @engine.to_sym
    when :google
      perform_google
    else
      perform_tesseract
    end
  end

  private

  # 🔹 Preprocess image to improve OCR quality
  def preprocess_image
    src = @image_path
    image = MiniMagick::Image.open(src)
    image.format "png"
    image.colorspace "Gray"
    image.auto_level
    image.normalize
    image.contrast
    image.sharpen "0x1"
    image.resize "1600x1600>"
    out = Rails.root.join("tmp", "ocr_preprocessed_#{SecureRandom.hex(8)}.png").to_s
    image.write(out)
    out
  end

  # 🔹 Local fallback using Tesseract
  def perform_tesseract
    prepped = preprocess_image
    t = RTesseract.new(prepped, lang: "eng", options: { oem: 1, psm: 6 })
    text = t.to_s
    File.delete(prepped) if File.exist?(prepped)

    {
      text: text.to_s.strip,
      words_with_boxes: nil,
      meta: { engine: "tesseract" }
    }
  rescue => e
    Rails.logger.error("[OCR] Tesseract failed: #{e.message}")
    { text: "", words_with_boxes: nil, meta: { engine: "tesseract", error: e.message } }
  end

  # 🔹 Primary: Google Cloud Vision OCR
  def perform_google
    require "google/cloud/vision"

    prepped = preprocess_image
    client = Google::Cloud::Vision.image_annotator
    response = client.document_text_detection image: prepped
    annotation = response.responses.first
    File.delete(prepped) if File.exist?(prepped)

    # Extract full text
    full_text =
      annotation&.full_text_annotation&.text.presence ||
      annotation&.text_annotations&.first&.description.to_s

    # Extract per-word bounding boxes (optional)
    words = []
    if annotation.respond_to?(:to_h)
      h = annotation.to_h
      (h.dig(:full_text_annotation, :pages) || []).each do |page|
        (page[:blocks] || []).each do |block|
          (block[:paragraphs] || []).each do |para|
            (para[:words] || []).each do |w|
              text = (w[:symbols] || []).map { |s| s[:text] }.join
              bbox = w.dig(:bounding_box, :vertices)
              words << { text: text, bbox: bbox }
            end
          end
        end
      end
    end

    {
      text: full_text.to_s.strip,
      words_with_boxes: words.presence,
      meta: { engine: "google" }
    }
  rescue LoadError
    Rails.logger.error("[OCR] google-cloud-vision gem not installed, using Tesseract fallback")
    perform_tesseract
  rescue => e
    Rails.logger.error("[OCR] Google Vision failed: #{e.message}")
    perform_tesseract
  end
end
