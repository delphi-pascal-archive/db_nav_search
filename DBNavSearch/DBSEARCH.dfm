object SearchForm: TSearchForm
  Left = 208
  Top = 270
  ActiveControl = ScrollBox1
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1055#1086#1080#1089#1082' '#1079#1072#1087#1080#1089#1080
  ClientHeight = 291
  ClientWidth = 623
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'Courier New'
  Font.Style = []
  Icon.Data = {
    000001000200202002000000000030010000260000002020100000000000E802
    0000560100002800000020000000400000000100010000000000800000000000
    000000000000000000000000000000000000FFFFFF00FFFFFFF1FFFFFFE0C000
    0040C0000001000000017FFFFC037FFFFC077FFFF80F7FF8001F7820003F7FC0
    003F7883C03F7F8FF03F791FF83F7F19B83F7936BC3F7F378C3F7937B43F7F36
    B47F7918887F7F9FF87F788FF07F7FC3C07F7820047F7FF81C7F780700FF7FFF
    7DFF78017BFF7FFF77FF7FFF6FFF7FFF5FFF00003FFFFFFFFFF1FFFFFFE0C000
    0040C00000010000000100000003000000070000000F0000001F0000003F0000
    003F0000003F0000003F0000003F0000003F0000003F0000003F0000003F0000
    007F0000007F0000007F0000007F0000007F0000007F0000007F000000FF0000
    01FF000003FF000007FF00000FFF00001FFF00003FFF28000000200000004000
    0000010004000000000000020000000000000000000000000000000000000000
    00000000BF0000BF000000BFBF00BF000000BF00BF00BFBF0000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000000000000000000000008880000000000000000000000000000888880088
    8888888888888888888880889988008888888888888888888888888999900000
    00000000000000000008889999900FFFFFFFFFFFFFFFFFFFFF08899999000FFF
    FFFFFFFFFFFFFFFFFF08999990000FFFFFFFFFFFFFFFFFFFF889999900000FFF
    FFFFFFFFF88888888899999000000FFFFC8C8C88899999999999990000000FFF
    FFFFFF89999999999999980000000FFFFC8C8899997777999999880000000FFF
    FFFF899977FFFF779999880000000FFFFC8C89977F7777F77999880000000FFF
    FFFF99978CC87C7F7999880000000FFFFC889977C77C7C777799880000000FFF
    FFFF9977C7777CCC8799880000000FFFFC889977C7777C77C799880000000FFF
    FFFF9977C77C7C77C799800000000FFFFC8899978CCC7CCC8999800000000FFF
    FFFFF9977F7777F77998800000000FFFFC8C899977FFFF779998800000000FFF
    FFFFFF99997777999908800000000FFFFC8C8C89999999999F08800000000FFF
    FFFFFFFFF99999977708800000000FFFFC8C8C8C888F00000008000000000FFF
    FFFFFFFFFFFF0FFFFF00000000000FFFFC8C8C8C8C8F0FFFF000000000000FFF
    FFFFFFFFFFFF0FFF0000000000000FFFFFFFFFFFFFFF0FF00000000000000FFF
    FFFFFFFFFFFF0F0000000000000000000000000000000000000000000000FFFF
    FFF1FFFFFFE0C0000040C00000010000000100000003000000070000000F0000
    001F0000003F0000003F0000003F0000003F0000003F0000003F0000003F0000
    003F0000003F0000007F0000007F0000007F0000007F0000007F0000007F0000
    007F000000FF000001FF000003FF000007FF00000FFF00001FFF00003FFF}
  KeyPreview = True
  OldCreateOrder = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 16
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 623
    Height = 251
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object ScrollBox1: TScrollBox
      Left = 2
      Top = 2
      Width = 619
      Height = 247
      Align = alClient
      TabOrder = 0
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 251
    Width = 623
    Height = 40
    Align = alBottom
    BevelInner = bvLowered
    TabOrder = 1
    object BitBtn1: TBitBtn
      Left = 361
      Top = 5
      Width = 117
      Height = 30
      Caption = #1053#1072#1081#1090#1080
      TabOrder = 0
      TabStop = False
      Kind = bkOK
    end
    object BitBtn2: TBitBtn
      Left = 501
      Top = 5
      Width = 96
      Height = 30
      Caption = #1042#1099#1093#1086#1076
      TabOrder = 1
      TabStop = False
      Kind = bkClose
    end
    object IgnoreCase: TCheckBox
      Left = 9
      Top = 12
      Width = 192
      Height = 17
      TabStop = False
      Caption = #1041#1077#1079' '#1091#1095#1077#1090#1072' '#1088#1077#1075#1080#1089#1090#1088#1072
      Checked = True
      State = cbChecked
      TabOrder = 2
      OnClick = CheckBoxClick
    end
    object AllowPartial: TCheckBox
      Left = 203
      Top = 12
      Width = 149
      Height = 17
      TabStop = False
      Caption = #1063#1072#1089#1090#1080#1095#1085#1099#1081' '#1082#1083#1102#1095
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = CheckBoxClick
    end
  end
end
