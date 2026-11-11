{% macro set_column_tag_value(materialization, model_schema, model_name, column_name, tag_name, desired_tag_value, existing_tags_for_table) %}
    {% if tag_name|lower in ["pii_type", "confidentiality_type", "semantic_type"] %}
        {%set tag_name=tag_name|replace("_type", "_classification") %}
    {% elif tag_name == "confidential_type" %}
        {%set tag_name="confidentiality_classification" %}
    {% elif tag_name == "default_mask" %}
        {%set tag_name="default_mask_value" %}
    {% endif %}
    {%- set current_tag_database = var("data_governance_database")|upper -%}
    {%- set current_tag_schema = var("tag_store")|upper -%}
    {%- set all_tag_entries_for_column = existing_tags_for_table|selectattr('0','equalto','COLUMN')|selectattr('1','equalto',model_name|upper)|selectattr('2','equalto',column_name|upper)|selectattr('3','equalto',tag_name|upper)|list -%}

    {# Remove tags with the same name left behind in a previous governance database/schema #}
    {% for stale_tag in all_tag_entries_for_column %}
        {% if stale_tag[5] != current_tag_database or stale_tag[6] != current_tag_schema %}
            {%- call statement('unset_stale_statement', fetch_result=True) -%}
                alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} modify column {{column_name}} unset tag {{stale_tag[5]}}.{{stale_tag[6]}}.{{tag_name|upper}}
            {%- endcall -%}
            {% set stale_result = load_result('unset_stale_statement')%}
            {% if stale_result['response']['code'] != "SUCCESS" %}
                {{ log("ERROR removing stale tag " ~ tag_name ~ " from " ~ stale_tag[5] ~ "." ~ stale_tag[6] ~ " on column '" ~ column_name|lower ~ "' for " ~ materialization|lower ~ " model " ~  model_schema|lower ~ "." ~ model_name|lower ~ " ............... [" ~ stale_result["response"]|string  ~ "]", info=True) }}
                {{ log(stale_result.data, info=True) }}
            {% else %}
                {{ log(column_name ~ ' ==> removed stale tag ' ~ tag_name ~ ' from previous governance location ' ~ stale_tag[5] ~ '.' ~ stale_tag[6] ~ ' ............... [SUCCESS]', info=True) }}
            {% endif %}
        {% endif %}
    {% endfor %}

    {%- set existing_tag_for_column = all_tag_entries_for_column|selectattr('5','equalto',current_tag_database)|selectattr('6','equalto',current_tag_schema)|list -%}
    {% if existing_tag_for_column|length > 0 and existing_tag_for_column[0][4]==desired_tag_value %}
        {{ log(column_name ~ ' ==> tag ' ~ tag_name ~ ' already set to value ' ~ desired_tag_value ~ ' ............... [IGNORE]', info=True) }}
    {% elif existing_tag_for_column|length > 0 and desired_tag_value|lower=="none" %}
        {%- call statement('unset_statement', fetch_result=True) -%}
            alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} modify column {{column_name}} unset tag {{ var("data_governance_database") }}.{{ var("tag_store") }}.{{tag_name|upper}}
        {%- endcall -%}
        {% set result = load_result('unset_statement')%}
        {% if result['response']['code'] != "SUCCESS" %}
            {{ log("ERROR removing tag " ~ tag_name ~ " from column '" ~ column_name|lower ~ "' for " ~ materialization|lower ~ " model " ~  model_schema|lower ~ "." ~ model_name|lower ~ " ............... [" ~ result["response"]|string  ~ "]", info=True) }}
            {{ log(result.data, info=True) }}
        {% endif %}
    {% elif desired_tag_value|lower not in ["public", "none"] %}
        {%- call statement('set_statement', fetch_result=True) -%}
            alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} modify column {{column_name}} set tag {{ var("data_governance_database") }}.{{ var("tag_store") }}.{{tag_name|upper}} = '{{desired_tag_value}}'
        {%- endcall -%}
        {% set result = load_result('set_statement')%}
        {% if result['response']['code'] != "SUCCESS" %}
            {{ log("ERROR setting tag " ~ tag_name ~ " on column '" ~ column_name|lower ~ "' to value' " ~ desired_tag_value ~ "' for " ~ materialization|lower ~ " model " ~  model_schema|lower ~ "." ~ model_name|lower ~ " ............... [" ~ result["response"]|string  ~ "]", info=True) }}
            {{ log(result.data, info=True) }}
        {% endif %}
    {% endif %}
{% endmacro %}
