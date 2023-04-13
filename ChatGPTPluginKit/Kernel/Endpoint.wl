BeginPackage["Wolfram`ChatGPTPluginKit`Endpoint`"];

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]


(****************************************************************)
(********************* ChatGPTPluginEndpoint ********************)
(****************************************************************)


(* Constructors *)

Options[ChatGPTPluginEndpoint] = {};

ChatGPTPluginEndpoint[args___] /; !argumentsChatGPTPluginEndpointQ[args] := createChatGPTPluginEndpoint[args]


argumentsChatGPTPluginEndpointQ[
	KeyValuePattern[{
		"OperationID" -> _?StringQ,
		"Prompt" -> _?StringQ | _Missing,
		"Parameters" -> {
			(_String -> KeyValuePattern[{
					"Interpreter" -> _,
					"Help" -> _,
					"Required" -> _
				}])...
		},
		"Function" -> _,
		"APIFunctionOptions" -> _
	}]?AssociationQ,
	{OptionsPattern[]}
] :=
	True

argumentsChatGPTPluginEndpointQ[___] := False


createChatGPTPluginEndpoint[args___] :=
	Enclose[
		icreateChatGPTPluginEndpoint@@Confirm[ArgumentsOptions[ChatGPTPluginEndpoint[args], {2,3}]],
		"InheritedFailure"
	]

icreateChatGPTPluginEndpoint[{opSpec_, params_, f_}, opts_] :=
	Enclose[
		ChatGPTPluginEndpoint[
			Join[
				Confirm@normalizeOpSpec[opSpec],
				<|
					"Parameters" -> Confirm@normalizeParamsList[params],
					"Function" -> f,
					"APIFunctionOptions" -> {}
				|>
			],
			opts
		],
		"InheritedFailure"
	]


normalizeOpSpec[opID_?StringQ] := <|"OperationID" -> opID, "Prompt" -> Missing["NotSpecified"]|>
normalizeOpSpec[{opID_?StringQ, prompt: _?StringQ | _Missing}] := <|"OperationID" -> opID, "Prompt" -> prompt|>
normalizeOpSpec[spec_] :=
	Failure["InvalidOperationSpecification", <|
		"MessageTemplate" -> "Expected an operation name, or a list containing an operation name and a prompt, but found `1` instead.",
		"MessageParameters" -> {spec},
		"OperationSpecification" -> spec
	|>]


normalizeParamsList[params_List] := Enclose[Confirm@*normalizeParam /@ params, "InheritedFailure"]
normalizeParamsList[params_?AssociationQ] := normalizeParamsList[Normal[params]]
normalizeParamsList[params_] := normalizeParamsList[{params}]

normalizeParam[name_ -> props_?AssociationQ] := name -> normalizeParamProps[props]
normalizeParam[name_?StringQ -> interp_] := normalizeParam[name -> <|"Interpreter" -> interp|>]
normalizeParam[name_?StringQ] := normalizeParam[name -> <||>]
normalizeParam[param_] :=
	Failure["InvalidParameterSpecification", <|
		"MessageTemplate" -> "Expected a parameter specification but found `1` instead.",
		"MessageParameters" -> {param},
		"ParameterSpecification" -> param
	|>]

normalizeParamProps[props_?AssociationQ] :=
	Merge[{
		<|
			"Interpreter" -> "String",
			"Help" -> Missing["NotSpecified"],
			"Required" -> True
		|>,
		props
	}, Last]


(* Association constructors *)

icreateChatGPTPluginEndpoint[{opName_, assoc_}, opts_] :=
	Enclose[
		With[{
				prompt = Lookup[assoc, "Prompt", Missing["NotSpecified"]],
				apiFunc = Lookup[assoc, "APIFunction", ConfirmAssert[False, missingAPIFunctionFailure[assoc]]]
			},
			ChatGPTPluginEndpoint[
				Join[
					<|
						"OperationID" -> ConfirmBy[opName, StringQ, invalidNameFailure[opName]],
						"Prompt" -> ConfirmMatch[prompt, _?StringQ | _Missing, invalidPromptFailure[prompt]]
					|>,
					Confirm@normalizeAPIFunction[apiFunc]
				],
				opts
			]
		],
		"InheritedFailure"
	]

icreateChatGPTPluginEndpoint[{opName_, apiFunc_APIFunction}, opts_] :=
	icreateChatGPTPluginEndpoint[{opName, <|"APIFunction" -> apiFunc|>}, opts]


normalizeAPIFunction[APIFunction[args___]] :=
	With[{res = ArgumentsOptions[APIFunction[args], {1,3}]},
		If[!FailureQ[res],
			inormalizeAPIFunction@@res,
			Failure["InvalidAPIFunction", <|
				"MessageTemplate" -> "Expected a valid APIFunction but found `1` instead.",
				"MessageParameters" -> {api},
				"Name" -> api
			|>]
		]
	]

inormalizeAPIFunction[{params_, f_, fmt_}, opts_] :=
	Enclose[
		<|
			"Parameters" -> Confirm@normalizeParamsList[params],
			"Function" -> f,
			"OutputFormat" -> fmt,
			"APIFunctionOptions" -> opts
		|>,
		"InheritedFailure"
	]

inormalizeAPIFunction[{params_, f_}, opts_] :=
	Enclose[
		<|
			"Parameters" -> Confirm@normalizeParamsList[params],
			"Function" -> f,
			"APIFunctionOptions" -> opts
		|>,
		"InheritedFailure"
	]

inormalizeAPIFunction[{params_}, opts_] :=
	inormalizeAPIFunction[{params, Identity}, opts]


invalidNameFailure[name_] :=
	Failure["InvalidEndpointName", <|
		"MessageTemplate" -> "Expected an endpoint name as a string but found `1` instead.",
		"MessageParameters" -> {name},
		"Name" -> name
	|>]

invalidPromptFailure[prompt_] :=
	Failure["InvalidEndpointPrompt", <|
		"MessageTemplate" -> "Expected an endpoint prompt as a string or Missing but found `1` instead.",
		"MessageParameters" -> {prompt},
		"Prompt" -> prompt
	|>]

missingAPIFunctionFailure[assoc_] :=
	Failure["MissingAPIFunction", <|
		"MessageTemplate" -> "Required an APIFunction in endpoint, but only found `1`.",
		"MessageParameters" -> {assoc},
		"Data" -> assoc
	|>]



(* Accessors *)

HoldPattern[ChatGPTPluginEndpoint][data_, opts_]["Data"] := data
HoldPattern[ChatGPTPluginEndpoint][data_, opts_]["Options"] := opts

endpoint_ChatGPTPluginEndpoint["OperationID"] := endpoint["Data"]["OperationID"]
endpoint_ChatGPTPluginEndpoint["Prompt"] := endpoint["Data"]["Prompt"]
endpoint_ChatGPTPluginEndpoint["Parameters"] := endpoint["Data"]["Parameters"]
endpoint_ChatGPTPluginEndpoint["Function"] := endpoint["Data"]["Function"]
endpoint_ChatGPTPluginEndpoint["APIFunctionOptions"] := endpoint["Data"]["APIFunctionOptions"]

endpoint_ChatGPTPluginEndpoint["OpenAPIJSON"] := endpointAPIJSON[endpoint]
endpoint_ChatGPTPluginEndpoint["APIFunction"] := endpointAPIFunction[endpoint]


(* OpenAPI *)

endpointAPIJSON[endpoint_ChatGPTPluginEndpoint] :=
	<|
		"/"<>endpoint["OperationID"] -> <|
			"get" -> <|
				"operationId" -> endpoint["OperationID"],
				If[StringQ@endpoint["Prompt"], "summary" -> endpoint["Prompt"], Nothing],
				"responses" -> <|"200" -> <|"description" -> "OK"|>|>,
				"parameters" -> endpointParamAPIJSON /@ endpoint["Parameters"]
			|>
		|>
	|>

endpointParamAPIJSON[name_ -> KeyValuePattern[{"Help" -> prompt_, "Required" -> req_}]] :=
	<|
		"name" -> name,
		"in" -> "query",
		If[StringQ@prompt, "description" -> prompt, Nothing],
		"required" -> req,
		"schema" -> <|"type" -> "string"|>
	|>


(* APIFunction *)

(* Because of CORS, ChatGPT makes an OPTIONS request before its POST request. This must return the right headers, but
it shouldn't run the function body. *)
endpointAPIFunction[endpoint_ChatGPTPluginEndpoint] :=
	If[KeyExistsQ[endpoint["Data"], "OutputFormat"],
		APIFunction[
			removeHelp@endpoint["Parameters"],
			With[{funcBody = endpoint["Function"]}, If[HTTPRequestData["Method"] === "OPTIONS", "", funcBody[#]]&],
			endpoint["Data"]["OutputFormat"],
			endpoint["APIFunctionOptions"]
		],
		APIFunction[
			removeHelp@endpoint["Parameters"],
			With[{funcBody = endpoint["Function"]}, If[HTTPRequestData["Method"] === "OPTIONS", "", funcBody[#]]&],
			endpoint["APIFunctionOptions"]
		]
	]


(* TODO: Temporary workaround for bug #434606 *)
removeHelp[params_] :=
	MapAt[KeyDrop["Help"], params, {All,2}]


(* Summary box *)

ChatGPTPluginEndpoint /: MakeBoxes[endpoint_ChatGPTPluginEndpoint, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		ChatGPTPluginEndpoint,
		endpoint,
		None,
		{
			BoxForm`SummaryItem@{"name: ", endpoint["OperationID"]}
		},
		{
			BoxForm`SummaryItem@{"prompt: ", endpoint["Prompt"]}
		},
		form
	]


End[];
EndPackage[];
