{{ config(materialized='table') }}

select
    1 as id,
    'Engineering' as department
union all
select
    2 as id,
    'Marketing' as department
