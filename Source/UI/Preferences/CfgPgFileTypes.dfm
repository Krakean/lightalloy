inherited CPFileTypes: TCPFileTypes
  Left = 201
  Top = 117
  Caption = 'CPFileTypes'
  ClientHeight = 351
  ClientWidth = 432
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object sbNone: TSpeedButton
    Left = 216
    Top = 322
    Width = 69
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'None'
    OnClick = sbNoneClick
  end
  object sbVideo: TSpeedButton
    Left = 76
    Top = 322
    Width = 69
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Video'
    OnClick = sbVideoClick
  end
  object sbAudio: TSpeedButton
    Left = 148
    Top = 322
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Audio'
    OnClick = sbAudioClick
  end
  object sbAll: TSpeedButton
    Left = 4
    Top = 322
    Width = 69
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'All'
    OnClick = sbAllClick
  end
  object clbFileTypes: TCheckListBox
    Left = 4
    Top = 4
    Width = 281
    Height = 315
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 18
    Items.Strings = (
      'LAP')
    Style = lbOwnerDrawFixed
    TabOrder = 0
    OnClick = clbFileTypesClick
    OnDrawItem = clbFileTypesDrawItem
  end
  object cbDVD: TCheckBox
    Left = 292
    Top = 326
    Width = 97
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'DVD Autorun'
    TabOrder = 1
  end
  object gbIconset: TGroupBox
    Left = 292
    Top = 4
    Width = 136
    Height = 315
    Anchors = [akTop, akRight, akBottom]
    Caption = 'Icons'
    TabOrder = 2
    DesignSize = (
      136
      315)
    object lbIcons: TListBox
      Left = 6
      Top = 16
      Width = 124
      Height = 161
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemHeight = 13
      Sorted = True
      TabOrder = 0
      OnClick = lbIconsClick
    end
    object mmAuthor: TMemo
      Left = 6
      Top = 180
      Width = 124
      Height = 131
      Anchors = [akLeft, akRight, akBottom]
      Color = clBtnFace
      Ctl3D = True
      ParentCtl3D = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
    end
  end
end
