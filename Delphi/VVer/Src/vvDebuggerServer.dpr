program vvDebuggerServer;

uses
  Forms,
  vvInteractiveDbgForm in 'vvInteractiveDbgForm.pas' {Form2},
  vvsConfig in 'vvsConfig.pas',
  vvsServiceThread in 'vvsServiceThread.pas',
  vvsTCPTransfer in 'vvsTCPTransfer.pas' {DMTCPTransfer: TDataModule},
  vvSvcDM in 'vvSvcDM.pas',
  vvConfig in 'vvConfig.pas',
  vvsFileMgmt in 'vvsFileMgmt.pas',
  vvsThreadList in 'vvsThreadList.pas',
  StreamHnd in '..\..\..\..\Pcks\StfLib\Src\StreamHnd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDMTCPTransfer, DMTCPTransfer);
  Application.CreateForm(TVVerService, VVerService);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.