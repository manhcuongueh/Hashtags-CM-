class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :username
      t.string :date_start
      t.string :date_end

      t.timestamps
    end
  end
end
