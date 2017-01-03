# ILPDFKit Plugin

Cordova plugin to [ILPDFKit](https://github.com/iwelabs/ILPDFKit), is a simple, minimalist toolkit for filling out PDF forms, which extends UIWebView and the CoreGraphics PDF C API.

This plugin defines a global ( `ILPDFKit` ) object which you can use to access the public API.


## Plugin

Although `ILPDFKit` is globally acessible, it isn't usable until `deviceready` event is called.

As with all the cordova plugins, you can listen to `deviceready` event as follows: 

```javascript
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    // ...
}
```

## Supported Platforms

 - iOS


## Installation
- Run the following command:

```shell
    cordova plugin add https://github.com/OutSystemsExperts/ILPDFKit-Cordova-Plugin.git
``` 
---

## API Reference

### ILPDFKit (`ILPDFKit`)

 - [`.present(filePath, options, successCallback, errorCallback)`](#editPdf)

 ---

<a name="editPdf"></a>
#### Edit PDF

Calling this method opens the pdf.

| Param             | Type      | Description |
| ---               | ---       | --- |
| filePath     | String    | Path to file in file system. |
| options     | [`Object`](#options)    | Possible options. |
| successCallback   | [`Function`](#successCallback)  | Callback function called when successfully open document. |
| errorCallback     | [`Function`](#errorCallback)    | Callback function called when an error occurs. |

<a name="options"></a>
#### Possible options


| Param             | Type      | Description |
| ---               | ---       | --- |
| useDocumentsFolder   | Boolean | f true we will serch for pdf in app's Documents folder otherwise in www folder |
| fileNameToSave | String | File name of saved pdf. If not specified original pdf name used. |
| askToSaveBeforeClose  | Boolean | If true alert massage will appear on close. |
| openFromUrl     | Boolean    | If is to open from a url |
| openFromPath     | Boolean    | If is to open from a file path |

<a name="successCallback"></a>
#### Success Callback

Signature: 

```javascript
function(result){
    // ...
};
```
where `result` parameter is a JSON object:

```javascript
{
    "filePath":"",  //optional
    "successMessage":"", //optional
    "successCode":""
}
```

<a name="errorCallback"></a>
#### Error Callback

Signature: 

```javascript
function(err){
    // ...
};
```

where `err` parameter is a JSON object:

```javascript
{
    "errorCode":"",
    "errorMessage":""
}
```

Possible `errorCode` values:
 - `1` - The user cancel the operation to close the document.
 - `2` - Failed to save pdf.
 - `3` - Failed to open pdf.
 - `4` - The path/url is empty
 - `5` - One of Types of path should be choose
 - `6` - Failed to download pdf.


## License

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.

