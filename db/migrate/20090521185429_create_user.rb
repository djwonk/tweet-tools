class CreateUser < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string   :username
      t.integer  :follower_count
      t.timestamps
    end
    add_index :users, :username
    add_index :users, :follower_count
  end

  def self.down
    drop_table :users
    remove_index :users, :username
    remove_index :users, :follower_count
  end
end
