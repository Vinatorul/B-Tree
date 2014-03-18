unit BTrieController;

interface

uses
  Graphics, SysUtils;

type
  TNode = class
  public
    Child: TNode;
    Sibling: TNode;
    StartID: Integer;
    EndID: Integer;
    IsLeaf: Boolean;
    DataIndex: Integer;
    Parent: TNode;
    ChildsCounter: Integer;
  end;

  TDocData = record
    DocID: Integer;
    DocDataSize: Integer;
  end;

  TData = record
    DocData: TArray<TDocData>;
    Size: Integer;
    ActualSize: Integer;
  end;

  TBTrieController = class
  public
    constructor Create;

    procedure AddData(const aID: Integer; const aDataSize: Integer);

    procedure DebugDraw(const aCanvas: TCanvas);
  private
    FRoot: TNode;
    FData: TArray<TData>;
    FRank: Integer;
    function GetNode(const aID: Integer): TNode;
  end;

const
  cChunkSize = 4096;
  cMaxChunkSize = 65536;
  cReservedProcent = 20;

implementation


{ TB_Tree }

procedure TBTrieController.AddData(const aID, aDataSize: Integer);
var
  vTempNode: TNode;
  i: Integer;
  vDocDataDelta: Integer;
  vDocInd: Integer;
  vIsNotHandled: Boolean;
  vNewNode: TNode;
  vTempData: TData;
  vInd: Integer;
  vSiblingCounter: Integer;
  vInserted: Boolean;
  vInterator: Integer;
begin
  if FRank = 0 then
  begin
    FRoot := TNode.Create;
    FRoot.StartID := aID;
    FRoot.EndID := aID;
    FRoot.IsLeaf := True;
    SetLength(FData, 1);
    SetLength(FData[0].DocData, 1);
    FData[0].DocData[0].DocID := aID;
    FData[0].DocData[0].DocDataSize := aDataSize;
    FData[0].Size := cChunkSize;
    FData[0].ActualSize := aDataSize;
    FRoot.DataIndex := 0;
    FRank := 1;
  end
  else
  begin
    vTempNode := FRoot;
    vIsNotHandled := True;
    while vIsNotHandled do
    begin
      if (aID <= vTempNode.EndID) or ((aID >= vTempNode.EndID) and (not Assigned(vTempNode.Sibling))) then
      begin
        if vTempNode.IsLeaf then
        begin
          vDocDataDelta := aDataSize;
          vDocInd := -1;
          for i := 0 to High(FData[vTempNode.DataIndex].DocData) do
            if FData[vTempNode.DataIndex].DocData[i].DocID = aID then
            begin
              vDocDataDelta := vDocDataDelta - FData[vTempNode.DataIndex].DocData[i].DocDataSize;
              vDocInd := i;
              Break;
            end;
          if FData[vTempNode.DataIndex].ActualSize + vDocDataDelta < cMaxChunkSize then
          begin
            while FData[vTempNode.DataIndex].ActualSize + vDocDataDelta >= FData[vTempNode.DataIndex].Size do
              FData[vTempNode.DataIndex].Size := FData[vTempNode.DataIndex].Size * 2;
            FData[vTempNode.DataIndex].ActualSize := FData[vTempNode.DataIndex].ActualSize + vDocDataDelta;
            if vDocInd >= 0 then
              FData[vTempNode.DataIndex].DocData[vDocInd].DocDataSize := aDataSize
            else
            begin
              SetLength(FData[vTempNode.DataIndex].DocData, Length(FData[vTempNode.DataIndex].DocData) + 1);
              vDocInd := High(FData[vTempNode.DataIndex].DocData);
              FData[vTempNode.DataIndex].DocData[vDocInd].DocDataSize := aDataSize;
              FData[vTempNode.DataIndex].DocData[vDocInd].DocID := aID;
            end;
            if vTempNode.StartID > aID then
              vTempNode.StartID := aID;
            if vTempNode.EndID < aID then
              vTempNode.EndID := aID;
            vIsNotHandled := False;
          end
          else
          begin
            if Assigned(vTempNode.Parent) then
              vSiblingCounter := vTempNode.Parent.ChildsCounter
            else
              vSiblingCounter := 0;
            vInserted := False;
            vTempData.Size := FData[vTempNode.DataIndex].Size;
            vInterator := 0;
            while (vInterator < Length(FData[vTempNode.DataIndex].DocData)) and
              (vTempData.ActualSize < (vTempData.Size * (100 - cReservedProcent))/100) do            
            begin
              if (not vInserted) and (FData[vTempNode.DataIndex].DocData[vInterator].DocID > aID) then
              begin
                SetLength(vTempData.DocData, Length(vTempData.DocData) + 1);
                vTempData.ActualSize := vTempData.ActualSize + aDataSize;
                vTempData.DocData[High(vTempData.DocData)].DocID := aID;
                vTempData.DocData[High(vTempData.DocData)].DocDataSize := aDataSize;
                vInserted := True;
                Continue;
              end
              else if FData[vTempNode.DataIndex].DocData[vInterator].DocID = aID then
                vInserted := True;
              SetLength(vTempData.DocData, Length(vTempData.DocData) + 1);
              vTempData.DocData[High(vTempData.DocData)] := FData[vTempNode.DataIndex].DocData[vInterator];
              vTempData.ActualSize := vTempData.ActualSize + FData[vTempNode.DataIndex].DocData[vInterator].DocDataSize;
              inc(vInterator);
            end;
            FData[vTempNode.DataIndex] := vTempData;
            vIsNotHandled := False;
          end;
        end
        else
        begin
          vTempNode := vTempNode.Child;
          Continue;
        end;
      end
      else
      begin
        if Assigned(vTempNode.Sibling) then
        begin
          vTempNode := vTempNode.Sibling;
          Continue;
        end;
      end;
    end;
  end;
end;

constructor TBTrieController.Create;
begin
  FRank := 0;
  FData := nil;
end;

procedure TBTrieController.DebugDraw(const aCanvas: TCanvas);

  procedure DrawNode(const aNode: TNode; const aX, aY: Integer);
  begin
    if aNode.IsLeaf then
      aCanvas.Brush.Color := clMoneyGreen
    else
      aCanvas.Brush.Color := clWebOrange;
    aCanvas.Ellipse(aX, aY, aX+60, aY+60);
    aCanvas.TextOut(aX + 7, aY + 20, IntToStr(aNode.StartID) + ' - ' + IntToStr(aNode.EndID));
    if aNode.IsLeaf then
      aCanvas.TextOut(aX + 7, aY + 35, IntToStr(FData[aNode.DataIndex].ActualSize) + '/' + IntToStr(FData[aNode.DataIndex].Size));
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
