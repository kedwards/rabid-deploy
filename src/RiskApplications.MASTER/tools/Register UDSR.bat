cd ../../
if exist olf_oframework.jar set CLASSLOADER=-Djava.system.class.loader=com.olf.oframework.OClassLoader 
java %CLASSLOADER% -jar RiskApplications\tools\RiskAppInstaller.jar CLASS_UDSR