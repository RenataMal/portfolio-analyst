-- 03.analytics_queries.sql
-- Аналитические запросы по витрине orders_datamart


-- 1. Проверка витрины: одна строка = один заказ
select count(*) as rows_count,
	count(distinct order_id) as unique_orders_count
from orders_datamart;


-- 2. Общие KPI
select count(distinct order_id) as orders_count,
	count(distinct customer_unique_id) as customers_count,
    round(sum(order_revenue), 2) as total_revenue,
    round(sum(freight_value), 2) as total_freight_value,
    round(sum(payment_value), 2) as total_payment_value,
    round(sum(order_revenue) / nullif(count(distinct order_id), 0), 2) as avg_order_value,
    round(avg(review_score), 2) as avg_review_score,
    round(
        sum(is_late_delivery) * 100.0 
        / nullif(count(distinct case when is_delivered = 1 then order_id end), 0),
        2
    ) as late_delivery_share_percent
from orders_datamart;


-- 3. Динамика заказов, клиентов и выручки по месяцам
select order_month,
    count(distinct order_id) as orders_count,
    count(distinct customer_unique_id) as customers_count,
    round(sum(order_revenue), 2) as revenue,
    round(sum(payment_value), 2) as payment_value,
    round(sum(order_revenue) / nullif(count(distinct order_id), 0), 2) as avg_order_value
from orders_datamart
group by order_month
order by order_month;


-- 4. Накопительная выручка по месяцам
select
    order_month,
    revenue,
    sum(revenue) over (
        order by order_month
    ) as cumulative_revenue
from (
    select
        order_month,
        round(sum(order_revenue), 2) as revenue
    from orders_datamart
    group by order_month
) monthly_revenue
order by order_month;


-- 5. Рост выручки к предыдущему месяцу
select
    order_month,
    revenue,
    lag(revenue) over (
        order by order_month
    ) as previous_month_revenue,
    round(
        (revenue - lag(revenue) over (order by order_month))
        * 100.0
        / nullif(lag(revenue) over (order by order_month), 0),
        2
    ) as revenue_growth_percent
from (
    select
        order_month,
        sum(order_revenue) as revenue
    from orders_datamart
    group by order_month
) monthly_revenue
order by order_month;


-- 6. Распределение заказов по статусам
select
    order_status,
    count(distinct order_id) as orders_count,
    round(
        count(distinct order_id) * 100.0
        / sum(count(distinct order_id)) over (),
        2
    ) as orders_share_percent,
    round(sum(order_revenue), 2) as revenue
from orders_datamart
group by order_status
order by orders_count desc;


-- 7. Топ регионов по выручке
select
    customer_state,
    count(distinct order_id) as orders_count,
    count(distinct customer_unique_id) as customers_count,
    round(sum(order_revenue), 2) as revenue,
    round(sum(order_revenue) / nullif(count(distinct order_id), 0), 2) as avg_order_value,
    rank() over (
        order by sum(order_revenue) desc
    ) as revenue_rank
from orders_datamart
group by customer_state
order by revenue_rank;


-- 8. Топ категорий по выручке
select
    main_product_category,
    count(distinct order_id) as orders_count,
    round(sum(order_revenue), 2) as revenue,
    round(sum(order_revenue) / nullif(count(distinct order_id), 0), 2) as avg_order_value,
    round(avg(review_score), 2) as avg_review_score
from orders_datamart
group by main_product_category
order by revenue desc
limit 15;


-- 9. Анализ доставки по регионам
select
    customer_state,
    count(distinct order_id) as delivered_orders,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(delivery_delay_days), 2) as avg_delay_days,
    round(
        sum(is_late_delivery) * 100.0
        / nullif(count(distinct order_id), 0),
        2
    ) as late_delivery_share_percent,
    round(avg(review_score), 2) as avg_review_score
from orders_datamart
where is_delivered = 1
group by customer_state
having count(distinct order_id) >= 100
order by late_delivery_share_percent desc;


-- 10. Связь задержки доставки и оценки клиента
select
    case
        when delivery_delay_days <= 0 then 'on_time_or_early'
        when delivery_delay_days > 0 and delivery_delay_days <= 3 then 'delay_1_3_days'
        when delivery_delay_days > 3 and delivery_delay_days <= 7 then 'delay_4_7_days'
        else 'delay_more_than_7_days'
    end as delivery_delay_group,
    count(distinct order_id) as orders_count,
    round(avg(review_score), 2) as avg_review_score,
    round(avg(delivery_days), 2) as avg_delivery_days
from orders_datamart
where is_delivered = 1
  and review_score is not null
  and delivery_delay_days is not null
group by
    case
        when delivery_delay_days <= 0 then 'on_time_or_early'
        when delivery_delay_days > 0 and delivery_delay_days <= 3 then 'delay_1_3_days'
        when delivery_delay_days > 3 and delivery_delay_days <= 7 then 'delay_4_7_days'
        else 'delay_more_than_7_days'
    end
order by avg_review_score desc;


-- 11. Распределение оценок клиентов
select
    review_score,
    count(distinct order_id) as orders_count,
    round(
        count(distinct order_id) * 100.0
        / sum(count(distinct order_id)) over (),
        2
    ) as review_share_percent
from orders_datamart
where review_score is not null
group by review_score
order by review_score;


-- 12. Анализ способов оплаты
select
    payment_types,
    count(distinct order_id) as orders_count,
    round(sum(payment_value), 2) as payment_value,
    round(avg(payment_installments_max), 2) as avg_installments,
    round(avg(review_score), 2) as avg_review_score
from orders_datamart
group by payment_types
order by orders_count desc;


-- 13. Повторные покупки клиентов
select
    case
        when orders_count = 1 then 'one_order'
        when orders_count between 2 and 3 then '2_3_orders'
        else '4_or_more_orders'
    end as customer_segment,
    count(*) as customers_count,
    round(avg(total_revenue), 2) as avg_customer_revenue,
    round(sum(total_revenue), 2) as segment_revenue
from (
    select
        customer_unique_id,
        count(distinct order_id) as orders_count,
        sum(order_revenue) as total_revenue
    from orders_datamart
    where customer_unique_id is not null
    group by customer_unique_id
) customer_metrics
group by
    case
        when orders_count = 1 then 'one_order'
        when orders_count between 2 and 3 then '2_3_orders'
        else '4_or_more_orders'
    end
order by segment_revenue desc;