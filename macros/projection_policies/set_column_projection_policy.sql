{% macro set_column_projection_policy(materlization, model_schema, model_name, column_name, projection_policy_name) %}
    {%- call statement('set_statement', fetch_result=True) -%}
        alter {{materlization}} {{model_schema|upper}}.{{model_name|upper}} modify column {{column_name}} set projection policy {{ var("data_governance_database") }}.{{ var("policy_store") }}.{{ projection_policy_name }} force;
    {%- endcall -%}
    {% set result = load_result('set_statement')%}
    {% if result['response']|string != "SUCCESS 1" %}
        {{ log("ERROR setting projection policy " ~ projection_policy_name ~ " on column '" ~ column_name|lower ~ " ............... [" + result["response"]|string  + "]", info=True) }}
        {{ log(result.data, info=True) }}
    {% endif %}
{% endmacro %}