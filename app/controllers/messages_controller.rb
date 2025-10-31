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

    @message = @conversation.messages.build(message_params)
    @message.user = current_user

    if @message.save
      if params[:message][:quoted_expense_ids].present?
        @message.quoted_expenses = Expense.where(id: params[:message][:quoted_expense_ids])
      end

      @conversation.touch
      redirect_to conversation_path(@conversation, anchor: "message-#{@message.id}")
    else
      @messages = @conversation.messages.includes(:user, :quoted_expenses)
      render "conversations/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, quoted_expense_ids: [])
  end
end
