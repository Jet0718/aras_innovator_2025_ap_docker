# Start script: start.ps1
# This script will perform a silent installation of Aras Innovator 2025.
# All installation parameters are read from environment variables.

# Define the path to the flag file to determine if the first installation is completed
$InstallFlagFile = "C:\Innovator\install_complete.flag"
$msiPath = "C:\Setup\InnovatorSetup.msi"

# Check if the flag file exists
if (Test-Path $InstallFlagFile) {
    Write-Host "Aras Innovator is already installed. Skipping installation steps."
} else {
    Write-Host "First run detected. Starting Aras Innovator 2025 installation..."
    Write-Host "   Installation source: $msiPath"

    # Check if the installation file exists
    if (!(Test-Path $msiPath)) {
        Write-Error "Error: InnovatorSetup.msi not found in C:\Setup. Please mount the installation directory correctly."
        Start-Sleep -Seconds 3600
        exit 1
    }

    # Define all required installation parameter environment variable names
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
        "INSTALL_OAUTH_SERVER",
        "LICENSEKEY"
    )

    # Check if all environment variables are set
    $msiArgs = @("/i", "`"$msiPath`"", "/qn", "/norestart")

    # For stability, first get all environment variables into a hash table
    $allEnvVars = Get-ChildItem Env:

    Write-Host "Validating and creating MSI installation parameters..."
    foreach ($param in $requiredParams) {
        # Find the variable we need in the complete list by name
        $variable = $allEnvVars | Where-Object { $_.Name -eq $param }
        
        if ($null -ne $variable) {
            # If $variable is not null, the environment variable exists (even if its value is empty)
            $paramValue = $variable.Value
            
            # Special handling for LICENSEKEY parameter as it contains XML and double quotes
            if ($param -eq "LICENSEKEY") {
                # Special handling for LICENSEKEY to ensure XML content is passed correctly
                # Use single quotes to wrap the entire value and escape internal double quotes
                $escapedValue = $paramValue -replace '"', '""'
                $msiArgs += "$param=`"$escapedValue`""
                Write-Host "  Special parameter '$param' processed, value length: $($paramValue.Length) characters"
            } else {
                # Add parameter and value to the array
                $msiArgs += "$param=`"$paramValue`""
                Write-Host "  Parameter '$param' found, value: '$paramValue'"
            }

        } else {
            # If not found in the complete list, the variable is definitely undefined
            Write-Error "Fatal error: Required environment variable '$param' is not defined. Please check the .env file."
            Write-Host "Installation cannot continue."
            Start-Sleep -Seconds 3600
            exit 1
        }
    }

    $logPath = "C:\Innovator\vault\InnovatorSetupLog.log"
    $msiArgs += "/l*v", "`"$logPath`""

    # Display the installation command and parameters about to be executed (hide sensitive info)
    Write-Host "About to execute installation command with parameters:"
    $safeArgs = $msiArgs | ForEach-Object {
        if ($_ -like "*PASSWORD*" -or $_ -like "*LICENSEKEY*") {
            "[REDACTED_SENSITIVE_INFO]"
        } else {
            $_
        }
    }
    Write-Host "msiexec.exe $($safeArgs -join ' ')"

    # Execute silent installation
    Write-Host "Executing silent installation... this may take some time."
    try {
        $ErrorActionPreference = 'Stop'
        
        # Method 1: Execute msiexec directly using Start-Process
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
        
        # Check the return value of MSI installation
        if ($process.ExitCode -ne 0) {
            # Convert MSI error code to a user-friendly message
            $errorMessage = switch ($process.ExitCode) {
                1601 { "User cancelled installation." }
                1602 { "User cancelled installation." }
                1603 { "Fatal error during installation." }
                1605 { "This action is only valid for currently installed products." }
                default { "Installation failed, error code: $($process.ExitCode)" }
            }
            Write-Error "Error: $errorMessage. Check $logPath for details."
            
            # If the log file exists, display the last few lines to help diagnose
            if (Test-Path $logPath) {
                Write-Host "=== Last 20 lines of installation log ==="
                Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host $_ }
            }
            
            Start-Sleep -Seconds 3600
            exit 1
        }

        Write-Host "msiexec.exe installation completed successfully."

        # Create a flag file to mark installation as completed
        New-Item -Path $InstallFlagFile -ItemType File -Force | Out-Null
        Write-Host "Installation completion flag file created."

    } catch {
        Write-Error "Error: Exception occurred while executing msiexec.exe installation. Error message: $_"
        Write-Error "Check the $logPath log file inside the container for details."
        Start-Sleep -Seconds 3600
        exit 1
    }
}

# Check IIS configuration
Write-Host "Checking IIS configuration..."
try {
    Import-Module WebAdministration -ErrorAction Stop
    Write-Host "Website list:"
    Get-Website | Format-Table Name, State, PhysicalPath
    Write-Host "Application list:"
    Get-WebApplication -Site "Default Web Site" | Format-Table Path, PhysicalPath, applicationPool
} catch {
    Write-Warning "Warning: Unable to load WebAdministration module or check IIS configuration. Error message: $_"
}

# Check if main files exist, this is an additional validation step
# Write-Host "Testing installation integrity..."
# if (Test-Path "C:\Innovator\Innovator\Server\Innovator.xml") {
    # Write-Host "Innovator.xml file exists. Installation validation successful."
# } else {
    # Write-Warning "Warning: Innovator.xml not found at C:\Innovator\Innovator\Server\Innovator.xml."
# }

# Test SQL Server connection
Write-Host "Testing SQL Server connection..."
try {
    $connectionTest = Test-NetConnection -ComputerName $env:IS_SQLSERVER_SERVER -Port 1433 -ErrorAction Stop
    if ($connectionTest.TcpTestSucceeded) {
        Write-Host "SQL Server connection successful."
    } else {
        Write-Warning "Warning: SQL Server connection failed. Host: $env:IS_SQLSERVER_SERVER , Port: 1433."
    }
} catch {
    Write-Warning "Warning: Unable to test SQL Server connection. Error message: $_"
}

# Ensure IIS service is running
Write-Host "Ensuring World Wide Web Publishing Service (w3svc) is running..."
try {
    $service = Get-Service -Name w3svc -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        Write-Host "Starting w3svc service..."
        Start-Service -Name w3svc -ErrorAction Stop
    }
    Write-Host "w3svc service is running."
} catch {
    Write-Error "Error: Unable to start w3svc service. Error message: $_"
    Start-Sleep -Seconds 3600
    exit 1
}

# Keep the container running and monitor service status
Write-Host "Container is running. Monitoring w3svc service..."
C:\ServiceMonitor.exe w3svc
