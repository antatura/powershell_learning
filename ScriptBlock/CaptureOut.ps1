﻿
$video = Resolve-Path $args[0]

$W = [int](Read-Host "[int]Pixel width of the final tiles")    # 指定最终合成图的像素宽度

$X = [int](Read-Host "[int]X-COLUMNS")    # 指定横向贴片数量

$Y = [int](Read-Host "[int]Y-ROWS")    # 指定纵向贴片数量

$XY = $X*$Y

$D = [int](ffprobe -v 16 -show_entries format=duration -of csv=p=0 $video)    # 获取视频时长

$stream_info = [string](ffprobe -v error -select_streams v:0 -show_streams $video)    # 获取流信息用以判断HDR


for ($E=1; $E -le $XY; $E++) 
{
    $ss = $E*$D/($XY+1)

    $T = "{0:D3}" -f $E

    # if ($video.Contains('.hdr.') -or $video.Contains('.HDR.'))    # 根据文件名判断HDR视频（已过时）

    if ($stream_info.Contains('bt2020'))    # 根据流信息中包含bt2020判断HDR视频
    {
        ffmpeg -y -stats -v 16 -ss $ss -i $video -vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv -frames:v 1 -pred 2 F:\Capture_$T.png
    }
    else
    {
        ffmpeg -y -stats -v 16 -ss $ss -i $video -frames:v 1 -pred 2 F:\Capture_$T.png
    }


    ffmpeg -y -stats -v 16 -i F:\Capture_$T.png -q 2 -pix_fmt yuvj420p F:\Capture_$T.jpg    # PNG 转 JPG（质量91）

}


ffmpeg -y -stats -v 16 -i F:\Capture_%3d.png -vf tile=$($X)x$($Y):padding=8,scale=$($W):-2  -q 2 -pix_fmt yuvj420p F:\TILES.jpg    # 可调整贴片边距padding，默认8px


Del F:\Capture_*.png -Confirm
Del F:\Capture_*.jpg -Confirm
Del F:\TILES.jpg -Confirm
