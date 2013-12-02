inherited CPKeyboard: TCPKeyboard
  Left = 415
  Top = 174
  Caption = 'CPKeyboard'
  ClientHeight = 281
  ClientWidth = 385
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object sbClear: TSpeedButton
    Left = 4
    Top = 252
    Width = 85
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Clear'
    OnClick = sbClearClick
  end
  object sbClearKeys: TSpeedButton
    Left = 92
    Top = 252
    Width = 85
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Clear All'
    OnClick = sbClearKeysClick
  end
  object sbDefaultKeys: TSpeedButton
    Left = 180
    Top = 252
    Width = 85
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Default'
    OnClick = sbDefaultKeysClick
  end
  object sgCommands: TStringGrid
    Left = 4
    Top = 4
    Width = 377
    Height = 245
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    DefaultColWidth = 120
    DefaultRowHeight = 16
    RowCount = 20
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goThumbTracking]
    ScrollBars = ssVertical
    TabOrder = 0
    OnDrawCell = sgCommandsDrawCell
    OnKeyDown = sgCommandsKeyDown
    RowHeights = (
      16
      16
      17
      16
      16
      16
      16
      16
      17
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
  object bbKeySet: TBitBtn
    Left = 268
    Top = 252
    Width = 89
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Custom...'
    TabOrder = 1
    OnClick = bbKeySetClick
  end
  object pmKeySet: TPopupMenu
    Left = 312
    Top = 216
    object WindowsMediaPlayer1: TMenuItem
      Caption = 'Windows Media Player'
      OnClick = WindowsMediaPlayer1Click
    end
    object BSPlayer1: TMenuItem
      Caption = 'BS Player'
      OnClick = BSPlayer1Click
    end
    object Sasami1: TMenuItem
      Caption = 'Sasami'
      OnClick = Sasami1Click
    end
    object ZoomPlayer1: TMenuItem
      Caption = 'Zoom Player'
      OnClick = ZoomPlayer1Click
    end
  end
end
