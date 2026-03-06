Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mulder's Diff Maker"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# Function to choose a folder
function Select-FolderDialog {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        return $dialog.SelectedPath
    }
    return $null
}

# Labels and fields
$labelSource = New-Object System.Windows.Forms.Label
$labelSource.Text = "Source folder :"
$labelSource.Location = New-Object System.Drawing.Point(10,20)
$labelSource.AutoSize = $true
$form.Controls.Add($labelSource)

$textBoxSource = New-Object System.Windows.Forms.TextBox
$textBoxSource.Location = New-Object System.Drawing.Point(120, 18)
$textBoxSource.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($textBoxSource)

$btnBrowseSource = New-Object System.Windows.Forms.Button
$btnBrowseSource.Text = "..."
$btnBrowseSource.Location = New-Object System.Drawing.Point(410, 17)
$btnBrowseSource.Size = New-Object System.Drawing.Size(30, 23)
$btnBrowseSource.Add_Click({
    $path = Select-FolderDialog
    if ($path) { $textBoxSource.Text = $path }
})
$form.Controls.Add($btnBrowseSource)

$checkBoxXDelta3 = New-Object System.Windows.Forms.CheckBox
$checkBoxXDelta3.Text = "XDelta3"
$checkBoxXDelta3.Location = New-Object System.Drawing.Point(10, 135)
$checkBoxXDelta3.AutoSize = $true
$checkBoxXDelta3.Checked = $true
$form.Controls.Add($checkBoxXDelta3)

$labelTarget = New-Object System.Windows.Forms.Label
$labelTarget.Text = "Target folder :"
$labelTarget.Location = New-Object System.Drawing.Point(10,60)
$labelTarget.AutoSize = $true
$form.Controls.Add($labelTarget)

$textBoxTarget = New-Object System.Windows.Forms.TextBox
$textBoxTarget.Location = New-Object System.Drawing.Point(120, 58)
$textBoxTarget.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($textBoxTarget)

$btnBrowseTarget = New-Object System.Windows.Forms.Button
$btnBrowseTarget.Text = "..."
$btnBrowseTarget.Location = New-Object System.Drawing.Point(410, 57)
$btnBrowseTarget.Size = New-Object System.Drawing.Size(30, 23)
$btnBrowseTarget.Add_Click({
    $path = Select-FolderDialog
    if ($path) { $textBoxTarget.Text = $path }
})
$form.Controls.Add($btnBrowseTarget)

$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Output folder :"
$labelOutput.Location = New-Object System.Drawing.Point(10,100)
$labelOutput.AutoSize = $true
$form.Controls.Add($labelOutput)

$textBoxOutput = New-Object System.Windows.Forms.TextBox
$textBoxOutput.Location = New-Object System.Drawing.Point(120, 98)
$textBoxOutput.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($textBoxOutput)

$btnBrowseOutput = New-Object System.Windows.Forms.Button
$btnBrowseOutput.Text = "..."
$btnBrowseOutput.Location = New-Object System.Drawing.Point(410, 97)
$btnBrowseOutput.Size = New-Object System.Drawing.Size(30, 23)
$btnBrowseOutput.Add_Click({
    $path = Select-FolderDialog
    if ($path) { $textBoxOutput.Text = $path }
})
$form.Controls.Add($btnBrowseOutput)

# Output textbox
$textBoxLog = New-Object System.Windows.Forms.TextBox
$textBoxLog.Location = New-Object System.Drawing.Point(10, 170)
$textBoxLog.Size = New-Object System.Drawing.Size(460, 160)
$textBoxLog.Multiline = $true
$textBoxLog.ScrollBars = "Vertical"
$textBoxLog.ReadOnly = $true
$form.Controls.Add($textBoxLog)

# Button "Extract diff"
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Extract diff"
$btnStart.Location = New-Object System.Drawing.Point(180, 130)
$btnStart.Size = New-Object System.Drawing.Size(120, 30)

$btnStart.Add_Click({
    $textBoxLog.Clear()

    $sourcePath = $textBoxSource.Text
    $targetPath = $textBoxTarget.Text
    $outputPath = $textBoxOutput.Text

    try {
        $arguments = @{
            sourceFolder = $sourcePath
            targetFolder = $targetPath
            outputFolder = $outputPath
            "NonInteractive" = $true
        }

        if (-not $checkBoxXDelta3.Checked) {
            $arguments["NoXDelta3"] = $true
        }

        $output = & ".\wip5.ps1" @arguments

        $output | ForEach-Object { $textBoxLog.AppendText("$_`r`n") }
    }
    catch {
        $textBoxLog.AppendText("Error: $_`r`n")
    }
})

$form.Controls.Add($btnStart)
[void]$form.ShowDialog()
