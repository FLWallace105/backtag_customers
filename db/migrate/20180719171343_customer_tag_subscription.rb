class CustomerTagSubscription < ActiveRecord::Migration[5.2]
  def up
    create_table :customer_tag_subscriptions do |t|
      t.string :subscription_id
      t.string :customer_id
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :next_charge_scheduled_at
      t.datetime :cancelled_at
      t.string :product_title
      t.decimal :price, precision: 10, scale: 2
      t.integer :quantity
      t.string :status
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.string :sku
      t.string :shopify_customer_id
      t.string :shopify_tags
      t.datetime :tag_updated_at
      t.boolean :is_tag_updated, default: false

    end
  end

  def down
    drop_table :customer_tag_subscriptions
  end
end
