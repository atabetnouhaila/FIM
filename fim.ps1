# Function to calculate the hash of a file using the SHA512 algorithm
Function Get-File-Hash($filePath) {
    $hashValue = Get-FileHash -Path $filePath -Algorithm SHA512
    return $hashValue
}

# Function to remove an existing baseline file, if found
Function Remove-Existing-Baseline() {
    $baselinePath = ".\baseline.txt"
    if (Test-Path -Path $baselinePath) {
        Remove-Item -Path $baselinePath
    }
}

# Define the directory path
$directoryPath = "C:\Users\atabe\OneDrive\Documents\FIM"

# Display user options
Write-Host "`nSelect an option:"
Write-Host "    1) Create new baseline"
Write-Host "    2) Monitor files using existing baseline"
$selection = Read-Host -Prompt "Enter '1' or '2'"
Write-Host ""

# If the user chooses to create a new baseline
if ($selection -eq "1") {
    # Remove old baseline if it exists
    Remove-Existing-Baseline

    # Check if the directory exists
    if (-not (Test-Path -Path $directoryPath)) {
        Write-Host "Directory $directoryPath does not exist. Please create the directory or update the path."
        exit
    }

    # Collect and hash all files in the specified directory, saving results in baseline.txt
    $fileList = Get-ChildItem -Path $directoryPath
    foreach ($file in $fileList) {
        $hash = Get-File-Hash $file.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }

    Write-Host "Baseline created successfully at .\baseline.txt" -ForegroundColor Green

# If the user chooses to start monitoring based on an existing baseline
} elseif ($selection -eq "2") {
    # Check if the baseline file exists
    if (-not (Test-Path -Path .\baseline.txt)) {
        Write-Host "Baseline file does not exist. Please create a baseline first."
        exit
    }

    $fileHashes = @{}

    # Load baseline data from the file and store file paths and hashes in a dictionary
    $baselineData = Get-Content -Path .\baseline.txt
    foreach ($line in $baselineData) {
        $splitLine = $line.Split("|")
        $fileHashes[$splitLine[0]] = $splitLine[1]
    }

     Write-Host "Monitoring started. Press Ctrl+C to stop." -ForegroundColor Yellow

    # Continuous file monitoring loop
    while ($true) {
        Start-Sleep -Seconds 1

        # Check if the directory exists
        if (-not (Test-Path -Path $directoryPath)) {
            Write-Host "Directory $directoryPath does not exist. Please check the path."
            exit
        }

        # Check all files in the specified directory
        $currentFiles = Get-ChildItem -Path $directoryPath
        foreach ($file in $currentFiles) {
            $hash = Get-File-Hash $file.FullName

            # Check if it's a new file
            if (-not $fileHashes.ContainsKey($hash.Path)) {
                Write-Host "$($hash.Path) is a new file!" -ForegroundColor yellow
            } else {
                # Check if the file has changed
                if ($fileHashes[$hash.Path] -ne $hash.Hash) {
                    Write-Host "$($hash.Path) has been modified!" -ForegroundColor purple
                }
            }
        }

        # Check for deleted files in the baseline
        foreach ($baselineFile in $fileHashes.Keys) {
            if (-not (Test-Path -Path $baselineFile)) {
                Write-Host "$($baselineFile) has been removed!" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "Invalid selection. Please enter '1' or '2'."
}
