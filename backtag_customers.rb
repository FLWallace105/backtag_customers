#file backtag_customers.rb
require 'shopify_api'
require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
require_relative 'models/model'
require_relative 'resque_backtag.rb'

require 'pry'

module BackTag
    class UpdateTag
        def initialize
            Dotenv.load
            @apikey = ENV['SHOPIFY_API_KEY']
            @shopname = ENV['SHOPIFY_SHOP_NAME']
            @password = ENV['SHOPIFY_PASSWORD']

        end

        def create_backtag_table
            #delete table and reset index
            CustomerTagSubscriptions.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('customer_tag_subscriptions')

            subs_update = "insert into customer_tag_subscriptions (subscription_id, customer_id, created_at, updated_at, next_charge_scheduled_at, cancelled_at, product_title, price, quantity, status, shopify_product_id, shopify_variant_id, sku) select subscription_id, customer_id, created_at, updated_at, next_charge_scheduled_at, cancelled_at, product_title, price, quantity, status, shopify_product_id, shopify_variant_id, sku from subscriptions where status = 'ACTIVE' "
            ActiveRecord::Base.connection.execute(subs_update)

            more_subs_update = "update customer_tag_subscriptions set shopify_customer_id = customers.shopify_customer_id from customers where customers.customer_id = customer_tag_subscriptions.customer_id"

            ActiveRecord::Base.connection.execute(more_subs_update)

            delete_dupes = "delete from customer_tag_subscriptions cust where cust.ctid <> (select min(mycust.ctid) from customer_tag_subscriptions mycust where cust.shopify_customer_id = mycust.shopify_customer_id)"

            ActiveRecord::Base.connection.execute(delete_dupes)

            puts "All Done setting up customers for backtagging."

        end


        def get_shopify_customers
            #puts "@apikey = #{@apikey}"
            ShopifyAPI::Base.site = "https://#{@apikey}:#{@password}@#{@shopname}.myshopify.com/admin"
            customer_count = ShopifyAPI::Customer.count
            puts "We have #{customer_count} customers"
            

            page_size = 250
            pages = (customer_count / page_size.to_f).ceil

            1.upto(pages) do |page|
                customers = ShopifyAPI::Customer.find(:all, params: {limit: 250})
                customers.each do |mycust|
                    #puts mycust.inspect
                    puts "#{mycust.attributes['email']}, #{mycust.attributes['tags']}, #{mycust.attributes['id']}"
                    #puts mycust.attributes['tags']
                    #puts mycust.attributes['id']
                    my_local_id = mycust.attributes['id'].to_s
                    cust_tag = CustomerTagSubscriptions.find_by_shopify_customer_id(my_local_id)
                    if !cust_tag.nil?
                        if !mycust.attributes['tags'].nil?
                            cust_tag.shopify_tags = mycust.attributes['tags']
                            cust_tag.save!
                            puts cust_tag.inspect
                        else
                            puts "No tags for this customer, nothing to save"
                        end
                    else
                        puts "Can't find customer from Shopify in Subscription record"

                    end

                end
                puts "Done with page #{page}"
            end

        end


        def update_shopify_customers
            puts "Now pushing task to background resque for updating customer tags"
            Resque.enqueue(BackTagCustomers)



        end

        class BackTagCustomers
            extend ResqueBackTag
            @queue = "back_tag_cust"
            def self.perform
                back_tag_customers
      
            end
          end


    end
end
