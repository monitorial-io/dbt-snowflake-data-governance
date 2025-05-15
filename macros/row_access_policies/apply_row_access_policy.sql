{% macro apply_row_access_policy() %}
    {% if execute %}
        {% set materialization_map = {"table": "table", "view": "view", "incremental": "table", "snapshot": "table", "immutable_table" : "table", "materialized_view" : "view"} %}
        {%- set model_database = model.database|upper -%}
        {%- set model_schema =  model.schema|upper -%}
        {%- set model_schema_full = model_database + '.' + model_schema -%}
        {%- set model_alias = model.alias|upper -%}
        {%- set materialization = materialization_map[model.config.get("materialized")] -%}
        {% if materialization in ["table", "view"] %}
            {%- call statement('main', fetch_result=True) -%}
                select
                    POLICY_NAME, REF_COLUMN_NAMES
                from table(information_schema.policy_references(ref_entity_name => '{{model_schema_full}}.{{model_alias}}', ref_entity_domain=> 'table'))
                where policy_kind = 'ROW_ACCESS_POLICY';
            {%- endcall -%}
            {%- set existing_row_access_policies_for_table = load_result('main')['data'] -%}
            {% if dbt_monitorial_datagovernance.model_meta_contains_item(["row_access_policy"], model) %}

                {%- set dbt_row_access_policies = model.meta["row_access_policy"] -%}
                {% if dbt_row_access_policies|length == 0 and existing_row_access_policies_for_table|length > 0 %}
                    {% set policy_name = existing_row_access_policies_for_table[0][0] %}
                    {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, policy_name)}}
                {% elif existing_row_access_policies_for_table|length == 0 %}
                    {% for policy_name, columns in row_access_policies[0].items() %}
                        {{ dbt_monitorial_datagovernance.add_row_access_policy(materialization, model_schema, model_alias, policy_name, columns)}}
                    {% endfor %}
                {% else %}
                    {% for policy in existing_row_access_policies_for_table %}
                        {% set existing_policy_name = policy[0] %}
                        {% set existing_columns = policy[1] %}
                        {% set found_matching_existing_policy = false %}
                        {% for policy_name, columns in row_access_policies[0].items() %}
                            {% if existing_policy_name != policy_name or existing_columns|sort != columns|sort %}
                                {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, existing_policy_name)}}
                                {{ dbt_monitorial_datagovernance.add_row_access_policy(materialization, model_schema, model_alias, policy_name, columns)}}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                    {% endfor %}
                {% endif %}
            {% elif existing_row_access_policies_for_table|length > 0 %}
                {% set policy_name = existing_row_access_policies_for_table[0][0] %}
                {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, policy_name)}}
            {% endif %}
        {% endif %}
    {% endif %}
{% endmacro %}