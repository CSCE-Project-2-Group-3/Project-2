class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # shows conversations + messageable users grouped by shared groups
    @conversations = Conversation
      .where("user_a_id = :id OR user_b_id = :id", id: current_user.id)
      .includes(:messages)
      .order(updated_at: :desc)

    @groups = current_user.groups.includes(:users)
    @messageable_by_group = @groups.each_with_object({}) do |group, hash|
      members = group.users.where.not(id: current_user.id)
      hash[group] = members
    end
  end

  def show
    @conversation = Conversation
      .where("user_a_id = :id OR user_b_id = :id", id: current_user.id)
      .find_by(id: params[:id])

    unless @conversation
      redirect_to conversations_path, alert: "You are not authorized to view that conversation."
      return
    end

    @messages = @conversation.messages.recent.includes(:user, :quoted_expenses)
    @message = Message.new
    @other_user = @conversation.other_user(current_user)
    @expenses = @other_user.expenses.order(spent_on: :desc).limit(20)
  end

  def create
    recipient_id = params[:recipient_id] || params[:user_id] || params[:expense_author_id]
    recipient = User.find_by(id: recipient_id)

    unless recipient
      redirect_back fallback_location: conversations_path, alert: "Recipient not found."
      return
    end

    if recipient.id == current_user.id
      redirect_back fallback_location: conversations_path, notice: "You cannot start a conversation with yourself."
      return
    end

    @conversation = Conversation.find_or_create_between(current_user, recipient)
    redirect_to conversation_path(@conversation)
  end
end
