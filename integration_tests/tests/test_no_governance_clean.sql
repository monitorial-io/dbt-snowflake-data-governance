-- Test that the control model with no governance config has no policies applied
-- Returns rows if unexpected policies are found (test fails)
-- depends_on: {{ ref('test_no_governance_model') }}
{% set model_schema = target.database | upper ~ '.' ~ target.schema | upper %}

select
    POLICY_NAME,
    POLICY_KIND
from table(information_schema.policy_references(
    ref_entity_name => '{{ model_schema }}.TEST_NO_GOVERNANCE_MODEL',
    ref_entity_domain => 'table'
))
