class CreatePercentages < ActiveRecord::Migration[5.2]
  def change
    create_table :percentages do |t|
      t.string :link
      t.string :image
      t.integer :reply_time
      t.integer :total_cm
      t.float :percentage
      t.integer :user_id

      t.timestamps
    end
  end
end
