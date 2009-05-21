require 'rubygems'
require 'twitter'

INTER_PAGE_DELAY   = 30 # seconds between pages
INTER_SEARCH_DELAY = 60 * 10 # seconds between searches

MAX_RESULTS      = 1500 # 1500 is fixed by the Twitter Search API
RESULTS_PER_PAGE = 100  # 100 is the max results per page
MAX_PAGES        = MAX_RESULTS / RESULTS_PER_PAGE

DUP_THRESHOLD = 10 # consecutive duplicates

namespace :x do
  desc "Download up to #{MAX_PAGES} pages (#{MAX_RESULTS} tweets)"
  task :get_max => :environment do
    get_all_pages(1, MAX_PAGES, query_param, RESULTS_PER_PAGE)
  end
  
  desc "Download tweets from page <pa> to <pb> [since <since_id>]"
  task :get_range => :environment do
    pa       = ENV['pa']
    pb       = ENV['pb']
    since_id = ENV['since_id']
    if pa.nil? || pb.nil?
      raise "pa and pb environment variables are required"
    end
    get_all_pages(pa, pb, query_param, RESULTS_PER_PAGE, since_id)
  end

  desc "Listen to <query> once every #{INTER_SEARCH_DELAY} seconds"
  task :loop => :environment do
    run_search_loop(query_param, RESULTS_PER_PAGE)
  end

  desc "Listen to <queries> once every #{INTER_SEARCH_DELAY} seconds"
  task :loop_many => :environment do
    queries = queries_param
    puts "Will loop and search for these queries:"
    queries.each { |q| puts "* #{q}"}
    run_multiple_search_loop(queries, RESULTS_PER_PAGE)
  end

  def run_multiple_search_loop(queries, results_per_page)
    len = queries.length
    last_twitter_ids = [nil] * len
    loop do
      queries.each_with_index do |query, i|
        last_twitter_ids[i] = get_fresh_pages(1, MAX_PAGES, query, RESULTS_PER_PAGE, last_twitter_ids[i])
      end
      inter_search_sleep
    end
  end
  
  def run_search_loop(query, results_per_page)
    last_twitter_id = 1 # arbitrary starting point
    loop do
      last_twitter_id = get_fresh_pages(1, MAX_PAGES, query, RESULTS_PER_PAGE, last_twitter_id)
      inter_search_sleep
    end
  end
  
  def get_all_pages(start_page, end_page, query, rpp, since_id = nil)
    puts "\n  Searching: query=#{query}, since_id=#{since_id} (all)"
    get_pages(:all, start_page, end_page, query, rpp, since_id)
  end
  
  def get_fresh_pages(start_page, end_page, query, rpp, since_id = nil)
    puts "\n  Searching: query=#{query}, since_id=#{since_id} (fresh)"
    get_pages(:fresh, start_page, end_page, query, rpp, since_id = nil)
  end

  def get_pages(all_pages, start_page, end_page, query, rpp, since_id = nil)
    bail_on_duplicate = case all_pages
    when :all   then false
    when :fresh then true
    else raise "Unexpected value: #{all_pages.inspect}"
    end

    largest = nil
    (start_page.to_i).upto(end_page.to_i) do |p|
      dup_count = 0
      puts "    ---- Page #{p} for query #{query} ----"

      search = if since_id.nil?
        Twitter::Search.new(query).per_page(rpp)
      else
        Twitter::Search.new(query).since(since_id.to_i).per_page(rpp)
      end
      
      begin
        results = search.page(p)
        # the above rarely, but sometimes, raises a
        # HTTParty::Parsers::JSON::ParseError
        
        result_count = 0
        results.each do |i|
          result_count += 1
          twitter_id = i["id"]
          if Tweet.find_by_query_and_twitter_id(query, twitter_id)
            puts "      %10i skipped (already exists in database)" % [twitter_id]
            if largest.nil? || twitter_id > largest
              largest = twitter_id
            end
            dup_count += 1
            if dup_count >= DUP_THRESHOLD && bail_on_duplicate
              inter_page_sleep
              return largest
            end
          else
            if create_tweet(query, twitter_id, i)
              puts "      %10i saved" % [twitter_id]
              if largest.nil? || twitter_id > largest
                largest = twitter_id
              end
              dup_count = 0
            else
              puts "      %10i save attempt failed" % [twitter_id]
            end
          end
        end

        if result_count < rpp
          return largest
        end

      rescue Crack::ParseError
        puts "HTTParty::Parsers::JSON::ParseError ... ignoring"
      end
      
      inter_page_sleep
    end
    largest
  end
  
  def create_tweet(query, twitter_id, i)
    Tweet.create(
      :profile_image_url => i["profile_image_url"],
      :created_at        => i["created_at"],
      :from_user         => i["from_user"],
      :text              => i["text"],
      :to_user_id        => i["to_user_id"],
      :twitter_id        => twitter_id,
      :from_user_id      => i["from_user_id"],
      :iso_language_code => i["iso_language_code"],
      :source            => i["source"],
      :query             => query
    )
  end
  
  def query_param
    ENV['query'] || '#gov20camp'
    # query = ENV['query']
    # query.nil? ? raise "query environment variable is required" : query
  end
  
  def queries_param
    queries = ENV['queries']
    if queries.nil?
      raise "queries environment variable is required"
    end
    queries.split(",")
  end

  def inter_search_sleep
    t = jitter(INTER_SEARCH_DELAY, INTER_SEARCH_DELAY / 2.0)
    puts "Sleeping for %.2f seconds...\n" % [t]
    sleep t
  end
  
  def inter_page_sleep
    t = jitter(INTER_PAGE_DELAY, INTER_PAGE_DELAY / 2.0)
    puts "Sleeping for %.2f seconds...\n" % [t]
    sleep t
  end
  
  # Defaults to +/- 40% jitter about the center
  def jitter(average, range)
    r = ((2.0 * rand) - 1.0)
    average + (range * r)
  end

end
