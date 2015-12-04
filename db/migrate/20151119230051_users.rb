class Users < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string "email"
      t.string "password_digest"
      t.string "token"
      t.integer "counter", default: 0

      t.timestamps null: false
    end
  end
end
