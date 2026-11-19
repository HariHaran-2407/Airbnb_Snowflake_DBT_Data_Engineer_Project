CREATE  FILE FORMAT IF NOT EXISTS csv_format
  TYPE = 'CSV' 
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

SHOW FILE FORMATS;

CREATE OR REPLACE STAGE snowstage
  FILE_FORMAT = csv_format
  URL='S3-Bucket';
    
SHOW stages;

COPY INTO HOSTS
 FRoM @snowstage
 FILES=('hosts.csv')
 CREDENTIALS=(aws_key_id = 'KEY', aws_secret_key = 'KEY');

COPY INTO LISTINGS
 FRoM @snowstage
 FILES=('listings.csv')
 CREDENTIALS=(aws_key_id = 'KEY', aws_secret_key = 'KEY');

COPY INTO BOOKINGS
 FRoM @snowstage
 FILES=('bookings.csv')
 CREDENTIALS=(aws_key_id = 'KEY', aws_secret_key = 'KEY');

select * from bookings;
select * from listings;
select * from hosts;