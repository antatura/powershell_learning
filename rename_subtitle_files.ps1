Write-Host 'Rename subtitle files with video basename' -ForegroundColor Yellow

$VE = '.'+(Read-Host -Prompt 'Video Extension')
$SE = '.'+(Read-Host -Prompt 'Subtitle Extension')

$VE_BaseName = (Get-ChildItem *$VE).BaseName

for ($X=0; $X -lt $VE_BaseName.Length; $X++) {
    (Get-ChildItem *$SE)[$X] | Rename-Item -NewName ($VE_BaseName[$X]+$SE)
}

Get-ChildItem
