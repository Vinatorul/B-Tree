unit BTrieController;

interface

uses
  Graphics, SysUtils, Generics.Defaults, Generics.Collections;

type
  TDocData = record
    DocID: Integer;
    DocDataSize: Integer;
  end;

  TData = record
    DocData: TArray<TDocData>;
    Size: Integer;
    ActualSize: Integer;
  end;

  TNode = class
  public
    Child: TNode;
    Sibling: TNode;
    StartID: Integer;
    EndID: Integer;
    IsLeaf: Boolean;
    Data: TData;
    Parent: TNode;
    ChildsCounter: Integer;
  end;

  TDocDataCompare = class(TInterfacedObject, IComparer<TDocData>)
  public
    function Compare(const aFirstDoc, aSndDoc: TDocData): Integer;
  end;

  TBTrieController = class
  public
    constructor Create;

    procedure AddData(const aID: Integer; const aDataSize: Integer);

    procedure DebugDraw(const aCanvas: TCanvas);
  private
    FRoot: TNode;
    FRank: Integer;
    function GetNode(const aID: Integer): TNode;
    procedure UpdateParents(const aNode: TNode);
    procedure SplitParent(const aNode: TNode);
    procedure SplitSelf(var aNode: TNode);
    procedure DeleteChain(var aNode: TNode);
  end;

const
  cChunkSize = 4096;
  cMaxChunkSize = 32768;
  cReservedProcent = 20;

implementation


{ TB_Tree }

procedure TBTrieController.AddData(const aID, aDataSize: Integer);
var
  vTempNode: TNode;
  i: Integer;
  vDocDataDelta: Integer;
  vDocInd: Integer;
begin
  if FRank = 0 then
  begin
    FRoot := TNode.Create;
    FRoot.StartID := aID;
    FRoot.EndID := aID;
    FRoot.IsLeaf := True;
    SetLength(FRoot.Data.DocData, 1);
    FRoot.Data.DocData[0].DocID := aID;
    FRoot.Data.DocData[0].DocDataSize := aDataSize;
    FRoot.Data.Size := cChunkSize;
    FRoot.Data.ActualSize := aDataSize;
    FRank := 1;
  end
  else
  begin
    vTempNode := FRoot;
    while True do
    begin
      if (aID <= vTempNode.EndID) or ((aID >= vTempNode.EndID) and (not Assigned(vTempNode.Sibling))) then
      begin
        if vTempNode.IsLeaf then
        begin
          vDocDataDelta := aDataSize;
          vDocInd := -1;
          for i := 0 to High(vTempNode.Data.DocData) do
            if vTempNode.Data.DocData[i].DocID = aID then
            begin
              vDocDataDelta := vDocDataDelta - vTempNode.Data.DocData[i].DocDataSize;
              vDocInd := i;
              Break;
            end;
          if (vTempNode.Data.ActualSize + vDocDataDelta < (cMaxChunkSize * (100 - cReservedProcent))/100) or
           ((vDocInd >= 0) and (vTempNode.Data.ActualSize + vDocDataDelta < cMaxChunkSize)) then
          begin
            if vDocInd < 0 then
              while vTempNode.Data.ActualSize + vDocDataDelta >= (vTempNode.Data.Size * (100 - cReservedProcent))/100 do
                vTempNode.Data.Size := vTempNode.Data.Size * 2
            else
              while vTempNode.Data.ActualSize + vDocDataDelta >= cMaxChunkSize do
                vTempNode.Data.Size := vTempNode.Data.Size * 2;
            vTempNode.Data.ActualSize := vTempNode.Data.ActualSize + vDocDataDelta;
            if vDocInd >= 0 then
              vTempNode.Data.DocData[vDocInd].DocDataSize := aDataSize
            else
            begin
              SetLength(vTempNode.Data.DocData, Length(vTempNode.Data.DocData) + 1);
              vDocInd := High(vTempNode.Data.DocData);
              vTempNode.Data.DocData[vDocInd].DocDataSize := aDataSize;
              vTempNode.Data.DocData[vDocInd].DocID := aID;
              TArray.Sort<TDocData>(vTempNode.Data.DocData, TDocDataCompare.Create);
            end;
            if vTempNode.StartID > aID then
              vTempNode.StartID := aID;
            if vTempNode.EndID < aID then
              vTempNode.EndID := aID;
            UpdateParents(vTempNode);
          end
          else
          begin
            if not Assigned(vTempNode.Parent) then
            begin
              FRoot := TNode.Create;
              FRoot.Child := vTempNode;
              FRank := FRank + 1;
              FRoot.StartID := vTempNode.StartID;
              FRoot.EndID := vTempNode.EndID;
              FRoot.IsLeaf := False;
              FRoot.ChildsCounter := 1;
              vTempNode.Parent := FRoot;
            end;
            if vDocInd >= 0 then
              vTempNode.Data.DocData[vDocInd].DocDataSize := aDataSize
            else
            begin
              SetLength(vTempNode.Data.DocData, Length(vTempNode.Data.DocData) + 1);
              vDocInd := High(vTempNode.Data.DocData);
              vTempNode.Data.DocData[vDocInd].DocDataSize := aDataSize;
              vTempNode.Data.DocData[vDocInd].DocID := aID;
              TArray.Sort<TDocData>(vTempNode.Data.DocData, TDocDataCompare.Create);
            end;
            SplitSelf(vTempNode);
          end;
          Break;
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
end;

procedure TBTrieController.DebugDraw(const aCanvas: TCanvas);

  procedure DrawNode(const aNode: TNode; const aX, aY: Integer; const aLevel: Integer);
  begin
    if aNode.IsLeaf then
      aCanvas.Brush.Color := clMoneyGreen
    else
      aCanvas.Brush.Color := clWebOrange;
    aCanvas.Ellipse(aX, aY, aX+60, aY+60);
    aCanvas.TextOut(aX + 7, aY + 20, IntToStr(aNode.StartID) + ' - ' + IntToStr(aNode.EndID));
    if aNode.IsLeaf then
      aCanvas.TextOut(aX + 7, aY + 35, IntToStr(aNode.Data.ActualSize) + '/' +
        IntToStr(aNode.Data.Size));
    if Assigned(aNode.Sibling) then
    begin
      DrawNode(aNode.Sibling, aX + 80 + 200*(FRank - aLevel - 1), aY, aLevel);
      aCanvas.Brush.Color := clBlack;
      aCanvas.MoveTo(aX + 30, aY + 30);
      aCanvas.LineTo(aX + 110 + 200*(FRank - aLevel - 1), aY + 30);
    end;
    if Assigned(aNode.Child) then
    begin
      DrawNode(aNode.Child, aX - 80, aY + 80, aLevel + 1);
      aCanvas.Brush.Color := clBlack;
      aCanvas.MoveTo(aX + 30, aY + 30);
      aCanvas.LineTo(aX - 50, aY + 110);
    end;
  end;

begin
  aCanvas.Brush.Color := clWhite;
  aCanvas.FillRect(aCanvas.ClipRect);
  if Assigned(FRoot) then
    DrawNode(FRoot, 250, 10, 0);
end;

procedure TBTrieController.DeleteChain(var aNode: TNode);
begin
  Assert(aNode.IsLeaf);
  if Assigned(aNode.Sibling) then
    DeleteChain(aNode.Sibling);
  FreeAndNil(aNode);
end;

function TBTrieController.GetNode(const aID: Integer): TNode;
begin

end;

procedure TBTrieController.SplitParent(const aNode: TNode);
var
  vChainCounter: Integer;
  vTempNode: TNode;
  vTempChild: TNode;
  vTempChainCounter: Integer;
  vChildChainToMoveStart: TNode;
  vChildChainToMoveEnd: TNode;
  vTempChainEnd: TNode;
  vChainNode: TNode;
begin
  Assert(Assigned(aNode.Parent));
  Assert(not aNode.Parent.IsLeaf);
  if not Assigned(aNode.Parent.Parent) then
  begin
    vTempNode := FRoot;
    FRoot := TNode.Create;
    FRoot.Child := vTempNode;
    FRoot.StartID := vTempNode.StartID;
    FRoot.EndID := vTempNode.EndID;
    vTempNode.Parent := FRoot;
    FRank := FRank + 1;
  end;
  vTempNode := aNode.Parent;
  vTempChainCounter := 1;
  vTempChild := vTempNode.Child;
  vChildChainToMoveStart := nil;
  while Assigned(vTempChild.Sibling) do
  begin
    vTempChild := vTempChild.Sibling;
    inc(vTempChainCounter);
    if not Assigned(vChildChainToMoveStart) and (vTempChainCounter >= FRank) then
    begin
      if Assigned(vTempChild.Sibling) then
        vChildChainToMoveStart := vTempChild.Sibling;
      vTempChainEnd := vTempChild;
      vTempNode.EndID := vTempChainEnd.EndID;
    end;
  end;
  if vTempChainCounter <= FRank then
    Exit;
  Assert(Assigned(vChildChainToMoveStart));
  vTempChainEnd.Sibling := nil;
  if not Assigned(vTempNode.Sibling) then
  begin
    vTempNode.Sibling := TNode.Create;
    vTempNode.Sibling.Parent := vTempNode.Parent;
    vTempNode.Sibling.EndID := -1;
  end;
  vTempNode := vTempNode.Sibling;
  vChildChainToMoveEnd := vChildChainToMoveStart;
  while Assigned(vChildChainToMoveEnd.Sibling) do
  begin
    vChildChainToMoveEnd := vChildChainToMoveEnd.Sibling;
    vChildChainToMoveEnd.Parent := vTempNode;
  end;
  vChildChainToMoveStart.Parent := vTempNode;
  vChildChainToMoveEnd.Sibling := vTempNode.Child;
  vTempNode.Child := vChildChainToMoveStart;
  vTempNode.StartID := vChildChainToMoveStart.StartID;
  if vTempNode.EndID = -1 then
    vTempNode.EndID := vChildChainToMoveEnd.EndID;
  if vTempNode.Child.IsLeaf then
    SplitSelf(vTempNode.Child);

  vChainCounter := 1;
  vChainNode := vTempNode.Parent.Child;
  while Assigned(vChainNode.Sibling) do
  begin
    vChainNode := vChainNode.Sibling;
    inc(vChainCounter);
  end;
  vTempNode.Parent.ChildsCounter := vChainCounter;
  if vChainCounter > FRank then
    SplitParent(vTempNode);
end;

procedure TBTrieController.SplitSelf(var aNode: TNode);
var
  vChainCounter: Integer;
  vTempNode: TNode;
  vChainNode: TNode;
  vOldCurNode: TNode;
  vNeighbour: TNode;
  vNoNeighbour: Boolean;
  vInd: Integer;
  vNode: TNode;
begin
  vNode := aNode;
  vNeighbour := aNode.Parent.Child;
  vNoNeighbour := vNeighbour = aNode;
  vTempNode := TNode.Create;
  vOldCurNode := aNode;
  if vNoNeighbour then
    aNode.Parent.Child := vTempNode
  else
  begin
    while vNeighbour.Sibling <> aNode do
      vNeighbour := vNeighbour.Sibling;
    vNeighbour.Sibling := vTempNode;
  end;
  vTempNode.Data.ActualSize := 0;
  vTempNode.Data.DocData := nil;
  vTempNode.StartID := -1;
  vTempNode.EndID := -1;
  vTempNode.IsLeaf := True;
  vTempNode.Parent := vOldCurNode.Parent;
  while Assigned(vOldCurNode) do
  begin
    vInd := 0;
    while vInd < Length(vOldCurNode.Data.DocData) do
    begin
      if vTempNode.Data.ActualSize + vOldCurNode.Data.DocData[vInd].DocDataSize >= (cMaxChunkSize * (100 - cReservedProcent))/100 then
      begin
        vTempNode.Data.Size := cMaxChunkSize;
        vTempNode.Sibling := TNode.Create;
        vTempNode := vTempNode.Sibling;
        vTempNode.Data.ActualSize := 0;
        vTempNode.Data.DocData := nil;
        vTempNode.StartID := -1;
        vTempNode.EndID := -1;
        vTempNode.IsLeaf := True;
        vTempNode.Parent := vOldCurNode.Parent;
      end;
      SetLength(vTempNode.Data.DocData, Length(vTempNode.Data.DocData) + 1);
      vTempNode.Data.DocData[High(vTempNode.Data.DocData)] := vOldCurNode.Data.DocData[vInd];
      vTempNode.Data.ActualSize := vTempNode.Data.ActualSize + vOldCurNode.Data.DocData[vInd].DocDataSize;
      if (vTempNode.StartID = -1) or (vTempNode.StartID > vOldCurNode.Data.DocData[vInd].DocID) then
        vTempNode.StartID := vOldCurNode.Data.DocData[vInd].DocID;
      if (vTempNode.EndID = -1) or (vTempNode.EndID < vOldCurNode.Data.DocData[vInd].DocID) then
        vTempNode.EndID := vOldCurNode.Data.DocData[vInd].DocID;
      Inc(vInd);
    end;
    vOldCurNode := vOldCurNode.Sibling;
  end;
  vTempNode.Data.Size := vTempNode.Data.ActualSize +
    Round((vTempNode.Data.ActualSize * cReservedProcent)/100);
  vChainCounter := 1;
  vChainNode := vTempNode.Parent.Child;
  while Assigned(vChainNode.Sibling) do
  begin
    vChainNode := vChainNode.Sibling;
    inc(vChainCounter);
  end;
  vTempNode.Parent.ChildsCounter := vChainCounter;
  if vChainCounter > FRank then
    SplitParent(vTempNode);
  DeleteChain(vNode);
end;

procedure TBTrieController.UpdateParents(const aNode: TNode);
begin
  if not Assigned(aNode.Parent) then
    Exit;
  if aNode.Parent.StartID > aNode.StartID then
    aNode.Parent.StartID := aNode.StartID;
  if aNode.Parent.EndID < aNode.EndID then
    aNode.Parent.EndID := aNode.EndID;
  UpdateParents(aNode.Parent);
end;

{ TDocDataCompare }

function TDocDataCompare.Compare(const aFirstDoc, aSndDoc: TDocData): Integer;
begin
  if aFirstDoc.DocID > aSndDoc.DocID then
    Result := 1
  else if aFirstDoc.DocID < aSndDoc.DocID then
    Result := -1
  else
    Result := 0;
end;

end.
