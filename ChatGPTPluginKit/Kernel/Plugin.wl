BeginPackage["Wolfram`ChatGPTPluginKit`Plugin`"];

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]


(****************************************************************)
(************************* ChatGPTPlugin ************************)
(****************************************************************)


(* Constructors *)

Options[ChatGPTPlugin] = {};

ChatGPTPlugin[args___] /; !argumentsChatGPTPluginQ[args] := createChatGPTPlugin[args]


argumentsChatGPTPluginQ[
	KeyValuePattern[{
		"Name" -> _,
		"Description" -> _,
		"Prompt" -> _,
		"Endpoints" -> {__ChatGPTPluginEndpoint}
	}],
	{OptionsPattern[]}
] := True

argumentsChatGPTPluginQ[___] := False


createChatGPTPlugin[args___] :=
	Enclose[
		icreateChatGPTPlugin@@Confirm[ArgumentsOptions[ChatGPTPlugin[args], {1,2}]],
		"InheritedFailure"
	]

icreateChatGPTPlugin[{metadata_, endpoints_}, opts_] :=
	Enclose[
		ChatGPTPlugin[
			Join[
				Confirm@normalizeMetadata[metadata],
				<|"Endpoints" -> Confirm@normalizeEndpoints[endpoints]|>
			],
			opts
		],
		"InheritedFailure"
	]


normalizeMetadata[prompt_?StringQ] :=
	normalizeMetadata[<|"Prompt" -> prompt|>]

normalizeMetadata[metadata: KeyValuePattern[{}]] :=
	Merge[{
		<|
			"Name" -> "ExperimentalPlugin",
			"Description" -> "",
			"Prompt" -> ""
		|>,
		KeyTake[metadata, {"Name", "Description", "Prompt"}]
	}, Last]

normalizeMetadata[expr_] :=
	Failure["InvalidMetadataSpecification", <|
		"MessageTemplate" -> "Expected an association with metadata but found `1` instead.",
		"MessageParameters" -> {expr},
		"MetadataSpecification" -> expr
	|>]


normalizeEndpoints[endpoint_ChatGPTPluginEndpoint] := {endpoint}
normalizeEndpoints[endpoints: {__ChatGPTPluginEndpoint}] := endpoints
normalizeEndpoints[name_ -> data_] := normalizeEndpoints[ChatGPTPluginEndpoint[name, data]]
normalizeEndpoints[endpoints: KeyValuePattern[{}] /; Length[endpoints] > 0] := normalizeEndpoints[KeyValueMap[ChatGPTPluginEndpoint, Association@endpoints]]
normalizeEndpoints[expr_] :=
	Failure["InvalidEndpointsSpecification", <|
		"MessageTemplate" -> "Expected a single ChatGPTPluginEndpoint, a list with at least one ChatGPTPluginEndpoint, or an association specifying ChatGPTEndpoints, but found `1` instead.",
		"MessageParameters" -> {expr},
		"Endpointspecification" -> expr
	|>]


(* Association constructors *)

icreateChatGPTPlugin[{assoc:KeyValuePattern[{}]}, opts_] :=
	Enclose[
		ChatGPTPlugin[
			Join[
				Confirm@normalizeMetadata[assoc],
				<|"Endpoints" -> Confirm@normalizeEndpoints[Lookup[assoc, "Endpoints", {}]]|>
			],
			opts
		],
		"InheritedFailure"
	]


icreateChatGPTPlugin[{spec_}, opts_] :=
	Failure["InvalidPluginSpecification", <|
		"MessageTemplate" -> "Unexpected expression `1` encountered representing a ChatGPT plugin.",
		"MessageParameters" -> {spec},
		"Endpointspecification" -> spec
	|>]



(* Accessors *)

HoldPattern[ChatGPTPlugin][data_, opts_]["Data"] := data
HoldPattern[ChatGPTPlugin][data_, opts_]["Options"] := opts

plugin_ChatGPTPlugin["Name"] := Lookup[plugin["Data"], "Name"]
plugin_ChatGPTPlugin["Description"] := Lookup[plugin["Data"], "Description"]
plugin_ChatGPTPlugin["Prompt"] := Lookup[plugin["Data"], "Prompt"]
plugin_ChatGPTPlugin["Endpoints"] := Lookup[plugin["Data"], "Endpoints"]
plugin_ChatGPTPlugin["OpenAPIJSON", port_] := pluginAPIJSON[plugin, port]
plugin_ChatGPTPlugin["OpenAPIJSON"] := plugin["OpenAPIJSON", $ChatGPTPluginPort]
plugin_ChatGPTPlugin["ManifestJSON", port_] := pluginManifestJSON[plugin, port]
plugin_ChatGPTPlugin["ManifestJSON"] := plugin["ManifestJSON", $ChatGPTPluginPort]
plugin_ChatGPTPlugin["URLDispatcher", port_] := pluginURLDispatcher[plugin, port]
plugin_ChatGPTPlugin["URLDispatcher"] := plugin["URLDispatcher", $ChatGPTPluginPort]


(* OpenAPI *)

pluginAPIJSON[plugin_ChatGPTPlugin, port_] :=
	<|
		"openapi" -> "3.0.1",
		"info" -> <|
			"title" -> plugin["Name"],
			"description" -> plugin["Description"],
			"version" -> "v1"
		|>,
		"servers" -> {<|"url" -> "http://localhost:"<>ToString[port]|>},
		"paths" -> Join@@(#["OpenAPIJSON"]&)/@plugin["Endpoints"]
	|>


(* Manifest *)

pluginManifestJSON[plugin_ChatGPTPlugin, port_] :=
	<|
		"schema_version" -> "v1",
		"name_for_human" -> plugin["Name"],
		"name_for_model" -> plugin["Name"],
		"description_for_human" -> plugin["Description"],
		"description_for_model" -> plugin["Prompt"],
		"auth" -> <|"type" -> "none"|>,
		"api" -> <|
			"type" -> "openapi",
			"url" -> StringTemplate["http://localhost:``/.well-known/openapi.json"][port],
			"is_user_authenticated" -> False
		|>,
		"logo_url" -> "https://www.wolframcdn.com/images/icons/Wolfram.png",
		"contact_email" -> "support@example.com",
		"legal_info_url" -> "http://www.example.com/legal"
	|>


(* URLDispatcher *)

pluginURLDispatcher[plugin_ChatGPTPlugin, port_] :=
	URLDispatcher[{
		"/.well-known/ai-plugin.json" -> addCORS@ExportForm[plugin["ManifestJSON", port], "JSON"],
		"/.well-known/openapi.json" -> addCORS@ExportForm[plugin["OpenAPIJSON", port], "JSON"],
		Splice["/"<>#["OperationID"] -> addCORS@#["APIFunction"]& /@ plugin["Endpoints"]]
	}]

addCORS[expr_] :=
	HTTPResponse[expr,
		<|"Headers" -> {
				"Access-Control-Allow-Origin" -> "*",
				"Access-Control-Allow-Method" -> "*",
				"Access-Control-Allow-Headers" -> "Accept, *"
			}
		|>
	]


(* Summary box *)

ChatGPTPlugin /: MakeBoxes[plugin_ChatGPTPlugin, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		ChatGPTPlugin,
		plugin,
		None,
		{
			BoxForm`SummaryItem@{"name: ", plugin["Name"]},
			BoxForm`SummaryItem@{"description: ", plugin["Description"]}
		},
		{
			BoxForm`SummaryItem@{"endpoints: ", Column@plugin["Endpoints"]},
			BoxForm`SummaryItem@{"prompt: ", plugin["Prompt"]}
		},
		form
	]


End[];
EndPackage[];
