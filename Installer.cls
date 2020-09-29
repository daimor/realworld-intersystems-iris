Class Conduit.Installer
{

XData setup [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Default Name="AppDir" Dir='#{$system.Util.GetEnviron("PWD")}'/>
  <Default Name="SourceDir" Dir="${AppDir}src"/>
  <Default Name="Namespace" Value="CONDUIT"/>
  <Default Name="app" Value="conduit" />

  <Namespace Name="${Namespace}" Code="${Namespace}-CODE" Data="${Namespace}-DATA" Create="yes" Ensemble="0">

    <Configuration>
      <Database Name="${Namespace}-DATA" Dir="${AppDir}db/data" Create="yes" Resource="%DB_${Namespace}"/>
      <Database Name="${Namespace}-CODE" Dir="${AppDir}db/code" Create="yes" Resource="%DB_${Namespace}"/>
    </Configuration>

  </Namespace>

</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  #; Let XGL document generate code for this method.
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

}
