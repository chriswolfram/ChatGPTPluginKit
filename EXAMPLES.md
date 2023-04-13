# Examples

## File System Access
Give ChatGPT access to your local file system:

```wl
ChatGPTPluginDeploy[<|
	"Name" -> "FileBrowser",
	"Description" -> "Browse files on a computer",
	"Prompt" -> "Browse files on a computer",
	"Endpoints" -> <|
		"getDirectoryFiles" -> <|
			"Prompt" -> "lists the files in a directory",
			"APIFunction" -> APIFunction[
					"path" -> <|"Help"->"the path to the directory"|>,
					StringRiffle[FileNameTake/@FileNames["*",#path],"\n"]&
				]
		|>,
		"getFileContents" -> <|
			"Prompt" -> "gets the contents of a file as text. Only request the contents of files that you are sure exist.",
			"APIFunction" ->
				APIFunction["path" -> <|"Help"->"the path to the file"|>, ReadString[#path]&]
		|>
	|>
|>]
```

<details>
<summary>Example chat</summary>
  
![FileBrowser](https://user-images.githubusercontent.com/5055424/231871756-319b280d-ceb4-4229-8bfb-4967fc654727.png)

</details>

## Database access
Give ChatGPT access to run queries on a database:

```wl
db = DatabaseReference[FindFile["ExampleData/ecommerce-database.sqlite"]];
ChatGPTPluginDeploy[<|
	"Name" -> "Database",
	"Description" -> "Run queries on a database",
	"Prompt" -> "Run queries on an SQLite database. Always get the schema for all the tables in the database before querying it.",
	"Endpoints" -> <|
		"runQuery" -> <|
			"Prompt" -> "runs a query on an SQLite database",
			"APIFunction" -> APIFunction[
					"query" -> <|"Help"->"the SQLite query all on one line"|>,
					ExportForm[ExternalEvaluate[db, #query]/._Missing->Null,"CSV"]&
				]
		|>
	|>
|>]
```

<details>
<summary>Example chat</summary>
  
![Databases](https://user-images.githubusercontent.com/5055424/231873761-f5377093-ced3-48b2-bead-19d92e3573a4.png)

</details>

## Full kernel access

Allow ChatGPT to run arbitrary Wolfram Language code in the local kernel session:

```wl
ChatGPTPluginDeploy@ChatGPTPlugin[
	<|
		"Name" -> "KernelAccess",
		"Description" -> "Give ChatGPT access to your WL kernel",
		"Prompt" -> "Evaluate Wolfram Language code in a kernel session."
	|>,
	ChatGPTPluginEndpoint[
		{"runCode", "runs a Wolfram Language program in a kernel session"},
		"code" -> <|"Help"->"the Wolfram Language program"|>,
		ToExpression[#code]&
	]
]
```

This plugin is pretty dangerous. There is nothing here stopping ChatGPT from running code to delete files, etc. However, as long as you never tell it to do anything dangerous, you should be fine. (Assuming no Skynet, that is.)

A better prompt could probably encourage it to be safe, and refuse requests to run unsafe operations.

<details>
<summary>Example chat</summary>
  
  In the kernel from which the plugin was deployed:
  
  ```wl
  func[r_] := FixedPoint[Function[x, (x + r/x)/2], r]
  ```
  
  Then, with ChatGPT:
  
  ![KernelAccess](https://user-images.githubusercontent.com/5055424/231874481-cd558372-679e-477a-a840-eb71934b2c49.png)

  Later in the same kernel:
  
  ```wl
  shortestTourPlot[Thread@RandomGeoPosition[10]]
  ```
  
  <img width="420" alt="image" src="https://user-images.githubusercontent.com/5055424/231875177-deda4515-253c-4512-940a-e0049e1c2824.png">


</details>
