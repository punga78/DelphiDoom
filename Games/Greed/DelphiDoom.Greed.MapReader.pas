{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - reads a map                                      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DoLoadMapData of utils.pas  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MapReader;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The 18 planes follow one another with no header (DoLoadMapData reads 4096 bytes 18 times). The
  ///   fixes that LoadNewMap then makes to the tables of the game (a floor or ceiling 0 becomes 56) belong to the
  ///   game, not to the file, and are not done here
  /// </summary>
  TGreedMapReader = class(TInterfacedObject, IGreedMapReader)
  public
    function Read(const ABytes: TBytes): IGreedMap;
  end;

implementation

uses
  DelphiDoom.Greed.Map;

{ TGreedMapReader }

function TGreedMapReader.Read(const ABytes: TBytes): IGreedMap;
begin
  Result := TGreedMap.Create(ABytes);
end;

end.
