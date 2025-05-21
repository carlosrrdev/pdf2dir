function Start-PdfToDir {
    param(
        [Parameter(Mandatory=$true)]
        [String]$InPath,

        [Parameter(Mandatory=$true)]
        [String]$OutPath
    )
    # Ensure the output directory exists
    if (!(Test-Path -Path $OutPath)) {
        New-Item -ItemType Directory -Path $OutPath -Force | Out-Null
        Write-Host "Created output directory: $OutPath"
    }

    # Get all PDF files in the input directory
    $pdfFiles = Get-ChildItem -Path $InPath -Filter "*.pdf" -File

    if ($pdfFiles.Count -eq 0) {
        Write-Host "No PDF files found in $InPath"
        return
    }

    Write-Host "Found $($pdfFiles.Count) PDF files to process"

    foreach ($pdf in $pdfFiles) {
        # Get the filename without extension and convert to uppercase
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($pdf.Name)
        $upperCaseFileName = $fileNameWithoutExtension.ToUpper()

        # Generate a random 4-digit number
        $randomNumber = Get-Random -Minimum 1000 -Maximum 10000

        # Create the directory name with the random number appended (with underscore)
        $dirName = "{0}_{1}" -f $upperCaseFileName, $randomNumber


        # Create the target directory path
        $targetDirPath = Join-Path -Path $OutPath -ChildPath $dirName

        # Create the target directory if it doesn't exist
        if (!(Test-Path -Path $targetDirPath)) {
            New-Item -ItemType Directory -Path $targetDirPath -Force | Out-Null
            Write-Host "Created directory: $targetDirPath"
        }

        # Construct the destination path for the PDF file
        $destinationPath = Join-Path -Path $targetDirPath -ChildPath $pdf.Name

        # Move the PDF file to the target directory
        Move-Item -Path $pdf.FullName -Destination $destinationPath -Force
        Write-Host "Moved $($pdf.Name) to $destinationPath"
    }

    Write-Host "PDF processing completed successfully"
}

$propertiesFilePath = "paths.properties"

if (!(Test-Path $propertiesFilePath)) {
    Write-Error "Properties file not found at: $propertiesFilePath"
    exit 1
}

$properties = @{}

Get-Content $propertiesFilePath | ForEach-Object {
    if (!$_.StartsWith("#") -and $_.Trim() -ne "") {
        $key, $value = $_ -split '=', 2
        if ($key -and $value) {
            $properties[$key.Trim()] = $value.Trim()
        }
    }
}

$intakePath = $properties["intake_path"]
$outputPath = $properties["output_path"]

Write-Host "Paths have been loaded"
Write-Host "Intake path: $intakePath"
Write-Host "Output path: $outputPath"

$userContinue = Read-Host "Continue with the script? (Y/N)"

if($userContinue.ToUpper() -eq "Y" -or $userContinue.ToUpper() -eq "YES") {
    Start-PdfToDir -InPath $intakePath -OutPath $outputPath
} else {
    exit 0
}
