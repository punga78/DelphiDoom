{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the video memory of the EGA                       }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.EgaMemory;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The video memory of the game: 4 planes (blue, green, red, intensity) of 64 KB, written at the same
  ///   offset by one instruction of the EGA. An offset wraps at 64 KB like the 16 bit offset of the C (the
  ///   floating screens of ID_RF go round the end of the memory). The write modes, the map mask and the latches
  ///   of the card are not state here: each operation of the video manager says what it does to the planes
  /// </summary>
  TKeenEgaMemory = class(TInterfacedObject, IKeenEgaMemory)
  strict private
    FPlanes: array[0..KEEN_EGA_PLANES - 1] of TBytes;
  public
    constructor Create;
    function ReadByte(APlane, AOffset: Integer): Byte;
    procedure WriteByte(APlane, AOffset: Integer; AValue: Byte);
    procedure CopyByte(ASourceOffset, ADestOffset: Integer);
    procedure Fill(AColor: Byte);
    function PlaneBytes(APlane: Integer): TBytes;
  end;

implementation

{ TKeenEgaMemory }

constructor TKeenEgaMemory.Create;
var
  LPlane: Integer;
begin
  inherited Create;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    SetLength(FPlanes[LPlane], KEEN_EGA_PLANE_BYTES);
end;

function TKeenEgaMemory.ReadByte(APlane, AOffset: Integer): Byte;
begin
  Result := FPlanes[APlane][AOffset and $FFFF];
end;

procedure TKeenEgaMemory.WriteByte(APlane, AOffset: Integer; AValue: Byte);
begin
  FPlanes[APlane][AOffset and $FFFF] := AValue;
end;

procedure TKeenEgaMemory.CopyByte(ASourceOffset, ADestOffset: Integer);
var
  LPlane: Integer;
  LLatch: array[0..KEEN_EGA_PLANES - 1] of Byte;
begin
  // the read loads the four latches, the write (mode 1, map mask 15) puts them in the four planes
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    LLatch[LPlane] := FPlanes[LPlane][ASourceOffset and $FFFF];
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    FPlanes[LPlane][ADestOffset and $FFFF] := LLatch[LPlane];
end;

procedure TKeenEgaMemory.Fill(AColor: Byte);
var
  LPlane: Integer;
begin
  // write mode 2: the plane gets $FF or $00 for each bit of the color
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    if ((AColor shr LPlane) and 1) <> 0 then
      FillChar(FPlanes[LPlane][0], KEEN_EGA_PLANE_BYTES, $FF)
    else
      FillChar(FPlanes[LPlane][0], KEEN_EGA_PLANE_BYTES, 0);
end;

function TKeenEgaMemory.PlaneBytes(APlane: Integer): TBytes;
begin
  Result := Copy(FPlanes[APlane]);
end;

end.
