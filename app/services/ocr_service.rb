require "mini_magick"
require "rtesseract"
require "google/cloud/vision"

class OcrService
  def initialize(image_path, engine: nil)
    @image_path = image_path
    @engine =
      engine ||
      (ENV["GOOGLE_APPLICATION_CREDENTIALS"].present? ? :google : :tesseract)
  end

  def perform
    result =
      case @engine.to_sym
      when :google then perform_google
      else perform_tesseract
      end

    # Fallback: if Tesseract result seems weak, retry with Google Vision
    if result[:meta][:engine] == "tesseract" &&
       (result[:text].strip.empty? || result[:text].length < 50)
      Rails.logger.info("[OCR] Fallback to Google Vision due to weak Tesseract result")
      google_result = perform_google rescue nil
      result = google_result if google_result && google_result[:text].present?
    end

    result
  end

  private

  # Step 1. Preprocess image to improve OCR quality
  def preprocess_image
    image = MiniMagick::Image.open(@image_path)

    image.format "png"
    image.auto_orient
    image.colorspace "Gray"
    image.auto_level
    image.contrast
    image.normalize
    image.sharpen "0x1"
    image.deskew "40%" rescue nil # straighten slight tilt
    image.resize "1600x1600>"
    image.blur "1x1"
    image.threshold("60%")

    out = Rails.root.join("tmp", "ocr_preprocessed_#{SecureRandom.hex(8)}.png").to_s
    image.write(out)
    out
  end

  # Step 2. Local OCR (Tesseract)
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

  # Step 3. Cloud OCR (Google Vision)
  def perform_google
    prepped = preprocess_image
    client = Google::Cloud::Vision.image_annotator
    response = client.document_text_detection image: prepped
    File.delete(prepped) if File.exist?(prepped)

    annotation = response.responses.first
    full_text =
      annotation&.full_text_annotation&.text.presence ||
      annotation&.text_annotations&.first&.description.to_s

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
