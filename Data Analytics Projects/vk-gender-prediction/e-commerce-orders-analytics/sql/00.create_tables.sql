drop table if exists order_reviews;
drop table if exists order_items;
drop table if exists order_payments;
drop table if exists orders;
drop table if exists customers;
drop table if exists products;
drop table if exists sellers;
drop table if exists geolocation;
drop table if exists product_category_translation;

create table customers (
	customer_id text,
	customer_unique_id text,
	customer_zip_code_prefix integer,
	customer_city text,
	customer_state text
);

create table orders (
	order_id text,
	customer_id text,
	order_status text,
	order_purchase_timestamp timestamp,
	order_approved_at timestamp,
	order_delivered_carrier_date timestamp,
	order_delivered_customer_date timestamp,
	order_estimated_delivery_date timestamp
);


create table order_items (
	order_id text,
    order_item_id integer,
    product_id text,
    seller_id text,
    shipping_limit_date timestamp,
    price numeric(10, 2),
    freight_value numeric (10, 2)
);


create table order_payments (
	order_id text,
    payment_sequential integer,
    payment_type text,
    payment_installments integer,
    payment_value numeric(10, 2)
);


create table order_reviews (
    review_id text,
    order_id text,
    review_score integer,
    review_comment_title text,
    review_comment_message text,
    review_creation_date text,
    review_answer_timestamp text
);


create table products (
    product_id text,
    product_category_name text,
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer
);


create table sellers (
    seller_id text,
    seller_zip_code_prefix integer,
    seller_city text,
    seller_state text
);


create table geolocation (
    geolocation_zip_code_prefix integer,
    geolocation_lat float8,
    geolocation_lng float8,
    geolocation_city text,
    geolocation_state text
);


create table product_category_translation (
    product_category_name text,
    product_category_name_english text
);