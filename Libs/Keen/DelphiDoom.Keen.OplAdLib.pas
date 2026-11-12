{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the AdLib card on the OPL2 emulator of Libs\Opl   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.OplAdLib;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf, DelphiDoom.Opl.Intf;

const
  /// <summary>The clock of the YM3812 of an AdLib card, in Hz</summary>
  KEEN_ADLIB_CLOCK = 3579545;

type
  /// <summary>
  ///   The AdLib card of the game: what alOut writes goes to a YM3812 of Libs\Opl, and the chip gives the samples.
  ///   The delays of alOut (SDL_Delay) are for the real card and are not here
  /// </summary>
  TKeenOplAdLib = class(TInterfacedObject, IKeenAdLibPort, IKeenSampleSource)
  strict private
    FChip: IOplChip;
    FScratch: TArray<SmallInt>;
    FWrites: Int64;
  public
    /// <param name="AChip">A YM3812 made for the rate of the mixer</param>
    constructor Create(const AChip: IOplChip);
    procedure Write(ARegister, AValue: Byte);
    procedure AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
    /// <summary>How many registers were written since the card was made</summary>
    property Writes: Int64 read FWrites;
  end;

implementation

{ TKeenOplAdLib }

constructor TKeenOplAdLib.Create(const AChip: IOplChip);
begin
  inherited Create;
  if not Assigned(AChip) then
    raise EArgumentNilException.Create('AChip');
  FChip := AChip;
end;

procedure TKeenOplAdLib.Write(ARegister, AValue: Byte);
begin
  FChip.WriteRegister(ARegister, AValue);
  Inc(FWrites);
end;

procedure TKeenOplAdLib.AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
var
  LIndex: Integer;
begin
  if ACount <= 0 then
    Exit;
  if Length(FScratch) < ACount then
    SetLength(FScratch, ACount);
  FChip.GenerateSamples(FScratch, ACount);
  for LIndex := 0 to ACount - 1 do
    Inc(ABuffer[LIndex], FScratch[LIndex]);
end;

end.
