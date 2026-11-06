{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UDMF library - a fake for the numbers of the sounds }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.Sounds;

interface

uses
  DelphiDoom.Udmf.Intf;

type
  /// <summary>
  ///   The number of a sound is 1000 times its length plus the first letter: the old converter
  ///   that made the wads of the tests had the same fake
  /// </summary>
  TFakeSounds = class(TInterfacedObject, IUdmfSoundResolver)
  public
    Calls: Integer;
    function NumberOf(const AName: string): Integer;
  end;

implementation

{ TFakeSounds }

function TFakeSounds.NumberOf(const AName: string): Integer;
begin
  Inc(Calls);
  if AName = '' then
    Result := 0
  else
    Result := Length(AName) * 1000 + Ord(AName[1]);
end;

end.
