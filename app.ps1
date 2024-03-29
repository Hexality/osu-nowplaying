#requires -version 7.3
using namespace System.Net
using namespace System.IO
using namespace System.Drawing
using namespace System.Windows
using namespace System.Windows.Forms

## Load Assembly
Add-Type -Assembly System.Windows.Forms
## WinAPI Backdrop
$code = @'
[System.Runtime.InteropServices.DllImport("gdi32.dll")]
public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect,
    int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
'@
$rect = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru

$global:appRoot = if ($PSScriptRoot) { $PSScriptRoot } else {
    (Get-Location).Path
}

## Variables
$global:npFile = Join-Path $appRoot nowplaying.log
$global:cfgPath = Join-Path $appRoot config.json
$global:webClient = [WebClient]@{}
if ((($PSVersionTable.OS -replace '[\sa-zA-Z]').Split('.')[2]) -gt 22000) { 
    $global:font = 'Segoe UI Variable Display' 
    $global:iconFont = 'Segoe Fluent Icons'
}
else { 
    $global:font = 'Segoe UI' 
    $global:iconFont = 'Segoe MDL2 Assets'
}
$global:started = $False

$global:logo = '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'
$global:icon = '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'

## Functions
function loadBase64 {
    param([switch]$ico, [switch]$img, [string]$base)
    $iB = [Convert]::FromBase64String($base)
    $ms = [MemoryStream]::new($iB, 0, $iB.Length)
    $ms.Write($iB, 0, $iB.Length);
    return @(
        switch ($true) {
            $ico { [Icon]::FromHandle(([System.Drawing.Bitmap]::new($ms)).GetHicon()) }
            $img { [Image]::FromStream($ms, $true) }
        }
    )
}
function RequestID {
    param([switch]$Invalid)
    $ridM = [Form]@{
        Text            = "Error"
        Size            = [Size]::new(370, 160)
        StartPosition   = 1
        ShowIcon        = $False
        FormBorderStyle = [FormBorderStyle]::FixedDialog
        TopMost         = $True
        BackColor       = "#191919"
    }

    $ridT = [Label]@{
        Text      = if($invalid) {"Invalid ID, please re-enter it!"} else {"Please enter you discord ID bellow:"}
        Size      = [Size]::new($ridM.ClientRectangle.Width, ($ridM.Height - 120))
        Font      = [Font]::new('Segoe UI Variable Display', 10, [FontStyle]::Regular)
        TextAlign = [ContentAlignment]::MiddleCenter
        ForeColor = "#c0c0c0"
    }

    $ridI = [TextBox]@{
        #PlaceholderText = "ID"
        MaxLength       = 19
        Size            = [Size]::new(120)
        TextAlign       = 2
        Location        = [Point]::new(($ridM.ClientRectangle.Width / 2) - (120 / 2), $ridT.Height)
		BackColor 		= "#2d2d2d"
		ForeColor = "#c0c0c0"
    }

    $ridB = [Button]@{
        Text      = "Confirm"
        Size      = [Size]::new(64, 30)
        Location  = [Point]::new((($ridM.ClientRectangle.Width / 2) - 32), ($ridM.ClientRectangle.Height - 42))
        FlatStyle = [FlatStyle]::Flat
        BackColor = "#2d2d2d"
        ForeColor = "#c0c0c0"
    }

    $ridB.Add_Click({
            if ($ridI.Text.Length -ge 17) {
                $global:cfg = @{
                    id        = $ridI.Text;
                    separator = "|"
                }
                $ridM.Dispose()
                MainGUI
            }
            else {
                ErrPop -idErr
                $ridM.Dispose()
                RequestID -Invalid
            }

        })

    $ridI.Add_TextChanged({
            if ($this.Text -match '\D') {
                $cursorPos = $this.SelectionStart
                $this.Text = $this.Text -replace '\D'
                $this.SelectionStart = $this.Text.Length
            }
        })
    $ridM.Add_Load({
            $ridB_Corner = $rect::CreateRoundRectRgn(0, 0, $ridB.Width, $ridB.Height, 4, 4)
            $ridB.Region = [Region]::FromHrgn($ridB_Corner)
        })
    $ridM.Controls.AddRange(@($ridB, $ridI, $ridT))
    [void]$ridM.ShowDialog()
    [void]$ridM.Dispose()
}
function GetConfig {
    if (Test-Path $cfgPath) {
        $global:cfg = Get-Content -Raw $cfgPath | ConvertFrom-Json
        [void]$cfg
        if ($cfg.id.length -ge 17) {
            if ($cfg.id.length -le 19) {
                MainGUI
            }
            else {
                ErrPop -idErr
            }
        }
        else {
            ErrPop -idErr
        }
    }
    else {
        RequestID
    }
}
function SaveConfig {
    $cfg | ConvertTo-Json > $cfgPath
}
function exportInfo {
    [File]::WriteAllText($npFile, $(if ($gameInfo.details) {$gameInfo.details + " " + $cfg.separator} else{""}))
}
function GetData {
    try {
        $payload = $webClient.DownloadString("https://api.lanyard.rest/v1/users/$($cfg.id)`?type=json")
    }
    catch {
        ErrPop -idErr
    }
    finally {
        if ($payload) {
            $json = $payload | ConvertFrom-Json
            if ($json.success) {
                $data = $json.data
                $activity = $data.activities | Where-Object -Property Name -eq 'osu!'
                <#$stateRef = (Compare-Object @(
                    "Idle", 
                    "Choosing a beatmap", 
                    "Modding a beatmap", 
                    "Editing a beatmap", 
                    "Watching *'s replay", 
                    "Spectating *", 
                    "Looking for a lobby", 
                    "In a lobby"
                ) $activity.state -ExcludeDifferent | Select-Object -Expand SideIndicator) -eq "=="#>
                $global:gameInfo = @{
                    name    = $activity.name
                    details = $activity.details
                    state   = $activity.state
                }
                $userData = $data.discord_user
                $global:userInfo = @{
                    name   = $userData.username + "#" + $userData.discriminator
                    status = $data.discord_status
                    avatar = $userData.avatar
                }
            }
            elseif (-not $json.success) {
                ErrPop -lanErr
            }
        }
    }
}
function MainGUI {
    GetData
    $aaaa_Icon = loadBase64 -ico -base $icon
    $aaaa = [Form]@{
        Name            = "UI"
        Text            = "osu!NowPlaying"
        Size            = [Size]::new(600, 140)
        FormBorderStyle = 0
        Icon            = $aaaa_Icon
        BackColor       = "#191919"
        ForeColor       = "#c0c0c0"
    }
    @( #Topbar
        @( #DragHandle
            $bbba = [Panel]@{
                Size      = [Size]::new($aaaa.Width, 50)
                Location  = [Point]::new(0, 0)
                BackColor = "#2d2d2d"
            }
            $bbbb_Image = loadBase64 -img -base $logo
            $bbbb = [PictureBox]@{
                Image    = $bbbb_Image
                Width    = $bbbb_Image.Width
                Location = [Point]::new(16, 15)
            }
            $bbbe = [Button]@{
                Text      = ""
                Font      = [Font]::new($iconFont, 11, [FontStyle]::Regular)
                Size      = [Size]::new(40, 40)
                Location  = [Point]::new($bbbb_Image.Width + 22, 6)
                FlatStyle = [FlatStyle]::Flat
                TextAlign = [ContentAlignment]::MiddleCenter
                BackColor = "#3a3a3a"
                ForeColor = "#c0c0c0"
            }
            $bbbe.Add_Click({
                    if ($global:started) {
                        $this.Text = ""
                        $global:started = $False
                        $t.Enabled = $False
                        [File]::WriteAllText($npFile, $null)
                        $this.FlatAppearance.MouseDownBackColor = "#4b4b4b"
                        $this.FlatAppearance.MouseOverBackColor = "#454545"
                        $this.BackColor = "#3a3a3a"
                        $this.ForeColor = "#c0c0c0"
                        $dddb.Text = ""
                        $dddc.Text = ""
                        $dddb.Refresh()
                        $dddc.Refresh()
                        $bbbe.Refresh()
                        $bbbc.Enabled = $True
                    }
                    else {
                        $this.Text = ""
                        $this.FlatAppearance.MouseDownBackColor = "#43AB52"
                        $this.FlatAppearance.MouseOverBackColor = "#6ABA61"
                        $this.BackColor = "#69BB62"
                        $this.ForeColor = "#303030"
                        GetData
                        $dddb.Text = $gameInfo.state
                        $dddc.Text = $gameInfo.details
                        $dddb.Refresh()
                        $dddc.Refresh()
                        $bbbe.Refresh()
                        $bbbc.Enabled = $False
                        $global:started = $True
                        $t.Enabled = $True
                    }
                })
            $bbba.Add_MouseDown({
                    $global:wDrag = $True 
                    $global:mDragX = [Cursor]::Position.X - $aaaa.Left
                    $global:mDragY = [Cursor]::Position.Y - $aaaa.Top
                    [void]@($wDrag, $mDragX, $mDragY)
                })
            $bbba.Add_MouseMove({
                    if ($global:wDrag) {
                        $scr = [Screen]::PrimaryScreen.WorkingArea
                        $curX = [Cursor]::Position.X
                        $curY = [Cursor]::Position.Y
                        [int]$newX = [Math]::Min($curX - $global:mDragX, $scr.Right - $aaaa.Width)
                        [int]$newY = [Math]::Min($curY - $global:mDragY, $scr.Bottom - $aaaa.Height)
                        $aaaa.Location = [Point]::new($newX, $newY)
                    }
                })
            $bbba.Add_MouseUp({
                    $global:wDrag = $False
                    [void]$wDrag
                })
        )
        @( #Window controls
            $bbbc = [Button]@{
                Name      = "Close"
                Text      = ""
                Font      = [Font]::new($iconFont, 9, [FontStyle]::Regular)
                TextAlign = [ContentAlignment]::MiddleCenter
                FlatStyle = [FlatStyle]::Flat
                Size      = [Size]::new(34, 34)
                Location  = [Point]::new($aaaa.ClientRectangle.Width - 43, 8)
                ForeColor = "#c0c0c0"
            }
            $bbbc.Add_Click({
                    $aaaa.Close()
                    $aaaa.Dispose()
                })
            $bbbd = [Button]@{
                Name      = "Minimize"
                Text      = ""
                Font      = [Font]::new($iconFont, 9, [FontStyle]::Regular)
                TextAlign = [ContentAlignment]::MiddleCenter
                FlatStyle = [FlatStyle]::Flat
                Size      = [Size]::new(34, 34)
                Location  = [Point]::new($bbbc.Location.X - 38, 8)
                ForeColor = "#c0c0c0"
            }
            $bbbd.Add_Click({
                    $aaaa.WindowState = [FormWindowState]::Minimized
                })
        )
        @( #UserInfo
            $ccca = [Panel]@{
                Name      = "Status"
                Size      = [Size]::new(120, 34)
                Padding   = [Padding]::new(8)
                Location  = [Point]::new($bbbd.Location.X - 128, 8)
                BackColor = "#3a3a3a"
            }
            $cccb = [Label]@{
                Name      = "Status_Label"
                Text      = "Logged as"
                Size      = [Size]::new($ccca.Width - 8, ($ccca.Height / 2) - 1)
                Font      = [Font]::new($font, 7, [FontStyle]::Regular)
                Location  = [Point]::new(2, 2)
                TextAlign = [ContentAlignment]::MiddleLeft
                ForeColor = "#c0c0c0"
                #AutoEllipsis = $True
            }
            $cccc = [Label]@{
                Name         = "Status_Label-2"
                Text         = "$($userInfo.name)"
                Size         = [Size]::new($cccb.Width, ($cccb.Height))
                Font         = [Font]::new($font, 9, [FontStyle]::Bold)
                Location     = [Point]::new(2, $cccb.Height - 2)
                ForeColor    = "#c0c0c0"
                #TextAlign = [ContentAlignment]::MiddleLeft
                AutoEllipsis = $True
            }
        )
    )
    @( #Content Panel
        $ddda = [Panel]@{
            Name     = "Content"
            #BackColor = '#000000'
            Size     = [Size]::new($aaaa.Width - 32, ($aaaa.Height - $bbba.Height - 32))
            Location = [Point]::new(16, $bbba.Height + 16)
        }
        $dddb = [Label]@{
            Text      = ""
            AutoSize  = $True
            Font      = [Font]::new($font, 12, [FontStyle]::Bold)
            ForeColor = "#c0c0c0"
        }
        $dddc = [Label]@{
            Text         = ""
            Size         = [Size]::new($ddda.Width - 32, 31)
            Location     = [Point]::new(12, $dddb.Height + 8)
            Font         = [Font]::new($font, 14, [FontStyle]::Regular)
            ForeColor    = "#c0c0c0"
            AutoEllipsis = $True
        }
        $ddda.Controls.AddRange(@(
                $dddb,
                $dddc
            ))
    )
    @( #Form load arguments
        $aaaa.Add_Load({
                $bbbc.FlatAppearance.BorderSize = 0
                $bbbd.FlatAppearance.BorderSize = 0
                $bbbe.FlatAppearance.BorderSize = 0
                $bbbd.FlatAppearance.MouseDownBackColor = "#4b4b4b"
                $bbbd.FlatAppearance.MouseOverBackColor = "#454545"
                $aaaa_Corner = $rect::CreateRoundRectRgn(0, 0, $aaaa.Width, $aaaa.Height, 8, 8)
                $bbbc_Corner = $rect::CreateRoundRectRgn(0, 0, $bbbc.Width, $bbbc.Height, 4, 4)
                $bbbd_Corner = $rect::CreateRoundRectRgn(0, 0, $bbbd.Width, $bbbd.Height, 4, 4)
                $bbbe_Corner = $rect::CreateRoundRectRgn(4, 2, $bbbe.Width - 1, $bbbe.Height - 3, 6, 6)
                $ccca_Corner = $rect::CreateRoundRectRgn(0, 0, $ccca.Width, $ccca.Height, 7, 7)
                $aaaa.Region = [Region]::FromHrgn($aaaa_Corner)
                $bbbc.Region = [Region]::FromHrgn($bbbc_Corner)
                $bbbd.Region = [Region]::FromHrgn($bbbd_Corner)
                $bbbe.Region = [Region]::FromHrgn($bbbe_Corner)
                $ccca.Region = [Region]::FromHrgn($ccca_Corner)
                $aaaa.Activate()
            })
        $aaaa.Add_Closing({
                SaveConfig
                [File]::WriteAllText($npFile, $null)
                $aaaa.Dispose()
            })
    )
    @( #Form controls
        $ccca.Controls.AddRange(@(
                $cccb,
                $cccc
            ))
        $bbba.Controls.AddRange(@(
                $ccca,
                $bbbe,
                $bbbd,
                $bbbc,
                $bbbb
            ))
        $aaaa.Controls.AddRange(@(
                $bbba, $ddda
            ))
    )
    @( #Timer
        $t = [Timer]@{ 
            Interval = 1500
            Enabled  = $False
        }
        $t_Tick = {
            GetData
            exportInfo
            $dddb.Text = $gameInfo.state
            $dddc.Text = $gameInfo.details
            $dddb.Refresh()
            $dddc.Refresh()
            if(-not (Get-Process -Name "osu!" -ErrorAction SilentlyContinue)) {
                [File]::WriteAllText($npFile, $null)
                $t.Enabled = $False
                $aaaa.Close()
                $aaaa.Dispose()
            }
        }
        $t.Add_Tick($t_Tick)
    )
    [void]$aaaa.ShowDialog()
}
function ErrPop {
    param([switch]$lanErr, [switch]$idErr, [switch]$runErr)
    $popM = [Form]@{
        Text            = "Error"
        Size            = [Size]::new(370, 140)
        StartPosition   = 1
        ShowIcon        = $False
        FormBorderStyle = [FormBorderStyle]::FixedDialog
        TopMost         = $True
        BackColor       = "#191919"
    }
    $popT = [Label]@{
        Text      = ""
        Size      = [Size]::new($popM.ClientRectangle.Width, ($popM.Height - 80))
        Font      = [Font]::new($font, 10, [FontStyle]::Regular)
        ForeColor = "#c0c0c0"
        TextAlign = [ContentAlignment]::MiddleCenter
    }
    switch ($True) {
        $lanErr {
            $popT.Text = "An error ocurred on lanyard's side.`n- User not monitored."
            $popT.Refresh()
        }
        $idErr {
            $popT.Text = "Our hamsters detected an issue...`nAre you sure the id inserted is correct?"
            $popT.Refresh()
        }
        $runErr {
            $popT.Text = "Please open the game before `nusing the application."
            $popT.Refresh()
        }
    }
    $popB = [Button]@{
        Text      = "Close"
        Size      = [Size]::new(64, 30)
        Location  = [Point]::new((($popM.ClientRectangle.Width / 2) - 32), ($popM.ClientRectangle.Height - 38))
        FlatStyle = [FlatStyle]::Flat
        BackColor = "#2d2d2d"
        ForeColor = "#c0c0c0"
    }
    $popM.Controls.AddRange(@($popB, $popT))
    $popB.Add_Click({
            $popM.Dispose()
        })
    $popM.Add_Load({
            $popB.FlatAppearance.BorderSize = 0
            $popM.Refresh()
            $popB_Corner = $rect::CreateRoundRectRgn(0, 0, $popB.Width, $popB.Height, 4, 4)
            $popB.Region = [Region]::FromHrgn($popB_Corner)
        })
    [void]$popM.ShowDialog()
}

## Runcode
if (Get-Process -Name "osu!" -ErrorAction SilentlyContinue) {
	GetConfig
	} 
else {
	ErrPop -runErr
}