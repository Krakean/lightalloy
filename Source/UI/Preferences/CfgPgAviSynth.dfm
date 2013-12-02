inherited CPAviSynth: TCPAviSynth
  Left = 197
  Top = 206
  Caption = 'CPAviSynth'
  ClientHeight = 350
  ClientWidth = 305
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object cbUseAviSynth: TCheckBox
    Left = 8
    Top = 4
    Width = 293
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Open files through Avisynth script'
    TabOrder = 0
  end
  object mmScript: TMemo
    Left = 8
    Top = 132
    Width = 293
    Height = 214
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      'LoadPlugin("_2DCleanYUY2_for_25.dll") '
      'AVISource({SOURCE}) '
      'ConvertToYUY2'
      '_2DCleanYUY2(0,9,2,2,0,2,2) ')
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
    WordWrap = False
  end
  object lbScript: TListBox
    Left = 8
    Top = 24
    Width = 293
    Height = 105
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 13
    Items.Strings = (
      'Clean2D.avs'
      'Version.avs')
    Sorted = True
    TabOrder = 1
    OnClick = lbScriptClick
  end
end
