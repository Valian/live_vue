cowboy_telemetry
=====

[![Hex.pm Version](https://img.shields.io/hexpm/v/cowboy_telemetry.svg)](https://hex.pm/packages/cowboy_telemetry)
[![Erlang CI](https://github.com/beam-telemetry/cowboy_telemetry/workflows/Erlang%20CI/badge.svg?branch=main)](https://github.com/beam-telemetry/cowboy_telemetry/actions)

[Telemetry](https://github.com/beam-telemetry/telemetry) instrumentation for the [Cowboy](https://github.com/ninenines/cowboy) HTTP server.

This package contains a [`cowboy_stream`](https://ninenines.eu/docs/en/cowboy/2.8/manual/cowboy_stream/) handler that will instrument each request and emit `telemetry` events.

## Usage

Configure your cowboy server with the `cowboy_telemetry_h` stream handler first.

```erlang
cowboy:start_clear(http, [{port, Port}], #{
    env => #{dispatch => Dispatch},
    stream_handlers => [cowboy_telemetry_h, cowboy_stream_h]
}.
```

## Telemetry Events

#### `[cowboy, request, start]`

A span event emitted at the beginning of a request.

* `measurements`: `#{system_time => erlang:system_time()}`
* `metadata`: `#{stream_id => cowboy_stream:streamid(), req => cowboy_req:req()}`

#### `[cowboy, request, stop]`

A span event emitted at the end of a request.

* `measurements`: `measurements()`
* `metadata`: `metadata()`

If the request is terminated early - by the client or by the server - before a response is sent, the metadata will also contain an `error`:

* `metadata`: `metadata()` + `#{error => cowboy_stream:reason()}`

#### `[cowboy, request, exception]`

A span event emitted if the request process exits.

* `measurements`: `measurements()`
* `metadata`: `metadata()` + `#{kind => exit, stacktrace => list()}`

#### `[cowboy, request, early_error]`

A single event emitted when Cowboy itself returns an `early_error` response before executing any handlers.

* `measurements`: `#{system_time => erlang:system_time(), resp_body_length => non_neg_integer()}`
* `metadata`: `metadata()` without `procs` or `informational`

### Types

* `measurements()`:
  * `duration :: req_start - req_end` see [`cowboy_metrics_h`](https://github.com/ninenines/cowboy/blob/master/src/cowboy_metrics_h.erl#L75)
  * `req_body_duration :: req_body_start - req_body_end` see [`cowboy_metrics_h`](https://github.com/ninenines/cowboy/blob/master/src/cowboy_metrics_h.erl#L80)
  * `resp_duration :: resp_start - resp_end` see [`cowboy_metrics_h`](https://github.com/ninenines/cowboy/blob/master/src/cowboy_metrics_h.erl#L87)
  * `req_body_length :: non_neg_integer()`
  * `resp_body_length :: non_neg_integer()`
* `metadata()`:
  * `pid`, `streamid`, `req`, `resp_headers`, `resp_status`, and `ref` from `cowboy_metrics_h:metrics()`
* `cowboy_metrics_h:metrics()`: Defined in [`cowboy_metrics_h`](https://github.com/ninenines/cowboy/blob/master/src/cowboy_metrics_h.erl#L46)

Note:

* The `telemetry` handlers are executed from the cowboy connection process, not from the request process.
