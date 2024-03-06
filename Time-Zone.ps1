# Function to check if a registry key exists
function Test-RegistryKeyExists {
    param (
        [string]$Path
    )
    return (Test-Path $Path -PathType Container)
}

# Function to check if a registry value exists
function Test-RegistryValueExists {
    param (
        [string]$Path,
        [string]$Name
    )
    $key = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($key -ne $null) {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($value -ne $null) {
            return $true
        }
    }
    return $false
}

# Function to set registry value and handle failure
function New-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type
    )
    try {
        $result = New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop
        Write-Host "Registry key '$Name' set successfully at path '$Path'."
    } catch {
        Write-Host "Failed to set registry key '$Name' at path '$Path'. Error: $_"
        exit 1
    }
}

# Configure Time Zone Auto Update Service
$tzautoupdatePath = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
if (-not (Test-RegistryValueExists $tzautoupdatePath "Start")) {
    New-RegistryValue -Path $tzautoupdatePath -Name "Start" -Value 3 -Type DWord
    exit 0
} else {
    # Check if the value is set to the correct value
    $currentValue = (Get-ItemProperty -Path $tzautoupdatePath -Name "Start").Start
    if ($currentValue -ne 3) {
        New-RegistryValue -Path $tzautoupdatePath -Name "Start" -Value 3 -Type DWord
    } else {
        Write-Host "Registry key 'Start' is already set to the correct value."
    }
}

# Configure Sensor Permissions
$sensorOverridesPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
if (-not (Test-RegistryValueExists $sensorOverridesPath "SensorPermissionState")) {
    New-RegistryValue -Path $sensorOverridesPath -Name "SensorPermissionState" -Value 1 -Type DWord
    exit 0
} else {
    # Check if the value is set to the correct value
    $currentValue = (Get-ItemProperty -Path $sensorOverridesPath -Name "SensorPermissionState").SensorPermissionState
    if ($currentValue -ne 1) {
        New-RegistryValue -Path $sensorOverridesPath -Name "SensorPermissionState" -Value 1 -Type DWord
    } else {
        Write-Host "Registry key 'SensorPermissionState' is already set to the correct value."
    }
}

# Configure Location and Sensors Policies
$locationAndSensorsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
if (-not (Test-RegistryValueExists $locationAndSensorsPath "DisableLocation")) {
    New-RegistryValue -Path $locationAndSensorsPath -Name "DisableLocation" -Value 0 -Type DWord
    exit 0
} else {
    # Check if the value is set to the correct value
    $currentValue = (Get-ItemProperty -Path $locationAndSensorsPath -Name "DisableLocation").DisableLocation
    if ($currentValue -ne 0) {
        New-RegistryValue -Path $locationAndSensorsPath -Name "DisableLocation" -Value 0 -Type DWord
    } else {
        Write-Host "Registry key 'DisableLocation' is already set to the correct value."
    }
}

# Start Location Services
try {
    Start-Service -Name "lfsvc" -ErrorAction Stop
    Write-Host "Location Services started successfully."
} catch {
    Write-Host "Failed to start Location Services. Error: $_"
    exit 1
}

# Resynchronize Time
try {
    w32tm /resync
    Write-Host "Time resynchronized successfully."
} catch {
    Write-Host "Failed to resynchronize time. Error: $_"
    exit 1
}
