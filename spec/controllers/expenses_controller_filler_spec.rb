# spec/controllers/expenses_controller_filler_spec.rb
require 'rails_helper'

RSpec.describe ExpensesController, type: :controller do
  let!(:category) { Category.create!(name: 'Transport') }

  describe 'POST #create' do
    it 'creates a new expense' do
      expect do
        post :create, params: {
          expense: {
            title: 'Bus Ticket',
            amount: 2.75,
            spent_on: Date.current,
            category_id: category.id
          }
        }
      end.to change(Expense, :count).by(1)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an expense' do
      expense = Expense.create!(title: 'Lunch', amount: 5, spent_on: Date.current, category: category)

      expect do
        delete :destroy, params: { id: expense.id }
      end.to change(Expense, :count).by(-1)
    end
  end

  # ✅ Covers send_data branch in download_template
  describe 'GET #download_template' do
    it 'executes send_data and returns CSV content' do
      get :download_template, format: :csv
      expect(response.body).to include('title', 'amount', 'category')
      expect(response.content_type).to eq('text/csv')
    end
  end

  # ✅ NEW: Covers the success redirect/notice line in bulk_upload
  describe 'POST #bulk_upload (success path)' do
    it 'redirects with a success notice when import succeeds' do
      # Stub the importer to avoid touching Roo/DB and drive the success branch
      fake_result = Imports::ExpensesImport::Result.new(created: 2, skipped: 1)
      allow(Imports::ExpensesImport).to receive(:call).and_return(fake_result)

      file = Tempfile.new(%w[fake .csv])
      begin
        upload = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        post :bulk_upload, params: { file: upload }

        expect(response).to redirect_to(expenses_path)
        expect(flash[:notice]).to match(/Imported 2 rows\. Skipped 1\./)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
