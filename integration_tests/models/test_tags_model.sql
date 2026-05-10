{{ config(materialized='table') }}

select
    1 as id,
    'John Doe' as full_name,
    'john@example.com' as email_address
union all
select
    2 as id,
    'Jane Smith' as full_name,
    'jane@example.com' as email_address
