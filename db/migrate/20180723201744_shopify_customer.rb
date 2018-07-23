class ShopifyCustomer < ActiveRecord::Migration[5.2]
  def up
    create_table :shopify_customers do |t|
      t.string :shopify_customer_id
      t.string :email
      t.string :first_name
      t.string :last_name
      t.datetime :created_at
      t.string :shopify_tags
      

    end
  end

  def down
    drop_table :shopify_customers
  end
end
