class ExpensesController < ApplicationController
  before_action :set_expense, only: [ :show, :edit, :update, :destroy ]
  before_action :set_group, only: [:new, :create]

  def index
    @expenses = Expense.includes(:category)
                       .order(spent_on: :desc)
                       .page(params[:page]).per(20)
    @total = @expenses.sum(:amount)
  end

  def new
    @expense = @group.expenses.build if @group
    @expense ||= Expense.new
  end

  def create
    @expense = @group ? @group.expenses.build(expense_params) : Expense.new(expense_params)
    @expense.user = current_user

    if @expense.save
      flash[:notice] = "Expense created!"
      redirect_to @group ? group_path(@group) : expenses_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Expense updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "Expense deleted."
  end

  # --- Bulk upload ---
  def bulk_upload
    return redirect_to(expenses_path, alert: "Please select a CSV or Excel file.") if params[:file].blank?

    result = Imports::ExpensesImport.call(file: params[:file])
    redirect_to expenses_path, notice: "Imported #{result.created} rows. Skipped #{result.skipped}."
  rescue Imports::ExpensesImport::ImportError => e
    redirect_to expenses_path, alert: e.message
  end

  def download_template
    template = <<~CSV
      title,amount,spent_on,category,notes
      Lunch,12.5,2025-10-18,Food,Team lunch
    CSV

    send_data template, filename: "expenses_template.csv", type: "text/csv"
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:title, :notes, :amount, :spent_on, :category_id)
  end
  
  def set_group
    @group = Group.find_by(id: params[:group_id])
  end
end
