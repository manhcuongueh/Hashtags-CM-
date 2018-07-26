class AddUserIdToHashtags < ActiveRecord::Migration[5.2]
  def change
    add_column :hashtags, :user_id, :integer
  end
end
