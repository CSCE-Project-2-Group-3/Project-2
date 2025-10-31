class BackupsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Gather all user data
    backup_data = {
      version: "1.0",
      exported_at: Time.current.iso8601,
      user: {
        email: current_user.email,
        full_name: current_user.full_name
      },
      expenses: current_user.expenses.includes(:category, :group).map do |expense|
        {
          title: expense.title,
          amount: expense.amount.to_s,
          spent_on: expense.spent_on.to_s,
          notes: expense.notes,
          category_name: expense.category&.name,
          group_name: expense.group&.name,
          participant_ids: expense.participant_ids,
          created_at: expense.created_at.iso8601
        }
      end,
      categories: current_user.expenses.includes(:category).map(&:category).compact.uniq.map do |category|
        {
          name: category.name
        }
      end,
      groups: current_user.groups.map do |group|
        {
          name: group.name,
          join_code: group.join_code,
          member_emails: group.users.pluck(:email)
        }
      end,
      conversations: Conversation.where("user_a_id = ? OR user_b_id = ?", current_user.id, current_user.id)
                                 .includes(:messages).map do |conv|
        {
          other_user_email: conv.other_user(current_user)&.email,
          messages: conv.messages.map do |msg|
            {
              body: msg.body,
              sender_email: msg.user.email,
              created_at: msg.created_at.iso8601
            }
          end
        }
      end
    }

    # Generate filename with timestamp
    filename = "expense_tracker_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"

    send_data backup_data.to_json,
              filename: filename,
              type: "application/json",
              disposition: "attachment"
  end

  def new
    # Show the restore form
  end

  def restore
    unless params[:backup_file].present?
      redirect_to new_backup_path, alert: "Please select a backup file."
      return
    end

    begin
      file_content = params[:backup_file].read
      backup_data = JSON.parse(file_content)

      # Validate backup format
      unless backup_data["version"] && backup_data["expenses"]
        redirect_to new_backup_path, alert: "Invalid backup file format."
        return
      end

      restored_counts = restore_data(backup_data)

      notice_message = "Backup restored successfully! " \
                       "Expenses: #{restored_counts[:expenses]}, " \
                       "Skipped duplicates: #{restored_counts[:skipped_expenses]}, " \
                       "Categories: #{restored_counts[:categories]}, " \
                       "Groups: #{restored_counts[:groups]}"

      if restored_counts[:skipped_expenses] > 0
        notice_message += " (Skipped #{restored_counts[:skipped_expenses]} duplicate expenses)"
      end

      redirect_to dashboard_path, notice: notice_message
    rescue JSON::ParserError
      redirect_to new_backup_path, alert: "Invalid JSON file."
    rescue => e
      Rails.logger.error "Backup restore failed: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to new_backup_path, alert: "Restore failed: #{e.message}"
    end
  end

  private

  def restore_data(backup_data)
    counts = { expenses: 0, categories: 0, groups: 0, skipped_expenses: 0 }

    ActiveRecord::Base.transaction do
      # Restore categories first
      category_map = {}
      backup_data["categories"]&.each do |cat_data|
        next if cat_data["name"].blank?
        category = Category.find_or_create_by!(name: cat_data["name"].strip.titleize)
        category_map[cat_data["name"]] = category
        counts[:categories] += 1
      end

      # Restore groups
      group_map = {}
      backup_data["groups"]&.each do |group_data|
        next if group_data["name"].blank?

        # Check if user is already in this group
        existing_group = current_user.groups.find_by(name: group_data["name"])
        if existing_group
          group_map[group_data["name"]] = existing_group
        else
          # Try to join by code if available
          if group_data["join_code"].present?
            existing_group = Group.find_by(join_code: group_data["join_code"])
            if existing_group && !existing_group.users.include?(current_user)
              existing_group.users << current_user
              group_map[group_data["name"]] = existing_group
              counts[:groups] += 1
            end
          end
        end
      end

      # Restore expenses with duplicate detection
      backup_data["expenses"]&.each do |expense_data|
        next if expense_data["title"].blank?

        category = category_map[expense_data["category_name"]] ||
                   Category.find_by(name: expense_data["category_name"])
        group = group_map[expense_data["group_name"]] ||
                current_user.groups.find_by(name: expense_data["group_name"])

        # --- DUPLICATE DETECTION LOGIC ---
        duplicate = current_user.expenses.where(
          title: expense_data["title"].strip,
          amount: expense_data["amount"].to_d,
          spent_on: Date.parse(expense_data["spent_on"])
        ).exists?

        if duplicate
          counts[:skipped_expenses] += 1
          next
        end
        # ---------------------------------

        current_user.expenses.create!(
          title: expense_data["title"],
          amount: expense_data["amount"],
          spent_on: Date.parse(expense_data["spent_on"]),
          notes: expense_data["notes"],
          category: category,
          group: group
        )

        counts[:expenses] += 1
      end
    end

    counts
  rescue ActiveRecord::RecordInvalid => e
    raise "Failed to restore data: #{e.message}"
  end
end
