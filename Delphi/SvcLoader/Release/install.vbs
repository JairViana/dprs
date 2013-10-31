'*********************************************************
'*********** FLAG DE DEPURA��O ABAIXO  *******************
const DBG = FALSE
'*********************************************************
'*********** DECLARA��O DE CONSTANTES  *******************
const svcdisplay = "SESOP TransBio Replicator"
const strSvcName = "'BioFilesService'"
const strComputer = "."
const strRT = "SvcLoader.exe"
const ExeDest = "D:\AplicTRE\Suporte\Scripts\SvcLoader.exe"
const ExeSource = "D:\Comum\InstSeg\SvcLoader.exe"
const IniDest = "D:\AplicTRE\Suporte\Scripts\SvcLoader.ini"
const IniSource = "D:\Comum\InstSeg\SvcLoader.ini"
'*********************************************************


'*********************************************************
'****************  ROTINA PRIM�RIA  *********************
On Error Resume Next
Err.Clear
Err.Number = 0
Main()
If Err.Number <> 0 Then
  WScript.Echo "Instala��o falhou!" & vbCrLf & Err.Description
  WScript.Quit(8666) 'Informa ao preinst do erro  
End If

'**********************  FINAL  **************************
'*********************************************************

function Main()
	Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

	rem testar se rodando e parar caso
	Set colRunningServices = objWMIService.ExecQuery ("Select * from Win32_Service Where Name = " & strSvcName & " and ( (State = 'Running') or ( State = 'Paused') )" )
	For Each objService in colRunningServices 
	    DbgMsg("Parando servico")
	    objService.StopService()
	Next

	rem testa se parado
	Set colRunningServices = objWMIService.ExecQuery ("Select * from Win32_Service Where Name = " & strSvcName & " and (State = 'Stopped')" )
	For Each objService in colRunningServices 
	    DbgMsg("removendo servico pela interface do pr�prio")
	    RunRT( false )
	Next

	rem copia os novos arquivos
	UpdateFiles ExeSource, ExeDest 
	UpdateFiles IniSource, IniDest 

	rem instala servico
	RunRT(true)

end function

sub UpdateFiles(byRef Src , byRef Dest )	
	Set fso = CreateObject("Scripting.FileSystemObject")
	'verifica arquibo preexistente
    If fso.FileExists(Dest) Then
		fso.DeleteFile Dest, True
    End If
    'Move arquivo diretamente
    fso.MoveFile Src, Dest
	Set fso = Nothing
	DbgMsg("Atualizado " & Dest )
end sub
'*********************************************************
'*********** FLAG DE DEPURA��O ABAIXO  *******************
const DBG = FALSE
'*********************************************************
'*********** DECLARA��O DE CONSTANTES  *******************
const svcdisplay = "SESOP TransBio Replicator"
const strSvcName = "'BioFilesService'"
const strComputer = "."
const strRT = "SvcLoader.exe"
const ExeDest = "D:\AplicTRE\Suporte\Scripts\SvcLoader.exe"
const ExeSource = "D:\Comum\InstSeg\SvcLoader.exe"
const IniDest = "D:\AplicTRE\Suporte\Scripts\SvcLoader.ini"
const IniSource = "D:\Comum\InstSeg\SvcLoader.ini"
'*********************************************************


'*********************************************************
'****************  ROTINA PRIM�RIA  *********************
On Error Resume Next
Err.Clear
Err.Number = 0
Main()
If Err.Number <> 0 Then
  WScript.Echo "Instala��o falhou!" & vbCrLf & Err.Description
  WScript.Quit(8666) 'Informa ao preinst do erro  
End If

'**********************  FINAL  **************************
'*********************************************************

function Main()
	Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

	rem testar se rodando e parar caso
	Set colRunningServices = objWMIService.ExecQuery ("Select * from Win32_Service Where Name = " & strSvcName & " and ( (State = 'Running') or ( State = 'Paused') )" )
	For Each objService in colRunningServices 
	    DbgMsg("Parando servico")
	    objService.StopService()
	Next

	rem testa se parado
	Set colRunningServices = objWMIService.ExecQuery ("Select * from Win32_Service Where Name = " & strSvcName & " and (State = 'Stopped')" )
	For Each objService in colRunningServices 
	    DbgMsg("removendo servico pela interface do pr�prio")
	    RunRT( false )
	Next

	rem copia os novos arquivos
	UpdateFiles ExeSource, ExeDest 
	UpdateFiles IniSource, IniDest 

	rem instala servico
	RunRT(true)

end function

sub UpdateFiles(byRef Src , byRef Dest )	
	Set fso = CreateObject("Scripting.FileSystemObject")
	'verifica arquibo preexistente
    If fso.FileExists(Dest) Then
		fso.DeleteFile Dest, True
    End If
    'Move arquivo diretamente
    fso.MoveFile Src, Dest
	Set fso = Nothing
	DbgMsg("Atualizado " & Dest )
end sub


Sub RunRT( byVal bolInstall )
	strErrorCode = "-"
	if DBG then 
		strCMDSufix = ""  'depura��o usar vazio	
	else 
		strCMDSufix = " /silent /autoconfig "  'produ��o usar silent e autoconfig
	end if	
	Set objShell = WScript.CreateObject("WScript.Shell")
	if bolInstall then
		strErrorCode = objShell.Run( ExeDest & " /install" & strCMDSufix , 1, True )
	else
		strErrorCode = objShell.Run( ExeDest & " /uninstall" & strCMDSufix , 1, True )
	end if
	DbgMsg("Retorno da execu��o = " & strErrorCode )
	if strErrorCode <> "0" then
		if bolInstall then
			Err.Raise vbObjectError + 8666, , "Erro instalando servi�o."
		else
			Err.Raise vbObjectError + 8666, , "Erro desinstalando servi�o"
		end if
	end if
	Set objShell = Nothing
end sub


sub DbgMsg( byRef msg )
	if DBG then 
		Wscript.Echo msg
	end if
end sub


Sub RunRT( byVal bolInstall )
	strErrorCode = "-"
	if DBG then 
		strCMDSufix = ""  'depura��o usar vazio	
	else 
		strCMDSufix = " /silent"  'produ��o usar silent
	end if	
	Set objShell = WScript.CreateObject("WScript.Shell")
	if bolInstall then
		strErrorCode = objShell.Run( ExeDest & " /install" & strCMDSufix , 1, True )
	else
		strErrorCode = objShell.Run( ExeDest & " /uninstall" & strCMDSufix , 1, True )
	end if
	DbgMsg("Retorno da execu��o = " & strErrorCode )
	if strErrorCode <> "0" then
		if bolInstall then
			Err.Raise vbObjectError + 8666, , "Erro instalando servi�o."
		else
			Err.Raise vbObjectError + 8666, , "Erro desinstalando servi�o"
		end if
	end if
	Set objShell = Nothing
end sub


sub DbgMsg( byRef msg )
	if DBG then 
		Wscript.Echo msg
	end if
end sub
