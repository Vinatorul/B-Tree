unit BTrieController;

interface

type
  TNode = class
  public
    Child: TNode;
    Sibling: TNode;
    StartID: Integer;
    EndID: Integer;
  end;

  TLeaf = class(TNode)
  public
    DataSize: Integer;
  end;

  TBTrieController = class
  public
    procedure AddData(const aID: Integer; const aDataSize: Integer);

    function GetNode(const aID): TNode;
  private
    FRoot: TNode;
  end;

implementation


{ TB_Tree }

procedure TBTrieController.AddData(const aID, aDataSize: Integer);
begin

end;

function TBTrieController.GetNode(const aID): TNode;
begin

end;

end.
