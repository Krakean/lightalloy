object frJumpToFile: TfrJumpToFile
  Left = 211
  Top = 126
  Width = 407
  Height = 388
  Caption = 'Jump to file'
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 200
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    399
    353)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 5
    Width = 385
    Height = 48
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    DesignSize = (
      385
      48)
    object edtSearch: TEdit
      Left = 8
      Top = 18
      Width = 369
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = edtSearchChange
      OnKeyDown = edtSearchKeyDown
      OnKeyPress = edtSearchKeyPress
    end
  end
  object lstFiles: TListBox
    Left = 8
    Top = 58
    Width = 385
    Height = 263
    Style = lbVirtual
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 1
    OnData = TakeDat
    OnDblClick = lstFilesOnDblClick
    OnKeyDown = lstFilesOnKeyDown
  end
  object btnClose: TButton
    Left = 319
    Top = 326
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCloseOnClick
  end
  object btnJump: TButton
    Left = 209
    Top = 326
    Width = 107
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Play'
    TabOrder = 3
    OnClick = JumpToOnClick
  end
end
