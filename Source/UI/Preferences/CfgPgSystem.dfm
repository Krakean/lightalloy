inherited CPSystem: TCPSystem
  Left = 191
  Top = 121
  Caption = 'CPSystem'
  ClientHeight = 313
  ClientWidth = 437
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object cbHighPriority: TCheckBox
    Left = 8
    Top = 4
    Width = 418
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Set high process priority'
    TabOrder = 0
  end
  object cbCPUUsage: TCheckBox
    Left = 8
    Top = 24
    Width = 418
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Show CPU usage'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object cbMultiUser: TCheckBox
    Left = 8
    Top = 84
    Width = 418
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Preferences for non-admin users'
    TabOrder = 4
    OnClick = cbMultiUserClick
  end
  object rbUserPrefs: TRadioGroup
    Left = 8
    Top = 108
    Width = 418
    Height = 54
    Anchors = [akLeft, akTop, akRight]
    Caption = 'User prefs'
    Enabled = False
    ItemIndex = 0
    Items.Strings = (
      'All User'
      'Single user')
    TabOrder = 5
  end
  object pnExeName: TPanel
    Left = 8
    Top = 284
    Width = 421
    Height = 25
    Alignment = taLeftJustify
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 6
    OnClick = pnExeNameClick
  end
  object cbAllowDownloadFilters: TCheckBox
    Left = 8
    Top = 44
    Width = 418
    Height = 17
    Caption = 'Allow automatically download filters'
    TabOrder = 2
  end
  object cbNotifyAboutNewVersion: TCheckBox
    Left = 8
    Top = 64
    Width = 418
    Height = 17
    Caption = 'Check for updates'
    TabOrder = 3
  end
end
