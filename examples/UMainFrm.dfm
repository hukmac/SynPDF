object MainFrm: TMainFrm
  Left = 0
  Top = 0
  Caption = 'Examples of alpha blending in SynPdf 1.18a'
  ClientHeight = 114
  ClientWidth = 412
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Gen_Pdf_with_alpha_blending_using_TPdfCanvas: TButton
    Left = 24
    Top = 24
    Width = 353
    Height = 25
    Caption = 'Create pdf using TPdfCanvas commands'
    TabOrder = 0
    OnClick = Gen_Pdf_with_alpha_blending_using_TPdfCanvasClick
  end
  object Gen_Pdf_with_alpha_blending_using_GDI: TButton
    Left = 24
    Top = 64
    Width = 353
    Height = 25
    Caption = 'Create pdf with alpha blending using GDI and MetaExtChannel'
    TabOrder = 1
    OnClick = Gen_Pdf_with_alpha_blending_using_GDIClick
  end
end
