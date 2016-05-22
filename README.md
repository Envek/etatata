# ETATATA

Microservice and JSON API to request an ETA of nearest vehicle calculated as [Haversine distance] in kilometers multiplied by factor of 1.5 minutes per kilometer. So, average distance to three nearest vehicles is 10 km, it will assume that one of them will arrive in 15 minutes.

## Components

### API

A Ruby application built with [Sinatra] microframework which is good for small APIs with multithreaded Puma application server. Receives coordinates, validates it and sends to service via [MessagePack RPC].


### Service

A pure Ruby application, accepts requests via MessagePack RPC, fetches required data from database, calculates answers, caches them, and returns. That's it.

Used technologies:

 - [MessagePack] — lightweight replacement for JSON.
 - [MessagePack RPC] — eliminates HTTP overhead which is huge when your payload is small. In case of common request for this service reduces request-response size from 387 bytes for HTTP (compared to API application) to 164 for [MessagePack RPC].
 - [ActiveRecord] — handles connection pooling, data transformations, input data quotations and more.
 - [ActiveSupport::Cache] — cache abstraqction, allows to change cache backends easily.

What is not implemented yet:

 - Concurrency — it's single process, single thread application that can handle only one request at a time.


### Database

[PostgreSQL] 9.5 with [PostGIS] 2.2. Open Source, very reliable, with strong guarantees of consistency, and support for a lot of data and index types.

I store a vehicle coordinates in a column of `geography` type with a GIST index over it to speed up lookups.

It allows to find nearest cars with query like:

```sql
SELECT
  ST_X(vehicles.position::geometry) AS longitude,
  ST_Y(vehicles.position::geometry) AS latitude
FROM vehicles
WHERE available = true
ORDER BY vehicles.position <-> 'POINT(37.058515 55.923175)'::geography ASC
LIMIT 3;
```

Query plan for this query over 100 000 vehicles:

```
Limit  (cost=0.28..1.66 rows=3 width=56) (actual time=15.580..15.658 rows=3 loops=1)
  ->  Index Scan using vehicles_position_idx on vehicles  (cost=0.28..22812.28 rows=49500 width=56) (actual time=15.578..15.655 rows=3 loops=1)
        Order By: ("position" <-> '0101000020E6100000A8A9656B7D8742400EBE30992AF64B40'::geography)
        Filter: available
        Rows Removed by Filter: 12
Planning time: 0.215 ms
Execution time: 15.751 ms
```

The `geography <-> geography` operator calculates distance on the sphere between given points ([see docs](http://postgis.net/docs/manual-2.2/geometry_distance_knn.html)). This is not the same as [Haversine distance] but both are algebraically equivalent (both are monotonically increasing), so we can get required number of nearest records with this function and recalculate [Haversine distance] only for them.


## Launch

### Via Docker

You will need to have installed:

 - Recent [Docker]
 - Recent [Docker Compose]

Then just execute next command from this directory:

    docker-compose up

Access API endpoint on URL like this: http://localhost:4567/?latitude=55.923175&longitude=37.858515


### Manually

You will need to have installed:

 - Recent MRI Ruby version (recommended: 2.3)
 - Recent PostgreSQL with PostGIS extension (recommended: 9.5 with 2.2)

Follow these simple steps:

 1. Create database and execute [db/setup.sql](db/setup.sql) script in it.

 2. Install required gems by executing `bundle install` in both `eta_api` and `eta_service` directories.

 3. Launch service with command like:

        cd eta_service
        env 'DATABASE_URL=postgresql://USER:PASSWORD@localhost/eta-db' ruby eta_service.rb

 4. Launch API with command like:

        cd eta_api
        ruby eta_service.rb

 5. Access API endpoint on URL like this: http://localhost:4567/?latitude=55.923175&longitude=37.858515

 6. …

 7. PROFIT!


## License

> The MIT License (MIT)
> Copyright (c) 2016 Andrey Novikov
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Haversine distance]: https://en.wikipedia.org/wiki/Haversine_formula (gedesic distance: as crow flies)
[MessagePack]: https://msgpack.org/
[MessagePack RPC]: https://github.com/msgpack-rpc/msgpack-rpc
[ActiveRecord]: https://github.com/rails/rails/tree/master/activerecord
[ActiveSupport::Cache]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
[Sinatra]: http://www.sinatrarb.com/
[PostgreSQL]: http://www.postgresql.org/
[PostGIS]: http://postgis.net/
