;ESTE PROGRAMA FOI COMPILADO NO NSIS <http://nsis.sourceforge.net/>
;OBJETIVOS:
	;1. INSTALAR O BROFFICE.ORG 3.0 VIA LOGIN SCRIPT EM REDES WINDOWS
	;2. INSTALAR AS SEGUINTES EXTENS�ES QUE FICAR�O DISPON�VEIS APENAS PARA O USU�RIO QUE INSTALOU O PRODUTO
		;- VERIFICADOR ORTOGR�FICO
		;- VERIFICADOR GRAMATICAL
		;- MODELOS DE DOCUMENTOS
		;* A DISPONIBILIZA��O DAS EXTENS�ES PARA OS DEMAIS PROFILES � CONTROLADA POR OUTRO PROGRAMA (bro-personal.exe)
;CARACTER�STICAS DO INSTALADOR: INSTALA��O FOR�ADA DESASSISTIDA; FAZ NOVA TENTATIVA DE INSTALA��O A CADA 10 MINUTOS
;AUTOR: KRAUCER FERNANDES MAZUCO (<kraucer@bb.com.br) em 07/11/2008
;LICEN�A: GPL <http://www.fsf.org/licensing/licenses/gpl.html>

Name "Instalador do BrOffice.org 3.0"
OutFile "instalar.exe"
!include "FileFunc.nsh"
!insertmacro DriveSpace
!include "LogicLib.nsh"
!insertmacro GetTime
!include "WinMessages.nsh"
RequestExecutionLevel user ;exigido pelo UAC do Windows Vista
ShowInstDetails Nevershow
Var VAL		;valor sequencial da instala��o
Var LIM		;valor limite de instala��es simult�neas
Var TEN		;n�mero de tentativas
Var ATU
Var ATT
Var dat1
Var dat2
Var dat3
Var dat4
Var dat5
Var dat6
Var dat7
Var hor1
Var hor2
Var min1
Var min2
Var intermin
Var LOCALDATA
Var USERNAME
Var SISOP

Function .onInit
		SetSilent Silent
		;O CONTROLE DA EXIST�NCIA OU N�O DO BROFFICE.ORG N�O EST� MAIS NO LOGIN SCRIPT. POR ESSE MOTIVO, IREI VERIFICAR AGORA SUA
		;EXIST�NCIA. CASO ESTEJA INSTALADO, N�O IREI EXECUTAR O INSTALADOR
		IfFileExists "$PROGRAMFILES\BrOffice.org 3\program\soffice.exe" 0 +2
			Quit
			
		;PROCEDIMENTO VERIFICA SE O ARQUIVO CONTADOR FICOU MAIS DE 30 MINUTOS SEM ALTERA��ES
		;SE FICOU, PROVAVELMENTE O MESMO TRAVOU O VALOR DO CONTADOR NO VALOR M�XIMO, IMPEDINDO NOVAS INSTALA��ES
		;NESTE CASO, O SISTEMA IR� RETORNAR O VALOR DO CONTADOR AO VALOR INICIAL DE ZERO (0)
		${GetTime} "P:\OpenOffice\contador.txt" "m" $dat1 $dat2 $dat3 $dat4 $dat5 $dat6 $dat7
		; $dat1="01"      day
		; $dat2="04"      month
		; $dat3="2005"    year
		; $dat4="Friday"  day of week name
		; $dat5="16"      hour
		; $dat6="05"      minute
		; $dat7="50"      seconds
		IntOp $hor1 $dat5 * 60
		IntOp $min1 $dat6 + $hor1
		${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
		; $0="01"      day
		; $1="04"      month
		; $2="2005"    year
		; $3="Friday"  day of week name
		; $4="16"      hour
		; $5="05"      minute
		; $6="50"      seconds
		IntOp $hor2 $4 * 60
		IntOp $min2 $5 + $hor2
		IntOp $intermin $min2 - $min1
			
		${If} $0 != $dat1
			CopyFiles H:\BrOffice-v30\contador.txt "P:\OpenOffice\contador.txt"
		${ElseIf} $0 = $dat1
			${If} $intermin > '30'
				CopyFiles H:\BrOffice-v30\contador.txt "P:\OpenOffice\contador.txt"
			${EndIf}
		${EndIf}
		
		;VERIFICA SE EXISTE O ARQUIVO contador.txt. SE N�O EXISTIR, ELE � CRIADO A PARTIR DE UMA C�PIA DO DRIVE H:
		ClearErrors
		${DriveSpace} "p:\openoffice\contador.txt" "/D=F /S=M" $R2
		IfErrors 0 +2
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		
		;ABRE O ARQUIVO contador.txt PARA LER O N�MERO DE INSTALA��ES SIMULT�NEAS ONLINE
Nova_tentativa:	ClearErrors
		IntOP $TEN $TEN + 1
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_Open
		FileRead $0 $1
		IntOp $VAL $1 + 1
		FileClose $0
		
		;ABRE O ARQUIVO LIMITE.TXT PARA LER A VARI�VEL QUE CONT�M O N�MERO LIMITE DE INSTALA��ES SIMULT�NEAS
		ClearErrors
		FileOpen $0 H:\BrOffice-v30\limite.txt r
            FileRead $0 $LIM
		FileClose $0

		;SE O N�MERO DE INSTALA��ES SIMULT�NEAS FOR ATINGIDO, FINALIZA O PROGRAMA
		${If} $VAL > $LIM
		  	; FAREI NOVA TENTATIVA DE INSTALA��O AP�S 10 MINUTOS
			sleep 600000
			call .onInit
		${EndIf}	

		;INCREMENTA O CONTADOR DE INSTALA��ES SIMULT�NEAS
Reabre:	ClearErrors
		IntOP $ATU $ATU + 1
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_atual		
		FileWrite $0 $VAL
            FileClose $0
		Goto +16

Wait_Open:	${If} $TEN >= '10'
			Quit
		${ElseIf} $TEN < '10'
			Sleep 2000
			Goto Nova_tentativa
		${EndIf}		
		Quit

Wait_atual:	${If} $ATU >= '10'
			Quit
		${Elseif} $ATU < '10'
			Sleep 500
			Goto Reabre
		${Endif}
		Quit
FunctionEnd

Section "In�cio"
	;ROTINA VERIFICA SE O ESPA�O EM DISCO � SUFICIENTE PARA A INSTALA��O
	${DriveSpace} "C:\" "/D=F /S=M" $R0
	${If} $R0 >= '400'

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
		
		;EXECUTA A INSTALA��O DO BROFFICE.ORG EM MODO QUIET
		MessageBox MB_OK|MB_ICONEXCLAMATION "O BrOffice.org de sua esta��o ser� atualizado para a vers�o 3.0 e suas vers�es antigas ser�o removidas. Favor n�o utilizar o aplicativo BrOffice at� que o processo seja conclu�do. Voc� ser� notificado sobre o t�rmino do mesmo em no m�ximo 10 minutos. Clique em OK para continuar."
		DetailPrint "Instalando o BrOffice.org 3.0...aguarde!!!"
		
		;S� IREI MOSTRAR A MENSAGEM ABAIXO SE O SISTEMA OPERACIONAL FOR WINDOWS VISTA
		StrCmp $SISOP "Windows Vista (TM) Business" 0 +2
		MessageBox MB_OK|MB_ICONEXCLAMATION "ATEN��O USU�RIOS DO WINDOWS VISTA: Na pr�xima tela, clique na op��o 'PERMITIR' para que a instala��o possa prosseguir."
		
		ExecWait "msiexec /passive /norestart /i H:\BrOffice-v30\brofficeorg30.msi ADDLOCAL=ALL REMOVE=gm_o_Quickstart ALLUSERS=1"

		;DESINSTALA VERS�O ANTIGA DO VERIFICADOR ORTOGR�FICO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe remove --shared dict-pt.oxt"
				
		;APLICA AS PERSONALIZA��ES DO BROFFICE.ORG PARA O USU�RIO ATUAL
		ExecWait "H:\BrOffice-v30\personal\bro-personal.exe"
		
		;L� O ARQUIVO contador.txt E DECREMENTA O CONTADOR DE INSTALA��ES SIMULT�NEAS NO FINAL DA INSTALA��O
		DetailPrint "Abrindo arquivo de contagem..."
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		FileRead $0 $1
		IntOp $VAL $1 - 1
		FileClose $0

		;ATUALIZA O VALOR DO CONTADOR DE INSTALA��ES SIMULT�NEAS
		DetailPrint "Decrementando n�mero de instala��es simult�neas..."
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		FileWrite $0 $VAL
            FileClose $0
		${If} $VAL < 0
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		${Endif}
		${If} $VAL > $LIM
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		${Endif}
		IfFileExists "$PROGRAMFILES\BrOffice.org 3\program\soffice.exe" +3 0
			MessageBox MB_OK|MB_ICONEXCLAMATION "A instala��o do BrOffice.org foi cancelada. Ser� realizada nova tentativa no pr�ximo logon."
			Quit
		MessageBox MB_OK|MB_ICONEXCLAMATION "O BrOffice.org 3.0 e as seguintes extens�es foram instaladas com sucesso: dicion�rios tem�ticos de inform�tica e jur�dico, modelos de documentos, corretor ortogr�fico e gramatical, importador e editor de PDF�s."
		Quit
		
	${ElseIf} $R0 < '400'
		;CANCELA O PROCESSO DE INSTALA��O DEVIDO AO ESPA�O INSUFICIENTE NO DISCO
		;DECREMENTA O VALOR DO CONTADOR DE INSTALA��ES SIMULT�NEAS
		DetailPrint "Decrementando n�mero de instala��es simult�neas..."
Re_open:	IntOP $ATT $ATT + 1
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_att
		FileWrite $0 $1
        FileClose $0
		MessageBox MB_OK|MB_ICONEXCLAMATION "A instala��o autom�tica do BrOffice.org foi cancelada. � necess�rio um espa�o m�nimo de 400 MegaBytes livres no disco r�gido. Clique no bot�o OK para finalizar."
	    Quit
    ${EndIf}

Wait_att:	${If} $ATT >= '10'
			Quit
		${Elseif} $ATT < '10'
			Sleep 500
			Goto Re_open
		${Endif}
		Quit
SectionEnd