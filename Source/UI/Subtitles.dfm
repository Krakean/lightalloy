object frSubtitles: TfrSubtitles
  Left = 250
  Top = 213
  BorderStyle = bsDialog
  Caption = 'Subtitles parameters'
  ClientHeight = 295
  ClientWidth = 406
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object gbSubs1: TGroupBox
    Left = 3
    Top = 2
    Width = 400
    Height = 143
    Caption = ' 1: '
    TabOrder = 0
    object cbSub1: TCheckBox
      Left = 12
      Top = -1
      Width = 17
      Height = 17
      Caption = 'Show'
      TabOrder = 0
    end
    object GroupBox3: TGroupBox
      Left = 8
      Top = 15
      Width = 49
      Height = 122
      Caption = ' VPos '
      TabOrder = 1
      object tbPos1: TTrackBar
        Left = 2
        Top = 15
        Width = 45
        Height = 105
        Align = alClient
        Max = 100
        Orientation = trVertical
        PageSize = 10
        Frequency = 10
        Position = 75
        TabOrder = 0
        TickMarks = tmBoth
      end
    end
    object GroupBox4: TGroupBox
      Left = 62
      Top = 15
      Width = 332
      Height = 122
      Caption = ' Font '
      TabOrder = 2
      object Label1: TLabel
        Left = 8
        Top = 102
        Width = 30
        Height = 13
        Caption = '-300,0'
      end
      object Label2: TLabel
        Left = 75
        Top = 102
        Width = 6
        Height = 13
        Caption = '0'
      end
      object Label3: TLabel
        Left = 119
        Top = 102
        Width = 33
        Height = 13
        Caption = '+300,0'
      end
      object sbColor1: TShape
        Left = 308
        Top = 14
        Width = 14
        Height = 57
        OnMouseDown = sbColor1MouseDown
      end
      object pnPrv1: TPanel
        Left = 8
        Top = 14
        Width = 297
        Height = 58
        BevelInner = bvLowered
        Caption = 'Sub Stream 1'
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clFuchsia
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        OnClick = pnPrv1Click
      end
      object tbShift1: TTrackBar
        Left = 2
        Top = 72
        Width = 154
        Height = 29
        Max = 3000
        Min = -3000
        Frequency = 1000
        TabOrder = 1
        ThumbLength = 18
      end
      object btLoad1: TBitBtn
        Left = 229
        Top = 76
        Width = 97
        Height = 38
        Caption = 'Load'
        TabOrder = 2
        Glyph.Data = {
          06030000424D06030000000000003600000028000000100000000F0000000100
          180000000000D002000000000000000000000000000000000000ADDFEFADDFEF
          18718C18718C18718C18718C18718C18718C18718C18718C18718C18718C1871
          8C18718C18718CADDFEFADDFEF1082AD2996C62996C62996C62996C62996C629
          96C62996C62996C62996C62996C62996C62996C62996C618718C2996C663CBFF
          2996C694FBFF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7
          FF9CFBFF2996C618718C2996C663CBFF2996C65ABEDE088EBD42B2DE7BE3FF7B
          E3FF7BE3FF63CBEF088EBD0079AD007DB563CBEF2996C618718C2996C65AC7FF
          2996C69CFFFF5AC3E75AC3E784EBFF84E7FF84EBFF84E7FF52BEE7088EBD2996
          C69CFBFF2996C618718C2996C663CBFF2996C69CFBFF94F7FF52C3E77BE3F794
          F7FF94F7FF94F7FF5ACFEF2996C629A2CE9CFBFF2996C618718C2996C66BD7FF
          2996C69CFBFF9CFFFF9CFBFF5ACFEF29AEDE29AEDE21AADE52BEE729AEDE31AE
          D69CFBFF2996C618718C2996C67BE3FF2996C6FFFFFFFFFFFFFFFFFFF7FFFF73
          C7E7BDE7F7DEF3FF8CD3EF39B6EF31B2E7FFFFFF2996C618718C2996C684EBFF
          84E7FF2996C62996C62996C62996C62996C62996C62996C62996C62996C62996
          C62996C62996C6ADDFEF2996C694F7FF8CF7FF8CF7FF8CF7FF8CF7FF8CF3FFFF
          FFFFADDFEF6BEFAD6BEFAD215D21215D21ADDFEFADDFEFADDFEF2996C6FFFFFF
          9CFBFF9CFFFF9CFFFF9CFFFFFFFFFF2996C61082AD18757B215D21215D21215D
          21ADDFEFADDFEFADDFEFADDFEF29A2CEFFFFFFFFFFFFFFFFFFFFFFFF2996C6AD
          DFEFADDFEFADDFEF317542006D00215D21ADDFEFADDFEFADDFEFADDFEFADDFEF
          2996C62996C62996C62996C6ADDFEFADDFEFADDFEFADDFEFADDFEF317542215D
          21ADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFAD
          DFEFADDFEFADDFEFADDFEFADDFEF215D21ADDFEFADDFEFADDFEFADDFEFADDFEF
          ADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDF
          EFADDFEFADDFEFADDFEF}
      end
      object bbReset1: TBitBtn
        Left = 156
        Top = 96
        Width = 69
        Height = 21
        Caption = 'Reset'
        TabOrder = 3
        OnClick = bbReset1Click
      end
      object edShift1: TEdit
        Left = 156
        Top = 74
        Width = 49
        Height = 21
        TabOrder = 4
        Text = '+0,0'
        OnChange = edShift1Change
      end
      object udShift1: TUpDown
        Left = 208
        Top = 73
        Width = 17
        Height = 21
        Min = -100
        TabOrder = 5
      end
    end
  end
  object gbSubs2: TGroupBox
    Left = 4
    Top = 149
    Width = 400
    Height = 143
    Caption = ' 1: '
    TabOrder = 1
    object cbSub2: TCheckBox
      Left = 12
      Top = -1
      Width = 17
      Height = 17
      Caption = 'Show'
      TabOrder = 0
    end
    object GroupBox5: TGroupBox
      Left = 8
      Top = 15
      Width = 49
      Height = 122
      Caption = ' VPos '
      TabOrder = 1
      object tbPos2: TTrackBar
        Left = 2
        Top = 15
        Width = 45
        Height = 105
        Align = alClient
        Max = 100
        Orientation = trVertical
        PageSize = 10
        Frequency = 10
        Position = 75
        TabOrder = 0
        TickMarks = tmBoth
      end
    end
    object GroupBox7: TGroupBox
      Left = 62
      Top = 15
      Width = 332
      Height = 122
      Caption = ' Font '
      TabOrder = 2
      object sbColor2: TShape
        Left = 309
        Top = 13
        Width = 14
        Height = 57
        OnMouseDown = sbColor2MouseDown
      end
      object Label4: TLabel
        Left = 8
        Top = 101
        Width = 30
        Height = 13
        Caption = '-300,0'
      end
      object Label5: TLabel
        Left = 77
        Top = 100
        Width = 6
        Height = 13
        Caption = '0'
      end
      object Label6: TLabel
        Left = 121
        Top = 101
        Width = 33
        Height = 13
        Caption = '+300,0'
      end
      object pnPrv2: TPanel
        Left = 8
        Top = 13
        Width = 297
        Height = 58
        BevelInner = bvLowered
        Caption = 'Sub Stream 2'
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clFuchsia
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        OnClick = pnPrv2Click
      end
      object btLoad2: TBitBtn
        Left = 229
        Top = 75
        Width = 97
        Height = 38
        Caption = 'Load'
        TabOrder = 1
        Glyph.Data = {
          06030000424D06030000000000003600000028000000100000000F0000000100
          180000000000D002000000000000000000000000000000000000ADDFEFADDFEF
          18718C18718C18718C18718C18718C18718C18718C18718C18718C18718C1871
          8C18718C18718CADDFEFADDFEF1082AD2996C62996C62996C62996C62996C629
          96C62996C62996C62996C62996C62996C62996C62996C618718C2996C663CBFF
          2996C694FBFF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7FF6BD7
          FF9CFBFF2996C618718C2996C663CBFF2996C65ABEDE088EBD42B2DE7BE3FF7B
          E3FF7BE3FF63CBEF088EBD0079AD007DB563CBEF2996C618718C2996C65AC7FF
          2996C69CFFFF5AC3E75AC3E784EBFF84E7FF84EBFF84E7FF52BEE7088EBD2996
          C69CFBFF2996C618718C2996C663CBFF2996C69CFBFF94F7FF52C3E77BE3F794
          F7FF94F7FF94F7FF5ACFEF2996C629A2CE9CFBFF2996C618718C2996C66BD7FF
          2996C69CFBFF9CFFFF9CFBFF5ACFEF29AEDE29AEDE21AADE52BEE729AEDE31AE
          D69CFBFF2996C618718C2996C67BE3FF2996C6FFFFFFFFFFFFFFFFFFF7FFFF73
          C7E7BDE7F7DEF3FF8CD3EF39B6EF31B2E7FFFFFF2996C618718C2996C684EBFF
          84E7FF2996C62996C62996C62996C62996C62996C62996C62996C62996C62996
          C62996C62996C6ADDFEF2996C694F7FF8CF7FF8CF7FF8CF7FF8CF7FF8CF3FFFF
          FFFFADDFEF6BEFAD6BEFAD215D21215D21ADDFEFADDFEFADDFEF2996C6FFFFFF
          9CFBFF9CFFFF9CFFFF9CFFFFFFFFFF2996C61082AD18757B215D21215D21215D
          21ADDFEFADDFEFADDFEFADDFEF29A2CEFFFFFFFFFFFFFFFFFFFFFFFF2996C6AD
          DFEFADDFEFADDFEF317542006D00215D21ADDFEFADDFEFADDFEFADDFEFADDFEF
          2996C62996C62996C62996C6ADDFEFADDFEFADDFEFADDFEFADDFEF317542215D
          21ADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFAD
          DFEFADDFEFADDFEFADDFEFADDFEF215D21ADDFEFADDFEFADDFEFADDFEFADDFEF
          ADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDFEFADDF
          EFADDFEFADDFEFADDFEF}
      end
      object bbReset2: TBitBtn
        Left = 157
        Top = 95
        Width = 68
        Height = 21
        Caption = 'Reset'
        TabOrder = 2
        OnClick = bbReset2Click
      end
      object edShift2: TEdit
        Left = 157
        Top = 73
        Width = 49
        Height = 21
        TabOrder = 3
        Text = '+0,0'
        OnChange = edShift1Change
      end
      object udShift2: TUpDown
        Left = 208
        Top = 72
        Width = 17
        Height = 21
        Min = -100
        TabOrder = 4
      end
      object tbShift2: TTrackBar
        Left = 3
        Top = 71
        Width = 154
        Height = 29
        Max = 3000
        Min = -3000
        Frequency = 1000
        TabOrder = 5
        ThumbLength = 18
      end
    end
  end
end
