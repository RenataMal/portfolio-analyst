-- 01.data_quality_checks.sql
-- Первичная проверка качества данных после импорта датасета Olist


-- 1. Проверка количества строк в таблицах

select 'customers' as table_name, count(*) as rows_count from customers
union all
select 'orders', count(*) from orders
union all
select 'order_items', count(*) from order_items
union all
select 'order_payments', count(*) from order_payments
union all
select 'order_reviews', count(*) from order_reviews
union all
select 'products', count(*) from products
union all
select 'sellers', count(*) from sellers
union all
select 'geolocation', count(*) from geolocation
union all
select 'product_category_translation', count(*) from product_category_translation
order by table_name;


-- 2. Проверка пропусков в ключевых столбцах

select 'customers.customer_id' as field_name, count(*) as missing_count
from customers
where customer_id is null or trim(customer_id) = ''

union all

select 'orders.order_id', count(*)
from orders
where order_id is null or trim(order_id) = ''

union all

select 'orders.customer_id', count(*)
from orders
where customer_id is null or trim(customer_id) = ''

union all

select 'order_items.order_id', count(*)
from order_items
where order_id is null or trim(order_id) = ''

union all

select 'order_items.product_id', count(*)
from order_items
where product_id is null or trim(product_id) = ''

union all

select 'order_items.seller_id', count(*)
from order_items
where seller_id is null or trim(seller_id) = ''

union all

select 'order_payments.order_id', count(*)
from order_payments
where order_id is null or trim(order_id) = ''

union all

select 'order_reviews.order_id', count(*)
from order_reviews
where order_id is null or trim(order_id) = ''

union all

select 'products.product_id', count(*)
from products
where product_id is null or trim(product_id) = ''

union all

select 'sellers.seller_id', count(*)
from sellers
where seller_id is null or trim(seller_id) = '';


-- 3. Проверка дублей в таблицах, где идентификатор должен быть уникальным

select 'orders' as table_name, order_id as id_value, count(*) as duplicates_count
from orders
group by order_id
having count(*) > 1

union all

select 'customers', customer_id, count(*)
from customers
group by customer_id
having count(*) > 1

union all

select 'products', product_id, count(*)
from products
group by product_id
having count(*) > 1

union all

select 'sellers', seller_id, count(*)
from sellers
group by seller_id
having count(*) > 1;


-- 4. Проверка статусов заказов

select
    order_status,
    count(*) as orders_count
from orders
group by order_status
order by orders_count desc;


-- 5. Проверка некорректной последовательности дат

-- Доставка клиенту раньше оформления заказа
select *
from orders
where order_delivered_customer_date < order_purchase_timestamp
    and order_delivered_customer_date is not null
    and order_purchase_timestamp is not null;


-- Одобрение заказа раньше оформления заказа
select *
from orders
where order_approved_at < order_purchase_timestamp
    and order_approved_at is not null
    and order_purchase_timestamp is not null;


-- Передача заказа перевозчику раньше одобрения заказа
select *
from orders
where order_delivered_carrier_date < order_approved_at
    and order_delivered_carrier_date is not null
    and order_approved_at is not null;


-- Количество и доля заказов, переданных перевозчику раньше одобрения
select
    count(*) as invalid_orders_count,
    round(count(*) * 100.0 / (select count(*) from orders), 2) as invalid_orders_share
from orders
where order_delivered_carrier_date < order_approved_at
    and order_delivered_carrier_date is not null
    and order_approved_at is not null;


-- Плановая дата доставки раньше даты оформления заказа
select *
from orders
where order_estimated_delivery_date < order_purchase_timestamp
    and order_estimated_delivery_date is not null
    and order_purchase_timestamp is not null;


-- 6. Проверка цен, доставки и оплат

select *
from order_items
where price < 0
   or freight_value < 0;


select *
from order_payments
where payment_value < 0;


select *
from order_payments
where payment_installments < 0;


-- Дополнительная проверка нулевого количества платежных частей
select *
from order_payments
where payment_installments = 0;


-- 7. Проверка оценок клиентов

select
    review_score,
    count(*) as reviews_count
from order_reviews
group by review_score
order by review_score;


select *
from order_reviews
where review_score < 1
   or review_score > 5
   or review_score is null;


-- 8. Проверка связей между таблицами

-- Заказы без клиента
select o.order_id
from orders o
left join customers c
    on o.customer_id = c.customer_id
where c.customer_id is null;


-- Позиции заказов без самого заказа
select oi.order_id
from order_items oi
left join orders o
    on oi.order_id = o.order_id
where o.order_id is null;


-- Оплаты без заказа
select p.order_id
from order_payments p
left join orders o
    on p.order_id = o.order_id
where o.order_id is null;


-- Отзывы без заказа
select r.order_id
from order_reviews r
left join orders o
    on r.order_id = o.order_id
where o.order_id is null;


-- Товары в order_items, которых нет в products
select oi.product_id
from order_items oi
left join products p
    on oi.product_id = p.product_id
where p.product_id is null;


-- Продавцы в order_items, которых нет в sellers
select oi.seller_id
from order_items oi
left join sellers s
    on oi.seller_id = s.seller_id
where s.seller_id is null;


-- 9. Проверка заказов без товаров, оплат и отзывов

-- Заказы без товарных позиций
select o.order_id
from orders o
left join order_items oi
    on o.order_id = oi.order_id
where oi.order_id is null;


-- Заказы без товарных позиций по статусам
select
    o.order_status,
    count(*) as orders_count
from orders o
left join order_items oi
    on o.order_id = oi.order_id
where oi.order_id is null
group by o.order_status
order by orders_count desc;


-- Заказы без оплаты
select o.order_id
from orders o
left join order_payments p
    on o.order_id = p.order_id
where p.order_id is null;


-- Заказы без оплаты по статусам
select
    o.order_status,
    count(*) as orders_count
from orders o
left join order_payments p
    on o.order_id = p.order_id
where p.order_id is null
group by o.order_status
order by orders_count desc;


-- Заказы без отзывов
select o.order_id
from orders o
left join order_reviews r
    on o.order_id = r.order_id
where r.order_id is null;


-- Заказы без отзывов по статусам
select
    o.order_status,
    count(*) as orders_count
from orders o
left join order_reviews r
    on o.order_id = r.order_id
where r.order_id is null
group by o.order_status
order by orders_count desc;


-- Сводная проверка по статусам заказов
select
    o.order_status,
    count(distinct o.order_id) as total_orders,

    count(distinct case
        when oi.order_id is null then o.order_id
    end) as orders_without_items,

    count(distinct case
        when p.order_id is null then o.order_id
    end) as orders_without_payments,

    count(distinct case
        when r.order_id is null then o.order_id
    end) as orders_without_reviews

from orders o
left join order_items oi
    on o.order_id = oi.order_id
left join order_payments p
    on o.order_id = p.order_id
left join order_reviews r
    on o.order_id = r.order_id
group by o.order_status
order by total_orders desc;


-- 10. Проверка геоданных

select *
from geolocation
where geolocation_lat is null
   or geolocation_lng is null;


select *
from geolocation
where geolocation_lat < -90
   or geolocation_lat > 90
   or geolocation_lng < -180
   or geolocation_lng > 180;


-- 11. Категории товаров, у которых нет перевода на английский
-- Также учитываются пустые значения категории

select
    case
        when p.product_category_name is null
          or trim(p.product_category_name) = ''
        then 'unknown_category'
        else p.product_category_name
    end as product_category_name,
    count(*) as products_count
from products p
left join product_category_translation t
    on p.product_category_name = t.product_category_name
where t.product_category_name_english is null
group by
    case
        when p.product_category_name is null
          or trim(p.product_category_name) = ''
        then 'unknown_category'
        else p.product_category_name
    end
order by products_count desc;


-- 12. Сводная проверка заказов по статусу и датам

select
    order_status,
    count(*) as orders_count,
    count(order_approved_at) as with_approved_date,
    count(order_delivered_carrier_date) as with_carrier_date,
    count(order_delivered_customer_date) as with_customer_delivery_date,
    count(order_estimated_delivery_date) as with_estimated_delivery_date
from orders
group by order_status
order by orders_count desc;