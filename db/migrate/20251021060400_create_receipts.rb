class CreateReceipts < ActiveRecord::Migration[7.0]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :ocr_raw
      t.json :ocr_metadata
      t.json :candidates
      t.string :status, default: 'pending', null: false
      t.timestamps
    end
  end
end
