param
(
    $Video,
    [ValidateSet("JPEG-86", "PNG", "WebP-lossless", "Tile")]$Mode,
    [int]$Width=3840,
    [int]$X=4,
    [int]$Y=4,
    [switch]$Timestamp,
    [switch]$help
)



if ($help -or !($Mode) -or !($Video))
{
    Write-Host -ForegroundColor Green " Example:     CaptureOut.ps1 -Video INPUT.mp4 -Mode PNG,Tile
                                     `r -----------------------------------------------------------
                                     `r -Video:      Video's path
                                     `r -Mode:       JPEG-86, PNG, WebP-lossless, Tile
                                     `r -Timestamp:  Show timestamp in the lower left corner
                                     `r -Width:      Pixel width of the final tile (Default: 3840)
                                     `r -X:          X-COLUMNS (Default: 4)
                                     `r -Y:          Y-ROWS (Default: 4)"
    Break
}



$Video_FullName = Resolve-Path $Video

$XY = $X*$Y

$ASCII = ((Split-Path $Video_FullName -Leaf).Replace(' ','_') -replace '[^a-zA-Z0-9_.-]').Trim('.')    # 仅保留部分ASCII字符

$Duration = [double](ffprobe -v 16 -select_streams v:0 -show_entries format=duration -of default=nk=1:nw=1 $Video_FullName)    # 获取视频时长

$W = ([array](ffprobe -v 16 -select_streams v:0 -show_entries stream=width -of default=nk=1:nw=1 $Video_FullName))[0]

$Frame_info = ffmpeg -i $Video_FullName -frames:v 1 -vf showinfo -f null - *>&1 | % {"$_"}    # 获取第一帧信息用以判断 Dolby Vision 或 HDR

if ($Frame_info -match 'Dolby Vision RPU Data')
{
    if (!($Frame_info -match 'Jellyfin'))
    {
        Write-Warning "This is a Dolby Vision video.`nRequirement: https://github.com/jellyfin/jellyfin-ffmpeg/releases "
        Break
    }
}

$HDR_Filter = "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=bgr24"
$DoVi_Filter = "hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12"
#(deprecated)  $SDR2PNG_Filter = "zscale=min=709:rin=limited,format=gbrp,format=bgr24"
$vf = "-vf"





for ($A=1; $A -le $XY; $A++) 
{
    $D3 = "{0:D3}" -f $A
    $SS = $A*$Duration/($XY+1)
    $SS_f = "{0:hh\.mm\.ss\.\.fff}" -f [timespan]::fromseconds($SS)
    $FF_SS = "{0:hh}\\:{0:mm}\\:{0:ss}.{0:fff}" -f [timespan]::fromseconds($SS)
    $TEXT_Filter = "drawtext=fontfile=C\\:/Windows/fonts/consola.ttf:text=$($FF_SS):x=H/50:y=H-th-x:fontsize=H/25:box=1:boxcolor=Black:fontcolor=White:boxborderw=5"

    if ($Timestamp -and ($Frame_info -match 'bt2020'))
    {
        $Filters = $HDR_Filter + ',' + $TEXT_Filter
    }
    elseif ($Timestamp -and ($Frame_info -match 'Dolby Vision RPU Data'))
    {
        $Filters = $DoVi_Filter + ',' + $TEXT_Filter
        $HW = '-init_hw_device'
        $Opencl = 'opencl:0'
    }
    elseif ($Timestamp)
    {
        $Filters = $TEXT_Filter
    }
    elseif ($Frame_info -match 'bt2020')
    {
        $Filters = $HDR_Filter
    }
    elseif ($Frame_info -match 'Dolby Vision RPU Data')
    {
        $Filters = $DoVi_Filter
        $HW = '-init_hw_device'
        $Opencl = 'opencl:0'
    }
    else
    {
        Clear-Variable vf
    }
    ffmpeg -y -v 16 $HW $Opencl -ss $SS -i $Video_FullName -frames:v 1 $vf $Filters -sws_flags accurate_rnd+full_chroma_int+bitexact $env:TEMP\$ASCII'__'$D3.bmp
    


    if ("PNG" -in $Mode)
    {
        ffmpeg -y -v 16 -i $env:TEMP\$ASCII'__'$D3.bmp -pred 2 D:\$ASCII'__'$SS_f.png
        Write-Host "$($XY-$A)  D:\$($ASCII)__$SS_f.png" -ForegroundColor DarkCyan
    }

    if ("JPEG-86" -in $Mode)
    {
        ffmpeg -y -v 16 -i $env:TEMP\$ASCII'__'$D3.bmp -sws_flags accurate_rnd+full_chroma_int+bitexact -q 3 -pix_fmt yuvj420p D:\$ASCII'__'$SS_f.jpg
        Write-Host "$($XY-$A)  D:\$($ASCII)__$SS_f.jpg" -ForegroundColor DarkBlue
    }

    if ("WebP-lossless" -in $Mode)
    {
        ffmpeg -y -v 16 -i $env:TEMP\$ASCII'__'$D3.bmp -lossless 1 D:\$ASCII'__'$SS_f.webp
        Write-Host "$($XY-$A)  D:\$($ASCII)__$SS_f.webp" -ForegroundColor DarkMagenta
    }
    
}
    
if ("Tile" -in $Mode)
{
    $Width = [math]::Min(($W+8)*$X-8,$Width)

    ffmpeg -y -v 16 -i $env:TEMP\$ASCII'__'%3d.bmp -vf "tile=layout=$($X)x$($Y):padding=8,scale=$($Width):-2:flags=accurate_rnd+full_chroma_int+bitexact" -q 3 -pix_fmt yuvj420p D:\Tile_$ASCII.jpg
    # 可调整贴片边距padding，默认8px

    Write-Host "D:\Tile_$ASCII.jpg" -ForegroundColor DarkGreen
}



Remove-Item $env:TEMP\$ASCII'__'*.bmp



