{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the sectors                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.SectorFormat;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>
  ///   The sectors. What changes from a game to another is in the extra record: the panning of
  ///   the floor and of the ceiling (Doom and Strife) and the number of the sound (all but Hexen).
  ///   A key that the game does not have is not known
  /// </summary>
  TUdmfSectorFormat = class(TInterfacedObject, IUdmfSectorFormat)
  private
    FLayout: TUdmfSectorLayout;
    FSounds: IUdmfSoundResolver;
    function ReadName(const AReader: IUdmfValueReader): TUdmfName8;
    procedure ReadMoreIds(const AReader: IUdmfValueReader; var ASector: TUdmfSector);
  public
    /// <param name="ASounds">Gives the number of a sound; it may be nil when the layout has no sound</param>
    constructor Create(const ALayout: TUdmfSectorLayout; const ASounds: IUdmfSoundResolver);
    procedure Reset(var ASector: TUdmfSector);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ASector: TUdmfSector): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
  end;

implementation

uses
  DelphiDoom.Udmf.Text;

{ TUdmfSectorFormat }

constructor TUdmfSectorFormat.Create(const ALayout: TUdmfSectorLayout;
  const ASounds: IUdmfSoundResolver);
begin
  inherited Create;
  FLayout := ALayout;
  FSounds := ASounds;
end;

procedure TUdmfSectorFormat.Reset(var ASector: TUdmfSector);
begin
  ASector := Default(TUdmfSector);
  ASector.LightLevel := 160;
  ASector.Gravity := FRACUNIT;
end;

function TUdmfSectorFormat.ReadName(const AReader: IUdmfValueReader): TUdmfName8;
var
  LToken: string;
begin
  LToken := AReader.ReadToken;
  if Length(LToken) > 8 then
    AReader.Warn(Format('TUdmfSectorFormat: the name "%s" is longer than 8 characters and is cut'#13#10,
      [LToken]));
  Result := TUdmfText.ToName8(LToken);
end;

procedure TUdmfSectorFormat.ReadMoreIds(const AReader: IUdmfValueReader; var ASector: TUdmfSector);
var
  LId: Integer;
begin
  for LId in AReader.ReadIntegerList do
    if (LId >= 0) and (LId <= 255) then
      Include(ASector.MoreIds, Byte(LId));
end;

function TUdmfSectorFormat.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var ASector: TUdmfSector): Boolean;
var
  LValue: Integer;
begin
  Result := True;
  if AKey = 'HEIGHTFLOOR' then
    ASector.FloorHeight := Round(AReader.ReadFloat)
  else if AKey = 'HEIGHTCEILING' then
    ASector.CeilingHeight := Round(AReader.ReadFloat)
  else if AKey = 'TEXTUREFLOOR' then
    ASector.FloorPic := ReadName(AReader)
  else if AKey = 'TEXTURECEILING' then
    ASector.CeilingPic := ReadName(AReader)
  else if AKey = 'LIGHTLEVEL' then
    ASector.LightLevel := AReader.ReadInteger
  else if AKey = 'SPECIAL' then
    ASector.Special := AReader.ReadInteger
  else if AKey = 'ID' then
  begin
    LValue := AReader.ReadInteger;
    ASector.Tag := LValue;
    if (LValue >= 0) and (LValue <= 255) then
      Include(ASector.MoreIds, Byte(LValue));
  end
  else if AKey = 'MOREIDS' then
    ReadMoreIds(AReader, ASector)
  else if FLayout.HasPanning and (AKey = 'XPANNINGFLOOR') then
    ASector.XPanningFloor := Round(AReader.ReadFloat * FRACUNIT)
  else if FLayout.HasPanning and (AKey = 'YPANNINGFLOOR') then
    ASector.YPanningFloor := Round(AReader.ReadFloat * FRACUNIT)
  else if FLayout.HasPanning and (AKey = 'XPANNINGCEILING') then
    ASector.XPanningCeiling := Round(AReader.ReadFloat * FRACUNIT)
  else if FLayout.HasPanning and (AKey = 'YPANNINGCEILING') then
    ASector.YPanningCeiling := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'ROTATIONFLOOR' then
    ASector.RotationFloor := Cardinal(Round(AReader.ReadFloat * ANG1))
  else if AKey = 'ROTATIONFLOORX' then
    ASector.RotationFloorX := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'ROTATIONFLOORY' then
    ASector.RotationFloorY := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'ROTATIONCEILING' then
    ASector.RotationCeiling := Cardinal(Round(AReader.ReadFloat * ANG1))
  else if AKey = 'ROTATIONCEILINGX' then
    ASector.RotationCeilingX := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'ROTATIONCEILINGY' then
    ASector.RotationCeilingY := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'GRAVITY' then
    ASector.Gravity := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'CEILINGPLANE_A' then
  begin
    ASector.CeilingPlane[0] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_CEILINGPLANE_A;
  end
  else if AKey = 'CEILINGPLANE_B' then
  begin
    ASector.CeilingPlane[1] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_CEILINGPLANE_B;
  end
  else if AKey = 'CEILINGPLANE_C' then
  begin
    ASector.CeilingPlane[2] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_CEILINGPLANE_C;
  end
  else if AKey = 'CEILINGPLANE_D' then
  begin
    ASector.CeilingPlane[3] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_CEILINGPLANE_D;
  end
  else if AKey = 'FLOORPLANE_A' then
  begin
    ASector.FloorPlane[0] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_FLOORPLANE_A;
  end
  else if AKey = 'FLOORPLANE_B' then
  begin
    ASector.FloorPlane[1] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_FLOORPLANE_B;
  end
  else if AKey = 'FLOORPLANE_C' then
  begin
    ASector.FloorPlane[2] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_FLOORPLANE_C;
  end
  else if AKey = 'FLOORPLANE_D' then
  begin
    ASector.FloorPlane[3] := AReader.ReadFloat;
    ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_FLOORPLANE_D;
  end
  else if AKey = 'RIPPLECEILING' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_RIPPLECEILING;
  end
  else if AKey = 'RIPPLEFLOOR' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_RIPPLEFLOOR;
  end
  else if AKey = 'FOG' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_FOG;
  end
  else if AKey = 'HIDDEN' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_HIDDEN;
  end
  else if AKey = 'NOJUMP' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_NOJUMP;
  end
  else if AKey = 'NOCROUCH' then
  begin
    if AReader.ReadIsTrue then
      ASector.ExtraFlags := ASector.ExtraFlags or UDMF_SF_NOCROUCH;
  end
  else if FLayout.HasSound and (AKey = 'SOUND') then
    ASector.Sound := FSounds.NumberOf(AReader.ReadToken)
  else if AKey = 'WINDTHRUST' then
    ASector.WindThrust := Round(AReader.ReadFloat * 2048)
  else if AKey = 'WINDANGLE' then
    ASector.WindAngle := Cardinal(Round(AReader.ReadFloat * ANG1))
  else if AKey = 'COMMENT' then
    AReader.ReadToken
  else
    Result := False;
end;

function TUdmfSectorFormat.GetBaseSize: Integer;
begin
  Result := 26;
end;

function TUdmfSectorFormat.GetExtraSize: Integer;
begin
  // flags, the two heights, 6 rotations, gravity, 8 plane numbers, the ids (32 bytes), wind
  Result := 4 * 3 + 4 * 6 + 4 + 4 * 8 + 32 + 4 * 2;
  if FLayout.HasPanning then
    Inc(Result, 16);
  if FLayout.HasSound then
    Inc(Result, 4);
end;

procedure TUdmfSectorFormat.WriteBase(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt16(ASector.FloorHeight);
  AWriter.WriteInt16(ASector.CeilingHeight);
  AWriter.WriteName8(ASector.FloorPic);
  AWriter.WriteName8(ASector.CeilingPic);
  AWriter.WriteInt16(ASector.LightLevel);
  AWriter.WriteInt16(ASector.Special);
  AWriter.WriteInt16(ASector.Tag);
end;

procedure TUdmfSectorFormat.WriteExtra(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
var
  LIndex: Integer;
begin
  AWriter.WriteInt32(ASector.ExtraFlags);
  AWriter.WriteInt32(ASector.ExtraFloorHeight);
  AWriter.WriteInt32(ASector.ExtraCeilingHeight);
  if FLayout.HasPanning then
  begin
    AWriter.WriteInt32(ASector.XPanningFloor);
    AWriter.WriteInt32(ASector.YPanningFloor);
    AWriter.WriteInt32(ASector.XPanningCeiling);
    AWriter.WriteInt32(ASector.YPanningCeiling);
  end;
  AWriter.WriteCardinal(ASector.RotationFloor);
  AWriter.WriteInt32(ASector.RotationFloorX);
  AWriter.WriteInt32(ASector.RotationFloorY);
  AWriter.WriteCardinal(ASector.RotationCeiling);
  AWriter.WriteInt32(ASector.RotationCeilingX);
  AWriter.WriteInt32(ASector.RotationCeilingY);
  AWriter.WriteInt32(ASector.Gravity);
  for LIndex := 0 to 3 do
    AWriter.WriteSingle(ASector.CeilingPlane[LIndex]);
  for LIndex := 0 to 3 do
    AWriter.WriteSingle(ASector.FloorPlane[LIndex]);
  AWriter.WriteMoreIds(ASector.MoreIds);
  if FLayout.HasSound then
    AWriter.WriteInt32(ASector.Sound);
  AWriter.WriteInt32(ASector.WindThrust);
  AWriter.WriteCardinal(ASector.WindAngle);
end;

end.