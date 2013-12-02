inherited CPEvents: TCPEvents
  Left = 324
  Top = 166
  Caption = 'CPEvents'
  ClientHeight = 344
  ClientWidth = 393
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object gbOnStart: TGroupBox
    Left = 8
    Top = 4
    Width = 377
    Height = 53
    Anchors = [akLeft, akTop, akRight]
    Caption = 'On player start'
    TabOrder = 0
    object cbOnStartResize: TCheckBox
      Left = 8
      Top = 16
      Width = 364
      Height = 17
      Hint = 
        #1057#1073#1088#1086#1089#1080#1090#1100' '#1088#1072#1079#1084#1077#1088#1099', '#1087#1077#1088#1077#1084#1077#1089#1090#1080#1090#1100' '#1086#1082#1085#1086' '#1074' '#1094#1077#1085#1090#1088', '#1086#1090#1086#1073#1088#1072#1079#1080#1090#1100' '#1087#1072#1085#1077#1083#1100' '#1091#1087 +
        #1088#1072#1074#1083#1077#1085#1080#1103' '
      Caption = 'Set default size'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      State = cbChecked
      TabOrder = 0
    end
    object cbAlwaysPrMonitor: TCheckBox
      Left = 8
      Top = 32
      Width = 364
      Height = 17
      Caption = 'Always start on primary display'
      TabOrder = 1
    end
  end
  object gbOnOpen: TGroupBox
    Left = 8
    Top = 59
    Width = 377
    Height = 149
    Anchors = [akLeft, akTop, akRight]
    Caption = 'On file load'
    TabOrder = 1
    object cbEvOpenHidePanels: TCheckBox
      Left = 8
      Top = 64
      Width = 364
      Height = 17
      Caption = 'Hide control panel'
      TabOrder = 3
    end
    object cbEvOpenFullScreen: TCheckBox
      Left = 8
      Top = 48
      Width = 364
      Height = 17
      Caption = 'Switch to fullscreen'
      TabOrder = 2
    end
    object cbEvOpenResize: TCheckBox
      Left = 8
      Top = 16
      Width = 364
      Height = 17
      Caption = 'Resize to movie bounds'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object cbEvOpenCenter: TCheckBox
      Left = 8
      Top = 32
      Width = 364
      Height = 17
      Caption = 'Move window to screen center'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object cbSeekLast: TCheckBox
      Left = 8
      Top = 80
      Width = 364
      Height = 17
      Hint = #1055#1077#1088#1077#1084#1072#1090#1099#1074#1072#1077#1090' '#1085#1072' '#1090#1086' '#1084#1077#1089#1090#1086' '#1075#1076#1077' '#1073#1099#1083' '#1086#1089#1090#1072#1085#1086#1074#1083#1077#1085' '#1092#1072#1081#1083' '#1074' '#1087#1086#1089#1083#1077#1076#1085#1080#1081' '#1088#1072#1079
      Caption = 'Seek to last playing position'
      TabOrder = 4
    end
    object cbApplySettings: TCheckBox
      Left = 8
      Top = 96
      Width = 364
      Height = 17
      Hint = 
        #1042#1086#1089#1089#1090#1072#1085#1086#1074#1083#1077#1085#1080#1077' '#1074#1099#1089#1090#1072#1074#1083#1077#1085#1085#1099#1093' '#1074#1072#1084#1080' '#1085#1072#1089#1090#1088#1086#1077#1082' '#1055#1088#1086#1087#1086#1088#1094#1080#1081' - '#1071#1088#1082#1086#1089#1090#1080' - ' +
        #1050#1086#1085#1090#1088#1072#1089#1090#1085#1086#1089#1090#1080' - '#1053#1072#1089#1099#1097#1077#1085#1085#1086#1089#1090#1080
      Caption = 'Apply saved settings'
      Checked = True
      State = cbChecked
      TabOrder = 5
    end
    object cbOnAutoSeek: TCheckBox
      Left = 8
      Top = 112
      Width = 364
      Height = 17
      Hint = 
        #1054#1090#1084#1077#1095#1072#1077#1084' '#1074#1088#1077#1084#1103' '#1082#1086#1085#1094#1072' '#1086#1087#1077#1085#1080#1085#1075#1072' '#1080#1083#1080' '#1085#1072#1095#1072#1083#1072' '#1101#1085#1076#1080#1085#1075#1072', '#1087#1086' '#1091#1084#1086#1083#1095#1072#1085#1080#1102' '#1082 +
        #1085#1086#1087#1082#1072' "O"; '#1056#1072#1073#1086#1090#1072#1077#1090' '#1090#1086#1083#1100#1082#1086' '#1076#1083#1103' '#1074#1080#1076#1077#1086', '#1087#1088#1080#1084#1077#1088#1085#1086' '#1086#1076#1085#1086#1081' '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083 +
        #1100#1085#1086#1089#1090#1080
      Caption = 'Automatically seek Opening/Ending'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
    end
    object cbSearchForSimilarFiles: TCheckBox
      Left = 8
      Top = 128
      Width = 364
      Height = 17
      Hint = #1044#1086#1073#1072#1074#1083#1103#1077#1090' '#1089#1093#1086#1078#1080#1077' '#1087#1086' '#1085#1072#1079#1074#1072#1085#1080#1102' '#1092#1072#1081#1083#1099' '#1074' '#1089#1087#1080#1089#1086#1082'. '#1059#1076#1086#1073#1085#1086' '#1076#1083#1103' '#1089#1077#1088#1080#1072#1083#1086#1074
      Caption = 'Add to the list with the same name'
      TabOrder = 7
    end
  end
  object rgOnPLEnd: TRadioGroup
    Left = 8
    Top = 211
    Width = 377
    Height = 67
    Anchors = [akLeft, akTop, akRight]
    Caption = 'On playlist end'
    ItemIndex = 0
    Items.Strings = (
      'Do nothing'
      'Close player'
      'Power off')
    TabOrder = 2
  end
  object cbOnMinimizePause: TCheckBox
    Left = 16
    Top = 297
    Width = 364
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Pause video when minimized'
    TabOrder = 4
    OnClick = cbOnMinimizePauseClick
  end
  object cbOnDoneRewind: TCheckBox
    Left = 16
    Top = 281
    Width = 364
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Rewind on playback finish'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object cbRestorePlayback: TCheckBox
    Left = 30
    Top = 314
    Width = 350
    Height = 17
    Caption = 'Resume playback'
    Enabled = False
    TabOrder = 5
  end
end
