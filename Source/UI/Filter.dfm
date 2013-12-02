object frFilter: TfrFilter
  Left = 200
  Top = 114
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'Select Filter...'
  ClientHeight = 253
  ClientWidth = 245
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  DesignSize = (
    245
    253)
  PixelsPerInch = 96
  TextHeight = 13
  object btOK: TButton
    Left = 4
    Top = 221
    Width = 73
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object btCancel: TButton
    Left = 167
    Top = 221
    Width = 73
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = frFilterClose
  end
  object lbFilters: TListBox
    Left = 4
    Top = 4
    Width = 237
    Height = 209
    Style = lbOwnerDrawFixed
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 14
    Sorted = True
    TabOrder = 2
    OnDblClick = lbFiltersDblClick
    OnDrawItem = lbFiltersDrawItem
  end
end
