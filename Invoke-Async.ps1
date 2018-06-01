#Source: http://gallery.technet.microsoft.com/scriptcenter/Invoke-Async-Allows-you-to-83b0c9f0#content
<#
.Synopsis
   A means of running multiple instances of a cmdlet/function/scriptblock
.DESCRIPTION
   This function allows you to provide a cmdlet, function or script block with a set of data to allow multithreading.
 
.EXAMPLE
    $servers = Get-Content c:\_dblog\servers.txt
    $sb = [scriptblock] {param($HostName) Test-Connection -ComputerName $HostName} 
    $rtn = Invoke-Async -Set $servers -SetParam HostName  -ScriptBlock $sb -Verbose -Measure:$true
    $rtn
 
.EXAMPLE
   $sb = [scriptblock] {param($system) gwmi win32_operatingsystem -ComputerName $system | select csname,caption}
   $servers = Get-Content c:\_dblog\servers.txt
   $rtn = Invoke-Async -Set $servers -SetParam system  -ScriptBlock $sb
 
.EXAMPLE
   $servers = Get-Content servers.txt
   $rtn = Invoke-Async -Set $servers -SetParam computername -Params @{count=1} -Cmdlet Test-Connection -ThreadCount 50 
 
.EXAMPLE
    #This example shows how to pass extra parameters other than the collection to iterate thru
    $VerbosePreference = 'Continue'
    $conns = @('DevDB','QADB','ProdDB')
 
    $sb = [scriptblock] `
            {
                param($Connection, $BasePath, $SQL, $QueryTimeout, $As)  
                 
                #Import all required functions that are needed for this scriptblock's functionality!
                . "$BasePath\SQLLib\Invoke-SQLCmd2.ps1"
                 
                Invoke-SQLCmd2 -Connection $connection -CloseConnection:$true -SQL $SQL -QueryTimeout $QueryTimeout -As $As
            }
 
 
    #Build the variable need to splat the parameters (for the other parameters)
    $params = @{
                    BasePath = Get-PoShBasePath
                    SQL = "SELECT * FROM sys.databases"
                    QueryTimeout = 10
                    As = "DataRow"
                }   
             
    $rslt = Invoke-Async -Set $conns -SetParam Connection  -ScriptBlock $sb -Verbose -Measure:$false -Params $params -ThreadCount 4
    $rslt | ft
 
.INPUTS
 
.OUTPUTS
   Determined by the provided cmdlet, function or scriptblock.
.NOTES
    This can often times eat up a lot of memory due in part to how some cmdlets work. Test-Connection is a good example of this. 
    Although it is not a good idea to manually run the garbage collector it might be needed in some cases and can be run like so:
    [gc]::Collect()
#>
 
function Invoke-Async{
param(
#The data group to process, such as server names.
[parameter(Mandatory=$true,ValueFromPipeLine=$true)]
[object[]]$Set,
#The parameter name that the set belongs to, such as Computername.
[parameter(Mandatory=$true)]
[string] $SetParam,
#The Cmdlet for Function you'd like to process with.
[parameter(Mandatory=$true, ParameterSetName='cmdlet')]
[string]$Cmdlet,
#The ScriptBlock you'd like to process with
[parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
[scriptblock]$ScriptBlock,
#any aditional parameters to be forwarded to the cmdlet/function/scriptblock
[hashtable]$Params,
#number of jobs to spin up, default being 10.
[int]$ThreadCount=10,
#return performance data
[switch]$Measure,
#return abort threshold (if non-negative/non-zero, bails after this many errors have occured)
[int]$AbortAfterErrorCount=-1
 
)
Begin
{
    [int] $ErrorCounter = 0                                                                              #20141031 Jana - Added to track errors and bail
    [int] $AllowedErrorCount = if ($AbortAfterErrorCount -le 0) {9999999} else {$AbortAfterErrorCount}   #20141031 Jana - Added to track errors and bail
    $Threads = @()
    $Length = $JobsLeft = $Set.Length
 
    $Count = 0
    if($Length -lt $ThreadCount){$ThreadCount=$Length}
    $timer = @(1..$ThreadCount  | ForEach-Object{$null})
    $Jobs = @(1..$ThreadCount  | ForEach-Object{$null})
     
    If($PSCmdlet.ParameterSetName -eq 'cmdlet')
    {
        $CmdType = (Get-Command $Cmdlet).CommandType
        if($CmdType -eq 'Alias')
        {
            $CmdType = (Get-Command (Get-Command $Cmdlet).ResolvedCommandName).CommandType
        }
         
        If($CmdType -eq 'Function')
        {
            $ScriptBlock = (Get-Item Function:\$Cmdlet).ScriptBlock
            1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
        }
        ElseIf($CmdType -eq "Cmdlet")
        {
            1..$ThreadCount  | ForEach-Object{ $Threads += [powershell]::Create().AddCommand($Cmdlet)}
        }
    }
    Else
    {
        1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
    }
 
    If($Params){$Threads | ForEach-Object{$_.AddParameters($Params) | Out-Null}}
 
}
Process
{
    while($JobsLeft)
    {
        #20140929 Jana - Bug fix - Changed "-lt" to "-le" because it does not execute if if there is only 1 item in the set total to begin with!
        #for($idx = 0; $idx -lt ($ThreadCount-1) ; $idx++)
        for($idx = 0; $idx -le ($ThreadCount-1) ; $idx++)
        {
 
            $SetParamObj = $Threads[$idx].Commands.Commands[0].Parameters| Where-Object {$_.Name -eq $SetParam}
 
            #NOTE: Only hits this block after atleast one item has been kicked off..so during very first pass, skips this.
            If ($Jobs[$idx] -ne $null)
            { 
                If($Jobs[$idx].IsCompleted) #job ran ok, clear it out
                {  
                    $result = $null
                    if($threads[$idx].InvocationStateInfo.State -eq "Failed")
                    {
                        $result  = $Threads[$idx].InvocationStateInfo.Reason
 
                         
                        #Will write out the hashtable values in the error instead of "Set Item: System.Collections.Hashtable Exception: ...."    
                        $OutError = "Set Item: $($($SetParamObj.Value)| Out-String )"                       
                        Write-Error "$OutError Exception: $result"
 
                        #Write-Error "Set Item: $($SetParamObj.Value) Exception: $result"
                         
                        #This was the original code by the original author (always leave this commented)
                        #Write-Error "Set Item: $($SetParamObj) Exception: $result"
 
                        #20141031 Jana - Added to track errors and bail
                        $ErrorCounter++
                        if ($ErrorCounter -ge $AllowedErrorCount)
                        {
                            break;
                        }
                    }
                    else
                    { 
                        $result = $Threads[$idx].EndInvoke($Jobs[$idx])
                    }
                    $ts = (New-TimeSpan -Start $timer[$idx] -End (Get-Date))
                    if($Measure)
                    {
                        new-object psobject -Property @{
                            TimeSpan = $ts
                            Output = $result
                            SetItem = $SetParamObj.Value
                            }
                    }
                    else
                    {
                        $result
                    }
                    $Jobs[$idx] = $null
                    $JobsLeft-- #one less left
 
                    write-verbose "Completed: $($SetParamObj.Value) in $ts"
                    #write-verbose "Completed: $SetParamObj in $ts"
                    write-progress -Activity "Processing Set" -Status "$JobsLeft jobs left" -PercentComplete (($length-$jobsleft)/$length*100)
                }
            }
 
            If(($Count -lt $Length) -and ($Jobs[$idx] -eq $null)) #add job if there is more to process
            {
                write-verbose "starting: $($Set[$Count])"
                $timer[$idx] = get-date
                $Threads[$idx].Commands.Commands[0].Parameters.Remove($SetParamObj) | Out-Null #check for success?
                $Threads[$idx].AddParameter($SetParam,$Set[$Count]) | Out-Null
                $Jobs[$idx] = $Threads[$idx].BeginInvoke()
                $Count++
            }
             
        }
 
        #20141031 Jana - Added to track errors and bail        
        if ($ErrorCounter -ge $AllowedErrorCount)
        {
            break;
        }
    }
}
End
{
    $Threads | ForEach-Object{$_.runspace.close();$_.Dispose()}
}
}