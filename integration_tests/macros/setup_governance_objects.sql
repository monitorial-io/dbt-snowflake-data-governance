{% macro setup_governance_objects() %}
{#
    Validates that the required governance objects exist before running tests.
    Run before the first `dbt build`:

        dbt run-operation setup_governance_objects

    All tags and policies are provided by the Monitorial Data Governance
    Native App and must already exist in the governance database.

    Required tags (in TAGS schema):
      - pii_classification
      - confidentiality_classification
      - semantic_classification
      - apply_masking_policy
      - default_mask_value

    Required policies (in POLICIES schema):
      - agg_min_group_five (aggregation policy)
      - hide_column (projection policy)
      - restrict_rows (row access policy)
#}

{{ log("Integration tests expect the Monitorial Data Governance Native App objects to exist in " ~ var("data_governance_database"), info=True) }}

{% endmacro %}
