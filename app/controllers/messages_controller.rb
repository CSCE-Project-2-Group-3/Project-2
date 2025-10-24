class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    # Safely scope conversation lookup to current_user participation
    @conversation = Conversation.where(
      "user_a_id = :id OR user_b_id = :id",
      id: current_user.id
    ).find_by(id: params[:conversation_id])

    unless @conversation
      # Keep original flash message so existing RSpec test passes
      redirect_to conversations_path, alert: "Not authorized."
      return
    end

    @message = @conversation.messages.build(message_params)
    @message.user = current_user

    if @message.save
      # update conversation timestamp so it sorts correctly in index
      @conversation.touch
      redirect_to conversation_path(@conversation, anchor: "message-#{@message.id}")
    else
      @messages = @conversation.messages.recent.includes(:user)
      render "conversations/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
