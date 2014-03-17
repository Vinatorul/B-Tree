unit BTrieController;

interface

uses
  Graphics, SysUtils;

const cChunkSize = 4096;

type
  TNode = class
  public
    Child: TNode;
    Sibling: TNode;
    StartID: Integer;
    EndID: Integer;
    DataSize: Integer;
    IsLeaf: Boolean;
  end;

  TBTrieController = class
  public
    procedure AddData(const aID: Integer; const aDataSize: Integer);

    procedure DebugDraw(const aCanvas: TCanvas);

  private
    FRoot: TNode;
    function GetNode(const aID: Integer): TNode;
  end;

implementation


{ TB_Tree }

procedure TBTrieController.AddData(const aID, aDataSize: Integer);
begin
  if not Assigned(FRoot) then
  begin
    FRoot := TNode.Create;
    FRoot.StartID := aID;
    FRoot.EndID := aID;
    FRoot.DataSize := aDataSize;
    FRoot.IsLeaf := True;
  end;
end;

procedure TBTrieController.DebugDraw(const aCanvas: TCanvas);

  procedure DrawNode(const aNode: TNode; const aX, aY: Integer);
  begin
    if aNode.IsLeaf then
      aCanvas.Brush.Color := clMoneyGreen
    else
      aCanvas.Brush.Color := clWebOrange;
    aCanvas.Ellipse(aX, aY, aX+60, aY+60);
    aCanvas.TextOut(aX + 5, aY + 25, IntToStr(aNode.StartID) + ' - ' + IntToStr(aNode.EndID));
    if aNode.IsLeaf then
      aCanvas.TextOut(aX + 15, aY + 40, IntToStr(aNode.DataSize));
    if Assigned(aNode.Sibling) then
    begin
      DrawNode(aNode.Sibling, aX + 80, aY);
      aCanvas.Brush.Color := clBlack;
      aCanvas.LineTo(aX + 80, aY);
    end;
    if Assigned(aNode.Child) then
    begin
      DrawNode(aNode.Child, aX - 80, aY + 80);
      aCanvas.Brush.Color := clBlack;
      aCanvas.LineTo(aX + 80, aY);
    end;
  end;

begin
  if Assigned(FRoot) then
    DrawNode(FRoot, 300, 10);
end;

function TBTrieController.GetNode(const aID: Integer): TNode;
begin

end;

end.
