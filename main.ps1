$CFG_NAME = "backup.json"
$KEY_FULLDIR = "backup_fulldir"
$KEY_SEARCHED = "backup_search_specific"
$SEARCH_REGEX = ".*\.bkp.*"


# Returns all content from json file as hashtable
function Get-JsonData {
    param (
        $FilePath
    )

    return (Get-Content -Raw $FilePath | ConvertFrom-Json -AsHashtable)
}


# Returns array with drive letters
function Get-DriveLetters {
    return (Get-PSDrive -PSProvider FileSystem).Name -match '^[a-z]$'
}


# Returns all available config paths
function Get-ConfigPaths {
    return Get-DriveLetters | ForEach-Object {
        $path = ($_ + ":\" + $CFG_NAME)
        if(Test-Path $path) {
            Write-Output $path
        }
    }
}


# Returns paths from single json section as array
# Converts relative paths to absolute by adding drive letter
# Paths in json file MUST be relative to drive root without any prefixes
# like "dir1/dir2/"
function Get-JsonSectionPaths {
    param (
        $SectionName, # Section in json file
        $JsonPath # Path to json file
    )

    return (Get-JsonData $JsonPath)[$SectionName] | ForEach-Object {
        # Append drive letter
        Write-Output ($JsonPath.substring(0, 3) + $_)
    }
}


# Returns array with paths to full backup (copy whole directory)
function Get-BackupFulldirPaths {
    return Get-ConfigPaths | ForEach-Object {
        Write-Output (Get-JsonSectionPaths -SectionName $KEY_FULLDIR -JsonPath $_)
    }
}


# Returns hashtable of filtered paths to backup
function Get-BackupSearchedPaths {
    $result = @()

    foreach($cfgPath in Get-ConfigPaths) {
        $dirPaths = (Get-JsonSectionPaths -SectionName $KEY_SEARCHED -JsonPath $cfgPath)

        foreach($dir in $dirPaths) {
            if(-Not (Test-Path $dir)) {
                continue
            }

            $result += (
                (Get-ChildItem -Path $dir -Recurse | Where-Object { $_.FullName -match $SEARCH_REGEX })
                | ForEach-Object { Write-Output $_.FullName }
            )
        }

    }

    return $result
}

