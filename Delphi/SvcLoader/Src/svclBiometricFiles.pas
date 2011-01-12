{$IFDEF svclBiometricFiles}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclBiometricFiles;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, svclTransBio, ExtCtrls;

type
    TBioFilesService = class(TService)
        tmrCycleEvent : TTimer;
        procedure ServiceStart(Sender : TService; var Started : boolean);
		 procedure ServiceCreate(Sender : TObject);
		 procedure ServiceAfterInstall(Sender : TService);
		 procedure ServiceStop(Sender : TService; var Stopped : boolean);
        procedure tmrCycleEventTimer(Sender : TObject);
        procedure ServiceBeforeInstall(Sender : TService);
	 private
		 { Private declarations }
		 FSvcThread : TTransBioThread;
		 procedure AddServiceAccountPrivilege();
    public
        function GetServiceController : TServiceController; override;
        procedure TimeCycleEvent();
        { Public declarations }
    end;

var
    BioFilesService : TBioFilesService;

implementation

uses
    AppLog, WinReg32, FileHnd, svclConfig, svclUtils;

{$R *.DFM}

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    BioFilesService.Controller(CtrlCode);
end;

procedure TBioFilesService.AddServiceAccountPrivilege;
var
	ret : DWORD;
begin
	ret:=LogonAsServiceToAccount( GlobalConfig.ServiceAccountName );
	if ret <> ERROR_SUCCESS then begin
		{TODO -oroger -cdsg : Colocar tratamento de erro de permiss�o}
   end;

end;

function TBioFilesService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
end;

procedure TBioFilesService.ServiceAfterInstall(Sender : TService);
var
    Reg : TRegistryNT;
begin
    Reg := TRegistryNT.Create();
    try
        Reg.WriteFullString(
            TFileHnd.ConcatPath(['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services', Self.Name, 'Description']),
            'Replica os arquivos de dados biom�tricos para m�quina prim�ria, possibilitando o transporte centralizado.', True);
    finally
        Reg.Free;
    end;
end;

procedure TBioFilesService.ServiceBeforeInstall(Sender : TService);
var
	msg : string;
begin
	//Conceder a conta a ser usada o direito de logon como servico
	try
		Self.AddServiceAccountPrivilege();
	except
		on E : Exception do begin
			msg:=Format('Privil�gio para logar como servi�o n�o concedido para a conta "%s".'#13 +
				'Necess�rio adcionar manualmente.'#13 +
				'Use gpedit.msc'#13 +
				'\Configura��o do computador\Configura��es do Windows\Configura��es de seguran�a\'#13 +
				'Diretivas locais\Atribui��o de direitos do usu�rio\Fazer logon como um servi�o',
		 [Self.ServiceStartName]);
			TLogFile.Log( msg );
			MessageDlg( msg, mtError, [ mbOK ], 0 );
		end;
	end;
	 //Ajusta as credenciais para instala��o do servi�o e registra a opera��o
	 Self.Password := GlobalConfig.ServiceAccountPassword;
	 Self.ServiceStartName := GlobalConfig.ServiceAccountName;
	 TLogFile.Log(Format('Iniciando o registro do servi�o com as credenciais:'#13'Conta: %s'#13'Senha: %s',
		 [Self.ServiceStartName, Self.Password]));
end;

procedure TBioFilesService.ServiceCreate(Sender : TObject);
begin
	Self.FSvcThread      := TTransBioThread.Create(True);
	Self.FSvcThread.Name := 'BioFiles Service Thread';
end;

procedure TBioFilesService.ServiceStart(Sender : TService; var Started : boolean);
begin
	 //Rotina de inicio do servico, cria o thread da opera��o e o inicia
	 Self.tmrCycleEvent.Interval:=GlobalConfig.CycleInterval;
	 Self.tmrCycleEvent.Enabled:=True;
	 Self.FSvcThread.Start;
    Sleep(300);
    Self.FSvcThread.Suspended := False;
    Started := True;
end;

procedure TBioFilesService.ServiceStop(Sender : TService; var Stopped : boolean);
begin
	Self.tmrCycleEvent.Enabled:=False;
    Self.FSvcThread.Suspended := True;
end;

procedure TBioFilesService.TimeCycleEvent;
begin
	TLogFile.LogDebug('Libera��o do thread de replica��o para novo ciclo', GlobalConfig.DebugLevel );
	Self.FSvcThread.Suspended := False;
end;

procedure TBioFilesService.tmrCycleEventTimer(Sender : TObject);
begin
	 Self.TimeCycleEvent();
	 if not Self.tmrCycleEvent.Enabled then begin
		TLogFile.LogDebug('Timer desabilitado', GlobalConfig.DebugLevel);
		Self.tmrCycleEvent.Enabled:=True;
    end;
end;

end.
