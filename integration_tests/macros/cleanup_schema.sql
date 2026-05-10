{% macro cleanup_schema(schema_name) %}
{#
    Drops a schema by name. Used by CI to clean up test schemas.

        dbt run-operation cleanup_schema --args '{schema_name: MY_SCHEMA}'
#}
{% do run_query("DROP SCHEMA IF EXISTS " ~ target.database ~ "." ~ schema_name ~ " CASCADE") %}
{{ log("Dropped schema " ~ target.database ~ "." ~ schema_name, info=True) }}
{% endmacro %}
