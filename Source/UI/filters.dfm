object frFilters: TfrFilters
  Left = 211
  Top = 122
  Width = 673
  Height = 403
  Caption = 'Filter Graph'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyUp = FormKeyUp
  DesignSize = (
    665
    372)
  PixelsPerInch = 96
  TextHeight = 13
  object cbStopBeforeProps: TCheckBox
    Left = 4
    Top = 346
    Width = 209
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'StopBeforeChange'
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 0
  end
  object btFilterProps: TButton
    Left = 4
    Top = 313
    Width = 209
    Height = 28
    Anchors = [akLeft, akBottom]
    Caption = 'PropertiesDialog'
    TabOrder = 1
    OnClick = btFilterPropsClick
  end
  object pnFltBox: TPanel
    Left = 216
    Top = 4
    Width = 445
    Height = 361
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvLowered
    Caption = 'Graph'
    TabOrder = 2
  end
  object mmProps: TMemo
    Left = 4
    Top = 4
    Width = 209
    Height = 305
    Anchors = [akLeft, akTop, akBottom]
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
end
