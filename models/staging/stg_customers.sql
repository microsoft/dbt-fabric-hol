select customer_id, trim(customer_name) customer_name, trim(segment) segment, trim(country) country from {{ source('seed','customers') }}
