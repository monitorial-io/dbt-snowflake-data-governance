-- Test that pii_classification tag was applied to the full_name column
-- This test passes if the tag exists (returns 0 rows)
-- depends_on: {{ ref('test_tags_model') }}
{% set model_schema = target.database | upper ~ '.' ~ target.schema | upper %}

with expected_tags as (
    select 'FULL_NAME' as column_name, 'PII_CLASSIFICATION' as expected_tag
    union all
    select 'EMAIL_ADDRESS', 'PII_CLASSIFICATION'
    union all
    select 'FULL_NAME', 'CONFIDENTIALITY_CLASSIFICATION'
    union all
    select 'EMAIL_ADDRESS', 'CONFIDENTIALITY_CLASSIFICATION'
    union all
    select 'EMAIL_ADDRESS', 'SEMANTIC_CLASSIFICATION'
),
actual_tags as (
    select
        upper(COLUMN_NAME) as column_name,
        upper(TAG_NAME) as tag_name
    from table(information_schema.tag_references_all_columns('{{ model_schema }}.TEST_TAGS_MODEL', 'table'))
    where LEVEL = 'COLUMN'
)
select
    e.column_name,
    e.expected_tag
from expected_tags e
left join actual_tags a
    on e.column_name = a.column_name
    and e.expected_tag = a.tag_name
where a.tag_name is null
