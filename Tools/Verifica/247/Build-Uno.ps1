function Build-One($name, $plat='Win32') {
  $out = "C:\Users\LUCA~1.ZAN\AppData\Local\Temp\b_$name.txt"
  $p = Start-Process cmd -ArgumentList "/c Tools\build.bat $name Release $plat > $out 2>&1" -PassThru -WindowStyle Hidden
  Start-Sleep 1; try { $p.PriorityClass='BelowNormal' } catch {}
  $p.WaitForExit(1800000) | Out-Null
  $log = if ($plat -eq 'Win64') { "logs\Win64\$name.log" } else { "logs\$name.log" }
  $root = (Get-Location).Path + '\'
  Select-String -Path $log -Pattern ' error ' | Select-Object -First 10 | ForEach-Object { ($_.Line).Replace($root,'') -replace '\[C:.*$','' }
  Get-Content $out | Select-String 'Riuscite|Fallite' | ForEach-Object { $_.Line }
}
