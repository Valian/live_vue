-module(cowboy_telemetry_h).
-behavior(cowboy_stream).

-export([init/3]).
-export([data/4]).
-export([info/3]).
-export([terminate/3]).
-export([early_error/5]).

init(StreamID, Req, Opts) ->
    telemetry:execute(
        [cowboy, request, start],
        #{system_time => erlang:system_time()},
        #{streamid => StreamID, req => Req}),
    cowboy_metrics_h:init(StreamID, Req, add_metrics_callback(Opts)).

info(StreamID, Info, State) ->
    cowboy_metrics_h:info(StreamID, Info, State).

data(StreamID, IsFin, Data, State) ->
    cowboy_metrics_h:data(StreamID, IsFin, Data, State).

terminate(StreamID, Reason, State) ->
    cowboy_metrics_h:terminate(StreamID, Reason, State).

early_error(StreamID, Reason, PartialReq, Resp, Opts) ->
    cowboy_metrics_h:early_error(StreamID, Reason, PartialReq, Resp, add_metrics_callback(Opts)).

%

add_metrics_callback(Opts) ->
    maps:put(metrics_callback, fun metrics_callback/1, Opts).

metrics_callback(#{early_error_time := Time} = Metrics) when is_number(Time) ->
    {RespBodyLength, Metadata} = maps:take(resp_body_length, Metrics),
    telemetry:execute(
        [cowboy, request, early_error],
        #{system_time => erlang:system_time(), resp_body_length => RespBodyLength},
        Metadata);
metrics_callback(#{reason := {internal_error, {'EXIT', _, {Reason, Stacktrace}}, _}} = Metrics) ->
    telemetry:execute(
        [cowboy, request, exception],
        measurements(Metrics),
        (metadata(Metrics))#{kind => exit, reason => Reason, stacktrace => Stacktrace});
metrics_callback(#{reason := {ErrorType, _, _} = Reason} = Metrics)
    when ErrorType == socket_error;
         ErrorType == connection_error ->
    telemetry:execute(
        [cowboy, request, stop],
        measurements(Metrics),
        (metadata(Metrics))#{error => Reason});
metrics_callback(Metrics) ->
    telemetry:execute(
        [cowboy, request, stop],
        measurements(Metrics),
        metadata(Metrics)).

measurements(Metrics) ->
    #{req_body_length := ReqBodyLength, resp_body_length := RespBodyLength} = Metrics,

    #{
        duration => duration(req_start, req_end, Metrics),
        req_body_duration => duration(req_body_start, req_body_end, Metrics),
        resp_duration => duration(resp_start, resp_end, Metrics),
        req_body_length => ReqBodyLength,
        resp_body_length => RespBodyLength
    }.

metadata(Metrics) ->
    #{
        pid := Pid,
        streamid := Streamid,
        req := Req,
        resp_headers := RespHeaders,
        resp_status := RespStatus,
        ref := Ref
    } = Metrics,

    #{
        pid => Pid,
        streamid => Streamid,
        req => Req,
        resp_headers => RespHeaders,
        resp_status => RespStatus,
        ref => Ref
    }.

duration(StartKey, EndKey, Metrics) ->
    case Metrics of
        #{StartKey := Start, EndKey := End} when is_integer(Start), is_integer(End) -> End - Start;
        #{} -> 0
    end.
