BeginPackage["Wolfram`ChatGPTPluginKit`CopyButton`"];

CopyButton

Begin["`Private`"];

Needs["Wolfram`ChatGPTPluginKit`"]


$copyIcon[color_] = Graphics[
	GeometricTransformation[{
		color,
		Thickness[0.05],
		CapForm["Butt"],
		JoinForm["Bevel"],
		JoinedCurve[{
			{{0, 2, 0}, {1, 3, 3}, {0, 1, 0}, {1, 3, 3},{0, 1, 0}, {1, 3, 3}, {0, 1, 0}},
			{{0, 2, 0}, {1, 3, 3}, {0, 1, 0}, {1, 3, 3}, {0, 1, 0}, {1, 3, 3}, {0, 1, 0},
			{1, 3, 3}}},
			{{{9.`, 15.`}, {5.`, 15.`}, {3.895430088043213`, 15.`},
			{3.`, 14.104599952697754`}, {3.`, 13.`}, {3.`, 5.`}, {3.`, 3.895430088043213`},
			{3.895430088043213`, 3.`}, {5.`, 3.`}, {13.`, 3.`}, {14.104599952697754`, 3.`},
			{15.`, 3.895430088043213`}, {15.`, 5.`}, {15.`, 9.`}},
			{{11.`, 21.`}, {19.`, 21.`}, {20.10460090637207`, 21.`},
			{21.`, 20.10460090637207`}, {21.`, 19.`}, {21.`, 11.`},
			{21.`, 9.895429611206055`}, {20.10460090637207`, 9.`},
			{19.`, 9.`}, {11.`, 9.`}, {9.895429611206055`, 9.`}, {9.`, 9.895429611206055`},
			{9.`, 11.`}, {9.`, 19.`}, {9.`, 20.10460090637207`},
			{9.895429611206055`, 21.`}, {11.`, 21.`}}
			},
			CurveClosed -> {0, 1}]
		},
		{{{1, 0}, {0, -1}}, {0, 0}}],
		ImageSize -> 20
	]


SetAttributes[myButton, HoldFirst]
myButton[action_, rules:{__Rule}|Association, opts: OptionsPattern[Button]] := 
	Button[
		DynamicModule[
			{mouseDown = False, mouseHover = False},
			EventHandler[
				PaneSelector[{
					"Default" -> Lookup[rules, "Default"],
					"Hover" -> Lookup[rules, "Hover", Lookup[rules, "Default"]],
					"Pressed" -> Lookup[rules, "Pressed", Lookup[rules, "Default"]]
					},
					Dynamic[
						FEPrivate`Which[
							mouseDown, "Pressed",
							mouseHover, "Hover",
							True, "Default"
						]
					]
				],
				{
					"MouseDown" :> FEPrivate`Set[mouseDown, True],
					"MouseUp" :> FEPrivate`Set[mouseDown, False],
					"MouseEntered" :> FEPrivate`Set[mouseHover, True],
					"MouseExited" :> FEPrivate`Set[mouseHover, False]
				},
				PassEventsDown -> True
			]
		],
		action,
		Appearance -> {
			"Default" -> FrontEnd`FileName[{"Misc"}, "TransparentBG.9.png"]
		},
		opts
	]


CopyButton = With[
	{opts = {FrameStyle -> Transparent, RoundingRadius -> 5, FrameMargins -> 5}},
	Function[
		expr, 
		myButton[
			CopyToClipboard[expr],
			{
				"Default" -> Framed[$copyIcon[GrayLevel[0.65]], opts, Background -> Transparent],
				"Hover" -> Framed[$copyIcon[GrayLevel[0.286]], opts, Background -> Transparent],
				"Pressed" -> Framed[$copyIcon[GrayLevel[0.286]], opts, Background -> GrayLevel[0.,0.05]]
			}
		],
		HoldFirst
	]
];



End[];
EndPackage[];
