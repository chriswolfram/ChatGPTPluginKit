BeginPackage["Wolfram`ChatGPTPluginKit`Deploy`"];

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]
Needs["Wolfram`ChatGPTPluginKit`CopyButton`"]


(* ChatGPTPluginDeploy for local deployment *)

Options[ChatGPTPluginDeploy] = {
	HandlerFunctions -> <||>,
	HandlerFunctionsKeys -> Automatic
};

ChatGPTPluginDeploy[args___] :=
	Enclose[
		iChatGPTPluginDeploy@@Confirm[ArgumentsOptions[ChatGPTPluginDeploy[args], {1,2}]],
		"InheritedFailure"
	]


iChatGPTPluginDeploy[{plugin_ChatGPTPlugin, loc_}, opts_] :=
	Enclose[Module[{listener},

		listener =
			Confirm@SocketListen[loc,
				Module[{handlers, handlerKeys, req, baseURL, resp},

					handlers = OptionValue[ChatGPTPluginDeploy, opts, HandlerFunctions];
					handlerKeys = Replace[OptionValue[ChatGPTPluginDeploy, opts, HandlerFunctionsKeys], Automatic -> {"HTTPRequest", "HTTPResponse"}];

					req = ImportByteArray[#DataByteArray, "HTTPRequest"];

					Lookup[handlers, "HTTPRequestReceived", Identity][KeyTake[<|"HTTPRequest" -> req, "HTTPResponse" -> Missing["NotAvailable"]|>, handlerKeys]];

					baseURL = StringTemplate["http://localhost:``"][#Socket["DestinationPort"]];
					resp = GenerateHTTPResponse[plugin["URLDispatcherTemplate"][<|"BaseURL" -> baseURL|>], req];

					BinaryWrite[#SourceSocket, ExportByteArray[resp, "HTTPResponse"]];

					Lookup[handlers, "HTTPResponseSent", Identity][KeyTake[<|"HTTPRequest" -> req, "HTTPResponse" -> resp|>, handlerKeys]];

					(* TODO: This is a hack because the shutdown procedure in HTTP is more complicated than this *)
					Pause[0.2];
					Close[#SourceSocket]
				]&
			];

		ChatGPTPluginDeployment[<|
			"SocketListener" -> listener,
			"URL" -> "localhost:"<>ToString[listener["DestinationPort"]],
			"Plugin" -> plugin
		|>]

	], "InheritedFailure"]


iChatGPTPluginDeploy[{spec_, port_}, opts_] :=
	Enclose[
		iChatGPTPluginDeploy[{Confirm@ChatGPTPlugin[spec], port}, opts],
		"InheritedFailure"
	]

iChatGPTPluginDeploy[{plugin_}, opts_] :=
	iChatGPTPluginDeploy[{plugin, Automatic}, opts]



(* ChatGPTPluginCloudDeploy for cloud deployment *)

Options[ChatGPTPluginCloudDeploy] = {};

ChatGPTPluginCloudDeploy[args___] :=
	Enclose[
		iChatGPTPluginCloudDeploy@@Confirm[ArgumentsOptions[ChatGPTPluginCloudDeploy[args], 1]],
		"InheritedFailure"
	]


iChatGPTPluginCloudDeploy[{plugin_ChatGPTPlugin}, opts_] :=
	With[{baseURL = getBaseURL[]},
		If[FailureQ[baseURL],
			baseURL,
			ChatGPTPluginCloudDeployment[<|
				"CloudObjects" -> {
						CloudDeploy[ExportForm[plugin["ManifestJSONTemplate"][<|"BaseURL" -> baseURL|>], "JSON"], ".well-known/ai-plugin.json", Permissions -> "Public"],
						CloudDeploy[ExportForm[plugin["OpenAPIJSONTemplate"][<|"BaseURL" -> baseURL|>], "JSON"], ".well-known/openapi.json", Permissions -> "Public"],
						CloudDeploy[ExportForm[plugin["Image"], "PNG"], ".well-known/plugin_icon.png", Permissions -> "Public"],
						Splice[CloudDeploy[#["APIFunction"], #["OperationID"], Permissions -> "Public"] &/@ plugin["Endpoints"]]
					},
					"Plugin" -> plugin,
					"URL" -> baseURL
			|>]
		]
	]

iChatGPTPluginCloudDeploy[{spec_}, opts_] :=
	Enclose[
		iChatGPTPluginCloudDeploy[{Confirm@ChatGPTPlugin[spec]}, opts],
		"InheritedFailure"
	]


getBaseURL[] :=
	If[$UserURLBase === None,
		Failure["NoUserURLBase", <|
			"MessageTemplate" -> "Expected user URL base in $UserURLBase but found None instead. Run CloudConnect[] to connect to a Wolfram Cloud account."
		|>],
		"https://" <> $UserURLBase <> "-assets.wolframcloud.com"
	]


(* Deployment objects *)

ChatGPTPluginDeployment[data_]["Data"] := data
deployment_ChatGPTPluginDeployment["Plugin"] := deployment["Data"]["Plugin"]
deployment_ChatGPTPluginDeployment["SocketListener"] := deployment["Data"]["SocketListener"]
deployment_ChatGPTPluginDeployment["URL"] := deployment["Data"]["URL"]

ChatGPTPluginDeployment /: DeleteObject[deployment_ChatGPTPluginDeployment] := DeleteObject[deployment["SocketListener"]]

ChatGPTPluginDeployment /: MakeBoxes[deployment_ChatGPTPluginDeployment, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		ChatGPTPluginDeployment,
		deployment,
		None,
		{
			Row[{BoxForm`SummaryItem@{"url: ", deployment["URL"]}, CopyButton[deployment["URL"]]}]
		},
		{
			BoxForm`SummaryItem@{"plugin: ", deployment["Plugin"]},
			BoxForm`SummaryItem@{"socket listener: ", deployment["SocketListener"]}
		},
		form
	]


(* ChatGPTPluginCloudDeployment *)

ChatGPTPluginCloudDeployment[data_]["Data"] := data
deployment_ChatGPTPluginCloudDeployment["Plugin"] := deployment["Data"]["Plugin"]
deployment_ChatGPTPluginCloudDeployment["CloudObjects"] := deployment["Data"]["CloudObjects"]
deployment_ChatGPTPluginCloudDeployment["URL"] := deployment["Data"]["URL"]

ChatGPTPluginCloudDeployment /: DeleteObject[deployment_ChatGPTPluginCloudDeployment] := DeleteObject/@deployment["CloudObjects"]

ChatGPTPluginCloudDeployment /: MakeBoxes[deployment_ChatGPTPluginCloudDeployment, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		ChatGPTPluginCloudDeployment,
		deployment,
		None,
		{
			Row[{BoxForm`SummaryItem@{"url: ", deployment["URL"]}, CopyButton[deployment["URL"]]}]
		},
		{
			BoxForm`SummaryItem@{"plugin: ", deployment["Plugin"]},
			BoxForm`SummaryItem@{"cloud objects: ", deployment["CloudObjects"]}
		},
		form
	]



End[];
EndPackage[];
