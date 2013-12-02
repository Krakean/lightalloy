object frVideoProps: TfrVideoProps
  Left = 198
  Top = 117
  BorderStyle = bsDialog
  Caption = 'Video properties'
  ClientHeight = 335
  ClientWidth = 615
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
  object btVideoDec: TButton
    Left = 8
    Top = 304
    Width = 601
    Height = 25
    Caption = 'Video decoder'
    TabOrder = 2
  end
  object gbColors: TGroupBox
    Left = 8
    Top = 8
    Width = 213
    Height = 289
    Caption = ' Colors '
    TabOrder = 0
    object btResetBCS: TButton
      Left = 76
      Top = 236
      Width = 65
      Height = 25
      Caption = '-> 0 <-'
      TabOrder = 3
      OnClick = btResetBCSClick
    end
    object gbCo: TGroupBox
      Left = 12
      Top = 88
      Width = 189
      Height = 69
      Caption = ' Contrast '
      TabOrder = 1
      object Image2: TImage
        Left = 12
        Top = 28
        Width = 21
        Height = 17
        Picture.Data = {
          07544269746D6170CA020000424DCA0200000000000036000000280000000E00
          00000F000000010018000000000094020000C40E0000C40E0000000000000000
          0000808080808080808080808080808080808080808080808080808080808080
          8080808080808080808080800000808080808080808080808080808080808080
          8080808080808080808080808080808080808080808080800000808080808080
          8080808080808080800000000000000000000000008080808080808080808080
          808080800000808080808080808080000000000000FFFFFFFFFFFFFFFFFFFFFF
          FF0000000000008080808080808080800000808080808080000000FFFFFFFFFF
          FF000000000000FFFFFFFFFFFFFFFFFFFFFFFF00000080808080808000008080
          80808080000000FFFFFF000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF00
          00008080808080800000808080000000FFFFFF000000000000000000000000FF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFF0000008080800000808080000000FFFFFF00
          0000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000808080
          0000808080000000FFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFF0000008080800000808080000000FFFFFF000000000000000000
          000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000008080800000808080808080
          000000FFFFFF000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF0000008080
          808080800000808080808080000000FFFFFFFFFFFF000000000000FFFFFFFFFF
          FFFFFFFFFFFFFF00000080808080808000008080808080808080800000000000
          00FFFFFFFFFFFFFFFFFFFFFFFF00000000000080808080808080808000008080
          8080808080808080808080808000000000000000000000000080808080808080
          8080808080808080000080808080808080808080808080808080808080808080
          80808080808080808080808080808080808080800000}
        Transparent = True
      end
      object Label4: TLabel
        Left = 44
        Top = 48
        Width = 6
        Height = 13
        Caption = '0'
      end
      object Label5: TLabel
        Left = 104
        Top = 48
        Width = 12
        Height = 13
        Caption = '50'
      end
      object Label6: TLabel
        Left = 160
        Top = 48
        Width = 18
        Height = 13
        Caption = '100'
      end
      object tbCo: TTrackBar
        Left = 35
        Top = 16
        Width = 150
        Height = 33
        Max = 100
        Frequency = 10
        Position = 50
        TabOrder = 0
        OnChange = tbBrChange
      end
    end
    object gbBr: TGroupBox
      Left = 12
      Top = 16
      Width = 189
      Height = 69
      Caption = ' Brightness '
      TabOrder = 0
      object Image1: TImage
        Left = 12
        Top = 28
        Width = 17
        Height = 17
        Picture.Data = {
          07544269746D617006030000424D060300000000000036000000280000000F00
          00000F0000000100180000000000D0020000C40E0000C40E0000000000000000
          0000808080808080808080808080808080808080808080000000808080808080
          8080808080808080808080808080800000008080808080808080808080808080
          8080808080808000000080808080808080808080808080808080808080808000
          0000808080808080000000808080808080808080808080808080808080808080
          8080808080800000008080808080800000008080808080808080800000008080
          8080808000000000000000000080808080808000000080808080808080808000
          0000808080808080808080808080808080000000FFFFFFFFFFFFFFFFFF000000
          8080808080808080808080808080800000008080808080808080808080800000
          00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000080808080808080808080808000
          0000808080808080808080000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFF000000808080808080808080000000000000000000808080000000FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000080808000000000000000
          0000808080808080808080000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFF0000008080808080808080800000008080808080808080808080800000
          00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000080808080808080808080808000
          0000808080808080808080808080808080000000FFFFFFFFFFFFFFFFFF000000
          8080808080808080808080808080800000008080808080808080800000008080
          8080808000000000000000000080808080808000000080808080808080808000
          0000808080808080000000808080808080808080808080808080808080808080
          8080808080800000008080808080800000008080808080808080808080808080
          8080808080808000000080808080808080808080808080808080808080808000
          0000808080808080808080808080808080808080808080000000808080808080
          808080808080808080808080808080000000}
        Transparent = True
      end
      object Label1: TLabel
        Left = 44
        Top = 48
        Width = 6
        Height = 13
        Caption = '0'
      end
      object Label2: TLabel
        Left = 104
        Top = 48
        Width = 12
        Height = 13
        Caption = '50'
      end
      object Label3: TLabel
        Left = 160
        Top = 48
        Width = 18
        Height = 13
        Caption = '100'
      end
      object tbBr: TTrackBar
        Left = 35
        Top = 16
        Width = 150
        Height = 33
        Max = 100
        Frequency = 10
        Position = 50
        TabOrder = 0
        OnChange = tbBrChange
      end
    end
    object gbSa: TGroupBox
      Left = 12
      Top = 160
      Width = 189
      Height = 69
      Caption = ' Saturation '
      TabOrder = 2
      object Image3: TImage
        Left = 12
        Top = 28
        Width = 17
        Height = 17
        Picture.Data = {
          07544269746D617006030000424D060300000000000036000000280000000F00
          00000F0000000100180000000000D0020000C40E0000C40E0000000000000000
          0000808080808080808080808080808080808080808080808080808080808080
          8080808080808080808080808080800000008080808080808080808080808080
          8080808080808080808080808080808080808080808080808080808080808000
          0000808080808080808080808080808080000000000000000000000000808080
          8080808080808080808080808080800000008080808080808080800000000000
          00FFFFFFFFFFFFFFFFFFFFFFFF00000000000080808080808080808080808000
          0000808080808080000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFF000000808080808080808080000000808080808080000000FFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000080808080808080808000
          0000808080000000FFFFFFFFFFFF00FF0000FF00FFFFFFFFFFFFFF0000FF0000
          FFFFFFFFFFFF000000808080808080000000808080000000FFFFFFFFFFFF00FF
          0000FF00FFFFFFFFFFFFFF0000FF0000FFFFFFFFFFFF00000080808080808000
          0000808080000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFF000000808080808080000000808080000000FFFFFFFFFFFFFFFF
          FFFFFFFF0000FF0000FFFFFFFFFFFFFFFFFFFFFFFFFF00000080808080808000
          0000808080808080000000FFFFFFFFFFFFFFFFFF0000FF0000FFFFFFFFFFFFFF
          FFFFFF000000808080808080808080000000808080808080000000FFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000080808080808080808000
          0000808080808080808080000000000000FFFFFFFFFFFFFFFFFFFFFFFF000000
          0000008080808080808080808080800000008080808080808080808080808080
          8000000000000000000000000080808080808080808080808080808080808000
          0000808080808080808080808080808080808080808080808080808080808080
          808080808080808080808080808080000000}
        Transparent = True
      end
      object Label7: TLabel
        Left = 44
        Top = 48
        Width = 6
        Height = 13
        Caption = '0'
      end
      object Label8: TLabel
        Left = 104
        Top = 48
        Width = 12
        Height = 13
        Caption = '50'
      end
      object Label9: TLabel
        Left = 160
        Top = 48
        Width = 18
        Height = 13
        Caption = '100'
      end
      object tbSa: TTrackBar
        Left = 35
        Top = 16
        Width = 150
        Height = 33
        Max = 100
        Frequency = 10
        Position = 50
        TabOrder = 0
        OnChange = tbBrChange
      end
    end
  end
  object gbGeometry: TGroupBox
    Left = 228
    Top = 8
    Width = 257
    Height = 289
    Caption = ' Geometry '
    TabOrder = 1
    object gbAR: TGroupBox
      Left = 12
      Top = 16
      Width = 233
      Height = 45
      TabOrder = 0
      object rb1: TRadioButton
        Left = 9
        Top = 20
        Width = 65
        Height = 17
        Caption = 'As Is'
        Checked = True
        TabOrder = 1
        TabStop = True
        OnClick = cbARClick
      end
      object rb2: TRadioButton
        Left = 76
        Top = 20
        Width = 37
        Height = 17
        Caption = '4:3'
        TabOrder = 2
        OnClick = cbARClick
      end
      object rb3: TRadioButton
        Left = 124
        Top = 20
        Width = 45
        Height = 17
        Caption = '16:9'
        TabOrder = 3
        OnClick = cbARClick
      end
      object cbAR: TCheckBox
        Left = 8
        Top = 0
        Width = 129
        Height = 17
        Caption = 'Fixed Aspect Ratio'
        Checked = True
        State = cbChecked
        TabOrder = 0
        OnClick = cbARClick
      end
      object rb4: TRadioButton
        Left = 172
        Top = 20
        Width = 53
        Height = 17
        Caption = '47:20'
        TabOrder = 4
        OnClick = cbARClick
      end
    end
    object gbZoom: TGroupBox
      Left = 12
      Top = 68
      Width = 233
      Height = 193
      Caption = ' Zoom: 100% x 100% '
      TabOrder = 1
      object imZoom: TImage
        Left = 56
        Top = 25
        Width = 160
        Height = 120
      end
      object tbZy: TTrackBar
        Left = 8
        Top = 16
        Width = 37
        Height = 141
        Max = 300
        Min = 50
        Orientation = trVertical
        Frequency = 50
        Position = 100
        TabOrder = 0
      end
      object tbZx: TTrackBar
        Left = 47
        Top = 152
        Width = 182
        Height = 37
        Max = 300
        Min = 50
        Frequency = 50
        Position = 100
        TabOrder = 2
        TickMarks = tmTopLeft
      end
      object btResetZoom: TButton
        Left = 8
        Top = 160
        Width = 37
        Height = 21
        Caption = '100%'
        TabOrder = 1
      end
    end
  end
  object GroupBox1: TGroupBox
    Left = 492
    Top = 8
    Width = 117
    Height = 289
    Caption = ' VideoProc '
    TabOrder = 3
    object cbVFlip: TCheckBox
      Left = 8
      Top = 20
      Width = 97
      Height = 17
      Caption = 'Vertical flip'
      TabOrder = 0
      OnClick = cbVFlipClick
    end
    object gbEffect: TGroupBox
      Left = 8
      Top = 44
      Width = 101
      Height = 233
      Caption = ' Effect '
      TabOrder = 1
      object Label10: TLabel
        Left = 24
        Top = 28
        Width = 19
        Height = 13
        Caption = 'Soft'
      end
      object Label11: TLabel
        Left = 12
        Top = 204
        Width = 28
        Height = 13
        Caption = 'Sharp'
      end
      object Label12: TLabel
        Left = 12
        Top = 104
        Width = 33
        Height = 13
        Caption = 'Normal'
      end
      object tbEffect: TTrackBar
        Left = 48
        Top = 23
        Width = 45
        Height = 198
        Max = 7
        Orientation = trVertical
        Position = 3
        TabOrder = 0
        TickMarks = tmTopLeft
        OnChange = tbEffectChange
      end
    end
  end
  object Timer1: TTimer
    Interval = 30
    OnTimer = Timer1Timer
    Left = 168
    Top = 244
  end
end
