{% macro is_statement_success(response) %}
    {#- Normalizes an adapter statement response before checking its status code.
        Depending on the execution environment, `response` may come through as the
        AdapterResponse object, a plain dict, or (rarely) a single-item list wrapping
        either of those -- and the `code` value can carry stray case/whitespace.
        Comparing the raw value directly against the literal "SUCCESS" string is
        brittle and can report false errors on genuinely successful statements. #}
    {%- if response is sequence and response is not string and response is not mapping and response|length > 0 -%}
        {%- set response = response[0] -%}
    {%- endif -%}
    {%- set response_code = response['code'] if response is mapping else response.code -%}
    {{ return((response_code | string | trim | upper) == "SUCCESS") }}
{% endmacro %}
