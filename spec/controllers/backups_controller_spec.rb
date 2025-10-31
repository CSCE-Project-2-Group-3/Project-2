require 'rails_helper'
require 'faker' rescue nil

# Fallback stub if Faker gem isn't loaded
unless defined?(Faker)
  module Faker
    module Lorem
      def self.sentence(word_count: 8)
        Array.new(word_count) { "word" }.join(" ")
      end
    end
  end
end

RSpec.describe BackupsController, type: :controller do
  let(:user) { create(:user) }
  let(:category) { create(:category, name: "Food") }
  let(:group) { create(:group, name: "Test Group", join_code: "TEST123") }
  let(:expense) { create(:expense, user: user, category: category) }

  before do
    sign_in user
    group.users << user unless group.users.include?(user)
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe "private #restore_data error handling" do
    it "raises error when expense creation fails" do
      backup_data = {
        "version" => "1.0",
        "expenses" => [
          {
            "title" => "Invalid Expense",
            "amount" => "invalid_amount", # This will cause validation error
            "spent_on" => "2023-01-01",
            "category_name" => "Food"
          }
        ],
        "categories" => [ { "name" => "Food" } ],
        "groups" => []
      }

      expect {
        controller.send(:restore_data, backup_data)
      }.to raise_error(/Failed to restore data/)
    end
  end

  describe "POST #create" do
    let!(:expense) { create(:expense, user: user, category: category) }
    let!(:conversation) { create(:conversation, user_a: user, user_b: create(:user)) }
    let!(:message) { create(:message, conversation: conversation, user: user) }

    it "generates backup data" do
      post :create
      expect(response).to have_http_status(:success)
    end

    it "includes user information in backup" do
      post :create
      backup_data = JSON.parse(response.body)
      expect(backup_data["user"]["email"]).to eq(user.email)
      expect(backup_data["user"]["full_name"]).to eq(user.full_name)
    end

    it "includes expenses in backup" do
      post :create
      backup_data = JSON.parse(response.body)
      expect(backup_data["expenses"].length).to eq(1)
      expect(backup_data["expenses"][0]["title"]).to eq(expense.title)
    end

    it "includes categories in backup" do
      post :create
      backup_data = JSON.parse(response.body)
      expect(backup_data["categories"].length).to eq(1)
      expect(backup_data["categories"][0]["name"]).to eq(category.name)
    end

    it "includes groups in backup" do
      group_expense = create(:expense, user: user, category: category, group: group)
      post :create
      backup_data = JSON.parse(response.body)
      expect(backup_data["groups"].map { |g| g["name"] }).to include(group.name)
    end

    it "includes conversations in backup" do
      post :create
      backup_data = JSON.parse(response.body)
      expect(backup_data["conversations"]).to be_an(Array)
    end

    it "sets correct content disposition" do
      post :create
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include(".json")
    end

    it "sets correct content type" do
      post :create
        expect(response.content_type).to start_with("application/json")
    end
  end

  describe "POST #restore" do
    let(:backup_file) { fixture_file_upload('backup.json', 'application/json') }
    let(:invalid_backup_file) { fixture_file_upload('invalid_backup.json', 'application/json') }
    let(:empty_backup_file) { fixture_file_upload('empty_backup.json', 'application/json') }

    before do
      create_backup_fixtures
    end

    context "with no file selected" do
      it "redirects with alert" do
        post :restore
        expect(response).to redirect_to(new_backup_path)
        expect(flash[:alert]).to eq("Please select a backup file.")
      end
    end

    context "with invalid JSON file" do
      it "redirects with alert" do
        post :restore, params: { backup_file: invalid_backup_file }
        expect(response).to redirect_to(new_backup_path)
        expect(flash[:alert]).to eq("Invalid JSON file.")
      end
    end

    context "with invalid backup format" do
      it "redirects with alert" do
        post :restore, params: { backup_file: empty_backup_file }
        expect(response).to redirect_to(new_backup_path)
        expect(flash[:alert]).to eq("Invalid backup file format.")
      end
    end

    context "with valid backup file" do
      it "restores data successfully" do
        expect {
          post :restore, params: { backup_file: backup_file }
        }.to change { user.expenses.count }.by(2)
          .and change { Category.count }.by(2)

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to include("Backup restored successfully!")
        expect(flash[:notice]).to include("Expenses: 2")
        expect(flash[:notice]).to include("Categories: 2")
      end

      it "handles duplicate expenses" do
        post :restore, params: { backup_file: backup_file }

        expect {
          post :restore, params: { backup_file: backup_file }
        }.to change { user.expenses.count }.by(0)

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to include("Skipped duplicates: 2")
      end

      it "handles existing groups gracefully" do
        existing_group = create(:group, name: "Roommates", join_code: "ROOM123")
        existing_group.users << user

        expect {
          post :restore, params: { backup_file: backup_file }
        }.to change { user.groups.count }.by(0)
      end

      it "joins groups by join code" do
        existing_group = create(:group, name: "Different Name", join_code: "ROOM123")

        expect {
          post :restore, params: { backup_file: backup_file }
        }.to change { existing_group.users.count }.by(1)
      end
    end

    context "with restore errors" do
      it "handles restore failures gracefully" do
        backup_data = {
          "version" => "1.0",
          "expenses" => [ {
            "title" => "Valid Expense",
            "amount" => "100.0",
            "spent_on" => "2023-01-01",
            "category_name" => "Food"
          } ],
          "categories" => [ { "name" => "Food" } ],
          "groups" => []
        }

        allow_any_instance_of(BackupsController).to receive(:restore_data).and_raise(ActiveRecord::RecordInvalid)

        file = Tempfile.new([ 'test', '.json' ])
        file.write(backup_data.to_json)
        file.rewind
        upload = Rack::Test::UploadedFile.new(file.path, 'application/json')

        post :restore, params: { backup_file: upload }

        expect(response).to redirect_to(new_backup_path)
        expect(flash[:alert]).to include("Restore failed")

        file.close
        file.unlink
      end
    end
  end

  describe "private #restore_data" do
    let(:backup_data) do
      {
        "version" => "1.0",
        "expenses" => [
          { "title" => "Test Expense 1", "amount" => "50.0", "spent_on" => "2023-01-01", "notes" => "Test notes", "category_name" => "Food" },
          { "title" => "Test Expense 2", "amount" => "75.0", "spent_on" => "2023-01-02", "category_name" => "Transportation" }
        ],
        "categories" => [ { "name" => "Food" }, { "name" => "Transportation" } ],
        "groups" => []
      }
    end

    let(:backup_data_with_groups) do
      {
        "version" => "1.0",
        "expenses" => [
          { "title" => "Test Expense 1", "amount" => "50.0", "spent_on" => "2023-01-01", "category_name" => "Food", "group_name" => "Roommates" }
        ],
        "categories" => [ { "name" => "Food" } ],
        "groups" => [
          { "name" => "Roommates", "join_code" => "ROOM123", "member_emails" => [ user.email ] }
        ]
      }
    end

    it "restores categories" do
      expect {
        controller.send(:restore_data, backup_data)
      }.to change { Category.count }.by(2)
    end

    it "restores groups and adds user when groups are present" do
      create(:group, name: "Roommates", join_code: "ROOM123") # ensure existence
      expect {
        controller.send(:restore_data, backup_data_with_groups)
      }.to change { user.groups.count }.by(1)
    end

    it "restores expenses" do
      expect {
        controller.send(:restore_data, backup_data)
      }.to change { user.expenses.count }.by(2)
    end

    it "skips duplicate expenses" do
      create(:expense, user: user, title: "Test Expense 1", amount: 50.0, spent_on: Date.parse("2023-01-01"))
      expect {
        controller.send(:restore_data, backup_data)
      }.to change { user.expenses.count }.by(1)
    end

    it "returns correct counts" do
      create(:group, name: "Roommates", join_code: "ROOM123") # ensure exists
      counts = controller.send(:restore_data, backup_data_with_groups)
      expect(counts[:expenses]).to eq(1)
      expect(counts[:categories]).to eq(1)
      expect(counts[:groups]).to eq(1)
      expect(counts[:skipped_expenses]).to eq(0)
    end

    it "handles blank category names" do
      backup_data_with_blank = backup_data.dup
      backup_data_with_blank["categories"] << { "name" => "" }
      expect {
        controller.send(:restore_data, backup_data_with_blank)
      }.to change { Category.count }.by(2)
    end

    it "handles blank expense titles" do
      backup_data_with_blank = backup_data.dup
      backup_data_with_blank["expenses"] << { "title" => "" }
      expect {
        controller.send(:restore_data, backup_data_with_blank)
      }.to change { user.expenses.count }.by(2)
    end
  end

  private

  def create_backup_fixtures
    backup_data = {
      "version" => "1.0",
      "expenses" => [
        { "title" => "Groceries", "amount" => "50.0", "spent_on" => "2023-01-01", "notes" => "Weekly groceries", "category_name" => "Food" },
        { "title" => "Gas", "amount" => "40.0", "spent_on" => "2023-01-02", "category_name" => "Transportation" }
      ],
      "categories" => [ { "name" => "Food" }, { "name" => "Transportation" } ],
      "groups" => [ { "name" => "Roommates", "join_code" => "ROOM123", "member_emails" => [ user.email ] } ]
    }

    File.open(Rails.root.join('spec', 'fixtures', 'files', 'backup.json'), 'w') { |f| f.write(backup_data.to_json) }
    File.open(Rails.root.join('spec', 'fixtures', 'files', 'invalid_backup.json'), 'w') { |f| f.write("invalid json content") }
    File.open(Rails.root.join('spec', 'fixtures', 'files', 'empty_backup.json'), 'w') { |f| f.write('{"other_data": "test"}') }
  end
end
