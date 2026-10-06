# ========== 推送 GitHub ==========
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Continue'
$repoDir = 'D:\test'

# 创建进度窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = '推送 GitHub'
$form.Size = New-Object System.Drawing.Size(420, 220)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = '#f8f9fa'

# 标题
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = '正在推送代码到 GitHub...'
$titleLabel.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = '#202124'
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($titleLabel)

# 状态文字
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = '准备中...'
$statusLabel.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)
$statusLabel.ForeColor = '#5f6368'
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(20, 60)
$form.Controls.Add($statusLabel)

# 进度条
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 90)
$progress.Size = New-Object System.Drawing.Size(365, 20)
$progress.Style = 'Continuous'
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

# 关闭按钮
$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = '关闭'
$closeBtn.Location = New-Object System.Drawing.Point(160, 130)
$closeBtn.Size = New-Object System.Drawing.Size(100, 32)
$closeBtn.FlatStyle = 'Flat'
$closeBtn.BackColor = '#1a73e8'
$closeBtn.ForeColor = '#ffffff'
$closeBtn.FlatAppearance.BorderSize = 0
$closeBtn.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)
$closeBtn.Enabled = $false
$closeBtn.Add_Click({ $form.Close() })
$form.Controls.Add($closeBtn)

# 显示窗口
$form.Add_Shown({
    Set-Location $repoDir
    Start-Sleep -Milliseconds 200

    function Update-UI($status, $progressValue) {
        $statusLabel.Text = $status
        $progress.Value = $progressValue
        [System.Windows.Forms.Application]::DoEvents()
    }

    try {
        # 检查 git
        Update-UI '检查 git 环境...' 5
        $gitCheck = git --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw '没有找到 git 命令，请先安装 Git'
        }

        # git add
        Update-UI '暂存所有改动 (git add)...' 25
        git add . 2>&1 | Out-Null

        # git commit
        Update-UI '提交改动 (git commit)...' 50
        $commitOutput = git commit -m "auto update" 2>&1
        # 没有改动时 commit 会失败，但不算错误

        # git push
        Update-UI '推送到 GitHub (git push)...' 75
        $pushOutput = git push 2>&1
        if ($LASTEXITCODE -ne 0) {
            # 检查是否是 "up-to-date"
            if ($pushOutput -match 'up-to-date|Everything up-to-date') {
                Update-UI '没有新改动，已是最新' 100
            } else {
                throw "推送失败：`n$pushOutput"
            }
        } else {
            Update-UI '推送完成！' 100
        }

        $titleLabel.Text = '✅ 推送成功'
        $titleLabel.ForeColor = '#1e8e3e'
        $statusLabel.Text = 'GitHub Pages 约 1~2 分钟后自动更新'
        $closeBtn.Enabled = $true

    } catch {
        $titleLabel.Text = '❌ 推送失败'
        $titleLabel.ForeColor = '#d93025'
        $statusLabel.Text = $_.Exception.Message
        $statusLabel.MaximumSize = New-Object System.Drawing.Size(365, 60)
        $progress.Value = 0
        $closeBtn.Enabled = $true
    }
})

[void]$form.ShowDialog()