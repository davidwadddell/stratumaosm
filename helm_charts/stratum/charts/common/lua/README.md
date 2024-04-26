# HAProxy Lua Scripts

<!-- TOC -->
* [HAProxy Lua Scripts](#haproxy-lua-scripts)
  * [Base64 Decode](#base64-decode)
  * [Unit Testing](#unit-testing)
    * [Running The Tests](#running-the-tests)
<!-- TOC -->

We use the *stratum.lua* script with HAProxy to select a backend, based on the IMSI in the request URL,
or in the request body. A backend will route to a particular Stratum partition.

## Base64 Decode
We are using the Lua *mime* library to decode base64 encoded text strings. For example we may get a DELETE request as:
```shell
DELETE /nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCMjM2RDdFRDMwMUE1NzQwMTAxMDNGMDAyIiwibmZJbnN0YW5jZUlkIjpbIjAwNTgzNGRmLWI2MWMtNDM5Ni1hMmY1LWQ3N2FlOWE4NzdiZCJdLCJtb25pdG9yZWRSZXNvdXJjZVVyaXMiOlsiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktMTE2MzEwOTUyMDAyL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3RhdHVzIiwiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktMTE2MzEwOTUyMDAyL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3Vic2NyaXB0aW9uIl19
```
where the last part of the path is the base64 encoded string. We extract this string and decode as follows:
```lua
local s = mime.unb64(encoded_text)
```
This seems to be the fastest library for doing the base64 decoding. With the *mime* library we get the following benchmarks:
```shell
[brian:lua]$ lua benchmark_mime.lua
Common text
Encoding: 305642154 bytes/sec
Decoding: 375530436 bytes/sec
Common text (cache)
Encoding: 421709610 bytes/sec
Decoding: 357717760 bytes/sec
Binary
Encoding: 437483594 bytes/sec
Decoding: 367026352 bytes/sec
Binary (cache)
Encoding: 446767636 bytes/sec
Decoding: 364179321 bytes/sec
```
The other alternative (non-standard) library is the [base64](https://github.com/iskolbin/lbase64) library which yields
considerably worse benchmarks:
```shell
[brian:lua]$ lua benchmark_base64.lua 
Common text
Encoding: 7185575 bytes/sec
Decoding: 5420295 bytes/sec
Common text (cache)
Encoding: 8291853 bytes/sec
Decoding: 1894773 bytes/sec
Binary
Encoding: 5405773 bytes/sec
Decoding: 2876526 bytes/sec
Binary (cache)
Encoding: 4142577 bytes/sec
Decoding: 1172118 bytes/sec
```

## Unit Testing
We use the [LuaUnit](https://github.com/bluebird75/luaunit) test framework to unit test our HAProxy Lua scripts.
We provide two mocked interfaces to simulate the HAProxy *core* and *Txn* functions:
- mock_core.lua
- mock_txn.lua

### Running The Tests
The unit tests can be run using:
```shell
lua invalid_requests_tests.lua -v
```

