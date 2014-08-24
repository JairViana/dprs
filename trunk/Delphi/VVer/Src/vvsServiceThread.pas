{$IFDEF vvsServiceThread}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsServiceThread;

interface

uses
	 SysUtils, Windows, Classes, XPFileEnumerator, XPThreads, vvsConsts, vvsConfig;

type

	 TVVerClientThread = class(TXPNamedThread)
	 private
		 FCycleErrorCount : Integer;
		 FLastVerification: TDateTime;
		 procedure DoClientCycle;
		 function GlobalLocalHash() : string;
	 public
		 procedure Execute(); override;
		 property LastVerification : TDateTime read FLastVerification;
    end;


    TVVerServerThread = class(TXPNamedThread)
    private
        //procedure StoreTransmitted(SrcFile : TFileSystemEntry);
        procedure DoServerCycle;
        //procedure CreatePrimaryBackup(const DirName : string);
        procedure StartTCPServer;
        procedure StopTCPServer;
    protected
        procedure DoTerminate(); override;
    public
        procedure Execute(); override;
    end;


implementation

uses
    vvsTCPTransfer, AppLog, FileHnd, StreamHnd;

{ TVVerServiceThread }

procedure TVVerServerThread.DoServerCycle;
begin
    {TODO -oroger -cdsg : Delimitar o que fara o ciclo servidor al�m de reenvio de logs}
end;

procedure TVVerServerThread.DoTerminate;
begin
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

end;

{ TClientThread }

procedure TVVerClientThread.DoClientCycle;
var
	localHash, remoteHash : string;
begin
	 {TODO -oroger -cdsg : Buscar por atualiza��es}


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

function TVVerClientThread.GlobalLocalHash : string;
var
    path :  string;
    Files : IEnumerable<TFileSystemEntry>;
    f :     TFileSystemEntry;
    ls :    TStringList;
begin
	 ls := TStringList.Create;
    try
        path  := VVSvcConfig.PathLocalInstSeg;
        Files := TDirectory.FileSystemEntries(path, '*.*', True);
        for f in Files do begin
            ls.Add(THashHnd.MD5(f.FullName));
        end;
    finally
        ls.Free;
    end;
end;

end.
