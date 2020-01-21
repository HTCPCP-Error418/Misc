$IpAddress = Read-Host "Enter IP Address: "
1..1024 | % {(New-Object Net.Sockets.TcpClient).Connect("$IpAddress", "$_")} 2>$null
