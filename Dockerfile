#escape=`

# 基礎映像: Windows Server 2019 with .NET 4.7.2 and ASP.NET
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2-windowsservercore-ltsc2019

# 設定工作目錄
WORKDIR /Setup

# 步驟 1: 安裝必要的相依性套件 (使用正確的 PowerShell 指令)
RUN powershell -Command "`
    # 使用 Invoke-WebRequest 下載 VC++ Redistributable
    Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile vc_redist.x64.exe; `
    Start-Process -FilePath .\vc_redist.x64.exe -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item .\vc_redist.x64.exe; `
    `
    # 使用 Invoke-WebRequest 下載 .NET Core Hosting Bundle
    Invoke-WebRequest -Uri https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.18/dotnet-hosting-8.0.18-win.exe -OutFile dotnet-hosting-bundle.exe; `
    Start-Process -FilePath .\dotnet-hosting-bundle.exe -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item .\dotnet-hosting-bundle.exe; `
	`
    # 使用 Invoke-WebRequest 下載 ASP.NET Core runtime 	
	Invoke-WebRequest -Uri https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.18/aspnetcore-runtime-8.0.18-win-x64.exe -OutFile aspnetcore-runtime.exe; `
	Start-Process -FilePath .\aspnetcore-runtime.exe -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item .\aspnetcore-runtime.exe "

# ...
RUN powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force; $ErrorActionPreference = 'Stop'; New-Item -Path C:\Innovator -ItemType Directory -Force; icacls.exe 'C:\Innovator' /grant 'IIS_IUSRS:(OI)(CI)(M)' /T; Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect, IIS-ManagementScriptingTools -All";

# 複製Aras Innovator安裝程式
COPY InnovatorSetup.msi C:\Setup\InnovatorSetup.msi

# 複製啟動腳本到容器中
COPY start.ps1 C:\start.ps1

# 開放 HTTP 80 連接埠
EXPOSE 80

# 設定 Entrypoint，容器啟動時執行此腳本
# 該腳本將處理首次運行的安裝邏輯
ENTRYPOINT ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\start.ps1"]