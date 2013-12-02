object frInfo: TfrInfo
  Left = 211
  Top = 123
  Width = 530
  Height = 401
  Caption = 'Info'
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
  OnKeyUp = FormKeyUp
  OnResize = FormResize
  DesignSize = (
    514
    363)
  PixelsPerInch = 96
  TextHeight = 13
  object btOk: TButton
    Left = 218
    Top = 334
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 0
    OnClick = btOkClick
  end
  object sgInfo: TStringGrid
    Left = 4
    Top = 4
    Width = 512
    Height = 325
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clBtnFace
    ColCount = 2
    Ctl3D = True
    DefaultColWidth = 155
    DefaultRowHeight = 16
    RowCount = 20
    FixedRows = 0
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    GridLineWidth = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goDrawFocusSelected, goThumbTracking]
    ParentCtl3D = False
    ParentFont = False
    PopupMenu = sgPopupMenu
    ScrollBars = ssVertical
    TabOrder = 1
    OnDrawCell = sgInfoDrawCell
    OnMouseDown = sgInfoMouseDown
    RowHeights = (
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16
      16)
  end
  object sgPopupMenu: TPopupMenu
    Left = 8
    Top = 304
    object N1: TMenuItem
      Caption = #1050#1086#1087#1080#1088#1086#1074#1072#1090#1100
      OnClick = N1Click
    end
  end
end
