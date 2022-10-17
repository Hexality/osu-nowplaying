#Powered by https://github.com/Hexality
using namespace System.Windows.Forms
using namespace System.Windows
using namespace System.Drawing
param ([string]$id)
Add-Type -Assembly System.Windows.Forms
Add-Type -Assembly System.Drawing
if (-not (Test-Path id.txt)) { $null > id.txt }
if (-not $id) {
    if ((Get-ChildItem).Name -contains 'id.txt') { 
        $id = Get-Content id.txt
    } else {
    "Please add your discord id to 'id.txt'"
    Start-Sleep -s 5
    break
    }
}
# Main #
$f = [Form]@{
    Text = 'osu!nowPlaying'
    MinimumSize = @{
        Width = 560
        Height = 82
    }
    Size = @{
        Width = 560
        Height = 82
    }
    MaximumSize = @{
        Width = 560
        Height = 82
    }
    StartPosition = 0
    ControlBox = $False
    SizeGripStyle = 'Hide'
}
$l = [Label]@{
    Text = 'Loading...'
    AutoSize = $Frue
    Size = @{
        Width = 422
        Height = 16
    }
    #BackColor = '#e1e1e1'
    Font = [Font]::new('Arial', 11)
    Location = [Point]::new(8,14)
}
$b = [Button]@{
    Text = 'Stop'
    Size = @{
        Height = 28
    }
    MinimumSize = @{
        Height = 28
        Width = '96'
    }
    MaximumSize = @{
        Height = 28
    }
    FlatStyle = 'Flat'
    Anchor = 'Right, left, bottom'
    BackColor = '#0DFFFFFF'
    Location = [Point]::new($f.Size.Width-120,8)
}
$b.FlatAppearance.BorderSize = 0
$b.FlatAppearance.MouseOverBackColor = '#1AFFFFFF'
$b.FlatAppearance.MouseDownBackColor = '#1Ac22d1b'

$t = [Timer]@{
    Interval = 10000
}

$t_Tick={
    if((Get-Process -Name "osu!" -ErrorAction SilentlyContinue).HasExited -contains $false){
    $np = (Invoke-WebRequest https://api.lanyard.rest/v1/users/"$id"?type=json | ConvertFrom-Json).data
    $details = (($np.activities -match 'osu') -match 'details').details
    $state = ($np.activities -match 'osu').state
    $o = if (-not $details) {
            $l.Text = "Currently $($state)"
            $f.Refresh()
            "$($state) | " 
        } else { 
            $l.Text = "Currently playing: $(($details).Substring(0,45))..."
            $f.Refresh()
            "$($details) |"
        }
    $o > np.log
    }
    else {
        $l.Text = 'Please close the window'
        $f.Refresh()
        $f.Close()
        $f.Dispose()
    }
}

$b.Add_Click({
    $t.Interval = ((60)*1000)
    $f.Close()
    $f.Dispose()
})
$f.Add_Shown({
    $f.Activate()
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
    })

$t.Enabled = $True
$t.add_Tick($t_Tick)    
$f.Controls.AddRange(@($b,$l))
[void]$f.ShowDialog()
$f.Dispose()