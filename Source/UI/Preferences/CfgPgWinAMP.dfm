inherited CPWinAMP: TCPWinAMP
  Left = 217
  Top = 185
  Caption = 'CPWinAMP'
  ClientHeight = 243
  ClientWidth = 439
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object lblGplugins: TLabel
    Left = 8
    Top = 32
    Width = 426
    Height = 17
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'General plugins'
    Color = clBtnFace
    ParentColor = False
  end
  object cbEmulWinAMP: TCheckBox
    Left = 8
    Top = 4
    Width = 426
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Emulate WinAMP window'
    TabOrder = 0
  end
  object lbWAPlug: TListBox
    Left = 8
    Top = 52
    Width = 422
    Height = 181
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 1
    OnDblClick = lbWAPlugDblClick
  end
end
