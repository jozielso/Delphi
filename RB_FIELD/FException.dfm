object ExceptionDialog: TExceptionDialog
  Left = 377
  Top = 182
  BorderIcons = [biSystemMenu]
  Caption = 'ExceptionDialog'
  ClientHeight = 445
  ClientWidth = 615
  Color = clBtnFace
  Constraints.MinWidth = 200
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnPaint = FormPaint
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    615
    445)
  PixelsPerInch = 96
  TextHeight = 13
  object BevelDetails: TBevel
    Left = 3
    Top = 119
    Width = 605
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
    ExplicitWidth = 473
  end
  object TextMemo: TMemo
    Left = 56
    Top = 8
    Width = 464
    Height = 105
    Hint = 'Use Ctrl+C to copy the report to the clipboard'
    Anchors = [akLeft, akTop, akRight]
    BevelInner = bvNone
    BevelKind = bkFlat
    BorderStyle = bsNone
    Color = clBtnFace
    Ctl3D = True
    ParentCtl3D = False
    ReadOnly = True
    TabOrder = 0
    WantReturns = False
  end
  object DetailsBtn: TBitBtn
    Left = 526
    Top = 88
    Width = 84
    Height = 25
    Hint = 'Mostra/Oculta Informa'#231#245'es'
    Anchors = [akTop]
    Caption = '&Detalhes'
    TabOrder = 1
    OnClick = DetailsBtnClick
  end
  object PageControl1: TPageControl
    Left = 8
    Top = 134
    Width = 599
    Height = 303
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    Style = tsFlatButtons
    TabOrder = 2
    ExplicitWidth = 624
    ExplicitHeight = 329
    object TabSheet1: TTabSheet
      Caption = 'Geral'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdGeral: TStringGrid
        Left = 0
        Top = 0
        Width = 591
        Height = 272
        Align = alClient
        BevelInner = bvNone
        BevelKind = bkFlat
        BevelOuter = bvNone
        ColCount = 2
        DefaultRowHeight = 18
        DrawingStyle = gdsGradient
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        TabOrder = 0
        OnClick = grdGeralClick
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Chamada'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdChamada: TStringGrid
        Left = 0
        Top = 0
        Width = 591
        Height = 272
        Align = alClient
        BevelInner = bvNone
        BevelKind = bkFlat
        BevelOuter = bvNone
        ColCount = 4
        DefaultRowHeight = 18
        DrawingStyle = gdsGradient
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        TabOrder = 0
        OnClick = grdGeralClick
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Log'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object DetailsMemo: TMemo
        Left = 0
        Top = 0
        Width = 591
        Height = 272
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentColor = True
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WantReturns = False
        WordWrap = False
      end
    end
  end
  object OkBtn: TBitBtn
    Left = 526
    Top = 8
    Width = 84
    Height = 25
    Anchors = [akTop]
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 3
    OnClick = OkBtnClick
  end
  object che_email: TCheckBox
    Left = 526
    Top = 39
    Width = 97
    Height = 17
    Caption = 'Enviar Email'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
end
