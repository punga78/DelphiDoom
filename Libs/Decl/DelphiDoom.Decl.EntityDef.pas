{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclEntityDef, "entityDef" and "mapDef"  }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclEntityDef.h, DeclEntityDef.cpp. Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.EntityDef;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base, DelphiDoom.Scanner.IdDict;

type
  /// <summary>An entity definition: a dictionary of keys and values, "inherit" already resolved (idDeclEntityDef)</summary>
  IDeclEntityDef = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0012}']
    /// <summary>The key/value pairs, the inherited ones included (the object is owned by the declaration)</summary>
    function GetDict: TIdDict;
  end;

  /// <summary>
  ///   <c>entityDef name { "key" "value" ... }</c>. Every pair is two tokens (the key must be a quoted string); a
  ///   <c>classname</c> key with the name of the decl is added; each "inherit" key copies the keys of another
  ///   entityDef that are not set here. An entityDef is parsed once, so a cycle of inherits stops where it
  ///   closes (the second decl to ask for the first one finds it as it is, the keys it has so far).
  /// </summary>
  TDeclEntityDef = class(TDecl, IDeclEntityDef)
  strict private
    FDict: TIdDict;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetBase(const ABase: IDeclBase); override;
    function GetDict: TIdDict;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
    /// <summary>Dumps all key/value pairs, including inherited ones, to the log</summary>
    procedure Print; override;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types;

{ TDeclEntityDef }

constructor TDeclEntityDef.Create;
begin
  inherited Create;
  FDict := TIdDict.Create;
end;

destructor TDeclEntityDef.Destroy;
begin
  FDict.Free;
  inherited Destroy;
end;

procedure TDeclEntityDef.SetBase(const ABase: IDeclBase);
begin
  inherited SetBase(ABase);
  if Assigned(ABase) then
  begin
    // the dictionary writes its warnings and its Print to the log of the manager
    FDict.Free;
    FDict := TIdDict.Create(ABase.GetLog);
  end;
end;

function TDeclEntityDef.GetDict: TIdDict;
begin
  Result := FDict;
end;

function TDeclEntityDef.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclEntityDef.FreeData;
begin
  FDict.Clear;
end;

function TDeclEntityDef.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'"DEFAULTED"'#9'"1"'#10'}';
end;

procedure TDeclEntityDef.Print;
begin
  FDict.Print;
end;

function TDeclEntityDef.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken, LToken2: TIdToken;
  LKeyValue: TIdKeyValue;
  LExisting: TIdKeyValue;
  LIndex: Integer;
  LDefinitions: TList<IDeclEntityDef>;
  LCopy: IDecl;
  LInherited: IDeclEntityDef;
  LFinder: IDeclFinder;
begin
  LSource := OpenLexer(AText);
  try
    while True do
    begin
      if not LSource.ReadToken(LToken) then
        Break;
      if TIdStrings.Icmp(LToken.Text, '}') = 0 then
        Break;
      if LToken.TokenType <> TT_STRING then
      begin
        LSource.Warning('Expected quoted string, but found ''%s''', [string(LToken.Text)]);
        MakeDefault;
        Exit(False);
      end;

      if not LSource.ReadToken(LToken2) then
      begin
        LSource.Warning('Unexpected end of file', []);
        MakeDefault;
        Exit(False);
      end;

      if FDict.FindKey(LToken.Text, LExisting) then
        LSource.Warning('''%s'' already defined', [string(LToken.Text)]);
      FDict.SetValue(LToken.Text, LToken2.Text);
    end;

    // we always automatically set a "classname" key to our name
    FDict.SetValue('classname', GetName);

    // "inherit" keys will cause all values from another entityDef to be copied into this one if they don't
    // conflict. Find all of the dicts first, because copying inherited values will modify the dict.
    LFinder := GetFinder;
    LDefinitions := TList<IDeclEntityDef>.Create;
    try
      while True do
      begin
        LIndex := FDict.MatchPrefix('inherit', -1);
        if LIndex < 0 then
          Break;
        FDict.TryGetKeyVal(LIndex, LKeyValue);

        LCopy := LFinder.FindType(DECL_ENTITYDEF, LKeyValue.Value, False);
        if not Supports(LCopy, IDeclEntityDef, LInherited) then
          LSource.Warning('Unknown entityDef ''%s'' inherited by ''%s''', [string(LKeyValue.Value), string(GetName)])
        else
          LDefinitions.Add(LInherited);

        // delete this key/value pair
        FDict.Delete(LKeyValue.Key);
      end;

      // now copy over the inherited key / value pairs
      for LInherited in LDefinitions do
        FDict.SetDefaults(LInherited.GetDict);
    finally
      LDefinitions.Free;
    end;
    // The original also asks the game to precache the media the keys name (game->CacheDictionaryMedia):
    // that belongs to the game and is not here.
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
