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
        procedure ReplicDataFiles2PrimaryMachine(const Filename : string);
        procedure CreatePrimaryBackup(const Filename : string);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure SetConnected(const Value : boolean);
    public
        procedure Execute(); override;
        property Connected : boolean read FConnected write SetConnected;
    end;

implementation

uses
	 XPFileEnumerator, svclConfig, FileHnd, AppLog;

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
        if not MoveFile(PWideChar(Source), PWideChar(DestName)) then begin
            raise Exception.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end else begin
        if not CopyFile(PWideChar(Source), PWideChar(DestName), True) then begin
            raise Exception.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end;
end;

procedure TTransBioThread.CreatePrimaryBackup(const Filename : string);
begin

end;

procedure TTransBioThread.DoCycle;
///Inicia novo ciclo de opera��o
var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f : TFileSystemEntry;
begin
    //FileEnt := TDirectory.FileSystemEntries(GlobalConfig.StationSourcePath, BIOMETRIC_FILE_MASK, False);
    FileEnt := TDirectory.FileSystemEntries(GlobalConfig.StationSourcePath, BIOMETRIC_FILE_MASK, False);
    if GlobalConfig.isPrimaryComputer then begin
        //Para o caso do computador prim�rio o servi�o executa o caso de uso "CreatePrimaryBackup"
        Self.CreatePrimaryBackup(GlobalConfig.StationSourcePath);
    end else begin
        //Para o caso de esta��o(�nica a coletar dados biom�tricos), o sistema executar� o caso de uso "ReplicDataFiles2PrimaryMachine"
        for f in FileEnt do begin
            Self.ReplicDataFiles2PrimaryMachine(f.FullName);
        end;
    end;
end;

procedure TTransBioThread.ReplicDataFiles2PrimaryMachine(const Filename : string);
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
    //Copia para a pasta local de transmiss�o
    LocalTransName := TFileHnd.ConcatPath([GlobalConfig.StationLocalTransPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalTransName, 'Transbio Local', ERR_MSG, False);

    //Copia arquivo para local remoto de transmiss�o
    PrimaryTransName := TFileHnd.ConcatPath([GlobalConfig.StationRemoteTransPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, PrimaryTransName, 'Reposit�rio prim�rio', ERR_MSG, False);

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
                    end;
                end;
            end;
            //Suspende este thread at� a libera��o pelo thread do servi�o
              {$IFDEF DEBUG}
            //SwitchToThread();
            Self.Suspended := True;
             {$ELSE}
            Self.Suspended := True;
            {$ENDIF}
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
        Path := GlobalConfig.PrimaryTransmittedPath;
        if not (DirectoryExists(Path)) then begin
            raise Exception.CreateFmt('Falha acessando reposit�rio dos arquivos no computador prim�rio.'#13'"%s', [Path]);
        end;
    end;
    FConnected := Value;
end;

end.
