class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer "user_id"
      t.string "file_name"
      t.string "word"
      t.boolean "hidden", default: false

      t.timestamps null: false
    end
  end
end
