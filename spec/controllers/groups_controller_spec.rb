require 'rails_helper'

RSpec.describe GroupsController, type: :controller do
  let(:user)  { create(:user) }
  let!(:group) { create(:group) }

  before { sign_in user }

  describe 'GET #index' do
    it 'assigns the user groups' do
      user.groups << group
      get :index
      expect(assigns(:groups)).to include(group)
    end
  end

  describe 'POST #create' do
    it 'creates a group with valid params' do
      expect {
        post :create, params: { group: { name: 'New Group' } }
      }.to change(Group, :count).by(1)

      expect(flash[:notice]).to eq('Group created successfully.')
      expect(response).to redirect_to(groups_path)
    end

    it 'does not create a group without a name' do
      expect {
        post :create, params: { group: { name: '' } }
      }.not_to change(Group, :count)
      expect(flash[:alert]).to match(/can't be blank/)
    end
  end

  describe 'GET #show' do
    it 'shows a group the user belongs to' do
      user.groups << group
      get :show, params: { id: group.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:group)).to eq(group)
    end
  end

  describe 'POST #join' do
    it 'adds the user to the group with a valid join_code' do
      post :join, params: { join_code: group.join_code }
      expect(user.groups.reload).to include(group)
      expect(flash[:notice]).to eq("Joined #{group.name} successfully.")
    end

    it 'shows error for invalid join_code' do
      post :join, params: { join_code: 'INVALID' }
      expect(flash[:alert]).to eq('Invalid join code.')
    end

    it 'shows message if user already a member' do
      user.groups << group
      post :join, params: { join_code: group.join_code }
      expect(flash[:alert]).to eq('You are already in this group.')
    end
  end

  describe 'GET #new' do
    it 'assigns a new Group to @group' do
      get :new
      expect(assigns(:group)).to be_a_new(Group)
      expect(response).to render_template(:new)
    end
  end
end
