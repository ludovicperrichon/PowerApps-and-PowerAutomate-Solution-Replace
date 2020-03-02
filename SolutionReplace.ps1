Param (
   [string] $jsonPath,
   [string] $solutionPath
)

# Need to encode in proper UTF8
$locationPath = (Get-Location).Path
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.Environment]::CurrentDirectory = $locationPath

# Global Var
$solutionName = [System.IO.Path]::GetFileNameWithoutExtension($solutionPath)
$strNow = Get-Date -Format "yyyyMMdd_HHmm"
$newSolutionFolder = "$($solutionName)_$($strNow)"

# Get JSON
$json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json 

# Functions
# =====> Replace content for a specific file
function ReplaceValue {
    param([string]$path)
    $content = Get-Content -path "$path" -Raw -Encoding UTF8
    $strContent = $content
    foreach($value in $json){
        $strContent = $strContent.Replace($value.old, $value.new)
    }
    
    return $strContent
}

# ====> Edit file, replace value and export it as encoded utf8
function EditFileTemplate {
    param( [string]$path )
    $valuereplaced = ReplaceValue -path $path
    
    [System.IO.File]::WriteAllLines($path, $valuereplaced, $Utf8NoBomEncoding)
}

# ====> Parsing file and folder
function ParseFilesNFolders{
    param([string]$thisFolder)
    Write-Host "Parsing $thisFolder ..."
    $folderContent = Get-ChildItem -Path $thisFolder
    foreach($content in $folderContent){
        if($content.GetType() -eq [System.IO.DirectoryInfo]){
            ParseFilesNFolders -thisFolder "$thisFolder\$content"
        }
        else{
            $ext = [System.IO.Path]::GetExtension($content)
            Switch($ext){
                ".json"{
                    Write-Host "Replacing value in $thisFolder\$content"
                    EditFileTemplate "$thisFolder\$content"
                    Write-Host "$thisFolder\$content done" -ForegroundColor Green
                }
                ".msapp"{
                    Write-Host "Temporary extract msapp file"
                    $msappFileName = [System.IO.Path]::GetFileNameWithoutExtension("$thisFolder\$content")
                    New-Item -Path ".\Temp\$newSolutionFolder" -Name $msappFileName -ItemType "directory" | Out-Null

                    Copy-Item "$thisFolder\$content" -Destination ".\Temp\$newSolutionFolder\$content"
                    Rename-Item ".\Temp\$newSolutionFolder\$content" "$msappFileName.zip"

                    Expand-Archive ".\Temp\$newSolutionFolder\$msappFileName.zip" -DestinationPath ".\Temp\$newSolutionFolder\$msappFileName"
                    Write-Host "Exctracted into .\Temp\$newSolutionFolder\$msappFileName"
                    Remove-Item -Path ".\Temp\$newSolutionFolder\$msappFileName.zip" -Force
                    Remove-Item -Path "$thisFolder\$content" -Force

                    ParseFilesNFolders -thisFolder ".\Temp\$newSolutionFolder\$msappFileName"

                    Write-Host "Compress .\Temp\$newSolutionFolder\$msappFileName folder and save it into $thisFolder"
                    Compress-Archive -Path ".\Temp\$newSolutionFolder\$msappFileName\*" -DestinationPath "$thisFolder\$msappFileName.zip"
                    Write-Host "Rename $msappFileName.zip into $content"
                    Rename-Item "$thisFolder\$msappFileName.zip" "$content"
                    Write-Host "$content regenerated" -ForegroundColor Green

                }
                Default{
                    Write-Host "Default : $ext"
                }
            }
        }
    }
}

################
#### SCRIPT ####
################

try{
    #Check if Output and Temp folder exist
    Write-Host "Check if Output folder exist"
    If(Test-Path ".\Output"){
        Write-Host "Output folder exist" -ForegroundColor Green
    }
    else{
        Write-Host "Output folder doesn't exist, creation in progress" -ForegroundColor Yellow
        New-Item -Path ".\" -Name "Output" -ItemType "directory" | Out-Null
        Write-Host "Output file created" -ForegroundColor Green
    }

    Write-Host "Check if Temp folder exist"
    If(Test-Path ".\Temp"){
        Write-Host "Temp folder exist" -ForegroundColor Green
    }
    else{
        Write-Host "Temp folder doesn't exist, creation in progress" -ForegroundColor Yellow
        New-Item -Path ".\" -Name "Temp" -ItemType "directory" | Out-Null
        Write-Host "Temp file created" -ForegroundColor Green
    }

    Write-Host ""

    #Get zip file name and create folder in Output Temp file
    Write-Host "Creating folder $newSolutionFolder in Output"
    New-Item -Path ".\Output" -Name $newSolutionFolder -ItemType "directory" | Out-Null
    Write-Host "$newSolutionFolder created in $locationPath\Output" -ForegroundColor Green
    Write-Host "Creating folder $newSolutionFolder in Temp"
    New-Item -Path ".\Temp" -Name $newSolutionFolder -ItemType "directory" | Out-Null
    Write-Host "$newSolutionFolder created in $locationPath\Temp" -ForegroundColor Green
    Write-Host ""

    #Unzip solution
    Write-Host "Get and unzip solution..."
    Expand-Archive $solutionPath -DestinationPath ".\Output\$newSolutionFolder"
    Write-Host "Unzipped in $locationPath\Output\$newSolutionFolder" -ForegroundColor Green
    Write-Host ""

    #Parse folder solution
    Write-Host "Parse file and folder in .\Output\$newSolutionFolder"

    ParseFilesNFolders -thisFolder ".\Output\$newSolutionFolder"

    Write-Host ""

    #Rebuild solution
    Write-Host "Rebuild solution"
    Compress-Archive -Path ".\Output\$newSolutionFolder\*" -DestinationPath ".\Output\$newSolutionFolder.zip"

    Write-Host "New solution:" -ForegroundColor Green
    Write-Host "$locationPath\Output\$newSolutionFolder.zip"-BackgroundColor DarkGreen

}
catch{
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

$t = Read-Host "Press enter to exit..."