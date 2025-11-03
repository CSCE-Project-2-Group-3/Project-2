class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.where(
      "user_a_id = :id OR user_b_id = :id",
      id: current_user.id
    ).find_by(id: params[:conversation_id])

    unless @conversation
      redirect_to conversations_path, alert: "Not authorized."
      return
    end

    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    if @message.save
      # Link quoted expenses after successful save
      if params[:message][:quoted_expense_ids].present?
        @message.quoted_expenses = Expense.where(id: params[:message][:quoted_expense_ids])
      end

      @conversation.touch
      redirect_to conversation_path(@conversation, anchor: "message-#{@message.id}")
    else
      # Re-render form with necessary data for expense dropdown
      @messages = @conversation.messages.recent.includes(:user, :quoted_expenses)
      @other_user = @conversation.other_user(current_user)

      # Only show expenses from shared groups (security + nil safety)
      if @other_user
        shared_group_ids = current_user.groups.pluck(:id) & @other_user.groups.pluck(:id)
        @expenses = @other_user.expenses
                              .where(group_id: shared_group_ids)
                              .order(spent_on: :desc)
                              .limit(20)
      else
        @expenses = []
      end

      render "conversations/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, quoted_expense_ids: [])
  end
end
