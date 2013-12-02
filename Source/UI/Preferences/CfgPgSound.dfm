inherited CPSound: TCPSound
  Caption = 'CPSound'
  ClientHeight = 342
  ClientWidth = 434
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object gbVolumeControl: TGroupBox
    Left = 8
    Top = 4
    Width = 418
    Height = 57
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Volume control'
    TabOrder = 0
    object cbVolumeWave: TCheckBox
      Left = 8
      Top = 16
      Width = 364
      Height = 17
      Caption = 'Adjust all digital devices volume'
      TabOrder = 0
    end
    object cbVolumeMaster: TCheckBox
      Left = 8
      Top = 32
      Width = 364
      Height = 17
      Caption = 'Adjust a whole system volume'
      TabOrder = 1
    end
  end
  object cbAddSound: TCheckBox
    Left = 8
    Top = 288
    Width = 364
    Height = 17
    Hint = #1058#1080#1087#1099' '#1092#1072#1081#1083#1086#1074' - WAV - MP3 - OGG - WMA - AC3 - AAC - MKA'
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Load sound with the same name'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object cbForce44: TCheckBox
    Left = 8
    Top = 304
    Width = 364
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Force sound output to 44 KHz'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object gbSoundOut: TGroupBox
    Left = 8
    Top = 65
    Width = 418
    Height = 45
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Default sound device and track'
    TabOrder = 1
    DesignSize = (
      418
      45)
    object cbSoundDevice: TComboBox
      Left = 8
      Top = 16
      Width = 361
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 13
      TabOrder = 0
    end
    object cbDefAudioStream: TComboBox
      Left = 376
      Top = 16
      Width = 32
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 13
      TabOrder = 1
      Items.Strings = (
        '1'
        '2'
        '3'
        '4'
        '5')
    end
  end
  object cbEqualizer: TCheckBox
    Left = 8
    Top = 320
    Width = 364
    Height = 17
    Caption = 'Use audio processing'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
end
