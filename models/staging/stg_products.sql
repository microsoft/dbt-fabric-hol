select product_id, trim(product_name) product_name, trim(category) category, cast(unit_price as decimal(10,2)) unit_price from {{ source('seed','products') }}
