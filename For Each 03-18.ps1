<#
.SYNOPSIS
    This script changes the registry to give user access to change location services and set time zone automatically
    
.DESCRIPTION
      This PowerShell script automates the process changing the registry keys to enable location services and automatic time zone.
    
.PARAMETER 
   
    
.NOTES
    File Name      : Time-Zone.ps1
    Author         : Calvin Quint
    License        : GNU GPL
    Permission     : You are free to change and re-distribute this script as per the terms of the GPL.
    
.LINK
    GitHub Repository: https://github.com/calvin-quint/Time-Zone
    
.EMAIL
    Contact email: github@myqnet.io
    
#>

# Function to check if a registry key exists
function Test-RegistryKeyExists {
    param (
        [string]$Path
    )
    Test-Path $Path -PathType Container
}

# Function to check if a registry value exists
function Test-RegistryValueExists {
    param (
        [string]$Path,
        [string]$Name
    )
    Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Out-Null
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
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Host "Registry key '$Name' set successfully at path '$Path'."
    } catch {
        Write-Host "Failed to set registry value '$Name' at path '$Path'. Error: $_"
        exit 1
    }
}

# Function to configure or check registry values
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type
    )

    if (Test-RegistryKeyExists $Path) {
        if (-not (Test-RegistryValueExists $Path $Name)) {
            New-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
            return $true
        }

        $currentValue = (Get-ItemProperty -Path $Path -Name $Name).($Name)
        if ($currentValue -ne $Value) {
            New-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
            return $true
        }

        return $false
    }
    else {
        try {
            New-Item -Path $Path -Force | Out-Null
            Write-Host "Registry key '$Path' created successfully."
            New-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
            return $true
        } catch {
            Write-Host "Failed to create registry key '$Path'. Error: $_"
            exit 1
        }
    }
}

# Main function
function Main {
    $settings = @(
        @{
            Path  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
            Name  = "Value"
            Value = "Allow"
            Type  = "String"
        }
    )

    $settings | ForEach-Object {
        if (Set-RegistryValue -Path $_.Path -Name $_.Name -Value $_.Value -Type $_.Type) {
            Write-Host "Registry key '$($_.Name)' configured successfully."
        } else {
            Write-Host "Registry key '$($_.Name)' is already set to the correct value."
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
}

# Call the main function
Main
