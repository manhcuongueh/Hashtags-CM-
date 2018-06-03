class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :hashtag
      t.integer :user_by_user
      t.integer :user_by_all

      t.timestamps
    end
  end
end
