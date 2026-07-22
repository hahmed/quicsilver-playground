class CreateDropEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :drop_events do |t|
      t.references :drop_product, null: false, foreign_key: true
      t.references :drop_variant, null: true, foreign_key: true
      t.string :kind, null: false
      t.string :actor
      t.string :emoji
      t.text :body, null: false
      t.text :metadata

      t.timestamps
    end

    add_index :drop_events, [:drop_product_id, :created_at]
  end
end
