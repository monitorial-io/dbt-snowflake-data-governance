{% macro apply_row_access_policy() %}
    {% if execute %}
        {% set materialization_map = {"table": "table", "view": "view", "incremental": "table", "snapshot": "table", "immutable_table" : "table", "materialized_view" : "view"} %}
        {%- set model_database = model.database|upper -%}
        {%- set model_schema =  model.schema|upper -%}
        {%- set model_schema_full = model_database + '.' + model_schema -%}
        {%- set model_alias = model.alias|upper -%}
        {%- set materialization = materialization_map[model.config.get("materialized")] -%}
        {%- set meta_data = model.get("config", {}).get("meta")%}
        {% if not meta_data %}
              {% set meta_data = model.meta %}
        {% endif %}
        {% if materialization in ["table", "view"] %}
            {%- call statement('main', fetch_result=True) -%}
                select
                    POLICY_NAME, REF_ARG_COLUMN_NAMES
                from table(information_schema.policy_references(ref_entity_name => '{{model_schema_full}}.{{model_alias}}', ref_entity_domain=> 'table'))
                where policy_kind = 'ROW_ACCESS_POLICY';
            {%- endcall -%}
            {%- set existing_row_access_policies_for_table = load_result('main')['data'] -%}
            {% if dbt_monitorial_datagovernance.model_meta_contains_item("row_access_policy", model) %}
                {%- set dbt_row_access_policies = meta_data["row_access_policy"]  -%}
                {% if dbt_row_access_policies|length == 0 and existing_row_access_policies_for_table|length > 0 %}
                    {% set policy_name = existing_row_access_policies_for_table[0][0] %}
                    {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, policy_name)}}
                {% elif existing_row_access_policies_for_table|length == 0 %}
                    {% for dbt_policy in dbt_row_access_policies %}
                        {% set policy_name = dbt_policy.get("name") %}
                        {% set columns = dbt_policy.get("columns") %}
                        {{ dbt_monitorial_datagovernance.add_row_access_policy(materialization, model_schema, model_alias, policy_name, columns)}}
                    {% endfor %}
                {% else %} 
                    {% set policies_to_drop = [] %}
                    {% set policies_no_change = [] %}
                    {% for policy in existing_row_access_policies_for_table %}
                        {% set existing_policy_name = policy[0] | lower%}
                        {% set existing_columns_raw = policy[1] %}
                        {% if existing_columns_raw is string %}
                            {% if existing_columns_raw.startswith('[') and existing_columns_raw.endswith(']') %}
                                {# Parse the string representation of a list #}
                                {% set existing_columns_str = existing_columns_raw[1:-1] %}
                                {% set existing_columns = [] %}
                                {% for item in existing_columns_str.split(',') %}
                                    {% set clean_item = item.strip().strip('"').strip("'") %}
                                    {% if clean_item %}
                                        {% do existing_columns.append(clean_item | lower) %}
                                    {% endif %}
                                {% endfor %}
                            {% else %}
                                {% set existing_columns = [existing_columns_raw | lower] %}
                            {% endif %}
                        {% elif existing_columns_raw is iterable %}
                            {% set existing_columns = existing_columns_raw %}
                        {% else %}
                            {% set existing_columns = [existing_columns_raw | lower] %}
                        {% endif %}
                        {% for dbt_policy in dbt_row_access_policies %}
                            {% set policy_name = dbt_policy.get("name") | lower%}
                            {% set columns = dbt_policy.get("columns") %}
                            {% if existing_policy_name | lower == policy_name | lower and existing_columns|sort != columns|sort %}
                                {% do policies_to_drop.append(existing_policy_name) %}

                                {% break %}
                            {% elif existing_policy_name  == policy_name and existing_columns|sort == columns|sort %}
                                {% do policies_no_change.append(policy_name) %}
                                {% set policy_found = true %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                        {% if existing_policy_name not in policies_no_change %}
                            {% do policies_to_drop.append(existing_policy_name) %}
                        {% endif %}
                    {% endfor %}
                    {% for existing_policy_name in policies_to_drop %}
                        {% do log("Dropping policy: " ~ existing_policy_name, info=True) %}
                        {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, existing_policy_name)}}
                    {% endfor %}
                    {% for dbt_policy in dbt_row_access_policies %}
                        {% set policy_name = dbt_policy.get("name") %}
                        {% set columns = dbt_policy.get("columns") %}
                        {% if policy_name not in policies_no_change %}
                            {{ dbt_monitorial_datagovernance.add_row_access_policy(materialization, model_schema, model_alias, policy_name, columns)}}
                        {% else %}
                            {% do log("Policy " ~ policy_name ~ " already exists with the same columns, skipping addition.", info=True) %}
                        {% endif %}
                    {% endfor %}
                {% endif %}
            {% elif existing_row_access_policies_for_table|length > 0 %}
                {% set policy_name = existing_row_access_policies_for_table[0][0] %}
                {{ dbt_monitorial_datagovernance.drop_row_access_policy(materialization, model_schema, model_alias, policy_name)}}
            {% endif %}
        {% endif %}
    {% endif %}
{% endmacro %}