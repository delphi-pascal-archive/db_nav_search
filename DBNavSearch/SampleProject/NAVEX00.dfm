object Form1: TForm1
  Left = 141
  Top = 89
  Caption = 'Form1'
  ClientHeight = 325
  ClientWidth = 427
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 8
    Top = 56
    Width = 320
    Height = 120
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavSearch1: TDBNavSearch
    Left = 8
    Top = 179
    Width = 264
    Height = 31
    DataSource = DataSource1
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
  end
  object Table1: TTable
    Active = True
    DatabaseName = 'DBDEMOS'
    TableName = 'CUSTOMER.DB'
    Left = 32
    Top = 8
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 64
    Top = 8
  end
end
