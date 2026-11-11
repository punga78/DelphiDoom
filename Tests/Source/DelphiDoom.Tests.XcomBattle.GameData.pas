{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom battle library - where the parity fixtures    }
{  find the data of each game (TFTD with the mod xcom2, UFO with xcom1)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.GameData;

interface

type
  /// <summary>
  ///   The names that change between the two games in the fixtures that compare the library with the harnesses of
  ///   Tools\Verifica\176\battle: the golden of Mod::loadAll, LOFTEMPS.DAT, the folder of the scenarios and the
  ///   environment variable that gives another folder
  /// </summary>
  TXcomTestGame = class
  public
    class function Golden(AUfo: Boolean): string; static;
    /// <summary>LOFTEMPS.DAT relative to the folder above Reference</summary>
    class function Loftemps(AUfo: Boolean): string; static;
    /// <summary>The folder under Tests\Data\XcomBattle: the name for TFTD, the name plus "ufo" for UFO</summary>
    class function ScenarioFolder(const AName: string; AUfo: Boolean): string; static;
    /// <summary>The environment variable: the name for TFTD, the name plus "UFO" for UFO</summary>
    class function FolderVariable(const AName: string; AUfo: Boolean): string; static;
  end;

implementation

class function TXcomTestGame.Golden(AUfo: Boolean): string;
begin
  if AUfo then
    Result := 'ufo.xcom1.golden.txt'
  else
    Result := 'tftd.xcom2.golden.txt';
end;

class function TXcomTestGame.Loftemps(AUfo: Boolean): string;
begin
  if AUfo then
    Result := 'Reference\_dati\xcom_ufo\UFO Enemy Unkown\DOS game\GEODATA\LOFTEMPS.DAT'
  else
    Result := 'Reference\_dati\xcom_tftd\TFTD\TERRAIN\LOFTEMPS.DAT';
end;

class function TXcomTestGame.ScenarioFolder(const AName: string; AUfo: Boolean): string;
begin
  Result := AName;
  if AUfo then
    Result := Result + 'ufo';
end;

class function TXcomTestGame.FolderVariable(const AName: string; AUfo: Boolean): string;
begin
  Result := AName;
  if AUfo then
    Result := Result + 'UFO';
end;

end.
