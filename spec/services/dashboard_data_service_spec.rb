require 'rails_helper'
require 'ostruct'

RSpec.describe DashboardDataService, type: :service do
  let!(:user) { create(:user) }
  let!(:food_category) { create(:category, name: 'Food') }
  let!(:rent_category) { create(:category, name: 'Housing') }
  let!(:group) { create(:group, users: [ user ]) }

  let!(:personal_expense) {
    create(:expense, user: user, category: food_category, amount: 50, spent_on: 1.day.ago)
  }
  let!(:group_expense) {
    create(:expense, user: user, category: rent_category, amount: 1000, spent_on: 2.days.ago, group: group)
  }
  let!(:old_expense) {
    create(:expense, user: user, category: food_category, amount: 10, spent_on: 40.days.ago)
  }

  context "with no filters" do
    it "fetches all data" do
      data = described_class.new(user).fetch_data

      expect(data.personal_total).to eq(60) # 50 + 10
      expect(data.group_total).to eq(1000)
      expect(data.recent_personal_expenses).to eq([ personal_expense, old_expense ])
      expect(data.top_5_largest_personal_expenses.first).to eq(group_expense)

      # Test chart data
      expect(data.category_data.labels).to match_array([ "Food", "Housing" ])
      expect(data.category_data.data).to match_array([ 60, 1000 ])

      # Test spending over time (default 30 days)
      expect(data.spending_over_time[1.day.ago.strftime("%Y-%m-%d")]).to eq(50)
      expect(data.spending_over_time[2.days.ago.strftime("%Y-%m-%d")]).to eq(1000)
      expect(data.spending_over_time[40.days.ago.strftime("%Y-%m-%d")]).to be_nil
    end
  end

  context "with filters" do
    it "applies a category filter" do
      params = { category_id: food_category.id }
      data = described_class.new(user, params).fetch_data

      expect(data.personal_total).to eq(60)
      expect(data.group_total).to eq(0)
      expect(data.category_data.labels).to match_array([ "Food" ])
    end

    it "applies a date filter" do
      params = { start_date: 3.days.ago.to_s, end_date: Date.today.to_s }
      data = described_class.new(user, params).fetch_data

      expect(data.personal_total).to eq(50) # Omits old_expense
      expect(data.group_total).to eq(1000)
    end
  end
end
