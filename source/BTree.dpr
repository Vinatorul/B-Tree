program BTree;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  BTreeController in 'BTreeController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
