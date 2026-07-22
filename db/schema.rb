# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_22_152200) do
  create_table "doc_pages", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "category", null: false
    t.text "summary", null: false
    t.text "body", null: false
    t.integer "position", default: 0, null: false
    t.integer "upvotes", default: 0, null: false
    t.integer "downvotes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "position"], name: "index_doc_pages_on_category_and_position"
    t.index ["slug"], name: "index_doc_pages_on_slug", unique: true
  end

  create_table "drop_events", force: :cascade do |t|
    t.integer "drop_product_id", null: false
    t.integer "drop_variant_id"
    t.string "kind", null: false
    t.string "actor"
    t.string "emoji"
    t.text "body", null: false
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drop_product_id", "created_at"], name: "index_drop_events_on_drop_product_id_and_created_at"
    t.index ["drop_product_id"], name: "index_drop_events_on_drop_product_id"
    t.index ["drop_variant_id"], name: "index_drop_events_on_drop_variant_id"
  end

  create_table "drop_products", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "tagline", null: false
    t.string "hero_image_path", null: false
    t.integer "watching_count", default: 12847, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_drop_products_on_slug", unique: true
  end

  create_table "drop_variants", force: :cascade do |t|
    t.integer "drop_product_id", null: false
    t.string "name", null: false
    t.string "sku", null: false
    t.string "image_path", null: false
    t.integer "stock", default: 0, null: false
    t.integer "claimed_count", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drop_product_id"], name: "index_drop_variants_on_drop_product_id"
    t.index ["sku"], name: "index_drop_variants_on_sku", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "author", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "drop_events", "drop_products"
  add_foreign_key "drop_events", "drop_variants"
  add_foreign_key "drop_variants", "drop_products"
end
