-module(bf_api).

-export([login/3,
	 logout/2,
	 keepalive/2,
	 convertCurrency/2,
	 getAllCurrencies/2,
	 getAllCurrenciesV2/2,
	 getActiveEventTypes/2,
	 getAllEventTypes/2,
	 getAllMarkets/2,
	 getMarket/3
	]).

-include("../include/BFGlobalService.hrl").
-include("../include/BFExchangeService.hrl").
-include("../include/BFGlobalServiceErrCodes.hrl").


-define(LOCALE, "en").

%%--------------------------------------------------------------------
%% @doc
%% login to betfair
%% @end
%%--------------------------------------------------------------------
-spec login(any(), string(), string()) -> {ok, string()} | {login_error, any()}.
login(GS_Wsdl, Username, Password) ->
    LoginReq = #'P:LoginReq'{ username = Username,
			      password = Password,      
			      ipAddress = "0",
			      locationId = 0,
			      productId = 82,
			      vendorSoftwareId = 0},
    try
	log4erl:debug("sending login req ~p", [LoginReq]),
	LoginResp = detergent:call(GS_Wsdl, "login", [LoginReq]),
	log4erl:debug("got login resp ~p", [LoginResp]),
	case LoginResp of
	    {ok, _, [#'p:loginResponse'{ 'Result' =
					     #'P:LoginResp'{header = #'P:APIResponseHeader'{'sessionToken' = Token},
							    currency = _Currency,
							    errorCode = ErrCode,
							    minorErrorCode = MErrCode}}]} ->
		case ErrCode == ?LOGIN_ERROR_OK of
		    true -> {ok, Token};
		    false -> {login_error, {ErrCode, MErrCode}}
		end;
	    Other -> {login_error, Other}
	end
    catch
	Err -> {login_error, Err}
    end.

%%--------------------------------------------------------------------
%% @doc
%% logout from betfair
%% @end
%%--------------------------------------------------------------------
-spec logout(any(), string()) -> {ok, string()} | {logout_error, any()}. 
logout(GS_Wsdl, Token) ->
    LogoutReq = #'P:LogoutReq'{ 'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" }},
    try
	log4erl:debug("sending logout req ~p", [LogoutReq]),
	LogoutResp = detergent:call(GS_Wsdl, "logout", [LogoutReq]),
	log4erl:debug("logout resp ~p", [LogoutResp]),
	case LogoutResp of
	    {ok, _, [#'p:logoutResponse'{'Result' =
					     #'P:LogoutResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
							     errorCode = ErrCode,
							     minorErrorCode = MErrCode}}]} ->
		case ErrCode == ?LOGOUT_ERROR_OK of
		    true -> {ok, NewToken};
		    false -> {logout_error, {ErrCode, MErrCode}}
		end;
	    Other -> {logout_error, Other}
	end
    catch
	Err -> {logout_error, Err}
    end.


%%--------------------------------------------------------------------
%% @doc
%% keepalive
%% @end
%%--------------------------------------------------------------------
-spec keepalive(any(), string()) -> {ok, string()} | {keepalive_error, any()}.
keepalive(GS_Wsdl, Token) ->
    KeepAliveReq = #'P:KeepAliveReq'{ 'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" }},
    try
	log4erl:debug("sending keepAlive ~p", [KeepAliveReq]),
	KeepAliveResp = detergent:call(GS_Wsdl, "keepAlive", [KeepAliveReq]),
	log4erl:debug("keepalive resp ~p", [KeepAliveResp]),
	case KeepAliveResp of
	    {ok, _, [#'p:keepAliveResponse'{'Result' =
						#'P:KeepAliveResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
								   apiVersion = _ApiVersion,
								   minorErrorCode = _MErrCode}}]} ->
		{ok, NewToken};
	    Other -> {keepalive_error, Other}
	end
    catch
	Err -> {keepalive_error, Err}
    end.


%%--------------------------------------------------------------------
%% @doc
%% @end
%%--------------------------------------------------------------------
%-spec
convertCurrency(_GS_Wsdl, _Token) ->
    throw(not_implemented).

getAllCurrencies(_GS_Wsdl, _Token) ->
    throw(not_implemented).

getAllCurrenciesV2(_GS_Wsdl, _Token) ->
    throw(not_implemented).


%%--------------------------------------------------------------------
%% @doc
%% The API GetActiveEventTypes service allows the customer to retrieve lists of all categories of sporting events
%% (Games, Event Types) that are available to bet on: in other words, all those that have at least one currently active
%% or suspended market associated with them. This means, therefore, that the service would, for example,
%% always return the event types Soccer and Horse Racing but would not return Olympics 2004 or EURO 2004 after
%% those events had finished.
%% @end
%%--------------------------------------------------------------------
-spec getActiveEventTypes(any(), string()) -> {ok, string(), [{integer(), string(), integer(), integer()}]} | {getActiveEventTypes_error, any()}.
getActiveEventTypes(GS_Wsdl, Token) ->
    GetActiveEventTypesReq = #'P:GetEventTypesReq'{'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" },
						   'locale' = ?LOCALE},
    try
	log4erl:debug("sending getActiveEventTypes ~p", [GetActiveEventTypesReq]),
	GetEventTypesResp = detergent:call(GS_Wsdl, "getActiveEventTypes", [GetActiveEventTypesReq]),
	log4erl:debug("getActiveEventTypes resp ~p", [GetEventTypesResp]),
	case GetEventTypesResp of
	    {ok, _, [#'p:getActiveEventTypesResponse'{'Result' =
							  #'P:GetEventTypesResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
										 eventTypeItems = #'P:ArrayOfEventType'{'EventType' = EventTypeItems},
										 errorCode = ErrCode,
										 minorErrorCode = MErrCode}}]} ->
		
		case ErrCode == ?GET_EVENTS_ERROR_OK of
		    true -> 
			EventTypes = [{Id, Name, MarketId, ExchId} || #'P:EventType'{'id' = Id,
										     'name' = Name,
										     'nextMarketId' = MarketId,
										     'exchangeId' = ExchId} <- EventTypeItems],
			
			{ok, NewToken, EventTypes};
		    false -> {getActiveEventTypes_error, {ErrCode, MErrCode}}
		end;
	    Other -> {getActiveEventTypes_error, Other}
	end
    catch
	Err -> {getActiveEventTypes_error, Err}
    end.


%%--------------------------------------------------------------------
%% @doc
%% The API GetAllEventTypes service allows the customer to retrieve lists of all categories of sports (Games, Event Types)
%% that have at least one market associated with them, regardless of whether that market is now closed for betting.
%% This means that, for example, the service would always returnthe event types Soccer and Horse Racing and would also return Olympics 2004
%% or EURO 2004 for a certain period after the markets for those events had closed; it would also return Olympics 2004 or EURO 2004 for a
%% certain period before the markets for those events had opened. The service returns information on future events to allow
%% API programmers to see the range of events that will be available to bet on in the near future.
%% @end
%%--------------------------------------------------------------------
-spec getAllEventTypes(any(), string()) -> {ok, string(), [{integer(), string(), integer(), integer()}]} | {getAllEventTypes_error, any()}.
getAllEventTypes(GS_Wsdl, Token) -> 
    GetActiveEventTypesReq = #'P:GetEventTypesReq'{'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" },
						   'locale' = ?LOCALE},
    try
	log4erl:debug("sending getAllEventTypes ~p", [GetActiveEventTypesReq]),
	GetEventTypesResp = detergent:call(GS_Wsdl, "getAllEventTypes", [GetActiveEventTypesReq]),
	log4erl:debug("getAllEventTypes resp ~p", [GetEventTypesResp]),
	case GetEventTypesResp of
	    {ok, _, [#'p:getAllEventTypesResponse'{'Result' =
						       #'P:GetEventTypesResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
									      eventTypeItems = #'P:ArrayOfEventType'{'EventType' = EventTypeItems},
									      errorCode = ErrCode,
									      minorErrorCode = MErrCode}}]} ->
		
		case ErrCode == ?GET_EVENTS_ERROR_OK of
		    true -> 
			EventTypes = [{Id, Name, MarketId, ExchId} || #'P:EventType'{'id' = Id,
										     'name' = Name,
										     'nextMarketId' = MarketId,
										     'exchangeId' = ExchId} <- EventTypeItems],
			
			{ok, NewToken, EventTypes};
		    false -> {getAllEventTypes_error, {ErrCode, MErrCode}}
		end;
	    Other -> {getAllEventTypes_error, Other}
	end
    catch
	Err -> {getActiveEventTypes_error, Err}
    end.

%%--------------------------------------------------------------------
%% @doc
%% @end
%%--------------------------------------------------------------------
%-spec getAllMarkets() ->
getAllMarkets(GX_Wsdl, Token) -> 
    GetAllMarketsReq = #'P:GetAllMarketsReq'{'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" },
					     'locale' = "",
 					     'eventTypeIds' = #'P:ArrayOfInt'{'int' = []},
  					     'countries' = #'P:ArrayOfCountryCode'{'Country' = []},
  					     'fromDate' = "",
  					     'toDate' = ""					     
					    },
    try
	log4erl:debug("sending getAllMarkets req ~p", [GetAllMarketsReq]),
	GetAllMarketsResp = detergent:call(GX_Wsdl, "getAllMarkets", [GetAllMarketsReq]),
	log4erl:debug("getAllMarkets resp ~p", [GetAllMarketsResp]),
	case GetAllMarketsResp of
	    {ok, _, [#'p:getAllMarketsResponse'{'Result' =
						       #'P:GetAllMarketsResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
									      marketData = MarketData,
									      errorCode = ErrCode,
									      minorErrorCode = MErrCode}}]} ->
		
		case ErrCode == ?GET_ALL_MARKETS_ERROR_OK of
		    true -> 
			{ok, NewToken, MarketData};
		    false -> {getAllMarkets_error, {ErrCode, MErrCode}}
		end;
	    Other -> {getAllMarkets_error, Other}
	end
    catch
	Err -> {getAllMarkets_error, Err}
    end.



getMarket(GX_Wsdl, Token, MarketId) -> 
    GetMarketReq = #'P:GetMarketReq'{'header' = #'P:APIRequestHeader'{sessionToken = Token, clientStamp = "0" },
				     'marketId' = MarketId,
				     'includeCouponLinks' = false,
				     'locale' = ?LOCALE
				    },
    try
	log4erl:debug("sending getMarket req ~p", [GetMarketReq]),
	GetMarketResp = detergent:call(GX_Wsdl, "getMarket", [GetMarketReq]),
	log4erl:debug("getMarket resp ~p", [GetMarketResp]),
	case GetMarketResp of
	    {ok, _, [#'p:getMarketResponse'{'Result' =
						#'P:GetMarketResp'{header = #'P:APIResponseHeader'{sessionToken = NewToken},
								   market = Market,
								   errorCode = ErrCode,
								   minorErrorCode = MErrCode}}]} ->
		
		case ErrCode == ?GET_MARKET_ERROR_OK of
		    true -> 
			Json = bf_json:market(Market),
			{ok, NewToken, Json};
		    false -> {getMarket_error, {ErrCode, MErrCode}}
		end;
	    Other -> {getMarket_error, Other}
	end
    catch
	Err -> {getMarket_error, Err}
    end.
