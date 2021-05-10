
  

# Trivial API

  

This is the Rails back-end for Trivial. 

### Postman Collection
https://gist.github.com/vgkids/2e75b84e0559ed0dcb51f2717f31889c
  
### Documentation
https://trivial-api-staging.herokuapp.com/api-docs/index.html


## Install

  

### Clone the repository

  

```shell

git clone git@github.com:solid-adventure/trivial-api.git

cd project

```

  
  

### Check your Ruby version

  

```shell

ruby -v

```

  

The ouput should start with something like `ruby 2.6.3p62`

  

If not, install the right ruby version using [rbenv](https://github.com/rbenv/rbenv) (it could take a while):

  

```shell

rbenv install 2.6.3

```

### Install Postgres

Install Postgres (version 13.1)


### Set environment variables

Copy `.env.example` in the project and rename it to `.env`

Edit `username` and `password` for Postgres in `.env`

  
  

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
  

## Serve

  

```shell

rails s

```
