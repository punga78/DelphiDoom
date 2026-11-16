{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the corrections of the data of the game          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): FixLump of g_fixlump.pas    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LumpFixes;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf;

type
  /// <summary>A lump of a size and CRC32 that is replaced by other bytes</summary>
  TGreedLumpFix = record
    Size: Integer;
    Crc32: Cardinal;
    Replacement: TBytes;
  end;

  /// <summary>
  ///   The corrections of the data as a table: a lump with that size and that CRC32 is replaced. The CRC32 is
  ///   calculated only for the lumps that have the size of an entry, as the original does
  /// </summary>
  TGreedLumpFixes = class(TInterfacedObject, IGreedLumpFixes)
  strict private
    FFixes: TArray<TGreedLumpFix>;
  public
    constructor Create(const AFixes: array of TGreedLumpFix);
    /// <summary>The table of the original: the sprite "pst" of 10463 bytes (CRC32 $48818333)</summary>
    class function CreateDefault: IGreedLumpFixes; static;
    function Apply(const ALump: TBytes): TBytes;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.Greed.PstCorrection;

{ TGreedLumpFixes }

constructor TGreedLumpFixes.Create(const AFixes: array of TGreedLumpFix);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FFixes, Length(AFixes));
  for LIndex := 0 to High(AFixes) do
    FFixes[LIndex] := AFixes[LIndex];
end;

class function TGreedLumpFixes.CreateDefault: IGreedLumpFixes;
var
  LFix: TGreedLumpFix;
begin
  LFix.Size := Length(GREED_PST_CORRECTED);
  LFix.Crc32 := $48818333;
  SetLength(LFix.Replacement, Length(GREED_PST_CORRECTED));
  Move(GREED_PST_CORRECTED[0], LFix.Replacement[0], Length(GREED_PST_CORRECTED));
  Result := TGreedLumpFixes.Create([LFix]);
end;

function TGreedLumpFixes.Apply(const ALump: TBytes): TBytes;
var
  LFix: TGreedLumpFix;
  LCrc: Cardinal;
  LCrcKnown: Boolean;
begin
  LCrcKnown := False;
  LCrc := 0;
  for LFix in FFixes do
    if (Length(ALump) > 0) and (Length(ALump) = LFix.Size) then
    begin
      if not LCrcKnown then
      begin
        LCrc := TCrc32.Calculate(ALump[0], Length(ALump));
        LCrcKnown := True;
      end;
      if LCrc = LFix.Crc32 then
        Exit(Copy(LFix.Replacement));
    end;
  Result := ALump;
end;

end.
