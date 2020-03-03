# PowerApps-and-PowerAutomate-Solution-Replace
Use PowerShell to replace data such as Connectors information into PowerApps and PowerAutomate Solution.zip

More information : http://www.ludovicperrichon.com/change-data-into-powerapps-and-powerautomate-solution-zip/

HOW TO USE IT:
Two inputs,
jsonPath : The path to JSON containing the values to replace (Example : https://github.com/ludovicperrichon/PowerApps-and-PowerAutomate-Solution-Replace/blob/master/replaceExample.json)
solutionPath : The path to the .zip solution package from PowerApps or PowerAutomate.

Script is going to create a Output and a Temp folder.
cd to the folder where you want Ouput and Temp to be created and then run the script:
.\SolutionReplace.ps1 -jsonPath "MY JSON PATH" -solutionPath "MY SOLUTION .ZIP PATH"

Please note:
For a better use, your json file with value to change must contains at least:
- The old and new SharePoint site url
- The old and new SharePoint site Title
- The old and new SharePoint List ID
- The old and new Solution name
- If Flow : The old and new SharePoint Content type ID
