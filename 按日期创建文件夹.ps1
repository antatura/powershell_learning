$date = Get-Date 2021.10.01

for($E=0; $date -lt (Get-Date 2021.12.31); $E++){
    $date = (Get-Date 2021.10.01).AddDays($E)
    $yea = '{0:d4}'-f $date.Year
    $mon = '{0:d2}'-f $date.Month
    $day = '{0:d2}'-f $date.Day
    $nam = $yea+'.'+$mon+'.'+$day
    New-Item -ItemType Directory .\$yea'年'\$mon'月'\$nam
}
