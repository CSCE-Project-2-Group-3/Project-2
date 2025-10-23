class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.find(params[:conversation_id])
    unless [@conversation.user_a_id, @conversation.user_b_id].include?(current_user.id)
      redirect_to conversations_path, alert: "Not authorized to post in this conversation."
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
