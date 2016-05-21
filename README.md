# ETATATA

## Launch

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
