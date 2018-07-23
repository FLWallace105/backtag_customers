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

    #add_tags_to_customer_tag_subscriptions
    desc 'final prep for customer_tag_subscriptions'
    task :final_prep_customer_tag_subscriptions do |t|
        BackTag::UpdateTag.new.add_tags_to_customer_tag_subscriptions
    end

    #update_only_shopify_customers
    desc 'update background only customers with no recurring_subscription tag'
    task :update_only_shopify_customers do |t|
        BackTag::UpdateTag.new.update_only_shopify_customers
    end


end