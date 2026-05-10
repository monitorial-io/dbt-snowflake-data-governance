{{ config(materialized='table') }}

select
    1 as id,
    'no_governance' as value
