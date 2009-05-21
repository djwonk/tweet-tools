require 'rubygems'
require 'twitter'

namespace :influence do
  
  desc "Update influencer information (i.e. follower counts)"
  task :update => :environment do
    followers = {}
    tweets = Tweet.find(:all)
    tweets.each do |tweet|
      username = tweet.from_user
      followers[username] = lookup_follower_count(username)
    end
    puts
  end
  
  desc "List top influencers"
  task :list => :environment do
    users = User.find(:all, :order => 'follower_count DESC')
    users.each do |user|
      puts "%30s %10i" % [user.username, user.follower_count]
    end
  end
  
  def lookup_follower_count(username)
    user_in_db = User.find_by_username(username)
    print "#{username} "
    if user_in_db
      count = user_in_db.follower_count
      if count
        print "(#{count}), "
        count
      else
        count = get_api_follower_count(username)
        user_in_db.count = count
        user_in_db.save!
      end
    else
      count = get_api_follower_count(username)
      User.create!(
        :username       => username,
        :follower_count => count
      )
      count
    end
  end
  
  def get_api_follower_count(username)
    print "<<"
    $stdout.flush
    sleep(5)
    user = Twitter.user(username)
    count = user.followers_count
    if count
      print "#{count}>>,  "
      count
    else
      raise RuntimeError, "followers_count is NULL"
    end
  end
  
end
