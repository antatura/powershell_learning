chcp 65001

$Dir = Read-Host -Prompt "输入要筛选的路径（如：D:\dir\）" 

$Leaf = Split-Path -Path $Dir -Leaf

$StartTime = Get-Date

$Dt = Get-Date -Format 'yyyy-MM-dd_HH.mm.ss'

New-Item -ItemType Directory $Leaf-LogFiles -ErrorAction Stop -Force >$null   ### 若PS1文件所在路径含有方括号[]，则闪退。

Add-Content -Path $Leaf'.txt' -Value `n`n`n$Dt`n -Encoding UTF8

$Ext = @('.mkv','.mp4','.webm','.mov')
$Gci = Get-ChildItem -LiteralPath $Dir -File -Recurse | 
       Where-Object {($_.Extension -in $Ext) -and ((Get-Content $Leaf'.txt') -notcontains $_.Name)} | 
       Sort-Object -Property LastWriteTime -Descending

$S_Properties =  @('Name','DuplicatedFrames','Dup_Percent','DroppedFrames','Drop_Percent','Abs_Frames','LastWriteTime','Directory')

$HT = @{}
$S_Properties[1..5].ForEach({$HT.Add($_,$null)})

$X = New-Object System.Collections.ArrayList


function Out-CsvLog
{
    $Gci[$A] | Select-Object -Property $S_Properties | Export-Csv -Path $Leaf-Result.csv -Append -NoTypeInformation -Encoding UTF8

    $Stats | Out-File -LiteralPath $Leaf-LogFiles\$($Gci[$A].BaseName).txt -Encoding utf8 -Force

    $X.Add($A)
}


for ($A=0; $A -lt $Gci.Count; $A++)
{
    $VID = '{0:D5}' -f $A
    
    $Stats = ffmpeg -v 16 -stats -hwaccel cuda -i $Gci[$A].FullName -map v -fps_mode cfr -stats_period 0.05 -f null - *>&1 |
             ForEach-Object {"$_"} 


    ### $Stats = ($Stats_s -split 'x    ').Trim()


    if ($Stats[-1].Contains('dup'))
    {        
        $HT.DuplicatedFrames = [regex]::Matches($Stats[-1], '(?<=dup=).+?(?= drop)').Value
        $HT.DroppedFrames = [regex]::Matches($Stats[-1], '(?<=drop=).+?(?= speed)').Value
        $frame = ($Stats[-1] -replace '.*frame=|fps.*').Trim()

        $HT.Abs_Frames = $frame-$HT.DuplicatedFrames+$HT.DroppedFrames
        $HT.Dup_Percent = '{0:P}' -f ($HT.DuplicatedFrames/$HT.Abs_Frames)
        $HT.Drop_Percent = '{0:P}' -f ($HT.DroppedFrames/$HT.Abs_Frames)

        foreach ($Key in $HT.Keys) 
        { 
            $Gci[$A] | Add-Member -NotePropertyName $Key -NotePropertyValue $HT["$Key"]
        }

        Out-CsvLog

        Write-Output "VID: $($VID)"$Gci[$A].FullName$Stats[-1]`n
    }

    elseif (!($Stats) -or ('True' -in ('Error','Invalid','Failed','missing').ForEach({[string]$Stats -match $_})))
    {       
        foreach ($Key in $HT.Keys) 
        { 
            $Gci[$A] | Add-Member -NotePropertyName $Key -NotePropertyValue ERROR
        }

        Out-CsvLog

        Write-Output "VID: $($VID)"$Gci[$A].FullName"!!视频已严重损坏!!"`n
    }


    Add-Content -Path $Leaf'.txt' -Value $Gci[$A].Name -Encoding UTF8

    $ElapsedTime = "{0:dd}天{0:hh}小时{0:mm}分{0:ss}秒" -f ((Get-Date)-$StartTime)
    $Host.UI.RawUI.WindowTitle = '  视频总数:',$Gci.Count,'  已检索:',"$($A+1)",'  已滤出:',$X.Count,'    已用时:',$ElapsedTime
}


$Gci[$X] | Select-Object -Property $S_Properties | Out-GridView

Pause

