require "ostruct"

class DashboardDataService
  attr_reader :user, :params, :expenses

  def initialize(user, params = {})
    @user = user
    @params = params
    @expenses = fetch_filtered_expenses
  end

  def fetch_data
    personal_expenses = @expenses.where(group_id: nil)
    group_expenses = @expenses.where.not(group_id: nil)

    OpenStruct.new(
      categories: Category.all,
      personal_total: personal_expenses.sum(:amount),
      group_total: group_expenses.sum(:amount),
      recent_personal_expenses: personal_expenses.order(spent_on: :desc).limit(5),
      recent_group_expenses: group_expenses.order(spent_on: :desc).limit(5),
      top_5_largest_personal_expenses: @expenses.order(amount: :desc).limit(5),
      spending_over_time: calculate_spending_over_time(@expenses),
      category_data: calculate_category_data(@expenses)
    )
  end

  private

  def fetch_filtered_expenses
    scope = user.expenses.includes(:category, :group)

    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = scope.where("spent_on >= ?", params[:start_date]) if params[:start_date].present?
    scope = scope.where("spent_on <= ?", params[:end_date]) if params[:end_date].present?

    scope
  end

  def calculate_spending_over_time(filtered_scope)
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    daily_data = filtered_scope.where(spent_on: start_date..end_date)
                                .group_by_day(:spent_on)
                                .sum(:amount)

    # Fill missing days with zero for complete chart data
    (start_date..end_date).each_with_object({}) do |day, hash|
      hash[day.strftime("%Y-%m-%d")] = daily_data[day] || 0
    end
  end

  def calculate_category_data(filtered_scope)
    # Use left_outer_joins to include expenses with nil category_id
    category_summary = filtered_scope.left_outer_joins(:category)
                                      .group("categories.name")
                                      .sum(:amount)

    OpenStruct.new(
      labels: category_summary.keys,
      data: category_summary.values
    )
  end
end
