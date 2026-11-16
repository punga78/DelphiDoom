{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the spawner asks of the pictures            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DemandLoadMonster of        }
{  spawn.pas                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Spawner.Intf;

interface

type
  /// <summary>
  ///   The pictures of the sprites that the spawner asks for before they are drawn. In the original
  ///   DemandLoadMonster(lump, num) does nothing if the first lump is already in memory, otherwise it loads the num
  ///   lumps from lump on and turns the colour 255 of their columns into 0 (see TGreedMonsterPictureFix): who keeps
  ///   the lumps of the sprites does the same
  /// </summary>
  IGreedSpritePictures = interface
    ['{7E2B94C1-0D5A-4F63-B8A7-53C1E9D06F2A}']
    /// <summary>ALump is the absolute number of the first lump, ACount how many lumps follow it</summary>
    procedure DemandLoadMonster(ALump, ACount: Integer);
  end;

implementation

end.
