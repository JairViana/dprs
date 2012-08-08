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
    FileInfo, ExtCtrls, ComCtrls;

type
    TForm1 = class(TForm)
        btnOK :         TBitBtn;
        grdList :       TListView;
        btnNotifSESOP : TBitBtn;
        pnlLog :        TPanel;
        pnlTop :        TPanel;
        lblMainLabel :  TLabel;
        lblProfLabel :  TLabel;
        lblProfile :    TLabel;
        procedure btnOKClick(Sender : TObject);
        procedure btnNotifSESOPClick(Sender : TObject);
        procedure FormShow(Sender : TObject);
        procedure FormCreate(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
        procedure grdListDblClick(Sender : TObject);
        procedure grdListAdvancedCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState;
            Stage : TCustomDrawStage; var DefaultDraw : boolean);
		 procedure grdListCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState; var DefaultDraw : boolean);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    WinNetHnd, FileHnd, vvMainDataModule, AppLog, ShellAPI, CommCtrl;

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

procedure TForm1.FormCloseQuery(Sender : TObject; var CanClose : boolean);
begin
    if Self.btnNotifSESOP.Enabled and GlobalInfo.EnsureNotification then begin
        //para o caso da notifica��o ser desejada, mas n�o enviada
        Self.btnNotifSESOPClick(nil); //Passa Sender nulo para n�o informar do sucesso do envio
    end;
end;

procedure TForm1.FormCreate(Sender : TObject);
begin
    Application.Title := 'VVer - Verificador de sistemas 2012 - T1';
    Self.lblMainLabel.Caption := 'SESOP - Verificador de Vers�es de Sistemas 2012 - T1';
    {$IFDEF DEBUG}
    Self.Caption      := 'Verificador de Vers�es 2012-T1 *** Depura��o ***  - ' + dtmdMain.fvVersion.FileVersion;
    {$ELSE}
    Self.Caption      := 'Verificador de Vers�es 2012-T1 Vers�o: ' + dtmdMain.fvVersion.FileVersion;
    {$ENDIF}
end;

procedure TForm1.FormShow(Sender : TObject);
var
    x :      Integer;
    p :      TProgItem;
    lstCol : TListColumn;
    lstItem : TListItem;
begin
    if not Self.pnlLog.Visible then begin //Visibilidade do painel indica carga de todos os parametros

        Self.pnlLog.Caption := 'Carregando informa��es sobre vers�es em:'#13#10 + VERSION_URL_FILE;
        Self.pnlLog.Refresh;
        Application.ProcessMessages;
        try
            try
                dtmdMain.InitInfoVersions();
                Self.lblProfile.Caption := GlobalInfo.ProfileName;
            except
                on E : Exception do begin
                    AppFatalError('Erro carregando informa��es de controle de vers�es'#13#10 + E.Message);
                    Exit;
                end;
            end;

            //;;Self.grdList.RowCount  := GlobalInfo.ProfileInfo.Count + 1;
            //;;Self.grdList.ColCount  := 3;
            //;Self.grdList.FixedRows := 1;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Descri��o';
            lstCol.Width := ColumnHeaderWidth;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Vers�o Instalada';
            lstCol.Width := ColumnHeaderWidth;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Vers�o Esperada';
            lstCol.Width := ColumnHeaderWidth;

            for x := 1 to GlobalInfo.ProfileInfo.Count do begin
                p := GlobalInfo.ProfileInfo.Programs[x - 1];
                //Atribui��o da exibi��o
                lstItem := Self.grdList.Items.Add;
                lstItem.Caption := p.Desc;
                lstItem.SubItems.Add(p.CurrentVersionDisplay);
                lstItem.SubItems.Add(p.ExpectedVerEx);
                lstItem.Data := p;
            end;
        finally
            Self.pnlLog.Visible := False;
        end;
    end;
end;


procedure TForm1.grdListAdvancedCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState;
    Stage : TCustomDrawStage; var DefaultDraw : boolean);
var
    prg : TProgItem;
begin
    prg := TProgItem(Item.Data);
    if Assigned(prg) then begin //pular linhas de cabecalho
        if prg.isUpdated then begin
            if (item.Focused) { or (Self.grdList.RowCount = ARow) } then begin
                //Self.grdList.Canvas.DrawFocusRect(Rect);
                Self.grdList.Canvas.Brush.Color := clBlue;
                DefaultDraw := True;
            end else begin
                Self.grdList.Canvas.Brush.Color := clGreen;
                //Self.grdList.Canvas.FillRect(Rect);
            end;
        end else begin
            if (Item.Focused) {or (Self.grdList.RowCount = ARow) } then begin
                //Self.grdList.Canvas.DrawFocusRect(Rect);
                Self.grdList.Canvas.Brush.Color := clBlue;
                DefaultDraw := True;
            end else begin
                Self.grdList.Canvas.Brush.Color := clRed;
                //Self.grdList.Canvas.FillRect(Rect);
            end;
        end;
    end;
end;

{
procedure TForm1.grdListAdvancedCustomDrawSubItem(Sender : TCustomListView; Item : TListItem; SubItem : Integer;
	 State : TCustomDrawState; Stage : TCustomDrawStage; var DefaultDraw : boolean);
var
	 rt : TRect;
begin
	 if (Item.Focused) then begin
		 Self.grdList.Canvas.Brush.Color := clBlue;
		 ListView_GetSubItemRect(Sender.Handle, Item.Index, SubItem, 0, @rt);
		 Self.grdList.Canvas.FillRect(rt);
	 end else begin
		 DefaultDraw := True;
	 end;
end;
}

procedure TForm1.grdListCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState;
	 var DefaultDraw : boolean);
var
	r : TRect;
begin
	 if ( ( Item.Selected ) or (cdsFocused in state) or (cdsSelected in state) ) and not( cdsHot in State )then begin
		 //Self.grdList.Canvas.Brush.Color := clActiveCaption;
		 //Self.grdList.Canvas.Font.Color  := clBlack;

		 //**r:=Item.DisplayRect( drSelectBounds );
		 //**Self.grdList.Canvas.FillRect( r );
		 //Self.grdList.Canvas.Pen.Width:=2;
		 //Self.grdList.Canvas.Rectangle( r );
		 //**DefaultDraw := True;
//	 end else begin
//		 Self.grdList.Canvas.Brush.Color := Color;
//		 Self.grdList.Canvas.Font.Color  := Font.Color;
	 end;
	 //Self.grdList.Canvas.TextOut(Item.Left, Item.Top, Item.Caption);

end;

procedure TForm1.grdListDblClick(Sender : TObject);
var
    prg : TProgItem;
begin
    { TODO -oroger -cdsg : Dispara navegador com a url carregada para download }
    if (Assigned(Self.grdList.Selected)) then begin
        prg := TProgItem(Self.grdList.Selected.Data);
        if Assigned(prg) then begin //pular linhas de cabecalho
            if ((not prg.isUpdated) and (prg.DownloadURL <> EmptyStr)) then begin
                ShellAPI.ShellExecute(self.WindowHandle, 'open', PChar(prg.DownloadURL), nil, nil, SW_SHOWNORMAL);
            end;
        end;
    end;
end;


end.
