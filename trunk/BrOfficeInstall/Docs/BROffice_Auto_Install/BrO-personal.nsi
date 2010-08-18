;ESTE PROGRAMA FOI COMPILADO NO NSIS <http://nsis.sourceforge.net/>
;OBJETIVOS:
	;1. INSTALAR AS SEGUINTES EXTENS�ES QUE FICAR�O DISPON�VEIS PARA O USU�RIO QUE LOGOU NA ESTA��O
		;- VERIFICADOR ORTOGR�FICO
		;- VERIFICADOR GRAMATICAL
		;- MODELOS DE DOCUMENTOS
	;2. FAZ O LOAD DOS DICION�RIOS INSTALADOS
;CARACTER�STICAS DO INSTALADOR: INSTALA��O FOR�ADA DESASSISTIDA
;AUTOR: KRAUCER FERNANDES MAZUCO (<kraucer@bb.com.br) em 07/11/2008
;LICEN�A: GPL <http://www.fsf.org/licensing/licenses/gpl.html>

Name "Personalizador do BrOffice.org"
OutFile "bro-personal.exe"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"
RequestExecutionLevel user ;apenas para o Windows Vista + UAC
ShowInstDetails Nevershow
Var LOCALDATA
Var USERNAME
Var SISOP

Function .onInit
		SetSilent Silent
FunctionEnd

Section "In�cio"
		;IREI LER O SISTEMA OPERACIONAL DEVIDO A ALGUMAS ESPECIFICIDADES ENTRE XP E VISTA
		ReadRegStr $SISOP HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" ProductName
		
		;BUSCO O NOME DO USU�RIO LOGADO NO MOMENTO DA INSTALA��O
		UserInfo::GetName
		Pop $USERNAME
		
		;POR N�O CONSEGUIR TRATAR CORRETAMENTE A CONSTANTE $LOCALAPPDATA, IREI VERIFIC�-LA CONFORME O SISTEMA OPERACIONAL
		ReadRegStr $SISOP HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" ProductName
		StrCpy $LOCALDATA "C:\Documents and Settings\$USERNAME\dados de aplicativos"
		${If} $SISOP == 'Microsoft Windows XP'
			StrCpy $LOCALDATA "C:\Documents and Settings\$USERNAME\dados de aplicativos"
		${ElseIf} $SISOP == 'Windows Vista (TM) Business'
			StrCpy $LOCALDATA "C:\Users\$USERNAME\AppData\Roaming"
		${EndIf}
		
		;O CONTROLE DA EXIST�NCIA OU N�O DAS DO BROFFICE.ORG N�O EST� MAIS NO LOGIN SCRIPT. POR ESSE MOTIVO, IREI VERIFICAR AGORA SUA
		;EXIST�NCIA. CASO AS PERSONALIZA��ES J� EXISTIREM,  N�O IREI EXECUTAR.
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Setup.xcu" 0 +2
			Quit
			
		;INSTALA��ES PERSONALIZADAS E EXCLUSIVAS PARA O WINDOWS XP (VISTA N�O PERMITE DEVIDO AO CONTROLE DO UAC)
		;INSTALANDO A EXTENS�O DO VERIFICADOR ORTOGR�FICO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extens�es\Vero_pt_BR_V200AOC.oxt"

		;INSTALANDO A EXTENS�O DO CORRETOR GRAMATICAL COGROO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extens�es\CoGrOO-AddOn-3.0.1-bin.oxt"

		;INSTALANDO A EXTENS�O DO MODELO DE DOCUMENTOS
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extens�es\Modelos_BrOffice-BB-v01.oxt"			

		;INSTALANDO A EXTENS�O QUE POSSIBILITA A IMPORTA��O DE ARQUIVOS PDF NO DRAW
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extens�es\pdfimport.oxt"
		
		;INSTALANDO DICION�RIOS TEM�TICOS DE INFORM�TICA E JUR�DICO APENAS PARA O USU�RIO QUE INSTALOU O BROFFICE.ORG POIS N�O
		;CONSIGO ESCREVER NO C:\PROGRAM FILES DO VISTA DEVIDO AO UAC
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\wordbook\DicInfo.dic" +6 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo2.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo3.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicJuridico.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
		
		;SE O ARQUIVO SETUP.XCU N�O EXISTIR NO PROFILE DO USU�RIO, FAREI A C�PIA PARA EVITAR TELA DE ERRO NA INICIALIZA��O
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Setup.xcu" +3 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice"
			CopyFiles H:\BrOffice-v30\register\Setup.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice"
		
		;SE O ARQUIVO COMMON.XCU N�O EXISTIR NO PROFILE DO USU�RIO, FAREI A C�PIA PARA EVITAR TELA DE ERRO NA INICIALIZA��O
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office\Common.xcu" +3 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office"
			CopyFiles H:\BrOffice-v30\register\Common.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office\Common.xcu"
		
		;SE O ARQUIVO  SCRIPT.XLC N�O EXISTIR NO PROFILE DO USU�RIO, FAREI A C�PIA PARA EVITAR TELA DE ERRO NA INICIALIZA��O
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\basic\script.xlc" +8 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\basic"
			CopyFiles H:\BrOffice-v30\register\script.xlc "$LOCALDATA\BrOffice.org\3\user\basic"
			CopyFiles H:\BrOffice-v30\register\dialog.xlc "$LOCALDATA\BrOffice.org\3\user\basic"
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\script.xlb "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\dialog.xlb "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\Module1.xba "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			
		;ATIVA O LOAD DE TODOS OS DICION�RIOS IMPLANTADOS
		CopyFiles H:\BrOffice-v30\dict\Linguistic.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office"
		Quit
SectionEnd