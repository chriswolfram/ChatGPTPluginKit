# Examples

## 📁 File System Access
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

## 🗃️ Database access
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

## 💻 Full kernel access

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

## 🔍 Documentation search

Give ChatGPT access to Wolfram Language documentation. This uses a vector database and works the same way as OpenAI's [Retrieval plugin](https://github.com/openai/chatgpt-retrieval-plugin).

### Create vector database

Use embeddings from OpenAI to to create a vector database for documentation search:

```wl
PacletInstall["ChristopherWolfram/OpenAILink"];
Needs["ChristopherWolfram`OpenAILink`"];

symbolEmbeddings =
  Map[
    OpenAIEmbedding[StringRiffle[#, "\n"]]&,
    DeleteMissing[EntityValue["WolframLanguageSymbol", "TextStrings", "EntityAssociation"]]
  ];
symbolEmbeddings //= Select[Not@*FailureQ];
nf = Nearest[symbolEmbeddings, DistanceFunction -> CosineDistance]
```

### Deploy plugin

```wl
ChatGPTPluginDeploy[<|
  "Name" -> "WolframLanguageDocumentation",
  "Description" -> "Get documentation on Wolfram Langauge symbols",
  "Prompt" -> "Get documentation on Wolfram Langauge symbols. Use the documentation to look up any Wolfram Language symbols that you are unsure about",
  "Endpoints" -> <|
    "getSymbolDocs" ->
      APIFunction["symbol" -> "WolframLanguageSymbol", StringRiffle[#symbol["TextStrings"],"\n"]&],
    "searchSymbols" -> <|
      "Prompt" -> "finds symbols which might be relevant to a query. Some symbols returned might not be relevant.",
      "APIFunction" -> APIFunction["query" -> "String", CanonicalName@nf[OpenAIEmbedding[#query],25]&]
    |>
  |>
|>]
```

<details>
<summary>Example chat</summary>
Also with the kernel access plugin enabled:
  
![DocumentationSearch](https://user-images.githubusercontent.com/5055424/231877625-a0c14506-3120-4d0c-a580-bdf5c0fe17d7.png)

</details>

## 🌐 Web browsing

Allow ChatGPT to use `Import` to get data form the web. It can extract data as plaintext, hyperlinks, or the full source. It also has access to a search endpoint:

```wl
ChatGPTPluginDeploy[<|
  "Name" -> "WebAccess",
  "Description" -> "Give ChatGPT access to the internet",
  "Prompt" -> "Get information from the internet",
  "Endpoints" -> <|
    "webSearch" -> APIFunction[ "query", Normal@WebSearch[#query][All,{"PageTitle","Hyperlink"/*First}]&],
    "getPageHyperlinks" -> APIFunction[ "url", Import[#url,"Hyperlinks"]&],
    "getPagePlaintext" -> APIFunction["url", Import[#url,"Plaintext"]&],
    "getPageHTML" -> APIFunction["url", Import[#url,"Source"]&]
  |>
|>]
```

<details>
<summary>Example chat</summary>
  
![WebAccess](https://user-images.githubusercontent.com/5055424/231878684-1e3946ee-8c47-4215-a9e1-256422c0da01.png)

</details>

## 📱 SMS

Give ChatGPT a simple SMS endpoint that can send messages to `$MobilePhone`:

```wl
ChatGPTPluginDeploy[<|
  "Name" -> "SMS",
  "Description" -> "Send SMS messages",
  "Prompt" -> "Send SMS messages",
  "Endpoints" -> <|"sendMessage" -> APIFunction["message", SendMessage["SMS", #message]&]|>
|>]
```

<details>
<summary>Example chat</summary>
  
![SendMessage](https://user-images.githubusercontent.com/5055424/231879054-b7c15846-040d-4c4b-9dfc-1b3870b6030e.png)

</details>

## 🗂️ Organizing a directory

Let ChatGPT help you organize the files in a directory. This takes advantage of `Import` to allow ChatGPT to inspect hundreds of different file formats that can be reduced to plaintext:

```wl
ChatGPTPluginDeploy[<|
  "Name" -> "FileOrganizer",
  "Description" -> "View and organize files on a computer.",
  "Prompt" -> "View and organize files on a computer.",
  "Endpoints" -> <|
    "getFileNames" -> <|
      "Prompt" -> "lists the names of the files",
      "APIFunction" -> APIFunction[{},StringRiffle[FileNameTake/@FileNames["*",exampleDirectory],"\n"]&]
    |>,
    "getFileContents" -> <|
      "Prompt" -> "gets the contents of a file as text. Only request the contents of files that you are sure exist.",
      "APIFunction" -> APIFunction[
          "name" -> <|"Help"->"the name of the file"|>,
          StringTake[Import[FileNameJoin[{exampleDirectory,#name}],"Plaintext"],UpTo[1000]]&
        ]
    |>,
    "renameFile" -> APIFunction[
        {"oldName", "newName"},
        RenameFile[FileNameJoin[{exampleDirectory,#oldName}], FileNameJoin[{exampleDirectory,#newName}]]&
      ]
  |>
|>]
```

<details>
<summary>Example chat</summary>
  
![FileOrganizer](https://user-images.githubusercontent.com/5055424/231879851-f0aec1ae-bf70-40ab-ae18-68a0a6cea6af.png)

</details>

## 💡 Programming assistant

Combine several of the plugins above to give ChatGPT the ability to:

* Run code
* Reload a Wolfram Language kernel
* Edit code in a paclet
* Search for keywords in a paclet
* Search documentation
* Read documentation

Note: this uses the vector database from the documentation plugin.

<details>
<summary>Full source</summary>
  
```wl
formatResults[lines_, resLines_, radius_:2] :=
  With[{returnedLines = Split[Union@@(Range@@Clip[{#-radius,#+radius},{1,Length[lines]}]&/@resLines), #2-#1<=1&]},
    StringRiffle[#,"\n"]&/@Map[ToString[#] <> "\t" <> lines[[#]]&, returnedLines, {2}]
  ]

basicSearch[dir_, query_] :=
  StringRiffle[
    Catenate@KeyValueMap[
      {fileName, res}|->(fileName<>":\n"<>#&/@res),
      FileSystemMap[
        Module[{lines, ps},
          lines = StringSplit[ReadString[#],"\n"];
          ps = Position[StringContainsQ[lines, query, IgnoreCase->True], True, {1}][[All,1]];
          formatResults[lines,ps]
        ]&,
        dir,
        Infinity,
        1
      ]
    ],
    "\n\n"
  ]
  
prompt = "Help the user program. All Wolfram Language code sent in the \"code\" parameter of runCode must be provided as a single-line string with NO comments (i.e. any text between `(*` and `*)`), extra line breaks, or formatting whitespace or tabs. If a line of code ends with a semicolon, its output will be suppressed. When editing a file, always read it before writing a change. When replacing an old or broken definition, always delete the old definition before inserting the replacement.";

programmingAssistantPlugin[directory_, kernelInit_] :=
  Module[{ker, plugin},
    ker = First@LaunchKernels[1];
    With[{init = kernelInit}, ParallelEvaluate[ReleaseHold[init],ker]];
    plugin = ChatGPTPlugin[<|
      "Name" -> "ProgrammingAssistant",
      "Description" -> "Assist in programming.",
      "Prompt" -> prompt,
      "Endpoints" -> <|
      
        "searchFiles" -> <|
          "Prompt" -> "searches files for a keyword",
          "APIFunction" -> APIFunction["query" -> "String", basicSearch[directory, #query]&]
        |>,
        
        "getFileLines" -> <|
          "Prompt" -> "gets the contents of a file near a line number.",
          "APIFunction" -> APIFunction[
            {
              "fileName" -> <|"Help" -> "the name of the file"|>,
              "line" -> <|"Interpreter" -> "Integer", "Help" -> "the line number in the file"|>
            },
            First@formatResults[StringSplit[ReadString[FileNameJoin[{directory,#fileName}]],"\n"], {#line}]&
          ]
        |>,
        
        "insertFileLine" -> <|
          "Prompt" -> "inserts a line into a file. Always re-read a file before inserting lines.",
          "APIFunction" -> APIFunction[
            {
              "fileName" -> <|"Help" -> "the name of the file"|>,
              "line" -> <|"Interpreter" -> "Integer", "Help" -> "the line at which to insert"|>,
              "contents" -> <|"Help" -> "the contents to insert at the line"|>
            },
            Module[{path, lines, newStr},
              path = FileNameJoin[{directory,#fileName}];
              lines = StringSplit[ReadString[path],"\n"];
              newStr = StringRiffle[Insert[lines, #contents, #line], "\n"];
              WriteString[path, newStr];
              Close[path]
            ]&
          ]
        |>,
        
        "deleteFileLines" -> <|
          "Prompt" -> "deletes lines in a file from a range of line numbers",
          "APIFunction" -> APIFunction[
            {
              "fileName" -> <|"Help" -> "the name of the file"|>,
              "startLine" -> <|"Interpreter" -> "Integer", "Help" -> "the first line to delete"|>,
              "stopLine" -> <|"Interpreter" -> "Integer", "Help" -> "the last line to delete"|>
            },
            Module[{path, lines, newStr},
              path = FileNameJoin[{directory,#fileName}];
              lines = StringSplit[ReadString[path],"\n"];
              newStr = StringRiffle[Delete[lines, Range[#startLine, #stopLine]], "\n"];
              WriteString[path, newStr];
              Close[path]
            ]&
          ]
        |>,
        
        "restartKernel" -> <|
          "Prompt" -> "restarts the Wolfram Language kernel session and re-runs the initialization",
          "APIFunction" -> APIFunction[{},
            (
              CloseKernels[ker];
              {ker} = LaunchKernels[1];
              With[{init = kernelInit}, ParallelEvaluate[ReleaseHold[init],ker]];
            )&
          ]
        |>,
        
        "runCode" -> <|
          "Prompt" -> "runs a Wolfram Language program in the kernel session.",
          "APIFunction" -> APIFunction[
            "code" -> <|"Help"->"the Wolfram Language program"|>,
            ParallelEvaluate[ToExpression[#code],ker]&
          ]
        |>,
        
        "getSymbolDocs" ->
          APIFunction["symbol" -> "WolframLanguageSymbol", StringRiffle[#symbol["TextStrings"],"\n"]&],
          
        "searchSymbols" -> <|
          "Prompt" -> "finds symbols which might be relevant to a query. Some symbols returned might not be relevant.",
          "APIFunction" -> APIFunction["query" -> "String", CanonicalName@nf[OpenAIEmbedding[#query],25]&]
        |>
      |>
    |>];
    {plugin, ker}
  ]
```

</details>
	
Deploy the plugin:
	
```wl
{plugin,kernel} = programmingAssistantPlugin[
    FileNameJoin[{NotebookDirectory[],"ChatGPTPluginKitCopy","Kernel"}],
    Hold[
      PacletInstall["Wolfram/ChatGPTPluginKit"];
      Needs["Wolfram`ChatGPTPluginKit`"]
    ]
  ];
ChatGPTPluginDeploy[server]
```
	
<details>
<summary>Example chat</summary>
  
![ProgrammingAssistant](https://user-images.githubusercontent.com/5055424/231881412-97f5c8cb-45c1-4250-bc1e-eb9c664c87de.png)

</details>
