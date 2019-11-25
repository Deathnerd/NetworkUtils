function Get-NetworkStatistics {
    netstat -ano |
        Select-String -Pattern '\s+(TCP|UDP)' |
        ForEach-Object { $_.line.split("", [System.StringSplitOptions]::RemoveEmptyEntries) } |
        Where-Object { -not $_[1].StartsWith("[::") } |
        ForEach-Object {
        $la = $item[1] -as [ipaddress]
        $ra = $item[2] -as [ipaddress]
        $LocalAddress, $LocalPort = if ($la.AddressFamily -eq 'InterNetworkV6') {
            $la.IPAddressToString, $item[1].split('\]:')[-1]
        }
        else {
            $item[1].split(':')[0], $item[1].split(':')[-1]
        }

        $RemoteAddress, $RemotePort = if ($ra.AddressFamily -eq 'InterNetworkV6') {
            $ra.IPAddressToString, $item[2].split('\]:')[-1]
        }
        else {
            $item[2].split(':')[0], $item[2].split(':')[-1]
        }

        [PSCustomObject]@{
            PID           = $item[-1]
            ProcessName   = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name
            Protocol      = $item[0]
            LocalAddress  = $LocalAddress
            LocalPort     = $LocalPort
            RemoteAddress = $RemoteAddress
            RemotePort    = $RemotePort
            State         = if ($item[0] -eq 'tcp') {
                $item[3]
            }
            else {
                $null
            }
        }
    }
}