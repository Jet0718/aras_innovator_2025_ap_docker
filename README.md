# 建立Aras Innovator 2025 的 Docker AP環境
嘗試使用Aras Innovator 2025的安裝檔案來建立Aras Innovator的Docker AP環境, 本docker image內容只會將必要的環境與安裝程式搭建複製進來,在建立docker container時,才會開始安裝Aras Innovator,所以docker run的時間會比較久(10-30分鐘), 注意的是,本環境並不包含SQL Server, 所以SQL Server是外部連接.

## 準備:
1. 在你的Windows環境裝好Docker Desktop,並啟動它(Aras Innovator必須使用windows base環境的docker).
2. 確認外部已有SQL Server且為相容版本(2012以上)的主機服務運行中.備好資料連線的位址與sa(或其他資料庫管理員的帳密或授權管理的windows帳號),建立好innovator,innovator_regular這兩個資料庫user的密碼.
3. 下載好[InnovatorSetup.msi](https://aras.com/en/download)的安裝程式(本例應先改命名為InnovatorSetup-2025.msi)
4. 預定義好容器要使用的MAC_Address,並以此向Aras申請好Aras Innovator 2025的[社群版授權碼](https://aras.com/en/support/licensekeyservice/community-edition?version=14.0.0)

## 安裝方式:
1. 將本倉庫git clone至你的工作根目錄,完成後切換到工作區中(ex: c:\test\aras_innovator_2025_ap_docker).
2. 申請 [Aras Innovator 2025的社群版安裝程式](https://aras.com/en/download). 並將它解壓後,得到InnovatorSetup.msi檔案,複製到工作區來,並更名為InnovatorSetup-2025.msi(供後續在容器中執行安裝, 本例使用的是 2025版本, 理論上14.x版本應皆適用,待驗證).
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

5. docker-compose.yml中 請將 mac_address 修改成你要指定的位址,此為你先前向Aras[申請社群版授權碼](https://aras.com/en/support/licensekeyservice/community-edition?version=14.0.0). 執行Docker Compose指令來建立docker 容器環境
```
docker-compose up -d
# 指令會很快結束,但所建了的容器在首次建立時,會需要十分鐘到二十多分鍾的時間來安裝Aras Innovator, 請稍候之. 此時你可以觀察該容器的logs訊息來確認是否完成.
```

6. 接下來就確認logs中的安裝需求訊息. 若無錯誤, 完成安裝後(完成訊息如下),待完成後,就可在宿主機採用 http://localhost/innovator 這個網址來連線.
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

## 常見問題:
Innovator安裝失敗(完裝成功 `exit code : 0` , 若為`16XX`則表示安裝失敗):
1. 請檢查sql server的連線位址是否正確,尤其是在容器內是否能連線至該DB,若不正確則應修正`.env`內的位址
2. 本安裝是以建立新資料庫為選項,故欲建立的資料庫名是否已存在,若存在則應先刪除或更名或更正`.env` 內的`IS_SQLSERVER_SERVER`的變數值.
3. 若要重新執行docker-compose, 注意檢查sql server的db是否已有同名的資料庫,若有,需要刪除,否則會安裝失敗.

## 總結:
Aras Innovator 2025 AP server 安裝前的預備環境, 本image需搭配幾個文件來建立容器: `innovatorSetup-2025.msi`(2025社群版安裝文件), `start.ps1` (安裝指令文件), `docker-compose.yml` (Compose設定文件), `.env` (安裝環境參數文件,可由`.env.example`複製而得).
詳情請參考 個人的github上說明: https://github.com/jet0718/aras_innovator_2025_ap_docker

作者: 羅仁 Jet Lo
