class ChangeParticipantIdsToArrayInExpenses < ActiveRecord::Migration[8.0]
  def change
    change_column_default :expenses, :participant_ids, nil

    # Step 2: Change the column type and convert all existing data.
    # The USING clause converts the old single integer (e.g., 5) into an array ([5]).
    change_column :expenses, :participant_ids, :integer, array: true, using: 'ARRAY[participant_ids]::INTEGER[]'

    # Step 3: Now that the column is an array, set the new default value.
    change_column_default :expenses, :participant_ids, from: nil, to: []
  end
end
