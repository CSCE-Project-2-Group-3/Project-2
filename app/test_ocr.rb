require_relative "../config/environment"

image_path = "/mnt/c/Users/qacer/Downloads/payment1.png"

puts "Starting OCR test..."
puts "Using image path: #{image_path}"
puts "File exists? #{File.exist?(image_path)}"

result = ReceiptParser.parse_receipt(image_path)
puts "Got result: #{result.inspect}"

if result.is_a?(Hash)
  puts "OCR Engine: #{result.dig(:meta, :engine)}"
  puts "Detected text (first 400 chars):"
  puts result[:raw_text].to_s[0..400]
  puts "Detected amounts: #{result[:detected_amounts]}"
  puts "Inferred total: #{result[:inferred_total]}"
else
  puts "parse_receipt did not return a Hash! Got: #{result.class}"
end
