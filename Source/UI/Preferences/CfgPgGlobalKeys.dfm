inherited CPGlobalKeys: TCPGlobalKeys
  Left = 241
  Top = 158
  Caption = 'CPGlobalKeys'
  ClientHeight = 361
  ClientWidth = 416
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object cbMMKeys: TCheckBox
    Left = 8
    Top = 20
    Width = 234
    Height = 17
    Hint = 
      #1047#1072#1076#1077#1081#1089#1090#1074#1086#1074#1072#1090#1100' '#1052#1091#1083#1100#1090#1080#1084#1077#1076#1080#1081#1085#1099#1077' '#1082#1085#1086#1087#1082#1080' '#1074#1072#1096#1077#1081' '#1082#1083#1072#1074#1080#1072#1090#1091#1088#1099' ('#1055#1072#1091#1079#1072','#1057#1090#1086#1087 +
      ' '#1080' '#1090'.'#1076')'
    Caption = 'cbMMKeys'
    Checked = True
    State = cbChecked
    TabOrder = 0
    OnClick = cbMMKeysClick
  end
  object cbEnabled: TCheckBox
    Left = 8
    Top = 4
    Width = 234
    Height = 17
    Hint = 
      #1056#1077#1075#1080#1089#1090#1088#1072#1094#1080#1103' '#1043#1083#1086#1073#1072#1083#1100#1085#1099#1093' '#1050#1083#1072#1074#1080#1096' '#1076#1077#1081#1089#1090#1074#1091#1102#1097#1080#1093' '#1076#1083#1103' '#1087#1083#1077#1077#1088#1072' '#1080#1079' '#1083#1102#1073#1086#1075#1086' '#1087 +
      #1088#1080#1083#1086#1078#1077#1085#1080#1103'.'
    Caption = 'cbEnabled'
    TabOrder = 1
    OnClick = OnClick
  end
  object sgCommands: TStringGrid
    Left = 7
    Top = 54
    Width = 406
    Height = 301
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    DefaultColWidth = 138
    DefaultRowHeight = 20
    RowCount = 13
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goThumbTracking]
    ScrollBars = ssVertical
    TabOrder = 2
    OnDrawCell = sgCommandsDrawCell
  end
  object btnClear: TButton
    Left = 332
    Top = 18
    Width = 75
    Height = 20
    Caption = 'btnClear'
    TabOrder = 3
    OnClick = btnClearClick
  end
  object cbAlternative: TCheckBox
    Left = 24
    Top = 36
    Width = 234
    Height = 17
    Caption = 'cbAlternative'
    TabOrder = 4
  end
end
