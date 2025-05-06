{% macro add_aggregation_policy(materlization, model_schema, model_name, column_name, policy_name, columns) %}
    {{ log("Adding aggregation policy " + policy_name + " for model " + model_schema|lower ~ "." ~ model_alias|lower, info=True) }}
    {% if columns|length > 0 %}
        {%- call statement('set_statement', fetch_result=True) -%}
            alter {{materlization}} {{model_schema|upper}}.{{model_name|upper}} add aggregation policy  {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ policy_name }} {{column_name}} entity key ({{columns|join(',')}});
       {%- endcall -%}
    {% else %}
       {%- call statement('set_statement', fetch_result=True) -%}
            alter {{materlization}} {{model_schema|upper}}.{{model_name|upper}} add aggregation policy  {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ policy_name }} {{column_name}}
       {%- endcall -%}
    {% endif %}

    {% set result = load_result('set_statement')%}
    {% if result['response']|string != "SUCCESS 1" %}
        {{ log("ERROR adding aggregation policy on model '" ~ model_name|lower ~ " ............... [" + result["response"]|string  + "]", info=True) }}
        {{ log(result.data, info=True) }}
    {% endif %}
{% endmacro %}