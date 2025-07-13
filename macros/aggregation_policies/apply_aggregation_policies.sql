{% macro apply_aggregation_policies() %}
    {% if execute %}
        {% set materialization_map = {"table": "table", "view": "view", "incremental": "table", "snapshot": "table", "immutable_table" : "table", "materialized_view" : "view"} %}

        {%- set model_database = model.database|upper -%}
        {%- set model_schema =  model.schema|upper -%}
        {%- set model_schema_full = model_database + '.' + model_schema -%}
        {%- set model_alias = model.alias|upper -%}
        {%- set materialization = materialization_map[model.config.get("materialized")] -%}
        {%- set meta_data = model.config.get("meta")%}
        {% if not meta_data %}
              {% set meta_data = model.meta %}
        {% endif %}
        {% if materialization in ["table", "view"] %}
            {%- call statement('main', fetch_result=True) -%}
                select POLICY_NAME, REF_ARG_COLUMN_NAMES
                from table(information_schema.policy_references(ref_entity_name => '{{model_schema_full}}.{{model_alias}}', ref_entity_domain=> 'table'))
                where policy_kind = 'AGGREGATION_POLICY';
            {%- endcall -%}
            {%- set existing_aggrgegate_policies_for_table = load_result('main')['data'] -%}

            {% if dbt_monitorial_datagovernance.model_meta_contains_item("aggregation_policies", model) %}
                {%- set apply_policies = [] %}
                {%- set no_change_policies = [] %}
                {%- set remove_policies = [] %}

                {%- set dbt_aggregation_policies = meta_data["aggregation_policies"] -%}

                {% if dbt_aggregation_policies is none %}
                {%set dbt_aggregation_policies = [] %}
                {% endif %}

                {% if dbt_aggregation_policies|length == 0 and existing_aggrgegate_policies_for_table|length > 0 %}
                    {% for policy in existing_aggrgegate_policies_for_table %}
                        {% do remove_policies.append({ "policy_name" : policy[0], "columns" : policy[1] }) %}
                    {% endfor %}
                {% else %}

                    {% for policy in existing_aggrgegate_policies_for_table %}
                        {% set policy_name = policy[0] %}
                        {% set columns = policy[1] %}
                        {% set dbt_policy = dbt_aggregation_policies|selectattr('name','equalto',policy_name)|list %}
                        {% if dbt_policy|length == 0 %}
                            {% do remove_policies.append({ "policy_name" : policy_name, "columns" : columns}) %}
                        {% endif %}
                    {% endfor %}

                    {% for policy in dbt_aggregation_policies %}
                        {% set policy_name = policy["name"] %}
                        {% if "entity_keys" in policy %}
                            {% set columns = policy["entity_keys"] %}
                        {% else %}
                            {% set columns = [] %}
                        {% endif %}

                        {% set existing_policies_for_table = existing_aggrgegate_policies_for_table|selectattr('0','equalto', policy_name)|list %}
                        {% if existing_policies_for_table|length == 0 %}
                            {% do apply_policies.append({ "policy_name" : policy_name, "columns" : columns }) %}
                        {% else %}
                            {% set found_matching_existing_policy = false %}
                            {% for existing_policy in existing_policies_for_table %}
                                {% set existing_policy_columns = existing_policy[1] %}
                                {% if columns|sort == existing_policy_columns|sort %}
                                    {% set found_matching_existing_policy = true %}
                                    {% break %}
                                {% endif %}
                            {% endfor %}
                            {% if not found_matching_existing_policy %}
                                {% do apply_policies.append({ "policy_name" : policy_name, "columns" : columns }) %}
                            {% else %}
                                {% do no_change_policies.append({ "policy_name" : policy_name, "columns" : columns }) %}
                            {% endif %}
                        {% endif %}
                    {% endfor %}

                    {% for policy in existing_aggrgegate_policies_for_table %}
                        {% set policy_name = policy[0] %}
                        {% set columns = policy[1] %}
                        {% set dbt_policies = dbt_aggregation_policies|selectattr('name','equalto',policy_name)|list %}
                        {% if dbt_policies|length == 0 %}
                            {% do remove_policies.append({ "policy_name" : policy_name, "columns" : columns }) %}
                        {% else %}
                            {% for dbt_policy in dbt_policies %}
                                {% if "entity_keys" in dbt_policy %}
                                    {% set dbt_policy_columns = dbt_policy["entity_keys"] %}
                                {% else %}
                                    {% set dbt_policy_columns = [] %}
                                {% endif %}
                                {% if columns|sort != dbt_policy_columns|sort %}
                                    {% do remove_policies.append({ "policy_name" : policy_name, "columns" : columns }) %}
                                {% endif %}
                            {% endfor %}
                        {% endif %}
                    {% endfor %}
                {% endif %}

                {% for policy in remove_policies %}
                    {% set policy_name = policy["policy_name"] %}
                    {% set column_names = policy["columns"] %}
                    {{ dbt_monitorial_datagovernance.drop_aggregation_policy(materialization, model_schema, model_alias, policy_name, column_names)}}
                {% endfor %}

                {% for policy in apply_policies %}
                    {% set policy_name = policy["policy_name"] %}
                    {% set column_names = policy["columns"] %}
                    {{ dbt_monitorial_datagovernance.add_aggregation_policy(materialization, model_schema, model_alias, policy_name, column_names)}}
                {% endfor %}
            {% elif  existing_aggrgegate_policies_for_table|length == 0 %}
                {% for policy in existing_aggrgegate_policies_for_table %}
                    {% set policy_name = policy[0] %}
                    {% set columns = policy[1] %}
                    {{ dbt_monitorial_datagovernance.drop_aggregation_policy(materialization, model_schema, model_alias, policy_name, columns)}}
                {% endfor %}
            {% endif %}
        {% endif %}
    {% endif %}
{% endmacro %}