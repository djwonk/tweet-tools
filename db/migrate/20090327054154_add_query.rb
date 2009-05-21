class AddQuery < ActiveRecord::Migration
  def self.up
    add_column :tweets, :query, :string
    add_index :tweets, :query
  end

  def self.down
    remove_column :tweets, :query
    remove_index :tweets, :query
  end
end
