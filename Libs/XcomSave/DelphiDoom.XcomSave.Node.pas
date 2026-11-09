{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a node of the battlescape (Node)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Node;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.PositionCodec;

type
  /// <summary>
  ///   Represents a node (a spawn point or a way of a patrol) in the battlescape, loaded from RMP files. The
  ///   segment is not in the saved game (the C++ keeps it commented out)
  /// </summary>
  TXcomNode = class
  strict private
    FId: Integer;
    FPosition: TXcomPosition;
    FSegment: Integer;
    FLinks: TArray<Integer>;
    FNodeType: Integer;
    FRank: Integer;
    FFlags: Integer;
    FReserved: Integer;
    FPriority: Integer;
    FAllocated: Boolean;
    FDummy: Boolean;
  public
    constructor Create; overload;
    constructor Create(AId: Integer; const APosition: TXcomPosition; ASegment, ANodeType, ARank, AFlags, AReserved,
      APriority: Integer); overload;
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Id: Integer read FId;
    property Position: TXcomPosition read FPosition;
    property Segment: Integer read FSegment;
    property Links: TArray<Integer> read FLinks write FLinks;
    property NodeType: Integer read FNodeType write FNodeType;
    /// <summary>getRank: the rank of the units that can spawn here (NodeRank)</summary>
    property Rank: Integer read FRank;
    /// <summary>The patrolling desirability</summary>
    property Flags: Integer read FFlags;
    property Reserved: Integer read FReserved;
    property Priority: Integer read FPriority;
    property Allocated: Boolean read FAllocated;
    property Dummy: Boolean read FDummy write FDummy;
    procedure Allocate;
    procedure Deallocate;
    /// <summary>isTarget: the reserved field is 5</summary>
    function IsTarget: Boolean;
  end;

implementation

{ TXcomNode }

constructor TXcomNode.Create;
begin
  inherited Create;
end;

constructor TXcomNode.Create(AId: Integer; const APosition: TXcomPosition; ASegment, ANodeType, ARank, AFlags,
  AReserved, APriority: Integer);
begin
  inherited Create;
  FId := AId;
  FPosition := APosition;
  FSegment := ASegment;
  FNodeType := ANodeType;
  FRank := ARank;
  FFlags := AFlags;
  FReserved := AReserved;
  FPriority := APriority;
end;

procedure TXcomNode.Load(const ANode: IYamlNode);
begin
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  FPosition := TXcomPositionCodec.Read(ANode, 'position', FPosition);
  FNodeType := TXcomNodeReader.ReadInteger(ANode, 'type', FNodeType);
  FRank := TXcomNodeReader.ReadInteger(ANode, 'rank', FRank);
  FFlags := TXcomNodeReader.ReadInteger(ANode, 'flags', FFlags);
  FReserved := TXcomNodeReader.ReadInteger(ANode, 'reserved', FReserved);
  FPriority := TXcomNodeReader.ReadInteger(ANode, 'priority', FPriority);
  FAllocated := TXcomNodeReader.ReadBoolean(ANode, 'allocated', FAllocated);
  FLinks := TXcomNodeReader.ReadIntegers(ANode, 'links', FLinks);
  FDummy := TXcomNodeReader.ReadBoolean(ANode, 'dummy', FDummy);
end;

function TXcomNode.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
  TXcomPositionCodec.Write(Result, 'position', FPosition);
  TXcomNodeWriter.SetInteger(Result, 'type', FNodeType);
  TXcomNodeWriter.SetInteger(Result, 'rank', FRank);
  TXcomNodeWriter.SetInteger(Result, 'flags', FFlags);
  TXcomNodeWriter.SetInteger(Result, 'reserved', FReserved);
  TXcomNodeWriter.SetInteger(Result, 'priority', FPriority);
  TXcomNodeWriter.SetBoolean(Result, 'allocated', FAllocated);
  TXcomNodeWriter.SetIntegers(Result, 'links', FLinks);
  TXcomNodeWriter.SetBoolean(Result, 'dummy', FDummy);
end;

procedure TXcomNode.Allocate;
begin
  FAllocated := True;
end;

procedure TXcomNode.Deallocate;
begin
  FAllocated := False;
end;

function TXcomNode.IsTarget: Boolean;
begin
  Result := FReserved = 5;
end;

end.
