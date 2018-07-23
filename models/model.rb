class CustomerTagSubscriptions < ActiveRecord::Base
  self.table_name = "customer_tag_subscriptions"
end

class Subscriptions < ActiveRecord::Base
    self.table_name = "subscriptions"

end

class ShopifyCustomersTags < ActiveRecord::Base
  self.table_name = "shopify_customers"
end