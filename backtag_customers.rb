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


        def quick_get_shopify_customers
            ShopifyAPI::Base.site = "https://#{@apikey}:#{@password}@#{@shopname}.myshopify.com/admin"     
            ShopifyCustomersTags.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('shopify_customers')

            customers = ShopifyAPI::Customer.find(:all, params: {limit: 250, query: 'Gay'})

            customers.each do |cust|
                puts cust.inspect
            end

            customer_count = ShopifyAPI::Customer.count
            puts "We have #{customer_count} customers"

        end

        def read_customer_tags
            ShopifyCustomersTags.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('shopify_customers')
            CSV.foreach('customers_export.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
                first_name = row['First Name']
                last_name = row['Last Name']
                email = row['Email']
                tags = row['Tags']
                puts "#{first_name}, #{last_name}, #{email}, #{tags}"
                my_local_shopify_customer = ShopifyCustomersTags.create(first_name: first_name, last_name: last_name, email: email, shopify_tags: tags)
              end


        end



        def get_shopify_customers
            #puts "@apikey = #{@apikey}"
            ShopifyAPI::Base.site = "https://#{@apikey}:#{@password}@#{@shopname}.myshopify.com/admin"
            customer_count = ShopifyAPI::Customer.count
            puts "We have #{customer_count} customers"
            
            #delete prior entries and reset the index
            #ShopifyCustomersTags.delete_all
            #ActiveRecord::Base.connection.reset_pk_sequence!('shopify_customers')


            page_size = 250
            pages = (customer_count / page_size.to_f).ceil

            1.upto(pages) do |page|
                customers = ShopifyAPI::Customer.find(:all, params: {limit: 250, page: page})
                customers.each do |mycust|
                    #puts mycust.inspect
                    puts "#{mycust.attributes['email']}, #{mycust.attributes['tags']}, #{mycust.attributes['id']}"
                    local_shopify_customer = ShopifyCustomersTags.find_by_email(mycust.attributes['email'])
                    if !local_shopify_customer.nil?
                        local_shopify_customer.shopify_customer_id = mycust.attributes['id']
                        local_shopify_customer.save!
                        puts local_shopify_customer.inspect
                    end

                    #my_shopify_customer = ShopifyCustomersTags.create(shopify_customer_id: mycust.attributes['id'], email: mycust.attributes['email'], created_at: mycust.attributes['created_at'], shopify_tags: mycust.attributes['tags'], first_name: mycust.attributes['first_name'], last_name: mycust.attributes['last_name'])
                    #puts mycust.attributes['tags']
                    #puts mycust.attributes['id']


                    #my_local_id = mycust.attributes['id'].to_s
                    #cust_tag = CustomerTagSubscriptions.find_by_shopify_customer_id(my_local_id)
                    #if !cust_tag.nil?
                    #    if !mycust.attributes['tags'].nil?
                    #        cust_tag.shopify_tags = mycust.attributes['tags']
                    #        cust_tag.save!
                    #        puts cust_tag.inspect
                    #    else
                    #        puts "No tags for this customer, nothing to save"
                    #    end
                    #else
                    #    puts "Can't find customer from Shopify in Subscription record"

                    #end
                    
                end
                
                puts "Done with page #{page}"
                sleep 4
            end

        end

        def add_tags_to_customer_tag_subscriptions
            update_customer_tag_subscriptions_sql = "update customer_tag_subscriptions set shopify_tags = shopify_customers.shopify_tags from shopify_customers where shopify_customers.shopify_customer_id = customer_tag_subscriptions.shopify_customer_id"
            ActiveRecord::Base.connection.execute(update_customer_tag_subscriptions_sql)
            delete_already_ok = "delete from customer_tag_subscriptions where shopify_tags ilike '%recurring_subscription%' "
            ActiveRecord::Base.connection.execute(delete_already_ok)

        
        end


        def update_shopify_customers
            puts "Now pushing task to background resque for updating customer tags"
            Resque.enqueue(BackTagCustomers)



        end

        def update_only_shopify_customers
            puts "Now pushing to background only the customers that don't have recurring_subscription tags"
            Resque.enqueue(BackTagOnlyCustomers)
        end


        class BackTagOnlyCustomers
            extend ResqueBackTag
            @queue = "back_tag_only_customers"
            def self.perform
                backtag_only_cust
            end

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
