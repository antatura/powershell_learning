function New-EmptyFile
{
    param( [string]$FilePath,[double]$Size )
 
    $file = [System.IO.File]::Create($FilePath)
    $file.SetLength($Size)
    $file.Close()
    Get-Item $file.Name
}

PS> New-EmptyFile -FilePath c:\temp\test.txt -Size 20mb

# https://www.powershellmagazine.com/2012/11/22/pstip-create-a-file-of-the-specified-size/
