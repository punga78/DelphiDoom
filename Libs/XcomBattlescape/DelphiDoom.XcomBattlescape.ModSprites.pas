{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the sprites of the mod        }
{  (the PCK and TAB files of UNITS, UFOGRAPH and TERRAIN)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.ModSprites;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.Xcom.PckDecoder,
  DelphiDoom.Xcom.Image, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomBattlescape.Sprites.Intf;

type
  /// <summary>
  ///   IXcomBattleSprites on the virtual files of the mods: a set is read the first time it is asked for
  ///   (Mod::loadBattlescapeResources reads them all at the start). The sets of the units and the objects are in
  ///   UNITS, the cursor, the smoke and the explosions in UFOGRAPH, the terrain ones in TERRAIN
  /// </summary>
  TXcomModSprites = class(TInterfacedObject, IXcomBattleSprites)
  strict private
    FFiles: IXcomModFiles;
    FSets: TObjectDictionary<string, TXcomSurfaceSet>;
    FTerrain: TObjectDictionary<string, TXcomSurfaceSet>;
    function LoadSet(const AFolder, AName: string; AWidth, AHeight: Integer): TXcomSurfaceSet;
    function FindSet(const AName: string): TXcomSurfaceSet;
    procedure FixTftdArmor(const ASet: TXcomSurfaceSet; AArmor: Integer);
    procedure FixUfoArmor(const ASet: TXcomSurfaceSet);
  public
    constructor Create(const AFiles: IXcomModFiles);
    destructor Destroy; override;
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    function TerrainFrame(const ADataSetName: string; AIndex: Integer): TXcomSurface;
  end;

implementation

constructor TXcomModSprites.Create(const AFiles: IXcomModFiles);
begin
  inherited Create;
  FFiles := AFiles;
  FSets := TObjectDictionary<string, TXcomSurfaceSet>.Create([doOwnsValues]);
  FTerrain := TObjectDictionary<string, TXcomSurfaceSet>.Create([doOwnsValues]);
end;

destructor TXcomModSprites.Destroy;
begin
  FTerrain.Free;
  FSets.Free;
  inherited Destroy;
end;

function TXcomModSprites.LoadSet(const AFolder, AName: string; AWidth, AHeight: Integer): TXcomSurfaceSet;
var
  LPck: TBytes;
  LTab: TBytes;
  LImages: TArray<TXcomImage>;
  LDecoder: TXcomPckDecoder;
  LImage: TXcomImage;
  LIndex: Integer;
  LBase: string;
begin
  LBase := ChangeFileExt(AName, '');
  LPck := FFiles.LoadBytes(AFolder + '/' + LBase + '.PCK');
  LTab := FFiles.LoadBytes(AFolder + '/' + LBase + '.TAB');
  Result := TXcomSurfaceSet.Create(AWidth, AHeight);
  try
    LDecoder := TXcomPckDecoder.Create;
    try
      LImages := LDecoder.Decode(LPck, LTab, AWidth, AHeight);
    finally
      LDecoder.Free;
    end;
    for LIndex := 0 to High(LImages) do
    begin
      LImage := LImages[LIndex];
      Result.AddImage(LIndex, LImage);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TXcomModSprites.FixTftdArmor(const ASet: TXcomSurfaceSet; AArmor: Integer);
var
  LFrame: TXcomSurface;
  LIndex: Integer;

  procedure Recolor(const AFrame: TXcomSurface; AFirstRow, ALastRow: Integer; AKind: Integer);
  var
    LColumn: Integer;
    LRow: Integer;
    LValue: Byte;
  begin
    for LRow := AFirstRow to Min(ALastRow, AFrame.Height - 1) do
      for LColumn := 0 to AFrame.Width - 1 do
      begin
        LValue := AFrame.GetPixel(LColumn, LRow);
        case AKind of
          // HairXCOM2: the woman's hair color becomes the man's
          0: if (LValue >= 16) and (LValue <= 31) then
               AFrame.SetPixel(LColumn, LRow, 64 + (LValue and 15));
          // FaceXCOM2: the face becomes pink, not to be mixed up with the backpack of the ion armor
          1: if (LValue >= 160) and (LValue <= 175) then
               AFrame.SetPixel(LColumn, LRow, 224 + (LValue and 15));
          // FallXCOM2
          2: if LValue = 151 then
               AFrame.SetPixel(LColumn, LRow, 224 + (LValue and 15) + 2)
             else if (LValue >= 128) and (LValue <= 143) then
               AFrame.SetPixel(LColumn, LRow, 224 + (LValue and 15));
          // BodyXCOM2: the palette of the ion armor
          3: if LValue = 153 then
               AFrame.SetPixel(LColumn, LRow, 128 + 12)
             else if LValue = 151 then
               AFrame.SetPixel(LColumn, LRow, 128 + 10)
             else if LValue = 148 then
               AFrame.SetPixel(LColumn, LRow, 128 + 4)
             else if LValue = 147 then
               AFrame.SetPixel(LColumn, LRow, 128 + 2)
             else if (LValue >= 16) and (LValue <= 31) then
               AFrame.SetPixel(LColumn, LRow, 128 + (LValue and 15));
        end;
      end;
  end;

begin
  // Mod::loadBattlescapeResources: the "fix" of the color indexes of the TFTD armors (Options::battleHairBleach)
  for LIndex := 0 to 15 do
  begin
    // chest frame without helm
    LFrame := ASet.GetFrame(262 + LIndex);
    if not Assigned(LFrame) then
      Continue;
    if LIndex < 8 then
    begin
      // female chest frame
      Recolor(LFrame, 6, 17, 0);
      if AArmor = 2 then
      begin
        // fix some pixels in the ion armor that were overwritten by the previous function
        if LIndex = 0 then
          LFrame.SetPixel(18, 14, 16)
        else if LIndex = 3 then
          LFrame.SetPixel(19, 12, 20)
        else if LIndex = 6 then
          LFrame.SetPixel(13, 14, 16);
      end;
    end;
    Recolor(LFrame, 0, LFrame.Height - 1, 1);
  end;
  for LIndex := 0 to 1 do
  begin
    // fall frame (first and second)
    LFrame := ASet.GetFrame(256 + LIndex);
    if not Assigned(LFrame) then
      Continue;
    Recolor(LFrame, 0, 16, 2);
    Recolor(LFrame, 0, LFrame.Height - 1, 1);
  end;
  // palette fix for the ion armor
  if AArmor = 2 then
    for LIndex in ASet.Indexes do
    begin
      LFrame := ASet.GetFrame(LIndex);
      Recolor(LFrame, 0, LFrame.Height - 1, 3);
    end;
end;

procedure TXcomModSprites.FixUfoArmor(const ASet: TXcomSurfaceSet);
const
  HAIR = 9 shl 4;
  FACE = 6 shl 4;
  SHADE_MAX = 15;
var
  LFrame: TXcomSurface;
  LIndex: Integer;

  // HairXCOM1: the colors of the face above the cutoff become the hair color of the man of XCOM_0.PCK
  procedure Recolor(const AFrame: TXcomSurface; AFirstRow, ALastRow, AFirstColumn, ALastColumn: Integer;
    ACutoff: Byte);
  var
    LColumn: Integer;
    LRow: Integer;
    LValue: Byte;
  begin
    for LRow := AFirstRow to Min(ALastRow, AFrame.Height - 1) do
      for LColumn := AFirstColumn to Min(ALastColumn, AFrame.Width - 1) do
      begin
        LValue := AFrame.GetPixel(LColumn, LRow);
        if (LValue > ACutoff) and (LValue <= FACE + SHADE_MAX) then
          AFrame.SetPixel(LColumn, LRow, Byte(HAIR + (LValue and SHADE_MAX) - 6));
      end;
  end;

begin
  // Mod::loadBattlescapeResources: the personal armor of UFO (XCOM_1.PCK) with Options::battleHairBleach
  for LIndex := 0 to 7 do
  begin
    // chest frame
    LFrame := ASet.GetFrame(4 * 8 + LIndex);
    if not Assigned(LFrame) then
      Continue;
    Recolor(LFrame, 6, 8, 0, LFrame.Width - 1, FACE + 5);
    Recolor(LFrame, 9, 9, 0, LFrame.Width - 1, FACE + 6);
  end;
  for LIndex := 0 to 2 do
  begin
    // fall frame
    LFrame := ASet.GetFrame(264 + LIndex);
    if not Assigned(LFrame) then
      Continue;
    Recolor(LFrame, 0, 23, 11, 19, FACE + 6);
  end;
end;

function TXcomModSprites.FindSet(const AName: string): TXcomSurfaceSet;
var
  LWidth: Integer;
  LHeight: Integer;
  LFolder: string;
  LName: string;
begin
  LWidth := 32;
  LHeight := 40;
  if SameText(AName, 'BIGOBS.PCK') then
    LHeight := 48;
  if SameText(AName, 'X1.PCK') then
  begin
    LWidth := 128;
    LHeight := 64;
  end;
  for LFolder in ['UNITS', 'UFOGRAPH', 'TERRAIN'] do
    try
      Result := LoadSet(LFolder, AName, LWidth, LHeight);
      LName := UpperCase(AName);
      if (Length(LName) = 12) and (Copy(LName, 1, 7) = 'TDXCOM_') and (LName[8] >= '0') and (LName[8] <= '2') then
        FixTftdArmor(Result, Ord(LName[8]) - Ord('0'));
      if LName = 'XCOM_1.PCK' then
        FixUfoArmor(Result);
      Exit;
    except
      // the files of the mod say "not found" with the exception of their own library: any of them means "not here"
      on Exception do
        Continue;
    end;
  Result := nil;
end;

function TXcomModSprites.SurfaceSet(const AName: string): TXcomSurfaceSet;
var
  LKey: string;
begin
  LKey := UpperCase(AName);
  if not FSets.TryGetValue(LKey, Result) then
  begin
    Result := FindSet(LKey);
    if Assigned(Result) then
      FSets.Add(LKey, Result);
  end;
end;

function TXcomModSprites.TerrainFrame(const ADataSetName: string; AIndex: Integer): TXcomSurface;
var
  LSet: TXcomSurfaceSet;
  LKey: string;
begin
  LKey := UpperCase(ADataSetName);
  if not FTerrain.TryGetValue(LKey, LSet) then
  begin
    LSet := LoadSet('TERRAIN', LKey, 32, 40);
    FTerrain.Add(LKey, LSet);
  end;
  Result := LSet.GetFrame(AIndex);
end;

end.
