class CreateDownloads < ActiveRecord::Migration[6.1]
  def change
    create_table :downloads do |t|
      t.string :text
      t.integer :status, default: 1
      t.string :job_id

      t.timestamps
    end
  end
end
