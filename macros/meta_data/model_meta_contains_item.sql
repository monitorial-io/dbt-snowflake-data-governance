
{% macro model_meta_contains_item(item_name, model_node) %}
    {% if model_node.config is defined and model_node.config.meta is defined %}
        {% set meta_data = model_node.config.meta %}
    {% else %}
        {% set meta_data = model_node.get("meta", {}) %}
    {% endif %}

    {# Check if the item exists in the model's metadata #}
    {% if meta_data and item_name in meta_data %}
        {{ return(True) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}