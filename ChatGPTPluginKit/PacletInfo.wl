(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "Wolfram/ChatGPTPluginKit",
    "Description" -> "Build plugins for ChatGPT in just a few lines",
    "Creator" -> "Christopher Wolfram",
    "License" -> "MIT",
    "PublisherID" -> "Wolfram",
    "Version" -> "1.3.3",
    "WolframVersion" -> "13.1+",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {"Wolfram`ChatGPTPluginKit`"},
        "Symbols" -> {
          "Wolfram`ChatGPTPluginKit`ChatGPTPlugin",
          "Wolfram`ChatGPTPluginKit`ChatGPTPluginDeploy",
          "Wolfram`ChatGPTPluginKit`ChatGPTPluginDeployment",
          "Wolfram`ChatGPTPluginKit`ChatGPTPluginCloudDeploy",
          "Wolfram`ChatGPTPluginKit`ChatGPTPluginCloudDeployment",
          "Wolfram`ChatGPTPluginKit`ChatGPTPluginEndpoint"
        }
      },
      {
        "Documentation",
        "Root" -> "Documentation",
        "Language" -> "English"
      },
      {
        "Asset",
        "Root" -> "Assets",
        "Assets" -> {
          {"DefaultIcon", "default_icon.png"}
        }
      }
    }
  |>
]
