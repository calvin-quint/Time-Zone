<#
.SYNOPSIS
    This script changes the registry to give user access to change location services and set time zone automatically
    
.DESCRIPTION
      This PowerShell script automates the process of changing the registry keys to enable location services and automatic time zone.
    
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
        $Path = $_.Path
        $Name = $_.Name
        $Value = $_.Value
        $Type = $_.Type

        if (-not (Test-RegistryValueExists $Path $Name)) {
            New-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
            Write-Host "Registry key '$Name' set successfully at path '$Path' ($Message)."
        } else {
            $currentValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
            if ($currentValue -ne $Value) {
                New-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
                Write-Host "Registry key '$Name' updated successfully at path '$Path' ($Message)."
            } else {
                Write-Host "Registry key '$Name' is already set to the correct value at path '$Path'."
            }
        }
    }
}

# Call the main function
Main
