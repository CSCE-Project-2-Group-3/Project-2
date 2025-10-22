class ExpensesController < ApplicationController
  before_action :set_expense, only: [ :show, :edit, :update, :destroy ]

  def index
    @expenses = Expense.includes(:category).order(spent_on: :desc).page(params[:page]).per(20)
    @total = @expenses.sum(:amount)
  end

  def new
    @expense = Expense.new(spent_on: Date.today)
  end

  def create
    @expense = Expense.new(expense_params)
    if @expense.save
      redirect_to expenses_path, notice: "Expense added successfully."
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
    if params[:file].blank?
      return redirect_to expenses_path, alert: "Please select a CSV or Excel file."
    end
    result = Imports::ExpensesImport.call(file: params[:file])
    redirect_to expenses_path, notice: "Imported #{result.created} rows. Skipped #{result.skipped}."
  rescue Imports::ExpensesImport::ImportError => e
    redirect_to expenses_path, alert: e.message
  end

  def download_template
    send_data "title,amount,spent_on,category,notes\nLunch,12.5,2025-10-18,Food,Team lunch\n",
              filename: "expenses_template.csv", type: "text/csv"
  end

  private
  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:title, :notes, :amount, :spent_on, :category_id)
  end
end
