{{ config(materialized='table') }}

select
    1 as id,
    100 as metric_value
union all
select
    2 as id,
    200 as metric_value
