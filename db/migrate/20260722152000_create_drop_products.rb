class CreateDropProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :drop_products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :tagline, null: false
      t.string :hero_image_path, null: false
      t.integer :watching_count, null: false, default: 12_847

      t.timestamps
    end

    add_index :drop_products, :slug, unique: true
  end
end
