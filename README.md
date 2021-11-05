# powershell_learning

- **查看30天以上的空文件夹**

```
Get-ChildItem -Recurse | Where-Object { !(Get-ChildItem -Force -LiteralPath $_.FullName) -and ($_.FullName -notmatch 'cn_windows') -and ($_.LastWriteTime -lt [datetime]::Now.AddDays(-30)) } | Select-Object -Property FullName,LastWriteTime | Out-GridView
```
