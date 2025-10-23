require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#after_sign_in_path_for' do
    let(:user) { create(:user) }

    context 'when there is a stored location' do
      before do
        session["user_return_to"] = '/some_path'
      end

      it 'returns the stored location' do
        allow(controller).to receive(:stored_location_for).with(user).and_return('/some_path')
        expect(controller.after_sign_in_path_for(user)).to eq('/some_path')
      end
    end

    context 'when there is no stored location' do
      it 'returns root path' do
        allow(controller).to receive(:stored_location_for).with(user).and_return(nil)
        expect(controller.after_sign_in_path_for(user)).to eq(root_path)
      end
    end
  end
end
