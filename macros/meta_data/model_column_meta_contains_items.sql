
{% macro model_column_meta_contains_items(item_names, model_node) %}
    {% for column in model_node.columns %}
       {% for item_name in item_names %}
            {% if item_name in model_node.columns[column].meta %}
              {{ return(True) }}
    	    {% endif %}
       {% endfor %}
    {% endfor %}
    {{ return(False) }}
{% endmacro %}