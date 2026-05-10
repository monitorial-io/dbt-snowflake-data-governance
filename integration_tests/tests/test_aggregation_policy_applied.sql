-- Test that the aggregation policy was applied to the model
-- Returns rows if the expected policy is missing (test fails)
-- depends_on: {{ ref('test_aggregation_policy_model') }}
{% set model_schema = target.database | upper ~ '.' ~ target.schema | upper %}

with expected_policies as (
    select 'AGG_MIN_GROUP_FIVE' as policy_name
),
actual_policies as (
    select upper(POLICY_NAME) as policy_name
    from table(information_schema.policy_references(
        ref_entity_name => '{{ model_schema }}.TEST_AGGREGATION_POLICY_MODEL',
        ref_entity_domain => 'table'
    ))
    where policy_kind = 'AGGREGATION_POLICY'
)
select e.policy_name
from expected_policies e
left join actual_policies a on e.policy_name = a.policy_name
where a.policy_name is null
