object Form5: TForm5
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Demo Integra'#231#227'o Dominio'
  ClientHeight = 604
  ClientWidth = 858
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel
    Left = 25
    Top = 38
    Width = 52
    Height = 13
    Alignment = taRightJustify
    Caption = 'Username:'
  end
  object Label7: TLabel
    Left = 16
    Top = 65
    Width = 61
    Height = 13
    Alignment = taRightJustify
    Caption = 'Client Secret'
  end
  object Label8: TLabel
    Left = 28
    Top = 89
    Width = 49
    Height = 13
    Alignment = taRightJustify
    Caption = 'Ambiente:'
  end
  object Label9: TLabel
    Left = 44
    Top = 119
    Width = 33
    Height = 13
    Alignment = taRightJustify
    Caption = 'Token:'
  end
  object Button1: TButton
    Left = 643
    Top = 8
    Width = 95
    Height = 36
    Cursor = crHandPoint
    Caption = 'GetToken'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 877
    Top = 8
    Width = 106
    Height = 36
    Cursor = crHandPoint
    Caption = 'Login'
    TabOrder = 1
    OnClick = Button2Click
  end
  object edToken: TEdit
    Left = 83
    Top = 116
    Width = 767
    Height = 21
    TabOrder = 2
  end
  object Button3: TButton
    Left = 643
    Top = 50
    Width = 207
    Height = 27
    Cursor = crHandPoint
    Caption = 'UploadFile'
    TabOrder = 3
    OnClick = Button3Click
  end
  object edUsername: TEdit
    Left = 83
    Top = 35
    Width = 414
    Height = 21
    TabOrder = 4
  end
  object edPassword: TEdit
    Left = 83
    Top = 62
    Width = 414
    Height = 21
    TabOrder = 5
  end
  object cbAmbiente: TComboBox
    Left = 83
    Top = 89
    Width = 414
    Height = 21
    Cursor = crHandPoint
    Style = csDropDownList
    ItemIndex = 1
    TabOrder = 6
    Text = 'Homologa'#231#227'o'
    Items.Strings = (
      'Produ'#231#227'o'
      'Homologa'#231#227'o')
  end
  object Button4: TButton
    Left = 643
    Top = 83
    Width = 207
    Height = 27
    Cursor = crHandPoint
    Caption = 'StatusFile'
    TabOrder = 7
    OnClick = Button4Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 143
    Width = 858
    Height = 461
    Align = alBottom
    Lines.Strings = (
      'Memo1')
    TabOrder = 8
  end
  object Button5: TButton
    Left = 744
    Top = 8
    Width = 106
    Height = 36
    Cursor = crHandPoint
    Caption = 'Get IntegrationKey'
    TabOrder = 9
    OnClick = Button5Click
  end
  object DTDominio1: TDTDominio
    GravarLog = False
    Ambiente = aProducao
    Left = 552
    Top = 32
  end
  object OpenDialog1: TOpenDialog
    Left = 416
    Top = 304
  end
end
