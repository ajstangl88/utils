//PersonalGenomeDemo.jsx
//An InDesign ExtendScript by SPI
//

//Eval the file for the paginator
var theScriptFolderPath = $.fileName.split(";")[0];
var theScriptFolder = new Folder(theScriptFolderPath);
var theFilePath = theScriptFolder.parent.parent.fsName + "/Scripts/SiliconPaginator_CommonFunctions.jsx";
theFilePath = theFilePath.replace(/\\/g, "/");
var theFile = new File(theFilePath);
if (!theFile.exists) {
	theFilePath = theFilePath + "bin";
	theFile = new File(theFilePath);
}
$.evalFile(theFile);

// Eval the json module
theFilePath = theScriptFolder.parent.parent.fsName + "/Scripts/json2.jsx";
theFilePath = theFilePath.replace(/\\/g, "/");
theFile = new File(theFilePath);
if (!theFile.exists)

{
	theFilePath = theFilePath + "bin";
	theFile = new File(theFilePath);
}
$.evalFile(theFile);
//WritingToConsole = true; // previously used in the old driver file
bWritingToConsole = true;	// defined in "SiliconPaginator_CommonFunctions.jsx"
var g_bServerRunning;
var g_bTesting = false;

main();
function main()
{
	var retVal = "Failure";
	var inDesignFilePathArg = app.scriptArgs.isDefined("INDESIGN-FILE-PATH") ? app.scriptArgs.getValue("INDESIGN-FILE-PATH") : null;
	var outputFolderPathArg = app.scriptArgs.isDefined("OUTPUT-FOLDER-PATH") ? app.scriptArgs.getValue("OUTPUT-FOLDER-PATH") : null;
	var outputBasenameArg = app.scriptArgs.isDefined("OUTPUT-BASENAME") ? app.scriptArgs.getValue("OUTPUT-BASENAME") : null;
	var graphicFolderBasePathArg = app.scriptArgs.isDefined("GRAPHIC-FOLDER-BASEPATH") ? app.scriptArgs.getValue("GRAPHIC-FOLDER-BASEPATH") : null;
	var overviewDataArg = app.scriptArgs.isDefined("OVERVIEWDATA") ? app.scriptArgs.getValue("OVERVIEWDATA") : null;
	var xmlVariableDataArg = app.scriptArgs.isDefined("XMLVARIABLEDATA") ? app.scriptArgs.getValue("XMLVARIABLEDATA") : null;
	var textframeDataArg = app.scriptArgs.isDefined("TEXTFRAMEDATA") ? app.scriptArgs.getValue("TEXTFRAMEDATA") : null;
	var storyDataArg = app.scriptArgs.isDefined("STORYDATA") ? app.scriptArgs.getValue("STORYDATA") : null;
	var staticDataArg = app.scriptArgs.isDefined("STATICTABLEDATA") ? app.scriptArgs.getValue("STATICTABLEDATA") : null;
	var dynamicDataArg = app.scriptArgs.isDefined("DYNAMICTABLEDATA") ? app.scriptArgs.getValue("DYNAMICTABLEDATA") : null;
	var xmlStoryDataArg = app.scriptArgs.isDefined("XMLSTORYDATA") ? app.scriptArgs.getValue("XMLSTORYDATA") : null;
	var conditionsDataArg = app.scriptArgs.isDefined("CONDITIONSDATA") ? app.scriptArgs.getValue("CONDITIONSDATA") : null;

	if (inDesignFilePathArg != null && outputFolderPathArg != null && outputBasenameArg != null && graphicFolderBasePathArg != null )
	{
		// Eval the json module
		theFilePath = theScriptFolder.parent.parent.fsName + "/Scripts/json2.jsx";
		theFilePath = theFilePath.replace(/\\/g, "/");
		theFile = new File(theFilePath);
		if (!theFile.exists)
		{
			theFilePath = theFilePath + "bin";
			theFile = new File(theFilePath);
		}
		$.evalFile(theFile);
		var inDesignFilePath = inDesignFilePathArg;	// location of indesign template to start from
		var overviewDataJSON = overviewDataArg;	// locations of file holding key/value pairs for variables not handled by a snippet
		var overviewData = JSON.parse(overviewDataJSON);
		var xmlVariableDataJSON = xmlVariableDataArg;	// locations of file holding key/value pairs for variables not handled by a snippet
		var xmlVariableData = JSON.parse(xmlVariableDataJSON);
		var textframeDataJSON = textframeDataArg;	// array in JSON format
		var textframeData = JSON.parse(textframeDataJSON);	// array of arrays, each inner array [datafile, variableinbraces] to bootstrap named textframes with text content
		var storyDataJSON = storyDataArg;	// array in JSON format
		var storyData = JSON.parse(storyDataJSON);	// array of arrays, each inner array [datafile, snippetfile, variableinbraces] to insert story snippet w/ optional data file for variable resolution
		var xmlStoryDataJSON = xmlStoryDataArg;	// array in JSON format
		var xmlStoryData = JSON.parse(xmlStoryDataJSON);	// array of arrays, each inner array [xmldatafile, elementname, mapfile, snippetfile, variableinbraces] to insert  story snippet w/ xml data file for variable resolution
		var staticDataJSON = staticDataArg;	// array in JSON format
		var staticData = JSON.parse(staticDataJSON);	// array of arrays, each inner array [datafile, snippetfile, variableinbraces] to insert a static table w/ optional data file for variable resolution
		var dynamicDataJSON = dynamicDataArg;	// array in JSON format
		var dynamicData = JSON.parse(dynamicDataJSON);	// array of arrays, each inner array [datafile, snippetfile, variableinbraces] to insert a dynamic table
		var conditionsDataJSON = conditionsDataArg;	// array in JSON format
		var conditionsData = JSON.parse(conditionsDataJSON);	// array of arrays, each inner array [conditionname, bVisible] to set conditions (assumed to already exist) in the template
		var outputFolderPath = ensureEndsWithSeparator(outputFolderPathArg);	// folder path for output files
		var outputBasename = outputBasenameArg;	// optional basename to use for output files (if not provided, decided in makeOutputPath() below
		var graphicFolderBasePath = graphicFolderBasePathArg;	// basepath for graphic paths in "@variablename" uses in overviewData file
		var outputPathSansExt = makeOutputPath(inDesignFilePath, outputFolderPath, outputBasename);
		var bogusFile = new File(outputPathSansExt);
		setupLogFile(outputFolderPath + "/" + bogusFile.displayName + "-indesign.log", true);
		retVal = processJob(graphicFolderBasePath, inDesignFilePath, overviewData, textframeData, storyData, staticData, dynamicData, outputPathSansExt);
		closeLogFile();
	}

	else {exit()}
	return retVal;
}



function makeOutputPath(inDesignFilePath, outputFolderPath, outputBasename) {
	var inDesignFile = new File(inDesignFilePath);
	if (typeof outputFolderPath === "undefined")
		var outputFolderPath = "";
	if (typeof outputBasename === "undefined")
		var outputBasename = "";
	if (outputFolderPath == "")
		outputFolderPath = inDesignFile.parent.fsName;
	if(outputFolderPath.charAt(outputFolderPath.length - 1) != '/') {
		outputFolderPath += '/';
	}
	if (outputBasename == "") {
		var today = new Date();
		outputBasename = "report";
		outputBasename = outputBasename.concat("_",today.getFullYear(),("0"+(today.getMonth()+1)).slice(-2),("0"+today.getDate()).slice(-2),("0"+today.getHours()).slice(-2),("0"+today.getMinutes()).slice(-2),("0"+today.getSeconds()).slice(-2));
	}
	var outputPathSansExt = outputFolderPath + outputBasename;
	return outputPathSansExt;
}
