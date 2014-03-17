program BTrie;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  BTrieController in 'BTrieController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
