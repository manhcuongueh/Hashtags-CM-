class CreateHashtags < ActiveRecord::Migration[5.2]
  def change
    create_table :hashtags do |t|
      t.string :hashtags
      t.integer :use_by_user
      t.integer :use_by_global
      t.string :avai
      t.integer :user_id

      t.timestamps
    end
  end
end
