<# 
 BinToUf2.ps1
 zigzagjoe 2024 

Used to convert one or more files to .UF2 file format.
Usage: Bin2UF2.ps1 -Files "File1"[,"File2"] -Outdir "Folder"

Will interactively ask for files if no arguments provided.

based on uf2conv.py (https://github.com/microsoft/uf2)
#>
param (
    [string[]]$files,
    [string]$Outdir = $null
)

#########################################
# Config
#########################################

# values for ISP-SIMM
$startAddress = 0               # for Macintosh ROM
$familyID = 0x10C68030          # ISP-SIMM

# prompt for input files if none provided on command line
$uiModeAllowed = $true

# automatically set folder picker to this volume, if found
$autoSelectDevice = "ISP-SIMM"

#########################################
# Constants
#########################################
 
# UF2 Consts
$UF2_MAGIC_START0 = 0x0A324655  # "UF2"
$UF2_MAGIC_START1 = 0x9E5D5157  # Randomly selected
$UF2_MAGIC_END    = 0x0AB16F30  # Ditto

#########################################
# Functions 
#########################################

# Show a file picker
Function Prompt-OpenFile($Title="Open Files", $Path = 'Desktop') {
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog

    if ($Path) {
        $FileBrowser.InitialDirectory = $Path
    }

    $FileBrowser.Multiselect = $true;
    $FileBrowser.Title = $Title
    if ($FileBrowser.ShowDialog() -ne "OK") {
        return @();
    }
    
    if ($FileBrowser.FileNames) {
        return $FileBrowser.FileNames;
    }

    return @();
}

# Show a folder picker
Function Prompt-Folder($Title="Select a folder", $Path = "") {

    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = $Title
    $browser.rootfolder = "MyComputer"

    if ($Path) {
        $browser.SelectedPath = $Path
    }

    if($browser.ShowDialog() -eq "OK") {
        return $browser.SelectedPath
    }

    return $null;
}

Function Log-Line($Str) {
    Write-Host $Str;
    $global:log += "$str`r`n"
}

#########################################
# globals
#########################################

$global:log = ""
$uiMode = $false
$errors = 0

#########################################
# Main code 
#########################################

Log-Line "Bin2UF2.ps1 by zigzagjoe v1.0`r`n"

# no files provided, try showing a dialog
if (!$files) {
    Write-host "Usage: Bin2UF2.ps1 -Files `"File1`"[,`"File2`"] -Outdir `"Folder`""
    
    if ($uiModeAllowed) {
        Write-host "Showing a dialog to ask for files."
        $files = Prompt-OpenFile "Select ROM files to convert..."
        if ($files.Count) {
            $uiMode = $true
        }
    }
}

# prompt for usage
if (!$files -or ($files.Count -eq 0)) {
    Write-host "No files selected to convert, exiting."  
    Exit 1 
}


if (! $Outdir -and $uiMode) {
	# suggest the device path if present
	# doesn't seem to work - bug in folder picker dialog?
	if ($autoSelectDevice) {
		$dr = gwmi Win32_LogicalDisk | ? {$_.VolumeName -eq $autoSelectDevice} | Select -ExpandProperty DeviceID -First 1
		if ($dr) {
			$Outdir = $dr + '\'
		}
	}

	# didn't find the dir / disabled? suggest the path from the input files
	if (! $Outdir) {
		$Outdir = [System.IO.Path]::GetDirectoryName(($files | Select -First 1));
	}

	$Outdir = Prompt-Folder "Select output directory" $Outdir
	if (! $Outdir) { # cancel
		exit 1
	}
} 
	
if (! $Outdir) { # cancel
		 Write-host "Please provide output directory with -Outdir or use -Outdir auto to search for $autoSelectDevice"
	exit 1
}

if ($Outdir -eq "auto") {
	write-host "Searching for $($autoSelectDevice) drive"
    $dr = gwmi Win32_LogicalDisk | ? {$_.VolumeName -eq $autoSelectDevice} | Select -ExpandProperty DeviceID -First 1
	if ($dr) {
		
        $Outdir = $dr + '\'
	} else {
		write-host "Unable to locate $($autoSelectDevice): upload failed."
		exit 1
	}
}

Log-Line "Output directory: $Outdir`r`n"

$files.ForEach({
    $file = $_
    $shortName = [System.IO.Path]::GetFileName($file);
    $newfile = ([System.IO.Path]::GetFileNameWithoutExtension($file) + ".uf2")

    Log-Line "Process $shortName"

    
    try {
        $file_content = [System.IO.File]::ReadAllBytes($file)

        if ([System.BitConverter]::ToUInt32($file_content,0) -eq $UF2_MAGIC_START0) {
            Log-Line "$shortname is already UF2, not processing it"
            $errors++;
            continue;
        }

        $fileStream = [System.IO.FileStream]::new($Outdir + '\' + $newfile, "Create")
		
        $numblocks = ($file_content.Length + 0xFF) -shr 8
    
        foreach ($blockno in @(0..($numblocks - 1))) {
            $ptr = 0x100 * $blockno
            $chunk = $file_content[$ptr..($ptr + 0xFF)]
            $flags = 0
            if ($familyID) {
                $flags = $flags -bor 0x2000
            }

            $data = @(
                    [System.BitConverter]::GetBytes([Int32]$UF2_MAGIC_START0),
                    [System.BitConverter]::GetBytes([Int32]$UF2_MAGIC_START1),
                    [System.BitConverter]::GetBytes([Int32]$flags),
                    [System.BitConverter]::GetBytes([Int32]($ptr + $startAddress)),
                    [System.BitConverter]::GetBytes([Int32]256),
                    [System.BitConverter]::GetBytes([Int32]$blockno),
                    [System.BitConverter]::GetBytes([Int32]$numblocks),
                    [System.BitConverter]::GetBytes([Int32]$familyID),
                    $chunk,
                    (@([Byte]0x00) * (0x200 - (32 + $chunk.Length + 4))),
                    [System.BitConverter]::GetBytes([Int32]$UF2_MAGIC_END)
                ) | ForEach-Object { $_ }
		
            $fileStream.Write($data, 0, 512)
        }

        Log-Line "Wrote $numblocks UF2 blocks"
    } catch {
        Log-Line ("Error: " + $_)
        $errors++
    } finally {
        if ($fileStream) {
            $fileStream.Close();
        }
    }
})

Write-host "Done."

if (! $uiMode) {
    Exit $error
} else {
    $msgBody = $log
    $icon = "Information"

    if ( $errors) {
        $icon = "Exclamation"
        $log = "$errors errors occurred: `r`n$log"
    }

    [System.Windows.Forms.MessageBox]::Show($msgBody,"UF2 Result","OK", $Icon) | Out-Null
}

