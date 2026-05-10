{{ config(materialized='table') }}

select
    1 as id,
    'sensitive_value_1' as sensitive_data
union all
select
    2 as id,
    'sensitive_value_2' as sensitive_data
