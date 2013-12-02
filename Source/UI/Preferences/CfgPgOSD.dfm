inherited CPOSD: TCPOSD
  Left = 222
  Top = 193
  Caption = 'CPOSD'
  ClientHeight = 340
  ClientWidth = 428
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 4
    Top = 8
    Width = 433
    Height = 329
    ActivePage = gbInfo
    Style = tsFlatButtons
    TabOrder = 0
    object gbInfo: TTabSheet
      Caption = 'OSD info'
      object shpInfoFont: TShape
        Left = 377
        Top = 15
        Width = 34
        Height = 34
        Shape = stSquare
        OnMouseDown = shpInfoFontMouseDown
      end
      object pnInfoPreview: TPanel
        Left = 2
        Top = 0
        Width = 367
        Height = 64
        BevelInner = bvLowered
        Caption = 'OSD Text'
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clAqua
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        OnClick = pnInfoPreviewClick
      end
      object gbInfoPos: TGroupBox
        Left = 286
        Top = 118
        Width = 128
        Height = 99
        Caption = 'Position'
        TabOrder = 1
        object Shape3: TShape
          Left = 16
          Top = 22
          Width = 97
          Height = 67
        end
        object Shape4: TShape
          Left = 16
          Top = 72
          Width = 97
          Height = 17
          Brush.Color = clSkyBlue
        end
        object Shape5: TShape
          Left = 16
          Top = 16
          Width = 97
          Height = 9
          Brush.Color = clSkyBlue
        end
        object rbOSDPos0: TRadioButton
          Left = 21
          Top = 28
          Width = 17
          Height = 17
          Color = clWhite
          ParentColor = False
          TabOrder = 0
        end
        object rbOSDPos1: TRadioButton
          Left = 56
          Top = 28
          Width = 17
          Height = 17
          Checked = True
          Color = clWhite
          ParentColor = False
          TabOrder = 1
          TabStop = True
        end
        object rbOSDPos2: TRadioButton
          Left = 91
          Top = 28
          Width = 17
          Height = 17
          Color = clWhite
          ParentColor = False
          TabOrder = 2
        end
        object rbOSDPos4: TRadioButton
          Left = 56
          Top = 52
          Width = 17
          Height = 17
          Color = clWhite
          ParentColor = False
          TabOrder = 3
        end
        object rbOSDPos3: TRadioButton
          Left = 21
          Top = 52
          Width = 17
          Height = 17
          Color = clWhite
          ParentColor = False
          TabOrder = 4
        end
        object rbOSDPos5: TRadioButton
          Left = 91
          Top = 52
          Width = 17
          Height = 17
          Color = clWhite
          ParentColor = False
          TabOrder = 5
        end
      end
      object gbOSDType: TGroupBox
        Left = 1
        Top = 69
        Width = 216
        Height = 44
        Caption = 'OSD type'
        TabOrder = 2
        object rbOSDOver: TRadioButton
          Left = 6
          Top = 18
          Width = 97
          Height = 17
          Caption = 'Over video'
          Checked = True
          TabOrder = 0
          TabStop = True
        end
        object rbOSDWith: TRadioButton
          Left = 110
          Top = 18
          Width = 101
          Height = 17
          Caption = 'With video'
          TabOrder = 1
        end
      end
      object gbBackground: TGroupBox
        Left = 224
        Top = 69
        Width = 190
        Height = 44
        Caption = 'Background'
        TabOrder = 3
        object shpInfoBG: TShape
          Left = 142
          Top = 15
          Width = 30
          Height = 20
          OnMouseDown = shpInfoBGMouseDown
        end
        object cbbBG: TComboBox
          Left = 24
          Top = 15
          Width = 109
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 0
          Text = 'Transparent'
          Items.Strings = (
            'Transparent'
            'Color')
        end
      end
      object gbAddition: TGroupBox
        Left = 1
        Top = 118
        Width = 277
        Height = 163
        Caption = 'Additionally'
        TabOrder = 4
        object Label2: TLabel
          Left = 202
          Top = 16
          Width = 48
          Height = 13
          Caption = 'Second(s)'
        end
        object cbSubAutoload: TCheckBox
          Left = 7
          Top = 37
          Width = 248
          Height = 17
          Hint = 
            #1055#1088#1080' '#1085#1072#1083#1080#1095#1080#1080' '#1074' '#1087#1072#1087#1082#1077' '#1089#1091#1073#1090#1080#1090#1088#1086#1074' '#1089' '#1085#1072#1079#1074#1072#1085#1080#1077#1084' '#1072#1085#1072#1083#1086#1075#1080#1095#1085#1099#1084' '#1074#1086#1089#1087#1088#1086#1080#1079#1074#1086 +
            #1076#1080#1084#1086#1084#1091' '#1074#1080#1076#1077#1086' '#1092#1072#1081#1083#1091','#13#10#1086#1085#1080' '#1073#1091#1076#1091#1090' '#1072#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1080' '#1079#1072#1075#1088#1091#1078#1077#1085#1099'.'
          Caption = 'Load subtitles with the same name'
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
        object cbShowSize: TCheckBox
          Left = 7
          Top = 77
          Width = 248
          Height = 17
          Caption = 'Show video size'
          TabOrder = 5
        end
        object cbOSDInfoShow: TCheckBox
          Left = 7
          Top = 16
          Width = 140
          Height = 17
          Caption = 'Show OSD info during'
          Checked = True
          State = cbChecked
          TabOrder = 0
        end
        object edInfoDur: TEdit
          Left = 151
          Top = 14
          Width = 28
          Height = 21
          ReadOnly = True
          TabOrder = 1
          Text = '2'
        end
        object udInfoDur: TUpDown
          Left = 179
          Top = 14
          Width = 15
          Height = 21
          Associate = edInfoDur
          Min = 1
          Max = 30
          Position = 2
          TabOrder = 2
        end
        object cbAlertMsg: TCheckBox
          Left = 7
          Top = 57
          Width = 248
          Height = 17
          Hint = 
            #1042#1084#1077#1089#1090#1086' '#1085#1072#1076#1086#1077#1076#1083#1080#1074#1099#1093' '#1086#1082#1086#1085' '#1089#1086#1086#1073#1097#1077#1085#1080#1103' '#1086#1073' '#1086#1096#1080#1073#1082#1072#1093' '#1087#1080#1096#1091#1090#1089#1103' '#1048#1085#1092#1086#1088#1084#1072#1094#1080#1086#1085 +
            #1085#1099#1084' '#1091#1074#1077#1076#1086#1084#1083#1077#1085#1080#1077#1084'.'
          Caption = 'OSD messages instead of Alert-windows'
          TabOrder = 4
        end
        object cbUseSkinColors: TCheckBox
          Left = 7
          Top = 97
          Width = 248
          Height = 17
          Caption = 'Use skin colors'
          TabOrder = 6
        end
        object cbPauseTime: TCheckBox
          Left = 7
          Top = 117
          Width = 248
          Height = 17
          Caption = 'Show position on pause'
          TabOrder = 7
        end
        object cbDurationSeek: TCheckBox
          Left = 7
          Top = 137
          Width = 248
          Height = 17
          Caption = 'Show duration on seek'
          TabOrder = 8
        end
      end
    end
    object gbSubs: TTabSheet
      Caption = 'Subtitles'
      ImageIndex = 1
      object shpSubsFont: TShape
        Left = 377
        Top = 2
        Width = 34
        Height = 34
        Shape = stSquare
        OnMouseDown = shpSubsFontMouseDown
      end
      object shpSubsShadow: TShape
        Left = 377
        Top = 43
        Width = 34
        Height = 20
        OnMouseDown = shpSubsShadowMouseDown
      end
      object pnSubPreview: TPanel
        Left = 2
        Top = 0
        Width = 367
        Height = 64
        BevelInner = bvLowered
        Caption = 'Subtitles Text'
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        OnClick = pnSubPreviewClick
      end
      object rgMicroDVDFPS: TRadioGroup
        Left = 2
        Top = 69
        Width = 191
        Height = 53
        Caption = 'FPS for MicroDVD'
        ItemIndex = 1
        Items.Strings = (
          'From media'
          'Fixed:')
        TabOrder = 1
      end
      object gbSubDir: TGroupBox
        Left = 200
        Top = 69
        Width = 213
        Height = 53
        Caption = 'Subtitles folder'
        TabOrder = 2
        DesignSize = (
          213
          53)
        object edSubDir: TEdit
          Left = 8
          Top = 21
          Width = 165
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          Enabled = False
          TabOrder = 0
          Text = 'C:\Subs\'
        end
        object bbSubDir: TBitBtn
          Left = 184
          Top = 21
          Width = 21
          Height = 21
          Anchors = [akTop, akRight]
          Caption = '...'
          Enabled = False
          TabOrder = 1
          OnClick = bbSubDirClick
        end
        object cbSubDir: TCheckBox
          Left = 12
          Top = -2
          Width = 13
          Height = 17
          Caption = 'cbSubDir'
          TabOrder = 2
          OnClick = cbSubDirClick
        end
      end
      object edMicroDVDFPS: TEdit
        Left = 127
        Top = 99
        Width = 57
        Height = 21
        TabOrder = 3
        Text = '25,00'
      end
    end
    object lbInfoStr: TTabSheet
      Caption = 'Info Text template'
      ImageIndex = 2
      object mmInfoStr: TMemo
        Left = 6
        Top = 7
        Width = 379
        Height = 154
        Lines.Strings = (
          '{ARTIST} - {TITLE}'
          '{CODECS}')
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
      end
      object InfoFill: TButton
        Left = 392
        Top = 7
        Width = 17
        Height = 17
        Hint = #1047#1072#1087#1086#1083#1085#1080#1090#1100
        Caption = '<'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = InfoFillClick
        OnMouseDown = InfoFillMouseDown
      end
      object mmInfoDef: TButton
        Left = 392
        Top = 28
        Width = 17
        Height = 17
        Hint = #1054#1089#1085#1086#1074#1085#1099#1077
        Caption = 'D'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = mmInfoDefClick
      end
      object mmInfoClear: TButton
        Left = 392
        Top = 49
        Width = 17
        Height = 17
        Hint = #1054#1095#1080#1089#1090#1080#1090#1100
        Caption = 'X'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnClick = mmInfoClearClick
      end
    end
  end
  object pmInfoFill: TPopupMenu
    Left = 392
    Top = 5
    object General: TMenuItem
      Caption = #1054#1073#1097#1080#1077
      object ARTIST: TMenuItem
        Caption = '{ARTIST} - '#1072#1088#1090#1080#1089#1090
        OnClick = MenuItemClick
      end
      object TITLE: TMenuItem
        Caption = '{TITLE} - '#1079#1072#1075#1086#1083#1086#1074#1086#1082
        OnClick = MenuItemClick
      end
      object ALBUM: TMenuItem
        Caption = '{ALBUM} - '#1072#1083#1100#1073#1086#1084
        OnClick = MenuItemClick
      end
      object YEAR: TMenuItem
        Caption = '{YEAR} - '#1075#1086#1076
        OnClick = MenuItemClick
      end
      object ENCODER: TMenuItem
        Caption = '{ENCODER} - '#1082#1086#1076#1077#1088
        OnClick = MenuItemClick
      end
      object GENRE: TMenuItem
        Caption = '{GENRE} - '#1078#1072#1085#1088
        OnClick = MenuItemClick
      end
      object FORMAT: TMenuItem
        Caption = '{FORMAT} - '#1090#1080#1087' '#1092#1072#1081#1083#1072
        OnClick = MenuItemClick
      end
      object FILENAME: TMenuItem
        Caption = '{FILENAME} - '#1080#1084#1103' '#1092#1072#1081#1083#1072
        OnClick = MenuItemClick
      end
      object CODECS: TMenuItem
        Caption = '{CODECS} - '#1074#1080#1076#1077#1086' '#1080' '#1072#1091#1076#1080#1086' '#1082#1086#1076#1077#1082
        OnClick = MenuItemClick
      end
      object DURATION: TMenuItem
        Caption = '{DURATION} - '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083#1100#1085#1086#1089#1090#1100
        OnClick = MenuItemClick
      end
      object REMAINS: TMenuItem
        Caption = '{REMAINS} - '#1086#1089#1090#1072#1083#1086#1089#1100
        OnClick = MenuItemClick
      end
      object POSITION: TMenuItem
        Caption = '{POSITION} - '#1087#1088#1086#1096#1083#1086
        OnClick = MenuItemClick
      end
      object TIME: TMenuItem
        Caption = '{TIME} - '#1089#1080#1089#1090#1077#1084#1085#1086#1077' '#1074#1088#1077#1084#1103
        OnClick = MenuItemClick
      end
      object SIZE: TMenuItem
        Caption = '{SIZE} - '#1088#1072#1079#1084#1077#1088' '#1092#1072#1081#1083#1072
        OnClick = MenuItemClick
      end
      object COUNT: TMenuItem
        Caption = '{COUNT} - '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1090#1088#1077#1082#1086#1074
        OnClick = MenuItemClick
      end
      object CURRENT: TMenuItem
        Caption = '{CURRENT} - '#1080#1085#1076#1077#1082#1089' '#1090#1077#1082#1091#1097#1077#1075#1086' '#1090#1088#1077#1082#1072
        OnClick = MenuItemClick
      end
    end
    object Video: TMenuItem
      Caption = #1042#1080#1076#1077#1086
      object VIDEOCODECDESC: TMenuItem
        Caption = '{VIDEOCODECDESC} - '#1088#1072#1089#1096#1080#1092#1088#1086#1074#1082#1072' '#1082#1086#1076#1077#1082#1072
        OnClick = MenuItemClick
      end
      object VIDEOCODEC: TMenuItem
        Caption = '{VIDEOCODEC} - '#1082#1086#1076#1077#1082
        OnClick = MenuItemClick
      end
      object VIDEODURATIONTEXT: TMenuItem
        Caption = '{VIDEODURATIONTEXT} - '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083#1100#1085#1086#1089#1090#1100
        OnClick = MenuItemClick
      end
      object VIDEODURATION: TMenuItem
        Caption = '{VIDEODURATION} - '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083#1100#1085#1086#1089#1090#1100
        OnClick = MenuItemClick
      end
      object VIDEOWIDTH: TMenuItem
        Caption = '{VIDEOWIDTH} - '#1096#1080#1088#1080#1085#1072
        OnClick = MenuItemClick
      end
      object VIDEOHEIGHT: TMenuItem
        Caption = '{VIDEOHEIGHT} - '#1074#1099#1089#1086#1090#1072
        OnClick = MenuItemClick
      end
      object VIDEOASPECTRATIO: TMenuItem
        Caption = '{VIDEOASPECTRATIO} - '#1089#1086#1086#1090#1085#1086#1096#1077#1085#1080#1077' '#1089#1090#1086#1088#1086#1085
        OnClick = MenuItemClick
      end
      object VIDEOFPS: TMenuItem
        Caption = '{VIDEOFPS} - '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1082#1072#1076#1088#1086#1074' '#1074' '#1089#1077#1082#1091#1085#1076#1091' (FPS)'
        OnClick = MenuItemClick
      end
      object VIDEOBITRATE: TMenuItem
        Caption = '{VIDEOBITRATE} - '#1074#1080#1076#1077#1086#1073#1080#1090#1088#1077#1081#1090
        OnClick = MenuItemClick
      end
    end
    object Audio: TMenuItem
      Caption = #1040#1091#1076#1080#1086
      object AUDIOCODECDESC: TMenuItem
        Caption = '{AUDIOCODECDESC} - '#1088#1072#1089#1096#1080#1092#1088#1086#1074#1082#1072' '#1082#1086#1076#1077#1082#1072
        OnClick = MenuItemClick
      end
      object AUDIOCODEC: TMenuItem
        Caption = '{AUDIOCODEC} - '#1082#1086#1076#1077#1082
        OnClick = MenuItemClick
      end
      object AUDIODURATIONTEXT: TMenuItem
        Caption = '{AUDIODURATIONTEXT} - '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083#1100#1085#1086#1089#1090#1100
        OnClick = MenuItemClick
      end
      object AUDIODURATION: TMenuItem
        Caption = '{AUDIODURATION} - '#1087#1088#1086#1076#1086#1083#1078#1080#1090#1077#1083#1100#1085#1086#1089#1090#1100
        OnClick = MenuItemClick
      end
      object AUDIOBITRATE: TMenuItem
        Caption = '{AUDIOBITRATE} - '#1073#1080#1090#1088#1077#1081#1076
        OnClick = MenuItemClick
      end
      object AUDIOFORMAT: TMenuItem
        Caption = '{AUDIOFORMAT} - '#1092#1086#1088#1084#1072#1090
        OnClick = MenuItemClick
      end
      object AUDIOSTREAMSCOUNT: TMenuItem
        Caption = '{AUDIOSTREAMSCOUNT} - '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1087#1086#1090#1086#1082#1086#1074'/'#1076#1086#1088#1086#1078#1077#1082
        OnClick = MenuItemClick
      end
    end
  end
end
