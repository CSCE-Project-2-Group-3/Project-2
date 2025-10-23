class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.string :name
      t.string :join_code

      t.timestamps
    end
    add_index :groups, :join_code
  end
end
