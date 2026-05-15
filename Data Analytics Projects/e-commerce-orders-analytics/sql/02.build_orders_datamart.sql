-- 02_build_orders_datamart.sql
-- Построение аналитической витрины заказов Olist
-- 1 строка = 1 заказ


drop table if exists orders_datamart;


create table orders_datamart as

with items_agg as (
    select
        oi.order_id,
        count(*) as items_count,
        count(distinct oi.product_id) as products_count,
        count(distinct oi.seller_id) as sellers_count,
        count(distinct coalesce(
            t.product_category_name_english,
            nullif(trim(p.product_category_name), ''),
            'unknown_category'
        )) as product_categories_count,
        sum(oi.price) as order_revenue,
        sum(oi.freight_value) as freight_value
    from order_items oi
    left join products p
        on oi.product_id = p.product_id
    left join product_category_translation t
        on p.product_category_name = t.product_category_name
    group by oi.order_id
),

category_revenue as (
    select
        oi.order_id,
        coalesce(
            t.product_category_name_english,
            nullif(trim(p.product_category_name), ''),
            'unknown_category'
        ) as product_category,
        sum(oi.price) as category_revenue
    from order_items oi
    left join products p
        on oi.product_id = p.product_id
    left join product_category_translation t
        on p.product_category_name = t.product_category_name
    group by
        oi.order_id,
        coalesce(
            t.product_category_name_english,
            nullif(trim(p.product_category_name), ''),
            'unknown_category'
        )
),

main_category as (
    select
        order_id,
        product_category as main_product_category
    from (
        select
            order_id,
            product_category,
            category_revenue,
            row_number() over (
                partition by order_id
                order by category_revenue desc, product_category
            ) as rn
        from category_revenue
    ) ranked_categories
    where rn = 1
),

payments_agg as (
    select
        order_id,
        count(*) as payments_count,
        sum(payment_value) as payment_value,
        max(payment_installments) as payment_installments_max,
        string_agg(distinct payment_type, ', ') as payment_types
    from order_payments
    group by order_id
),

reviews_agg as (
    select
        order_id,
        count(*) as reviews_count,
        avg(review_score) as review_score
    from order_reviews
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    date(o.order_purchase_timestamp) as order_date,
    date_trunc('month', o.order_purchase_timestamp)::date as order_month,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    coalesce(i.items_count, 0) as items_count,
    coalesce(i.products_count, 0) as products_count,
    coalesce(i.sellers_count, 0) as sellers_count,
    coalesce(i.product_categories_count, 0) as product_categories_count,
    coalesce(i.order_revenue, 0) as order_revenue,
    coalesce(i.freight_value, 0) as freight_value,
    coalesce(mc.main_product_category, 'unknown_category') as main_product_category,

    coalesce(p.payment_value, 0) as payment_value,
    coalesce(p.payments_count, 0) as payments_count,
    p.payment_installments_max,
    coalesce(p.payment_types, 'unknown_payment') as payment_types,

    r.review_score,
    coalesce(r.reviews_count, 0) as reviews_count,
    case
        when r.reviews_count is null then 0
        else 1
    end as has_review,

    case
        when o.order_delivered_customer_date is not null then 1
        else 0
    end as is_delivered,

    case
        when o.order_delivered_customer_date is not null
         and o.order_delivered_customer_date > o.order_estimated_delivery_date
        then 1
        else 0
    end as is_late_delivery,

    round(
        extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400,
        2
    ) as delivery_days,

    round(
        extract(epoch from (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400,
        2
    ) as delivery_delay_days

from orders o
left join customers c
    on o.customer_id = c.customer_id
left join items_agg i
    on o.order_id = i.order_id
left join main_category mc
    on o.order_id = mc.order_id
left join payments_agg p
    on o.order_id = p.order_id
left join reviews_agg r
    on o.order_id = r.order_id;



-- Проверка количества строк в витрине
select count(*) as datamart_rows
from orders_datamart;


-- Проверка, что одна строка = один заказ
select
    count(*) as rows_count,
    count(distinct order_id) as unique_orders_count
from orders_datamart;


-- Проверка первых строк
select *
from orders_datamart
limit 20;


-- Проверка финансовых метрик
select
    sum(order_revenue) as total_order_revenue,
    sum(freight_value) as total_freight_value,
    sum(payment_value) as total_payment_value
from orders_datamart;


-- Проверка заказов без оплаты
select *
from orders_datamart
where payment_value = 0
order by order_status;


-- Проверка доставленных заказов с задержкой
select
    count(*) as late_delivered_orders
from orders_datamart
where is_late_delivery = 1
  and order_status = 'delivered';