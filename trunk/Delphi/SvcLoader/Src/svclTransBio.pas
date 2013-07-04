{$IFDEF svclTransBio}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclTransBio;

interface

uses
    SysUtils, Windows, Classes, XPFileEnumerator, XPThreads;

type
    TTransBioThread = class(TXPNamedThread)
    private
        FCycleErrorCount : Integer;
        procedure DoClientCycle;
        procedure DoServerCycle;
        procedure ReplicDataFiles2PrimaryMachine(const Filename : string);
        procedure CreatePrimaryBackup(const DirName : string);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure StoreTransmitted(SrcFile : TFileSystemEntry);
        procedure ForceEloConfiguration();
    public
        procedure Execute(); override;
    end;

implementation

uses
    svclConfig, FileHnd, AppLog, svclUtils, svclTCPTransfer, WinNetHnd, WinReg32, AppSettings, JclSysInfo, svclBiometricFiles;

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
        raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(ERROR_CANNOT_MAKE)]);
    end;
    if ToMove then begin
        if not MoveFile(PWideChar(Source), PWideChar(DestName)) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end else begin
        if not CopyFile(PWideChar(Source), PWideChar(DestName), True) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end;
end;

procedure TTransBioThread.CreatePrimaryBackup(const DirName : string);
 ///Monta arvore de diretorios baseado na data do arquivo no padr�o <root>\year\month\day
 /// Onde <root> � configurado
var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f : TFileSystemEntry;
begin
    FileEnt := TDirectory.FileSystemEntries(DirName, BIOMETRIC_FILE_MASK, False);
    for f in FileEnt do begin
        Self.StoreTransmitted(f);
    end;
end;

procedure TTransBioThread.DoClientCycle;
///Inicia novo ciclo de opera��o
///

procedure LSRSearchDivergents( list : TStringList );
//--------------------------------------------------------
///<summary>
///Varre lista de arquivos ordenada por nome por arquivos com hash divergente. Encontrando
///</summary>
///<remarks>
///
///</remarks>
var
	x : Integer;
	f1, f2 : TTransferFile;
	oldName : string;
begin
	x:=list.Count-1; //pivot no final da lista para comparar aos pares
	while( x >=0 ) do begin
		if ( list.Strings[x] = list.Strings[x-1] ) then begin //comparar os hash
			f1:=TTransferFile( list.Objects[x-1] );
			f2:=TTransferFile( list.Objects[x] );
			if ( f1.Hash <> f2.Hash ) then begin //Renomear e remover os n�o constantes na pasta Bioservice
				if ( not SameText( TFileHnd.ParentDir(f2.Filename ) , GlobalConfig.PathELOBioService )  ) then begin
					f2.SetAsDivergent;
					f2.Free;
					list.Delete( x );
					x:=list.Count; //recome�ar
					System.Continue;
				end;
			end;
		end;
		Dec( x ); //Pula para o par seguinte, se houver
   end;
end;

var
	 FileEnt : IEnumerable<TFileSystemEntry>;
	 f :   TFileSystemEntry;
	 cmp : string;
	 FileList : TStringList;
begin
	 //Coleta a lista de arquivos para a opera��o neste ciclo
	 FileList := TStringList.Create;
	 try
		 FileList.Sorted := True;
		 FileList.Duplicates := dupIgnore;
		 {TODO -oroger -cdebug : Ponto critico de verifica��o de memory leak}
		 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathELOBioService, BIOMETRIC_FILE_MASK, False); //repositorio Bioservice
		 for f in FileEnt do begin
			 FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
		 end;

		 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.Elo2TransBio, BIOMETRIC_FILE_MASK, False);
		 //repositorio TransBio(Bio)
		 for f in FileEnt do begin
			 FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
		 end;

		 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.PathBio, BIOMETRIC_FILE_MASK, False);
		 //repositorio TransBio(Trans)
		 for f in FileEnt do begin
			 FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
		 end;

		 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathELOTransbioReTrans, BIOMETRIC_FILE_MASK, False);
		 //repositorio TransBio(ReTrans)
		 for f in FileEnt do begin
			 FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
		 end;

		 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathELOTransbioError, BIOMETRIC_FILE_MASK, False);
		 //repositorio TransBio(Erro)
		 for f in FileEnt do begin
			 FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
		 end;

		 //Inicia busca por divergentes
        LSRSearchDivergents( FileList );

		 //Processa a lista de arquivos para envio
		 cmp := TFileHnd.FirstOccurrence(GlobalConfig.PathServiceCapture, BIOMETRIC_FILE_MASK);
		 if (cmp = EmptyStr) then begin
			 Exit;
		 end;
		 cmp := WinNetHnd.GetComputerName();
		 DMTCPTransfer.StartClient;
		 try
			 FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathServiceCapture, BIOMETRIC_FILE_MASK, False);
			 DMTCPTransfer.StartSession(cmp);
			 try
				 //Para o caso de esta��o(�nica a coletar dados biom�tricos), o sistema executar� o caso de uso "ReplicDataFiles2PrimaryMachine"
				 for f in FileEnt do begin
					 Self.ReplicDataFiles2PrimaryMachine(f.FullName);
				 end;
			 finally
				 DMTCPTransfer.EndSession(cmp);
			 end;
        finally
            DMTCPTransfer.StopClient;
        end;
	 finally
        FileList.Free;
    end;

end;

procedure TTransBioThread.DoServerCycle;
///Inicia novo ciclo de opera��o do servidor
begin
    //Para o caso do computador prim�rio o servi�o executa o caso de uso "CreatePrimaryBackup"
    Self.CreatePrimaryBackup(GlobalConfig.PathServerBackup);
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
    tf : TTransferFile;
begin
    {TODO -oroger -cdsg : empacotar e enviar para servidor}

    tf := TTransferFile.CreateOutput(Filename);
    try
        DMTCPTransfer.SendFile(tf);
    finally
        tf.Free;
    end;


    //Copia para a pasta local de transmiss�o
    LocalTransName := TFileHnd.ConcatPath([GlobalConfig.PathServiceCapture, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalTransName, 'Transbio Local', ERR_MSG, False);

	 //Copia arquivo para local remoto de transmiss�o
	 //PrimaryTransName := TFileHnd.ConcatPath([GlobalConfig.TransbioConfig.PathBioServiceRepository, ExtractFileName(Filename)]);
    //Self.CopyBioFile(Filename, PrimaryTransName, 'Reposit�rio prim�rio', ERR_MSG, False);

    //Move arquivo para backup local
    LocalBackupName := TFileHnd.ConcatPath([GlobalConfig.PathLocalBackup, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalBackupName, 'Backup Local', ERR_MSG, True);
end;

procedure TTransBioThread.Execute;
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
    begin
        //Registrar o erro e testar o contador de erros
        Inc(Self.FCycleErrorCount);
        ErrorMessage := Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 +
            '�ltimo erro registrado = "%s"', [Self.FCycleErrorCount, EComm.Message]);
        if (Integer(Self.FCycleErrorCount) > 10) then begin
            {TODO -oroger -cdsg : Interrromper servico e notificar agente monitorador}
            TLogFile.Log(ErrorMessage, lmtError);
            Self.FCycleErrorCount := 0; //reseta contador global
        end;
    end;

begin
    inherited;

    try
        //Checar na inicializa��o do servi�o as configura��es locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
        Self.ForceEloConfiguration();
    except
        on EElo : Exception do begin //Registrar o erro e continuar com o processo
            BioFilesService.SendMailNotification('Erro for�ando a configura��o dos aplicativos ELO e/ou Transbio'#13#10 +
                EElo.Message);
        end;
    end;

    //Repetir os ciclos de acordo com a temporiza��o configurada
    //O Thread prim�rio pode enviar notifica��o da cancelamento que deve ser verificada ao inicio de cada ciclo
    Self.FCycleErrorCount := 0;
    while Self.IsAlive do begin
        try
            if (GlobalConfig.isPrimaryComputer) then begin {TODO -oroger -cdsg : remover computador primario por flag servidor/estacao}
                Self.DoServerCycle;
            end else begin
                Self.DoClientCycle;
            end;
            Self.FCycleErrorCount := 0; //Reseta contador de erros do ciclo
        except
            on EComm : Exception do begin
                LSRReportError(EComm);
            end;
        end;
        //Suspende este thread at� a libera��o pelo thread do servi�o
        //SwitchToThread();
        Self.Suspended := True;
    end;
end;

procedure TTransBioThread.ForceEloConfiguration;
///Checar na inicializa��o do servi�o as configura��es locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
/// Requisitos: Vera�o anterior ao Windows Vista
var
    EloReg : TRegistryNT;
begin
    //**** Configura��es do TransBio *****
    //Todas as configura��es do TransBio forcadas desta forma, caso o ini do servi�o esteja ompleto
	 if (Assigned(GlobalConfig.TransbioConfig)) then begin
		 GlobalConfig.TransbioConfig.Import(GlobalConfig, 'TransBio', '', True);
	 end;
	 //Caminhos de configura��o do elo e pasta de transmiss�o do Transbio devem ser iguais, notificar para divergente
	 if (not SameText(GlobalConfig.TransbioConfig.Elo2TransBio, GlobalConfig.TransbioConfig.PathBio)) then begin
		 BioFilesService.SendMailNotification(
			 'Caminhos de destino do arquivos biom�tricos do elo divergente do caminho de leitura do servi�o Transbio nesta esta��o');
	 end;

	 if (not IsDebuggerPresent) then begin
		 if (JclSysInfo.GetWindowsVersion() > wvWinXP) then begin
			 raise Exception.Create('Vers�o do windows n�o suportada(Requer eleva��o)');
		 end;

		 //Configura��es do ELO
		 EloReg := TRegistryNT.Create;
		 try
			 try
				 EloReg.WriteFullString(ELO_TRANSFER_TRANSBIO_PATH, GlobalConfig.TransbioConfig.PathBio, True);
			 finally
				 EloReg.Free;
			 end;
		 except
			 on E : Exception do begin
				 {TODO -oroger -cdsg : Registrar a falha e continuar com a opera��o}
			 end;
		 end;

	 end;
end;

procedure TTransBioThread.StoreTransmitted(SrcFile : TFileSystemEntry);
 ///
 /// Move arquivo da pasta de transmitidos de acordo com a data de cria��o para a pasta raiz de armazenamento
 ///
var
    DestPath, FullDateStr, sy, sm, sd : string;
    dummy, t : TDateTime;
begin
    TFileHnd.FileTimeProperties(SrcFile.FullName, dummy, dummy, t);
    FullDateStr := FormatDateTime('YYYYMMDD', t);
    sy := Copy(FullDateStr, 1, 4);
    sm := Copy(FullDateStr, 5, 2);
    sd := Copy(FullDateStr, 7, 2);
    DestPath := TFileHnd.ConcatPath([GlobalConfig.PathClientBackup, sy, sm, sd]);
    ForceDirectories(DestPath);
    if (not MoveFile(PChar(SrcFile.FullName), PChar(DestPath + '\' + SrcFile.Name))) then begin
        TLogFile.Log('Erro movendo arquivo para o reposit�rio definitivo no computador prim�rio'#13 +
            SysErrorMessage(GetLastError()));
    end;
end;

end.
