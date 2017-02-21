<#
.SYNOPSIS
   RABID - Risk Application Binaries Informal Deploy
   Verifies RiskApplication binaries on servers


.DESCRIPTION
    The script will verify the RiskApplication binaries compared to a LOCAl verified copy
    
    Note: Get-FileHash cmdlet requires PowerShell version 4.0 or later


.PARAMETER source
    Path to the RiskApplications binaries
    Default = '.\src\RiskApplications.MASTER'


.PARAMETER servers
    Path to a file that contains server ids


.EXAMPLE
   .\rabid_verify.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt
    No STDOUT output displayed if the script is succesful

.EXAMPLE
   .\rabid_verify.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt -Debug
    Output will include Debug logging


.EXAMPLE
   .\rabid_verify.ps1 -source d:\rabid_deploy\src\RiskApplications.Master -servers d:\rabid_deploy\RiskServerList.txt 5>d:\rabid_deploy\debugRabid-Log.log
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
Set-Variable RABID_DATE_STAMP -Value (Get-Date -Format yyyy-MM-dd-hh-mm) -Option ReadOnly -Force

# log file name
Set-Variable RABID_LOG_FILE -Value ([String]"$PSScriptRoot\hash\RABID_HASH_$RABID_DATE_STAMP.log") -Option ReadOnly -Force

# header for log initilization
Set-Variable RABID_LOG_HEADER -Value ([String]"-- R.A.B.I.D Verify INITIALIZE --") -Option ReadOnly -Force

Set-Variable RABID_LOG_FOOTER -Value ([String]"-- R.A.B.I.D Verify TERMINATE --") -Option ReadOnly -Force

# risk application hash file path with file prefix
Set-Variable RABID_HASH -Value ([String]"$PSScriptRoot" + "\hash\RABID_HASH_") -Option ReadOnly -Force

# risk application source folder, this src folder should be retrieved via SVN
Set-Variable RABID_SRC_PATH -Value ([String]$source) -Option ReadOnly -Force

# risk application backup path
# risk application path on application servers
Set-Variable RABID_REMOTE_X86_PATH -Value ([string]"D$\Openlink\Endur\V14_0_08082015ENB_12212015_1081\bin") -Option ReadOnly -Force

# risk application path on application servers
Set-Variable RABID_REMOTE_X64_PATH -Value ([string]"D$\Openlink\Endur\V14_0_08082015ENB_12212015_1081\bin.win64") -Option ReadOnly -Force

# risk application folder name on application servers
Set-Variable RABID_FOLDER_NAME -Value ([string]"RiskApplications") -Option ReadOnly -Force

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

    $hash_source = $RABID_HASH + 'LOCAL.log'
    $hash_remote = "$RABID_HASH$Server.log"

    if(!($hash_remote | Test-Path))
    { 
        Rabid-Hash -Server $server
    }   

    If(Compare-Object -ReferenceObject $(Get-Content $hash_source) -DifferenceObject $(Get-Content $hash_remote))
    {
        Rabid-Log -message "Hash files from $Server do not match SOURCE Hash file" -server $Server -level INFO
    }
    else
    {
         Rabid-Log -message "Verification Succesful, Hash files from $Server match SOURCE Hash file" -server $Server -level INFO      
    }
}

# create_hash
Function Rabid-Hash()
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [string]
        $Server
    )
    
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        if (!($Server)){ $Server = 'LOCAL' }

        Rabid-Log -message "Creating hash file" -server $server

        $hash_file = $RABID_HASH + $Server + '.log'
        if($hash_file | Test-Path) { Remove-Item $hash_file -Force }
    
        if (!($Server -eq "LOCAL"))
        {
            $source = "\\$Server\$RABID_REMOTE_X64_PATH\$RABID_FOLDER_NAME"
        }
        
        echo $source

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

### MAIN ###
Rabid-Hash
$content = Get-IniContent $servers
$content["ra_verify"]["servers"].Split(",") | % {
    $server = $_.ToUpper()
    Rabid-Hash -Server $server
    Rabid-Verify -Server $server
}