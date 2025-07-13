
{% macro model_column_meta_contains_items(item_names, model_node) %}
    {% for column in model_node.columns %}
       {% for item_name in item_names %}
            {% set column_metadata = model_node.columns[column].get("config", {}).get("meta") %}
            {% if not column_metadata %}
                  {% set column_metadata = model_node.columns[column].get("meta", {}) %}
            {% endif %}
            {% if item_name in column_metadata %}
              {{ return(True) }}
    	    {% endif %}
       {% endfor %}
    {% endfor %}
    {{ return(False) }}
{% endmacro %}