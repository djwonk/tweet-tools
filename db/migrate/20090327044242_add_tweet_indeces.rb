class AddTweetIndeces < ActiveRecord::Migration
  def self.up
    add_index :tweets, :twitter_id
    add_index :tweets, :to_user_id
    add_index :tweets, :from_user_id
    add_index :tweets, :created_at
  end

  def self.down
    remove_index :tweets, :twitter_id
    remove_index :tweets, :to_user_id
    remove_index :tweets, :from_user_id
    remove_index :tweets, :created_at
  end
end
