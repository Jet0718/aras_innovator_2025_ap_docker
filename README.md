# 建立Aras Innovator 2025 的 Docker AP環境
嘗試使用Aras Innovator 2025的安裝檔案來建立Aras Innovator的Docker AP環境, 注意的是,本環境並不包含SQL Server, 所以SQL Server是外部連接.
安裝方式:
1. 將本環境git clone至你的工作區.
2. 申請 Aras Innovator 2025的社群版安裝程式. 並將它複製到工作區來(供後續在容器中執行安裝, 本例使用的是 2025版本, 理論上14.x版本應皆適用,待驗證).
3. 建立 Docker Image環境 (當然你也可以採用現成的image:我在[DockerHub上的image](https://hub.docker.com/repository/docker/jetlo0718/innovator_pre_env/general)).
```sh
# 使用Dockerfile內容來建立image,過程中會複製 工作區的InnovatorSetup.msi與start.ps1會被docker複製到image中.
docker build . -t="[your image name]"
# 或
# 使用現成的 image file.
docker pull jetlo0718/innovator_pre_env:2025
```
4. 依你實際環境需要,將.env.example複製為.env, 修改 .env 環境變數的值 (如 sql server主機服務位置, sa與innovator*的密碼,還有 LICENSEKEY(先確認使用的MAC Address,申請好授權碼) ).

```conf
# Aras Innovator Environment Variables
INSTALLDIR=C:\Innovator
UPGRADEORINSTALL=1
WEBALIAS=innovator
SMTPSERVER=queue
VAULTNAME=default
VAULTFOLDER=C:\Innovator\Vault
DB_CREATE_NEW_OR_USE_EXISTING=0
IS_SQLSERVER_SERVER=192.168.10.125
IS_SQLSERVER_DATABASE=InnovatorDB
IS_SQLSERVER_AUTHENTICATION=1
IS_SQLSERVER_USERNAME=sa
IS_SQLSERVER_PASSWORD=Password@openplm
SQL_SERVER_LOGIN_NAME=innovator
SQL_SERVER_LOGIN_PASSWORD=innovator
SQL_SERVER_LOGIN_REGULAR_NAME=innovator_regular
SQL_SERVER_LOGIN_REGULAR_PASSWORD=innovator
INSTALL_CONVERSION_SERVER=1
CONVERSION_SERVER_NAME=ConversionServer
CONVERSION_SERVER_APP_URL=http://localhost/Innovator/Server/InnovatorServer.aspx
INSTALL_AGENT_SERVICE=1
ARAS_AGENTSERVICE_TO_INNOVATORSERVER_URL=http://localhost/Innovator/Server/InnovatorServer.aspx
INNOVATOR_TO_SERVICE_ADDRESS=http://localhost:8734/
AS_FOLDER=ArasInnovatorAgent
INSTALL_INNOVATOR_SERVER=1
INSTALL_VAULT_SERVER=1
INSTALL_OAUTH_SERVER=1
LICENSEKEY=<!-- name=Your Development Co. Ltd - Taiwan   mac_address=00-60-5A-8D-29-27   version=14.0  --><License  lic_type="Unlimited" lic_key="038784b748bce3d94d7035d946fbe4e5a" act_key="E7252CB668832F46BBC5A910BB20256E"/>
```   

5. docker-compose.yml中 請將 mac_address 修改成你要指定的位址,以利你向aras Innovator申請社群版授權碼(此時安裝授權碼會給空值). 執行Docker Compose指令來建立docker 容器環境
```
docker-compose up -d
# 首次建立時,可能會需要數分鐘到十多分鍾的時間來安裝Aras Innovator, 請稍候之.
```

6. 接下來就確認logs中的安裝需求訊息. 若無錯誤, 完成安裝後(完成訊息如下),待完成後,就可採用 http://localhost/innovator 這個網址來連線.
```
Checking IIS configuration...
網站清單：
name             state   physicalPath                 
----             -----   ------------                 
Default Web Site Started %SystemDrive%\inetpub\wwwroot

應用程式清單：

path                        PhysicalPath                   applicationPool     
----                        ------------                   ---------------     
/innovator                  C:\Innovator\Innovator\        Aras Innovator Ap...
/innovator/Client           C:\Innovator\Innovator\Client\ Aras Innovator Ap...
/innovator/ConversionServer C:\Innovator\ConversionServer\ Aras Conversion A...
/innovator/OAuthServer      C:\Innovator\OAuthServer\      Aras OAuth AppPoo...
/innovator/Server           C:\Innovator\Innovator\Server\ Aras Innovator Ap...
/innovator/Vault            C:\Innovator\VaultServer\      Aras Vault AppPoo...

Testing SQL Server connection...
✅ SQL Server 連線成功。
Ensuring World Wide Web Publishing Service (w3svc) is running...
✅ w3svc 服務正在運行。
🚀 容器正在運行。監控 w3svc 服務...
```

7. 常見問題:
若要重新執行docker-compose, 注意檢查sql server的db是否已有同名的資料庫,若有,需要刪除,否則會安裝失敗.
# 記得再啟動容器來試連線, 祝一切順利.
docker container start [your container name]

```
Aras Innovator 2025 AP server 安裝前的預備環境, 本image需搭配幾個文件來建立容器: innovatorSetup-2025.msi(2025社群版安裝文件), start.ps1 (安裝指令文件), docker-compose.yml (Compose設定文件), .env (安裝環境參數文件,可由.env.example複製而得).
詳情請參考 個人的github上說明: https://github.com/jet0718/aras_innovator_2025_ap_docker