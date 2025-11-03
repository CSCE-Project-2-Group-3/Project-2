class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  def self.from_omniauth(auth)
    # Try to find user by provider & uid
    user = where(provider: auth.provider, uid: auth.uid).first
    # If not found, try by email
    user ||= find_by(email: auth.info.email)
    # If still not found, create new user
    if user.nil?
      user = create!(
        email: auth.info.email,
        full_name: auth.info.name,
        avatar_url: auth.info.image,
        provider: auth.provider,
        uid: auth.uid,
        password: Devise.friendly_token[0, 20]
      )
    else
      # Update missing OAuth info if needed
      user.update(
        provider: auth.provider,
        uid: auth.uid,
        full_name: user.full_name.presence || auth.info.name,
        avatar_url: user.avatar_url.presence || auth.info.image
      )
    end
    user.reload
  end
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :expenses, dependent: :destroy
  has_many :comments, dependent: :destroy
end
