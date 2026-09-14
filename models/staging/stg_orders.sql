select order_id, cast(order_date as date) order_date, customer_id, product_id, quantity from {{ source('seed','orders') }}
