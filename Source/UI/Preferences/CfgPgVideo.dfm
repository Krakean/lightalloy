inherited CPVideo: TCPVideo
  Left = 357
  Top = 250
  Caption = 'CPVideo'
  ClientHeight = 345
  ClientWidth = 428
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object lblRenderer: TLabel
    Left = 8
    Top = 4
    Width = 93
    Height = 13
    Caption = 'Use video renderer:'
  end
  object cbForceOverlay: TCheckBox
    Left = 216
    Top = 49
    Width = 210
    Height = 17
    Caption = 'Force overlay usage'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object cbVideoProcessor: TCheckBox
    Left = 216
    Top = 9
    Width = 210
    Height = 17
    Caption = 'Use video processing'
    TabOrder = 0
  end
  object gbSeek: TGroupBox
    Left = 188
    Top = 74
    Width = 232
    Height = 94
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Seek'
    TabOrder = 3
    object lbKeySeek: TLabel
      Left = 8
      Top = 20
      Width = 121
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'By keys, in seconds'
    end
    object lbKeyJump: TLabel
      Left = 12
      Top = 44
      Width = 117
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Jump, in seconds'
    end
    object edKeySeek: TEdit
      Left = 136
      Top = 16
      Width = 57
      Height = 21
      TabOrder = 0
      Text = '10'
    end
    object cbKeyFrameSeek: TCheckBox
      Left = 8
      Top = 68
      Width = 209
      Height = 17
      Caption = 'By key frames'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object edKeyJump: TEdit
      Left = 136
      Top = 40
      Width = 57
      Height = 21
      TabOrder = 1
      Text = '60'
    end
  end
  object gbFullScreen: TGroupBox
    Left = 8
    Top = 74
    Width = 173
    Height = 94
    Caption = 'Full screen'
    TabOrder = 2
    object cbFullScrMode: TCheckBox
      Left = 12
      Top = 40
      Width = 149
      Height = 17
      Caption = 'Switch resolution to:'
      TabOrder = 1
      OnClick = cbFullScrModeClick
    end
    object btScrMode: TButton
      Left = 12
      Top = 62
      Width = 149
      Height = 22
      Caption = '640 x 480, 16 Bits'
      Enabled = False
      TabOrder = 2
      OnClick = btScrModeClick
    end
    object cbStayOnTopInFullScreenMode: TCheckBox
      Left = 12
      Top = 20
      Width = 153
      Height = 17
      Caption = 'Stay on top'
      TabOrder = 0
    end
  end
  object gbSpeedCgange: TGroupBox
    Left = 8
    Top = 176
    Width = 173
    Height = 84
    TabOrder = 4
    object Label1: TLabel
      Left = 8
      Top = 56
      Width = 15
      Height = 13
      Caption = '0,1'
    end
    object Label2: TLabel
      Left = 140
      Top = 56
      Width = 15
      Height = 13
      Caption = '2,0'
    end
    object lbSpeed: TLabel
      Left = 136
      Top = 16
      Width = 25
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'x1,3'
    end
    object lbSpeedChange: TLabel
      Left = 12
      Top = 16
      Width = 121
      Height = 13
      AutoSize = False
      Caption = 'Speed change:'
    end
    object tbSpeed: TTrackBar
      Left = 8
      Top = 32
      Width = 149
      Height = 25
      Max = 20
      Min = 1
      PageSize = 1
      Position = 13
      TabOrder = 0
      ThumbLength = 14
      OnChange = tbSpeedChange
    end
  end
  object gbSSDir: TGroupBox
    Left = 8
    Top = 262
    Width = 412
    Height = 74
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Screenshot folder'
    TabOrder = 5
    DesignSize = (
      412
      74)
    object edScrShDir: TEdit
      Left = 10
      Top = 20
      Width = 362
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = '{MyDocs}'
    end
    object btScrShDir: TButton
      Left = 377
      Top = 20
      Width = 27
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 1
      OnClick = btScrShDirClick
    end
    object rbBMP: TRadioButton
      Left = 8
      Top = 48
      Width = 49
      Height = 17
      Caption = 'BMP'
      Checked = True
      TabOrder = 2
      TabStop = True
    end
    object rbJPG: TRadioButton
      Left = 60
      Top = 48
      Width = 53
      Height = 17
      Caption = 'JPG'
      TabOrder = 3
    end
    object cbCreateRelatedDirectoryName: TCheckBox
      Left = 112
      Top = 48
      Width = 257
      Height = 17
      Caption = 'Create folder with videofile name'
      TabOrder = 4
    end
  end
  object gbAspectRatio: TGroupBox
    Left = 188
    Top = 170
    Width = 232
    Height = 90
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Aspect ratio'
    TabOrder = 6
    object lbAspectRatioCustom: TLabel
      Left = 17
      Top = 67
      Width = 124
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Custom aspect ratio:'
    end
    object edAspectRatio: TEdit
      Left = 146
      Top = 63
      Width = 57
      Height = 21
      TabOrder = 0
      Text = '47 : 20'
    end
    object cbAspectRatioForced: TCheckBox
      Left = 8
      Top = 17
      Width = 209
      Height = 17
      Caption = 'Set forced aspect ratio'
      TabOrder = 1
      OnClick = cbAspectRatioForcedClick
    end
    object cbAspectRatio: TComboBox
      Left = 42
      Top = 36
      Width = 145
      Height = 21
      Style = csDropDownList
      Enabled = False
      ItemHeight = 13
      TabOrder = 2
      Items.Strings = (
        #1050#1072#1082' '#1077#1089#1090#1100
        '16:9'
        '4:3'
        #1055#1086' '#1064#1080#1088#1080#1085#1077
        #1055#1086' '#1042#1099#1089#1086#1090#1077
        #1054#1089#1086#1073#1099#1077' '#1087#1088#1086#1087#1086#1088#1094#1080#1080
        #1041#1077#1079' '#1089#1086#1093#1088#1072#1085#1077#1085#1080#1103' '#1087#1088#1086#1087#1086#1088#1094#1080#1081)
    end
  end
  object cbOnTopWhilePlay: TCheckBox
    Left = 8
    Top = 49
    Width = 201
    Height = 17
    Caption = 'On Top while Playing'
    TabOrder = 7
  end
  object cbbVideoRenderer: TComboBox
    Left = 8
    Top = 22
    Width = 173
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 8
  end
  object cbHardwareVideoProcessing: TCheckBox
    Left = 216
    Top = 29
    Width = 210
    Height = 17
    Caption = 'Allow hardware processing'
    TabOrder = 9
  end
  object pmScrModes: TPopupMenu
    Left = 400
    Top = 65532
    object Resolutin1: TMenuItem
      Caption = 'Resolution'
    end
  end
end
