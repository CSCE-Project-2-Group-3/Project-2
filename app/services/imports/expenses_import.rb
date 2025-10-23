require "roo"

module Imports
  class ExpensesImport
    Result = Struct.new(:created, :skipped, keyword_init: true)
    class ImportError < StandardError; end

    def self.call(file:, user:)
      new(file, user).call
    end

    def initialize(file, user)
      @file = file
      @user = user
      @created = 0
      @skipped = 0
    end

    def call
      raise ImportError, "User must be provided." if @user.nil?

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
            category: category,
            user: @user
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
      ext  = File.extname(file&.original_filename.to_s)
      path = file&.tempfile&.path

      # :nocov: Defensive guard clauses (not part of normal flow)
      raise ImportError, "No file provided." if file.nil?
      raise ImportError, "Unsupported file type." unless %w[.csv .xlsx].include?(ext)
      # :nocov:

      ext == ".xlsx" ? Roo::Excelx.new(path) : Roo::CSV.new(path)
    end
  end
end
