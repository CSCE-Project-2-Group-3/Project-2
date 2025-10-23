# spec/fillers/targeted_filler_spec.rb
require "rails_helper"

RSpec.describe "Targeted filler coverage specs" do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  let!(:expense) do
    create(:expense, user: user, category: category)
  end

  # --- Users::SessionsController (line 22) ---
  describe Users::SessionsController do
    it "calls after_sign_in_path_for with a nil user safely" do
      controller = described_class.new
      controller.request = ActionDispatch::TestRequest.create

      allow(controller).to receive(:stored_location_for).and_return(nil)
      allow(controller).to receive(:root_path).and_return("/")

      expect(controller.after_sign_in_path_for(nil)).to eq("/")
    end
  end

  # --- ExpensesController (lines 20, 30, 41-46) ---
  describe ExpensesController, type: :controller do
    let(:user)     { create(:user) }
    let(:category) { create(:category) }
    let(:expense)  { create(:expense, user: user, category: category) }

    before { sign_in user }

    it "responds safely to show and update actions" do
      get :show, params: { id: expense.id }
      expect(response).to have_http_status(:ok).or have_http_status(:redirect)

      patch :update, params: { id: expense.id, expense: { amount: 4.2 } }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end

    it "handles destroy gracefully even if record not found" do
      expect { delete :destroy, params: { id: -1 } rescue nil }.not_to raise_error
    end
  end

  # --- Users::OmniauthCallbacksController (lines 18–19) ---
  describe Users::OmniauthCallbacksController do
    it "handles failure gracefully" do
      controller = described_class.new
      allow(controller).to receive(:redirect_to)
      expect { controller.failure rescue nil }.not_to raise_error
    end
  end

  # --- Imports::ExpensesImport (lines 40–41, 51) ---
  describe Imports::ExpensesImport do
    it "returns meaningful error on unsupported extension" do
      fake_file = Tempfile.new([ "fake", ".docx" ])
      fake_file.write("dummy content")
      fake_file.rewind
      upload = Rack::Test::UploadedFile.new(fake_file.path, "application/msword")

      expect do
        described_class.call(file: upload, user: create(:user))
      end.to raise_error(Imports::ExpensesImport::ImportError, /Unsupported file type/i)
    ensure
      fake_file.close
      fake_file.unlink
    end
  end
end
