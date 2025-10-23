RSpec.configure do |config|
  config.before(:each, :auto_sign_in) do
    user = FactoryBot.create(:user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
end
