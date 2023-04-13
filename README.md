# 🤖🔌 ChatGPTPluginKit

Deploy powerful plugins to ChatGPT in only a few lines of code.

## ⚙️ Installation

ChatGPTPluginKit is provided through the Wolfram Paclet Repository, and can be found [here](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/ChatGPTPluginKit/).

To install, just run:

```
PacletInstall["Wolfram/ChatGPTPluginKit"]
```

and then use `Needs` to load it in any subsequent session:

```
Needs["Wolfram`ChatGPTPluginKit`"]
```

## 📚 Examples

### 🌆 Minimal example

Deploy a plugin that lets ChatGPT look up the populations of cities, using data and entity resolution from Wolfram|Alpha:

```wl
ChatGPTPluginDeploy[<|
	"Name" -> "CityPopulationFinder",
	"Endpoints" -> <|"getCityPopulation" -> APIFunction["city"->"City", #city["Population"]&]|>
|>]
```

Use it inside ChatGPT:

<img width="705" alt="cityPopulation" src="https://user-images.githubusercontent.com/5055424/231856851-9d7dfed4-9eda-440f-b08c-660ffb13f003.png">

### 💬 Interactive environment

Collaborate with ChatGPT in real time:

_Insert gif here_

### 🌟 Example showcase

See [here](EXAMPLES.md) for more examples.
