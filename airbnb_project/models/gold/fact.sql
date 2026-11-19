{% set configs=[
    {
        "table":'AIRBNB.GOLD.OBT',
        "columns": "gold_obt.booking_id, gold_obt.listing_id, gold_obt.host_id, gold_obt.total_booking_amount, gold_obt.SERVICE_FEE, gold_obt.CLEANING_FEE, gold_obt.ACCOMMODATES, gold_obt.BEDROOMS, gold_obt.BATHROOMS, gold_obt.PRICE_PER_NIGHT, gold_obt.RESPONSE_RATE",
        "alias": "gold_obt"
    },
    {
        "table":'AIRBNB.GOLD.DIM_LISTINGS',
        "columns": "",
        "alias": "DIM_LISTINGS",
        "join_condition": "gold_obt.listing_id = DIM_LISTINGS.listing_id"
    },
    {
        "table":'AIRBNB.GOLD.DIM_HOSTS',
        "columns": "",
        "alias": "DIM_HOSTINGS",
        "join_condition": "gold_obt.host_id = DIM_HOSTINGS.host_id"
    }
] %}

SELECT 
    {{ configs[0]['columns'] }}  
from
    {% for config in configs %}
        {% if loop.first %}
            {{ config['table'] }} as {{ config['alias'] }}
        {% else %}
            LEFT JOIN {{ config['table'] }} as {{ config['alias'] }}
            on {{ config['join_condition']}}
        {%endif%}
    {%endfor%}