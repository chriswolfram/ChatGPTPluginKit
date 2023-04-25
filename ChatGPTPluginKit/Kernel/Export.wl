BeginPackage["Wolfram`ChatGPTPluginKit`Export`"];

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]


Options[ChatGPTPluginExport] = {IncludeDefinitions -> True};

ChatGPTPluginExport[args___] :=
	Enclose[
		iExportChatGPTPlugin@@Confirm[ArgumentsOptions[ChatGPTPluginExport[args], 1]],
		"InheritedFailure"
	]

iChatGPTPluginExport[{plugin_ChatGPTPlugin}, opts_] :=
	pluginString[plugin, TrueQ@OptionValue[ChatGPTPluginExport, opts, IncludeDefinitions]]

iChatGPTPluginExport[{plugin_}, opts_] :=
	Failure["InvalidPlugin", <|
		"MessageTemplate" -> "Expected a ChatGPTPlugin object but found `1` instead.",
		"MessageParamters" -> {plugin},
		"PluginSpecification" -> plugin
	|>]


pluginString[plugin_, True] :=
	With[{dispatcher = plugin["URLDispatcherTemplate"][<|"BaseURL" -> "http://localhost:18000"|>]},
	With[{defs = Language`ExtendedFullDefinition[dispatcher]},
		ToString[Unevaluated[Language`ExtendedFullDefinition[] = defs; dispatcher], InputForm]
	]]

pluginString[plugin_, False] :=
	With[{dispatcher = plugin["URLDispatcherTemplate"][<|"BaseURL" -> "http://localhost:18000"|>]},
		ToString[Unevaluated[dispatcher], InputForm]
	]


End[];
EndPackage[];
