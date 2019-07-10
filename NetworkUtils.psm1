using namespace System.Management.Automation
using namespace System.IO
using namespace System.Collections.Generic
using namespace Security.Principal
function Invoke-DownloadFile {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [System.Uri]$Url,
        [ValidateNotNullOrEmpty()]
        [FuturePathTransform()]$TargetFile
    )
    if ($PSCmdlet.ShouldProcess($url, "Download") -and $PSCmdlet.ShouldProcess($TargetFile, "Save")) {
        try {
            $request = [System.Net.HttpWebRequest]::Create($url)
            $request.set_Timeout(15000) #15 second timeout
            $response = $request.GetResponse()
            $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
            $responseStream = $response.GetResponseStream()
            $targetStream = [System.IO.FileStream]::new($TargetFile, "Create")
            $buffer = [System.Byte[]]::CreateInstance([System.Byte], 10KB)
            $count = $responseStream.Read($buffer, 0, $buffer.length)
            $downloadedBytes = $count
            $filename = $url.AbsoluteUri.Split('/') | Select-Object -Last 1
            while ($count -gt 0) {
                $targetStream.Write($buffer, 0, $count)
                $count = $responseStream.Read($buffer, 0, $buffer.length)
                $downloadedBytes = $downloadedBytes + $count
                $downloaded = [System.Math]::Floor($downloadedBytes / 1024)
                $PercentComplete = ($downloaded / $totalLength) * 100
                Write-Progress -Activity "Downloading file '$filename'" -Status "Downloaded ($($downloaded)K of $($totalLength)K): " -PercentComplete $PercentComplete
            }
            Write-Progress -Activity "Downloading file '$filename'" -Status "Ready" -Completed
        }
        finally {
            if ($targetStream) {
                $targetStream.Flush()
                $targetStream.Close()
                $targetStream.Dispose()
            }
            if ($resposneStream) {
                $responseStream.Dispose()
            }
        }
    }
}

function Get-NetworkStatistics {
    netstat -ano |
        Select-String -Pattern '\s+(TCP|UDP)' |
        ForEach-Object {

        $item = $_.line.split("", [System.StringSplitOptions]::RemoveEmptyEntries)

        if (-not $item[1].StartsWith("[::")) {
            $la = $item[1] -as [ipaddress]
            $ra = $item[2] -as [ipaddress]
            if ($la.AddressFamily -eq 'InterNetworkV6') {
                $localAddress = $la.IPAddressToString
                $localPort = $item[1].split('\]:')[-1]
            } else {
                $localAddress = $item[1].split(':')[0]
                $localPort = $item[1].split(':')[-1]
            }
            
            if ($ra.AddressFamily -eq 'InterNetworkV6') {
                $remoteAddress = $ra.IPAddressToString
                $remotePort = $item[2].split('\]:')[-1]
            } else {
                $remoteAddress = $item[2].split(':')[0]
                $remotePort = $item[2].split(':')[-1]
            }

            [PSCustomObject]@{
                PID           = $item[-1]
                ProcessName   = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name
                Protocol      = $item[0]
                LocalAddress  = $localAddress
                LocalPort     = $localPort
                RemoteAddress = $remoteAddress
                RemotePort    = $remotePort
                State         = if ($item[0] -eq 'tcp') {$item[3]} else {$null}
            }
        }
    }
}

Export-ModuleMember -Function *-* -Alias * -Variable * -Cmdlet *-*