# openresty-statsd

A simple(crude) openresty statsd implementation using ngx.timer.at and 
ngxshared.DICT.  Other implimentations that I found were not thread safe and did
not aggregate the counts.  

### Disclaimer:

I am not a lua guy and am very green with openresty and lua.  Use at your own risk.

### nginx.conf memory allocation.

```
lua_shared_dict statsdict 1m;
lua_shared_dict statsdumper 12k;
```

### Server endpoint config
```
    location /some/endpoint {
      ...
      ...
        access_by_lua_block {
            -- TODO: This could be included into a single call
            statsd.startdumper()
            statsd.inc()
        }
```


### Statsd configuration

There really isn't much going on here.  Just the ability to change the hostname and port

statsd.host = "127.0.0.1"
statsd.port = 8125 
