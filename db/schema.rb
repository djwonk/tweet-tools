# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090521185429) do

  create_table "tweets", :force => true do |t|
    t.string   "profile_image_url"
    t.datetime "created_at"
    t.string   "from_user"
    t.string   "text"
    t.integer  "to_user_id"
    t.integer  "twitter_id"
    t.integer  "from_user_id"
    t.string   "iso_language_code"
    t.string   "source"
    t.string   "query"
  end

  add_index "tweets", ["created_at"], :name => "index_tweets_on_created_at"
  add_index "tweets", ["from_user_id"], :name => "index_tweets_on_from_user_id"
  add_index "tweets", ["query"], :name => "index_tweets_on_query"
  add_index "tweets", ["to_user_id"], :name => "index_tweets_on_to_user_id"
  add_index "tweets", ["twitter_id"], :name => "index_tweets_on_twitter_id"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.integer  "follower_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["follower_count"], :name => "index_users_on_follower_count"
  add_index "users", ["username"], :name => "index_users_on_username"

end
