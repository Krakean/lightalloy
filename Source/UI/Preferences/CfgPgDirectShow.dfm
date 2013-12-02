inherited CPDirectShow: TCPDirectShow
  Left = 211
  Top = 126
  Caption = 'CPDirectShow'
  ClientHeight = 298
  ClientWidth = 398
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object cbFastRender: TCheckBox
    Left = 8
    Top = 4
    Width = 364
    Height = 17
    Hint = #1069#1082#1089#1087#1077#1088#1080#1084#1077#1085#1090#1072#1083#1100#1085#1072#1103' '#1092#1091#1085#1082#1094#1080#1103', '#1074#1086#1079#1084#1086#1078#1085#1099' '#1074#1099#1083#1077#1090#1099' '#1087#1088#1086#1075#1088#1072#1084#1084#1099'.'
    Caption = 'Fast file open'
    TabOrder = 0
  end
  object gbFilters: TGroupBox
    Left = 8
    Top = 92
    Width = 385
    Height = 201
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Force filters load'
    TabOrder = 1
    DesignSize = (
      385
      201)
    object lbDSPlug: TListBox
      Left = 8
      Top = 16
      Width = 369
      Height = 145
      Style = lbOwnerDrawFixed
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemHeight = 13
      TabOrder = 0
      OnDblClick = bbDSPlugPropsClick
      OnDrawItem = lbDSPlugDrawItem
    end
    object btDSPlugAdd: TButton
      Left = 8
      Top = 168
      Width = 69
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'Add'
      TabOrder = 1
      OnClick = btDSPlugAddClick
    end
    object btDSPlugRemove: TButton
      Left = 309
      Top = 168
      Width = 69
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Remove'
      TabOrder = 3
      OnClick = btDSPlugRemoveClick
    end
    object bbDSPlugProps: TBitBtn
      Left = 160
      Top = 168
      Width = 75
      Height = 25
      Anchors = [akBottom]
      Caption = 'Properties'
      TabOrder = 2
      OnClick = bbDSPlugPropsClick
    end
  end
  object cbLocalFiltersPriority: TCheckBox
    Left = 8
    Top = 22
    Width = 364
    Height = 17
    Caption = 'Local filters priority'
    TabOrder = 2
  end
  object cbDisableSubs: TCheckBox
    Left = 8
    Top = 39
    Width = 364
    Height = 17
    Caption = 'Disable internal subtitles'
    TabOrder = 3
  end
end
