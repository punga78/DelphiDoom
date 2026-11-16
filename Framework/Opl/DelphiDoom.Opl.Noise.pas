{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - the white noise of the rhythm section    }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  See DelphiDoom.Opl.Types for the copyright notice                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Noise;

interface

uses
  DelphiDoom.Opl.Intf;

type
  /// <summary>
  ///   rand() of the Windows C runtime (the generator OpenXcom gets from MinGW and MSVC): seed * 214013 + 2531011,
  ///   the bits 16..30 of the result. The chip only uses the lowest bit of each value. The C library has one global
  ///   sequence; here each noise source is its own sequence, starting from the seed given (srand(1) is the default
  ///   of the C library)
  /// </summary>
  TOplMsvcrtNoise = class(TInterfacedObject, IOplNoiseSource)
  strict private
    FSeed: Cardinal;
  public
    constructor Create(ASeed: Cardinal = 1);
    function NextBit: Integer;
  end;

implementation

{$Q-}
{$R-}

{ TOplMsvcrtNoise }

constructor TOplMsvcrtNoise.Create(ASeed: Cardinal);
begin
  inherited Create;
  FSeed := ASeed;
end;

function TOplMsvcrtNoise.NextBit: Integer;
begin
  // the multiplication wraps around at 32 bit, as the unsigned arithmetic of the C does
  FSeed := FSeed * 214013 + 2531011;
  Result := Integer((FSeed shr 16) and $7FFF) and 1;
end;

end.
