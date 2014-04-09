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
    Level: Integer;
  end;

  TDocDataCompare = class(TInterfacedObject, IComparer<TDocData>)
  public
    function Compare(const aFirstDoc, aSndDoc: TDocData): Integer;
  end;

  TBTrieController = class
  strict private
    FRoot: TNode;
    FRank: Integer;

    FDataAllocated: Int64;
    FDataUsed: Int64;
    FBlocksAllocated: Integer;

    procedure UpdateParents(const aNode: TNode);
    procedure SplitParent(const aNode: TNode);
    procedure SplitSelf(var aNode: TNode);
    procedure DeleteChain(var aNode: TNode);
    function CountChilds(const aNode: TNode): Integer;
  public

    constructor Create;

    procedure AddData(const aID: Integer; const aDataSize: Integer);

    procedure DebugDraw(const aCanvas: TCanvas);

    property DataAlloc: Int64 read FDataAllocated;
    property DataInUse: Int64 read FDataUsed;
    property TotalBlocksAlloc: Integer read FBlocksAllocated;
  end;

const
  cChunkSize = 256;
  cMaxChunkSize = 65536;
  cReservedProcent = 20;
  cInd = 16;

implementation


{ TB_Tree }

procedure TBTrieController.AddData(const aID, aDataSize: Integer);
var
  vTempNode: TNode;
  i: Integer;
  vDocDataDelta: Integer;
  vDocInd: Integer;
  vRealloc: Boolean;
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
    FBlocksAllocated := 1;
    FDataAllocated := FRoot.Data.Size;
    FDataUsed := aDataSize;
    FRank := 1;
    FRoot.Level := FRank;
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
          FDataUsed := FDataUsed + vDocDataDelta;
          if (vTempNode.Data.ActualSize + vDocDataDelta < (cMaxChunkSize * (100 - cReservedProcent))/100) or
           ((vDocInd >= 0) and (vTempNode.Data.ActualSize + vDocDataDelta < cMaxChunkSize)) then
          begin
            vRealloc := False;
            if vDocInd < 0 then
              while vTempNode.Data.ActualSize + vDocDataDelta >= 
                (vTempNode.Data.Size * (100 - cReservedProcent))/100 do
              begin
                vTempNode.Data.Size := vTempNode.Data.Size * cInd;
                vRealloc := True;
              end
            else
              while vTempNode.Data.ActualSize + vDocDataDelta >= vTempNode.Data.Size do
              begin
                vTempNode.Data.Size := vTempNode.Data.Size * cInd;
                vRealloc := True;
              end;
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
            if vRealloc then
            begin
              Inc(FBlocksAllocated);
              FDataAllocated := FDataAllocated + vTempNode.Data.Size;
            end;
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
              FRoot.Level := FRank;
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

function TBTrieController.CountChilds(const aNode: TNode): Integer;
var
  vChainNode: TNode;
begin
  Assert(not aNode.IsLeaf);
  vChainNode := aNode.Child;
  Result := 1;
  while Assigned(vChainNode.Sibling) do
    begin
      vChainNode := vChainNode.Sibling;
      inc(Result);
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
        IntToStr(aNode.Data.Size))
    else
      aCanvas.TextOut(aX + 7, aY + 35, IntToStr(aNode.ChildsCounter));
    if Assigned(aNode.Sibling) then
    begin
      DrawNode(aNode.Sibling, aX + 80 + 500*(FRank - aLevel - 1)*(FRank - aLevel - 1), aY, aLevel);
      aCanvas.Brush.Color := clBlack;
      aCanvas.MoveTo(aX + 30, aY + 30);
      aCanvas.LineTo(aX + 110 + 500*(FRank - aLevel - 1)*(FRank - aLevel - 1), aY + 30);
    end;
    if Assigned(aNode.Child) then
    begin
      DrawNode(aNode.Child, aX - 80, aY + 80, aLevel + 1);
      aCanvas.Brush.Color := clBlack;
      aCanvas.MoveTo(aX + 30, aY + 30);
      aCanvas.LineTo(aX - 50, aY + 110);
    end;
    if Assigned(aNode.Parent) then
    begin
      aCanvas.Brush.Color := clMoneyGreen;
      aCanvas.TextOut(aX + 7, aY + 0, IntToStr(aNode.Parent.StartID) + ' - ' + IntToStr(aNode.Parent.EndID));
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
  if not Assigned(aNode) then
    Exit;
  if Assigned(aNode.Sibling) then
    DeleteChain(aNode.Sibling);
  FreeAndNil(aNode);
end;


procedure TBTrieController.SplitParent(const aNode: TNode);
var
  i, vOldDataEnd: Integer;
  vTempNode: TNode;
  vStartNode: TNode;
  vEndNode: TNode;
  vCounter: Integer;
  vToMove: TNode;
  vNewParent: TNode;
begin
  Assert(Assigned(aNode.Parent));
  Assert(not aNode.Parent.IsLeaf);
  if not Assigned(aNode.Parent.Parent) then
  begin
    vTempNode := FRoot;
    FRoot := TNode.Create;
    FRoot.Child := vTempNode;
    FRoot.ChildsCounter := CountChilds(FRoot);
    FRoot.StartID := vTempNode.StartID;
    FRoot.EndID := vTempNode.EndID;
    FRoot.IsLeaf := False;
    vTempNode.Parent := FRoot;
    FRank := FRank + 1;
    FRoot.Level := FRank;
  end;
  vStartNode := aNode.Parent.Child;
  vCounter := 1;
  // Ќахожу начало цепочки, подлежащей переносу
  while Assigned(vStartNode.Sibling) do
  begin
    Inc(vCounter);
    if vCounter > FRank then
      vToMove := vStartNode;
    vStartNode := vStartNode.Sibling;
  end;
  if vCounter > FRank then
  begin
    vStartNode := vToMove.Sibling;
    vToMove.Sibling := nil;
    vStartNode.Parent.ChildsCounter := FRank;
  end
  else
    Exit;
  if (not vStartNode.IsLeaf) and Assigned(vStartNode.Parent.Sibling) then
  begin
      vNewParent := vStartNode.Parent.Sibling;
    while not vStartNode.IsLeaf do
    begin
      Assert(vStartNode.Child.IsLeaf or (vStartNode.ChildsCounter < 2));
      vStartNode := vStartNode.Child;
      vNewParent := vNewParent.Child;
    end;
    vStartNode.Parent := vNewParent;
  end;
  if (not Assigned(vStartNode.Parent.Sibling)) or (vStartNode.IsLeaf) then
  begin
    if not Assigned(vStartNode.Parent.Sibling) then
    begin
      vNewParent := TNode.Create;
      vStartNode.Parent.Sibling := vNewParent;
      vNewParent.IsLeaf := False;
      vNewParent.Level := vStartNode.Parent.Level;
      vNewParent.Parent := vStartNode.Parent.Parent;
    end;
    vNewParent := vStartNode.Parent.Sibling;
    vEndNode := vStartNode;
    while Assigned(vEndNode.Sibling) do
    begin
      vEndNode.Parent := vNewParent;
      vEndNode := vEndNode.Sibling;
    end;
    vEndNode.Parent := vNewParent;
    if vEndNode.IsLeaf and Assigned(vNewParent.Child) then
    begin
      if vEndNode.Data.ActualSize + vNewParent.Child.Data.ActualSize < cMaxChunkSize then
      begin
        vOldDataEnd := High(vEndNode.Data.DocData);
        SetLength(vEndNode.Data.DocData, Length(vEndNode.Data.DocData) +
          Length(vNewParent.Child.Data.DocData));
        Inc(vOldDataEnd);
        for i := 0 to High(vNewParent.Child.Data.DocData) do
          vEndNode.Data.DocData[vOldDataEnd + i] := vNewParent.Child.Data.DocData[i];
        vEndNode.Data.ActualSize := vNewParent.Child.Data.ActualSize + vEndNode.Data.ActualSize;
        vEndNode.EndID := vNewParent.Child.EndID;
        Dec(FBlocksAllocated);
        FDataAllocated := FDataAllocated - vEndNode.Data.Size;
        if vEndNode.Data.Size < vEndNode.Data.ActualSize then
        begin
          vEndNode.Data.Size := Round((100*vEndNode.Data.ActualSize) / (100 - cReservedProcent));
          FDataAllocated := FDataAllocated + vEndNode.Data.Size;
          Inc(FBlocksAllocated);
        end;
        vNewParent.Child.Parent := nil;
        vNewParent.Child := vNewParent.Child.Sibling;        
      end;
    end;
    vEndNode.Sibling := vNewParent.Child;
    vNewParent.Child := vStartNode;
    vNewParent.ChildsCounter := CountChilds(vNewParent);
    if vNewParent.ChildsCounter > FRank then
      SplitParent(vNewParent.Child);
    vNewParent.Parent.ChildsCounter := CountChilds(vNewParent.Parent);
    if vNewParent.Parent.ChildsCounter > FRank then
      SplitParent(vNewParent);
    if vNewParent.Child.IsLeaf then
      UpdateParents(vNewParent.Child);
  end
end;

procedure TBTrieController.SplitSelf(var aNode: TNode);
var
  vOldCurNode: TNode;
  vTempNode: TNode;
  vInd: Integer;
  vSplitedData: TArray<TData>;
  vDataInd: Integer;
  i: Integer;
begin
  Assert(aNode.IsLeaf);
  Assert(Assigned(aNode));
  
  SetLength(vSplitedData, 1);
  vDataInd := 0;
  vOldCurNode := aNode;

  while Assigned(vOldCurNode) do
  begin
    vInd := 0;
    while vInd < Length(vOldCurNode.Data.DocData) do
    begin
      if vSplitedData[vDataInd].ActualSize + vOldCurNode.Data.DocData[vInd].DocDataSize >= (cMaxChunkSize * (100 - cReservedProcent))/100 then
      begin
        vSplitedData[vDataInd].Size := cMaxChunkSize;
        Inc(vDataInd);
        SetLength(vSplitedData, vDataInd + 1);
        vSplitedData[vDataInd].ActualSize := 0;
        vSplitedData[vDataInd].DocData := nil;
        vSplitedData[vDataInd].Size := 0;
      end;
      SetLength(vSplitedData[vDataInd].DocData, Length(vSplitedData[vDataInd].DocData) + 1);
      vSplitedData[vDataInd].DocData[High(vSplitedData[vDataInd].DocData)] := vOldCurNode.Data.DocData[vInd];
      vSplitedData[vDataInd].ActualSize := vSplitedData[vDataInd].ActualSize + vOldCurNode.Data.DocData[vInd].DocDataSize;
      Inc(vInd);
    end;
    vOldCurNode := vOldCurNode.Sibling;
  end;

  vTempNode := aNode;
  for i := 0 to High(vSplitedData) do
  begin
    if vSplitedData[i].Size = 0 then
    begin
      if (vTempNode.Data.Size = 0) or (vSplitedData[i].ActualSize > vTempNode.Data.Size) then
      begin
        vSplitedData[i].Size := Round((100*vSplitedData[i].ActualSize) / (100 - cReservedProcent));
        FDataAllocated := FDataAllocated + vSplitedData[i].Size;
      end
      else
        vSplitedData[i].Size := vTempNode.Data.Size;
    end;
    vTempNode.Data := vSplitedData[i];
    vTempNode.StartID := vTempNode.Data.DocData[0].DocID;
    vTempNode.EndID := vTempNode.Data.DocData[High(vTempNode.Data.DocData)].DocID;
    if (i < High(vSplitedData)) then
    begin
      if not Assigned(vTempNode.Sibling) then
      begin
        vTempNode.Sibling := TNode.Create;
        vTempNode.Sibling.Level := vTempNode.Level;
        vTempNode.Sibling.Parent := vTempNode.Parent;
        vTempNode.Sibling.IsLeaf := True;
        vTempNode.Sibling.Data.Size := 0;
        Inc(FBlocksAllocated);
        FDataAllocated := FDataAllocated + vSplitedData[i+1].Size;
      end;
      vTempNode := vTempNode.Sibling;
    end;
  end;
  if Assigned(vTempNode.Sibling) then
    DeleteChain(vTempNode.Sibling);
  if CountChilds(aNode.Parent) > FRank then
    SplitParent(aNode);
  aNode.Parent.ChildsCounter := CountChilds(aNode.Parent);
end;


procedure TBTrieController.UpdateParents(const aNode: TNode);
var
  vChild: TNode;
begin
  if not Assigned(aNode.Parent) then
    Exit;
  vChild := aNode.Parent.Child;
  vChild.Parent.StartID := 1231312312;
  vChild.Parent.EndID := -1;
  while Assigned(vChild) do
  begin
    if vChild.Parent.StartID > vChild.StartID then
      vChild.Parent.StartID := vChild.StartID;
    if vChild.Parent.EndID < vChild.EndID then
      vChild.Parent.EndID := vChild.EndID;
    vChild := vChild.Sibling;
  end;
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
