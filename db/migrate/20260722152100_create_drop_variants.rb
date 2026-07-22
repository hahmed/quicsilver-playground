class CreateDropVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :drop_variants do |t|
      t.references :drop_product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.string :image_path, null: false
      t.integer :stock, null: false, default: 0
      t.integer :claimed_count, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :drop_variants, :sku, unique: true
  end
end
