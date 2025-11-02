class CreateMessageExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :message_expenses do |t|
      t.references :message, null: false, foreign_key: true
      t.references :expense, null: false, foreign_key: true

      t.timestamps
    end
  end
end
