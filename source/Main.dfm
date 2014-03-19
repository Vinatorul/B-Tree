object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'B-Trie Builder'
  ClientHeight = 366
  ClientWidth = 545
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 257
    Width = 545
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    AutoSnap = False
    Beveled = True
    MinSize = 100
    ExplicitTop = 0
    ExplicitWidth = 262
  end
  object gbTests: TGroupBox
    Left = 0
    Top = 261
    Width = 545
    Height = 105
    Align = alBottom
    Caption = #1058#1077#1089#1090#1080#1088#1086#1074#1072#1085#1080#1077
    TabOrder = 0
    object pnlRandTest: TPanel
      Left = 2
      Top = 15
      Width = 541
      Height = 26
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        541
        26)
      object lblRandTest: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 5
        Width = 50
        Height = 18
        Margins.Top = 5
        Align = alLeft
        Caption = #1044#1086#1073#1072#1074#1080#1090#1100
        ExplicitHeight = 13
      end
      object lblRandTest2: TLabel
        AlignWithMargins = True
        Left = 251
        Top = 5
        Width = 102
        Height = 18
        Margins.Top = 5
        Align = alRight
        Caption = ' '#1089#1083#1091#1095#1072#1081#1085#1099#1093' '#1079#1072#1087#1080#1089#1077#1081' '
        ExplicitLeft = 231
        ExplicitHeight = 13
      end
      object btRandTest: TButton
        Left = 356
        Top = 0
        Width = 185
        Height = 26
        Align = alRight
        Caption = #1044#1086#1073#1072#1074#1080#1090#1100' '#1079#1072#1087#1080#1089#1080
        TabOrder = 0
        OnClick = btRandTestClick
      end
      object SpinEdit1: TSpinEdit
        Left = 80
        Top = 0
        Width = 145
        Height = 22
        Anchors = [akLeft, akTop, akRight, akBottom]
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
        OnChange = SpinEdit1Change
      end
    end
  end
  object gbDebugDraw: TGroupBox
    Left = 0
    Top = 0
    Width = 545
    Height = 257
    Align = alClient
    Caption = #1054#1090#1083#1072#1076#1086#1095#1085#1099#1081' '#1074#1099#1074#1086#1076
    TabOrder = 1
    object JvScrollBox1: TJvScrollBox
      Left = 2
      Top = 15
      Width = 541
      Height = 240
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      DoubleBuffered = True
      Color = clWhite
      ParentColor = False
      ParentDoubleBuffered = False
      TabOrder = 0
      HintColor = clBlack
      OnPaint = JvScrollBox1Paint
    end
  end
end
