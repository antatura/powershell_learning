
$Dir = Read-Host -Prompt "输入要筛选的路径（如：D:\dir\）" 


$StartTime = Get-Date

$Dt = Get-Date -Format 'yyyy-MM-dd_HH.mm.ss'

New-Item -ItemType Directory LogFiles_$Dt -ErrorAction Stop    ### 若PS1文件所在路径含有方括号[]，则闪退。

$Ext = @('.mkv','.mp4','.webm','.mov')
$Gci = Get-ChildItem -LiteralPath $Dir -File -Recurse | Where-Object { $_.Extension -in $Ext } | Sort-Object -Property LastWriteTime -Descending

$S_Properties =  @('VID','Name','DuplicatedFrames','Dup_Percent','DroppedFrames','Drop_Percent','Abs_Frames','LastWriteTime','Directory')

$HT = @{}
$S_Properties[2..6].ForEach({ $HT.Add($_,$null) })

$X = New-Object System.Collections.ArrayList


for ($A=0; $A -lt $Gci.Count; $A++ ) 
{
    $VID = '{0:D5}' -f $A
    
    $Gci[$A] | Add-Member -NotePropertyName VID -NotePropertyValue $VID -Force
    
    $Stats = ffmpeg -v 8 -stats -hwaccel cuda -i $Gci[$A].FullName -map v -fps_mode cfr -stats_period 0.05 -f null - 2>&1 | ForEach-Object { "$_" } 

    ### $Stats = ($Stats_s -split 'x    ').Trim()


    if (!($Stats))
    {
        $X.Add($A)

        Write-Output "VID: $($VID)"$Gci[$A].FullName"！无法读取视频文件！"`n


        foreach ($Key in $HT.Keys) 
        { 
            $Gci[$A] | Add-Member -NotePropertyName $Key -NotePropertyValue ERROR
        }


        $Gci[$A] | Select-Object -Property $S_Properties | Export-Csv -Path Result_$Dt.csv -Append -NoTypeInformation -Encoding UTF8 
          
    }

    elseif ($Stats[-1].Contains('dup'))
    {
        $X.Add($A)

        Write-Output "VID: $($VID)"$Gci[$A].FullName$Stats[-1]`n

        $HT.DuplicatedFrames = [regex]::Matches($Stats[-1], '(?<=dup=).+?(?= drop)').Value
        $HT.DroppedFrames = [regex]::Matches($Stats[-1], '(?<=drop=).+?(?= speed)').Value
        $frame = [regex]::Matches($Stats[-1], '(?<=frame=).+?(?= fps)').Value

        $HT.Abs_Frames = $frame-$HT.DuplicatedFrames+$HT.DroppedFrames
        $HT.Dup_Percent = '{0:P}' -f ($HT.DuplicatedFrames/$HT.Abs_Frames)
        $HT.Drop_Percent = '{0:P}' -f ($HT.DroppedFrames/$HT.Abs_Frames)


        foreach ($Key in $HT.Keys) 
        { 
            $Gci[$A] | Add-Member -NotePropertyName $Key -NotePropertyValue $HT[$Key]
        }


        $Gci[$A] | Select-Object -Property $S_Properties | Export-Csv -Path Result_$Dt.csv -Append -NoTypeInformation -Encoding UTF8

        $LogName = $VID + '__' + $Gci[$A].BaseName
        $Stats | Out-File -LiteralPath LogFiles_$Dt\VID.$LogName.txt -Encoding utf8
           
    }

    $ElapsedTime = "{0:dd}天{0:hh}小时{0:mm}分{0:ss}秒" -f ((Get-Date)-$StartTime)
    $Host.UI.RawUI.WindowTitle = '  视频总数:',$Gci.Count,'  已检索:',"$($A+1)",'  已滤出:',$X.Count,'    已用时:',$ElapsedTime

}


$Gci[$X] | Select-Object -Property $S_Properties | Out-GridView

Pause

