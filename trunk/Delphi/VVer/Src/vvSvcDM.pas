{$IFDEF vvSvcDM}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
unit vvSvcDM;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, IdBaseComponent, IdMessage, IdComponent, IdRawBase,
	IdRawClient, IdIcmpClient, FileInfo, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase,
	IdSMTP, XPThreads, ExtCtrls, vvsServiceThread, vvsFileMgmt, MS_ICMP;

type
	TVVerService = class(TService)
		mailMsgNotify: TIdMessage;
		icmpclntMain: TIdIcmpClient;
		fvInfo: TFileVersionInfo;
		smtpSender: TIdSMTP;
		tmrCycleEvent: TTimer;
		procedure ServiceAfterInstall(Sender: TService);
		procedure ServiceBeforeInstall(Sender: TService);
		procedure ServiceCreate(Sender: TObject);
		procedure ServiceStart(Sender: TService; var Started: boolean);
		procedure ServiceContinue(Sender: TService; var Continued: boolean);
		procedure ServicePause(Sender: TService; var Paused: boolean);
		procedure tmrCycleEventTimer(Sender: TObject);
	private
		{ Private declarations }
		FLastLogCheck: Word;
		FServerThread: TVVerServerThread;
		FClientThread: TVVerClientThread;
		procedure InitPublications();
		procedure AddDestinations;
		procedure CheckLogs();
		function isIntranetConnected(): boolean;
		procedure ServiceThreadPulse();
		function SendMailNotification(const NotificationText: string): boolean;
		function GetTitle: string;
	public
		class function LogFilePrefix(): string;
		function GetServiceController: TServiceController; override;
		destructor Destroy; override;
		constructor Create(AOwner: TComponent); override;
		property Title: string read GetTitle;
		class procedure AlignEndStream(AStrm: TStream; AMultSize: Integer);
		class function GetBlockHash(AStrm: TMemoryStream; ALength: Integer): string;
		{ Public declarations }
	end;

var
	VVerService: TVVerService;

implementation

uses
	WinReg32, FileHnd, AppLog, vvsConsts, XPFileEnumerator, XPTypes, StrHnd, IdGlobal,
	Str_Pas, IdEMailAddress, WinNetHnd, StreamHnd, vvConfig;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
	VVerService.Controller(CtrlCode);
end;

procedure TVVerService.AddDestinations;
var
	dst: TIdEMailAddressItem;
	lst: TStringList;
	x  : Integer;
begin
	lst := TStringList.Create;
	try
		lst.Delimiter     := ';';
		lst.DelimitedText := GlobalInfo.NotificationList;
		for x             := 0 to lst.Count - 1 do begin
			dst           := Self.mailMsgNotify.Recipients.Add();
			dst.Address   := lst.Strings[x];
			dst.Name      := 'SESOP - Verificador de Sistemas eleitorais';
		end;
	finally
		lst.Free;
	end;
end;

class procedure TVVerService.AlignEndStream(AStrm: TStream; AMultSize: Integer);
///caso o stream n�o possua tamanho multiplo de AMultSize o complemento � preenchido com zeros
var
	pbesta: array of byte;
	compl : Integer;
	delta : int64;
begin
	compl := 0;
	delta := AStrm.Size mod AMultSize;
	if (delta <> 0) then begin
		compl      := AMultSize - delta;
		AStrm.Size := AStrm.Size + compl;
	end;
	compl := AStrm.Size - AStrm.Position;
	if (compl > 0) then begin
		SetLength(pbesta, compl + 1); { TODO -oroger -cdsg : testar se zera conteudo da memoria }
		AStrm.Write(PByte(pbesta)^, compl);
	end;
end;

procedure TVVerService.CheckLogs;
///<summary>
///Buscar por logs posteriores a data de registro, enviando todos aqueles que possuirem erros.
///A cada envio com sucesso avancar a data de registro para a data do respectivo arquivo de log e buscar pelo mais antigo at� chegar ao log atual
///</summary>
///<remarks>
///
///</remarks>
var
	Files                            : IEnumerable<TFileSystemEntry>;
	f                                : TFileSystemEntry;
	currLogName, newLogName, sentPath: string;
	logText                          : TXPStringList;
	dummy                            : Integer;
	sentOK                           : boolean;
	lt                               : TSystemTime;
begin
	//Registra a hora da ultima passagem de verifica��o de log
	currLogName := AppLog.TLogFile.GetDefaultLogFile.FileName;
	GetLocalTime(lt);
	if (Self.FLastLogCheck <> lt.wHour) then begin
		newLogName := TFileHnd.ConcatPath([GlobalInfo.PathServiceLog, TVVerService.LogFilePrefix() + FormatDateTime('YYYYMMDD',
			Now())]) + '.log';
		if (currLogName <> newLogName) then begin
			AppLog.TLogFile.GetDefaultLogFile.FileName := newLogName;
			currLogName                                := newLogName;
		end;
		Self.FLastLogCheck := lt.wHour; //Registra a mudanca de hora
	end;
	//filtra arquivos referentes apenas a este runtime
	Files := TDirectory.FileSystemEntries(GlobalInfo.PathServiceLog, TVVerService.LogFilePrefix + '*.log', False);
	for f in Files do begin
		if (not Sametext(f.FullName, currLogName)) then begin //Pula o arquivo em uso no momento como saida de log
			logText := TXPStringList.Create;
			try
				logText.LoadFromFile(f.FullName);
				dummy  := 1;                                                    //Sempre do inicio
				sentOK := not logText.FindPosIgnoreCase('erro:', dummy, dummy); //Marca para envio em caso de erro presente
				sentOK := sentOK and (not logText.FindPosIgnoreCase('Alarme:', dummy, dummy)); //Idem acima para o caso de alarmes
				if (not sentOK) then begin
					try
						sentOK := Self.SendMailNotification(logText.Text);
					except
						on E: Exception do begin //Apenas logar a falha de envio e continuar com os demais arquivos
							TLogFile.Log('Envio de notifica��es de erro falhou:'#13#10 + E.Message, lmtError);
							sentOK := False;
						end;
					end;
				end;
				//mover arquivo para a pasta de enviados applog
				if (sentOK) then begin
					sentPath := GlobalInfo.PathServiceLog + '\Sent\';
					ForceDirectories(sentPath);
					sentPath := sentPath + f.Name;
					sentPath := TFileHnd.NextFamilyFilename(sentPath);
					if (not MoveFile(PWideChar(f.FullName), PWideChar((sentPath)))) then begin
						TLogFile.Log('Final do processamento de arquivo de log falhou:'#13#10 + SysErrorMessage(GetLastError()),
							lmtError);
					end;
				end;
			finally
				logText.Free;
			end;
		end;
	end;
end;

constructor TVVerService.Create(AOwner: TComponent);
begin
	inherited;
	GlobalInfo := TVVStartupConfig.Create(SysUtils.ChangeFileExt(ParamStr(0), '.ini'), APP_CONFIG_KEYPREFIX);
end;

destructor TVVerService.Destroy;
begin
	if (Assigned(Self.FServerThread)) then begin
		Self.FServerThread.Terminate;
		FreeAndNil(Self.FServerThread);
	end;
	if (Assigned(Self.FClientThread)) then begin
		Self.FClientThread.Terminate;
		FreeAndNil(Self.FClientThread);
	end;

	if (Assigned(GlobalPublication)) then begin
		FreeAndNil(GlobalPublication);
	end;
	inherited;
end;

class function TVVerService.GetBlockHash(AStrm: TMemoryStream; ALength: Integer): string;
begin
	raise Exception.Create('Usar rotina da classe de configura��o agora');
end;

function TVVerService.GetServiceController: TServiceController;
begin
	Result := ServiceController;
end;

function TVVerService.GetTitle: string;
begin
	if (Application.ServiceCount = 0) then begin
		Result := 'Aplicativo de depura��o desktop';
	end else begin
		Result := Application.Title;
		if (Result = EmptyStr) then begin
			raise Exception.Create('Informa��es de vers�o desta inst�ncia n�o est�o completas(T�tulo)');
		end;
	end;
end;

procedure TVVerService.InitPublications;
begin
	//Inicia as instancias de publica��es globais
	if (not Assigned(vvsFileMgmt.GlobalPublication)) then begin
		if (ForceDirectories(GlobalInfo.PathLocalRepository)) then begin
			vvsFileMgmt.GlobalPublication := TVVSPublication.Create(PUBLICATION_INSTSEG, GlobalInfo.PathLocalRepository);
		end else begin
			raise Exception.Create('Caminho da publica��o INSTSEG inv�lido: ' + GlobalInfo.PathLocalRepository);
		end;
	end;
end;

function TVVerService.isIntranetConnected: boolean;
///Alerta: M�todo n�o thread safe
var
	x      : Integer;
	PingObj: TICMP;
begin
	{
	  ///    Self.icmpclntMain.Protocol       := 1;
	  ///    Self.icmpclntMain.ReceiveTimeout := 2000;
	  ///    Self.icmpclntMain.ProtocolIPv6   := 58;
	  ///    Self.icmpclntMain.IPVersion      := Id_IPv4;
	  ///    Self.icmpclntMain.PacketSize     := 32;
	  ///    Self.icmpclntMain.Host           := GlobalInfo.RegisterServer;
	  ///    Result                           := False;
	}
	PingObj := TICMP.Create;
	try
		for x := 0 to 5 do begin
			try
				PingObj.Address := GlobalInfo.RegisterServer;
				Result          := (PingObj.Ping <> 0);
				{TODO -oroger -cdsg : remover component de ping indy que requer eleva��o no win7}
				//Result := (Self.icmpclntMain.ReplyStatus.ReplyStatusType = rsEcho);
			except
				on E: Exception do begin
					//Sem tratamento -> espera nova tentativa
					TLogFile.LogDebug(Format('Sem conectividade com a intranet(%s): %s.'#13#10'Tentativa(%d)',
						[GlobalInfo.RegisterServer, E.Message, x + 1]), DBGLEVEL_ULTIMATE);
				end;
			end;
			if (Result) then begin
				Break;
			end;
		end;
	finally
		PingObj.Free;
	end;
end;

class function TVVerService.LogFilePrefix: string;
begin
	Result := APP_SERVICE_NAME + '_' + TFileHnd.ExtractFilenamePure(ParamStr(0)) + '_';
end;

function TVVerService.SendMailNotification(const NotificationText: string): boolean;
begin
	Result := False;
	if (not Self.isIntranetConnected) then begin //Verificar a conectividade com a intranet
		Exit;
	end;

	mailMsgNotify.ConvertPreamble    := True;
	mailMsgNotify.AttachmentEncoding := 'UUE';
	mailMsgNotify.Encoding           := mePlainText;
	mailMsgNotify.From.Address       := GlobalInfo.SenderAddress;
	mailMsgNotify.From.Name          := Self.Title;
	mailMsgNotify.From.Text          := Format(' %s <%s>', [Application.Title, GlobalInfo.SenderAddress]);
	mailMsgNotify.From.Domain        := Str_Pas.GetDelimitedSubStr('@', GlobalInfo.SenderAddress, 1);
	mailMsgNotify.From.User          := Str_Pas.GetDelimitedSubStr('@', GlobalInfo.SenderAddress, 0);
	mailMsgNotify.Sender.Address     := GlobalInfo.SenderAddress;
	mailMsgNotify.Sender.Name        := APP_NOTIFICATION_DESCRIPTION;
	mailMsgNotify.Sender.Text        := Format('"%s" <%s>', [APP_NOTIFICATION_DESCRIPTION, GlobalInfo.SenderAddress]);
	mailMsgNotify.Sender.Domain      := mailMsgNotify.From.Domain;
	mailMsgNotify.Sender.User        := mailMsgNotify.From.User;

	//Coletar informa��es de destino de mensagem com possibilidade de macros no mesmo arquivo de configura��o
	Self.AddDestinations();

	Self.mailMsgNotify.Subject := Format(SUBJECT_TEMPLATE, [Self.fvInfo.FileVersion, GlobalInfo.ClientName,
		FormatDateTime('yyyyMMDDhhmm', Now())]);
	Self.mailMsgNotify.Body.Text := NotificationText + #13#10'****** Arquivo de configura��o ******' + #13#10 + GlobalInfo.ToString;
	//insere arquivo de configura��o ao final
	try
		Self.smtpSender.Connect;
		Self.smtpSender.Send(Self.mailMsgNotify);
		Self.smtpSender.Disconnect(True);
		Result := True;
	except
		on E: Exception do begin
			raise EVVException.Create('Falha enviando notifica��o: ' + E.Message);
		end;
	end;
end;

procedure TVVerService.ServiceAfterInstall(Sender: TService);
///<summary>
///Registra as informa��es de fun��o deste servi�o
///</summary>
var
	Reg    : TRegistryNT;
	svcType: Integer;
	svcKey : string;
begin
	Reg := TRegistryNT.Create();
	try
		svcKey := TFileHnd.ConcatPath(['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services', Self.Name]);
		Reg.WriteFullString(svcKey + '\Description', 'Verifica��o das vers�es dos aplicativos seguros.', True);
		Reg.ReadFullInteger(svcKey + '\Type', svcType);
		svcType := svcType or $100; //Nono bit para indicar interativo
		Reg.WriteFullInteger(svcKey + '\Type', svcType, True);
	finally
		Reg.Free;
	end;
	TLogFile.Log('Servi�o instalado com sucesso neste computador', lmtAlarm);
end;

procedure TVVerService.ServiceBeforeInstall(Sender: TService);
///<summary>
///Ajusta os parametros do servi�o antes de sua instala��o. Dentre as a��es est� levantar o servi�o como o �ltimo da lista de
///servi�os
///</summary>
///<remarks>
///
///</remarks>
var
	Reg: TRegistryNT;
	lst: TStringList;
begin
	Reg := TRegistryNT.Create;
	lst := TStringList.Create;
	try
		Reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', lst);
		if ((lst.IndexOf(APP_SERVICE_GROUP) < 0)) then begin
			lst.Add(APP_SERVICE_GROUP);
			TLogFile.Log('Alterando ordem de inicializa�ao dos servi�os no registro local', lmtInformation);
			if (not IsDebuggerPresent()) then begin
				Reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', lst, True);
			end;
		end;
	finally
		Reg.Free;
		lst.Free;
	end;
	TLogFile.Log('Ordem de carga do servi�o alterada com SUCESSO no computador local', lmtInformation);
end;

procedure TVVerService.ServiceContinue(Sender: TService; var Continued: boolean);
///<summary>
///Reincio do servico
///</summary>
///<remarks>
///
///</remarks>
begin
	TLogFile.LogDebug('Chamada de ServiceContinue em execu��o', DBGLEVEL_ULTIMATE);
	Continued := False;
	//Libera��o do thread servidor
	if Assigned(Self.FServerThread) then begin
		if Self.FServerThread.Suspended then begin
			TLogFile.LogDebug('Liberando thread de servi�o servidor de conex�es', DBGLEVEL_ULTIMATE);
			Self.FServerThread.Start; //Dispara o thread de servi�o
			Sleep(300);
		end;
		Continued := (not Self.FServerThread.Finished);
	end else begin
		Continued := True; //primeiro teste OK
	end;

	//Libera��o do thread cliente
	if Assigned(Self.FClientThread) then begin
		if Self.FClientThread.Suspended then begin
			TLogFile.LogDebug('Liberando thread de servi�o cliente', DBGLEVEL_ULTIMATE);
			Self.FClientThread.Start; //Dispara o thread de servi�o
			Sleep(300);
		end;
		Continued := (not Self.FClientThread.Finished) and Continued; //threads necessarios levantados
	end;
end;

procedure TVVerService.ServiceCreate(Sender: TObject);
begin
	Self.DisplayName            := APP_SERVICE_DISPLAYNAME;
	Self.Interactive            := True;
	Self.WaitHint               := 1000;
	Self.smtpSender.Host        := 'smtp.tre-pb.gov.br';
	Self.tmrCycleEvent.Interval := 60000;
	Self.tmrCycleEvent.Enabled  := False;
end;

procedure TVVerService.ServicePause(Sender: TService; var Paused: boolean);
begin
	TLogFile.LogDebug('Chamada de ServicePause em execu��o', DBGLEVEL_ULTIMATE);

	//Libera��o do thread servidor
	if Assigned(Self.FServerThread) then begin
		if Self.FServerThread.Suspended then begin
			TLogFile.LogDebug('Liberando thread de servi�o servidor de conex�es', DBGLEVEL_ULTIMATE);
			Self.FServerThread.Start; //Dispara o thread de servi�o
			Sleep(300);
		end;
		Paused := (not Self.FServerThread.Finished);
	end else begin
		Paused := False;
		TLogFile.Log('Thread de Servi�o servidor n�o criado anteriormente!');
	end;

	//Libera��o do thread cliente
	if Assigned(Self.FClientThread) then begin
		if Self.FClientThread.Suspended then begin
			TLogFile.LogDebug('Liberando thread de servi�o cliente', DBGLEVEL_ULTIMATE);
			Self.FClientThread.Start; //Dispara o thread de servi�o
			Sleep(300);
		end;
		Paused := (not Self.FClientThread.Finished);
	end else begin
		Paused := False;
		TLogFile.Log('Thread de Servi�o cliente n�o criado anteriormente!');
	end;
end;

procedure TVVerService.ServiceStart(Sender: TService; var Started: boolean);
var
	msvc: string;
begin
	try
		Self.CheckLogs(); //proteger chamada ,pois rede pode estar instavel neste momento
	except
		on E: Exception do begin
			TLogFile.Log('Checagem de logs falhou.'#13#10 + E.Message, lmtWarning);
		end;
	end;

	TLogFile.Log('Iniciando servi�o de verifica��o de vers�es', lmtInformation);

	msvc := ServiceStatus2String(Self.Status);

	TLogFile.LogDebug('Transi��o de estado durante in�cio do servi�o. Estado anterior = ' + msvc, DBGLEVEL_ULTIMATE);

	try
		if (Self.Status in [csStartPending, csStopped]) then begin //veio de parada(n�o pause)
			//Teste de inst�ncia servidora
			if (GlobalInfo.PathPublicationInstSeg <> EmptyStr) then begin
				TLogFile.Log('Criando thread de servi�o no modo Servidor', lmtInformation);
				InitPublications();
				Self.FServerThread := TVVerServerThread.Create(True, APP_SERVICE_NAME + 'Server'); //thread prim�rio servidor
			end else begin
				TLogFile.Log('Inst�ncia n�o funcionar� como servidor de publica��o', lmtInformation);
			end;
			//Teste de inst�ncia cliente
			if (GlobalInfo.PublicationParentServer <> EmptyStr) then begin
				TLogFile.Log('Criando thread de servi�o no modo Cliente', lmtInformation);
				Self.FClientThread := TVVerClientThread.Create(True, APP_SERVICE_NAME + 'Client'); //thread prim�rio client
			end else begin
				TLogFile.Log
					('Inst�ncia sem servidor pai configurado. Sem fonte de replica��o em uso(Thread cliente n�o ser� criado)',
					lmtInformation);
			end;
		end;
	except
		on E: Exception do begin
			TLogFile.Log('Erro fatal durante carga dos threads do servi�o: ' + E.Message, lmtError);
		end;
	end;

	Self.ServiceContinue(Sender, Started); //Rotinas de resumo do thread de servico
	if (Started) then begin
		Self.tmrCycleEvent.Interval := GlobalInfo.CycleInterval;
		Self.tmrCycleEvent.Enabled  := True; //Liberar disparo de libera��o de thread de servi�o
		TLogFile.Log('Servi�o ' + Self.Name + ' - Vers�o: ' + Self.fvInfo.FileVersion + ' - iniciado com sucesso.', lmtInformation);
	end else begin
		TLogFile.Log('Servi�o falhou em sua carga.', lmtWarning);
	end;
end;

procedure TVVerService.ServiceThreadPulse;
///Dispara libera os threads de servi�o de seu estado de ociosidade
begin

	if (Assigned(Self.FServerThread) and (not Self.FServerThread.Finished)) then begin
		Self.FServerThread.Suspended := False;
	end;

	if (Assigned(Self.FClientThread) and (not Self.FClientThread.Finished)) then begin
		Self.FClientThread.Suspended := False;
	end;
end;

procedure TVVerService.tmrCycleEventTimer(Sender: TObject);
begin
	//Realiza a checkagem dos logs a cada mudan�a de hora
	Self.CheckLogs;
	Self.ServiceThreadPulse();
end;

end.
