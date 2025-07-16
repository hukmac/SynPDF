program SynPdf_1v18a_alpha_blending;

uses
  Vcl.Forms,
  UMainFrm in 'UMainFrm.pas' {MainFrm},
  mORMotReport in '..\mORMotReport.pas',
  SynCommons in '..\SynCommons.pas',
  SynCrypto in '..\SynCrypto.pas',
  SynGdiPlus in '..\SynGdiPlus.pas',
  SynLZ in '..\SynLZ.pas',
  SynPdf in '..\SynPdf.pas',
  SynTable in '..\SynTable.pas',
  SynZip in '..\SynZip.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Examples of alpha blending in SynPdf 1.18a';
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
