class DashboardAiAnalyzerService
  def initialize(dashboard_data)
    @data = dashboard_data
  end

  def generate_main_summary
    prompt = <<~PROMPT
      You are a financial analyst. Based on the following data, provide a concise summary (2-3 sentences)
      of the user's spending habits.

      - Total Personal Spending: #{@data.personal_total}
      - Total Group Spending: #{@data.group_total}
      - Top Category: #{@data.category_data.labels.first} ($#{@data.category_data.data.first})
      - Number of Categories: #{@data.category_data.labels.count}
      - Top 5 Expenses: #{@data.top_5_largest_personal_expenses.map { |e| "#{e.title} ($#{e.amount})" }.join(', ')}
      - Spending Trend: (Analyze the spending_over_time hash: #{@data.spending_over_time})

      Your summary:
    PROMPT

    # TODO: Integrate with OpenAI API when ready
    "This is a placeholder for the main AI summary. You spent $#{@data.personal_total} personally, with most of it going to #{@data.category_data.labels.first}."
  end

  def generate_widget_summary(widget_type)
    case widget_type.to_sym
    when :personal_expenses
      generate_personal_summary
    when :group_expenses
      generate_group_summary
    when :top_5_expenses
      generate_top_5_summary
    when :spending_over_time
      generate_bar_chart_summary
    when :category_spending
      generate_pie_chart_summary
    else
      "No analysis available."
    end
  end

  private

  def generate_personal_summary
    prompt = <<~PROMPT
      Analyze this personal expense data. Total spent is $#{@data.personal_total}.
      Recent expenses are: #{@data.recent_personal_expenses.map(&:title).join(', ')}.

      Provide a deep insight as one paragraph. Don't just list the data.
      What do these recent expenses suggest about current habits?
      How does the total relate to a typical budget?
    PROMPT
    # TODO: Integrate with OpenAI API when ready
    "<p>Your personal spending of <strong>$#{@data.personal_total}</strong> seems focused on daily activities, given recent purchases like '#{@data.recent_personal_expenses.first&.title}'.</p><p>It's important to notice if these small, frequent purchases are adding up more than you realize. This category often represents the core of your discretionary budget.</p>"
  end

  def generate_group_summary
    prompt = <<~PROMPT
      Analyze this group expense data. Total spent is $#{@data.group_total}.
      Compare this to the personal total of $#{@data.personal_total}.

      Provide a deep insight as one paragraph.
      What does this comparison reveal about social vs. personal spending?
    PROMPT
    # TODO: Integrate with OpenAI API when ready
    "<p>You've spent <strong>$#{@data.group_total}</strong> in group settings. This type of spending is often social and can be unpredictable.</p><p>It's useful to compare this to your <strong>$#{@data.personal_total}</strong> personal total to see if your social spending is in line with your personal financial goals.</p>"
  end

  def generate_top_5_summary
    top_expense = @data.top_5_largest_personal_expenses.first
    prompt = <<~PROMPT
      Analyze these top 5 expenses, led by '#{top_expense&.title}' ($#{top_expense&.amount}).

      Provide a deep insight as one paragraph.
      What is the impact of these 'one-off' purchases on the overall budget?
    PROMPT
    # TODO: Integrate with OpenAI API when ready
    "<p>Your top 5 expenses are driving a significant portion of your spending, led by <strong>'#{top_expense&.title}' ($#{top_expense&.amount})</strong>.</p><p>These 'one-off' large purchases can often derail a budget. Were these planned for? Reducing the frequency of just these few items can have a greater impact than cutting dozens of small purchases.</p>"
  end

  def generate_bar_chart_summary
    prompt = <<~PROMPT
      Analyze the spending over time data: #{@data.spending_over_time}.

      Provide a deep insight as one paragraph.
      What do the peaks and valleys suggest? What should the user look for?
    PROMPT
    # TODO: Integrate with OpenAI API when ready
    "<p>Your spending over the last 30 days shows clear peaks and valleys.</p><p>Look closer at the dates with high spending—do they correspond to paydays, weekends, or specific events? Understanding this <strong>timing</strong> is key to managing cash flow and avoiding spending spikes.</p>"
  end

  def generate_pie_chart_summary
    top_cat = @data.category_data.labels.first
    top_val = @data.category_data.data.first
    prompt = <<~PROMPT
      Analyze this category spending data. Top category is '#{top_cat}' at $#{top_val}.
      There are #{@data.category_data.labels.count} categories total.

      Provide a deep insight as one paragraph.
      What is the "long tail" effect and why is it important here?
    PROMPT
    # TODO: Integrate with OpenAI API when ready
    "<p>Your spending is heavily weighted towards <strong>'#{top_cat}'</strong>, which accounts for <strong>$#{top_val}</strong>.</p><p>While this is your largest category, don't ignore the 'long tail' of smaller categories. Often, 5-6 small categories combined (like 'Subscriptions', 'Coffee', etc.) can add up to be your second or third largest expense area, yet fly under the radar.</p>"
  end
end
