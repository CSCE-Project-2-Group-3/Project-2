# spec/fillers/final_full_coverage_spec.rb
require "rails_helper"

RSpec.describe "Final full coverage fillers" do
  # --- ExpensesController: covers all actions and rescue branches ---
  describe ExpensesController, type: :controller do
    let(:user) { create(:user) }
    let(:category) { create(:category) }
    let!(:expense) { create(:expense, user: user, category: category) }

    before { sign_in user }

    it "renders index successfully" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:total)).to eq(expense.amount)
    end

    it "renders new successfully" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "creates a valid expense" do
      post :create, params: { expense: { title: "Coffee", amount: 2, spent_on: Date.today, category_id: category.id } }
      expect(response).to redirect_to(expenses_path)
      expect(Expense.last.user).to eq(user)
    end

    it "renders new on invalid create" do
      post :create, params: { expense: { title: "", amount: 10, spent_on: Date.today, category_id: category.id } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders edit successfully" do
      get :edit, params: { id: expense.id }
      expect(response).to have_http_status(:ok)
    end

    it "updates successfully" do
      patch :update, params: { id: expense.id, expense: { title: "Updated" } }
      expect(response).to redirect_to(expenses_path)
    end

    it "renders edit on invalid update" do
      patch :update, params: { id: expense.id, expense: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "destroys an expense successfully" do
      delete :destroy, params: { id: expense.id }
      expect(response).to redirect_to(expenses_path)
    end

    it "handles bulk_upload with no file" do
      post :bulk_upload, params: { file: nil }
      expect(response).to redirect_to(expenses_path)
    end

    it "handles bulk_upload with bad file type" do
      file = Tempfile.new(%w[bad .txt])
      begin
        upload = Rack::Test::UploadedFile.new(file.path, "text/plain")
        post :bulk_upload, params: { file: upload }
        expect(response).to redirect_to(expenses_path)
      ensure
        file.close
        file.unlink
      end
    end

    it "rescues ImportError in bulk_upload gracefully" do
      file = Tempfile.new(%w[error .csv])
      begin
        upload = Rack::Test::UploadedFile.new(file.path, "text/csv")
        allow(Imports::ExpensesImport).to receive(:call)
          .with(file: anything, user: user)
          .and_raise(Imports::ExpensesImport::ImportError, "Bad file")

        post :bulk_upload, params: { file: upload }
        expect(response).to redirect_to(expenses_path)
        expect(flash[:alert]).to eq("Bad file")
      ensure
        file.close
        file.unlink
      end
    end

    it "downloads CSV template successfully" do
      get :download_template
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("title", "amount", "category")
    end

    it "calls send_data inside download_template" do
      expect_any_instance_of(described_class).to receive(:send_data)
      get :download_template, format: :csv
      expect(response).to have_http_status(:ok).or have_http_status(:no_content)
    end

    it "invokes set_expense privately without raising" do
      ctrl = described_class.new
      allow(ctrl).to receive(:params).and_return(ActionController::Parameters.new(id: expense.id))
      expect { ctrl.send(:set_expense) }.not_to raise_error
    end
  end

  # --- Imports::ExpensesImport: covers unsupported & nil file branches ---
  describe Imports::ExpensesImport do
    it "raises ImportError for unsupported file type" do
      tmp = Tempfile.new(%w[dummy .txt])
      begin
        tmp.write("no data")
        tmp.rewind
        upload = Rack::Test::UploadedFile.new(tmp.path, "text/plain")
        expect { described_class.call(file: upload, user: create(:user)) }
          .to raise_error(Imports::ExpensesImport::ImportError)
      ensure
        tmp.close
        tmp.unlink
      end
    end

    it "raises ImportError when file is nil (No file provided)" do
      importer = described_class.new(nil, create(:user))
      expect { importer.send(:open_spreadsheet, nil) }
        .to raise_error(Imports::ExpensesImport::ImportError, /No file provided/)
    end

    it "opens a .csv file successfully" do
      file = Tempfile.new(%w[test .csv])
      begin
        file.write("title,amount,spent_on,category\nRow,1,2025-10-21,Food\n")
        file.rewind
        upload = Rack::Test::UploadedFile.new(file.path, "text/csv")
        importer = described_class.new(upload, create(:user))
        expect(importer.send(:open_spreadsheet, upload)).to be_a(Roo::CSV)
      ensure
        file.close
        file.unlink
      end
    end

    it "triggers rescue logging path for a bad CSV row" do
      file = Tempfile.new(%w[badrow .csv])
      begin
        file.write("title,amount,spent_on,category,notes\nBad,abc,xyz,Food,\n")
        file.rewind
        upload = Rack::Test::UploadedFile.new(file.path, "text/csv")
        allow(Rails.logger).to receive(:warn)
        described_class.call(file: upload, user: create(:user))
        expect(Rails.logger).to have_received(:warn).at_least(:once)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
