require 'dotenv'
Dotenv.load
require 'redis'
require 'resque'
Resque.redis = Redis.new(url: ENV['REDIS_URL'])
require 'active_record'
#require 'sinatra'
require 'sinatra/activerecord/rake'
require 'resque/tasks'
require_relative 'backtag_customers'
require_relative 'resque_backtag.rb'
require 'pry'


namespace :back_tag do
    desc 'setup subscribers for updating'
    task :setup_subs_table do |t|
        BackTag::UpdateTag.new.create_backtag_table
    end

    #get_shopify_customers
    desc 'load shopify customers'
    task :load_shopify_customers do |t|
        BackTag::UpdateTag.new.get_shopify_customers
    end

    #update_shopify_customers
    desc 'update Shopify customers tags to recurring_subscription'
    task :update_shopify_customers do |t|
        BackTag::UpdateTag.new.update_shopify_customers
    end

end