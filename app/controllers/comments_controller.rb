class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense

  def create
    comment = @expense.comments.build(comment_params.merge(user: current_user))

    if comment.save
      redirect_back fallback_location: expense_path(@expense), notice: "Comment posted successfully"
    else
      redirect_back fallback_location: expense_path(@expense), alert: comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_expense
    @expense = Expense.find(params[:expense_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
