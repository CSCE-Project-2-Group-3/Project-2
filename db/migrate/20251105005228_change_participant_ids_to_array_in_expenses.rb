class ChangeParticipantIdsToArrayInExpenses < ActiveRecord::Migration[8.0]
  def change
    change_column :expenses, :participant_ids, :integer, array: true, default: [], using: 'ARRAY[participant_ids]::INTEGER[]'
  end
end
