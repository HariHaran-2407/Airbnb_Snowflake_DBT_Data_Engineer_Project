{{ config(materialized='ephemeral') }}

with bookings as(
    SELECT 
        booking_id,
        booking_date,
        booking_status,
        created_at     
    from    
        {{ref('obt')}}
)
select * from bookings