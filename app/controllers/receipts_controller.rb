class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_receipt, only: [:show, :confirm]

  def new
    @receipt = current_user.receipts.new
  end

  def create
    @receipt = current_user.receipts.build(receipt_params)

    if @receipt.save
      if @receipt.file.attached?
        local_path = ActiveStorage::Blob.service.send(:path_for, @receipt.file.key)
        result = ReceiptParser.parse_receipt(local_path)

        if result[:success] && result[:inferred_total].present?
          @receipt.update!(
            ocr_raw: result[:raw_text],
            ocr_metadata: { detected_amounts: result[:detected_amounts], inferred_total: result[:inferred_total] },
            status: "processed"
          )

          Expense.create!(
            user: current_user,
            receipt: @receipt,
            amount: result[:inferred_total],
            merchant: "Auto-detected",
            happened_on: Date.today
          )

          redirect_to expenses_path, notice: "Receipt processed successfully!"
        else
          @receipt.update!(status: "failed")
          redirect_to new_expense_path(receipt_id: @receipt.id), alert: "Uploaded but parsing failed. Please enter details manually."
        end
      else
        redirect_to new_receipt_path, alert: "Please upload a file."
      end
    else
      render :new
    end
  end


  def show
    @candidates = @receipt.candidates || []
    # Ensure at least one candidate for the view
    @candidates = [] unless @candidates.is_a?(Array)
  end

  def confirm
    chosen_amount = params[:amount].presence || params[:manual_amount].presence
    unless chosen_amount.present?
      redirect_to receipt_path(@receipt), alert: "Please provide an amount."
      return
    end

    normalized_amount = begin
                          BigDecimal(chosen_amount.to_s)
                        rescue
                          nil
                        end

    unless normalized_amount
      redirect_to receipt_path(@receipt), alert: "Invalid amount format."
      return
    end

    expense = current_user.expenses.new(
      amount: normalized_amount,
      currency: params[:currency].presence || (@receipt.candidates && @receipt.candidates.first && @receipt.candidates.first["currency"]) || "USD",
      merchant: params[:merchant].presence || (@receipt.candidates && @receipt.candidates.first && @receipt.candidates.first["merchant"]),
      happened_on: params[:happened_on].presence || (@receipt.candidates && @receipt.candidates.first && @receipt.candidates.first["date"]) || Date.today,
      receipt: @receipt,
      category_id: params[:category_id],
      notes: params[:notes]
    )

    if expense.save
      redirect_to expenses_path, notice: "Expense created."
    else
      flash.now[:alert] = expense.errors.full_messages.to_sentence
      @candidates = @receipt.candidates || []
      render :show
    end
  end

  private

  def set_receipt
    @receipt = current_user.receipts.find(params[:id])
  end
  private

  def receipt_params
    params.require(:receipt).permit(:file)
  end
end
