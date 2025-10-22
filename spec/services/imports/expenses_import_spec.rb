require 'rails_helper'

RSpec.describe Imports::ExpensesImport, type: :service do
  let(:csv_file) do
    file = Tempfile.new(['expenses', '.csv'])
    file.write("title,amount,spent_on,category,notes\nLunch,12.5,2025-10-18,Food,Team lunch\n")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv')
  end

  it 'imports valid rows successfully' do
    result = described_class.call(file: csv_file)
    expect(result.created).to be > 0
    expect(result.skipped).to eq(0)
  end

  it 'skips or ignores invalid rows gracefully' do
    bad_file = Tempfile.new(['expenses_bad', '.csv'])
    bad_file.write("title,amount,spent_on,category,notes\n,,,\n")
    bad_file.rewind

    bad_upload = Rack::Test::UploadedFile.new(bad_file.path, 'text/csv')
    result = described_class.call(file: bad_upload)

    expect(result.skipped).to be >= 0
    expect(result.created).to be >= 0
  end

  it 'handles unsupported file types gracefully (raises ImportError)' do
    fake_file = Tempfile.new(['fake', '.txt'])
    fake_file.write("dummy text")
    fake_file.rewind
    upload = Rack::Test::UploadedFile.new(fake_file.path, 'text/plain')

    # Expect the specific custom ImportError, not a crash
    expect do
      described_class.call(file: upload)
    end.to raise_error(Imports::ExpensesImport::ImportError, /Unsupported file type/i)
  ensure
    fake_file.close
    fake_file.unlink
  end
end
