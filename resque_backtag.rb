#resque_backtag.rb
require 'dotenv'
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require_relative 'models/model'
require 'pry'

Dotenv.load

module ResqueBackTag


    def update_customer_tags(customer_tags)
        my_local_hash = Hash.new
        my_tag_array = Array.new
        if !customer_tags.nil?
            my_tag_array = customer_tags.split(", ")
            puts my_tag_array.inspect
        end
        if my_tag_array.include? "recurring_subscription"
            my_local_hash = {"update_tags_shopify" => false, "tags" => customer_tags}
        else
            my_tag_array << "recurring_subscription"
            new_tags = my_tag_array.join(", ")
            my_local_hash = {"update_tags_shopify" => true, "tags" => new_tags}
        end
        return my_local_hash

    end

    
    def back_tag_customers
        apikey = ENV['SHOPIFY_API_KEY']
        shopname = ENV['SHOPIFY_SHOP_NAME']
        password = ENV['SHOPIFY_PASSWORD']
        Resque.logger = Logger.new("#{Dir.getwd}/logs/backtag_resque.log")
        
        ShopifyAPI::Base.site = "https://#{apikey}:#{password}@#{shopname}.myshopify.com/admin"
        tag_customers = CustomerTagSubscriptions.where("is_tag_updated = ?", false)
        my_start = Time.now
        tag_customers.each do |cust|
            puts "Shopify Customer ID for this record = #{cust.shopify_customer_id}"
            Resque.logger.info "Shopify Customer ID for this record = #{cust.shopify_customer_id}"
            if !cust.shopify_customer_id.nil?
                local_customer = ShopifyAPI::Customer.find(cust.shopify_customer_id)
                my_local_update_decision = update_customer_tags(cust.shopify_tags)
                puts my_local_update_decision.inspect
                if my_local_update_decision['update_tags_shopify'] == false
                    puts "Not updating tags for this Shopify customer they already have the recurring_subscription tag"
                    Resque.logger.info "Not updating tags for this Shopify customer they already have the recurring_subscription tag"
                else
                    local_customer.tags = my_local_update_decision['tags']
                    local_customer.save
                    cust.tag_updated_at = Time.now
                    cust.is_tag_updated = true
                    cust.save
                    puts "Saving new recurring_subscription tag to customer on Shopify!"
                    Resque.logger.info "Saving new recurring_subscription tag to customer on Shopify!"
                end
                #puts local_customer.inspect
            else
                puts "No customer_id for this record"
                Resque.logger.info "No customer_id for this record"

            end
            sleep 4
            my_end = Time.now
            duration = (my_end - my_start).ceil
            puts "Running #{duration} seconds"
            Resque.logger.info "Running #{duration} seconds"
            if duration > 480
                puts "Working more than 8 minutes, must exit"
                Resque.logger.info "Working more than 8 minutes, must exit"
                exit
            else
                puts "Continuing on."
                Resque.logger.info "Continuing on."
            end

        end
        puts "All done with updating customers tags"
        Resque.logger.info "All done with updating customers tags"

    end

    def backtag_only_cust
        apikey = ENV['SHOPIFY_API_KEY']
        shopname = ENV['SHOPIFY_SHOP_NAME']
        password = ENV['SHOPIFY_PASSWORD']
        Resque.logger = Logger.new("#{Dir.getwd}/logs/backtag_resque.log")
        
        ShopifyAPI::Base.site = "https://#{apikey}:#{password}@#{shopname}.myshopify.com/admin"
        tag_customers = CustomerTagSubscriptions.where("is_tag_updated = ?", false)
        my_start = Time.now

        tag_customers.each do |cust|
            puts "Shopify Customer ID for this record = #{cust.shopify_customer_id}"
            Resque.logger.info "Shopify Customer ID for this record = #{cust.shopify_customer_id}"
            if !cust.shopify_customer_id.nil?
                local_tags = cust.shopify_tags
                if local_tags.nil?
                    local_tags = "recurring_subscription"
                else
                    local_tags = local_tags << ", recurring_subscription"

                end
                #Now update Shopify
                local_customer = ShopifyAPI::Customer.find(cust.shopify_customer_id)
                local_customer.tags = local_tags
                local_customer.save
                cust.tag_updated_at = Time.now
                cust.is_tag_updated = true
                cust.save
                puts "Saving new recurring_subscription tag to customer on Shopify!"
                Resque.logger.info "Saving new recurring_subscription tag to customer on Shopify!"

            else
                puts "Cannot update this subscription -- no matching shopify customer id"
                Resque.logger.info "Cannot update this subscription -- no matching shopify customer id"
            end
            #end of saving stuff to Shopify and local DB
            sleep 4
            my_end = Time.now
            duration = (my_end - my_start).ceil
            puts "Running #{duration} seconds"
            Resque.logger.info "Running #{duration} seconds"
            if duration > 480
                puts "Working more than 8 minutes, must exit"
                Resque.logger.info "Working more than 8 minutes, must exit"
                exit
            else
                puts "Continuing on."
                Resque.logger.info "Continuing on."
            end

        
        end
        puts "All done with updating customers tags"
        Resque.logger.info "All done with updating customers tags"



    end



end