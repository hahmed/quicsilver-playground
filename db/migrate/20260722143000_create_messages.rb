class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.string :author, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
