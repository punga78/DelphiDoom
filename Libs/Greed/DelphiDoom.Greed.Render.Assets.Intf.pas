{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the renderer reads from the data file       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the lumpcache of d_disk.pas }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.Assets.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The lumps that the renderer draws with. The arrays that it returns are kept by the object for its whole life
  ///   (the renderer holds pointers into them), and are a few bytes longer than the lump (zeros) so that a post that
  ///   reads a little past its end does not leave the memory. An empty array is a lump that is not there
  /// </summary>
  IGreedRenderAssets = interface
    ['{8D2B1F46-C7A3-4E50-91B8-3A6F05D4E7C2}']
    /// <summary>numwalls: the lumps between startwalls and endwalls (the first wall is number 1)</summary>
    function GetWallCount: Integer;
    /// <summary>numflats</summary>
    function GetFlatCount: Integer;
    /// <summary>The lump walllump + AIndex</summary>
    function WallLump(AIndex: Integer): TBytes;
    /// <summary>The lump flatlump + AIndex (4096 bytes of pixels)</summary>
    function FlatLump(AIndex: Integer): TBytes;
    /// <summary>The lump of a sprite, by its number in the archive (the picture of a sprite is an absolute lump)</summary>
    function SpriteLump(ALump: Integer): TBytes;
    /// <summary>The "lights" lump: the color tables of the light, 256 bytes each</summary>
    function ColorMaps: TBytes;
    /// <summary>The "transparency" lump: 256 tables of 256 bytes</summary>
    function Transparency: TBytes;
    /// <summary>The sky: 256 x 256 pixels, 65536 bytes</summary>
    function Backdrop: TBytes;
    property WallCount: Integer read GetWallCount;
    property FlatCount: Integer read GetFlatCount;
  end;

implementation

end.
