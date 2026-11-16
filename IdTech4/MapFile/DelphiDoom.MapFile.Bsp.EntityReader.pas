{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: the entities     }
{                                                                              }
{  Written for this library: the entity lump of a BSP is the text of the       }
{  entities of a .map without brushes, so it is read with the reader of the    }
{  .map (the original parses it with COM_Parse in R_LoadEntities and          }
{  CM_EntityString). Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.EntityReader;

interface

uses
  System.Generics.Collections, DelphiDoom.MapFile.Entity;

type
  /// <summary>
  ///   Reads the text of the entities lump into the entities of the map file model (key/value
  ///   pairs in a TIdDict, keys without capitals as in a .map). The caller owns the list
  /// </summary>
  TBspEntityReader = class
  public
    /// <summary>
    ///   An entity text that is not valid (a brace that is not closed, a missing value...)
    ///   raises EBspFileException with the message of the lexer
    /// </summary>
    class function Parse(const AText: AnsiString): TObjectList<TMapEntity>; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.IdLib.Text.Types, DelphiDoom.MapFile.EntityReader, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.MapFile.Types;

const
  ENTITY_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES;

class function TBspEntityReader.Parse(const AText: AnsiString): TObjectList<TMapEntity>;
var
  LLexer: TIdLexer;
  LEntity: TMapEntity;
begin
  Result := TObjectList<TMapEntity>.Create(True);
  try
    LLexer := TIdLexer.Create(ENTITY_LEXER_FLAGS, nil, nil);
    try
      if not LLexer.LoadMemory(AText, 'entities') then
        Exit;
      repeat
        LEntity := TMapEntityReader.Parse(LLexer, CURRENT_MAP_VERSION);
        if Assigned(LEntity) then
          Result.Add(LEntity);
      until not Assigned(LEntity);
    finally
      LLexer.Free;
    end;
  except
    on E: EIdLibException do
    begin
      Result.Free;
      raise EBspFileException.Create(E.Message);
    end;
    else
    begin
      Result.Free;
      raise;
    end;
  end;
end;

end.
