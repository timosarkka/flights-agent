{{ config(materialized='semantic_view') }}

	tables (
		DEV.MARTS.DIM_AIRCRAFT primary key (HK_AIRCRAFT) comment='The table contains records of individual aircraft and their associated attributes. Each record includes details about the aircraft''s identity and registration, manufacturer information, model and type classifications, and operational details such as the operating entity, ownership, and year of manufacture.',
		DEV.MARTS.DIM_AIRLINE primary key (HK_AIRLINE) comment='The table contains records of airlines, serving as a reference dimension. Each record represents a single airline and includes details about its identifiers, naming conventions, country of origin, and operational status.',
		DEV.MARTS.DIM_AIRPORT primary key (HK_AIRPORT) comment='The table contains records of airports from around the world. Each record represents a single airport and includes details about its geographic location, classification type, and operational characteristics such as scheduled service availability.',
		DEV.MARTS.DIM_DATE primary key (DATE_KEY) comment='The table contains a date dimension used to support time-based analysis. Each record represents a single calendar date and includes hierarchical time attributes such as year, quarter, month, week, and day, as well as descriptive labels and weekend classification.',
		DEV.MARTS.FCT_FLIGHT comment='The table contains records of individual flights, capturing key details about each flight''s journey. Each record includes information about the associated aircraft, airline, departure and arrival airports, and the flight''s duration, along with the timeframe during which the flight was observed.'
	)
	relationships (
		FCT_FLIGHT_TO_DIM_AIRCRAFT as FCT_FLIGHT(HK_AIRCRAFT) references DIM_AIRCRAFT(HK_AIRCRAFT),
		FCT_FLIGHT_TO_DIM_AIRLINE as FCT_FLIGHT(HK_AIRLINE) references DIM_AIRLINE(HK_AIRLINE),
		FCT_FLIGHT_TO_DIM_AIRPORT as FCT_FLIGHT(HK_DEPARTURE_AIRPORT) references DIM_AIRPORT(HK_AIRPORT),
		FCT_FLIGHT_TO_DIM_AIRPORT_2 as FCT_FLIGHT(HK_ARRIVAL_AIRPORT) references DIM_AIRPORT(HK_AIRPORT),
		FCT_FLIGHT_TO_DIM_DATE as FCT_FLIGHT(DATE_KEY_FIRST_SEEN) references DIM_DATE(DATE_KEY),
		FCT_FLIGHT_TO_DIM_DATE_2 as FCT_FLIGHT(DATE_KEY_LAST_SEEN) references DIM_DATE(DATE_KEY)
	)
	facts (
		DIM_AIRPORT.LATITUDE_DEG as LATITUDE_DEG comment='The latitude of the airport measured in degrees.' sample_values ('33.098732', '17.266831', '-5.364716'),
		DIM_AIRPORT.LONGITUDE_DEG as LONGITUDE_DEG comment='The longitude of the airport measured in degrees.' sample_values ('-109.18656', '31.849913', '135.534563')
	)
	dimensions (
		DIM_AIRCRAFT.BUILT_YEAR as BUILT_YEAR with synonyms=('building year','manufacturing year') comment='The year in which the aircraft was built.' sample_values ('1978', '1979', '1982'),
		DIM_AIRCRAFT.CATEGORY_DESCRIPTION as CATEGORY_DESCRIPTION comment='The description of the aircraft''s Automatic Dependent Surveillance-Broadcast emitter category.' sample_values ('(unknown)', 'Large (75000 to 300000 lbs)', 'Reserved'),
		DIM_AIRCRAFT.HK_AIRCRAFT as HK_AIRCRAFT comment='A hash key uniquely identifying each aircraft record.' sample_values ('c18d37c67c8dbe7df07c915644d150f3', 'c1837f3015cd857cad356ca9e8631bdf', 'c1890d7c3c04d4a4258cae7cbf0a0a40'),
		DIM_AIRCRAFT.ICAO_AIRCRAFT_TYPE as ICAO_AIRCRAFT_TYPE comment='The International Civil Aviation Organization (ICAO) aircraft type designator code used to classify aircraft by size and engine type.' sample_values ('H1P', 'L2J', 'L1P'),
		DIM_AIRCRAFT.ICAO24 as ICAO24 comment='The 24-bit International Civil Aviation Organization transponder address assigned to an individual aircraft for identification purposes.' sample_values ('7812000000000', 'a21d13', '44011e'),
		DIM_AIRCRAFT.MANUFACTURER_ICAO as MANUFACTURER_ICAO comment='The International Civil Aviation Organization (ICAO) designated manufacturer of the aircraft.' sample_values ('PITTS', 'RAYTHEON', 'YAKIMA AEROSPORT'),
		DIM_AIRCRAFT.MANUFACTURER_NAME as MANUFACTURER_NAME comment='The name of the aircraft manufacturer.' sample_values ('Schempp-hirth', 'Henderson Howard W', 'Saint Donald W'),
		DIM_AIRCRAFT.MODEL as MODEL with synonyms=('type') comment='The model designation of an aircraft.' sample_values ('A320-251N', 'SA3B', 'P210N'),
		DIM_AIRCRAFT.OPERATOR as OPERATOR comment='The name of the aircraft operator, which may be an airline, cargo carrier, or individual.' sample_values ('Royal Air Force', 'Spanish Air Force', 'United States Air Force'),
		DIM_AIRCRAFT.OPERATOR_CALLSIGN as OPERATOR_CALLSIGN comment='The callsign name of the aircraft operator.' sample_values ('BOMBARDIER', 'VORTEX'),
		DIM_AIRCRAFT.OPERATOR_IATA as OPERATOR_IATA comment='The International Air Transport Association (IATA) code identifying the aircraft operator or airline.' sample_values ('JA', 'ZT', '9W'),
		DIM_AIRCRAFT.OPERATOR_ICAO as OPERATOR_ICAO comment='The International Civil Aviation Organization (ICAO) code identifying the aircraft operator.' sample_values ('SHF', 'BFO', 'AWC'),
		DIM_AIRCRAFT.OWNER as OWNER comment='The name of the aircraft owner.' sample_values ('Atlantis Flight Academy Inc', 'Gable S Corp', 'Private'),
		DIM_AIRCRAFT.REGISTRATION as REGISTRATION comment='The official registration codes assigned to individual aircraft.' sample_values ('D-6495', 'N613LB', 'SP-GKM'),
		DIM_AIRCRAFT.TYPE_CODE as TYPE_CODE comment='The aircraft type code used to identify and classify the aircraft model.' sample_values ('PA31', 'B738', 'A119'),
		DIM_AIRLINE.AIRLINE_ICAO as AIRLINE_ICAO comment='The International Civil Aviation Organization (ICAO) code assigned to an airline.' sample_values ('(unknown)', 'ETL', 'ECA'),
		DIM_AIRLINE.AIRLINE_ID as AIRLINE_ID comment='Unique numeric identifier for an airline.' sample_values ('4987', '2580', '789'),
		DIM_AIRLINE.AIRLINE_NAME as AIRLINE_NAME comment='The full name of the airline.' sample_values ('United States Coast Guard Auxiliary', 'Australian Customs Service', 'Envoy Air'),
		DIM_AIRLINE.ALIAS as ALIAS comment='Alternative names or aliases used to identify airlines.' sample_values ('All America BOPY', 'Domenican'),
		DIM_AIRLINE.CALLSIGN as CALLSIGN comment='The official callsign name used to identify an airline.' sample_values ('COASTWATCH', 'VILLAVERDE', 'PRIMAC'),
		DIM_AIRLINE.COUNTRY as COUNTRY comment='The country associated with the airline.' sample_values ('India', 'Sweden', 'Uganda'),
		DIM_AIRLINE.HK_AIRLINE as HK_AIRLINE comment='The hash key uniquely identifying an airline record.' sample_values ('0909ac9561c653ed436933b96c95a92e', '07a0fbc7a79c2bcd1d1dfb71449b5ff3', '09e18a97b3c3563624916dcd2ebae1c2'),
		DIM_AIRLINE.IATA_CODE as IATA_CODE comment='The International Air Transport Association (IATA) code assigned to an airline.' sample_values ('5Y', 'M8', 'AG'),
		DIM_AIRLINE.IS_ACTIVE as IS_ACTIVE comment='Flag indicating whether the airline is currently active.' sample_values ('1', '0'),
		DIM_AIRPORT.AIRPORT_ICAO as AIRPORT_ICAO comment='The International Civil Aviation Organization (ICAO) code assigned to the airport.' sample_values ('JP-1097', 'ZA-0078', 'US-0650'),
		DIM_AIRPORT.AIRPORT_NAME as AIRPORT_NAME comment='The full name of the airport.' sample_values ('Pes Heliport', 'Black Butte North Airport', '(unknown)'),
		DIM_AIRPORT.AIRPORT_TYPE as AIRPORT_TYPE comment='The classification or category of an airport.' sample_values ('small_airport', 'heliport', '(unknown)'),
		DIM_AIRPORT.CONTINENT as CONTINENT comment='The continent in which the airport is located.' sample_values ('NA', '(unknown)', 'AS'),
		DIM_AIRPORT.ELEVATION_FT as ELEVATION_FT comment='The elevation of the airport measured in feet above sea level.' sample_values ('262', '3126', '284'),
		DIM_AIRPORT.HK_AIRPORT as HK_AIRPORT comment='A hash key uniquely identifying each airport record.' sample_values ('00030cf0c0d7dad2fc112e767438226c', '0055968fc39e8cad1551a454e938583b', '00af597de879bd641656cdb1422bb021'),
		DIM_AIRPORT.ISO_COUNTRY as ISO_COUNTRY comment='The two-letter ISO country code associated with the airport''s country of location.' sample_values ('(unknown)', 'JP', 'AR'),
		DIM_AIRPORT.ISO_REGION as ISO_REGION comment='The International Organization for Standardization (ISO) region code associated with the airport.' sample_values ('PY-7', 'US-LA', 'CL-ML'),
		DIM_AIRPORT.MUNICIPALITY as MUNICIPALITY with synonyms=('city') comment='The municipality or city associated with the airport.' sample_values ('Otaki', 'Osaka', 'Benito Juarez'),
		DIM_AIRPORT.SCHEDULED_SERVICE as SCHEDULED_SERVICE comment='Indicates whether scheduled passenger service is available at the airport.' sample_values ('no', 'yes', '(unknown)'),
		DIM_DATE.DATE_KEY as DATE_KEY comment='A numeric surrogate key that uniquely identifies a date record in the date dimension.' sample_values ('20150101', '20150103', '20150409'),
		DIM_DATE.DAY_NAME as DAY_NAME comment='Abbreviated name of the day of the week.' sample_values ('Fri', 'Thu', 'Sat'),
		DIM_DATE.DAY_OF_MONTH as DAY_OF_MONTH comment='The numeric day of the month.' sample_values ('1', '3', '2'),
		DIM_DATE.DAY_OF_WEEK as DAY_OF_WEEK comment='The numeric representation of the day of the week.' sample_values ('6', '4', '7'),
		DIM_DATE.IS_WEEKEND as IS_WEEKEND comment='Indicates whether the date falls on a weekend.' sample_values ('TRUE', 'FALSE'),
		DIM_DATE.MONTH as MONTH comment='The numeric month of the year.' sample_values ('1', '3', '2'),
		DIM_DATE.MONTH_NAME as MONTH_NAME comment='The full name of the month associated with a given date.' sample_values ('February', 'March', 'January'),
		DIM_DATE.QUARTER as QUARTER comment='The fiscal or calendar quarter of the year.' sample_values ('1', '2', '3'),
		DIM_DATE.WEEK_OF_YEAR as WEEK_OF_YEAR comment='The week number within a given year.' sample_values ('2', '8', '31'),
		DIM_DATE.YEAR as YEAR comment='The calendar year associated with a date record.' sample_values ('2017', '2015', '2016'),
		DIM_DATE.FULL_DATE as FULL_DATE comment='The full calendar date represented by a dimension record.' sample_values ('2015-01-01', '2015-03-01', '2015-07-05'),
		FCT_FLIGHT.ARRIVAL_AIRPORT_CANDIDATES as ARRIVAL_AIRPORT_CANDIDATES comment='The number of candidate airports considered for the arrival destination of a flight.' sample_values ('7', '10', '2'),
		FCT_FLIGHT.CALLSIGN as CALLSIGN comment='The unique alphanumeric identifier assigned to a flight used for air traffic control communication purposes.' sample_values ('WZZ262', 'FIN50M', 'BTI9816'),
		FCT_FLIGHT.DATE_KEY_FIRST_SEEN as DATE_KEY_FIRST_SEEN comment='The date when the flight was first observed or recorded.' sample_values ('20260823', '20260821', '20260822'),
		FCT_FLIGHT.DATE_KEY_LAST_SEEN as DATE_KEY_LAST_SEEN comment='The date key representing the last recorded sighting or observation of a flight.' sample_values ('20260821', '20260822', '20260824'),
		FCT_FLIGHT.DEPARTURE_AIRPORT_CANDIDATES as DEPARTURE_AIRPORT_CANDIDATES comment='The number of candidate airports considered for the departure location of a flight.' sample_values ('3', '2', '0'),
		FCT_FLIGHT.DURATION_HOURS as DURATION_HOURS comment='The duration of the flight measured in hours.' sample_values ('11', '15', '10'),
		FCT_FLIGHT.DURATION_MINUTES as DURATION_MINUTES comment='The duration of a flight measured in minutes.' sample_values ('59', '567', '239'),
		FCT_FLIGHT.HK_AIRCRAFT as HK_AIRCRAFT comment='A hash key used to uniquely identify an aircraft record.' sample_values ('055f62364e60149a70d928489167ce78', '55f7366868288a7750d0ea643bc0df61', '17ac8c28bdb86a3b4931cd86a56f4d2e'),
		FCT_FLIGHT.HK_AIRLINE as HK_AIRLINE comment='A hash key used to uniquely identify an airline record.' sample_values ('708d8673cb88c51c05328d287d90ec6e', '6e826297def3c86e318c4adfc6e239dc', '12f72a9d3d684dbdbae01682c5f2a26e'),
		FCT_FLIGHT.HK_ARRIVAL_AIRPORT as HK_ARRIVAL_AIRPORT comment='A hash key identifying the arrival airport.' sample_values ('f892447b8993dddc50b7c52ee155529f', 'ef0e66fc02c2dd28a1ca378967c68866', '3a7c93a76595c8c5386957c5cb105176'),
		FCT_FLIGHT.HK_DEPARTURE_AIRPORT as HK_DEPARTURE_AIRPORT comment='A hashed key representing the departure airport.' sample_values ('a28c9d4f098cd5476dcc8ca6a1af59c4', 'eadee3ed86db89e3286069422ee8f278', '7727ad9a534a677d4c2ce63ceb22de91'),
		FCT_FLIGHT.HK_FLIGHT as HK_FLIGHT comment='A hash key uniquely identifying each flight record.' sample_values ('00007ae17922a15546cb9de667b0f6ef', '0030934d2f98c0993a9f2280c543915e', '0efd1a2fe1e1979bcf0450384592819f'),
		FCT_FLIGHT.FIRST_SEEN_AT as FIRST_SEEN_AT comment='The timestamp when the flight was first observed or recorded.' sample_values ('2026-08-21T10:14:52.000Z', '2026-08-21T10:12:02.000Z', '2026-08-21T16:02:30.000Z'),
		FCT_FLIGHT.LAST_SEEN_AT as LAST_SEEN_AT comment='The timestamp indicating when the flight was last observed or recorded.' sample_values ('2026-08-21T12:04:27.000Z', '2026-08-21T14:11:51.000Z', '2026-08-21T21:09:17.000Z')
	)
	ai_sql_generation 'Round all numeric columns to 2 decimal points.

In case the result set of an aggregate query includes nulls (for example in the top 10 results), present the nulls last.'
	ai_verified_queries (
		"What flights have departed from JFK airport, and what are the details of the airlines and aircraft involved?" AS ( 
QUESTION 'What flights have departed from JFK airport, and what are the details of the airlines and aircraft involved?' 
VERIFIED_AT 1787741291
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  flight.CALLSIGN,
  flight.FIRST_SEEN_AT,
  airport.AIRPORT_NAME,
  airline.AIRLINE_NAME,
  airline.COUNTRY,
  aircraft.MODEL,
  aircraft.BUILT_YEAR,
  aircraft.MANUFACTURER_NAME
FROM
  __fct_flight AS flight
  LEFT JOIN __dim_airport AS airport 
  ON airport.HK_AIRPORT = flight.HK_DEPARTURE_AIRPORT
  LEFT JOIN __dim_airline AS airline 
  ON airline.HK_AIRLINE = flight.HK_AIRLINE
  LEFT JOIN __dim_aircraft AS aircraft 
  ON aircraft.HK_AIRCRAFT = flight.HK_AIRCRAFT
WHERE
  airport.AIRPORT_ICAO = ''KJFK'''),
		"What is the share of flights for different airlines per each day in Helsinki Vantaa airport in Finland?" AS ( 
QUESTION 'What is the share of flights for different airlines per each day in Helsinki Vantaa airport in Finland?' 
VERIFIED_AT 1787742570
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'WITH helsinki_departures AS (
  SELECT
    f.hk_flight,
    f.hk_airline,
    air.airline_name,
    f.hk_departure_airport,
    dep.airport_name,
    DATE_TRUNC(''DAY'', f.first_seen_at) AS departure_day
  FROM
    __fct_flight AS f
    LEFT JOIN __dim_airport dep 
    ON f.hk_departure_airport = dep.hk_airport
    LEFT JOIN __dim_airline air
    ON f.hk_airline = air.hk_airline
  WHERE
    dep.airport_name ILIKE ''%Helsinki%Vantaa%''
    AND dep.iso_country = ''FI''
)

SELECT 
    airline_name,
    airport_name,
    departure_day,
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY airport_name, departure_day)
        AS airline_prc_share
FROM
    helsinki_departures
    group by 1, 2, 3'),
		"How many flights have departed in total from each airport in the dataset?" AS ( 
QUESTION 'How many flights have departed in total from each airport in the dataset?' 
VERIFIED_AT 1787742775
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  dep_airport.airport_name,
  dep_airport.airport_icao,
  MIN(flight.first_seen_at) AS start_date,
  MAX(flight.first_seen_at) AS end_date,
  COUNT(flight.hk_flight) AS total_departures
FROM
  __fct_flight AS flight
  LEFT JOIN __dim_airport AS dep_airport 
  ON flight.hk_departure_airport = dep_airport.hk_airport
GROUP BY
  dep_airport.airport_name,
  dep_airport.airport_icao
ORDER BY
  total_departures DESC NULLS LAST'),
		"What are the top 10 most common aircraft models departing from London Heathrow Airport?" AS ( 
QUESTION 'What are the top 10 most common aircraft models departing from London Heathrow Airport?' 
VERIFIED_AT 1787775477
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  aircraft.model,
  COUNT(flight.hk_flight) AS total_flights
FROM
  __fct_flight AS flight
  LEFT JOIN __dim_airport AS dep_airport ON flight.hk_departure_airport = dep_airport.hk_airport
  LEFT JOIN __dim_aircraft AS aircraft ON flight.hk_aircraft = aircraft.hk_aircraft
WHERE
  dep_airport.airport_name = ''London Heathrow Airport''
GROUP BY
  aircraft.model
ORDER BY
  total_flights DESC NULLS LAST
LIMIT
  10'),
		"Which airport departures does this semantic view have data on?" AS ( 
QUESTION 'Which airport departures does this semantic view have data on?' 
VERIFIED_AT 1787775902
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  a.airport_name,
  a.airport_icao,
  a.airport_type,
  a.iso_country,
  a.municipality,
  a.continent,
  COUNT(DISTINCT f.hk_flight) AS total_flights
FROM
  __dim_airport AS a
  INNER JOIN __fct_flight AS f ON (
    a.hk_airport = f.hk_departure_airport
  )
GROUP BY
  a.airport_name,
  a.airport_icao,
  a.airport_type,
  a.iso_country,
  a.municipality,
  a.continent
HAVING
  COUNT(DISTINCT f.hk_flight) > 0
ORDER BY
  total_flights DESC NULLS LAST'),
		"What are the shortest and longest flight durations in the dataset?" AS ( 
QUESTION 'What are the shortest and longest flight durations in the dataset?' 
VERIFIED_AT 1787776407
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  MIN(f.duration_minutes) AS shortest_duration_minutes,
  MAX(f.duration_minutes) AS longest_duration_minutes,
  MIN(f.duration_hours) AS shortest_duration_hours,
  MAX(f.duration_hours) AS longest_duration_hours,
  MIN(f.first_seen_at) AS start_date,
  MAX(f.last_seen_at) AS end_date
FROM
  __fct_flight AS f'),
		"Which are the top 5 airports with the highest elevation (in meters)?" AS ( 
QUESTION 'Which are the top 5 airports with the highest elevation (in meters)?' 
VERIFIED_AT 1787777324
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  airport_name,
  airport_icao,
  iso_country,
  elevation_ft,
  elevation_ft * 0.3048 AS elevation_meters
FROM
  __dim_airport
WHERE
  NOT elevation_ft IS NULL
ORDER BY
  elevation_ft DESC NULLS LAST
LIMIT
  5'),
		"Can you present the percentage shares of airlines per country?" AS ( 
QUESTION 'Can you present the percentage shares of airlines per country?' 
VERIFIED_AT 1787777357
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  country,
  100 * ratio_to_report(count(*)) OVER () AS airline_share
FROM
  __dim_airline
GROUP BY
  country
ORDER BY
  airline_share desc'),
		"What are the most often flown routes (departure airport -> arrival airport) in this dataset? Exclude unknown airports from the query." AS ( 
QUESTION 'What are the most often flown routes (departure airport -> arrival airport) in this dataset? Exclude unknown airports from the query.' 
VERIFIED_AT 1787777714
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  dep_airport.airport_name AS departure_airport,
  dep_airport.airport_icao AS departure_airport_icao,
  arr_airport.airport_name AS arrival_airport,
  arr_airport.airport_icao AS arrival_airport_icao,
  COUNT(flight.hk_flight) AS total_flights
FROM
  __fct_flight AS flight
  LEFT JOIN __dim_airport AS dep_airport ON flight.hk_departure_airport = dep_airport.hk_airport
  LEFT JOIN __dim_airport AS arr_airport ON flight.hk_arrival_airport = arr_airport.hk_airport
WHERE
  dep_airport.airport_name <> ''(unknown)''
  AND arr_airport.airport_name <> ''(unknown)''
  AND NOT dep_airport.airport_name IS NULL
  AND NOT arr_airport.airport_name IS NULL
GROUP BY
  dep_airport.airport_name,
  dep_airport.airport_icao,
  arr_airport.airport_name,
  arr_airport.airport_icao
ORDER BY
  total_flights DESC NULLS LAST'),
		"Which airlines have the longest average flight duration?" AS ( 
QUESTION 'Which airlines have the longest average flight duration?' 
VERIFIED_AT 1787777812
VERIFIED_BY 'Timo Särkkä'
ONBOARDING_QUESTION false
SQL 'SELECT
  airline.airline_name,
  airline.airline_icao,
  MIN(flight.first_seen_at) AS start_date,
  MAX(flight.first_seen_at) AS end_date,
  AVG(flight.duration_minutes) AS avg_duration_minutes
FROM
  __fct_flight AS flight
  LEFT JOIN __dim_airline AS airline ON airline.hk_airline = flight.hk_airline
GROUP BY
  airline.airline_name,
  airline.airline_icao
ORDER BY
  avg_duration_minutes DESC NULLS LAST')
	)
	with extension (
		CA='{
			"tables":[
				{
					"name":"DIM_AIRCRAFT",
					"dimensions":[
						{"name":"BUILT_YEAR"},
						{"name":"CATEGORY_DESCRIPTION"},
						{"name":"HK_AIRCRAFT"},
						{"name":"ICAO_AIRCRAFT_TYPE"},
						{"name":"ICAO24"},
						{"name":"MANUFACTURER_ICAO"},
						{"name":"MANUFACTURER_NAME"},
						{"name":"MODEL"},
						{"name":"OPERATOR"},
						{"name":"OPERATOR_CALLSIGN"},
						{"name":"OPERATOR_IATA"},
						{"name":"OPERATOR_ICAO"},
						{"name":"OWNER"},
						{"name":"REGISTRATION"},
						{"name":"TYPE_CODE"}
					]
				},
				{
					"name":"DIM_AIRLINE",
					"dimensions":[
						{"name":"AIRLINE_ICAO"},
						{"name":"AIRLINE_ID"},
						{"name":"AIRLINE_NAME"},
						{"name":"ALIAS"},
						{"name":"CALLSIGN"},
						{"name":"COUNTRY"},
						{"name":"HK_AIRLINE"},
						{"name":"IATA_CODE"},
						{"name":"IS_ACTIVE"}
					]
				},
				{
					"name":"DIM_AIRPORT",
					"dimensions":[
						{"name":"AIRPORT_ICAO"},
						{"name":"AIRPORT_NAME"},
						{"name":"AIRPORT_TYPE"},
						{"name":"CONTINENT"},
						{"name":"ELEVATION_FT"},
						{"name":"HK_AIRPORT"},
						{"name":"ISO_COUNTRY"},
						{"name":"ISO_REGION"},
						{"name":"MUNICIPALITY"},
						{"name":"SCHEDULED_SERVICE"}
					],
					"facts":[{"name":"LATITUDE_DEG"},{"name":"LONGITUDE_DEG"}]
				},
				{
					"name":"DIM_DATE",
					"dimensions":[
						{"name":"DATE_KEY"},
						{"name":"DAY_NAME"},
						{"name":"DAY_OF_MONTH"},
						{"name":"DAY_OF_WEEK"},
						{"name":"IS_WEEKEND"},
						{"name":"MONTH"},
						{"name":"MONTH_NAME"},
						{"name":"QUARTER"},
						{"name":"WEEK_OF_YEAR"},
						{"name":"YEAR"}
					],
					"time_dimensions":[{"name":"FULL_DATE"}]
				},
				{
					"name":"FCT_FLIGHT",
					"dimensions":[
						{"name":"ARRIVAL_AIRPORT_CANDIDATES"},
						{"name":"CALLSIGN"},
						{"name":"DATE_KEY_FIRST_SEEN"},
						{"name":"DATE_KEY_LAST_SEEN"},
						{"name":"DEPARTURE_AIRPORT_CANDIDATES"},
						{"name":"DURATION_HOURS"},
						{"name":"DURATION_MINUTES"},
						{"name":"HK_AIRCRAFT"},
						{"name":"HK_AIRLINE"},
						{"name":"HK_ARRIVAL_AIRPORT"},
						{"name":"HK_DEPARTURE_AIRPORT"},
						{"name":"HK_FLIGHT"}
					],
					"time_dimensions":[{"name":"FIRST_SEEN_AT"},{"name":"LAST_SEEN_AT"}]
				}
			],
			"relationships":[
				{
					"name":"FCT_FLIGHT_TO_DIM_AIRCRAFT",
					"relationship_type":"many_to_one",
					"join_type":"left_outer"
				},
				{
					"name":"FCT_FLIGHT_TO_DIM_AIRLINE",
					"relationship_type":"many_to_one",
					"join_type":"left_outer"
				},
				{
					"name":"FCT_FLIGHT_TO_DIM_AIRPORT",
					"relationship_type":"many_to_one",
					"join_type":"left_outer"
				},
				{"name":"FCT_FLIGHT_TO_DIM_AIRPORT_2"},
				{"name":"FCT_FLIGHT_TO_DIM_DATE"},
				{"name":"FCT_FLIGHT_TO_DIM_DATE_2"}
			]
		}'
	);