Table customers {
  customer_id text [pk]
  customer_unique_id text
  customer_zip_code_prefix int
  customer_city text
  customer_state text
}

Table orders {
  order_id text [pk]
  customer_id text [ref: > customers.customer_id]
  order_status text
  order_purchase_timestamp timestamp
  order_approved_at timestamp
  order_delivered_carrier_date timestamp
  order_delivered_customer_date timestamp
  order_estimated_delivery_date timestamp
}

Table order_items {
  order_id text [ref: > orders.order_id]
  order_item_id int
  product_id text [ref: > products.product_id]
  seller_id text [ref: > sellers.seller_id]
  shipping_limit_date timestamp
  price numeric
  freight_value numeric

  indexes {
    (order_id, order_item_id) [pk]
  }
}

Table order_payments {
  order_id text [ref: > orders.order_id]
  payment_sequential int
  payment_type text
  payment_installments int
  payment_value numeric

  indexes {
    (order_id, payment_sequential) [pk]
  }
}

Table order_reviews {
  review_id text
  order_id text [ref: > orders.order_id]
  review_score int
  review_comment_title text
  review_comment_message text
  review_creation_date timestamp
  review_answer_timestamp timestamp
}

Table products {
  product_id text [pk]
  product_category_name text [ref: > product_category_translation.product_category_name]
  product_name_lenght int
  product_description_lenght int
  product_photos_qty int
  product_weight_g int
  product_length_cm int
  product_height_cm int
  product_width_cm int
}

Table sellers {
  seller_id text [pk]
  seller_zip_code_prefix int
  seller_city text
  seller_state text
}

Table product_category_translation {
  product_category_name text [pk]
  product_category_name_english text
}

Table geolocation {
  geolocation_zip_code_prefix int
  geolocation_lat float
  geolocation_lng float
  geolocation_city text
  geolocation_state text
}