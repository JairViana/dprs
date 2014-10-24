{$IFDEF vvsmMainDatamodule}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
unit vvsmMainDatamodule;

interface

uses
	SysUtils, Classes, ExtCtrls, ImgList, Controls, Menus, Forms, vvsFileMgmt, IdBaseComponent, IdComponent,
	IdTCPConnection, IdTCPClient, vvConfig, IdHTTP, vvProgItem, FileInfo;

const
	STR_DEFAULT_NET_INSTSEG = '<default>';
	VERSION_INFO_FILENAME   = 'VVER.ini';

type
	TVVSMMainDM = class(TDataModule)
		TrayIcon: TTrayIcon;
		tmrTrigger: TTimer;
		ilIcons: TImageList;
		pmMenuTray: TPopupMenu;
		Mostrar1: TMenuItem;
		Atualizar1: TMenuItem;
		Sair1: TMenuItem;
		tcpclntRegister: TIdTCPClient;
		fvVersion: TFileVersionInfo;
		procedure TrayIconMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
		procedure DataModuleCreate(Sender: TObject);
		procedure tmrTriggerTimer(Sender: TObject);
		procedure Mostrar1Click(Sender: TObject);
		procedure Atualizar1Click(Sender: TObject);
		procedure Sair1Click(Sender: TObject);
		procedure tcpclntDisconnected(Sender: TObject);
		procedure tcpclntConnected(Sender: TObject);
	private
		{ Private declarations }
		FStartTime         : TDateTime;
		FLastRegisterSended: TDateTime;
		FLastStatus        : TVVUpdateStatus;
		FDownloadExecuted  : boolean;
		FPassCount         : Integer;
		function GlobalStatusStr(): string;
		procedure InitVersionsConfig;
		procedure EndSession();
		procedure StartSession();
		procedure StartClient();
		procedure RegisterStatusServer(CurrentStatus: TVVUpdateStatus);
		procedure PostRequest(Args: array of string);
		procedure InitSettings();
		procedure StopClient();
		function ReadResponse(): string;
		procedure PostStatus(CurrentStatus: TVVUpdateStatus);
		//function LoadURL(const url, DestFilename : string) : string;
	public
		{ Public declarations }
		procedure ShowNotification(StatusOK: TVVUpdateStatus);
		procedure UpdateFiles();
	end;

var
	VVSMMainDM: TVVSMMainDM;

implementation

{$R *.dfm}

uses
	FileHnd, StrHnd, IdContext, IdCustomTCPServer,
	IdTCPServer,
	IdEMailAddress, WinNetHnd, AppLog, vvMainForm, Str_Pas, TREUtils, XPFileEnumerator,
	vvsConsts, IdGlobal, Rtti, TypInfo, Masks, Windows, ShellFilesHnd, JclSysInfo, Dialogs, XP.StrConverters, system.UITypes;

const
	ICON_UPDATED     = 0;
	ICON_NOT_UPDATED = 1;
	ICON_UNKNOW      = 2;

procedure TVVSMMainDM.Atualizar1Click(Sender: TObject);
begin
	Self.tmrTriggerTimer(Self);
end;

procedure TVVSMMainDM.DataModuleCreate(Sender: TObject);
var
	filename: string;
begin
	Self.FStartTime := Now();
	if (FindCmdLineSwitch('shortcut')) then begin
		try
			if (GetWindowsVersion() = wvWin7) then begin //matar arquivo antigo
				filename := 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\VVerMonitor.lnk';
			end else begin
				filename := 'C:\Documents and Settings\All Users\Menu Iniciar\Programas\Inicializar\VVerMonitor.lnk';
			end;
			DeleteFile(PWideChar(filename));
			TShellHnd.CreateShellShortCut(ParamStr(0), filename, ParamStr(0), 0);
		except
			on E: Exception do begin
				MessageDlg('Erro de atalho: ' + E.Message, mtError, [mbOK], 0);
			end;
		end;
		//Termina a aplica��o
		Application.Terminate;
	end else begin
		//carrega as informa��es de vers�o
		try
			Self.InitVersionsConfig();
		except
			on E: Exception do begin
				AppLog.AppFatalError('Erro carregando configura��es base: '#13#10 + E.Message, 2, True);
			end;
		end;
		//Inicia componentes internos
		Self.tmrTrigger.Enabled  := True;
		Self.tmrTrigger.Interval := GlobalInfo.CycleInterval;
		Self.tmrTrigger.OnTimer  := Self.tmrTriggerTimer;
		Application.ShowMainForm := False;
	end;
end;

procedure TVVSMMainDM.EndSession;
begin
	//Envia a finaliza��o de sess�o para o servidor
	Self.tcpclntRegister.IOHandler.WriteLn(STR_END_SESSION_SIGNATURE + GlobalInfo.ClientName); //Envia msg de fim de sess�o
	{TODO -oroger -cURGENTE : na vers�o de produ��o atual n�o h� leitura da recep��o por parte do cliente do retorno do servidor, assim a disconex�o fica pendente em algum lado }
end;

function TVVSMMainDM.GlobalStatusStr: string;
///retorna cadeia com o status das aplica��es
begin
	if (GlobalInfo.UpdateStatus = usOK) then begin
		Result := 'Atualizados';
	end else begin
		Result := 'DESATUALIZADOS PARA SEU PERFIL';
	end;
end;

procedure TVVSMMainDM.InitVersionsConfig;
{ {
  Rotina de inicializa��o para a carga dos parametros iniciais e perfil associado
}
var
	baseCfgURL, remoteConfFile, localConfFile: string;
	ret                                      : Integer;
begin
	GlobalInfo := TVVStartupConfig.Create(SysUtils.ChangeFileExt(ParamStr(0), '.ini'), APP_CONFIG_KEYPREFIX);
	TLogFile.GetDefaultLogFile.DebugLevel := GlobalInfo.DebugLevel;
	TLogFile.LogDebug('Iniciando configura��es do aplicativo', DBGLEVEL_ULTIMATE);
	localConfFile := TFileHnd.ConcatPath([GlobalInfo.PathLocalRepository, VERSION_INFO_FILENAME]); //caminho local
	baseCfgURL    := GlobalInfo.RootBaseConfigFilename; //arquivo base
	//baixar vers�o atual do arquivo de configura��o antes de usar a local
	TLogFile.LogDebug('Baixando startup remoto em ' + baseCfgURL, DBGLEVEL_DETAILED);
	if (not GlobalInfo.LoadHTTPContent(baseCfgURL, localConfFile)) then begin
		//Sempre ser carregado por este caminho
		//tenta atualizar arquivo de configura��o base
		if (not GlobalInfo.IsPrimaryPC) then begin
			remoteConfFile := TFileHnd.ConcatPath([GlobalInfo.RemoteRepositoryPath, VERSION_INFO_FILENAME]);
			//Sempre ser carregado por este caminho
			ForceDirectories(GlobalInfo.PathLocalRepository);
			ret := TFileHnd.CopyFile(remoteConfFile, localConfFile, True, True);
			if (ret <> ERROR_SUCCESS) then begin
				raise Exception.CreateFmt('Arquivo (%s) de configura��o inicial n�o pode ser carregado'#13#10'%s',
					[localConfFile, SysErrorMessage(ret)]);
			end;
		end;
	end;
	if (not FileExists(localConfFile)) then begin
		raise Exception.Create('Arquivo de configura��o base n�o encontrado');
	end;
	//Alterna para a configura��o carregada antes do disparo dos threads auxiliares
	FreeAndNil(GlobalInfo);
	GlobalInfo := TVVStartupConfig.Create(localConfFile, APP_CONFIG_KEYPREFIX);
	//VersionConfig := TVVConfig.Create(filename, 'VVer'); //carrega o arquivo de vers�es atualizado/valido
end;

procedure TVVSMMainDM.InitSettings;
var
	FS: TFormatSettings;
begin
	{$WARN UNSAFE_CODE OFF}
	FS                   := TStrConv.FormatSettings^;
	FS.DecimalSeparator  := '.';
	FS.ThousandSeparator := ' ';
	TStrConv.AdjustFormatSettings(FS);
	{$WARN UNSAFE_CODE ON}
end;

procedure TVVSMMainDM.Mostrar1Click(Sender: TObject);
begin
	Application.MainForm.Show;
end;

procedure TVVSMMainDM.PostRequest(Args: array of string);
var
	req, s: string;
begin
	req := EmptyStr;
	for s in Args do begin
		req := req + s + TOKEN_DELIMITER;
	end;
	try
		TLogFile.LogDebug(STR_CMD_VERB + req, DBGLEVEL_ULTIMATE);
		Self.tcpclntRegister.IOHandler.Write(STR_CMD_VERB + req); //write -> cadeia possui fim de linha
	except
		on E: Exception do begin
			raise Exception.Create('Erro enviando solicita��o ao servidor: ' + E.Message);
		end;
	end;
end;

procedure TVVSMMainDM.PostStatus(CurrentStatus: TVVUpdateStatus);
var
	p   : TProgItem;
	Data: string;
	I   : Integer;
begin
	//Calcula valor a postar
	Data  := EmptyStr;
	for I := 0 to GlobalInfo.ProfileInfo.Count - 1 do begin
		p := GlobalInfo.ProfileInfo.Programs[I];
		if (not p.isUpdated) then begin
			Data := Data + p.Desc + '[' + GetEnumName(TypeInfo(TVVUpdateStatus), Integer(p.UpdateStatus)) + ']' + TOKEN_DELIMITER;
		end;
	end;
	//Postar o registro do status
	{$WARN IMPLICIT_STRING_CAST_LOSS OFF} {$WARN IMPLICIT_STRING_CAST OFF}
	Self.PostRequest([Verb2String(vvvRegisterStatus), HTTPEncode(Data)]);
	{$WARN IMPLICIT_STRING_CAST_LOSS ON} {$WARN IMPLICIT_STRING_CAST ON}
	Data := Self.ReadResponse();
	if (SameText(Data, STR_OK_PACK)) then begin
		Self.FLastRegisterSended := Now();
		Self.FLastStatus         := CurrentStatus;
	end;
end;

function TVVSMMainDM.ReadResponse: string;
var
	ret: string;
begin
	try
		{$WARN IMPLICIT_STRING_CAST_LOSS OFF} {$WARN IMPLICIT_STRING_CAST OFF}
		Result := HTTPDecode(Self.tcpclntRegister.IOHandler.ReadLn(nil)); //leitura da resposta em si
		{$WARN IMPLICIT_STRING_CAST_LOSS ON} {$WARN IMPLICIT_STRING_CAST ON}
	except
		on E: Exception do begin
			raise Exception.Create('Erro lendo resposta do servidor.' + E.Message);
		end;
	end;
	try
		//Leitura da checagem da resposta
		ret := Self.tcpclntRegister.IOHandler.ReadLn(nil); //codigo de retorno
		if (ret <> STR_OK_PACK) then begin
			raise Exception.CreateFmt('Opera��o falhou(%s):'#13#10'%s', [ret, Result]);
		end;
	except
		on E: Exception do begin { TODO -oroger -cdsg : verificar e garantir o envio recebimento nesta codifica��o }
			raise Exception.Create('Resposta de leitura de conte�do n�o foi completa ou falha.'#13#10 + E.Message);
		end;
	end;
end;

procedure TVVSMMainDM.RegisterStatusServer(CurrentStatus: TVVUpdateStatus);
begin
	if ((Self.FLastRegisterSended <> 0) and (Self.FLastStatus = CurrentStatus)) then begin
		Exit;
	end;
	try
		Self.StartClient();
		try
			Self.StartSession();
			try
				Self.PostStatus(CurrentStatus);
			finally
				Self.EndSession;
			end;
		finally
			Self.StopClient();
		end;
	except
		on E: Exception do begin
			TLogFile.Log('Erro durante registro de status no servidor(' + GlobalInfo.RegisterServer + '): ' + E.Message, lmtError);
		end;
	end;
end;

procedure TVVSMMainDM.Sair1Click(Sender: TObject);
begin
	Application.Terminate;
end;

procedure TVVSMMainDM.ShowNotification(StatusOK: TVVUpdateStatus);
begin
	Self.TrayIcon.Visible := True;
	case StatusOK of
		usUnknow: begin
				Self.TrayIcon.IconIndex := ICON_UNKNOW;
			end;
		usOld: begin
				Self.TrayIcon.IconIndex := ICON_NOT_UPDATED;
			end;
		usOK: begin
				Self.TrayIcon.IconIndex := ICON_UPDATED;
			end;
	end;
end;

procedure TVVSMMainDM.StartClient;
begin
	Self.InitSettings();

	Self.tcpclntRegister.Host           := GlobalInfo.RegisterServer;
	Self.tcpclntRegister.Port           := GlobalInfo.NetClientPort;
	Self.tcpclntRegister.OnDisconnected := tcpclntDisconnected;
	Self.tcpclntRegister.OnConnected    := tcpclntConnected;
	Self.tcpclntRegister.ConnectTimeout := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	Self.tcpclntRegister.IPVersion      := Id_IPv4;
	Self.tcpclntRegister.ReadTimeout    := 0; //usa o valor dado por  IdTimeoutDefault
	//Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
	TLogFile.LogDebug(Format('Falando na porta:(%d) - Servidor:(%s)', [GlobalInfo.NetClientPort, GlobalInfo.RegisterServer]),
		DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.StartSession;
var
	SessionName, ret, msg: string;
begin
	try
		SessionName := GlobalInfo.ClientName;
		//Envia a abertura de sess�o para o servidor
		Self.tcpclntRegister.Connect;
		//passa valores obrigatorios para inicio de sess�o
		Self.tcpclntRegister.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //cabecalho da sess�o
		Self.tcpclntRegister.IOHandler.WriteLn(Self.fvVersion.FileVersion); //vers�o do cliente
		Self.tcpclntRegister.IOHandler.WriteLn(GlobalInfo.ClientName); //Nome do computador cliente
		Self.tcpclntRegister.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //repete cabecalho da sess�o
		ret := Self.tcpclntRegister.IOHandler.ReadLn();
		if (not SameText(ret, STR_OK_PACK)) then begin
			try
				msg := Self.tcpclntRegister.IOHandler.ReadLn();
			except
				on E: Exception do begin
					msg := '"' + msg + '"'#13#10 + E.Message;
				end;
			end;
			raise Exception.Create('Sess�o n�o pode ser iniciada: ' + msg);
		end;
	except
		on E: Exception do begin //colocar como registro de depura��o, por se tratar de erro comum
			TLogFile.LogDebug(Format('Falha de comunica��o com o servidor pai desta inst�ncia(%s) na porta(%d).'#13#10,
				[Self.tcpclntRegister.Host, Self.tcpclntRegister.Port]) + E.Message, DBGLEVEL_ALERT_ONLY);
			raise;
		end;
	end;
end;

procedure TVVSMMainDM.StopClient;
///<summary>
///Atividade opcional, pois o processamento por sess�o � r�pido
///</summary>
///<remarks>
///
///</remarks>
begin
	if (Self.tcpclntRegister.Connected()) then begin
		Self.tcpclntRegister.Disconnect;
	end;
end;

procedure TVVSMMainDM.tcpclntConnected(Sender: TObject);
begin
	TLogFile.LogDebug('Conectado ao servidor', DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.tcpclntDisconnected(Sender: TObject);
begin
	TLogFile.LogDebug('Desconectado do servidor', DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.tmrTriggerTimer(Sender: TObject);
//A cada ciclo:
//1 - remonta-se a compara��o
//2 - Incrementa contador de instancia para atingir 10 e verifica-se a notifica��o ao servidor
var
	bUpd: TVVUpdateStatus;
begin
	Inc(Self.FPassCount);
	if ((Self.FPassCount div 100) = 0) then begin
		Self.InitVersionsConfig; //recarrega configura��es
		Self.FPassCount := 0;    //evita estouro
	end;
	bUpd := GlobalInfo.UpdateStatus;
	VVSMMainDM.ShowNotification(bUpd); //atualiza icone de status
	Self.RegisterStatusServer(usOld);
end;

procedure TVVSMMainDM.TrayIconMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
	rtVersion   : string;
	hint, status: string;
begin
	rtVersion := 'Vers�o: ' + Self.fvVersion.FileVersion;
	hint      := 'SESOP - VVER Monitor' + #13#10 + rtVersion + #13#10;
	hint      := hint + 'Perfil = ' + GlobalInfo.ProfileName + #13#10;
	try
		if (Self.FDownloadExecuted) then begin
			status := 'Logar-se como instalador e atualizar.';
		end else begin
			status := Self.GlobalStatusStr;
		end;
	except
		on E: Exception do begin
			status := 'Indeterminado';
		end;
	end;
	hint               := hint + 'Status dos sistemas = ' + status;
	Self.TrayIcon.hint := hint;
end;

procedure TVVSMMainDM.UpdateFiles;
var
	dest, src: TManagedFolder;
	list     : TVVSFileList;
	f        : TVVsFile;
	newName  : string;
	mask     : TMask;
	ret      : Integer;
begin
	TLogFile.LogDebug('Iniciando processo de atualiza��o', DBGLEVEL_DETAILED);
	dest := TManagedFolder.CreateLocal(GlobalInfo.PathLocalRepository);
	src  := TManagedFolder.CreateLocal(GlobalInfo.RemoteRepositoryPath);
	list := TVVSFileList.Create;
	mask := TMask.Create('*.cvc');
	try
		dest.Diff(src, list);
		for f in list do begin
			if (TStrHnd.endsWith(f.FullFilename, '.')) then begin
				TLogFile.LogDebug(Format('Ignorando entrada de arquivo para %s', [f.FullFilename]), DBGLEVEL_DETAILED);
			end;
			if (f.Parent = dest) then begin
				TLogFile.LogDebug(Format('Opera��o de apagmento de %s', [f.FullFilename]), DBGLEVEL_DETAILED);
				if (not mask.Matches(f.FullFilename)) then begin
					f.Delete;
				end;
			end else begin
				if (not f.IsDirectory) then begin
					newName := TFileHnd.ConcatPath([dest.RootDir, Copy(f.filename, 2, Length(f.filename))]);
					try
						TLogFile.LogDebug(Format('Copiando %s para %s', [f.FullFilename, newName]), DBGLEVEL_DETAILED);
						ret := TFileHnd.CopyFile(f.FullFilename, newName, True, True);
						if (ret <> ERROR_SUCCESS) then begin
							raise Exception.CreateFmt('Erro copiando %s para %s.'#13#10'%s ',
								[f.FullFilename, newName, SysErrorMessage(ret)]);
						end;
					except
						on E: Exception do begin
							raise Exception.CreateFmt('Falha copiando %s para %s'#13#10'%s', [f.FullFilename, newName, E.Message]);
						end;
					end;
				end;
			end;
		end;
		Self.FDownloadExecuted := True;
	finally
		mask.Free;
		list.Free;
	end;
end;

end.
