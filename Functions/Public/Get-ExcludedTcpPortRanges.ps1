Update-TypeData -TypeName "User.PortRange" -DefaultDisplayPropertySet "Start", "End", "Administered" -Force
Update-TypeData -TypeName "User.PortRange" -MemberType ScriptProperty -MemberName "PortsInRange" -Value {$this.Start..$this.End} -Force
function Get-ExcludedTcpPortRanges {
    [CmdletBinding()]
    [OutputType('User.PortRange[]')]
    Param()
    Process {
        netsh int ipv4 show excludedportrange tcp |
            Select-String -Pattern "(?<start>\d+)\s+(?<end>\d+)\s+(?<administered>\*)?" -AllMatches |
            Select-Object -ExpandProperty Matches |
            ForEach-Object {
            [pscustomobject]@{
                PSTypeName = "PortRange"
                Start      = $_.Groups['start'].Value
                End        = $_.Groups['end'].Value
                Administered = $_.Groups['administered'].Value -eq "*"
            }
        }
    }
}
