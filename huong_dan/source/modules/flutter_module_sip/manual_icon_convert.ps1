try {
    Add-Type -AssemblyName System.Drawing
    $sourcePng = "c:\projects\siprix_voip_sdk\example\assets\logo.png"
    $destIco = "c:\projects\siprix_voip_sdk\example\windows\runner\resources\app_icon.ico"
    
    Write-Host "Converting $sourcePng to $destIco..."
    
    $bitmap = [System.Drawing.Bitmap]::FromFile($sourcePng)
    # Resize to 256x256 if needed, but let's try direct conversion first
    # Icons from HIcon are usually 32x32 which is small.
    # To do it properly we need a library or a specialized function. 
    # For now, let's try the simple HIcon method as a fallback.
    
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    
    $fs = New-Object System.IO.FileStream($destIco, [System.IO.FileMode]::Create)
    $icon.Save($fs)
    $fs.Close()
    
    Write-Host "Conversion successful."
} catch {
    Write-Error "Failed to convert icon: $_"
    exit 1
}
