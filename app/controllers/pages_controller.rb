class PagesController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!, only: [ :dashboard ]

  def home
  end

  def dashboard
    @categories = Category.all

    # Get all expenses for the current user (master scope)
    all_expenses = Expense.for_user(current_user.id)
                          .includes(:category, :user, :group)

    # Group expenses are not filtered by dashboard filters
    group_expenses_query = all_expenses.where.not(group_id: nil)
    @group_total = group_expenses_query.sum(:amount)
    @recent_group_expenses = group_expenses_query.order(spent_on: :desc).limit(5)

    # Personal expenses are filtered by category and date range
    personal_expenses_query = all_expenses.where(group_id: nil)

    personal_expenses_query = personal_expenses_query.where(category_id: params[:category_id]) if params[:category_id].present?
    personal_expenses_query = personal_expenses_query.where("spent_on >= ?", params[:start_date]) if params[:start_date].present?
    personal_expenses_query = personal_expenses_query.where("spent_on <= ?", params[:end_date]) if params[:end_date].present?

    @personal_total = personal_expenses_query.sum(:amount)
    @recent_personal_expenses = personal_expenses_query.order(spent_on: :desc).limit(5)
    @top_5_largest_personal_expenses = personal_expenses_query.order(amount: :desc).limit(5)

    # Chart data uses filtered personal expenses only
    @spending_over_time = personal_expenses_query.group_by_day(:spent_on,
                                                                last: 30,
                                                                format: "%b %d").sum(:amount)

    category_data = personal_expenses_query.joins(:category)
                                           .group("categories.name")
                                           .sum(:amount)

    @category_labels = category_data.keys
    @category_data = category_data.values

    # Generate AI summary using filtered personal and unfiltered group totals
    @ai_summary = get_ai_summary(
      personal_total: @personal_total,
      group_total: @group_total,
      category_data: category_data,
      top_expenses: @top_5_largest_personal_expenses
    )
  end

  private

  def get_ai_summary(personal_total:, group_total:, category_data:, top_expenses:)
    # Allow stubbing for testing
    return PagesController.class_variable_get(:@@stubbed_ai_summary) if PagesController.class_variable_defined?(:@@stubbed_ai_summary)

    total_spending = personal_total + group_total
    return "Start logging expenses to get your AI summary!" if total_spending.zero?

    # Format expense data for AI prompt
    prompt_data = """
    Total Personal Spent: #{number_to_currency(personal_total)}
    Total Group Spent: #{number_to_currency(group_total)}
    Total Combined Spent: #{number_to_currency(total_spending)}
    Spending by Category: #{category_data.to_json}
    5 Largest Expenses: #{top_expenses.map { |e| "#{e.title} (#{number_to_currency(e.amount)})" }.to_json}
    """

    prompt = """
    You are a friendly financial assistant. Based on the following spending data,
    write a short, 2-3 sentence summary for the user. Give one positive insight
    and one helpful tip. Be encouraging and brief.

    Data:
    #{prompt_data}

    Summary:
    """

    begin
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [ { role: "user", content: prompt } ],
          temperature: 0.7,
          max_tokens: 150
        }
      )
      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error "AI Summary Failed: #{e.message}"
      "Your AI summary is being generated. Check back soon!"
    end
  end
end
