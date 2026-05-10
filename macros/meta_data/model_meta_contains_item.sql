
{% macro model_meta_contains_item(item_name, model_node) %}
    {% set meta_data = model_node.config.get("meta", {}) if model_node.config is defined else {} %}
    {% if not meta_data %}
        {% set meta_data = model_node.get("meta", {}) %}
    {% endif %}

    {# Check if the item exists in the model's metadata #}
    {% if meta_data and item_name in meta_data %}
        {{ return(True) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}