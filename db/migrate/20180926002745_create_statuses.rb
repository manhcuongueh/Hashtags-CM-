class CreateStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :statuses do |t|
      t.string :username
      t.string :status
      t.string :string

      t.timestamps
    end
  end
end
