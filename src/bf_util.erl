%% Copyright (C) 2011 Roman Shestakov
%%%
%%% This file is part of bf_gateway
%%%
%%% bf_gateway is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU Lesser General Public License as 
%%% published by the Free Software Foundation, either version 3 of 
%%% the License, or (at your option) any later version.
%%%
%%% bf_gateway is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU Lesser General Public License for more details.
%%%
%%% You should have received a copy of the GNU Lesser General Public 
%%% License along with Erlsom.  If not, see 
%%% <http://www.gnu.org/licenses/>.
%%%
%%% Author contact: romanshestakov@yahoo.co.uk

-module(bf_util).

-export([
	 log4erl_config/0,
	 get_username/0,
	 get_password/0,
	 get_GS_Wsdl/0,
	 get_GX_Wsdl/0,
	 get_webmachine_ip/0,
	 url_encode/1
	]).

%%--------------------------------------------------------------------
%% @doc
%% Get log config of the project
%% creates a full path name to the job file definition.
%% @end
%%--------------------------------------------------------------------
-spec log4erl_config() -> string() | no_return().
log4erl_config() ->
    case application:get_env(bf_gateway, log4erl_config) of
	{ok, Value} -> Value;
	undefined -> throw({error, log4erl_config_not_defined})
    end.

%%--------------------------------------------------------------------
%% @doc
%% get betfair username
%% @end
%%--------------------------------------------------------------------
-spec get_username() -> string() | no_return().
get_username() ->
    case application:get_env(bf_gateway, username) of
	{ok, Value} -> Value;
	undefined -> throw({error, username_not_defined})
    end.

%%--------------------------------------------------------------------
%% @doc
%% get passord
%% @end
%%--------------------------------------------------------------------
-spec get_password() -> string() | no_return().
get_password() ->
    case application:get_env(bf_gateway, password) of
	{ok, Value} -> Value;
	undefined -> throw({error, password_not_defined})
    end.

%%--------------------------------------------------------------------
%% @doc
%% get ip for web server
%% @end
%%--------------------------------------------------------------------
-spec get_webmachine_ip() -> string() | false.
get_webmachine_ip() ->
    case application:get_env(bf_gateway, webmachine_ip) of
	{ok, Value} -> Value;
	undefined -> false %throw({error, webmachine_ip_not_defined})
    end.


%%--------------------------------------------------------------------
%% @doc
%% get BFGlobalService.wsdl
%% @end
%%--------------------------------------------------------------------
-spec get_GS_Wsdl() -> string() | no_return.
get_GS_Wsdl() ->
    File = code:priv_dir(bf_gateway) ++ "/BFGlobalService.wsdl",
    case filelib:is_file(File) of
	true -> File;
	false -> throw({file_not_exist, File})
    end.

%%--------------------------------------------------------------------
%% @doc
%% get BFExchangeService.wsdl
%% @end
%%--------------------------------------------------------------------
-spec get_GX_Wsdl() -> string() | no_return.
get_GX_Wsdl() ->
    File = code:priv_dir(bf_gateway) ++ "/BFExchangeService.wsdl",
    case filelib:is_file(File) of
	true -> File;
	false -> throw({file_not_exist, File})
    end.

%% @doc A function to URL encode form data.
%% @spec url_encode(formdata()).
%% http:request(post, {"http://localhost:3000/foo", [], 
%                        "application/x-www-form-urlencoded",
%                        url_encode([{"username", "bob"}, {"password", "123456"}])}
%                 ,[],[]).
%-spec(url_encode(formdata()) -> string()).
url_encode(Data) -> url_encode(Data, "").
url_encode([],Acc) -> Acc;
url_encode([{Key,Value} | R], "") ->
    url_encode(R, edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value));
url_encode([{Key,Value}|R],Acc) ->
    url_encode(R, Acc ++ "&" ++ edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value)).
