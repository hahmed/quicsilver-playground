class CreateDocPages < ActiveRecord::Migration[8.0]
  def change
    create_table :doc_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :category, null: false
      t.text :summary, null: false
      t.text :body, null: false
      t.integer :position, null: false, default: 0
      t.integer :upvotes, null: false, default: 0
      t.integer :downvotes, null: false, default: 0

      t.timestamps
    end

    add_index :doc_pages, :slug, unique: true
    add_index :doc_pages, [ :category, :position ]
  end
end
