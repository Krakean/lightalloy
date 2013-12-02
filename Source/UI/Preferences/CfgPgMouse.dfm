inherited CPMouse: TCPMouse
  Left = 287
  Top = 174
  Caption = 'CPMouse'
  ClientHeight = 346
  ClientWidth = 433
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object lbHideMouse: TLabel
    Left = 24
    Top = 263
    Width = 121
    Height = 13
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Hide mouse after'
  end
  object lbMouseInactivity: TLabel
    Left = 196
    Top = 262
    Width = 129
    Height = 13
    AutoSize = False
    Caption = 'second(s) of inactivity'
  end
  object cbMouseWheelInvert: TCheckBox
    Left = 28
    Top = 298
    Width = 400
    Height = 17
    Caption = 'Reverse wheel direction'
    TabOrder = 3
  end
  object edMouseTimeout: TEdit
    Left = 148
    Top = 261
    Width = 29
    Height = 21
    ReadOnly = True
    TabOrder = 0
    Text = '0'
  end
  object udMouseTimeout: TUpDown
    Left = 177
    Top = 261
    Width = 16
    Height = 21
    Associate = edMouseTimeout
    Max = 30
    TabOrder = 1
  end
  object cbHoverCPanel: TCheckBox
    Left = 28
    Top = 282
    Width = 400
    Height = 17
    Hint = 
      #1055#1086#1082#1072#1079' '#1087#1072#1085#1077#1083#1080' '#1091#1087#1088#1072#1074#1083#1077#1085#1080#1103' '#1074' '#1055#1086#1083#1085#1086#1101#1082#1088#1072#1085#1085#1086#1084' '#1088#1077#1078#1080#1084#1077' '#1087#1088#1080' '#1085#1072#1074#1077#1076#1077#1085#1080#1080' '#1082#1091#1088 +
      #1089#1086#1088#1072'.'#13#10#1041#1077#1079' '#1080#1079#1084#1077#1085#1077#1085#1080#1103' '#1088#1072#1079#1084#1077#1088#1086#1074' '#1074#1080#1076#1077#1086'.'
    Caption = 'Show control panel on mouse hover'
    TabOrder = 2
  end
  object gbMouseLeft: TGroupBox
    Left = 24
    Top = 4
    Width = 233
    Height = 41
    Caption = 'Left button'
    TabOrder = 4
    object cbMouseLeft: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Pause'
        'Move window'
        'Mute sound'
        'Pause / Drag window'
        'Pause / Pause - Drag window')
    end
  end
  object gbMouseRight: TGroupBox
    Left = 24
    Top = 44
    Width = 233
    Height = 41
    Caption = 'Right button'
    TabOrder = 5
    object cbMouseRight: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Show/Hide control panel'
        'Popup menu'
        'Show/Hide playlist')
    end
  end
  object gbMouseMiddle: TGroupBox
    Left = 24
    Top = 84
    Width = 233
    Height = 41
    Caption = 'Middle button'
    TabOrder = 6
    object cbMouseMiddle: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Window / Full Screen'
        'Minimize'
        'Pause'
        'Switch wheel function')
    end
  end
  object gbMouseLeftDbl: TGroupBox
    Left = 24
    Top = 124
    Width = 233
    Height = 41
    Caption = 'Left button, double'
    TabOrder = 7
    object cbMouseLeftDbl: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Pause'
        'Full screen'
        'Do nothing')
    end
  end
  object gbAdditionalKeys: TGroupBox
    Left = 24
    Top = 164
    Width = 233
    Height = 41
    Caption = 'Additional keys'
    TabOrder = 8
    object cbAdditionalkeys: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Volume'
        'Next / Previous track'
        'Seek'
        'Jump')
    end
  end
  object gbMouseWheel: TGroupBox
    Left = 24
    Top = 204
    Width = 233
    Height = 41
    Caption = 'Wheel'
    TabOrder = 9
    object cbMouseWheel: TComboBox
      Left = 8
      Top = 13
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Sound volume'
        'Seek'
        'Brightness'
        'Contrast'
        'Saturation'
        'Video size'
        'Speed play')
    end
  end
end
