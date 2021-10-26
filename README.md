
  

# Trivial API

  

This is the Rails back-end for Trivial. 

### Postman Collection
https://gist.github.com/vgkids/2e75b84e0559ed0dcb51f2717f31889c
  
### Documentation
https://trivial-api-staging.herokuapp.com/api-docs/index.html


## Install

### STOP

First, verify that you need to configure this repository locally. Most development can be done with a local copy of lupin pointed at the staging API server. You should only need to install this Rails application if you will be making changes to the API itself.

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

  

The output should start with something like `ruby 2.6.3p62`

  

If not, install the right ruby version using [rbenv](https://github.com/rbenv/rbenv) (it could take a while):

  

```shell

rbenv install 2.6.3

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

You will then need to update lupin to use your public key instead of the public key for staging. You can generate the public key on the command line:

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
