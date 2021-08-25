class CreateOutputs < ActiveRecord::Migration[6.1]
  def change
    create_table :outputs do |t|
      t.string :text
      t.integer :type
      t.references :download, null: false, foreign_key: true

      t.timestamps
    end
  end
end
