-- Test that the projection policy was applied to the sensitive_data column
-- Returns rows if the expected policy is missing (test fails)
-- depends_on: {{ ref('test_projection_policy_model') }}
{% set model_schema = target.database | upper ~ '.' ~ target.schema | upper %}

with expected as (
    select 'SENSITIVE_DATA' as column_name, 'HIDE_COLUMN' as policy_name
),
actual_policies as (
    select
        upper(REF_COLUMN_NAME) as column_name,
        upper(POLICY_NAME) as policy_name
    from table(information_schema.policy_references(
        ref_entity_name => '{{ model_schema }}.TEST_PROJECTION_POLICY_MODEL',
        ref_entity_domain => 'table'
    ))
    where policy_kind = 'PROJECTION_POLICY'
)
select e.column_name, e.policy_name
from expected e
left join actual_policies a
    on e.column_name = a.column_name
    and e.policy_name = a.policy_name
where a.policy_name is null
