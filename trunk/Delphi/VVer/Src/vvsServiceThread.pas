{$IFDEF vvsServiceThread}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsServiceThread;

interface

uses
    SysUtils, Windows, Classes, XPFileEnumerator, XPThreads, vvsConsts, vvsConfig, vvsFileMgmt, IdContext,
    IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer, Generics.Collections,
    IdTCPServer, AppLog, IdGlobal;

type

    TVVerClientThread = class(TXPNamedThread)
    private
        FCycleErrorCount :  Integer;
        FLastVerification : TDateTime;
        FTempFolder :       TManagedFolder;
        FSyncFolder :       TManagedFolder;
        procedure DoClientCycle;
    public
        constructor Create(CreateSuspended : boolean; const ThreadName : string); override;
        procedure DoTerminate; override;
        procedure Execute(); override;
        property LastVerification : TDateTime read FLastVerification;
    end;


    TVVerServerThread = class(TXPNamedThread)
    private
        procedure DoServerCycle;
        procedure StartTCPServer;
        procedure StopTCPServer;
    protected
        procedure DoTerminate(); override;
    public
        constructor Create(CreateSuspended : boolean; const ThreadName : string); override;
        procedure Execute(); override;
    end;


    TClientSyncSession = class
    private
        FParent : TVVerClientThread;
        FSocket : TIdTCPClient;
        function GetCancelled : boolean;
    protected
        procedure PostRequest(Args : array of string);
        function ReadResponse() : string;
    public
        constructor Create(AParent : TVVerClientThread; ASocket : TIdTCPClient);
        property Cancelled : boolean read GetCancelled;
        function ReadRemoteContent(const PubName : string) : string;
        function Synch(const PubName : string; LocalFolder, TempFolder : TManagedFolder) : string;
    end;

implementation

uses
    vvsTCPTransfer, FileHnd, StreamHnd, StrHnd;

{ TVVerServiceThread }

constructor TVVerServerThread.Create(CreateSuspended : boolean; const ThreadName : string);
begin
    //Self.FInstSegPublication := TVVSPublication.Create( PUBLICATION_INSTSEG, VVSvcConfig.PathLocalInstSeg );
    if (not ForceDirectories(VVSvcConfig.PathLocalInstSeg)) then begin
        raise ESVCLException.CreateFmt('Caminho "%s" usado para reposit�rio local, n�o pode ser acessado',
            [VVSvcConfig.PathLocalInstSeg]);
    end;
    inherited;
end;

procedure TVVerServerThread.DoServerCycle;
begin
    {TODO -oroger -cdsg : Delimitar o que fara o ciclo servidor al�m de reenvio de logs, sugest�o para ser o local de atualiza��o de status }
end;

procedure TVVerServerThread.DoTerminate;
begin
    //Finaliza o servidor TCP
    Self.StopTCPServer;
    inherited;
end;

procedure TVVerServerThread.Execute;
{TODO -oroger -cdsg : repete o ciclo do servidor e aguarda sinaliza��es}
begin
    inherited;
    try
        Self.StartTCPServer; //Para o servidor inicia escuta na porta
    except
        on E : Exception do begin
            TLogFile.Log('Servi�o n�o pode continuar e ser� encerrado. Raz�o:' + E.Message, lmtError);
            raise;
        end;
    end;
    while (not Self.Terminated) do begin
        try
            Self.DoServerCycle();
        except
            on E : Exception do begin
                TLogFile.Log('Ciclo de organiza��o de arquivos do servidor de envio falhou: ' + E.Message, lmtError);
            end;
        end;
        Self.Suspended := True; //Libera cpu at� novo ciclo
    end;
end;

procedure TVVerServerThread.StartTCPServer;
//Verificar a atividade do servidor tcp, ativando o mesmo se necess�rio
begin
    try
        if (not DMTCPTransfer.tcpsrvr.Active) then begin
            TLogFile.LogDebug('Abrindo porta no modo servidor', DBGLEVEL_ULTIMATE);
            DMTCPTransfer.StartServer();
        end;
    except
        on E : Exception do begin
            TLogFile.Log('Chamada StartTCPServer retornou erro:' + E.Message, lmtError);
            raise;
        end;
    end;
end;

procedure TVVerServerThread.StopTCPServer;
begin
    DMTCPTransfer.StopServer;
end;

{ TClientThread }

constructor TVVerClientThread.Create(CreateSuspended : boolean; const ThreadName : string);
begin
    inherited;
    Self.FTempFolder := TManagedFolder.CreateLocal(VVSvcConfig.PathTempDownload);
    if (VVSvcConfig.ParentServer = EmptyStr) then begin
        raise ESVCLException.CreateFmt('Servidor pai desta inst�ncia inv�lido(%s)', [VVSvcConfig.ParentServer]);
    end;
end;

procedure TVVerClientThread.DoClientCycle;
var
    clientSession : TClientSyncSession;
begin
    {TODO -oroger -cdsg : Buscar por atualiza��es}
    DMTCPTransfer.StartSession(VVSvcConfig.ClientName + ' * ' + TimeToStr(Now()));
    clientSession := TClientSyncSession.Create(Self, DMTCPTransfer.tcpclnt);
    clientSession.Synch(PUBLICATION_INSTSEG, Self.FSyncFolder, Self.FTempFolder);
    DMTCPTransfer.EndSession(VVSvcConfig.ClientName);
end;

procedure TVVerClientThread.DoTerminate;
begin
    FreeAndNil(Self.FTempFolder);
    FreeAndNil(Self.FSyncFolder);
    inherited;
end;

procedure TVVerClientThread.Execute;
 ///<summary>
 ///Rotina primaria do caso de uso do servico.
 ///Nele temos 2 cenarios:
 /// 1 - Maquina secund�ria:
 ///     a) Enumera todos os arquivos da pasta de origem
 ///    b) Repassa todo os arquivos para a maquina prim�ria
 ///    c) Realiza seu backup local
 /// 2 - M�quina prim�ria:
 ///     a) Move todos os da pasta de recep��o remota para a pasta de transmiss�o
 ///     b) Move todos os arquivos da pasta transmitidos para a de backup global
 ///     c) Reorganiza todos os arquivos do backup global
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
var
    ErrorMessage : string;

    procedure LSRReportError(EComm : Exception);
    //notificar agente monitorador
    begin
        //Registrar o erro e testar o contador de erros
        Inc(Self.FCycleErrorCount);
        ErrorMessage := Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 +
            '�ltimo erro registrado = "%s"', [Self.FCycleErrorCount, EComm.Message]);
        if (Integer(Self.FCycleErrorCount) > 10) then begin
            TLogFile.Log(ErrorMessage, lmtError);
            Self.FCycleErrorCount := 0; //reseta contador global
        end;
    end;

begin
    inherited;
    DMTCPTransfer.StartClient(); //configura o tcpclient
    //Repetir os ciclos de acordo com a temporiza��o configurada
    //O Thread prim�rio pode enviar notifica��o da cancelamento que deve ser verificada ao inicio de cada ciclo
    while (not Self.Terminated) do begin
        try
            Self.DoClientCycle;
            Self.FCycleErrorCount := 0; //Reseta contador de erros do ciclo
        except
            on EComm : Exception do begin
                LSRReportError(EComm);
            end;
        end;
        //Suspende este thread at� a libera��o pelo thread do servi�o ou de mudan�a de arqivo monitorado
        Self.Suspended := True;
    end;
end;


{ TClientSyncSession }

constructor TClientSyncSession.Create(AParent : TVVerClientThread; ASocket : TIdTCPClient);
begin
    inherited Create;
    Self.FParent := AParent;
    Self.FSocket := ASocket;
end;

function TClientSyncSession.GetCancelled : boolean;
begin
    Result := Self.FParent.Terminated;
end;

procedure TClientSyncSession.PostRequest(Args : array of string);
var
    req, s : string;
begin
    req := EmptyStr;
    for s in Args do begin
        req := req + s + TOKEN_DELIMITER;
    end;
    try
        Self.FSocket.IOHandler.Write(STR_CMD_VERB + req);
    except
        on E : Exception do begin
            raise ESVCLException.Create('Erro enviando solicita��o ao servidor: ' + E.Message);
        end;
    end;
end;

function TClientSyncSession.ReadRemoteContent(const PubName : string) : string;
begin
    try
        Self.PostRequest([Verb2String(vvvReadContent), PubName]);
        Result := Self.ReadResponse();
    except
        on E : Exception do begin
            raise ESVCLException.Create('Cliente n�o pode carregar conte�do da publica��o: ' + PubName + #13#10 + E.Message);
        end;
    end;
end;

function TClientSyncSession.ReadResponse() : string;
var
    ret : string;
begin
    try
        Result := Self.FSocket.IOHandler.ReadLn(TEncoding.UTF8); //leitura da resposta em si
    except
        on E : Exception do raise ESVCLException.Create('Erro lendo resposta do servidor.' + E.Message);
    end;
    try //Leitura da checagem da resposta
        ret := Self.FSocket.IOHandler.ReadLn(); //codigo de retorno
        if (TStrHnd.startsWith(ret, STR_FAIL_PREFIX)) then begin
            raise Exception.Create('O servidor retornou erro para a opera��o: ' + ret);
        end;
    except
        on E : Exception do {TODO -oroger -cdsg : verificar e garantir o envio recebimento nesta codifica��o}
            raise ESVCLException.Create('Resposta de leitura de conte�do n�o foi completa ou falha.'#13#10 + E.Message);
    end;
end;

function TClientSyncSession.Synch(const PubName : string; LocalFolder, TempFolder : TManagedFolder) : string;
var
    remoteFolder : TManagedFolder;
    slines : string;
    delta :  TVVSFileList;
begin
    try
        slines := HttpDecode(Self.ReadRemoteContent(PUBLICATION_INSTSEG));
    except
        on E : Exception do raise ESVCLException.Create('Opera��o de sincronismo falhou: ' + E.Message);
    end;

    try
        remoteFolder := TManagedFolder.CreateRemote(slines);
    except
        on E : Exception do raise ESVCLException.Create('Erro de parser para inst�ncia de conte�do: '#13#10 + E.Message + #13#10 + slines);
    end;

    try
        Delta := TVVSFileList.Create;
        try
			 remoteFolder.Diff(Self.FParent.FTempFolder, Delta);
			 --io com o delta
        finally
            Delta.Free;
        end;
    finally
        remoteFolder.Free;
    end;

end;

end.
