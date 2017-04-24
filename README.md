## Simple Adafruit IO Client App

Should run on Heroku, as is.

This is a very very barebones example of a custom web app using the Adafruit IO Ruby client, Sinatra, and a smidgen of jQuery to exchange data with Adafruit IO.

NOTE: If you build a site like this and open it to the public, you'll probably exceed your API limit pretty quick :D

### Sign up for Adafruit IO

https://io.adafruit.com/

### Get code

    $ git clone https://github.com/abachman/adafruit-io-shared-client.git
    $ cd adafruit-io-shared-client

### Start up on Heroku

https://www.heroku.com/

    $ heroku create
    $ heroku config:add IO_USERNAME=yourusername
    $ heroku config:add IO_KEY=yourkey
    $ git push heroku master

