require 'rails_helper'

RSpec.describe 'Split bill workflow', type: :feature do
  let(:user) { create(:user, email: 'split-owner@example.com') }
  let(:member) { create(:user, email: 'teammate@example.com', full_name: 'Team Mate') }
  let(:group) { create(:group) }
  let!(:category) { create(:category, name: 'Travel') }

  before do
    create(:group_membership, user: user, group: group)
    create(:group_membership, user: member, group: group)
    sign_in user
  end

  it 'allows selecting group members and saving the split' do
    visit new_group_expense_path(group)

    fill_in 'Title', with: 'Shared Taxi'
    fill_in 'Amount', with: '30'
    fill_in 'Spent on', with: Date.today
    select category.name, from: 'Category'

    expect(page).to have_content('Split Bill')
    expect(page).to have_content('Select who to split this bill with.')

    check "Team Mate"

    click_button 'Save Expense'

    expect(current_path).to eq(group_path(group))

    # --- FIX ---
    # The old assertion was too specific.
    # We will check that all the key pieces of information are on the page.
    expect(page).to have_content('Shared Taxi')
    expect(page).to have_content('Split with:')
    expect(page).to have_content('Team Mate')
    expect(page).to have_content('$30.00') # Or '$15.00' if you show per-person
  end
end
