-module(bf_market_web).

-export([init/1]).
-export([
	 allowed_methods/2,
	% process_post/2,
         resource_exists/2,
         %% last_modified/2,
         content_types_provided/2,
         content_types_accepted/2,
         delete_resource/2,
	 %%to_json/2,
	 to_text/2,
	 accept_form/2
         %% post_is_create/2,
         %% create_path/2,
         %provide_content/2
         %% accept_content/2,
         %% generate_etag/2
	]).

%-record(context, {root,response_body=undefined,metadata=[]}).

%-include_lib("kernel/include/file.hrl").
-include_lib("webmachine/include/webmachine.hrl").

init([]) -> {ok, undefined}.
    
allowed_methods(ReqData, Context) ->
    {['HEAD', 'GET', 'PUT', 'DELETE', 'POST'], ReqData, Context}.

%% content_types_provided(ReqData, Context) ->
%%     {[{"application/json", to_json}], ReqData, Context}.

content_types_provided(ReqData, Context) ->
   {[{"text/plain", to_text}], ReqData, Context}.

content_types_accepted(ReqData, Context) ->
    {[{"application/x-www-form-urlencoded", accept_form}], ReqData, Context}.

resource_exists(ReqData, Context) ->
    case wrq:path(ReqData) of
	"/markets" -> {true, ReqData, {show_all_markets}};
	_Other ->
	    case wrq:path_info(marketId, ReqData) of
		undefined -> {false, ReqData, Context};
		Other1 ->
		    try
			MarketId = list_to_integer(Other1),
			case proplists:is_defined(MarketId, bf_gateway:getSubscribedMarkets()) of
			    true -> {true, ReqData, {marketId, MarketId}};
			    false -> {false, ReqData, {marketId, MarketId}}
			end
		    catch
			_:_ -> {false, ReqData, Context}
		    end
	    end
    end.

to_text(ReqData, {show_all_markets}) ->
    Markets = bf_gateway:getSubscribedMarkets(),
    Body = io_lib:format("~p.~n", [Markets]),
    {Body, ReqData, {}};
to_text(ReqData, {marketId, _MarketId}) ->
    %%Markets = bf_gateway:getSubscribedMarkets(),
    Body = io_lib:format("~p.~n", ["dddd"]),
    {Body, ReqData, {}}.

%% to_json(ReqData, Result) -> 
%%     {mochijson:encode(Result), ReqData, Result}.

%% %% reply to post
%% %% hit with 
%% %% curl -X POST http://rs.home:8000/market/subscribe -d "MarketId=102940691"
%% process_post(ReqData, subscribe) ->
%%     Body = mochiweb_util:parse_qs(wrq:req_body(ReqData)),
%%     MarketId = list_to_integer(proplists:get_value("MarketId", Body)),
%%     bf_gateway:subscribeToMarket(MarketId),
%%     {true, ReqData, {}}.
%% curl -X PUT -H "Content-type: application/x-www-form-urlencoded" http://rs.home:8000/market/104432877
accept_form(ReqData, {marketId, MarketId}) ->
    bf_gateway:subscribeToMarket(MarketId),
    {true, ReqData, MarketId}.

%% curl -X DELETE http://rs.home:8000/market/unsubscribe?MarketId=102873654
%% curl -X PUT -H "Content-type: application/x-www-form-urlencoded" http://rs.home:8000/market/104432877
delete_resource(ReqData, {marketId, MarketId}) ->
    bf_gateway:unsubscribeFromMarket(MarketId),
    {true, ReqData, MarketId}.
