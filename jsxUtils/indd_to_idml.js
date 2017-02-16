/**
 * Created by astangl on 11/22/16.
 */
// Convert INDD TO IDML

#target indesign


main();

function main() {
    retVal = "Done";
    var theScriptFolderPath = $.fileName.split(";")[0];
    var theScriptFolder = new Folder(theScriptFolderPath);
    var theFilePath = theScriptFolder.parent.fsName;
    var theFileFolder = new Folder(theFilePath);
    myFiles(theFileFolder, theFilePath);
    app.quit();
    return retVal;
}


function myFiles(dir, path) {
     // Inhibit the UserInterface For Processing
    inhibitUI();
    var retVal = "FAILURE";
    var inFolder = dir;
    if(inFolder != null) {
        // Set the file list array and filter based on indd suffix
        var inddFiles = inFolder.getFiles(/\.(indd)$/i);
    }

    // Loop through all of the files in the directory
    for(var indCount=0; indCount < inddFiles.length; indCount++) {


        // Set the PDF Export Preferences
        // var initialPDFExportPrefs = app.pdfExportPreferences.properties;
        // app.pdfExportPreferences.pageRange = PageRange.ALL_PAGES;
        // app.pdfExportPreferences.includeHyperlinks = true;

        var myPresets = app.pdfExportPresets.everyItem().name;


        // Set the IDML Name
        var tempName = inddFiles[indCount].fsName.split(".")[0];
        var idmlFile = new File(tempName + ".idml");
        var pdfFile = new File(tempName + ".pdf");
        // Set the active document and open based on counter of the loop
        var aDoc = app.open(File(inddFiles[indCount]), true);

        // Update Links -- Incase they are not updated
        aDoc.links.everyItem().update();

        // Export the IDML File
        aDoc.exportFile(ExportFormat.INDESIGN_MARKUP, idmlFile);

        // Export PDF
        aDoc.exportFile(ExportFormat.PDF_TYPE, pdfFile);

        // Save the INDD File
        aDoc.save(inddFiles[indCount].fsName);

        // Close the INDD FILE
        aDoc.close();

    }
    restoreUI();
    return retVal;
}

var oldRedraw;
var oldInteractionLevel;
function inhibitUI() {
		oldRedraw = app.scriptPreferences.enableRedraw;
		oldInteractionLevel = app.scriptPreferences.userInteractionLevel;
		app.scriptPreferences.enableRedraw = false;
		app.scriptPreferences.userInteractionLevel = UserInteractionLevels.NEVER_INTERACT;

}

function restoreUI() {
		app.scriptPreferences.enableRedraw = oldRedraw;
		app.scriptPreferences.userInteractionLevel = oldInteractionLevel;

}

