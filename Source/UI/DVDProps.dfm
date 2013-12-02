object frDVDProps: TfrDVDProps
  Left = 187
  Top = 183
  Width = 493
  Height = 283
  Caption = 'DVD Control Panel'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    485
    249)
  PixelsPerInch = 96
  TextHeight = 13
  object pcMain: TPageControl
    Left = 4
    Top = 4
    Width = 477
    Height = 241
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Main'
    end
    object TabSheet2: TTabSheet
      Caption = 'Menu'
      ImageIndex = 1
    end
    object TabSheet3: TTabSheet
      Caption = 'Title/Chapter'
      ImageIndex = 2
    end
    object TabSheet4: TTabSheet
      Caption = 'Subs/CC'
      ImageIndex = 3
    end
    object TabSheet5: TTabSheet
      Caption = 'Sound'
      ImageIndex = 4
    end
    object TabSheet6: TTabSheet
      Caption = 'Angle'
      ImageIndex = 5
    end
    object TabSheet7: TTabSheet
      Caption = 'Parental'
      ImageIndex = 6
    end
    object TabSheet8: TTabSheet
      Caption = 'Karaoke'
      ImageIndex = 7
    end
    object TabSheet9: TTabSheet
      Caption = 'Bookmarks'
      ImageIndex = 8
    end
  end
end
