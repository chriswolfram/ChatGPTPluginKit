BeginPackage["Wolfram`ChatGPTPluginKit`Deploy`"];

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]


Options[ChatGPTPluginDeploy] = {
	HandlerFunctions -> <||>,
	HandlerFunctionsKeys -> Automatic
};

ChatGPTPluginDeploy[args___] :=
	Enclose[
		iChatGPTPluginDeploy@@Confirm[ArgumentsOptions[ChatGPTPluginDeploy[args], {1,2}]],
		"InheritedFailure"
	]


iChatGPTPluginDeploy[{plugin_ChatGPTPlugin, port_}, opts_] :=
	SocketListen[port,
		Module[{handlers, handlerKeys, req, resp},

			handlers = OptionValue[ChatGPTPluginDeploy, opts, HandlerFunctions];
			handlerKeys = Replace[OptionValue[ChatGPTPluginDeploy, opts, HandlerFunctionsKeys], Automatic -> {"HTTPRequest", "HTTPResponse"}];

			req = ImportByteArray[#DataByteArray, "HTTPRequest"];

			Lookup[handlers, "HTTPRequestReceived", Identity][KeyTake[<|"HTTPRequest" -> req, "HTTPResponse" -> Missing["NotAvailable"]|>, handlerKeys]];

			resp = GenerateHTTPResponse[plugin["URLDispatcher", port], req];

			BinaryWrite[#SourceSocket, ExportByteArray[resp, "HTTPResponse"]];

			Lookup[handlers, "HTTPResponseSent", Identity][KeyTake[<|"HTTPRequest" -> req, "HTTPResponse" -> resp|>, handlerKeys]];

			Close[#SourceSocket]
		]&
	]


iChatGPTPluginDeploy[{plugin_, loc_}, opts_] :=
	Failure["InvalidPlugin", <|
		"MessageTemplate" -> "Expected a ChatGPTPlugin object but found `1` instead.",
		"MessageParamters" -> {plugin},
		"PluginSpecification" -> plugin
	|>]
	

iChatGPTPluginDeploy[{plugin_ChatGPTPlugin}, opts_] :=
	iChatGPTPluginDeploy[{plugin, $ChatGPTPluginPort}, opts]



End[];
EndPackage[];
