<#
.SYNOPSIS
   RABID - Risk Application Binaries Informal Deploy
   Deploys the RiskApplications binaries to MRM Systems


.DESCRIPTION
    The script will deploy the RiskApplications folder from SVN
    to each od the servers listed in serverList.txt
   
    The current RiskApplication folder on the server will be backed up
    and stored on a file share.
   
    File hash verification is done after the deployment has completed
    to ensure the integrity of all files transferred.
      
    Note: Get-FileHash cmdlet requires PowerShell version 4.0 or later


.PARAMETER source
    Path to the RiskApplications binaries
    Default = '.\src\RiskApplications.MASTER'


.PARAMETER servers
    Path to a file that contains server ids


.EXAMPLE
   .\rabid_deploy.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt
    No STDOUT output displayed if the script is succesful

.EXAMPLE
   .\rabid_deploy.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt -Debug
    Output will include Debug logging


.EXAMPLE
   .\rabid_deploy.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt 5>d:\rabid_deploy\debugRabid-Log.log
    No STDOUT output, but debug log will be created and populated.


.NOTES
    Author: LivITy Consulting Ltd., Kevin Edwards (http://www.livity.consulting)  
    Version: 0.0.1
    LEGAL: Copyright Enbridge Inc.
#>
[CmdletBinding()]

param (
    [string]$source = 'src\RiskApplications.MASTER',
    [string]$servers = 'RABIDServers.ini'
)

### constants

$source = "$PSScriptRoot\$source"
$servers = "$PSScriptRoot\$servers"

# date stamp for log file
Set-Variable RABID_DATE_STAMP -Value (Get-Date -Format yyyy-MM-dd) -Option ReadOnly -Force

# log file name
Set-Variable RABID_LOG_FILE -Value ([String]"$PSScriptRoot\RABID_$RABID_DATE_STAMP.log") -Option ReadOnly -Force

# header for log initilization
Set-Variable RABID_LOG_HEADER -Value ([String]"-- R.A.B.I.D INITIALIZE --") -Option ReadOnly -Force

Set-Variable RABID_LOG_FOOTER -Value ([String]"-- R.A.B.I.D TERMINATE --") -Option ReadOnly -Force

# risk application hash file path with file prefix
Set-Variable RABID_HASH -Value ([String]"$PSScriptRoot" + "\hash\RABID_HASH_") -Option ReadOnly -Force

# risk application source folder, this src folder should be retrieved via SVN
Set-Variable RABID_SRC_PATH -Value ([String]$source) -Option ReadOnly -Force

# risk application backup path
Set-Variable RABID_BACKUP_PATH -Value ([String]"$PSScriptRoot\") -Option ReadOnly -Force

# risk application path on application servers
Set-Variable RABID_REMOTE_X86_PATH -Value ([string]"D$\Openlink\Endur\V14_0_08082015ENB_12212015_1081\bin") -Option ReadOnly -Force

# risk application path on application servers
Set-Variable RABID_REMOTE_X64_PATH -Value ([string]"D$\Openlink\Endur\V14_0_08082015ENB_12212015_1081\bin.win64") -Option ReadOnly -Force

# risk application folder name on application servers
Set-Variable RABID_FOLDER_NAME -Value ([string]"RiskApplications") -Option ReadOnly -Force

# location to the source zip, built from SVN?
Set-Variable RABID_SRC_ZIP -Value ([String]"$source.zip") -Option ReadOnly -Force

# remote service
Set-Variable RABID_SERVICE -Value ([string]'OpenLink_Endur_DailyDev') -Option ReadOnly -Force


### Assemblies

# required for zip functionality
Add-Type -assembly 'system.io.compression.filesystem'


### Functions

# simple logging
function Rabid-Log
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]
        $message,
        
        [Parameter(Mandatory=$False)]
        [ValidateSet("INFO","WARN","ERRR","FATL","DEBG")]
        [String]
        $level = "INFO",

        [Parameter(Mandatory=$False)]
        [String]
        $server
    )

    $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    if ($server)
    {
        $line = "$stamp $PID $level [$server] $message"
    }
    else
    {
        $line = "$stamp $PID $level $message"
    }
    
    Add-Content $RABID_LOG_FILE -Value $line
    Write-Debug $message
}


Function Rabid-Terminate()
{
    Rabid-Log -message $RABID_LOG_FOOTER
}


# export from SVN
Function Rabid-SVN()
{
    # 
    # Given an SVN URL and local directory path, this script copies all files from
    # SVN into the specified local directory.
    #
    # Uses SharpSVN DLL v1.7002.1998 (Documentation : http://docs.sharpsvn.net/current/)
    #
    # Takes two command line arguments, an SVN URL and a local directory path.
    #
    [CmdletBinding()]

    param (
        [string]$svnUrl       = $(read-host "Please specify the path to SVN"),
        [string]$svnLocalPath = $(read-host "Please specify the local path"),
        [string]$svnUsername  = $(read-host "Please specify the username"),
        [string]$svnPassword  = $(read-host "Please specify the password")
    )

    if ([System.IO.Path]::IsPathRooted($svnLocalPath) -eq $false)
    {
        throw "Please specify a local absolute path"
    }

    # Sets IO directory to location of script
    $currentScriptDirectory = Get-Location
    [System.IO.Directory]::SetCurrentDirectory($currentScriptDirectory.Path)
    
    # Needed in some cases to load the DLL, Load SharpSVN DLL
    $evidence = [System.Reflection.Assembly]::GetExecutingAssembly().Evidence
    [Reflection.Assembly]::LoadFile(($currentScriptDirectory.Path + "SharpSvn.dll"), $evidence)
    
    # checkout from SVN
    $svnClient = new-object SharpSvn.SvnClient
    $repoUri = new-object SharpSvn.SvnUriTarget($svnUrl)
    $svnClient.CheckOut($repoUri, $svnLocalPath)

    # Remove SVN metadata files from local directory
    gci $svnLocalPath -include .svn -Recurse -Force | Remove-Item -Recurse -Force
}


# verification of hash files
Function Rabid-Verify()
{
    [CmdletBinding()] 
    
    Param (
        [Parameter(Mandatory=$True)]
        [string]
        $Server
    )

    Rabid-Log -message "Verifying Hash files with LOCAL Hash file" -server $server

    $remote_path_32 = "\\$Server\$RABID_REMOTE_X86_PATH"
    $remote_path_64 = "\\$Server\$RABID_REMOTE_X64_PATH"
        
    if("$remote_path_32" | Test-Path)
    {
        $remote_path = $remote_path_32
        
    }
    elseif("$remote_path_64" | Test-Path)
    {
        $remote_path = $remote_path_64
    }
    
    $remote_src_name = "$remote_path\RiskApplications.MASTER"
    $remote_new_name = $RABID_FOLDER_NAME
    
    $hash_source = $RABID_HASH + 'LOCAL.log'
    
    Rabid-Hash -Server $server
    
    $hash_remote = "$RABID_HASH$Server.log"

    If(Compare-Object -ReferenceObject $(Get-Content $hash_source) -DifferenceObject $(Get-Content $hash_remote))
    {
        Rabid-Log -message "Hash files from $Server do not match SOURCE Hash file" -server $Server -level ERRR
        
        Remove-Item "$remote_src_name" -Force -Recurse

        throw "ERROR: Hash files from $Server do not match SOURCE Hash file"
    }
    else
    {
         Rabid-Log -message "Verification Succesful, Renaming folder" -server $Server
         
         Remove-Item "$remote_path\$remote_new_name" -Force -Recurse
         Rename-Item -Path $remote_src_name -NewName $remote_new_name #-WhatIf # TOD0: remove -WhatIf
         
    }
}


# deploy 
Function Rabid-Deploy()
{
    [CmdletBinding()] 
    
    Param(
        [Parameter(Mandatory=$True)]
        [string]
        $Server
    )

    Rabid-Log "Depoying RiskApplications binaries" -server $Server
    
    $remote_path_32 = "\\$Server\$RABID_REMOTE_X86_PATH"
    $remote_path_64 = "\\$Server\$RABID_REMOTE_X64_PATH"
        
    if("$remote_path_32" | Test-Path)
    {
        $remote_zip = "$remote_path_32\$RABID_FOLDER_NAME.zip"
        $remote_path = $remote_path_32
        
    }
    elseif("$remote_path_64" | Test-Path)
    {
        $remote_zip = "$remote_path_64\$RABID_FOLDER_NAME.zip"
        $remote_path = $remote_path_64
    }

    if (-not ($RABID_SRC_ZIP | Test-Path)){
        $compression_level = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($source, $RABID_SRC_ZIP, $compression_level, $false)
    }

    Copy-Item -Path $RABID_SRC_ZIP -Destination $remote_zip -Force
    [System.IO.Compression.ZipFile]::ExtractToDirectory($remote_zip, "$remote_path\RiskApplications.MASTER")
    
    Remove-Item $remote_zip -Force -Recurse
}



# backup payload and remove
Function Rabid-Backup ()
{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True)]
        [string]$Server
    )

    $remote_path_32 = "\\$Server\$RABID_REMOTE_X86_PATH"
    $remote_path_64 = "\\$Server\$RABID_REMOTE_X64_PATH"
        
    if("$remote_path_32" | Test-Path)
    {
        $remote_folder = "$remote_path_32\$RABID_FOLDER_NAME"
        
    }
    elseif("$remote_path_64" | Test-Path)
    {
        $remote_folder = "$remote_path_64\$RABID_FOLDER_NAME"
    }
        
    $remote_zip = $remote_folder + '_' + $Server + '_' + $RABID_DATE_STAMP + '.zip'

    if (-not ( $remote_folder | Test-Path))
    {
        Rabid-Log -message "RiskApplication folder $remote_folder does not exist to backup" -level WARN -server $server
    }
    else
    {
        Rabid-Log -message "RiskApplication folder $remote_folder found" -server $Server

        if ($remote_zip | Test-Path){ Remove-Item $remote_zip -Force }
        
        Rabid-Log -message "Backing up riskApplications folder to $RABID_BACKUP_PATH" -level INFO -server $Server
        
        $compression_level = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($remote_folder, $remote_zip, $compression_level, $false)
        
        # TODO: define where backups should be stored
        #Copy-Item -Path $remote_zip -Destination $RABID_BACKUP_PATH -Force
    }
}

# create_hash
Function Rabid-Hash()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [string]
        $server
    )
    
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        if (!($server)){ $server = 'LOCAL' }

        Rabid-Log -message "Creating hash file" -server $server

        $hash_file = $RABID_HASH + $server + '.log'
        if($hash_file | Test-Path) { Remove-Item $hash_file -Force }
    
        if ($server -eq "REMOTE")
        {
            $remote_path_32 = "\\$server\$RABID_REMOTE_X86_PATH"
            $remote_path_64 = "\\$server\$RABID_REMOTE_X64_PATH"
        
            if("$remote_path_32\riskApplications" | Test-Path)
            {
                $remote_folder = "\\$server\$RABID_REMOTE_X86_PATH\$RABID_FOLDER_NAME"
        
            }
            elseif("$remote_path_64\riskApplications" | Test-Path)
            {
                $remote_folder = "\\$server\$RABID_REMOTE_X86_PATH\$RABID_FOLDER_NAME"
            }
        
            $source = "\\$server\$remote_folder"
        }
    
        $files = Get-childitem -Path $source -Recurse -File -Force
        Foreach ($file in $files)
        {
            $hash = (Get-FileHash -Path $file.fullname -Algorithm MD5).hash       
            $line = "$file $hash"
            Add-Content -Path $hash_file -Value $line
        }
    }

    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

# Get-IniContent
Function Get-IniContent {  
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath,
        [char[]]$CommentChar = @(";")
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        $commentRegex = "^([$($CommentChar -join '')].*)$"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\s*\[(.+)\]\s*$" # Section
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0
                continue
            }  
            $commentRegex # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount++
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value
                
                continue 
            }   
            "(.+?)\s*=\s*(.*)" # Key
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

# initialize script
Function Rabid-Init() {
    Rabid-Log -message $RABID_LOG_HEADER
    
    if (-not ($servers | Test-Path))
    {
         $err_msg = "File $servers does not exist and is required."
         Rabid-Log -message $err_msg -level ERRR
         throw $err_msg
    }
}

Function Rabid-Update() {
    [CmdletBinding()]  
    param ([string]$Env)
     
    $answer = Read-Host "Confirm deploy to $Env servers: [y] or [n]: "
    while('y', 'n', 'Y', 'N' -notcontains $answer)
    {
	    $answer = Read-Host "Confirm deploy to $Env servers: [y] or [n]: "
    }

    #$a = new-object -comobject wscript.shell 
    #$answer = $a.popup("Do you wish to deploy to $Env servers?", 0, "Deploy to $Env", 4) 
    #If ($answer -eq 6) {     
    
    If ($answer -eq "y") {     
        $content = Get-IniContent $servers
        $content["$Env"]["servers"].Split(",") | % {
            $server = $_.ToUpper()
            Write-Host -NoNewline "Processing $server "
            Write-Host -NoNewline .
            #Rabid-Service -Server $server -Service $RABID_SERVICE -Status STOP
            #Write-Host -NoNewline .
            Rabid-Backup -Server $server
            Write-Host -NoNewline .
            Rabid-Deploy -Server $server
            Write-Host -NoNewline .
            Rabid-Verify -Server $server
            Write-Host .
            #_configure -Server $server
            #Write-Host .
            #Rabid-Service -Server $server -Service $RABID_SERVICE -Status START
        }
    }
    
}

Function Show-Menu
{
    [CmdletBinding()]  
    param ([string]$Title = 'R.A.B.I.D')
    cls
    Write-Host "================ $Title ================"
     
    Write-Host "    D: Press 'D' to deploy to $domain servers."
    Write-Host "    Q: Press 'Q' to Quit."
}

### MAIN ###
$domain = (Get-WmiObject Win32_ComputerSystem).Domain.Split('.')[0]
do
{
     Rabid-Init -Domain $domain.ToUpper()
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           'd' {
                cls
                Rabid-Hash
                Rabid-Update -Env $domain
           } 'HSH' {
                Write-Host -NoNewline 'Please wait creating LOCAL hash ...'                
                Rabid-hash
                Write-Host Done
           } 'BKP' {
                cls
                Write-Host 'Please wait while each server backup is processing ...'
                $content = Get-IniContent $servers
                $content["ra_deploy"]["cnpldev"].Split(",") | % {
                    $server = $_.ToUpper()
                    Write-Host backing up $server...
                    Rabid-Backup -Server $server
                }
           } 'RUN' {
                cls
                Write-Host 'Please wait while each server deploy is processing...'
                $content = Get-IniContent $servers
                $content["ra_deploy"]["cnpldev"].Split(",") | % {
                    $server = $_.ToUpper()
                    Write-Host deploying binaries to $server...
                    Rabid-Deploy -Server $server
               }
           } 'VER' {
                cls
               Write-Host 'Please wait while each server deploy is verified...'
                $content = Get-IniContent $servers
                $content["cnpldev"]["servers"].Split(",") | % {
                    $server = $_.ToUpper()
                    Write-Host verifying deploy to $server...
                    Rabid-Verify -Server $server
                }
           } 'q' {
                Rabid-Terminate
                return
           }
     }
     pause
}
until ($input -eq 'q')
