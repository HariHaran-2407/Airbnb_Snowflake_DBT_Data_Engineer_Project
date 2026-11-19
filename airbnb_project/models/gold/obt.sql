{% set configs=[
    {
        "table":'AIRBNB.silver.silver_BOOKINGS',
        "columns": "silver_bookings.*",
        "alias": "silver_bookings"
    },
    {
        "table":'AIRBNB.silver.silver_LISTINGS',
        "columns": "silver_listings.HOST_ID, silver_listings.property_type, silver_listings.room_type, silver_listings.city, silver_listings.COUNTRY, silver_listings.ACCOMMODATES, silver_listings.BEDROOMS, silver_listings.BATHROOMS, silver_listings.PRICE_PER_NIGHT, silver_listings.PRICE_PER_NIGHT_TAG, silver_listings.CREATED_AT As LISTINGS_CREATED_AT",
        "alias": "silver_listings",
        "join_condition": "silver_bookings.listing_id = silver_listings.listing_id"
    },
    {
        "table":'AIRBNB.silver.silver_HOSTS',
        "columns": "silver_hosts.HOST_NAME, silver_hosts.HOST_SINCE, silver_hosts.IS_SUPERHOST, silver_hosts.RESPONSE_RATE, silver_hosts.RESPONSE_RATE_QUALITY, silver_hosts.CREATED_AT as HOST_CREATED_AT",
        "alias": "silver_hosts",
        "join_condition": "silver_listings.host_id = silver_hosts.host_id"
    }
] %}

SELECT 
    {% for config in configs %}
        {{ config['columns'] }} {% if not loop.last %} , {%endif%}
    {% endfor %}
from
    {% for config in configs %}
        {% if loop.first %}
            {{ config['table'] }} as {{ config['alias'] }}
        {% else %}
            LEFT JOIN {{ config['table'] }} as {{ config['alias'] }}
            on {{ config['join_condition']}}
        {%endif%}
    {%endfor%}