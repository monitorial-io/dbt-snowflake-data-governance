{% macro drop_row_access_policy(materialization, model_schema, model_name, policy_name) %}
    {{ log("Removing row access policy " ~ policy_name ~ " for model " ~ model_schema|lower ~ "." ~ model_name|lower, info=True) }}
    {%- call statement('set_statement', fetch_result=True) -%}
        alter {{materialization}} {{model_schema|upper}}.{{model_name|upper}} drop row access policy {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ policy_name }};
    {%- endcall -%}
    {% set result = load_result('set_statement')%}
    {% if result['response']|string != "SUCCESS 1" %}
        {{ log("ERROR dropping row access policy on model '" ~ model_name|lower ~ " ............... [" + result["response"]|string  + "]", info=True) }}
        {{ log(result.data, info=True) }}
    {% endif %}
{% endmacro %}