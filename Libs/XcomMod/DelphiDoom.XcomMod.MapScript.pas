{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a command of a map script (MapScript)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapScript;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleTerrain;

type
  /// <summary>SDL_Rect of a script: a rectangle of blocks of the map</summary>
  TXcomScriptRect = record
    X: Integer;
    Y: Integer;
    W: Integer;
    H: Integer;
  end;

  /// <summary>MCDReplacement: the part of a tile set that replaces another when a tunnel is dug</summary>
  TXcomMcdReplacement = record
    TileSet: Integer;
    Entry: Integer;
  end;

  /// <summary>TunnelData: the level of a tunnel and the tile parts it uses, by type</summary>
  TXcomTunnelData = class
  strict private
    FLevel: Integer;
    FReplacements: TXcomStringMap<TXcomMcdReplacement>;
  public
    constructor Create;
    destructor Destroy; override;
    property Level: Integer read FLevel write FLevel;
    property Replacements: TXcomStringMap<TXcomMcdReplacement> read FReplacements;
  end;

  /// <summary>
  ///   One command of the script that builds a battlescape map: add a block, a line, the craft or UFO, dig a
  ///   tunnel, fill an area, check or remove a block, resize (MapScript). The command and the direction are the
  ///   numbers of MapScriptCommand and MapDirection
  /// </summary>
  TXcomMapScript = class
  public
    const
      /// <summary>MapScriptCommand</summary>
      MSC_UNDEFINED = -1;
      MSC_ADDBLOCK = 0;
      MSC_ADDLINE = 1;
      MSC_ADDCRAFT = 2;
      MSC_ADDUFO = 3;
      MSC_DIGTUNNEL = 4;
      MSC_FILLAREA = 5;
      MSC_CHECKBLOCK = 6;
      MSC_REMOVE = 7;
      MSC_RESIZE = 8;
      /// <summary>MapDirection</summary>
      MD_NONE = 0;
      MD_VERTICAL = 1;
      MD_HORIZONTAL = 2;
      MD_BOTH = 3;
  strict private
    FType: Integer;
    FRects: TArray<TXcomScriptRect>;
    FGroups: TArray<Integer>;
    FBlocks: TArray<Integer>;
    FFrequencies: TArray<Integer>;
    FMaxUses: TArray<Integer>;
    FConditionals: TArray<Integer>;
    FSizeX: Integer;
    FSizeY: Integer;
    FSizeZ: Integer;
    FExecutionChances: Integer;
    FExecutions: Integer;
    FLabel: Integer;
    FDirection: Integer;
    FTunnelData: TXcomTunnelData;
    FUfoName: string;
    FCumulativeFrequency: Integer;
    FBlocksTemp: TArray<Integer>;
    FGroupsTemp: TArray<Integer>;
    FFrequenciesTemp: TArray<Integer>;
    FMaxUsesTemp: TArray<Integer>;
    class procedure Erase(var AValues: TArray<Integer>; AIndex: Integer); static;
    function Pick(var AItems: TArray<Integer>; const ARandom: IXcomRandom): Integer;
    procedure ReadRects(const ANode: IYamlNode);
    procedure ReadTunnel(const ANode: IYamlNode);
    procedure ReadSizes(const ANode: IYamlNode);
    procedure ReadSelection(const ANode: IYamlNode);
    procedure ReadDirection(const ANode: IYamlNode; const ACommand: string);
    class procedure Append(var AValues: TArray<Integer>; AValue: Integer); static;
    class procedure Fill(var AValues: TArray<Integer>; ASize, AValue: Integer); static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Loads the command from a YAML node. A missing or unknown "type", a direction that is not V, H or B and a
    ///   tunnel or line without direction are EXcomModException with the messages of the C++
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>
    ///   init: starts a battle with the full lists of groups, blocks, frequencies and uses (the temporary lists
    ///   that the picks shrink). Call it before GetNextBlock
    /// </summary>
    procedure Init;
    /// <summary>
    ///   getGroupNumber: a group by frequency (MT_DEFAULT if the command has no groups, MT_UNDEFINED if every
    ///   frequency is used up); a group with a use limit leaves the list when it is used up. Lists of
    ///   different lengths (the C++ throws out_of_range from at()) are EXcomModException
    /// </summary>
    function GetGroupNumber(const ARandom: IXcomRandom): Integer;
    /// <summary>getBlockNumber: like GetGroupNumber for the numbers of the blocks</summary>
    function GetBlockNumber(const ARandom: IXcomRandom): Integer;
    /// <summary>
    ///   getNextBlock: the next block of the terrain for the command: a random one of the size and group if
    ///   the command has no blocks, otherwise the one picked by number; nil if the number is out of the terrain
    /// </summary>
    function GetNextBlock(const ATerrain: TXcomRuleTerrain; const ARandom: IXcomRandom): TXcomMapBlock;
    property CommandType: Integer read FType;
    property Rects: TArray<TXcomScriptRect> read FRects;
    property Groups: TArray<Integer> read FGroups;
    property Blocks: TArray<Integer> read FBlocks;
    property Frequencies: TArray<Integer> read FFrequencies;
    property MaxUses: TArray<Integer> read FMaxUses;
    property Conditionals: TArray<Integer> read FConditionals;
    property SizeX: Integer read FSizeX;
    property SizeY: Integer read FSizeY;
    property SizeZ: Integer read FSizeZ;
    property ChancesOfExecution: Integer read FExecutionChances;
    property Executions: Integer read FExecutions;
    property ScriptLabel: Integer read FLabel;
    property Direction: Integer read FDirection;
    /// <summary>The data of a tunnel; nil if the command has none</summary>
    property TunnelData: TXcomTunnelData read FTunnelData;
    property UfoName: string read FUfoName;
  end;

implementation

const
  /// <summary>MapBlockType: MT_UNDEFINED and MT_DEFAULT</summary>
  MT_UNDEFINED = -1;
  MT_DEFAULT = 0;

resourcestring
  SMapScriptUnknown = 'Unknown command: %s';
  SMapScriptMissing = 'Missing command type.';
  SMapScriptBadDirection = 'direction must be [V]ertical, [H]orizontal, or [B]oth, what does %s mean?';
  SMapScriptNoDirection = 'no direction defined for %s command, must be [V]ertical, [H]orizontal, or [B]oth';

{ TXcomTunnelData }

constructor TXcomTunnelData.Create;
begin
  inherited Create;
  FReplacements := TXcomStringMap<TXcomMcdReplacement>.Create;
end;

destructor TXcomTunnelData.Destroy;
begin
  FReplacements.Free;
  inherited Destroy;
end;

{ TXcomMapScript }

constructor TXcomMapScript.Create;
begin
  inherited Create;
  FType := MSC_UNDEFINED;
  FSizeX := 1;
  FSizeY := 1;
  FExecutionChances := 100;
  FExecutions := 1;
  FDirection := MD_NONE;
end;

destructor TXcomMapScript.Destroy;
begin
  FTunnelData.Free;
  inherited Destroy;
end;

class procedure TXcomMapScript.Erase(var AValues: TArray<Integer>; AIndex: Integer);
begin
  Delete(AValues, AIndex, 1);
end;

procedure TXcomMapScript.Init;
var
  LFrequency: Integer;
begin
  FCumulativeFrequency := 0;
  for LFrequency in FFrequencies do
    Inc(FCumulativeFrequency, LFrequency);
  FBlocksTemp := Copy(FBlocks);
  FGroupsTemp := Copy(FGroups);
  FFrequenciesTemp := Copy(FFrequencies);
  FMaxUsesTemp := Copy(FMaxUses);
end;

function TXcomMapScript.Pick(var AItems: TArray<Integer>; const ARandom: IXcomRandom): Integer;
var
  LPick, LIndex: Integer;
begin
  if FCumulativeFrequency > 0 then
  begin
    LPick := ARandom.Generate(0, FCumulativeFrequency - 1);
    for LIndex := 0 to High(AItems) do
    begin
      // the C++ reads the frequencies and uses with at(): a shorter list throws out_of_range
      if (LIndex >= Length(FFrequenciesTemp)) or (LIndex >= Length(FMaxUsesTemp)) then
        raise EXcomModException.Create('Xcom: map script lists of different lengths');
      if LPick < FFrequenciesTemp[LIndex] then
      begin
        Result := AItems[LIndex];
        if FMaxUsesTemp[LIndex] > 0 then
        begin
          Dec(FMaxUsesTemp[LIndex]);
          if FMaxUsesTemp[LIndex] = 0 then
          begin
            Erase(AItems, LIndex);
            Dec(FCumulativeFrequency, FFrequenciesTemp[LIndex]);
            Erase(FFrequenciesTemp, LIndex);
            Erase(FMaxUsesTemp, LIndex);
          end;
        end;
        Exit;
      end;
      Dec(LPick, FFrequenciesTemp[LIndex]);
    end;
  end;
  Result := MT_UNDEFINED;
end;

function TXcomMapScript.GetGroupNumber(const ARandom: IXcomRandom): Integer;
begin
  if Length(FGroups) = 0 then
    Exit(MT_DEFAULT);
  Result := Pick(FGroupsTemp, ARandom);
end;

function TXcomMapScript.GetBlockNumber(const ARandom: IXcomRandom): Integer;
begin
  Result := Pick(FBlocksTemp, ARandom);
end;

function TXcomMapScript.GetNextBlock(const ATerrain: TXcomRuleTerrain; const ARandom: IXcomRandom): TXcomMapBlock;
var
  LNumber: Integer;
begin
  if Length(FBlocks) = 0 then
    Exit(ATerrain.GetRandomMapBlock(FSizeX * 10, FSizeY * 10, GetGroupNumber(ARandom), ARandom));
  LNumber := GetBlockNumber(ARandom);
  if (LNumber <> MT_UNDEFINED) and (LNumber < ATerrain.MapBlocks.Count) then
    Exit(ATerrain.MapBlocks[LNumber]);
  Result := nil;
end;

class procedure TXcomMapScript.Append(var AValues: TArray<Integer>; AValue: Integer);
begin
  SetLength(AValues, Length(AValues) + 1);
  AValues[High(AValues)] := AValue;
end;

class procedure TXcomMapScript.Fill(var AValues: TArray<Integer>; ASize, AValue: Integer);
var
  LOld, LIndex: Integer;
begin
  // std::vector::resize(n, value): cut or extended with the value
  LOld := Length(AValues);
  SetLength(AValues, ASize);
  for LIndex := LOld to ASize - 1 do
    AValues[LIndex] := AValue;
end;

procedure TXcomMapScript.ReadRects(const ANode: IYamlNode);
var
  LItem: IYamlNode;
  LRect: TXcomScriptRect;
begin
  for LItem in ANode.Items do
  begin
    LRect.X := LItem.Find(0).AsInteger;
    LRect.Y := LItem.Find(1).AsInteger;
    LRect.W := LItem.Find(2).AsInteger;
    LRect.H := LItem.Find(3).AsInteger;
    SetLength(FRects, Length(FRects) + 1);
    FRects[High(FRects)] := LRect;
  end;
end;

procedure TXcomMapScript.ReadTunnel(const ANode: IYamlNode);
var
  LData: IYamlNode;
  LItem: IYamlNode;
  LReplacement: TXcomMcdReplacement;
begin
  // the C++ leaks the data it replaces
  FTunnelData.Free;
  FTunnelData := TXcomTunnelData.Create;
  FTunnelData.Level := TXcomNodeReader.ReadInteger(ANode, 'level', 0);
  LData := TXcomNodeReader.Field(ANode, 'MCDReplacements');
  if LData.IsDefined then
    for LItem in LData.Items do
    begin
      LReplacement.Entry := TXcomNodeReader.ReadInteger(LItem, 'entry', -1);
      LReplacement.TileSet := TXcomNodeReader.ReadInteger(LItem, 'set', -1);
      FTunnelData.Replacements.SetValue(TXcomNodeReader.ReadString(LItem, 'type', ''), LReplacement);
    end;
end;

procedure TXcomMapScript.ReadSizes(const ANode: IYamlNode);
var
  LEntry: Integer;
  LItem: IYamlNode;
begin
  if ANode.IsSequence then
  begin
    LEntry := 0;
    for LItem in ANode.Items do
    begin
      case LEntry of
        0: FSizeX := LItem.AsInteger(1);
        1: FSizeY := LItem.AsInteger(1);
        2: FSizeZ := LItem.AsInteger(1);
      end;
      Inc(LEntry);
      if LEntry = 3 then
        Break;
    end;
  end
  else
  begin
    FSizeX := ANode.AsInteger(FSizeX);
    FSizeY := FSizeX;
  end;
end;

procedure TXcomMapScript.ReadSelection(const ANode: IYamlNode);
var
  LField, LItem: IYamlNode;
  LSelectionSize, LEntry: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'groups');
  if LField.IsDefined then
  begin
    FGroups := nil;
    if LField.IsSequence then
      for LItem in LField.Items do
        Append(FGroups, LItem.AsInteger(0))
    else
      Append(FGroups, LField.AsInteger(0));
  end;
  LSelectionSize := Length(FGroups);
  LField := TXcomNodeReader.Field(ANode, 'blocks');
  if LField.IsDefined then
  begin
    FGroups := nil;
    if LField.IsSequence then
      for LItem in LField.Items do
        Append(FBlocks, LItem.AsInteger(0))
    else
      Append(FBlocks, LField.AsInteger(0));
    LSelectionSize := Length(FBlocks);
  end;
  Fill(FFrequencies, LSelectionSize, 1);
  Fill(FMaxUses, LSelectionSize, -1);
  LField := TXcomNodeReader.Field(ANode, 'freqs');
  if LField.IsDefined then
  begin
    if LField.IsSequence then
    begin
      LEntry := 0;
      for LItem in LField.Items do
      begin
        if LEntry = LSelectionSize then
          Break;
        FFrequencies[LEntry] := LItem.AsInteger(1);
        Inc(LEntry);
      end;
    end
    else
    begin
      if Length(FFrequencies) = 0 then
        raise EXcomModException.Create('vector::_M_range_check');
      FFrequencies[0] := LField.AsInteger(1);
    end;
  end;
  LField := TXcomNodeReader.Field(ANode, 'maxUses');
  if LField.IsDefined then
  begin
    if LField.IsSequence then
    begin
      LEntry := 0;
      for LItem in LField.Items do
      begin
        if LEntry = LSelectionSize then
          Break;
        FMaxUses[LEntry] := LItem.AsInteger(-1);
        Inc(LEntry);
      end;
    end
    else
    begin
      if Length(FMaxUses) = 0 then
        raise EXcomModException.Create('vector::_M_range_check');
      FMaxUses[0] := LField.AsInteger(-1);
    end;
  end;
end;

procedure TXcomMapScript.ReadDirection(const ANode: IYamlNode; const ACommand: string);
var
  LField: IYamlNode;
  LDirection: string;
begin
  LField := TXcomNodeReader.Field(ANode, 'direction');
  if LField.IsDefined then
  begin
    LDirection := TXcomNodeReader.TextOf(LField, '');
    if LDirection <> '' then
      case UpCase(LDirection[1]) of
        'V': FDirection := MD_VERTICAL;
        'H': FDirection := MD_HORIZONTAL;
        'B': FDirection := MD_BOTH;
      else
        raise EXcomModException.CreateFmt(SMapScriptBadDirection, [LDirection]);
      end;
  end;
  if (FDirection = MD_NONE) and ((FType = MSC_DIGTUNNEL) or (FType = MSC_ADDLINE)) then
    raise EXcomModException.CreateFmt(SMapScriptNoDirection, [ACommand]);
end;

procedure TXcomMapScript.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LCommand: string;
begin
  LField := TXcomNodeReader.Field(ANode, 'type');
  if not LField.IsDefined then
    raise EXcomModException.Create(SMapScriptMissing);
  LCommand := TXcomNodeReader.TextOf(LField, '');
  if LCommand = 'addBlock' then
    FType := MSC_ADDBLOCK
  else if LCommand = 'addLine' then
    FType := MSC_ADDLINE
  else if LCommand = 'addCraft' then
  begin
    FType := MSC_ADDCRAFT;
    // a default that the node can override
    Append(FGroups, 1);
  end
  else if LCommand = 'addUFO' then
  begin
    FType := MSC_ADDUFO;
    Append(FGroups, 1);
  end
  else if LCommand = 'digTunnel' then
    FType := MSC_DIGTUNNEL
  else if LCommand = 'fillArea' then
    FType := MSC_FILLAREA
  else if LCommand = 'checkBlock' then
    FType := MSC_CHECKBLOCK
  else if LCommand = 'removeBlock' then
    FType := MSC_REMOVE
  else if LCommand = 'resize' then
  begin
    FType := MSC_RESIZE;
    // don't resize anything unless specified
    FSizeX := 0;
    FSizeY := 0;
  end
  else
    raise EXcomModException.CreateFmt(SMapScriptUnknown, [LCommand]);
  LField := TXcomNodeReader.Field(ANode, 'rects');
  if LField.IsDefined then
    ReadRects(LField);
  LField := TXcomNodeReader.Field(ANode, 'tunnelData');
  if LField.IsDefined then
    ReadTunnel(LField);
  LField := TXcomNodeReader.Field(ANode, 'conditionals');
  if LField.IsDefined then
  begin
    if LField.IsSequence then
      FConditionals := TXcomNodeReader.ReadIntegers(ANode, 'conditionals', FConditionals)
    else
      Append(FConditionals, LField.AsInteger(0));
  end;
  LField := TXcomNodeReader.Field(ANode, 'size');
  if LField.IsDefined then
    ReadSizes(LField);
  ReadSelection(ANode);
  ReadDirection(ANode, LCommand);
  FExecutionChances := TXcomNodeReader.ReadInteger(ANode, 'executionChances', FExecutionChances);
  FExecutions := TXcomNodeReader.ReadInteger(ANode, 'executions', FExecutions);
  FUfoName := TXcomNodeReader.ReadString(ANode, 'UFOName', FUfoName);
  // take no chances, don't accept negative values here
  FLabel := Abs(TXcomNodeReader.ReadInteger(ANode, 'label', FLabel));
end;

end.
