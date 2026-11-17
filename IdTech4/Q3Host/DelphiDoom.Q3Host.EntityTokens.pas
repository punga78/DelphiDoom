{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the entity tokens of the map           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): G_GET_ENTITY_   }
{  TOKEN of sv_game.c (sv.entityParsePoint). Copyright (C) 1999-2005 Id        }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.EntityTokens;

interface

uses
  DelphiDoom.Models.Q3Player.TokenReader, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   COM_Parse over the entity string of the map, one word at a time: what the module reads to spawn the
  ///   entities. It starts again from the beginning when the map changes or on Rewind (SV_SpawnServer)
  /// </summary>
  TQ3EntityTokens = class
  strict private
    FClipMap: IQ3HostClipMap;
    FReader: TQ3TokenReader;
    FText: AnsiString;
  public
    constructor Create(const AClipMap: IQ3HostClipMap);
    destructor Destroy; override;
    procedure Rewind;
    /// <summary>
    ///   The next word; False only when the text has ended and the word is empty (the C returns qfalse when
    ///   entityParsePoint is NULL and the token empty). Without a map the text is empty
    /// </summary>
    function Next(out AToken: AnsiString): Boolean;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Intf;

constructor TQ3EntityTokens.Create(const AClipMap: IQ3HostClipMap);
begin
  inherited Create;
  FClipMap := AClipMap;
end;

destructor TQ3EntityTokens.Destroy;
begin
  FReader.Free;
  inherited Destroy;
end;

procedure TQ3EntityTokens.Rewind;
begin
  FReader.Free;
  FReader := nil;
end;

function TQ3EntityTokens.Next(out AToken: AnsiString): Boolean;
var
  LText: AnsiString;
begin
  LText := '';
  if Assigned(FClipMap.Model) then
    LText := FClipMap.Model.EntityString;
  // a new map (or a map seen for the first time) is read from its start
  if (not Assigned(FReader)) or (LText <> FText) then
  begin
    FReader.Free;
    FText := LText;
    FReader := TQ3TokenReader.Create(FText);
  end;
  AToken := FReader.Next;
  Result := not (FReader.Ended and (AToken = ''));
end;

end.
