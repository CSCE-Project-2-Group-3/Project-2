require 'rails_helper'
require 'ostruct'

RSpec.describe DashboardAiAnalyzerService, type: :service do
  # Create a mock data object that mimics the DashboardDataService
  let(:mock_data) do
    OpenStruct.new(
      personal_total: 150,
      group_total: 800,
      recent_personal_expenses: [
        OpenStruct.new(title: 'Groceries')
      ],
      top_5_largest_personal_expenses: [
        OpenStruct.new(title: 'Rent', amount: 800)
      ],
      spending_over_time: { "2025-10-01" => 100, "2025-10-02" => 50 },
      category_data: OpenStruct.new(
        labels: [ "Housing", "Food" ],
        data: [ 800, 150 ]
      )
    )
  end

  let(:analyzer) { described_class.new(mock_data) }

  describe "#generate_main_summary" do
    it "generates a placeholder summary" do
      # We test the placeholder, but in a real app you'd stub the AI call
      expect(analyzer.generate_main_summary).to include("$150")
      expect(analyzer.generate_main_summary).to include("Housing")
    end
  end

  describe "#generate_widget_summary" do
    it "generates personal_expenses summary" do
      expect(analyzer.generate_widget_summary(:personal_expenses)).to include("$150")
      expect(analyzer.generate_widget_summary(:personal_expenses)).to include("Groceries")
    end

    it "generates group_expenses summary" do
      expect(analyzer.generate_widget_summary(:group_expenses)).to include("$800")
    end

    it "generates top_5_expenses summary" do
      expect(analyzer.generate_widget_summary(:top_5_expenses)).to include("Rent")
    end

    it "generates spending_over_time summary" do
      expect(analyzer.generate_widget_summary(:spending_over_time)).to include("peaks and valleys")
    end

    it "generates category_spending summary" do
      expect(analyzer.generate_widget_summary(:category_spending)).to include("Housing")
      expect(analyzer.generate_widget_summary(:category_spending)).to include("long tail")
    end

    it "handles an unknown type" do
      expect(analyzer.generate_widget_summary(:unknown_widget)).to eq("No analysis available.")
    end
  end
end
