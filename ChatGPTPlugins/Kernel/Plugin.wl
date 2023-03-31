BeginPackage["ChristopherWolfram`ChatGPTPlugins`Plugin`"];

Begin["`Private`"];

Needs["ChristopherWolfram`ChatGPTPlugins`"]


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
		"Prompt" -> _ 
	}],
	{__ChatGPTPluginEndpoint},
	{OptionsPattern[]}
] := True

argumentsChatGPTPluginQ[___] := False


createChatGPTPlugin[args___] :=
	Enclose[
		icreateChatGPTPlugin@@Confirm[ArgumentsOptions[ChatGPTPlugin[args], 2]],
		"InheritedFailure"
	]

icreateChatGPTPlugin[{metadata_, endpoints_}, opts_] :=
	Enclose[
		ChatGPTPlugin[
			Confirm@normalizeMetadata[metadata],
			Confirm@normalizeEndpoints[endpoints],
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
		metadata
	}, Last]

normalizeMetadata[expr_] :=
	Failure["InvalidMetadataSpecification", <|
		"MessageTemplate" -> "Expected an association with metadata but found `1` instead.",
		"MessageParameters" -> {expr},
		"MetadataSpecification" -> expr
	|>]


normalizeEndpoints[endpoint_ChatGPTPluginEndpoint] := {endpoint}
normalizeEndpoints[endpoints: {__ChatGPTPluginEndpoint}] := endpoints
normalizeEndpoints[expr_] :=
	Failure["InvalidEndpointsSpecification", <|
		"MessageTemplate" -> "Expected a single ChatGPTPluginEndpoint or a list with at least one ChatGPTPluginEndpoint, but found `1` instead.",
		"MessageParameters" -> {expr},
		"Endpointspecification" -> expr
	|>]



(* Accessors *)

HoldPattern[ChatGPTPlugin][metadata_, endpoints_, opts_]["Metadata"] := metadata
HoldPattern[ChatGPTPlugin][metadata_, endpoints_, opts_]["Endpoints"] := endpoints
HoldPattern[ChatGPTPlugin][metadata_, endpoints_, opts_]["Options"] := opts

plugin_ChatGPTPlugin["Name"] := Lookup[plugin["Metadata"], "Name"]
plugin_ChatGPTPlugin["Description"] := Lookup[plugin["Metadata"], "Description"]
plugin_ChatGPTPlugin["Prompt"] := Lookup[plugin["Metadata"], "Prompt"]
plugin_ChatGPTPlugin["OpenAPIJSON"] := pluginAPIJSON[plugin]
plugin_ChatGPTPlugin["ManifestJSON"] := pluginManifestJSON[plugin]
plugin_ChatGPTPlugin["URLDispatcher"] := pluginURLDispatcher[plugin]


(* OpenAPI *)

pluginAPIJSON[plugin_ChatGPTPlugin] :=
	<|
		"openapi" -> "3.0.1",
		"info" -> <|
			"title" -> plugin["Name"],
			"description" -> plugin["Description"],
			"version" -> "v1"
		|>,
		"servers" -> {<|"url" -> "http://localhost:18000"|>},
		"paths" -> Join@@(#["OpenAPIJSON"]&)/@plugin["Endpoints"]
	|>


(* Manifest *)

pluginManifestJSON[plugin_ChatGPTPlugin] :=
	<|
		"schema_version" -> "v1",
		"name_for_human" -> plugin["Name"],
		"name_for_model" -> plugin["Name"],
		"description_for_human" -> plugin["Description"],
		"description_for_model" -> plugin["Prompt"],
		"auth" -> <|"type" -> "none"|>,
		"api" -> <|
			"type" -> "openapi",
			"url" -> "http://localhost:18000/.well-known/openapi.json",
			"is_user_authenticated" -> False
		|>,
		"logo_url" -> "https://www.wolframcdn.com/images/icons/Wolfram.png",
		"contact_email" -> "support@example.com",
		"legal_info_url" -> "http://www.example.com/legal"
	|>


(* URLDispatched *)

pluginURLDispatcher[plugin_ChatGPTPlugin] :=
	URLDispatcher[{
		"/.well-known/ai-plugin.json" -> addCORS@ExportForm[plugin["ManifestJSON"], "JSON"],
		"/.well-known/openapi.json" -> addCORS@ExportForm[plugin["OpenAPIJSON"], "JSON"],
		Splice["/"<>#["OperationID"] -> addCORS@#["APIFunction"]& /@ plugin["Endpoints"]]
	}]

addCORS[expr_] :=
	HTTPResponse[expr,
		<|"Headers" -> {
				"Access-Control-Allow-Origin" -> "*",
				"Access-Control-allow-Method" -> "*",
				"Access-Control-allow-Headers" -> "*"
			}
		|>
	]


End[];
EndPackage[];
