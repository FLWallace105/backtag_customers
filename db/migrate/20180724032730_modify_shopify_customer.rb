class ModifyShopifyCustomer < ActiveRecord::Migration[5.2]
  def up
    add_column :shopify_customers, :is_updated, :boolean, default: false
    add_column :shopify_customers, :updated_at, :datetime
    
  end

  def down
    remove_column :shopify_customers, :is_updated, :boolean
    remove_column :shopify_customers, :updated_at, :datetime
    
  end


end
