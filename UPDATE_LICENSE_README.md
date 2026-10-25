# Aras Innovator License Update Tool

## 概述

此 PowerShell 腳本用於在 Docker 容器已建立並運行後，動態更新 Aras Innovator 的 License。

## 使用方法

### 基本用法

```powershell
.\Update-InnovatorLicense.ps1 -ContainerName "aras2025_ap" -LicenseString '<License  lic_type="Unlimited" lic_key="YOUR_KEY" act_key="YOUR_ACT_KEY"/>'
```

### 範例

```powershell
.\Update-InnovatorLicense.ps1 `
  -ContainerName "aras2025_ap" `
  -LicenseString '<License  lic_type="Unlimited" lic_key="03004c748bbf3d94d7033d489fbe7e53" act_key="E7939CA833634F46AAC5A910AA20084B"/>'
```

### 使用預設容器名稱

如果容器名稱是 `aras2025_ap`（預設值），可以簡化為：

```powershell
.\Update-InnovatorLicense.ps1 -LicenseString '<License  lic_type="Unlimited" lic_key="03004c748bbf3d94d7033d489fbe7e53" act_key="E7939CA833634F46AAC5A910AA20084B"/>'
```

## 功能說明

此腳本自動執行以下步驟：

1. **驗證容器狀態**
   - 確認指定的容器正在運行
   - 如果容器未運行，腳本會終止並顯示錯誤

2. **建立備份**
   - 備份原始的 `InnovatorServerConfig.xml` 到 `InnovatorServerConfig.xml.backup`
   - 如需復原，可手動將備份檔案複製回去

3. **更新 License**
   - 在 XML 檔案中找到 `<License>` 元素
   - 用新的 License 字符串替換舊的
   - 保存更新後的配置檔案

4. **重啟應用程式池**
   - 重新啟動 "Aras Innovator AppPool ASP.NET Core"
   - 應用程式池重啟後新 License 即生效

## 配置檔案位置

容器內的配置檔案路徑：
- **主配置檔案**: `C:\Innovator\Innovator\Server\InnovatorServerConfig.xml`
- **備份檔案**: `C:\Innovator\Innovator\Server\InnovatorServerConfig.xml.backup`

## 預期執行結果

成功執行時的輸出範例：

```
========================================
Aras Innovator License Update Tool
========================================

[1/4] Checking if container 'aras2025_ap' is running...
✓ Container is running

[2/4] Preparing to update license...
  Config file: C:\Innovator\Innovator\Server\InnovatorServerConfig.xml
  Backup file: C:\Innovator\Innovator\Server\InnovatorServerConfig.xml.backup

[3/4] Creating backup and updating license in container...
✓ Backup created: C:\Innovator\Innovator\Server\InnovatorServerConfig.xml.backup
✓ License element updated
✓ InnovatorServerConfig.xml saved
✓ License updated successfully

[4/4] Recycling Aras Innovator AppPool...
✓ AppPool recycled successfully

========================================
License update completed successfully!
========================================

Next steps:
  1. Wait a few seconds for the AppPool to restart
  2. Access http://localhost/innovator/client in your browser
  3. The new license should now be active
```

## 錯誤排除

### 容器未運行
```
✗ Error: Container 'aras2025_ap' is not running. Please start the container first.
```
**解決方案**: 確保容器已啟動
```powershell
docker-compose up -d
```

### License 字符串格式不正確
確保 License 字符串是完整的 XML 元素，格式如下：
```xml
<License  lic_type="Unlimited" lic_key="YOUR_KEY" act_key="YOUR_ACT_KEY"/>
```

### 需要復原舊 License
從容器內執行：
```powershell
docker exec aras2025_ap powershell -Command "Copy-Item 'C:\Innovator\Innovator\Server\InnovatorServerConfig.xml.backup' 'C:\Innovator\Innovator\Server\InnovatorServerConfig.xml' -Force"
```

然後重啟應用程式池：
```powershell
docker exec aras2025_ap powershell -Command "C:\Windows\System32\inetsrv\appcmd.exe recycle apppool 'Aras Innovator AppPool ASP.NET Core'"
```

## 常見問題

**Q: 腳本執行多少次？**
A: 可以根據需要執行多次。每次執行都會建立新的備份，覆蓋舊備份。

**Q: License 更新後立即生效嗎？**
A: 應用程式池重啟後（通常 5-10 秒）生效。如需確認，可訪問 Web 應用程式檢查 License 狀態。

**Q: 是否支援多容器場景？**
A: 支援。透過 `-ContainerName` 參數指定不同容器名稱即可。

## 參數說明

| 參數 | 必要 | 預設值 | 說明 |
|------|------|--------|------|
| `-ContainerName` | 否 | `aras2025_ap` | Docker 容器名稱 |
| `-LicenseString` | 是 | - | 新的 License XML 字符串 |

## 相關檔案

- `Update-InnovatorLicense.ps1` - 主要腳本
- `docker-compose.yml` - Docker Compose 配置
- `.env` - 環境變數配置

## 聯絡

如有問題，請檢查容器日誌：
```powershell
docker logs aras2025_ap --tail 50
```
