BeginPackage["ChristopherWolfram`ChatGPTPlugins`Endpoint`"];

Begin["`Private`"];

Needs["ChristopherWolfram`ChatGPTPlugins`"]


(****************************************************************)
(********************* ChatGPTPluginEndpoint ********************)
(****************************************************************)


(* Constructors *)

Options[ChatGPTPluginEndpoint] = {};

ChatGPTPluginEndpoint[args___] /; !argumentsChatGPTPluginEndpointQ[args] := createChatGPTPluginEndpoint[args]


argumentsChatGPTPluginEndpointQ[
	{opID_?StringQ, prompt: _?StringQ | _Missing},
	paramsList: {
		(_String -> KeyValuePattern[{
				"Interpreter" -> _,
				"Help" -> _,
				"Required" -> _
			}])...
	},
	f_,
	{OptionsPattern[]}
] :=
	True

argumentsChatGPTPluginEndpointQ[___] := False


createChatGPTPluginEndpoint[args___] :=
	Enclose[
		icreateChatGPTPluginEndpoint@@Confirm[ArgumentsOptions[ChatGPTPluginEndpoint[args], 3]],
		"InheritedFailure"
	]

icreateChatGPTPluginEndpoint[{opSpec_, params_, f_}, opts_] :=
	Enclose[
		ChatGPTPluginEndpoint[
			Confirm@normalizeOpSpec[opSpec],
			Confirm@normalizeParamsList[params],
			f,
			opts
		],
		"InheritedFailure"
	]


normalizeOpSpec[opID_?StringQ] := {opID, Missing["NotSpecified"]}
normalizeOpSpec[op: {opID_?StringQ, prompt: _?StringQ | _Missing}] := op
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



(* Accessors *)

HoldPattern[ChatGPTPluginEndpoint][op_, params_, f_, opts_]["Operation"] := op
HoldPattern[ChatGPTPluginEndpoint][op_, params_, f_, opts_]["Parameters"] := params
HoldPattern[ChatGPTPluginEndpoint][op_, params_, f_, opts_]["Function"] := f
HoldPattern[ChatGPTPluginEndpoint][op_, params_, f_, opts_]["Options"] := opts

endpoint_ChatGPTPluginEndpoint["OperationID"] := endpoint["Operation"][[1]]
endpoint_ChatGPTPluginEndpoint["Prompt"] := endpoint["Operation"][[2]]
endpoint_ChatGPTPluginEndpoint["OpenAPIJSON"] := endpointAPIJSON[endpoint]
endpoint_ChatGPTPluginEndpoint["APIFunction"] := endpointAPIFunction[endpoint]


(* OpenAPI *)

endpointAPIJSON[endpoint_ChatGPTPluginEndpoint] :=
	<|
		"/"<>endpoint["OperationID"] -> <|
			"post" -> <|
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

endpointAPIFunction[endpoint_ChatGPTPluginEndpoint] :=
	APIFunction[removeHelp@endpoint["Parameters"], endpoint["Function"]]


(* TODO: Temporary workaround for bug #434606 *)
removeHelp[params_] :=
	MapAt[KeyDrop["Help"], params, {All,2}]


End[];
EndPackage[];
