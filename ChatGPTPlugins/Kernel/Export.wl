BeginPackage["ChristopherWolfram`ChatGPTPlugins`Export`"];

Begin["`Private`"];

Needs["ChristopherWolfram`ChatGPTPlugins`"]


Options[ExportChatGPTPlugin] = {IncludeDefinitions -> True};

ExportChatGPTPlugin[args___] :=
	Enclose[
		iExportChatGPTPlugin@@Confirm[ArgumentsOptions[ExportChatGPTPlugin[args], 1]],
		"InheritedFailure"
	]

iExportChatGPTPlugin[{plugin_ChatGPTPlugin}, opts_] :=
	pluginString[plugin, TrueQ@OptionValue[ExportChatGPTPlugin, opts, IncludeDefinitions]]

iExportChatGPTPlugin[{plugin_}, opts_] :=
	Failure["InvalidPlugin", <|
		"MessageTemplate" -> "Expected a ChatGPTPlugin object but found `1` instead.",
		"MessageParamters" -> {plugin},
		"PluginSpecification" -> plugin
	|>]


pluginString[plugin_, True] :=
	With[{dispatcher = plugin["URLDispatcher"]},
	With[{defs = Language`ExtendedFullDefinition[dispatcher]},
		ToString[Unevaluated[Language`ExtendedFullDefinition[] = defs; dispatcher], InputForm]
	]]

pluginString[plugin_, False] :=
	With[{dispatcher = plugin["URLDispatcher"]},
		ToString[Unevaluated[dispatcher], InputForm]
	]


End[];
EndPackage[];
