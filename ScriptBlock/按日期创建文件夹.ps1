
$date = Get-Date (Read-Host -Prompt '开始日期（例2021.10.01）')
$end  = Get-Date (Read-Host -Prompt '截止日期')
$days = ($end-$date).Days+1

do{
    $year  = '{0:d4}'-f $date.Year
    $month = '{0:d2}'-f $date.Month
    $day   = '{0:d2}'-f $date.Day
    $name  = $year+'.'+$month+'.'+$day
    New-Item -ItemType Directory .\$year'年'\$month'月'\$name
    $date  = $date.AddDays(1)

}while($date -le $end)

Write-Host "`n 创建完成！共$($days)个文件夹。" -ForegroundColor Yellow

Read-Host -Prompt 'Press enter to exit'
