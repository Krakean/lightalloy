object frMain: TfrMain
  Left = 315
  Top = 199
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'Light Alloy'
  ClientHeight = 298
  ClientWidth = 357
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Scaled = False
  ShowHint = True
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object spPlayList: TSplitter
    Left = 190
    Top = 0
    Width = 7
    Height = 219
    Align = alRight
    AutoSnap = False
    Color = clGray
    MinSize = 160
    ParentColor = False
    ResizeStyle = rsUpdate
    Visible = False
  end
  object pnControl: TPanel
    Left = 0
    Top = 219
    Width = 357
    Height = 79
    Align = alBottom
    BevelOuter = bvNone
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clAqua
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnMouseDown = pnControlMouseDown
    OnMouseMove = pnMovieMouseMove
    OnMouseUp = pnControlMouseUp
    object pnAdvanced: TPanel
      Left = 0
      Top = 50
      Width = 357
      Height = 29
      Align = alBottom
      BevelOuter = bvNone
      Color = clGray
      ParentBackground = False
      TabOrder = 0
      OnMouseDown = pnControlMouseDown
      OnMouseMove = pnMovieMouseMove
      OnMouseUp = pnControlMouseUp
    end
    object pnStandard: TPanel
      Left = 0
      Top = 0
      Width = 357
      Height = 29
      Align = alTop
      BevelOuter = bvNone
      Color = clGray
      ParentBackground = False
      TabOrder = 1
      OnMouseDown = pnControlMouseDown
      OnMouseMove = pnMovieMouseMove
      OnMouseUp = pnControlMouseUp
    end
  end
  object pnPlayList: TPanel
    Left = 197
    Top = 0
    Width = 160
    Height = 219
    Align = alRight
    BevelOuter = bvNone
    ParentBackground = False
    ParentColor = True
    TabOrder = 1
    Visible = False
    object pnPlayListBottom: TPanel
      Left = 0
      Top = 165
      Width = 160
      Height = 54
      Align = alBottom
      BevelOuter = bvNone
      Color = clSilver
      Ctl3D = True
      ParentBackground = False
      ParentCtl3D = False
      TabOrder = 0
      OnMouseMove = pnMovieMouseMove
      OnMouseUp = pnMovieMouseUp
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Any file|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Title = 'Open File...'
    Left = 4
    Top = 4
  end
  object Timer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = TimerTimer
    Left = 36
    Top = 4
  end
  object sdPLSave: TSaveDialog
    DefaultExt = 'lap'
    Filter = 'Light Alloy Playlist|*.lap'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save Playlist...'
    Left = 324
    Top = 4
  end
end
