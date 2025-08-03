# 啟動腳本：start.ps1
# 本腳本將會執行 Aras Innovator 2025 的靜默安裝。
# 所有安裝參數現在從環境變數中讀取。

# 定義一個標記檔案的路徑，用來判斷是否已完成首次安裝
$InstallFlagFile = "C:\Innovator\install_complete.flag"
$msiPath = "C:\Setup\InnovatorSetup.msi"

# 檢查標記檔案是否存在
if (Test-Path $InstallFlagFile) {
    Write-Host "✅ Aras Innovator 已經安裝。跳過安裝步驟。"
} else {
    Write-Host "🚀 偵測到首次運行。開始安裝 Aras Innovator 2025..."
    Write-Host "   安裝程式來源： $msiPath"

    # 檢查安裝檔案是否存在
    if (!(Test-Path $msiPath)) {
        Write-Error "❌ 錯誤：在 C:\Setup 中找不到 InnovatorSetup.msi。請使用 '-v' 參數正確掛載安裝目錄。"
        Start-Sleep -Seconds 3600
        exit 1
    }

    # 定義所有必須的安裝參數環境變數名稱
    $requiredParams = @(
        "INSTALLDIR",
        "UPGRADEORINSTALL",
        "WEBALIAS",
        "SMTPSERVER",
        "VAULTNAME",
        "VAULTFOLDER",
        "DB_CREATE_NEW_OR_USE_EXISTING",
        "IS_SQLSERVER_SERVER",
        "IS_SQLSERVER_DATABASE",
        "IS_SQLSERVER_AUTHENTICATION",
        "IS_SQLSERVER_USERNAME",
        "IS_SQLSERVER_PASSWORD",
        "SQL_SERVER_LOGIN_NAME",
        "SQL_SERVER_LOGIN_PASSWORD",
        "SQL_SERVER_LOGIN_REGULAR_NAME",
        "SQL_SERVER_LOGIN_REGULAR_PASSWORD",
        "INSTALL_CONVERSION_SERVER",
        "CONVERSION_SERVER_NAME",
        "CONVERSION_SERVER_APP_URL",
        "INSTALL_AGENT_SERVICE",
        "ARAS_AGENTSERVICE_TO_INNOVATORSERVER_URL",
        "INNOVATOR_TO_SERVICE_ADDRESS",
        "AS_FOLDER",
        "INSTALL_INNOVATOR_SERVER",
        "INSTALL_VAULT_SERVER",
        "INSTALL_OAUTH_SERVER"
    )

	# 檢查所有環境變數是否都已設定
	$msiArgs = @("/i", "`"$msiPath`"", "/qn", "/norestart")

	# 為了穩定性，先一次性獲取所有環境變數到一個雜湊表中
	$allEnvVars = Get-ChildItem Env:

	Write-Host "🔍 正在驗證並建立 MSI 安裝參數..."
	foreach ($param in $requiredParams) {
		# 在獲取到的完整清單中，按名稱查找我們需要的變數
		$variable = $allEnvVars | Where-Object { $_.Name -eq $param }
		
		if ($null -ne $variable) {
			# 如果 $variable 不是 null，表示環境變數存在（即使其值為空）
			$paramValue = $variable.Value
			
			# 將參數和值加入到陣列中。這個語法會正確處理 LICENSEKEY="" 的情況
			$msiArgs += "$param=`"$paramValue`""
			Write-Host "  ✅ 參數 '$param' 已找到，值為: '$paramValue'"

		} else {
			# 如果在完整清單中都找不到，表示變數確定未定義
			Write-Error "❌ 致命錯誤：必要的環境變數 '$param' 未定義。請檢查 .env 檔案。"
			Write-Host "安裝無法繼續。"
			Start-Sleep -Seconds 3600
			exit 1
		}
	}

	# 手動添加空的 LICENSEKEY 參數，繞過 Docker Compose 的限制
	Write-Host "  ✅ 手動添加特殊參數 'LICENSEKEY'，值為: ''"
	$msiArgs += 'LICENSEKEY=""'

	$logPath = "C:\Innovator\Vault\InnovatorSetupLog.log"
	$msiArgs += "/l*v", "`"$logPath`""

    # 顯示即將執行的安裝命令及其參數
    Write-Host "➡️ 即將執行安裝命令，參數如下："
    Write-Host "msiexec.exe $($msiArgs -join ' ')"

    # 執行靜默安裝
    Write-Host "➡️ 執行靜默安裝...這可能需要一些時間。"
    try {
        $ErrorActionPreference = 'Stop'
        # 為了更好地排查，這次使用 cmd /c 繞過 PowerShell 的參數解析，直接傳遞字串
        $cmdArgs = "/c start /wait msiexec.exe $($msiArgs -join ' ')"
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -Wait -PassThru
        
        # 檢查 MSI 安裝的回傳值
        if ($process.ExitCode -ne 0) {
            # 將 MSI 錯誤碼轉譯為易於理解的訊息
            $errorMessage = switch ($process.ExitCode) {
                1601 { "使用者已取消安裝。"}
                1602 { "使用者已取消安裝。"}
                1603 { "安裝過程中發生嚴重錯誤。"}
                1605 { "此操作只對目前已安裝的產品有效。"}
                default { "安裝失敗，錯誤碼：$($process.ExitCode)" }
            }
            Write-Error "❌ 錯誤：$errorMessage。請檢查 $logPath 獲取詳細資訊。"
            Start-Sleep -Seconds 3600
            exit 1
        }

        Write-Host "✅ msiexec.exe 安裝程式成功完成。"

        # 建立標記檔案，標記安裝已完成
        New-Item -Path $InstallFlagFile -ItemType File -Force | Out-Null
        Write-Host "✅ 安裝完成標記檔案已建立。"

    } catch {
        Write-Error "❌ 錯誤：在執行 msiexec.exe 安裝時發生例外。錯誤訊息：$_"
        Write-Error "請檢查容器內的 $logPath 日誌文件以獲取詳細資訊。"
        Start-Sleep -Seconds 3600
        exit 1
    }
}

# 檢查 IIS 配置
Write-Host "Checking IIS configuration..."
try {
    Import-Module WebAdministration -ErrorAction Stop
    Write-Host "網站清單："
    Get-Website | Format-Table Name, State, PhysicalPath
    Write-Host "應用程式清單："
    Get-WebApplication -Site "Default Web Site" | Format-Table Path, PhysicalPath, applicationPool
} catch {
    Write-Warning "⚠️ 警告：無法載入 WebAdministration 模組或檢查 IIS 配置。錯誤訊息：$_"
}

# 檢查主要檔案是否存在，這是一個額外的驗證步驟
<# Write-Host "Testing installation integrity..."
if (Test-Path "C:\Innovator\Innovator\Server\InnovatorServer.aspx") {
    Write-Host "✅ InnovatorServer.aspx 檔案存在。安裝驗證成功。"
} else {
    Write-Warning "⚠️ 警告： InnovatorServer.aspx 未在 C:\Innovator\Innovator\Server\InnovatorServer.aspx 找到。"
} #>

# 測試 SQL Server 連線
Write-Host "Testing SQL Server connection..."
try {
    $connectionTest = Test-NetConnection -ComputerName host.docker.internal -Port 1433 -ErrorAction Stop
    if ($connectionTest.TcpTestSucceeded) {
        Write-Host "✅ SQL Server 連線成功。"
    } else {
        Write-Warning "⚠️ 警告： SQL Server 連線失敗。Host: host.docker.internal, Port: 1433."
    }
} catch {
    Write-Warning "⚠️ 警告： 無法測試 SQL Server 連線。錯誤訊息：$_"
}

# 確保 IIS 服務運行
Write-Host "Ensuring World Wide Web Publishing Service (w3svc) is running..."
try {
    $service = Get-Service -Name w3svc -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        Write-Host "Starting w3svc service..."
        Start-Service -Name w3svc -ErrorAction Stop
    }
    Write-Host "✅ w3svc 服務正在運行。"
} catch {
    Write-Error "❌ 錯誤：無法啟動 w3svc 服務。錯誤訊息：$_"
    Start-Sleep -Seconds 3600
    exit 1
}

# 保持容器運行並監控服務狀態
Write-Host "🚀 容器正在運行。監控 w3svc 服務..."
while ($true) {
    try {
        $service = Get-Service -Name w3svc -ErrorAction Stop
        if ($service.Status -ne 'Running') {
            Write-Warning "⚠️ w3svc 服務停止了。嘗試重新啟動..."
            Start-Service -Name w3svc -ErrorAction Stop
            Write-Host "✅ w3svc 服務已重新啟動。"
        }
    } catch {
        Write-Error "❌ 錯誤：監控 w3svc 服務時發生錯誤。錯誤訊息：$_"
    }
    Start-Sleep -Seconds 60
}
