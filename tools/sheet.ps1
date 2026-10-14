param([string]$out, [string]$labels, [Parameter(ValueFromRemainingArguments = $true)][string[]]$files)
# 2-column contact sheet at half size, each tile labelled.
Add-Type -AssemblyName System.Drawing
$names = $labels.Split(",")
$tw = 480; $th = 360
$cols = 2
$rows = [math]::Ceiling($files.Count / $cols)
$o = New-Object System.Drawing.Bitmap ($tw * $cols), ($th * $rows)
$g = [System.Drawing.Graphics]::FromImage($o)
$g.InterpolationMode = 'HighQualityBicubic'
$font = New-Object System.Drawing.Font 'Arial', 18, ([System.Drawing.FontStyle]::Bold)
for ($i = 0; $i -lt $files.Count; $i++) {
	$b = [System.Drawing.Bitmap]::FromFile($files[$i])
	$x = ($i % $cols) * $tw; $y = [math]::Floor($i / $cols) * $th
	$g.DrawImage($b, $x, $y, $tw, $th)
	$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 0, 0, 0))), $x, $y + $th - 34, 200, 34)
	$g.DrawString($names[$i], $font, [System.Drawing.Brushes]::White, $x + 8, $y + $th - 31)
	$b.Dispose()
}
$o.Save($out)
