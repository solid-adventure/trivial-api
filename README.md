
  

# Trivial API
RESTful Backend API for Trivial written in Ruby on Rails. 

Documentation at [trivial-js.org](https://trivial-js.org)

## Install

### STOP

First, verify that you need to configure this repository locally. Unless you are working on the API itself, most development can be done with a local copy of trivial-ui pointed at the staging API server.

If you are certain you need to set up this app, follow the instructions below.

### Clone the repository

  

```shell

git clone git@github.com:solid-adventure/trivial-api.git

cd project

```

  
  

### Check your Ruby version

  

```shell

ruby -v

```

  

The output should start with something like `ruby 3.1.2p20`

  

If not, install the right ruby version using rvm or [rbenv](https://github.com/rbenv/rbenv) (it could take a while):

  

```shell

rbenv install 3.1.2

```

### Install Postgres

Install Postgres (version 13.1)


### Set environment variables

Copy `.env.example` in the project and rename it to `.env`

Edit `username` and `password` for Postgres in `.env`

Create a new private key for signing app API tokens:

```shell
openssl genrsa 2048 | pbcopy
```

The above command creates a new key and copies it to the clipboard. Paste the copied key into `.env` for `JWT_PRIVATE_KEY`. It is a multiline value, which is legal in env files if the value is surrounded by double quotes:

```
JWT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAxG3mvjgpfKopKqG4ESlbkheXmw2Oa8QxDwJNUlTCI2Zzhzkc
...
fSwN61FgeWoGIBn4CSVgmkr8kVYUgjPv5jNvRXxHBolRqYRjNXMhsRU=
-----END RSA PRIVATE KEY-----"
```

If you need to verify an API key signature in another application (currently no other applications need this), you will need to provide them with your public key during development. You can generate the public key on the command line:

```shell
pbpaste | openssl rsa -pubout -outform PEM
```

or, perhaps more simply, from the Rails console once you have configured `JWT_PRIVATE_KEY` (launch the console with the command `bundle exec rails c`):

```ruby
puts OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY']).public_key.to_pem
```

### Install dependencies

  

Using [Bundler](https://github.com/bundler/bundler) :

  

```shell

bundle

```

  

### Initialize the database

```shell

rails db:setup

```

It will set up the databases and run migrations and seed for the project.


###  Ensure tests are passing
```shell
rake test
# Finished in 3.170946s, 10.7224 runs/s, 10.7224 assertions/s.
# 34 runs, 34 assertions, 0 failures, 0 errors, 0 skips
```

```shell
bundle exec rspec
# Finished in 4.63 seconds (files took 2.34 seconds to load)
# 112 examples, 0 failures, 101 pending
```

## Serve

  

```shell

rails s

```

## Re-generate API docs from tests

```shell
RAILS_ENV=test bundle exec rake rswag
```
