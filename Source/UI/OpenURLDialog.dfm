object frOpenURL: TfrOpenURL
  Left = 201
  Top = 195
  Width = 454
  Height = 100
  BorderIcons = [biSystemMenu]
  Caption = 'Open URL...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object cbbURL: TComboBox
    Left = 37
    Top = 12
    Width = 385
    Height = 21
    ItemHeight = 13
    TabOrder = 0
    OnKeyPress = cbbURLKeyPress
  end
  object btnOk: TButton
    Left = 261
    Top = 39
    Width = 75
    Height = 20
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 347
    Top = 39
    Width = 75
    Height = 20
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
end
