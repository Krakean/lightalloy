object frAudioProps: TfrAudioProps
  Left = 226
  Top = 150
  BorderStyle = bsDialog
  Caption = 'Audio Properties'
  ClientHeight = 334
  ClientWidth = 508
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object gb1: TGroupBox
    Left = 8
    Top = 8
    Width = 92
    Height = 196
    TabOrder = 0
    object tb1: TTrackBar
      Left = 26
      Top = 36
      Width = 45
      Height = 132
      Max = 100
      Orientation = trVertical
      Frequency = 10
      Position = 50
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = tbChange
    end
    object bt1: TButton
      Left = 10
      Top = 168
      Width = 72
      Height = 20
      Caption = 'Decoder'
      Enabled = False
      TabOrder = 1
      OnClick = bt1Click
    end
    object tbBal1: TTrackBar
      Left = 2
      Top = 12
      Width = 86
      Height = 25
      Max = 100
      Frequency = 25
      Position = 50
      TabOrder = 2
      OnChange = tbBalChange
    end
  end
  object gb2: TGroupBox
    Left = 108
    Top = 8
    Width = 92
    Height = 196
    TabOrder = 1
    object tb2: TTrackBar
      Left = 26
      Top = 36
      Width = 45
      Height = 132
      Max = 100
      Orientation = trVertical
      Frequency = 10
      Position = 50
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = tbChange
    end
    object bt2: TButton
      Left = 10
      Top = 168
      Width = 72
      Height = 20
      Caption = 'Decoder'
      Enabled = False
      TabOrder = 1
      OnClick = bt2Click
    end
    object tbBal2: TTrackBar
      Left = 2
      Top = 12
      Width = 86
      Height = 25
      Max = 100
      Frequency = 25
      Position = 50
      TabOrder = 2
      OnChange = tbBalChange
    end
  end
  object gb3: TGroupBox
    Left = 208
    Top = 8
    Width = 92
    Height = 196
    TabOrder = 2
    object tb3: TTrackBar
      Left = 26
      Top = 36
      Width = 45
      Height = 132
      Max = 100
      Orientation = trVertical
      Frequency = 10
      Position = 50
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = tbChange
    end
    object bt3: TButton
      Left = 10
      Top = 167
      Width = 72
      Height = 20
      Caption = 'Decoder'
      Enabled = False
      TabOrder = 1
      OnClick = bt3Click
    end
    object tbBal3: TTrackBar
      Left = 2
      Top = 12
      Width = 86
      Height = 25
      Max = 100
      Frequency = 25
      Position = 50
      TabOrder = 2
      OnChange = tbBalChange
    end
  end
  object cb1: TCheckBox
    Left = 15
    Top = 3
    Width = 76
    Height = 17
    Caption = 'Channel 1'
    TabOrder = 3
    OnMouseUp = cb1MouseUp
  end
  object cb2: TCheckBox
    Left = 115
    Top = 3
    Width = 76
    Height = 17
    Caption = 'Channel 2'
    TabOrder = 4
    OnMouseUp = cb2MouseUp
  end
  object cb3: TCheckBox
    Left = 215
    Top = 3
    Width = 76
    Height = 17
    Caption = 'Channel 3'
    TabOrder = 5
    OnMouseUp = cb3MouseUp
  end
  object gbEQ: TGroupBox
    Left = 8
    Top = 208
    Width = 393
    Height = 121
    Caption = ' EQ '
    TabOrder = 6
    object lbl1: TLabel
      Left = 102
      Top = 102
      Width = 12
      Height = 13
      Caption = '64'
    end
    object lbl2: TLabel
      Left = 131
      Top = 102
      Width = 18
      Height = 13
      Caption = '128'
    end
    object lbl3: TLabel
      Left = 164
      Top = 102
      Width = 18
      Height = 13
      Caption = '250'
    end
    object lbl4: TLabel
      Left = 198
      Top = 102
      Width = 18
      Height = 13
      Caption = '500'
    end
    object lbl5: TLabel
      Left = 233
      Top = 102
      Width = 12
      Height = 13
      Caption = '1k'
    end
    object lbl6: TLabel
      Left = 267
      Top = 102
      Width = 12
      Height = 13
      Caption = '2k'
    end
    object lbl7: TLabel
      Left = 299
      Top = 102
      Width = 12
      Height = 13
      Caption = '4k'
    end
    object lbl8: TLabel
      Left = 333
      Top = 102
      Width = 12
      Height = 13
      Caption = '8k'
    end
    object lbl0: TLabel
      Left = 68
      Top = 102
      Width = 12
      Height = 13
      Caption = '32'
    end
    object lbl9: TLabel
      Left = 363
      Top = 102
      Width = 18
      Height = 13
      Caption = '16k'
    end
    object lblAmplify: TLabel
      Left = 9
      Top = 102
      Width = 33
      Height = 13
      Caption = 'Amplify'
    end
    object tbEq0: TTrackBar
      Left = 56
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 0
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq1: TTrackBar
      Left = 89
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 1
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq3: TTrackBar
      Left = 155
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 3
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq4: TTrackBar
      Left = 188
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 4
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq2: TTrackBar
      Left = 122
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 2
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq5: TTrackBar
      Left = 221
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 5
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq6: TTrackBar
      Left = 254
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 6
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbeq7: TTrackBar
      Left = 287
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 7
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq8: TTrackBar
      Left = 320
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 8
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbEq9: TTrackBar
      Left = 353
      Top = 12
      Width = 30
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 9
      ThumbLength = 16
      TickMarks = tmBoth
      OnChange = EQTune
    end
    object tbAmplify: TTrackBar
      Left = 6
      Top = 12
      Width = 40
      Height = 92
      Max = 120
      Min = -120
      Orientation = trVertical
      Frequency = 20
      TabOrder = 10
      ThumbLength = 18
      TickMarks = tmBoth
      OnChange = tbAmplifyChange
    end
  end
  object gb4: TGroupBox
    Left = 308
    Top = 8
    Width = 92
    Height = 196
    TabOrder = 7
    object tb4: TTrackBar
      Left = 26
      Top = 36
      Width = 45
      Height = 132
      Max = 100
      Orientation = trVertical
      Frequency = 10
      Position = 50
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = tbChange
    end
    object bt4: TButton
      Left = 10
      Top = 167
      Width = 72
      Height = 20
      Caption = 'Decoder'
      Enabled = False
      TabOrder = 1
      OnClick = bt4Click
    end
    object tbbal4: TTrackBar
      Left = 2
      Top = 12
      Width = 86
      Height = 25
      Max = 100
      Frequency = 25
      Position = 50
      TabOrder = 2
      OnChange = tbBalChange
    end
  end
  object gb5: TGroupBox
    Left = 408
    Top = 8
    Width = 92
    Height = 196
    TabOrder = 8
    object tb5: TTrackBar
      Left = 26
      Top = 36
      Width = 45
      Height = 132
      Max = 100
      Orientation = trVertical
      Frequency = 10
      Position = 50
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = tbChange
    end
    object bt5: TButton
      Left = 10
      Top = 167
      Width = 72
      Height = 20
      Caption = 'Decoder'
      Enabled = False
      TabOrder = 1
      OnClick = bt5Click
    end
    object tbbal5: TTrackBar
      Left = 2
      Top = 12
      Width = 86
      Height = 25
      Max = 100
      Frequency = 25
      Position = 50
      TabOrder = 2
      OnChange = tbBalChange
    end
  end
  object cb4: TCheckBox
    Left = 315
    Top = 3
    Width = 76
    Height = 17
    Caption = 'Channel 4'
    TabOrder = 9
    OnMouseUp = cb4MouseUp
  end
  object cb5: TCheckBox
    Left = 415
    Top = 3
    Width = 76
    Height = 17
    Caption = 'Channel 5'
    TabOrder = 10
    OnMouseUp = cb5MouseUp
  end
  object btEqReset: TButton
    Left = 411
    Top = 312
    Width = 86
    Height = 18
    Caption = '> 0 <'
    TabOrder = 11
    OnClick = btEqResetClick
  end
  object gbNormalization: TGroupBox
    Left = 408
    Top = 214
    Width = 92
    Height = 96
    TabOrder = 13
    object tbDynAmp: TTrackBar
      Left = 27
      Top = 11
      Width = 40
      Height = 83
      Min = -10
      Orientation = trVertical
      Frequency = 5
      TabOrder = 0
      ThumbLength = 18
      TickMarks = tmBoth
      OnChange = tbDynAmpChange
    end
  end
  object cbNormalization: TCheckBox
    Left = 413
    Top = 208
    Width = 84
    Height = 17
    Caption = 'Normalization'
    TabOrder = 12
    OnClick = cbNormalizationClick
  end
end
