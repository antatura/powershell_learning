# powershell_learning

- **查看30天以上的空文件夹**

```
Get-ChildItem -Recurse | Where-Object { !(Get-ChildItem -Force -LiteralPath $_.FullName) -and ($_.FullName -notmatch 'cn_windows') -and ($_.LastWriteTime -lt [datetime]::Now.AddDays(-30)) } | Select-Object -Property FullName,LastWriteTime | Out-GridView
```

- **获取已安装应用列表**

```
Get-CimInstance -ClassName Win32_Product | Sort-Object -Property InstallDate | Format-Table -AutoSize -Property Name,Version,InstallDate
```

- **弹出提示窗口**

```
(New-Object -ComObject wscript.shell).Popup('A Question?',0,'A Title',3)
```
