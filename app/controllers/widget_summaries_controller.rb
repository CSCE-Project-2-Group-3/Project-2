class WidgetSummariesController < ApplicationController
  # The :empty action was being blocked by Devise, causing a 302 redirect.
  # We can safely exclude it from authentication, as it just renders
  # an empty view to close the modal.
  before_action :authenticate_user!, except: [ :empty ]
  layout false

  def show
    @widget_type = params[:widget]

    # 1. Get the same filtered data as the dashboard
    dashboard_data = DashboardDataService.new(current_user, params).fetch_data

    # 2. Generate *only* the specific widget summary
    analyzer = DashboardAiAnalyzerService.new(dashboard_data)
    @summary_html = analyzer.generate_widget_summary(@widget_type).html_safe

    # 3. Render the modal view
    render :show
  end

  def empty
    render :empty
  end
end
