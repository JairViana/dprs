unit pctprepUtils;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    StdCtrls, Registry, ShellApi, ExtCtrls, FileCtrl, NB30,
    WinSvc, Contnrs;

const
    OS_WIN95: AnsiString  = 'WIN95';
    OS_WIN98: AnsiString  = 'WIN98';
    OS_WINME: AnsiString  = 'WINME';
    OS_WINNT: AnsiString  = 'WINNT';
    OS_WIN2K: AnsiString  = 'WIN2K';
    OS_WINXP: AnsiString  = 'WINXP';
    OS_WIN2K3: AnsiString = 'WIN2K3';

type
   TTREPct = class;
    TTREPctZone = class(TObject)
    private
       FPCTs : TObjectList;
       FId : integer;
      public
      constructor Create( AZoneId : integer );
      destructor Destroy; override;
      property Id : integer read FId;
      function Add( PCT : TTREPct ) : integer;
    end;


    TTREPct = class
    private
       FParent : TTREPctZone;
       FPCTId : integer;
       FName : string;
       FIp : string;
       FSubNet : string;
       FId : integer;
    public
      constructor Create(Parent : TTREPctZone; PCTId : integer; const Name, Ip, SubNet: string ); virtual;
      property Id : integer read FId;
    end;

    TTREPCTZoneList = class(TStringList)
    private
       function AddPct( const sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN : AnsiString) : integer;
      public
      procedure LoadFromCSV( const Filename : string );
    end;

function RenameComputer(newname, CompDescription : AnsiString) : Integer;
function GetComputerDomain() : AnsiString;
function SetIpConfig(const NewIpAddr : string; const NewGateWay : string = ''; const NewSubnet : string = '') : Integer;

implementation

uses
	 APIHnd, StrHnd, WinNetHnd, WinReg32, LmCons, LmErr, LmWksta, LmJoin, Variants, OleAuto, ActiveX, UrlMon;

function SetIpConfig(const NewIpAddr : string; const NewGateWay : string = ''; const NewSubnet : string = '') : Integer;
var
    Retvar :   Integer;
	 objBind : IDispatch;
	 objAllAdapters, objNetAdapter, oIpAddress, oGateWay, oWMIService, oSubnetMask : olevariant;
    i, iValue : longword;
    oEnum :    IEnumvariant;
    oCtx :     IBindCtx;
    oMk :      IMoniker;
    sFileObj : WideString;
begin
    Retvar   := 0;
    sFileObj := 'winmgmts:\\.\root\cimv2';

	 // Cria��o dos parametros OLE de entrada
	 oIpAddress    := VarArrayCreate([1, 1], varOleStr);
	 oIpAddress[1] := NewIpAddr;
	 oGateWay      := VarArrayCreate([1, 1], varOleStr);
	 oGateWay[1]   := NewGateway;
	 oSubnetMask   := VarArrayCreate([1, 1], varOleStr);
	 if NewSubnet = '' then    begin
		 oSubnetMask[1] := '255.255.255.0';
	 end else begin
		 oSubnetMask[1] := NewSubnet;
	 end;

	 // Connect to WMI - Emulate API GetObject()
	 OleCheck(CreateBindCtx(0, oCtx));
	 OleCheck(MkParseDisplayNameEx(oCtx, PWideChar(sFileObj), i, oMk));
	 OleCheck(oMk.BindToObject(oCtx, nil, IUnknown, objBind));
	 oWMIService := objBind;

	 //Monta consulta para todos os adaptadores ativos(cabo de rede conectado)
	 objAllAdapters := oWMIService.ExecQuery('Select * from ' +
		 'Win32_NetworkAdapterConfiguration ' +
		 'where IPEnabled=TRUE');
	 oEnum := IUnknown(objAllAdapters._NewEnum) as IEnumVariant;

	 while oEnum.Next(1, objNetAdapter, iValue) = 0 do begin //Varre todos os adaptadores
		 try
			 if (NewIpAddr = EmptyStr ) or SameText(NewIpAddr, 'DHCP') then    begin
				 Retvar := objNetAdapter.EnableDHCP; //desnecess�rio ajustar o gateway neste caso
			 end else begin
				// ajustar IP de forma est�tica
				 Retvar := objNetAdapter.EnableStatic(oIpAddress, oSubnetMask);
				 if (Retvar = 0) and (NewGateway <> '') then    begin // troca de gateway
					 Retvar := objNetAdapter.SetGateways(oGateway);
				 end;
				 {TODO -oroger -clib : Local para colocar quaisquer limpezas de caches e regitro de dns externo, etc}
			 end;
		 except
			 Retvar := -1;
		 end;

		 objNetAdapter := Unassigned; //liberar as instancias
	 end;

	 //liberar as instancias
	 oGateWay := Unassigned;
    oSubnetMask := Unassigned;
    oIpAddress := Unassigned;
    objAllAdapters := Unassigned;
    oWMIService := Unassigned;
    Result := Retvar;
end;

function RenameComputerInWorkGroup(CompName : ansistring) : NET_API_STATUS;
type
    ProtSetComputerNameEx = function(nType : TComputerNameFormat; NewName : PAnsiChar) : boolean stdcall;
var
    FuncSetComputerNameEx : ProtSetComputerNameEx;
    MHandle : longint;
begin
    MHandle := LoadLibrary('kernel32.dll');
    try
        @FuncSetComputerNameEx := GetProcAddress(MHandle, 'SetComputerNameExA');
        if not FuncSetComputerNameEx(ComputerNamePhysicalDnsHostname, PAnsiChar(CompName)) then begin
            Result := GetLastError();
        end else begin
            Result := NERR_Success;
        end;
    finally
        FreeLibrary(MHandle);
    end;
end;

function RenameComputerInDomain(strTargetComputer, CompName, strUserID, strPassword : string) : NET_API_STATUS;
var
    pwcNewComputerName, pwcUserID, pwcPassword,
    pwcTargetComputer : PWideChar;
begin
    pwcNewComputerName := nil;
    pwcUserID   := nil;
    pwcPassword := nil;
    pwcTargetComputer := nil;
    try
        GetMem(pwcNewComputerName, 2 * Length(CompName) + 2);
        GetMem(pwcUserID, 2 * Length(strUserID) + 2);
        GetMem(pwcPassword, 2 * Length(strPassword) + 2);
        GetMem(pwcTargetComputer, 2 * Length(strTargetComputer) + 2);
        StringToWideChar(CompName, pwcNewComputerName, Length(CompName) + 2);
        StringToWideChar(strUserID, pwcUserID, Length(strUserID) + 2);
        StringToWideChar(strPassword, pwcPassword, Length(strPassword) + 2);
        StringToWideChar(strTargetComputer, pwcTargetComputer, Length(strTargetComputer) + 2);
        Result := NetRenameMachineInDomain(pwcTargetComputer, pwcNewComputerName, pwcUserID, pwcPassword, 2);
    finally
        FreeMem(pwcNewComputerName);
        FreeMem(pwcUserID);
        FreeMem(pwcPassword);
        FreeMem(pwcTargetComputer);
    end;
end;

function GetComputerDomain() : AnsiString;
var
    PBuf : PWkstaInfo100;
    Res :  longint;
begin
    {TODO -oroger -clib : Portar para library}
    Result := EmptyAnsiStr;
    Res    := NetRenameMachineInDomain(nil, nil, nil, nil, 0);
    if Res <> NERR_SetupNotJoined then begin //Computador n�o pertence a nenhum dominio
        Res := NetWkstaGetInfo(nil, 100, @PBuf);
        if Res = NERR_Success then begin
            Result := string(PBuf^.wki100_langroup);
        end;
    end;
end;

procedure SetComputerDescription(ACompDescription : string);
const
    WinNTComputerDescriptionKey: string =
        'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters\srvcomment';
var
    Reg : TRegistryNT;
begin
    Reg := TRegistryNT.Create;
    try
        if ACompDescription <> EmptyStr then begin
            if Length(ACompDescription) > 256 then begin //trunca descri��o ao limite m�ximo
                ACompDescription := Copy(ACompDescription, 1, 256);
            end;
            Reg.WriteFullString(WinNTComputerDescriptionKey, ACompDescription, True);
        end else begin
            Reg.DeleteFullValue(WinNTComputerDescriptionKey);
        end;
    finally
        Reg.Free;
    end;
end;

function GetOSVersionStr(blnDetailed : boolean) : AnsiString;
var
    VersionInfo : TOSVersionInfo;
begin
    Result := 'Unknown';
    VersionInfo.dwOSVersionInfoSize := Sizeof(TOSVersionInfo);
    GetVersionEx(VersionInfo);
    case VersionInfo.dwPlatformID of
        VER_PLATFORM_WIN32S : begin
            Result := 'WIN32';
        end;
        VER_PLATFORM_WIN32_WINDOWS : begin
            Result := 'WIN9X';
            if blnDetailed then begin
                if (VersionInfo.dwMinorVersion = 0) then begin
                    Result := OS_WIN95;
                end else
                if (VersionInfo.dwMinorVersion = 10) then begin
                    Result := OS_WIN98;
                end else
                if (VersionInfo.dwMinorVersion = 90) then begin
                    Result := OS_WINME;
                end else begin
                    Result := OS_WIN95;
                end;
            end;
        end;
        VER_PLATFORM_WIN32_NT : begin
            Result := OS_WINNT;
            if blnDetailed then begin
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 2) then begin
                    Result := OS_WIN2K3;
                end else
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 1) then begin
                    Result := OS_WINXP;
                end else
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 0) then begin
                    Result := OS_WIN2K;
                end else begin
                    Result := OS_WINNT;
                end;
            end;
        end;
    end;
end;

procedure SetLocalLogOnTo(NewName : AnsiString);
const
    DEFAULT_LOCAL_LOGON_NAME = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName';
var
    Reg : TRegistryNT;
begin
    if GetOSVersionStr(False) = OS_WINNT then begin
        Reg := TRegistryNT.Create;
        try
            Reg.WriteFullString(DEFAULT_LOCAL_LOGON_NAME, NewName, True);
        finally
            Reg.Free;
        end;
    end else begin
        raise Exception.Create('Ajuste de logon local n�o suportado para esta plataforma');
    end;
end;

procedure CheckValidityofCompterName(const ComputerNametoCheck : AnsiString );
const
    VALIDCHARS = ['a'..'z', 'A'..'Z', '0'..'9', '!', '@', '#', '$', '%', '^', '&', '(', ')', '-', '_', '''', '{', '}', '~'];
    //removed '.'
var
    i : Integer;
    blnAllNumeric : boolean;
begin
    if (GetOSVersionStr(False) = OS_WINNT) and (GetOSVersionStr(True) <> OS_WINNT) then begin
        // Only want to check for numeric names on Windows 2000 or above
        blnAllNumeric := True;
        for i := 1 to length(ComputerNametoCheck) do begin
            if not CharInSet(ComputerNametoCheck[i], ['0'..'9']) then begin
                blnAllNumeric := False;
                Break;
            end;
        end;
        if blnAllNumeric then begin
            raise Exception.CreateFmt('Apenas n�meros n�o permitidos para plataforma %s', [GetOSVersionStr(True)]);
        end;
    end;
    if length(ComputerNametoCheck) > MAX_COMPUTERNAME_LENGTH then begin
        raise Exception.CreateFmt('Nome do computador muito longo: "%s"', [ComputerNametoCheck]);
    end;
    if ComputerNametoCheck[1] = '-' then begin
        raise Exception.CreateFmt('Nome do computador inicia com caracter inv�lido: "%s"', [ComputerNametoCheck]);
    end;
    for i := 1 to length(ComputerNametoCheck) do begin
        if not CharInSet(ComputerNametoCheck[i], VALIDCHARS) then begin
            raise Exception.CreateFmt('Nome do computador possui um ou mais caracteres inv�lidos: "%s" [%s]',
                [ComputerNametoCheck, ComputerNametoCheck[i]]);
        end;
    end;
end;

function RenameComputer(newname, CompDescription : AnsiString ) : Integer;
var
    OSVer, DomainName, LocalComputerName : AnsiString;
begin
    OSVer := GetOSVersionStr(True);
    try
        CheckValidityofCompterName(newname)
    except
        on E : Exception do begin
            {TODO -oroger -cdsg : A��o de registro de erro}
        end;
    end;
    LocalComputerName := WinNetHnd.GetComputerName();
    if SameText(LocalComputerName, newName) then begin
        Result := ERROR_XP_ALREADY_DONE;
        Exit;
    end;
    DomainName := GetComputerDomain();
    if DomainName = EmptyAnsiStr then begin
		 Result := RenameComputerInWorkGroup(newname);     //SetComputerNameEx - W2K and XP only
        if Result = NERR_Success then begin
            //Logon local dirigido para o mesmo nome do computador sempre
            SetLocalLogOnTo(newname);
        end;

    end else begin
        Result := RenameComputerInDomain('', newname, 'LOGIN_ADM', 'PWD_ADM');
        //NetRenameMachineInDomain - W2K and XP only
    end;

    if Result = NERR_Success then begin

        if CompDescription <> EmptyStr then begin
            SetComputerDescription(CompDescription);
        end;

        //Local para rotinas de ajustes do registro de DNS
         (*
         if UnRegisterFromNDS then begin
             if UnRegProgramName <> '' then begin
                 AppendToLogFile('called ' + UnRegProgramName);
                 if not TaskTestOnly then begin
                     RunProcess(UnRegProgramName, '', SW_SHOWNORMAL, True);
                 end;
             end else begin
                 AppendToLogFile('The request to UnRegister was made could not be actioned as WSName could not find ' +
                     UnRegProgramName + ' in the path');
             end;
         end;
         if RebootOnCompletion then begin
             if not WinExit(EWX_REBOOT or EWX_FORCE) then begin
                 APIHnd.TAPIHnd.CheckAPI( GetLastError() );
             end;
         end;
         *)
    end;

end;

function TTREPctZone.Add(PCT: TTREPct): integer;
var
x : integer;
begin
   for x  := 0 to Self.FPCTs.Count - 1 do begin
       if PCT.Id = TTREPct(Self.FPCTs.Items[x] ).Id then begin
           raise Exception.CreateFmt('Redund�ncia para par (zona, pct) = (%d, %d )', [Self.Id, PCT.Id]);
       end;
   end;
   result:=Self.FPCTs.Add( PCT );
end;

constructor TTREPctZone.Create(AZoneId: integer);
begin
   Self.FId:=AZoneId;
   Self.FPCTs:=TObjectList.Create;
   Self.FPCTs.OwnsObjects:=True;
end;

destructor TTREPctZone.Destroy;
begin
   Self.FPCTs.Free;
  inherited;
end;

constructor TTREPct.Create(Parent: TTREPctZone; PCTId: integer; const Name, Ip, SubNet: string);
begin
   Self.FPCTId:=PCTId;
   Self.FName:=Name;
   Self.FIp:=Ip;
   Self.FSubNet:=SubNet;
   Self.FParent.Add( Self );
end;

function TTREPCTZoneList.AddPct(const sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN: AnsiString ): integer;
begin
  {TODO -oroger -cdsg : inserir lista dupla de zonas e pcts por zonas}
end;

procedure TTREPCTZoneList.LoadFromCSV(const Filename: string);
const
   DELIMS : TSysCharSet = [';', #13, #10 ];
var
   parser : TBufferedStringStream;
   fs : TFileStream;
   sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN : AnsiString;
begin
   fs := TFileStream.Create(Filename, fmOpenRead );
   try
       parser := TBufferedStringStream.Create(fs);
       try
           parser.SetWordDelimiters( @DELIMS );
           parser.Reset;
           parser.ReadLine; //ignora 1a linha
           while not parser.EoS do begin
               sZone:=parser.ReadStringWord;
               sCity:=parser.ReadStringWord;
               sPctId:=parser.ReadStringWord;
               sPctName:=parser.ReadStringWord;
               sPctIP:=parser.ReadStringWord;
               sPctWAN:=parser.ReadStringWord;
               parser.ReadLine; //descarta demais informa��es da linha
               Self.AddPct( sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN );
           end;
       finally
         parser.Free;
       end;
   finally
     fs.Free;
   end;
end;

end.
