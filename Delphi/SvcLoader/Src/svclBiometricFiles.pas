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
	 public
		 function GetServiceController : TServiceController; override;
		 procedure TimeCycleEvent();
		 { Public declarations }
	 end;

var
    BioFilesService : TBioFilesService;

implementation

uses
	 AppLog, WinReg32, FileHnd, svclConfig, svclUtils, WinnetHnd, APIHnd, svclEditConfigForm;

{$R *.DFM}

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    BioFilesService.Controller(CtrlCode);
end;

function TBioFilesService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
end;

procedure TBioFilesService.ServiceAfterInstall(Sender : TService);
/// <summary>
///  Registra as informa��es de fun��o deste servi�o
/// </summary>
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
 ///  <summary>
 ///    Ajusta os parametros do servi�o antes de sua instala��o. Dentre as a��es est� levantar o servi�o como o �ltimo da lista de
 /// servi�os
 ///  </summary>
 ///  <remarks>
 ///
 ///  </remarks>
var
    reg : TRegistryNT;
    lst : TStringList;
begin

	TEditConfigForm.EditConfig; //Chama janela de configura��o para exibi��o

	 reg := TRegistryNT.Create;
	 lst := TStringList.Create;
	 try
		 reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst);
		 if(  ( lst.IndexOf(APP_SERVICE_GROUP ) < 0 ) )then begin
			 lst.Add(APP_SERVICE_GROUP);
			 TLogFile.Log('Alterando ordem de inicializa�ao dos servi�os no registro local', lmtInformation);
			 if ( not IsDebuggerPresent()) then begin
				reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst, True);
			 end;
		 end;
	 finally
		 reg.Free;
		 lst.Free;
	 end;
	 TLogFile.Log('Ordem de carga do servi�o alterada com SUCESSO no computador local', lmtInformation);
end;

procedure TBioFilesService.ServiceCreate(Sender : TObject);
begin
	 Self.DisplayName := APP_SERVICE_DISPLAYNAME;
	 Self.LoadGroup:= APP_SERVICE_GROUP;
	 Self.TagID:=100;
	 Self.FSvcThread      := TTransBioThread.Create(True);  //Criar thread de opera��o prim�rio
	 Self.FSvcThread.Name := APP_SERVICE_DISPLAYNAME;  //Nome de exibi��o do thread prim�rio
end;

procedure TBioFilesService.ServiceStart(Sender : TService; var Started : boolean);
begin
	 //Rotina de inicio do servico, cria o thread da opera��o e o inicia
	 Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
	 Self.tmrCycleEvent.Enabled:=True;
	 Self.FSvcThread.Start;
	 Sleep(300);
	 Self.FSvcThread.Suspended := False;
	 Started := True;
end;

procedure TBioFilesService.ServiceStop(Sender : TService; var Stopped : boolean);
begin
	 Self.FSvcThread.Suspended := True;
end;

procedure TBioFilesService.TimeCycleEvent;
begin
	 Self.FSvcThread.Suspended := False;
end;

procedure TBioFilesService.tmrCycleEventTimer(Sender : TObject);
begin
	 Self.TimeCycleEvent();
end;

end.
