SET PATH=
SET SYBASE=
SET ORACLE_HOME=
SET MSSQL=
SET TEMP=
SET TMP=
SET TNS_ADMIN=
SET JAVA_ARGS=
SET RISKPAK_XML_UPGRADE_LIMIT=
SET RP_ALLOW_XML_UPGRADE_SERVICE_OVERRIDE=
if exist olf_oframework.jar set CLASSLOADER=-Djava.system.class.loader=com.olf.oframework.OClassLoader 
java %JAVA_ARGS% %CLASSLOADER% -jar RiskApplications\tools\RiskAppInstaller.jar %1 %2 2>rainstall.log
