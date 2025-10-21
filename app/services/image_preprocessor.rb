require "image_processing/mini_magick"

class ImagePreprocessor
  # Accepts an ActiveStorage attachment or path
  def initialize(attachment)
    @attachment = attachment
  end

  # Returns a path to a preprocessed tempfile (PNG)
  def run
    io = @attachment.download
    tmpfile = Tempfile.new(["receipt", ".png"], binmode: true)
    tmpfile.write(io)
    tmpfile.rewind

    pipeline = ImageProcessing::MiniMagick
      .source(tmpfile.path)
      .convert("png")
      .resize_to_limit(1600, 1600)
      .saver(quality: 85)

    output = pipeline.call(dest: tmpfile.path + ".proc.png")
    tmpfile.close
    tmpfile.unlink
    output
  end
end
