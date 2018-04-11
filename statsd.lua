local _M = {}


local function is_empty(s)
    return s == nil or s == ""
end

_M.host = "127.0.0.1"
_M.port = 8125

local function sendit(key, cnt)
   local sock = ngx.socket.udp()
   local ok, err = sock:setpeername(_M.host, _M.port)
   if not ok then
      ngx.log(ngx.ERR, "failed to connect to statsd: ", err)
   end
   local suc, err = sock:send(key..":".. cnt .."|c")
   if is_empty(suc) then
      ngx.log(ngx.ERR,  err)
   end
   sock:close()
end

local function dumpkeys()
   ngx.sleep(5)
   keys, err = ngx.shared.statsdict:get_keys(1024)
   if is_empty(keys) then
      ngx.log(ngx.ERR, err)
   else
      for i, k in ipairs(keys) do
         local v, _ = ngx.shared.statsdict:get(k)
         if v > 0 then
            sendit(k,v)
         end
         local n, err = ngx.shared.statsdict:incr(k, (-1*v))
         if is_empty(n) then
            ngx.log(ngx.ERR,  err)
         end
      end
   end
   -- This is done to make sure there isn't an integer overflow 
   local ok, err = ngx.shared.statsdumper:set("dumper", 1)
   if not ok then
      ngx.log(ngx.ERR,  err)
   end
   ngx.timer.at(0, dumpkeys)
end

function _M.inc()
   -- Need to split this into parts for addition to the shared dictionary
   -- 'GET /some/endpoint' turnes into get.some.endpoint:32|c for statsd. 
   local uri = string.lower(ngx.req.get_method()) .. string.gsub(string.gsub(ngx.var.request_uri, "/", "."), "?.*", "")
   local v, err = ngx.shared.statsdict:incr(uri, 1, 0)
   if is_empty(v) then
      ngx.log(ngx.ERR,  err)
   end
end

function _M.startdumper()
   -- This could become an issue due to integer overflow.  Revisit
   local v, err = ngx.shared.statsdumper:incr("dumper", 1, 0)
   if is_empty(v) then
      ngx.log(ngx.ERR,  err)
   end
   if v == 1 then
      ngx.timer.at(0, dumpkeys)
   end
end

return _M
