
param ($i, $o, [switch]$help)


if($help)
{
    Write-Host -ForegroundColor Green " Requirements: FFmpeg.exe; FFprobe.exe; Image File(Resolution>=256x256; Ratio=1:1)
                                     `r Example: IMG-ICO.ps1 -i INPUT.png -o Music.ico"
    Break
}


FFmpeg -v 16 -i $i -map_metadata -1 -map v:0 -s 256x256 -pix_fmt bgra V_256x256.bmp

('64x64','48x48','40x40','32x32','24x24','20x20','16x16').ForEach({ FFmpeg -v 16 -i V_256x256.bmp -s $_ -pix_fmt bgra V_$_.bmp })

FFmpeg -v 16 -i V_256x256.png -i V_64x64.bmp -i V_48x48.bmp -i V_40x40.bmp -i V_32x32.bmp -i V_24x24.bmp -i V_20x20.bmp -i V_16x16.bmp -map 0 -map 1 -map 2 -map 3 -map 4 -map 5 -map 6 -map 7 -c copy $o

FFprobe -hide_banner $o

Remove-Item V_*

