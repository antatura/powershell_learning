

### 若视频起始时间远离零点，须使之归零： ffmpeg -i [INPUT] -c copy [output]


param ($Video, $ss=0, $to=[int]::MaxValue, [switch]$help)

if(!($Video))
{
    if($help)
    {
        Write-Host -ForegroundColor DarkGreen " Example: Video_Motion_Detect.ps1 -Video INPUT.mp4 -ss 30 -to 60
                                             `r -ss: Start-Timestamp(sec)[00:27:35.123456]
                                             `r -to: Analytical-Duration(sec)[00:32:35]"
        Break
    }

    Write-Host -ForegroundColor Red "Use <Video_Motion_Detect.ps1 -help> to get help."
    Break
}





$Video_Path = Resolve-Path $Video
$W = ((Split-Path $Video_Path -Leaf).Replace(' ','_') -replace '[][]').Trim('.')    # 空格替换为下划线；剔除[]

$TEMP = New-TemporaryFile    # 在%TEMP%中生成临时文件
$TEMP_FF = $TEMP.FullName.Replace('\','/').Replace(':','\\:')    # 临时文件的路径转为FFmpeg可用的格式

try {$ss = [timespan]::FromSeconds($ss)}
catch {[timespan]$ss = '00:'+$ss}

try {$to = [timespan]::FromSeconds($to)}
catch {[timespan]$to = '00:'+$to}

ffmpeg -ss $ss.TotalSeconds -to $to.TotalSeconds -v 16 -stats -i $Video_Path -map v:0 -vf "select='not(mod(n\,1))',select='gte(scene\,0)',metadata=print:file=$TEMP_FF" -f null -
# select='not(mod(n\,1))'：假设1变为10，则ffmpeg先过滤出第00、10、20、30......帧，后续将用第10帧对比第00帧，第20帧对比第10帧......得出场景变化程度，故设为1；若删除此项，也为1

$Stats = Get-Content $TEMP
$HashTable = @{}


for ($A=0; $A -lt $Stats.Count; $A++)
{
    if($Stats[$A] -match 'pts_time')
    {
        $pts_time = "{0:hh\:mm\:ss\.ffffff}" -f ($ss+[timespan]::FromSeconds($Stats[$A].Split('pts_time:')[-1]))
        $HashTable.Add($pts_time,$null)
    }

    elseif($Stats[$A] -match 'scene_score')
    {
        $HashTable[$pts_time] = $Stats[$A].TrimStart('lavfi.scene_score=')
    }
}


$TEMP.Delete()

$HashTable.GetEnumerator() | Sort Name | Select -Property @{N='pts_time';E={$_.Key}},@{N='scene_score';E={$_.Value}} | Export-Csv -Path __$W.CSV -NoTypeInformation

