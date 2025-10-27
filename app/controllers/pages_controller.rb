class PagesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  # Make sure only logged-in users can see the dashboard
  before_action :authenticate_user!, only: [ :dashboard ]

  def home
  end

  def dashboard
    # 1. START WITH THE BASE SCOPE
    all_expenses = Expense.for_user(current_user.id)
                          .includes(:category, :user, :group)
                          .recent

    # 2. APPLY FILTERS TO PERSONAL EXPENSES ONLY
    personal_expenses_query = all_expenses.where(group_id: nil)
    if params[:category_id].present?
      personal_expenses_query = personal_expenses_query.where(category_id: params[:category_id])
    end
    if params[:start_date].present?
      personal_expenses_query = personal_expenses_query.where("spent_on >= ?", params[:start_date])
    end
    if params[:end_date].present?
      personal_expenses_query = personal_expenses_query.where("spent_on <= ?", params[:end_date])
    end

    # 3. GET GROUP EXPENSES (UNFILTERED)
    group_expenses_query = all_expenses.where.not(group_id: nil)

    # 4. GET DATA FOR FILTERS & CHARTS
    # For the filter dropdown
    @categories = Category.all

    # For the bar graph (Spending Over Time) - use filtered personal expenses
    @spending_over_time = personal_expenses_query.group_by_day(:spent_on,
                                                             last: 30,
                                                             format: "%b %d").sum(:amount)

    # 5. CALCULATE SUMMARIES
    @personal_expenses = personal_expenses_query.to_a
    @group_expenses = group_expenses_query.to_a

    # Features 15 & 16 (Summaries)
    @personal_total = @personal_expenses.sum(&:amount)
    @group_total = @group_expenses.sum(&:amount)

    # Features 19 & 20 (Recent Lists)
    @recent_personal_expenses = @personal_expenses.take(5)
    @recent_group_expenses = @group_expenses.take(5)

    # 6. GET DATA FOR PIE CHART
    # We use @personal_expenses, which is already filtered
    category_data = @personal_expenses.group_by { |expense| expense.category.name }
                                      .transform_values { |expenses| expenses.sum(&:amount) }

    @category_labels = category_data.keys
    @category_data = category_data.values

    # 7. GET AI SUMMARY
    @ai_summary = get_ai_summary(
      total: @personal_total,
      category_data: category_data,
      recent_expenses: @recent_personal_expenses
    )
  end

  private

  def get_ai_summary(total:, category_data:, recent_expenses:)
    # Check if we have a stubbed summary for testing
    if PagesController.class_variable_defined?(:@@stubbed_ai_summary)
      return PagesController.class_variable_get(:@@stubbed_ai_summary)
    end

    # Don't bother calling the API if there's no data
    return "Start logging expenses to get your AI summary!" if total == 0

    # 1. Format the data for the prompt
    prompt_data = """
    Total Spent: #{number_to_currency(total)}
    Spending by Category: #{category_data.to_json}
    5 Most Recent Expenses: #{recent_expenses.map { |e| "#{e.title} (#{number_to_currency(e.amount)})" }.to_json}
    """

    # 2. Create the prompt
    prompt = """
    You are a friendly financial assistant. Based on the following spending data,
    write a short, 2-3 sentence summary for the user. Give one positive insight
    and one helpful tip. Be encouraging and brief.

    Data:
    #{prompt_data}

    Summary:
    """

    # 3. Call the API
    begin
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo", # Cheaper and faster
          messages: [ { role: "user", content: prompt } ],
          temperature: 0.7,
          max_tokens: 150
        }
      )
      response.dig("choices", 0, "message", "content")
    rescue => e
      # If the API fails, log the error and show a nice message
      Rails.logger.error "AI Summary Failed: #{e.message}"
      "Your AI summary is being generated. Check back soon!"
    end
  end
end
