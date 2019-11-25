function Invoke-DownloadFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Uri]$Url,
        [Parameter(Mandatory=$True)]
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