
{% macro model_meta_contains_item(item_name, model_node) %}
    {% if dbt_monitorial_datagovernance.get_model_meta_item(item_name, model_node) is not none %}
        {{ return(True) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}

{% macro get_model_meta_item(item_name, model_node) %}
    {# Check config.meta first (primary/fusion approach) #}
    {% set meta_data = model_node.config.get("meta", {}) if model_node.config is defined else {} %}
    {% if not meta_data %}
        {% set meta_data = model_node.get("meta", {}) %}
    {% endif %}

    {% if meta_data and item_name in meta_data %}
        {{ return(meta_data[item_name]) }}
    {% endif %}

    {# Fall back to top-level config (dbt-snowflake 2.0+ pattern) #}
    {% if model_node.config is defined and model_node.config.get(item_name) is not none %}
        {{ return(model_node.config.get(item_name)) }}
    {% endif %}

    {{ return(none) }}
{% endmacro %}