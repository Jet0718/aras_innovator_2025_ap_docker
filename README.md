# 建立Aras Innovator 2025 的 Docker AP環境
嘗試使用Aras Innovator 2025的安裝檔案來建立Aras Innovator的Docker AP環境, 注意的是,本環境並不包含SQL Server, 所以SQL Server是外部連接.
安裝方式:
1. 將本環境git clone至你的工作區.
2. 申請 Aras Innovator 2025的社群版安裝程式. 並將它複製到工作區來(供後續在容器中執行安裝, 本例使用的是 2025版本, 其他鄰近的版本是否適用,需待驗證).
3. 建立 Docker Image環境 (當然你也可以採用現成的image:我在[DockerHub上的image](https://hub.docker.com/repository/docker/jetlo0718/innovator_pre_env/general)).
```
# 使用Dockerfile內容來建立image,過程中會複製 工作區的InnovatorSetup.msi與start.ps1會被docker複製到image中.
docker build . -t="[your image name]"

# 使用現成的 image file.
docker pull jetlo0718/innovator_pre_env:2025
```
4. 依你實際環境需要,修改 .env 環境變數的值 (如 sql server主機服務位置, sa與innovator*的密碼), 
5. docker-compose.yml中 請將 mac_address 修改成你要指定的位址,以利你向aras Innovator申請社群版授權碼(此時安裝授權碼會給空值). 執行Docker Compose指令來建立docker 容器環境
```
docker-compose up -d
# 首次安裝會需要數分鐘到十多分鍾的時間來安裝Aras Innovator, 請稍候之.
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

7. 若你以指定的 mac_address 申請了授權碼, 請利用 `docker cp `指令將 `C:\Innovator\InnovatorServerConfig.xml` 複製出來將授權碼維護進去後, 再複製進去容器中.
```
# 請記得先停止運行中的container;
docker container stop [your container name]
# 由容器中的目錄複製檔案到宿主機當下的目錄
docker cp [your container name]:C:\Innovator\InnovagtorServerConfig.xml .
# 編輯設定文件,將授權碼維護進去.
notepad InnovatorServerConfig.xml

# 修改後再將設定檔案複製回容器中.
docker cp InnovatorServerConfig.xml [your container name]:C:\Innovator\

# 記得再啟動容器來試連線, 祝一切順利.
docker container start [your container name]

```
Aras Innovator 2025 AP server 安裝前的預備環境, 本image需搭配幾個文件來建立容器: innovatorSetup.msi(2025社群版安裝文件), start.ps1 (安裝指令文件), docker-compose.yml (Compose設定文件), .env (安裝環境參數文件).
詳情請參考 個人的github上說明: https://github.com/jet0718/aras_innovator_2025_ap_docker