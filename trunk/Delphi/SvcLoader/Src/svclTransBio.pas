{$IFDEF svclTransBio}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclTransBio;

interface

uses
    SysUtils, Windows, Classes, XPThreads;

type
    TTransBioThread = class(TXPNamedThread)
    private
        FStream :    TFileStream;
        FConnected : boolean;
        procedure DoCycle;
        procedure DoReplicate(const Filename : string);
        procedure DoCreatePrimaryBackup(const Filename : string);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure SetConnected(const Value : boolean);
    public
        procedure Execute(); override;
        property Connected : boolean read FConnected write SetConnected;
    end;

implementation

uses
    FSEnum, svclConfig, FileHnd, AppLog;

{ TTransBioThread }
procedure TTransBioThread.CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
//ErrMsg DEVE conter exatamente 4 tokens para string
var
    DestName : string;
begin
    //Verificar se existe o destino, garantindo nome �nico
	 if FileExists(Dest) then begin
		 DestName := TFileHnd.NextFamilyFilename(Dest);
	 end else begin
		 DestName := Dest;
	 end;
	 if not (ForceDirectories(ExtractFilePath(Dest))) then begin
		 raise Exception.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(ERROR_CANNOT_MAKE)]);
	 end;
	 if ToMove then begin
		 TLogFile.LogDebug( Format( 'Comando Move CopyBioFile(%s, %s, %s )', [ Source, Dest, Fase, ErrMsg ]), GlobalConfig.DebugLevel);
		 if not MoveFile(PWideChar(Source), PWideChar(DestName)) then begin
			 raise Exception.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
		 end;
	 end else begin
		TLogFile.LogDebug( Format( 'Comando Copy CopyBioFile(%s, %s, %s )', [ Source, Dest, Fase, ErrMsg ]), GlobalConfig.DebugLevel);
		 if not CopyFile(PWideChar(Source), PWideChar(DestName), True) then begin
			 raise Exception.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
		 end;
	 end;
end;

procedure TTransBioThread.DoCreatePrimaryBackup(const Filename : string);
var
	 dest, dirName : string;
	 fileDate : TDateTime;
begin
	 {TODO -oroger -cdsg : Servico sendo executado no computador primario, causa a execu��o de rotina de backup apeans }
	 dest:=GlobalConfig.PrimaryBackupPath;
	 fileDate:=TFileHnd.FileTimeChangeTime( Filename );
	 dirName:=FormatDateTime('yyyymmdd', fileDate );
	 dest := TFileHnd.ConcatPath([dest, dirName ]);
	 if not ForceDirectories( dest ) then begin
		 raise Exception.Create('Erro acessando pasta para backup do computador prim�rio'#13#10 + dest );
	 end;
	 dest := TFileHnd.ConcatPath([dest, ExtractFileName(Filename)]);
	 if FileExists( dest ) then begin
		dest := TFileHnd.NextFamilyFilename(dest);
	 end;
	 if not MoveFile(PWideChar(Filename), PWideChar(dest) ) then begin
		 raise Exception.CreateFmt('Falha criando backup para %s em %s'#13#10'%s', [Filename, dest,
			 SysErrorMessage(GetLastError())]);
	 end;
end;

procedure TTransBioThread.DoCycle;
///Inicia novo ciclo de opera��o
var
    FileEnt : IEnumerable<TFileSystemEntry>;
	 f : TFileSystemEntry;
begin
	TLogFile.LogDebug( 'Entrando em novo ciclo', GlobalConfig.DebugLevel );
	 if GlobalConfig.isPrimaryComputer then begin
		 //Para o caso do computador prim�rio o servi�o executa o caso de uso "DoCreatePrimaryBackup"
		 if DirectoryExists(  GlobalConfig.PrimaryTransmittedPath ) then begin
			FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PrimaryTransmittedPath, BIOMETRIC_FILE_MASK, False);
		 end else begin
			raise Exception.Create('Falha acessando pasta com arquivos do computador prim�rio j� transmitidos.'#13#10 + GlobalConfig.PrimaryTransmittedPath );
		 end;
		 for f in FileEnt do begin
			 Self.DoCreatePrimaryBackup(f.FullName);
        end;
    end else begin
        //Para o caso de esta��o(�nica a coletar dados biom�tricos), o sistema executar� o caso de uso "ReplicDataFiles2PrimaryMachine"
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.StationSourcePath, BIOMETRIC_FILE_MASK, False);
        for f in FileEnt do begin
            Self.DoReplicate(f.FullName);
        end;
    end;
end;

procedure TTransBioThread.DoReplicate(const Filename : string);
 //Realiza a opera��o unit�ria com o arquivo dado:
 //1 - Copia para a pasta local de transmiss�o
 //2 - Copia para a pasta de transmiss�o prim�ria
 //3 - Copia para o bakup local
 //4 - Apaga do local de aquisi��o
const
    ERR_MSG: string = 'Falha copiando arquivo'#13'%s'#13'para'#13'%s'#13'%s'#13'%s';
var
    PrimaryTransName, LocalTransName, LocalBackupName : string;
begin
	 TLogFile.LogDebug( Format('Processando arquivo: %s', [ Filename ] ), GlobalConfig.DebugLevel );
	 //Copia para a pasta local de transmiss�o
	 LocalTransName := TFileHnd.ConcatPath([GlobalConfig.StationLocalTransPath, ExtractFileName(Filename)]);
	 Self.CopyBioFile(Filename, LocalTransName, 'Transbio Local', ERR_MSG, False);

    //Copia arquivo para local remoto de transmiss�o
	 PrimaryTransName := TFileHnd.ConcatPath([GlobalConfig.StationRemoteTransPath, ExtractFileName(Filename)]);
	 Self.CopyBioFile(Filename, PrimaryTransName, 'Reposit�rio remoto prim�rio', ERR_MSG, False);

    //Move arquivo para backup local
    LocalBackupName := TFileHnd.ConcatPath([GlobalConfig.StationBackupPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalBackupName, 'Backup Local', ERR_MSG, True);

end;

procedure TTransBioThread.Execute;
var
    ErrCnt : Integer;
begin
    inherited;
    //Repetir os ciclos de acordo com a temporiza��o configurada
    //O Thread prim�rio pode enviar notifica��o da cancelamento que deve ser verificada ao inicio de cada ciclo
    try
        ErrCnt := 0;
        while Self.IsAlive do begin
            try
                Self.DoCycle;
                ErrCnt := 0;
            except
                on E : Exception do begin
                    //Registrar o erro e testar o contador de erros
                    Inc(ErrCnt);
                    if ErrCnt > 10 then begin
                        {TODO -oroger -cdsg : Interrromper servico e notificar agente monitorador}
                        TLogFile.Log(Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.', [ErrCnt]), lmtError);
                        Self.Terminate; //Chamada de finaliza��o de do ancestral especializado
                    end;
                end;
            end;
            //Suspende este thread at� a libera��o pelo thread do servi�o
            Self.Suspended := True;
        end;
    finally
        Self.FStream.Destroy;
    end;
end;

procedure TTransBioThread.SetConnected(const Value : boolean);
var
    Path : string;
begin
    if Value then begin //Acessar o mapeamento para o reposit�rio da m�quina prim�ria
        Path := GlobalConfig.StationRemoteTransPath;
        if not (DirectoryExists(Path)) then begin
            raise Exception.CreateFmt('Falha acessando reposit�rio dos arquivos no computador prim�rio.'#13'"%s', [Path]);
        end;
    end;
    FConnected := Value;
end;

end.
