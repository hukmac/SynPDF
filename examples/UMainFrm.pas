//  Demo project showcasing alpha blending in PDF documents using
//  SynPdf 1.18a (unofficial).
//
//  It generates two PDF files:
//  1. Using direct TPdfCanvas commands (PDF stream-level drawing),
//  2. Using standard GDI drawing via TMetafileCanvas and MetaExtChannel
//     (EMF-level embedding).
//
//  Each file is very simple and contains two pages:
//  - First: with alpha blending effects (semi-transparent shapes and text),
//  - Second: the same content without alpha blending for comparison.
//  Different placement of objects on both pages is related to
//  reversed Y axis in PDF versus GDI.
//
//  To generate pages of the second file, one can use procedures:
//    - DrawToMetafile() : standard case, 'identical' as in first file
//  and
//    - DrawToMetafile_ProblematicMixingWithGSaveGRestore()
//
//  The second function allows one to visualize some problems one can
//  face when mixing PDF-level and GDI-level commands. A detailed
//  description of these problems is at the end of this file (below
//  the code).
//
//  Remarks:
//  - SynPdf 1.18a implements ExtGState to manage alpha blending on the
//    PDF level and MetaExtChannel to manage alpha blending with GDI
//    commands. If MetaExtChannel is not needed, it can be disabled by
//    defining the directive NO_USE_META_EXT_CHANNEL.
//  - SynPdf adds /ExtGState entries to the page's /Resources dictionary
//    only if alpha blending was actually used on that page.
//  - In this demo, all PDF files are not compressed so you can easily
//    inspect the created content and /Resources across pages.
//  - Proposed SetAlphaBlend() is quite fast: 2.1–10.2 µs/call,
//    depending on configuration. But TPdfCanvas.RenderMetaFile
//    (EnumEnhMetaFile GDI32) can take a considerable amount of time when
//    a large number of ExtGStates is added to the EMF.
//    Approximate timings as a function of the number of ExtGStates
//    (i9-9900K 3.2 GHz, PDF with an empty page including only many
//    distinct ExtGStates):
//      1.6k: 137ms, 16k: 3.1s, 32k: 14.2s, 64k: 100s, 128k: 504s
//    Happily, the expected number of distinct ExtGStates in a typical PDF
//    is below 1000, and in a large, complex PDF is up to 10k.
//  - SynPdf 1.18a reuses already-defined ExtGStates to minimize their
//    overall number, but always includes all considered settings
//    (ca, CA, BM). Thus, in some cases, it can be useful to add
//    the possibility to create also an ExtGState with selected settings.
//  - SetAlphaBlend() expects alpha values in range 0–100 as in GDI+.
//    If alpha is mapped to 0–1 range, one can use SetAlphaBlendMode().
//
//
//  Legal notice:
//
//  This software is provided "as is", without warranty of any kind,
//  express or implied, including but not limited to the warranties of
//  merchantability, fitness for a particular purpose and noninfringement.
//  In no event shall the author be liable for any claim, damages or other
//  liability, whether in an action of contract, tort or otherwise, arising
//  from, out of or in connection with the software or the use or other
//  dealings in the software.
//
//  Author: Maciej Huk (this demo and SynPdf 1.18a)
//  Contact: www.ii.pwr.edu.pl/~huk

unit UMainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TMainFrm = class(TForm)
    Gen_Pdf_with_alpha_blending_using_TPdfCanvas: TButton;
    Gen_Pdf_with_alpha_blending_using_GDI: TButton;
    procedure Gen_Pdf_with_alpha_blending_using_TPdfCanvasClick(Sender: TObject);
    procedure Gen_Pdf_with_alpha_blending_using_GDIClick(Sender: TObject);
  end;

var
  MainFrm: TMainFrm;

implementation

uses SynPdf;

{$R *.dfm}

//creates example page with/without alpha blending
//drawing with SynPdf TPdfCanvas commands (PDF stream level)
procedure DrawPageToPdfStream(canvas :TPdfCanvas; use_blending :Boolean);
begin
  with canvas do
  begin
    if use_blending then SetAlphaBlendMode(1, 1, bmNormal);
    GSave;
    Rectangle(100,100,500,500);
    SetRGBFillColor(clBlue);
    FillStroke;

    Rectangle(200,200,700,700);
    SetRGBFillColor(clGreen);
    if use_blending then SetAlphaBlendMode(0.3, 0.3, bmNormal);
    FillStroke;

    if use_blending then SetAlphaBlendMode(0.9, 0.9, bmNormal);
    SetFont('Arial', 64, [pfsBold]);
    canvas.SetRGBFillColor(clBlack);
    TextOut(10,500,AnsiString('Example of alpha blending using SynPdf with TPdfCanvas commands'));
    TextOut(10,20,AnsiString('Second page intentionally without blending'));

    Rectangle(400,400,900,900);
    SetRGBFillColor(clRed);
    if use_blending then SetAlphaBlendMode(0.4, 0.4, bmNormal);
    FillStroke;

    SetRGBFillColor(clYellow);
    if use_blending then SetAlphaBlendMode(0.2, 0.2, bmNormal);
    Rectangle(800,100, 1000,1000);
    FillStroke;

    GRestore;
    SetRGBFillColor(clYellow);
    Rectangle(120,120,150,150);
    FillStroke;
  end;
end;

procedure TMainFrm.Gen_Pdf_with_alpha_blending_using_TPdfCanvasClick(Sender: TObject);
var pdf: TPdfDocumentGDI;
    dpi :Integer;
    fname :String;
begin
  fname:=ExtractFileDir(Application.ExeName)+'\alpha_blending_with_pdf_commands.pdf';
  pdf := TPdfDocumentGDI.Create;
  with pdf do
  try
    dpi:=Screen.PixelsPerInch; //typically 96dpi
    ScreenLogPixels:=dpi;
    CompressionMethod:=cmNone; //disabled compression for easier pdf structure analysis
    GeneratePDF15File:=True;   //PDF14 works as well but requires disabling
                               // UseOptionalContent := False;
    UseOptionalContent := False;
    Info.Title         := 'SynPdf alpha blending example using TPdfCanvas commands';
    Info.Author        := 'Maciej Huk, maciej.huk@pwr.edu.pl';
    Info.CreationDate  := Now;
    Info.Creator       := 'SynPdf 1.18a (unofficial)';
    Info.subject       := 'example';
    DefaultPaperSize   := psA4;
    DefaultPageLandscape:=True;
    DefaultPageWidth:= Round(3000*72/dpi);
    DefaultPageHeight:=Round(2000*72/dpi);

    with Canvas do
    begin
      AddPage;
      DrawPageToPdfStream(canvas, True);  //page with alpha blending
      AddPage;
      DrawPageToPdfStream(canvas, False); //page without alpha blending
    end;
    SaveToFile(fname);
  finally
    Free;
  end;
  ShowMessage('File saved to:'+#10#13+fname);
end;

//creates example page with/without alpha blending
//drawing to TMetafileCanvas with GDI and MetaExtChannel (EMF level)
procedure DrawToMetafile(c :TCanvas; use_blending :Boolean);
var Wmf :TMetafile;
    WmfCanvas :TMetafileCanvas;
begin
  Wmf:=TMetafile.Create;
  Wmf.Enhanced:=True;
  Wmf.height:=2000;
  Wmf.width:=3000;
  WmfCanvas:=TMetafileCanvas.CreateWithComment(Wmf, 0, 'Demo', 'Demo');
  with WmfCanvas do
  begin
    pen.color:=clYellow;
    brush.color:=clYellow;
    if use_blending then SetAlphaBlend(WmfCanvas, 100, 100, bmNormal);

    GSave(WmfCanvas);  //saves PDF state alpha(1,1) and clBlack stroke and fill (see comments at the end of file)
    pen.color:=clBlue;
    brush.color:=clBlue;
    Rectangle(100,100,500,500);  //uses actual pen/brush to set PDF colors before drawing rectangle

    if use_blending then SetAlphaBlend(WmfCanvas, 30, 30, bmNormal);
    pen.color:=clGreen;
    brush.color:=clGreen;
    Rectangle(200,200,700,700);

    if use_blending then SetAlphaBlend(WmfCanvas, 90, 90, bmNormal);
    font.Name:='Arial';
    font.size:=34;
    font.Style:=[fsBold];
    pen.color:=clBlack;
    brush.color:=clWhite;
    TextOut(10,400,AnsiString('Example of alpha blending using SynPdf with GDI and MetaExtChannel'));
    TextOut(10,20,AnsiString('Second page intentionally without blending'));

    pen.color:=clRed;
    brush.color:=clRed;
    if use_blending then SetAlphaBlend(WmfCanvas, 40, 40, bmNormal);
    Rectangle(400,400,900,900);

    if use_blending then SetAlphaBlend(WmfCanvas, 20, 20, bmNormal);
    pen.color:=clYellow;
    brush.color:=clYellow;
    Rectangle(600,100,1300,800);

         //Interesting case (see also comments at the end of file):
    GRestore(WmfCanvas);        //Restores black colors and alpha(1,1)
    pen.color:=clYellow;   //clRed;  //clYellow => rect will be Black
    brush.color:=clYellow; //clRed;  //clRed => rect will be Red
    Rectangle(70,70,190,190);   //Why this rect is drawn with black
  end;                          //   despite canvas colors are set to
  WmfCanvas.Free;               //   clYellow just before?
                                //In such case rectangle is not using canvas colors
                                //to change PDF colors, because canvas colors have not changed
                                //from last drawing.
                                //GRestore acts on PDF level (sets clBlack)
                                //and it is unnoticed by GDI mechanisms.
                                //If clRed is set just before Rectangle,
                                //then PDF colors (and line width) are
                                //updated to clRed after GRestore
  c.StretchDraw(c.ClipRect, Wmf);
  Wmf.Free;
end;

procedure DrawToMetafile_ProblematicMixingWithGSaveGRestore(c :TCanvas; use_blending :Boolean);
var Wmf :TMetafile;
    WmfCanvas :TMetafileCanvas;
begin
  Wmf:=TMetafile.Create;
  Wmf.Enhanced:=True;
  Wmf.height:=2000;
  Wmf.width:=3000;
  WmfCanvas:=TMetafileCanvas.CreateWithComment(Wmf, 0, 'Demo', 'Demo');
  with WmfCanvas do
  begin
    if use_blending then SetAlphaBlend(WmfCanvas, 100, 100, bmNormal);
    pen.color:=clYellow;
    brush.color:=clYellow;       //not added to pdf stream - no object is draw with this color
    Rectangle(0,0,0,0);
    GSave(WmfCanvas);            //saves actual color (black is default at the beginning of the content)
    if use_blending then SetAlphaBlend(WmfCanvas, 20, 20, bmScreen);
    pen.color:=clBlue;
    brush.color:=clBlue;
    GRestore(WmfCanvas);         //restores black colors on pdf level,
                                 //  but does not change canvas colors (still blue)
    Rectangle(100,100, 500,500); //sets PDF colors to canvas colors before drawing
  end;                           //because they are different than during previous drawing
  WmfCanvas.Free;
  c.StretchDraw(c.ClipRect, Wmf);
  Wmf.Free;
end;

procedure TMainFrm.Gen_Pdf_with_alpha_blending_using_GDIClick(Sender: TObject);
var MetaFile: TMetafile;
    MetaFileCanvas: TMetafileCanvas;
    pdf: TPdfDocumentGDI;
    dpi :Integer;
    fname :String;
begin
  fname:=ExtractFileDir(Application.ExeName)+'\alpha_blending_with_GDI_and_MetaExtChannel.pdf';
  pdf := TPdfDocumentGDI.Create;
  with pdf do
  try
    dpi:=Screen.PixelsPerInch; //typically 96dpi
    ScreenLogPixels:=dpi;
    CompressionMethod:=cmNone; //disabled compression for easier pdf structure analysis
    GeneratePDF15File:=True;

    UseOptionalContent := False;
    Info.Title         := 'SynPdf alpha blending example using GDI and MetaExtChannel';
    Info.Author        := 'Maciej Huk, maciej.huk@pwr.edu.pl';
    Info.CreationDate  := Now;
    Info.Creator       := 'SynPdf 1.18a (unofficial)';
    Info.subject       := 'example';
    DefaultPaperSize   := psA4;
    DefaultPageLandscape:=True;
    DefaultPageWidth:= Round(3000*72/dpi);
    DefaultPageHeight:=Round(2000*72/dpi);
    UseMetaFileTextPositioning:=tpKerningFromAveragePosition;

    //example page with alpha blending
    Metafile:=TMetafile.Create;
    MetaFileCanvas:=TMetaFileCanvas.Create(Metafile,0);
    DrawToMetafile(MetaFileCanvas, True);
    //DrawToMetafile_ProblematicMixingWithGSaveGRestore(MetaFileCanvas, True);
    MetafileCanvas.Free;
    AddPage;
    canvas.RenderMetaFile(MetaFile,3,3,0,0);

    //example page without alpha blending
    Metafile:=TMetafile.Create;
    MetaFileCanvas:=TMetaFileCanvas.Create(Metafile,0);
    DrawToMetafile(MetaFileCanvas, False);
    MetafileCanvas.Free;
    AddPage;
    canvas.RenderMetaFile(MetaFile,3,3,0,0);

    SaveToFile(fname);
  finally
    Free;
  end;
  ShowMessage('File saved to:'+#10#13+fname);
end;

end.

// *******************************************************************
//      Comments on mixing PDF level GSave and GRestore operations
//                         with GDI commands
// *******************************************************************
//
//  GSave and GRestore even when used on GDI level are simply pdf-level
//  operations (q and Q). They do not store/restore canvas colors or
//  line style. Thus when mixing GDI/TMetafileCanvas operations with
//  GSave/GRestore please remember that:
//  - setting canvas pen and/or brush colors does not affect the pdf
//    content till some object will be drawn,
//  - GSave will remember only those elements of state which are
//    included in the pdf content,
//  - GRestore will restore colors on PDF level but will not change
//    values of canvas pen and brush colors.
//  - GDI drawing operations (Rectangle, LineTo, etc.) are setting PDF
//    colors and line style using canvas settings before drawing - but
//    not always - only when colors were changed after previous drawing.
//  - Changes of colors done with GRestore are not seen by GDI mechanisms.
//    Thus in some cases this can lead to not expected results.
//    See example below and, another one at the end of DrawToMetafile().
//
//  This can lead to situations as in the following example:
//  (see DrawToMetafile_ProblematicMixingWithGSaveGRestore)
//
//  ---beginning of the content---
//  with WmfCanvas do begin                     (operation level)
//  01 SetAlphaBlend(WmfCanvas, 100, 100, bmNormal); (PDF) puts alpha (1,1, bmNormal) to content as /GS0 ExtGState
//  02 pen.color:=clYellow;			                     (GDI) ignored (no object is drawn using this setting)
//  03 brush.color:=clYellow;                        (GDI) ignored (no object is drawn using this setting)
//  04 GSave(WmfCanvas);                             (PDF) puts q to content - saves prior PDF state
//                                                         (/GS0 is included, but stored stroke/fill colors are
//                                                         clBlack - defaults at the beginning of the PDF stream)
//  05 pen.color:=clBlue;                            (GDI) will be used later by the Rectangle()
//  06 brush.color:=clBlue;                          (GDI) will be used later by the Rectangle()
//  07 SetAlphaBlend(WmfCanvas, 20, 20, bmScreen);   (PDF) puts alpha (0.2,0.2, bmScreen) to content as /GS1 ExtGState
//  08 GRestore(WmfCanvas);                          (PDF) puts Q to content - restores state (/GS0 and colors based on content prior line 1 (clBlack).
//                                                         Canvas colors are not changed (stay clBlue)
//  09 Rectangle(100,100, 500,500);                  (GDI=>PDF) blue rectangle with alpha (1,1, bmNormal) appears in the PDF
//  end;                                                   not yellow or black). This is because Rectangle operation uses
//  ---                                                    actual canvas pen&brush colors to change PDF colors before drawing
//
//  Thus please be cautious about this when mixing GSave/GRestore
//  with the GDI. It is useful to see also the actual stream generated
//  in the above situation:
//
//  stream   // COMMANDS  >> COMMENTS:
//  q        // default GStore added by SynPdf
//  /GS0 gs  // SetAlphaBlend(WmfCanvas, 100, 100, bmNormal);
//           // pen.color:=clYellow;
//           // brush.color:=clYellow;
//  q		     // GSave(WmfCanvas);
//                >> looks like storing clYellow, but storing clBlack
//                >> Yellow was never used, so is not set in PDF. Black
//                >> is the default at the beginning of the PDF stream.
//                >> of course is also storing settings from /GS0
//           // pen.color:=clBlue;
//           // brush.color:=clBlue;
//  /GS1 gs  // SetAlphaBlend(WmfCanvas, 20, 20, bmScreen);
//  Q        // GRestore(WmfCanvas);
//                >> looks like restoring clYellow, but in fact it
//                >> restores clBlack (and alpha settings from /GS0)
//           // Rectangle(100,100, 500,500)
//                >> looks like it will be drawn with Yellow (or Black)
//                >> but before drawing it sets PDF colors and style
//                >> using actual settings of the canvas:
//  0 0 1 RG           >> pen color (clBlue)
//  [] 0 d             >> dash pattern: solid line
//  1 J                >> line cap: round ends
//  1.44 w             >> line width (1.44)
//  0 0 1 rg           >> brush color (clBlue)
//  143.92 828.26 572.82 536.85 re   >> rectangle at (143.92, 828.26), size (572.82 × 536.85)
//  B             >> fill and stroke the rect using current PDF settings
//  Q        // default GRestore added by SynPdf
//  endstream
//
// ===EOT===

