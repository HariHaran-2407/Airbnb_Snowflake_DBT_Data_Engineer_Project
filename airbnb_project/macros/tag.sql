{% macro tag(col) %}
   case 
        when {{col}} < 100 then 'low'
        when {{col}} < 200 then 'medium'
        else 'high'
    END
{% endmacro %}