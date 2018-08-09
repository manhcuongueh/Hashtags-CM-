class AddRepondPercentageToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :repond_percentage, :float
  end
end
