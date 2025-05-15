{% macro apply_tags(tag_names) %}
    {% if execute %}
        {% set materialization_map = {"table": "table", "view": "view", "incremental": "table", "snapshot": "table", "immutable_table" : "table", "materialized_view" : "view"} %}
        {% if dbt_monitorial_datagovernance.model_column_meta_contains_items(tag_names, model) %}
            {{ log("Applying tags for model " + model_schema|lower ~ "." ~ model_alias|lower, info=True) }}
            {% set tag_names_str = tag_names | join(', ') %}
            {%- set model_database = model.database -%}
            {%- set model_schema =  model.schema|upper -%}
            {%- set model_schema_full = model_database|upper + '.' + model_schema -%}
            {%- set model_alias = model.alias|upper -%}
            {%- set materialization = materialization_map[model.config.get("materialized")] -%}
            {%- call statement('main', fetch_result=True) -%}
                select
                    LEVEL,OBJECT_NAME,COLUMN_NAME,UPPER(TAG_NAME) as TAG_NAME,TAG_VALUE
                from table(information_schema.tag_references_all_columns('{{model_schema_full}}.{{model_alias}}', 'table'))
            {%- endcall -%}
            {%- set existing_tags_for_table = load_result('main')['data'] -%}
            {% for column in model.columns %}
                {% for column_tag in model.columns[column].meta %}
                    {% if column_tag in tag_names %}
                        {% set desired_tag_value = model.columns[column].meta[column_tag] %}
                        {{ dbt_monitorial_datagovernance.set_column_tag_value(materialization, model_schema, model_alias|upper,column|upper,column_tag,desired_tag_value, existing_tags_for_table)}}
                    {% endif %}
                {% endfor %}
            {% endfor %}
        {% endif %}
    {% endif %}
{% endmacro %}