
{% macro model_meta_contains_item(item_name, model_node) %}
    {% if item_name in model_node.meta %}
        {{ return(True) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}