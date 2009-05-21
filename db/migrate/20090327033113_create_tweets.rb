class CreateTweets < ActiveRecord::Migration
  def self.up
    create_table :tweets do |t|
      t.string   :profile_image_url
      t.datetime :created_at
      t.string   :from_user
      t.string   :text
      t.integer  :to_user_id
      t.integer  :twitter_id
      t.integer  :from_user_id
      t.string   :iso_language_code
      t.string   :source
    end
  end

  def self.down
    drop_table :tweets
  end
end
