object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 453
  ClientWidth = 706
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object edtSourceDir: TJvDirectoryEdit
    Left = 32
    Top = 24
    Width = 409
    Height = 21
    DialogKind = dkWin32
    TabOrder = 0
    Text = 'edtSourceDir'
    OnChange = edtSourceDirChange
  end
  object edtDestDir: TJvDirectoryEdit
    Left = 32
    Top = 64
    Width = 409
    Height = 21
    DialogKind = dkWin32
    TabOrder = 1
    Text = 'edtSourceDir'
  end
  object fllstSource: TFileListBox
    Left = 32
    Top = 99
    Width = 193
    Height = 233
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 2
    OnChange = fllstSourceChange
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 392
    Width = 706
    Height = 61
    Align = alBottom
    TabOrder = 3
    object btnConvert: TBitBtn
      Left = 32
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnConvert'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnConvertClick
    end
  end
  object edtRTF: TJvRichEdit
    Left = 240
    Top = 104
    Width = 425
    Height = 225
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object hkstrms: THKStreams
    Compressed = True
    Encrypted = False
    Left = 480
    Top = 32
  end
  object jvrchdthtml: TJvRichEditToHtml
    Left = 536
    Top = 32
  end
  object rvrndrhtml: TRvRenderHTML
    DisplayName = 'Web Page (HTML)'
    FileExtension = '*.html;*.htm'
    OnDecodeImage = rvrndrhtmlDecodeImage
    ServerMode = False
    UseBreakingSpaces = False
    Left = 568
    Top = 344
  end
end