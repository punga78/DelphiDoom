{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sprites of the interface from DATA.WAR        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_sprites.c (wspr_createSpriteFromResource   }
{  and wspr_createSpriteFromResourceIndex), (c) 2019 Alejandro Coto Gutierrez, }
{  zlib License (see Games\War\LICENSE-war1.txt). This is an altered version,  }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SpriteLoader;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   Makes the sprite of a record of DATA.WAR with what the catalog says it is: an image and a cursor are one frame
  ///   whose texture is already filled, a sprite record has its frames and an empty texture. The records are decoded
  ///   each time (the cache of the interface asks once for each frame)
  /// </summary>
  TWarUiSpriteLoader = class(TInterfacedObject, IWarUiSprites)
  strict private
    FGraphics: IWarGraphics;
    FCatalog: IWarCatalog;
  public
    constructor Create(const AGraphics: IWarGraphics; const ACatalog: IWarCatalog);
    function CreateSprite(AResourceIndex: Integer): IWarUiSprite;
    procedure CursorHotspot(AResourceIndex: Integer; out AX, AY: Integer);
  end;

implementation

uses
  DelphiDoom.War.Sprite.Sheet, DelphiDoom.War.Ui.Sprite;

{ TWarUiSpriteLoader }

constructor TWarUiSpriteLoader.Create(const AGraphics: IWarGraphics; const ACatalog: IWarCatalog);
begin
  inherited Create;
  FGraphics := AGraphics;
  FCatalog := ACatalog;
end;

function TWarUiSpriteLoader.CreateSprite(AResourceIndex: Integer): IWarUiSprite;
begin
  case FCatalog.RecordTypeOf(AResourceIndex) of
    wrtImage:
      Result := TWarUiSprite.Create(TWarSpriteSheet.FromImage(FGraphics.GetImage(AResourceIndex)), True);
    wrtCursor:
      Result := TWarUiSprite.Create(TWarSpriteSheet.FromCursor(FGraphics.GetCursor(AResourceIndex)), True);
    wrtSprite:
      Result := TWarUiSprite.Create(TWarSpriteSheet.FromSprite(FGraphics.GetSprite(AResourceIndex), nil), False);
  else
    raise EWarException.CreateFmt(SWarUiResourceType, [AResourceIndex]);
  end;
end;

procedure TWarUiSpriteLoader.CursorHotspot(AResourceIndex: Integer; out AX, AY: Integer);
var
  LCursor: TWarCursor;
begin
  LCursor := FGraphics.GetCursor(AResourceIndex);
  AX := LCursor.HotX;
  AY := LCursor.HotY;
end;

end.
