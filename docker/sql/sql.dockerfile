# SQL Server 2019 Windows container dockerfile
## Warning: Restarting windows container causes the machine key to change and hence if you have any encryption configured then restarting SQL On Windows containers
## breaks the encryption key chain in SQL Server. 

# Download the SQL Developer from the following location  https://go.microsoft.com/fwlink/?linkid=866662 and extract the .box and .exe files using the option: "Download Media"

FROM mcr.microsoft.com/windows/servercore:ltsc2022

ENV sa_password="NewPassw0rd!" \
    attach_dbs="[]" \
    ACCEPT_EULA="Y" \
    sa_password_path="C:\\ProgramData\\sa-password"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# make install files accessible
# COPY sa-password C:/ProgramData/sa-password
COPY start.ps1 /
COPY SQLServer2022-DEV-x64-ENU.box /
COPY SQLServer2022-DEV-x64-ENU.exe /
# COPY SQLServer2019-DEV-x64-ENU /

WORKDIR /

RUN Start-Process -Wait -FilePath .\SQLServer2022-DEV-x64-ENU.exe -ArgumentList /qs, /x:setup ; \
        .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS ; \
        Remove-Item -Recurse -Force SQLServer2022-DEV-x64-ENU.exe, SQLServer2022-DEV-x64-ENU.box, setup

RUN stop-service MSSQLSERVER ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2 ;

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

CMD .\start -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -Verbose