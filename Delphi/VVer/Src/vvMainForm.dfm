object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Verificador de Vers'#245'es 2010 T1'
  ClientHeight = 338
  ClientWidth = 634
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF008888
    8888888888888888888888888888FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    FFFFFFFFFFFFF87778FFFFFFFFFFFFFFFFFFFFFFFFF811987646FFFFFFFFFFFF
    FFFFFFFFFF118937888747FFFFFFFFFFFFFFFFFFF19793988888848FFFFFFFFF
    FFFFFFFF819933378888884FFFFFFFFFFFFFFFFF179999977E767E48FFFFFFFF
    FFFFFFF819393937777777E4FFFFFFFFFFFFFFF7799999976666767CFFFFFFFF
    FFFFFFF77BBBBBB7E666E6E4FFFFFFFFFFFFFFF77BBBBBBB66666664FFFFFFFF
    888888877BBBBBBB76666664FFFFFFFF7888888898BBBBBBB6666666FFFFFFFF
    7878888738BBBBBBB7666648FFFFFFFFF87BBB35838BBBBBBB66667FFFFFFFFF
    F88BBB358938BBBBBB7664FFFFFFFFFFF87BBB3589913888B8B47FFFFFFFFFFF
    F88BBB35793931333178FFFFFFFFFFFFF87BBB357999762222FFFFFFFFFFFFFF
    F88BBB357939736220FFFFFFFFFFFFFFF87BBB3587775726228FFFFFFFFFFFFF
    F87BBB377777836262FFFFFFFFFFFFFFF838889FFFFF872222FFFFFFFFFFFFFF
    F877778FFFFFF3A262FFFFFFFFFFFFFFFFFFFFFFFFFF8288828FFFFFFFFFFFFF
    FFFFFFFFFFFFF77777FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    634
    338)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TBitBtn
    Left = 116
    Top = 273
    Width = 100
    Height = 57
    Anchors = []
    Caption = '&Fechar'
    DoubleBuffered = True
    Kind = bkOK
    Layout = blGlyphTop
    ParentDoubleBuffered = False
    Spacing = 0
    TabOrder = 3
    OnClick = btnOKClick
    ExplicitLeft = 97
  end
  object grdList: TListView
    Left = 8
    Top = 57
    Width = 622
    Height = 205
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    GridLines = True
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    TabOrder = 1
    ViewStyle = vsReport
    OnAdvancedCustomDrawItem = grdListAdvancedCustomDrawItem
    OnClick = grdListDblClick
    OnDblClick = grdListDblClick
    ExplicitWidth = 551
  end
  object btnNotifSESOP: TBitBtn
    Left = 255
    Top = 273
    Width = 100
    Height = 58
    Anchors = []
    Caption = '&Notificar'
    Default = True
    DoubleBuffered = True
    Glyph.Data = {
      C6060000424DC60600000000000036000000280000001C000000140000000100
      18000000000090060000C40E0000C40E00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000089898983
      83838282828E8E8E000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000005959595454545353535151515252
      52C6C6C6CBCBCBD5D5D5E1E1E1ECECECE9E9E9F0F0F0F9F9F9C6C6C600000000
      00000000002323232222222323231D1D1DC9C9C9C2C2C2C7C7C7C6C6C6CCCCCC
      D1D1D1DCDCDCDDDDDDE5E5E5F2F2F2FEFEFEFFFFFFFFFFFFFCFCFCF9F9F9F5F5
      F5F3F3F3F3F3F3F4F4F4EFEFF1CFCFCF4D4D4D000000B2B2B2EFEFEFFFFFFFFF
      FFFFFFFFFFFCFCFCFCFCFCFAFAFAFAFAFAF7F7F7F7F7F7F4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F5F5F5ECECEEF5F5
      F5DDDDDD474747000000B4B4B4EEEEF0F5F5F6F3F3F3F4F4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F5F5F5ECECEDF2F2F2F5F5F5EFEFEF4848480000005B5B
      5BF4F4F4ECECEDF0F0F1F6F6F6F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F5
      F5F5ECECECDCDCDCE2E2E2F5F5F5F4F4F4F4F4F4F4F4F4F4F4F4F4F4F5EDEDEE
      F1F1F2F4F4F4F4F4F4FFFFFF464646000000000000EFEFEFF7F7F7F2F2F2EAEA
      ECF5F5F5F5F5F5F4F4F4F4F4F4F4F4F4F4F4F4E1E1E1C4C4C4C6C6C6C5C5C5C5
      C5C5E4E4E4F3F3F3F4F4F4F5F5F5EFEFF0F3F3F3F4F4F4F4F4F4F4F4F4FFFFFF
      696969000000000000E1E1E1FAFAFAF4F4F4F4F4F4EBEBECF1F1F1F5F5F5F4F4
      F4F5F5F5DFDFDFC6C6C6C6C6C6C6C6C6C6C6C6C6C6C6C6C6C6CBCBCBF2F2F2EF
      EFF0F0F0F1F4F4F4F4F4F4F4F4F4F4F4F4FFFFFFCECECE000000000000D7D7D7
      FDFDFDF4F4F4F4F4F4F4F4F4F1F1F2E9E9EBF7F7F7E3E3E3C5C5C5C6C6C6C6C6
      C6B2B2B2B0B0B0C3C3C3C7C7C7C6C6C6DBDBDBE0E0E1F5F5F5F4F4F4F4F4F4F4
      F4F4F4F4F4FCFCFCD6D6D6000000000000909090FFFFFFF4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4E2E2E4D7D7D8C8C8C8B1B1B1B9B9B9DFDFDFE5E5E5CDCDCDB8B8
      B8B9B9B9C6C6C6C4C4C4D9D9D9F6F6F6F4F4F4F4F4F4F4F4F4FAFAFADFDFDF00
      00000000008A8A8AFFFFFFF4F4F4F4F4F4F4F4F4F4F4F4F3F3F3CACACABEBEBF
      C4C4C4E9E9E9FFFFFFFDFDFDFDFDFDFDFDFDFFFFFFF1F1F1B7B7B7BEBEBEC4C4
      C4D0D0D0F3F3F3F4F4F4F4F4F4F5F5F5E8E8E80000000000008C8C8CF8F8F8F3
      F3F3F4F4F4F4F4F4F5F5F5CFCFCFC7C7C7B7B7B7FFFFFFFDFDFDFDFDFDFDFDFD
      FDFDFDFDFDFDFDFDFDFDFDFDFDFDFDF7F7F7B8B8B8C1C1C1CACACAF4F4F4F4F4
      F4F3F3F3E9E9E98F8F8F0000008F8F8FF0F0F0F3F3F3F4F4F4F4F4F4E6E6E6C4
      C4C4CBCBCBFDFDFDFDFDFDFBFBFBF5F5F5F5F5F5F4F4F4F4F4F4F5F5F5F5F5F5
      F7F7F7F9F9F9FEFEFEF1F1F1BDBDBDC0C0C0F2F2F2F4F4F4F5F5F58F8F8F0000
      00414141F0F0F0F4F4F4F4F4F4F1F1F1C1C1C1CFCFCFFFFFFFF9F9F9F5F5F5F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F5F5F5
      FBFBFBDFDFDFBDBDBDECECECFEFEFE8F8F8F000000000000EFEFEFF7F7F7F5F5
      F5CCCCCCCBCBCBFBFBFBF5F5F5F3F3F3F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F6F6F6CDCDCD
      FFFFFFD1D1D1000000000000EAEAEAFAFAFAE0E0E0D0D0D0F6F6F6F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4
      F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F4F6F6F6FEFEFEDFDFDF000000000000
      E8E8E8FAFAFADCDCDCF5F5F5F4F4F4F4F4F4F4F4F4F3F3F3F3F3F3F3F3F3F5F5
      F5F7F7F7F9F9F9FCFCFCFFFFFFFFFFFFFEFEFEF6F6F6EEEEEEEBEBEBDFDFDFF0
      F0F0E0E0E0E1E1E1DFDFDFAEAEAE000000000000E4E4E4FFFFFFF8F8F8F9F9F9
      FBFBFBFDFDFDFBFBFBF7F7F7F2F2F2F9F9F9F4F4F4EFEFEFEAEAEAE3E3E3AEAE
      AE6363636262626363636363636363636B6B6B00000000000000000000000000
      0000000000000000C3C3C3F3F3F3F0F0F0E5E5E5CECECEA1A1A1A1A1A1A1A1A1
      A3A3A31212120000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000}
    Layout = blGlyphTop
    ModalResult = 6
    ParentDoubleBuffered = False
    Spacing = 0
    TabOrder = 4
    OnClick = btnNotifSESOPClick
    ExplicitLeft = 221
  end
  object pnlLog: TPanel
    Left = 116
    Top = 108
    Width = 321
    Height = 129
    Caption = 'Carregando informa'#231#245'es. aguarde....'
    TabOrder = 2
    Visible = False
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 634
    Height = 51
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 563
    object lblMainLabel: TLabel
      Left = 8
      Top = 10
      Width = 258
      Height = 13
      Caption = 'SESOP - Verificador de Vers'#245'es de Sistemas 2010 - T1'
    end
    object lblProfLabel: TLabel
      Left = 9
      Top = 29
      Width = 34
      Height = 13
      Caption = 'Perfil : '
    end
    object lblProfile: TLabel
      Left = 55
      Top = 29
      Width = 40
      Height = 13
      Caption = '----------'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
  object btnChangeProfile: TBitBtn
    Left = 395
    Top = 272
    Width = 100
    Height = 58
    Anchors = []
    Caption = 'For'#231'ar &Perfil'
    Default = True
    DoubleBuffered = True
    Glyph.Data = {
      66090000424D660900000000000036000000280000001C0000001C0000000100
      18000000000030090000C40E0000C40E00000000000000000000FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7F7F7D2D2D2F0F0
      F0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFF8F8F8BEBEBEB1B1B1AFAFAFDFDFDFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9F9F9BFBFBF
      C7C7C7F6F6F6DBDBDBACACACCCCCCCFCFCFCFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFBFBFBC3C3C3C7C7C7EBEBEBB0B0B0E2E2E2ECECEC
      B4B4B4BABABAF2F2F2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCFCFCC5
      C5C5C6C6C6F8F8F8EFEFEFBABABAE0E0E0FCFCFCF6F6F6C5C5C5AEAEAEE2E2E2
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDC9C9C9C5C5C5F6F6F6EEEEEEDFDFDFE5
      E5E5F1F1F1F6F6F6F9F9F9FBFBFBD8D8D8ACACACCECECEFDFDFDFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFE
      FECCCCCCC3C3C3F6F6F6F6F6F6DBDBDBBFBFBFBDBDBDD1D1D1EFEFEFF8F8F8F7
      F7F7FDFDFDE8E8E8B3B3B3BCBCBCF3F3F3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFEFECFCFCFC2C2C2EFEFEFF5F5F5EEEE
      EECDCDCDB1B1B1A9A9A9C2C2C2EEEEEEF8F8F8F7F7F7F7F7F7FBFBFBF5F5F5C6
      C6C6B1B1B1E4E4E4FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFD2D2D2C0C0C0E9E9E9EFEFEFF0F0F0E2E2E2BDBDBD9E9E9E979797CDCD
      CDF2F2F2F8F8F8F7F7F7F7F7F7F7F7F7F8F8F8EBEBEBCFCFCFA9A9A9D4D4D4FE
      FEFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD5D5D5C3C3C3E7E7E7ECECEC
      EBEBEBE6E6E6CCCCCCA2A2A25C5C5C5C5C5CB8B8B8F9F9F9F9F9F9F7F7F7F7F7
      F7F7F7F7F1F1F1ABABABCDCDCDE7E7E7B4B4B4F6F6F6FFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFD8D8D8C2C2C2E6E6E6ECECECEBEBEBE9E9E9D5D5D5A7A7A75D5D5D
      4D4D4D858585ADADADBEBEBEF2F2F2F8F8F8F7F7F7F7F7F7F6F6F6D1D1D1E0E0
      E0E2E2E2DFDFDFFDFDFDFFFFFFFFFFFFFFFFFFFFFFFFDBDBDBC4C4C4E6E6E6EB
      EBEBEAEAEAE9E9E9DEDEDEB2B2B26262626363639F9F9FB1B1B1BDBDBDB3B3B3
      D7D7D7FAFAFAF7F7F7F7F7F7F7F7F7FDFDFDE3E3E3DCDCDCFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFDDDDDDC5C5C5E7E7E7ECECECEAEAEAEAEAEAE8E8E8C2C2C267
      6767707070C6C6C6FDFDFDF2F2F2B8B8B8BEBEBEEDEDEDF6F6F6F7F7F7F7F7F7
      FAFAFAE3E3E3DDDDDDFEFEFEFFFFFFFFFFFFFFFFFFFFFFFFDFDFDFC8C8C8EDED
      EDEFEFEFECECECEBEBEBEBEBEBDFDFDF7D7D7D7A7A7AB8B8B8B7B7B7CDCDCDD9
      D9D9E9E9E9E6E6E6F2F2F2F2F2F2F5F5F5F9F9F9E5E5E5DDDDDDFEFEFEFFFFFF
      FFFFFFFFFFFFFFFFFFE1E1E1C7C7C7E3E3E3CECECEE2E2E2EDEDEDECECECEFEF
      EFAFAFAF8D8D8DE2E2E2D6D6D6C0C0C08C8C8CB6B6B6EBEBEBEDEDEDEDEDEDEF
      EFEFF4F4F4E5E5E5DDDDDDFDFDFDFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDD4D4D4
      EEEEEEE9E9E9A0A0A0CFCFCFEFEFEFECECECEDEDEDDBDBDBB3B3B3C7C7C7E7E7
      E7A5A5A5B0B0B0EEEEEEE8E8E8E8E8E8EBEBEBEEEEEEE3E3E3DDDDDDFDFDFDFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4F4F4F3F3F3F5F5F5E1E1E1EBEBEB
      EFEFEFEEEEEEECECECF0F0F0E8E8E8B7B7B78C8C8CAEAEAEEEEEEEEBEBEBE7E7
      E7E4E4E4E9E9E9E0E0E0DDDDDDFDFDFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFF7F7F7F1F1F1F9F9F9F4F4F4F1F1F1F0F0F0EEEEEEEDEDED
      EEEEEEEEEEEED2D2D2EAEAEAEBEBEBEAEAEAE6E6E6E2E2E2DDDDDDDDDDDDFCFC
      FCFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB
      FBFBF1F1F1F3F3F3F5F5F5F2F2F2F0F0F0EFEFEFEDEDEDEDEDEDF1F1F1ECECEC
      EAEAEAEAEAEAE8E8E8D9D9D9DCDCDCFCFCFCFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDF4F4F4F2F2F2F5
      F5F5F2F2F2F0F0F0EFEFEFEFEFEFF1F1F1EDEDEDEBEBEBECECECE4E4E4DCDCDC
      FBFBFBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6F6F6F1F1F1F4F4F4F3F3F3F1F1F1E8
      E8E8CCCCCCE4E4E4EDEDEDE7E7E7E0E0E0FAFAFAFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFAFAFAF1F1F1F4F4F4F6F6F6E4E4E4A1A1A1D6D6D6EAEAEAE1
      E1E1F9F9F9FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFD
      FDF3F3F3F2F2F2F4F4F4DFDFDFE9E9E9E4E4E4F9F9F9FFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6F6F6F2F2F2F6F6
      F6E6E6E6F8F8F8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFAFAFAF1F1F1F9F9F9FFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF}
    Layout = blGlyphTop
    ParentDoubleBuffered = False
    Spacing = 0
    TabOrder = 5
    OnClick = btnChangeProfileClick
    ExplicitLeft = 345
  end
end
