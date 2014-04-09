unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JvExForms, JvScrollBox, BTrieController, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin, Vcl.Mask, JvExMask, JvSpin, JvDBSpinEdit;

type
  TfmMain = class(TForm)
    JvScrollBox1: TJvScrollBox;
    Splitter1: TSplitter;
    gbTests: TGroupBox;
    gbDebugDraw: TGroupBox;
    pnlRandTest: TPanel;
    lblRandTest: TLabel;
    lblRandTest2: TLabel;
    btRandTest: TButton;
    SpinEdit1: TSpinEdit;
    procedure JvScrollBox1Paint(Sender: TObject);
    procedure btRandTestClick(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
  private
    FBTrie: TBTrieController;
    FRandomTestCounter: Integer;
    procedure RandomTest;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

{ TfmMain }

procedure TfmMain.btRandTestClick(Sender: TObject);
begin
  RandomTest;
end;

constructor TfmMain.Create(AOwner: TComponent);
begin
  inherited;
  FBTrie := TBTrieController.Create;
  FBTrie.DebugDraw(JvScrollBox1.Canvas);
end;

procedure TfmMain.JvScrollBox1Paint(Sender: TObject);
begin
  FBTrie.DebugDraw(JvScrollBox1.Canvas);
end;

procedure TfmMain.RandomTest;
var
  i: Integer;
begin
  for i := 0 to FRandomTestCounter - 1 do
    FBTrie.AddData(Random(250000), Random(1024) + 1);
  FBTrie.DebugDraw(JvScrollBox1.Canvas);
end;

procedure TfmMain.SpinEdit1Change(Sender: TObject);
var
  vValue: Integer;
begin
  vValue := Round(SpinEdit1.Value);
  if vValue < 0 then
    vValue := 0;
  FRandomTestCounter := vValue;
  SpinEdit1.Value := vValue;
end;

end.
