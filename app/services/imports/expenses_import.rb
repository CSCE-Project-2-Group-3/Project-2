# app/services/imports/expenses_import.rb
require "roo"
module Imports
  class ExpensesImport
    Result = Struct.new(:created, :skipped, keyword_init: true)
    class ImportError < StandardError; end

    def self.call(file:)
      new(file).call
    end

    def initialize(file)
      @file = file
      @created = 0
      @skipped = 0
    end

    def call
      spreadsheet = open_spreadsheet(@file)
      header = spreadsheet.row(1).map { |h| h.to_s.strip.downcase }
      required = %w[title amount spent_on category]
      missing = required - header
      raise ImportError, "Missing columns: #{missing.join(', ')}" if missing.any?

      (2..spreadsheet.last_row).each do |i|
        row = Hash[[ header, spreadsheet.row(i) ].transpose]
        next if row.values.all?(&:blank?)

        begin
          category = Category.find_or_create_by!(name: row["category"].to_s.strip)
          Expense.create!(
            title: row["title"],
            amount: BigDecimal(row["amount"].to_s),
            spent_on: Date.parse(row["spent_on"].to_s),
            notes: row["notes"],
            category: category
          )
          @created += 1
        rescue => e
          @skipped += 1
          Rails.logger.warn("Row #{i} skipped: #{e.message}")
        end
      end
      Result.new(created: @created, skipped: @skipped)
    end

    private

    def open_spreadsheet(file)
      case File.extname(file.original_filename)
      when ".xlsx" then Roo::Excelx.new(file.tempfile.path)
      when ".csv"  then Roo::CSV.new(file.tempfile.path)
      else
        raise ImportError, "Unsupported file type."
      end
    end
  end
end
