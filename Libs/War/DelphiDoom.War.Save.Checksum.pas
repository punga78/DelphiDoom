{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the checksum of a saved game                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Save.Checksum;

// the multiplication of the hash wraps around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>FNV-1a over 32 bits: it finds a file that was cut or changed, it is not a protection</summary>
  TWarSaveChecksum = class
  public
    /// <summary>The hash of the first ACount bytes of ABytes</summary>
    class function Compute(const ABytes: TBytes; ACount: Integer): Cardinal; static;
  end;

implementation

{ TWarSaveChecksum }

class function TWarSaveChecksum.Compute(const ABytes: TBytes; ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := $811C9DC5;
  for LIndex := 0 to ACount - 1 do
    Result := (Result xor ABytes[LIndex]) * 16777619;
end;

end.
