
### Requirements: FFmpeg.exe; FFprobe.exe; PNG File(Resolution>=256x256; Ratio=1:1)

Write-Host "# PNG to ICO (256,64,48,40,32,24,20,16) #" -ForegroundColor Cyan

Write-Host "# Example: PtI.ps1 Sample.png Music.ico #" -ForegroundColor Magenta

$IMG = $args[0]

$ICO = $args[1]

FFmpeg -v 16 -i $IMG -map_metadata -1 -map v:0 -s 256x256 -pix_fmt rgba V_256x256.png

('64x64','48x48','40x40','32x32','24x24','20x20','16x16').ForEach({ FFmpeg -v 16 -i V_256x256.png -s $_ -pix_fmt bgra V_$_.bmp })

FFmpeg -v 16 -i V_256x256.png -i V_64x64.bmp -i V_48x48.bmp -i V_40x40.bmp -i V_32x32.bmp -i V_24x24.bmp -i V_20x20.bmp -i V_16x16.bmp -map 0 -map 1 -map 2 -map 3 -map 4 -map 5 -map 6 -map 7 -c copy $ICO

FFprobe -hide_banner $ICO

Remove-Item V_*

