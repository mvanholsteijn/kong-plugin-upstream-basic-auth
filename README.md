#Kong plugin upstream-basic-auth

This repository contains a Kong plugin to insert a basic authentication header
to the upstream for authenticated consumers.


## Configuration
Configuring the plugin is straightforward, you can add it on top of an API by executing the following request on your Kong server:

```
curl -X POST http://kong:8001/apis/{api}/plugins \
    --data "name=upstream-basic-auth" 
```

There are no configuration parameters for this plugin.



### Example
To use this plugin, create an API with some form of authentication:
```
curl -X POST http://kong:8001/apis \
    --data name=headers-api  \
    --data uris=/headers  \
    --data strip_uri=false \
    --data upstream_url=https://httpbin.org

curl -X POST http://kong:8001/apis/headers-api/plugins \
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
curl -X POST http://kong:8001/apis/headers-api/plugins \
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
curl --user aladdin:open-sesame http://kong:8001/headers

```


This template was designed to work with the `kong-vagrant` 
[development environment](https://github.com/Mashape/kong-vagrant). Please
checkout that repos `readme` for usage instructions.
