class CreateUser < ActiveRecord::Migration
  def change
    create_table "users"
  end
end
