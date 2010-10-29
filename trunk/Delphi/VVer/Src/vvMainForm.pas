{$IFDEF vvMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvMainForm;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Grids, EnhGrids, Buttons, vvConfig, IdBaseComponent, IdComponent,
    FileInfo, ExtCtrls;

type
    TForm1 = class(TForm)
        btnOK :         TBitBtn;
        grdList :       TEnhStringGrid;
        lblMainLabel :  TLabel;
        btnNotifSESOP : TBitBtn;
        pnlLog :        TPanel;
        lblProfLabel :  TLabel;
        lblProfile :    TLabel;
        procedure btnOKClick(Sender : TObject);
        procedure grdListDrawCellGetProperties(Sender : TObject; ACol, ARow : Integer; Rect : TRect; State : TGridDrawState);
        procedure btnNotifSESOPClick(Sender : TObject);
        procedure FormShow(Sender : TObject);
        procedure FormCreate(Sender : TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    WinNetHnd, FileHnd, vvMainDataModule, AppLog;

{$R *.dfm}

const
    COL_DESC  = 0;
    COL_VER   = 1;
    COL_EXPEC = 2;

procedure TForm1.btnNotifSESOPClick(Sender : TObject);
begin
	 Self.btnNotifSESOP.Enabled := False;
	 dtmdMain.SendNotification();
	 if Sender <> nil then begin
		 MessageDlg('Notifica��o enviada com sucesso!!', mtInformation, [mbOK], 0);
	 end;
end;

procedure TForm1.btnOKClick(Sender : TObject);
begin
	 Self.Close;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	if Self.btnNotifSESOP.Enabled and GlobalInfo.EnsureNotification then begin //para o caso da notifica��o ser desejada, mas n�o enviada
   	Self.btnNotifSESOPClick( nil ); //Passa Sender nulo para n�o informar do sucesso do envio
	end;
end;

procedure TForm1.FormCreate(Sender : TObject);
begin
	Application.Title:='VVer - Verificador de sistemas 2010 - T2';
	Self.lblMainLabel.Caption:='SESOP - Verificador de Vers�es de Sistemas 2010 - T2';
	{$IFDEF DEBUG}
	Self.Caption := 'Verificador de Vers�es 2010-T2 *** Depura��o ***  - ' + dtmdMain.fvVersion.FileVersion;
	{$ELSE}
	Self.Caption := 'Verificador de Vers�es 2010-T2 Vers�o: ' + dtmdMain.fvVersion.FileVersion;
	{$ENDIF}
end;

procedure TForm1.FormShow(Sender : TObject);
var
    x : Integer;
    p : TProgItem;
begin
    if not Self.pnlLog.Visible then begin //Visibilidade do painel indica carga de todos os parametros

        Self.pnlLog.Caption := 'Carregando informa��es sobre vers�es em:'#13#10 + VERSION_URL_FILE;
        Self.pnlLog.Refresh;
        Application.ProcessMessages;
        try
            try
				 dtmdMain.InitInfoVersions();
				 Self.lblProfile.Caption:=GlobalInfo.ProfileName;
			 except
				 on E : Exception do begin
					 AppFatalError('Erro carregando informa��es de controle de vers�es'#13#10 + E.Message);
					 Exit;
				 end;
			 end;

			 Self.grdList.RowCount  := GlobalInfo.ProfileInfo.Count + 1;
            Self.grdList.ColCount  := 3;
            Self.grdList.FixedRows := 1;
            Self.grdList.Cells[COL_DESC, 0] := 'Descri��o';
            Self.grdList.Cells[COL_VER, 0] := 'Vers�o Instalada';
            Self.grdList.Cells[COL_EXPEC, 0] := 'Vers�o Esperada';
            for x := 1 to GlobalInfo.ProfileInfo.Count do begin
                p := GlobalInfo.ProfileInfo.Programs[x - 1];
                //Atribui��o da exibi��o
                Self.grdList.Cells[COL_DESC, x] := p.Desc;
                Self.grdList.Cells[COL_VER, x] := p.CurrentVersionDisplay;
                Self.grdList.Cells[COL_EXPEC, x] := p.ExpectedVerEx;
                //Atibui��o dos objetos
                Self.grdList.Objects[COL_DESC, x] := p;
                Self.grdList.Objects[COL_VER, x] := p;
                Self.grdList.Objects[COL_EXPEC, x] := p;
            end;
        finally
            Self.pnlLog.Visible := False;
        end;
    end;
end;


procedure TForm1.grdListDrawCellGetProperties(Sender : TObject; ACol, ARow : Integer; Rect : TRect; State : TGridDrawState);
var
    prg : TProgItem;
begin
    prg := TProgItem(Self.grdList.Objects[ACol, ARow]);
    if Assigned(prg) then begin //pular linhas de cabecalho
        if prg.isUpdated then begin
            if (gdFocused in State) or (Self.grdList.RowCount = ARow) then begin
                Self.grdList.Canvas.DrawFocusRect(Rect);
            end else begin
                Self.grdList.Canvas.Brush.Color := clGreen;
                Self.grdList.Canvas.FillRect(Rect);
            end;
        end else begin
            if (gdFocused in State) or (Self.grdList.RowCount = ARow) then begin
                Self.grdList.Canvas.DrawFocusRect(Rect);
            end else begin
                Self.grdList.Canvas.Brush.Color := clRed;
                Self.grdList.Canvas.FillRect(Rect);
            end;
        end;
    end;
end;

end.
