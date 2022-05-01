
$video = $args[0]

$number = [int](Read-Host "Number of Captures")

$duration = [double](ffprobe -v 16 -show_entries format=duration -of csv=p=0 $video)

for ($E=1; $E -le $number; $E++) 
{
    $ss = $E*$duration/($number+1)

    $T = "{0:D3}" -f $E

    if ($video.Contains('.hdr.') -or $video.Contains('.HDR.'))
    {
        ffmpeg -y -stats -v 16 -ss $ss -i $video -vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv -frames:v 1 -pred 2 "F:\Capture_$T.png"
    }
    else
    {
        ffmpeg -y -stats -v 16 -ss $ss -i $video -frames:v 1 -pred 2 "F:\Capture_$T.png"
    }

    ffmpeg -y -stats -v 16 -i "F:\Capture_$T.png" -q 2 -pix_fmt yuvj420p "F:\Capture_$T.jpg"
}

Del F:\Capture_*.png -Confirm
Del F:\Capture_*.jpg -Confirm







# ffmpeg -y -v 16 -i Capture_%d.png -vf scale=1920:-2,tile=1x5:padding=32 otpt.png