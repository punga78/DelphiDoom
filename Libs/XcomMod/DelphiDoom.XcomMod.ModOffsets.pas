{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the offsets of the mods (Mod::getOffset,  }
{  Mod::loadOffsetNode, loadSoundOffset, loadTransparencyOffset)                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ModOffsets;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types;

type
  /// <summary>
  ///   ModData: a mod that has resources in the common sets. The offset is where its resources start in a set
  ///   shared by every mod, the size how many it may have. They are size_t in the C++ (32 bit here)
  /// </summary>
  TXcomModData = record
    Name: string;
    Offset: Cardinal;
    Size: Cardinal;
    class function Make(const AName: string; AOffset, ASize: Cardinal): TXcomModData; static;
  end;

  /// <summary>What the offsets need to know of the resource sets that the mods share</summary>
  IXcomSharedResources = interface
    ['{2C8E4F17-6A93-4D05-B1E7-F30A95C8D426}']
    /// <summary>SoundSet::getMaxSharedSounds of the sound set ASet: the sounds that every mod sees</summary>
    function MaxSharedSounds(const ASet: string): Integer;
    /// <summary>
    ///   SurfaceSet::getMaxSharedFrames of the sprite set ASet (Mod::loadSpriteOffset looks it up and the C++
    ///   throws "Sprite Set ... not found" if there is none: this raises EXcomModException)
    /// </summary>
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>
  ///   The functions of Mod that turn the numbers of a ruleset into positions in the common sets: a number or a
  ///   map {index, mod}. The Mod of the C++ knows many more things: this is the part that the rules use to read
  ///   their sprites and sounds. The sprite sets (Mod::loadSpriteOffset, that looks a SurfaceSet up) are not here
  /// </summary>
  TXcomModOffsets = class
  strict private
    FMods: TArray<TXcomModData>;
    FCurrent: Integer;
    FShared: IXcomSharedResources;
  public
    const
      /// <summary>ModNameMaster: the first mod of the list</summary>
      MOD_NAME_MASTER = 'master';
      /// <summary>ModNameCurrent: the mod that is being loaded</summary>
      MOD_NAME_CURRENT = 'current';
      /// <summary>ModTransparceySizeReduction: a transparency offset counts a hundredth of the others</summary>
      TRANSPARENCY_SIZE_REDUCTION = 100;
    /// <param name="AMods">The mods in load order</param>
    /// <param name="ACurrent">The position in AMods of the mod that is being loaded (_modCurrent)</param>
    constructor Create(const AMods: TArray<TXcomModData>; ACurrent: Integer; const AShared: IXcomSharedResources);
    /// <summary>
    ///   Mod::getOffset: an id over AMax is one of the current mod and moves by its offset
    /// </summary>
    function GetOffset(AId, AMax: Integer): Integer;
    /// <summary>
    ///   Mod::loadOffsetNode. A scalar is the number; a map is {index, mod}: the mod is master, current or the
    ///   name of one in the list. A node that is neither leaves AOffset as it was. An offset under -1, or over the
    ///   size of the mod, is EXcomModException with the message of the C++; -1 means no resource. The message of the
    ///   line is the line of the node counted from 0
    /// </summary>
    procedure LoadOffsetNode(const AParent: string; var AOffset: Integer; const ANode: IYamlNode; AShared: Integer;
      const ASet: string; AMultiplier: Cardinal = 1; ASizeScale: Cardinal = 1);
    /// <summary>Mod::loadSoundOffset for one sound: nothing happens if the node is not there</summary>
    procedure LoadSoundOffset(const AParent: string; var ASound: Integer; const ANode: IYamlNode;
      const ASet: string); overload;
    /// <summary>Mod::loadSoundOffset for a list of sounds (a node that is not a sequence is one sound)</summary>
    procedure LoadSoundOffset(const AParent: string; var ASounds: TArray<Integer>; const ANode: IYamlNode;
      const ASet: string); overload;
    /// <summary>Mod::loadSpriteOffset: nothing happens if the node is not there; AMultiplier is for projectiles</summary>
    procedure LoadSpriteOffset(const AParent: string; var ASprite: Integer; const ANode: IYamlNode;
      const ASet: string; AMultiplier: Cardinal = 1);
    /// <summary>Mod::loadTransparencyOffset</summary>
    procedure LoadTransparencyOffset(const AParent: string; var AIndex: Integer; const ANode: IYamlNode);
  end;

implementation

uses
  DelphiDoom.Yaml.Types, DelphiDoom.XcomMod.NodeReader;

resourcestring
  SModOffsetUnknownMod = 'Error for ''%s'': unknown mod ''%s'' used';
  SModOffsetIncorrect = 'Error for ''%s'': offset ''%d'' has incorrect value in set ''%s'' at line %d';
  SModOffsetExceeds = 'Error for ''%s'': offset ''%d'' exceeds mod size limit %d in set ''%s''';
  SModOffsetNoMods = 'XcomMod: the list of mods is empty or the current mod is not in it';

{ TXcomModData }

class function TXcomModData.Make(const AName: string; AOffset, ASize: Cardinal): TXcomModData;
begin
  Result.Name := AName;
  Result.Offset := AOffset;
  Result.Size := ASize;
end;

{ TXcomModOffsets }

constructor TXcomModOffsets.Create(const AMods: TArray<TXcomModData>; ACurrent: Integer;
  const AShared: IXcomSharedResources);
begin
  inherited Create;
  if (Length(AMods) = 0) or (ACurrent < 0) or (ACurrent >= Length(AMods)) then
    raise EXcomModException.Create(SModOffsetNoMods);
  if not Assigned(AShared) then
    raise EArgumentNilException.Create('AShared');
  FMods := AMods;
  FCurrent := ACurrent;
  FShared := AShared;
end;

function TXcomModOffsets.GetOffset(AId, AMax: Integer): Integer;
begin
  if AId > AMax then
    Result := Integer(Cardinal(AId) + FMods[FCurrent].Offset)
  else
    Result := AId;
end;

procedure TXcomModOffsets.LoadOffsetNode(const AParent: string; var AOffset: Integer; const ANode: IYamlNode;
  AShared: Integer; const ASet: string; AMultiplier: Cardinal; ASizeScale: Cardinal);
var
  LCurrent: Integer;
  LName: string;
  LIndex: Integer;
  LFound: Integer;
  LFactor: Integer;
begin
  LCurrent := FCurrent;
  if ANode.IsScalar then
    AOffset := ANode.AsInteger
  else if ANode.IsMap then
  begin
    AOffset := TXcomNodeReader.Field(ANode, 'index').AsInteger;
    LName := TXcomNodeReader.Field(ANode, 'mod').AsString;
    if LName = MOD_NAME_MASTER then
      LCurrent := 0
    else if LName = MOD_NAME_CURRENT then
      // nothing
    else
    begin
      LFound := -1;
      for LIndex := 0 to High(FMods) do
        if FMods[LIndex].Name = LName then
        begin
          LFound := LIndex;
          Break;
        end;
      if LFound < 0 then
        raise EXcomModException.CreateFmt(SModOffsetUnknownMod, [AParent, LName]);
      LCurrent := LFound;
    end;
  end;
  if AOffset < -1 then
    raise EXcomModException.CreateFmt(SModOffsetIncorrect, [AParent, AOffset, ASet, ANode.Mark.Line])
  else if AOffset <> -1 then
  begin
    LFactor := Integer(Cardinal(AOffset) * AMultiplier);
    if Cardinal(LFactor) > FMods[LCurrent].Size div ASizeScale then
      raise EXcomModException.CreateFmt(SModOffsetExceeds,
        [AParent, AOffset, Integer(FMods[LCurrent].Size div AMultiplier div ASizeScale), ASet]);
    if LFactor >= AShared then
      LFactor := Integer(Cardinal(LFactor) + FMods[LCurrent].Offset div ASizeScale);
    AOffset := LFactor;
  end;
end;

procedure TXcomModOffsets.LoadSoundOffset(const AParent: string; var ASound: Integer; const ANode: IYamlNode;
  const ASet: string);
begin
  if ANode.IsDefined then
    LoadOffsetNode(AParent, ASound, ANode, FShared.MaxSharedSounds(ASet), ASet, 1);
end;

procedure TXcomModOffsets.LoadSoundOffset(const AParent: string; var ASounds: TArray<Integer>;
  const ANode: IYamlNode; const ASet: string);
var
  LMaxShared: Integer;
  LItem: IYamlNode;
  LSound: Integer;
begin
  if not ANode.IsDefined then
    Exit;
  LMaxShared := FShared.MaxSharedSounds(ASet);
  ASounds := nil;
  if ANode.IsSequence then
  begin
    for LItem in ANode.Items do
    begin
      LSound := -1;
      LoadOffsetNode(AParent, LSound, LItem, LMaxShared, ASet, 1);
      SetLength(ASounds, Length(ASounds) + 1);
      ASounds[High(ASounds)] := LSound;
    end;
  end
  else
  begin
    LSound := -1;
    LoadOffsetNode(AParent, LSound, ANode, LMaxShared, ASet, 1);
    SetLength(ASounds, 1);
    ASounds[0] := LSound;
  end;
end;

procedure TXcomModOffsets.LoadSpriteOffset(const AParent: string; var ASprite: Integer; const ANode: IYamlNode;
  const ASet: string; AMultiplier: Cardinal);
begin
  if ANode.IsDefined then
    LoadOffsetNode(AParent, ASprite, ANode, FShared.MaxSharedFrames(ASet), ASet, AMultiplier);
end;

procedure TXcomModOffsets.LoadTransparencyOffset(const AParent: string; var AIndex: Integer;
  const ANode: IYamlNode);
begin
  if ANode.IsDefined then
    LoadOffsetNode(AParent, AIndex, ANode, 0, 'TransparencyLUTs', 1, TRANSPARENCY_SIZE_REDUCTION);
end;

end.
