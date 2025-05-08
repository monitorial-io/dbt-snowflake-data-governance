{% macro apply_projection_policies() %}
    {% if execute %}
        {% set materialization_map = {"table": "table", "view": "view", "incremental": "table", "snapshot": "table", "immutable_table" : "table", "materialized_view" : "view"} %}
        {% if dbt_monitorial_datagovernance.model_column_meta_contains_items(["projection_policy"], model) %}
            {%- set model_database = model.database|upper -%}
            {%- set model_schema =  model.schema|upper -%}
            {%- set model_schema_full = model_database + '.' + model_schema -%}
            {%- set model_alias = model.alias|upper -%}
            {%- set materialization = materialization_map[model.config.get("materialized")] -%}
            {%- call statement('main', fetch_result=True) -%}
                select
                    POLICY_NAME, REF_COLUMN_NAME as COLUMN_NAME
                from table(information_schema.policy_references(ref_entity_name => '{{model_schema_full}}.{{model_alias}}', ref_entity_domain=> 'table'))
                where policy_kind = 'PROJECTION_POLICY';
            {%- endcall -%}
            {%- set existing_projection_policies_for_table = load_result('main')['data'] -%}
            {% for column in model.columns %}
                {% if "projection_policy" in model.columns[column].meta %}
                    {% set desired_projection_policy_value = model.columns[column].meta["projection_policy"] %}
                    {%- set existing_policy_for_columns = existing_projection_policies_for_table|selectattr('21','equalto',column|upper)|list -%}
                    {% if desired_projection_policy_value == 'none' and existing_policy_for_columns|length > 0  %}
                        {{ log("Removing projection policy from model " + model_schema|lower ~ "." ~ model_alias|lower, info=True) }}
                        {{ dbt_monitorial_datagovernance.unset_column_projection_policy(materialization, model_schema, model_alias, column|upper)}}
                    {% elif desired_projection_policy_value != 'none' %}
                        {{ log("Applying '" ~ desired_projection_policy_value ~ "' projection policy for model " + model_schema|lower ~ "." ~ model_alias|lower ~ "." ~ column|lower, info=True) }}
                        {{ dbt_monitorial_datagovernance.set_column_projection_policy(materialization, model_schema, model_alias, column|upper, desired_projection_policy_value)}}
                    {% endif%}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endif %}
{% endmacro %}