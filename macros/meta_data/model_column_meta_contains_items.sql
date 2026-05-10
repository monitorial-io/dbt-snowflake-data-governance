
{% macro model_column_meta_contains_items(item_names, model_node) %}
    {% for column in model_node.columns %}
       {% for item_name in item_names %}
            {% if model_node.columns[column].config is defined and model_node.columns[column].config.meta is defined %}
                {% set column_metadata = model_node.columns[column].config.meta %}
            {% else %}
                {% set column_metadata = model_node.columns[column].get("meta", {}) %}
            {% endif %}
            {% if column_metadata and item_name in column_metadata %}
              {{ return(True) }}
          {% endif %}
       {% endfor %}
    {% endfor %}
    {{ return(False) }}
{% endmacro %}