class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # show all conversations the current_user participates in
    @conversations = Conversation.where("user_a_id = :id OR user_b_id = :id", id: current_user.id)
                                 .includes(:messages)
                                 .order("conversations.updated_at desc")
  end

  def show
    @conversation = Conversation.find(params[:id])
    unless participant?(@conversation, current_user)
      redirect_to conversations_path, alert: "You are not authorized to view that conversation."
      return
    end

    @messages = @conversation.messages.recent.includes(:user)
    @message = Message.new
  end

  def create
    recipient_id = params[:recipient_id] || params[:user_id] || params[:expense_author_id]
    recipient = User.find_by(id: recipient_id)

    unless recipient
      redirect_back fallback_location: expenses_path, alert: "Recipient not found."
      return
    end

    if recipient.id == current_user.id
      redirect_back fallback_location: expenses_path, notice: "You cannot start a conversation with yourself."
      return
    end

    @conversation = Conversation.find_or_create_between(current_user, recipient)

    redirect_to conversation_path(@conversation)
  end

  private

  def participant?(conversation, user)
    [conversation.user_a_id, conversation.user_b_id].include?(user.id)
  end
end
