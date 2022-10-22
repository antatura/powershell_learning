
$Video = Resolve-Path $args[0]

$W = [int](Read-Host "[int]Pixel width of the final tiles")    # 指定最终合成图的像素宽度

$X = [int](Read-Host "[int]X-COLUMNS")    # 指定横向贴片数量

$Y = [int](Read-Host "[int]Y-ROWS")    # 指定纵向贴片数量

$XY = $X*$Y

$ASCII = ($args[0] -replace '[^a-zA-Z0-9_.+-]').TrimStart('.')    # 仅保留部分ASCII字符

$Duration = [int](ffprobe -v 16 -show_entries format=duration -of csv=p=0 $Video)    # 获取视频时长

$Stream_info = [string](ffprobe -v error -select_streams v:0 -show_streams $Video)    # 获取流信息用以判断HDR

$HDR = "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv"


for ($A=1; $A -le $XY; $A++) 
{
    $T = "{0:D3}" -f $A
    
    $SS = $A*$Duration/($XY+1)

    $SS_f = "{0:hh\.mm\.ss\.fff}" -f [timespan]::fromseconds($SS)


    if ($Stream_info.Contains('bt2020'))    # 根据流信息中包含bt2020判断HDR视频
    {
        ffmpeg -y -stats -v 16 -ss $SS -i $Video -vf $HDR -frames:v 1 -pred 2 F:\Capture_$T.png
    }
    else
    {
        ffmpeg -y -stats -v 16 -ss $SS -i $Video -frames:v 1 -pred 2 F:\Capture_$T.png
    }


    ffmpeg -y -stats -v 16 -i F:\Capture_$T.png -q 2 -pix_fmt yuvj420p F:\$ASCII--$ss_f.jpg    # PNG 转 JPG（质量91）

}


ffmpeg -y -stats -v 16 -i F:\Capture_%3d.png -vf tile=$($X)x$($Y):padding=8,scale=$($W):-2  -q 2 -pix_fmt yuvj420p F:\TILES_$ASCII.jpg
# 可调整贴片边距padding，默认8px


Del F:\Capture_*.png -Confirm
Del F:\$ASCII-*.jpg -Confirm
Del F:\TILES_$ASCII.jpg -Confirm
