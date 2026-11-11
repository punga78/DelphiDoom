{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - reads the parts of a MCD file into a      }
{  MapDataSet (MapDataSet::loadData, without the sprites)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapDataLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomMod.MapData,
  DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch;

type
  /// <summary>
  ///   MapDataSet::loadData: reads TERRAIN/name.MCD (62 bytes a part), applies the patch of the mods and checks
  ///   that every part points to parts that exist and has armor. The lines that the C++ writes to the log for
  ///   the invalid parts are in Problems. The PCK and TAB sprites are not loaded here
  /// </summary>
  TXcomMapDataLoader = class
  strict private
    FFiles: IXcomModFiles;
    FProblems: TArray<string>;
    class procedure ReadPart(const ABytes: TBytes; AOffset: Integer; const APart: TXcomMapData); static;
    procedure Validate(const ADataSet: TXcomMapDataSet);
  public
    /// <param name="AFiles">The virtual files of the mods (TERRAIN/ folder)</param>
    constructor Create(const AFiles: IXcomModFiles);
    /// <summary>
    ///   Loads the set once (a second call does nothing). A missing file, a part that points out of the set
    ///   or has no armor is EXcomModException with the message of the C++; the parts read stay in the set
    /// </summary>
    /// <param name="ADataSet">The set to fill</param>
    /// <param name="APatch">The patch of the mods for the set, or nil</param>
    procedure LoadData(const ADataSet: TXcomMapDataSet; const APatch: TXcomMcdPatch);
    /// <summary>The log lines of the last LoadData ("MCD name object i has 0 armor")</summary>
    property Problems: TArray<string> read FProblems;
  end;

implementation

const
  MCD_RECORD_BYTES = 62;

{ TXcomMapDataLoader }

constructor TXcomMapDataLoader.Create(const AFiles: IXcomModFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

class procedure TXcomMapDataLoader.ReadPart(const ABytes: TBytes; AOffset: Integer; const APart: TXcomMapData);
var
  LFrame, LLayer: Integer;
  function Item(AIndex: Integer): Integer;
  begin
    Result := ABytes[AOffset + AIndex];
  end;
begin
  // the packed MCD record: frames 0..7, LOFT 8..19, ScanG 20..21, then the flags and numbers
  for LFrame := 0 to 7 do
    APart.SetSprite(LFrame, Item(LFrame));
  // P_Level 49, Target_Type 59 and Tile_Type 53; TU_Walk 39, TU_Slide 40, TU_Fly 41
  APart.YOffset := Item(49);
  APart.SetSpecialType(Item(59), Item(53));
  APart.SetTuCosts(Item(39), Item(41), Item(40));
  // UFO_Door 30, Stop_LOS 31, No_Floor 32, Big_Wall 33, Gravlift 34, Door 35, Block_Fire 36, Block_Smoke 37, Xcom_Base 60
  APart.SetFlags(Item(30) <> 0, Item(31) <> 0, Item(32) <> 0, Item(33), Item(34) <> 0, Item(35) <> 0,
    Item(36) <> 0, Item(37) <> 0, Item(60) <> 0);
  // T_Level (48) is a signed char
  APart.TerrainLevel := ShortInt(Item(48));
  APart.FootstepSound := Item(52);
  APart.AltMcd := Item(46);
  APart.DieMcd := Item(44);
  // Light_Block 51, Stop_LOS 31, HE_Block 43, Block_Smoke 37, Flammable 45
  APart.SetBlockValue(Item(51), Item(31), Item(43), Item(37), Item(45), Item(43));
  APart.LightSource := Item(58);
  APart.Armor := Item(42);
  APart.Flammable := Item(45);
  APart.Fuel := Item(57);
  APart.ExplosiveType := Item(54);
  APart.Explosive := Item(55);
  APart.MiniMapIndex := Word(Item(20) or (Item(21) shl 8));
  for LLayer := 0 to 11 do
    APart.SetLoftId(Item(8 + LLayer), LLayer);
end;

procedure TXcomMapDataLoader.Validate(const ADataSet: TXcomMapDataSet);
var
  LIndex: Integer;
  LPart: TXcomMapData;
  LValid: Boolean;
  procedure Report(const AMessage: string);
  begin
    SetLength(FProblems, Length(FProblems) + 1);
    FProblems[High(FProblems)] := AMessage;
    LValid := False;
  end;
begin
  LValid := True;
  for LIndex := 0 to ADataSet.Size - 1 do
  begin
    LPart := ADataSet.GetObject(LIndex);
    // (size_t)int: a negative number is a huge one, so it is out of the set as well
    if (LPart.DieMcd < 0) or (LPart.DieMcd >= ADataSet.Size) then
      Report(Format('MCD %s object %d has invalid DieMCD: %d', [ADataSet.Name, LIndex, LPart.DieMcd]));
    if (LPart.AltMcd < 0) or (LPart.AltMcd >= ADataSet.Size) then
      Report(Format('MCD %s object %d has invalid AltMCD: %d', [ADataSet.Name, LIndex, LPart.AltMcd]));
    if LPart.Armor = 0 then
      Report(Format('MCD %s object %d has 0 armor', [ADataSet.Name, LIndex]));
  end;
  if not LValid then
    raise EXcomModException.CreateFmt('invalid MCD file: TERRAIN/%s.MCD, check log file for more details.',
      [ADataSet.Name]);
end;

procedure TXcomMapDataLoader.LoadData(const ADataSet: TXcomMapDataSet; const APatch: TXcomMcdPatch);
var
  LBytes: TBytes;
  LOffset: Integer;
begin
  SetLength(FProblems, 0);
  if not ADataSet.BeginLoad then
    Exit;
  LBytes := FFiles.LoadBytes('TERRAIN/' + ADataSet.Name + '.MCD');
  // read() of a partial last record sets eof: the C++ ignores a tail shorter than a record
  LOffset := 0;
  while LOffset + MCD_RECORD_BYTES <= Length(LBytes) do
  begin
    ReadPart(LBytes, LOffset, ADataSet.AddObject);
    Inc(LOffset, MCD_RECORD_BYTES);
  end;
  if Assigned(APatch) then
    APatch.ModifyData(ADataSet);
  Validate(ADataSet);
end;

end.
