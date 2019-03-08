# Kong plugin upstream-basic-auth

This repository contains a Kong plugin to insert a different basic authentication header per consumer
to the upstream service. This plugin requires that a consumer is identified with the request.


## Configuration
Configuring the plugin is straightforward, you can add it on top of an API by executing the following request on your Kong server:
```
curl -X POST http://kong:8001/routes/{route}/plugins \
    --data "name=upstream-basic-auth" 
```

There are no configuration parameters for this plugin.



### Example
To use this plugin, create an API with some form of authentication:
```
curl -i -X POST \
    --url http://kong:8001/services/ \
    --data 'name=headers-service' \
    --data 'url=http://mockbin.org'

curl -i -X POST \
    --url http://kong:8001/services/headers-service/routes \
    --data 'name=headers-route' \
    --data 'paths[]=/headers' \
    --data 'strip_path=false'

curl -X POST http://kong:8001/services/headers-service/plugins \
    --data name=basic-auth \
    --data config.hide_credentials=true
```

And a consumer:
```
curl http://kong:8001/consumers/ \
	--data username=aladdin

curl -X POST http://kong:8001/consumers/aladdin/basic-auth \
    --data username=aladdin \
    --data password=open-sesame
```

Now we can call the service:
```
curl --user aladdin:open-sesame http://kong:8000/headers
```

Now we can add the upstream basic authentication plugin:
```
curl -X POST http://kong:8001/routes/headers-route/plugins \
	--data name=upstream-basic-auth 
```

and add the credential to the consumer aladdin that we would like to pass to the upstream service:
```
curl -X POST http://kong:8001/consumers/aladdin/upstream-basic-auth \
    --data username=genie \
    --data password=of-the-lamp
```

Now you can call the service:
```
curl --user aladdin:open-sesame http://kong:8000/headers
```

## Installation
To install the plugin, type:
```
luarocks install kong-plugin-upstream-basic-auth
```
And add the custom plugin to the `kong.conf` file (e.g. `/etc/kong/kong.conf`)
```
custom_plugins = upstream-basic-auth
```
Create the required database tables, by running:
```
kong stop
kong migrations up
kong start
```

## Compatibility matrix

The following matrix lists compatible versions of `Kong` and `upstream-basic-auth` plugin:

| upstream-basic-auth      | 0.1.x              | 0.2.x              |
|--------------------------|:------------------:|:------------------:|
| Kong 0.14.x              | :white_check_mark: | :x:                |
| Kong 1.0.x               | :x:                | :white_check_mark: |

## Release history

0.2.1

* Fixed performance regression introduced in `v0.2.0`

0.2.0

* Added compatibility with `Kong 1.0.x`
* Added tests against `Cassandra` backend
* Dropped compatibility with `Kong 0.x`
* Dropped support for `username` as an alternative to entity `id` in `/consumers/:consumers/upstream-basic-auth/:upstreambasicauth_credentials` APIs
  * Those operation were error-prone since `username` is not unique
* Performance regression in the `Load upstream-basic-auth Credentials by Consumer ID` operation
  caused by limitations of the new `Kong DAO framework`
  * Caching is still in place, however occasional DB Query is no longer an index lookup but rather a sequential scan
  * This is a temporary situation until `Kong DAO framework` is improved
  * There is also an option to bring performance back 
    by introducing a synthetic `cache_key` field similarly to `plugins` entity
* Updated [Example](#example) section to use `Service` and `Routes` objects instead of `APIs`

0.1.0

* Initial release
* Compatible with `Kong 0.14.x` 
