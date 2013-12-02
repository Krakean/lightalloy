inherited CPPlayList: TCPPlayList
  Left = 210
  Top = 124
  Caption = 'CPPlayList'
  ClientHeight = 346
  ClientWidth = 367
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object rgColor: TRadioGroup
    Left = 8
    Top = 2
    Width = 211
    Height = 52
    Caption = 'Color'
    ItemIndex = 0
    Items.Strings = (
      'Always the same'
      'According selected skin')
    TabOrder = 0
    OnClick = rgColorClick
  end
  object lbPList: TListBox
    Left = 224
    Top = 6
    Width = 135
    Height = 335
    Style = lbOwnerDrawFixed
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clAqua
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 18
    Items.Strings = (
      '01. MediaFile1.avi'
      '02. MediaFile2.avi'
      '03. MediaFile3.avi'
      '04. MediaFile4.avi'
      '05. MediaFile5.avi'
      '06. MediaFile6.avi'
      '07. MediaFile7.avi')
    ParentFont = False
    TabOrder = 8
    OnDrawItem = lbPListDrawItem
    OnKeyDown = lbPListKeyDown
    OnMouseDown = lbPListMouseDown
  end
  object rgExternal: TRadioGroup
    Left = 8
    Top = 186
    Width = 211
    Height = 52
    Caption = 'Default'
    ItemIndex = 0
    Items.Strings = (
      'Embedded playlist'
      'Separate playlist')
    TabOrder = 2
  end
  object cbNumbers: TCheckBox
    Left = 11
    Top = 240
    Width = 208
    Height = 16
    Caption = 'Show numbers'
    TabOrder = 3
  end
  object cbDuration: TCheckBox
    Left = 11
    Top = 256
    Width = 208
    Height = 16
    Caption = 'Show duration'
    TabOrder = 4
  end
  object gbAdvColor: TGroupBox
    Left = 8
    Top = 56
    Width = 211
    Height = 128
    Caption = 'Color: additionally'
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 18
      Width = 56
      Height = 13
      Caption = 'Cursor color'
    end
    object Label2: TLabel
      Left = 8
      Top = 45
      Width = 84
      Height = 13
      Caption = 'Background color'
    end
    object Label3: TLabel
      Left = 8
      Top = 71
      Width = 73
      Height = 13
      Caption = 'Repeated color'
    end
    object cbSelectionColor: TColorBox
      Left = 102
      Top = 14
      Width = 97
      Height = 22
      ItemHeight = 16
      TabOrder = 0
      OnChange = selColor_OnChange
    end
    object cbBackgroundColor: TColorBox
      Left = 102
      Top = 41
      Width = 97
      Height = 22
      ItemHeight = 16
      TabOrder = 1
      OnChange = backColor_OnChange
    end
    object bbFont: TBitBtn
      Left = 8
      Top = 97
      Width = 192
      Height = 23
      Caption = 'Font'
      TabOrder = 2
      OnClick = bbFontClick
    end
    object cbRepeatFont: TColorBox
      Left = 102
      Top = 67
      Width = 97
      Height = 22
      ItemHeight = 16
      TabOrder = 3
      OnChange = selColor_OnChange
    end
  end
  object cbIntPLState: TCheckBox
    Left = 11
    Top = 272
    Width = 208
    Height = 16
    Caption = 'Remember (Open/Close)'
    TabOrder = 5
  end
  object cbGetNamesFromFileTags: TCheckBox
    Left = 11
    Top = 288
    Width = 208
    Height = 16
    Caption = 'Get track name from tags'
    TabOrder = 6
  end
  object cbEraseOnExit: TCheckBox
    Left = 11
    Top = 304
    Width = 208
    Height = 16
    Caption = 'Clear on exit'
    TabOrder = 7
  end
  object cbAddInsteadReplacing: TCheckBox
    Left = 11
    Top = 320
    Width = 208
    Height = 16
    Caption = 'Add files instead replacing'
    TabOrder = 9
  end
end
