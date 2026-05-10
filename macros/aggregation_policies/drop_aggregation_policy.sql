{% macro drop_aggregation_policy(materialization, model_schema, model_name, policy_name, columns) %}
    {{ log("Removing aggregation policy " + policy_name + " for model " + model_schema|lower ~ "." ~ model_name|lower, info=True) }}
    {% if columns|length > 0 %}
        {%- call statement('set_statement', fetch_result=True) -%}
            alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} drop aggregation policy  {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ policy_name }} entity key ({{columns|join(',')}});
       {%- endcall -%}
    {% else %}
       {%- call statement('set_statement', fetch_result=True) -%}
            alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} drop aggregation policy  {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ policy_name }}
       {%- endcall -%}
    {% endif %}

    {% set result = load_result('set_statement')%}
    {% if result['response']|string != "SUCCESS 1" %}
        {{ log("ERROR dropping aggregation policy on model '" ~ model_name|lower ~ " ............... [" + result["response"]|string  + "]", info=True) }}
        {{ log(result.data, info=True) }}
    {% endif %}
{% endmacro %}
