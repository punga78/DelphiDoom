{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of zlib - compressed streams written by hand              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Streams;

// The streams follow the specifications, not the code under test: RFC 1951
// (a stored block: BFINAL = 1, BTYPE = 00, LEN, NLEN, the bytes), RFC 1950
// (header 78 01, Adler-32 of "abc" = 024D0127) and RFC 1952 (header 1F 8B 08,
// CRC-32 of "abc" = 352441C2, size 3)

interface

uses
  System.SysUtils;

type
  TZlibTestStreams = class
  public
    /// <summary>"abc" in the zlib format</summary>
    class function ZlibOfAbc: TBytes; static;
    /// <summary>"abc" in the gzip format</summary>
    class function GzipOfAbc: TBytes; static;
    /// <summary>A zlib header with FDICT (78 BB) and a dictionary id: inflate stops at once</summary>
    class function ZlibThatNeedsADictionary: TBytes; static;
  end;

implementation

{ TZlibTestStreams }

class function TZlibTestStreams.ZlibOfAbc: TBytes;
begin
  Result := TBytes.Create($78, $01, $01, $03, $00, $FC, $FF, $61, $62, $63,
    $02, $4D, $01, $27);
end;

class function TZlibTestStreams.GzipOfAbc: TBytes;
begin
  Result := TBytes.Create($1F, $8B, $08, $00, $00, $00, $00, $00, $00, $FF,
    $01, $03, $00, $FC, $FF, $61, $62, $63,
    $C2, $41, $24, $35, $03, $00, $00, $00);
end;

class function TZlibTestStreams.ZlibThatNeedsADictionary: TBytes;
begin
  Result := TBytes.Create($78, $BB, $00, $00, $00, $01, $03, $00);
end;

end.
