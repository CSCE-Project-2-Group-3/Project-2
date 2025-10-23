class AddParticipantIdsToExpenses < ActiveRecord::Migration[8.0]
  def up
    if sqlite?
      add_column :expenses, :participant_ids, :text, default: "[]", null: false
    else
      add_column :expenses, :participant_ids, :integer, array: true, default: [], null: false
      add_index :expenses, :participant_ids, using: :gin
    end
  end

  def down
    remove_index :expenses, :participant_ids if index_exists?(:expenses, :participant_ids)
    remove_column :expenses, :participant_ids if column_exists?(:expenses, :participant_ids)
  end

  private

  def sqlite?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end
end
