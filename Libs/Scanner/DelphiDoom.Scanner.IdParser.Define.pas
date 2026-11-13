{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdParserDefine, a macro of the idTech 4      }
{  parser                                                                      }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): define_t of idlib\Parser.h.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser.Define;

interface

uses
  DelphiDoom.IdLib.Text.Token;

type
  /// <summary>
  ///   A macro (define_t): name, flags, builtin id, parameters and tokens. The linked lists of the
  ///   original (next, hashnext, the token chains) are arrays and the lists of the parser.
  /// </summary>
  TIdParserDefine = class
  private
    FName: AnsiString;
    FFlags: Integer;
    FBuiltin: Integer;
    FNumParms: Integer;
    FParms: TArray<TIdToken>;
    FTokens: TArray<TIdToken>;
  public
    constructor Create(const AName: AnsiString);
    /// <summary>idParser::CopyDefine: an unlinked copy with its own tokens</summary>
    function Copy: TIdParserDefine;
    /// <summary>idParser::FindDefineParm: the index of the parameter with the name, -1 if none</summary>
    function FindParm(const AName: AnsiString): Integer;
    /// <summary>Appends a parameter and counts it</summary>
    procedure AddParm(const AToken: TIdToken);
    procedure AddToken(const AToken: TIdToken);
    property Name: AnsiString read FName;
    property Flags: Integer read FFlags write FFlags;
    property Builtin: Integer read FBuiltin write FBuiltin;
    property NumParms: Integer read FNumParms;
    property Parms: TArray<TIdToken> read FParms;
    property Tokens: TArray<TIdToken> read FTokens;
  end;

implementation

{ TIdParserDefine }

constructor TIdParserDefine.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
end;

function TIdParserDefine.Copy: TIdParserDefine;
begin
  Result := TIdParserDefine.Create(FName);
  Result.FFlags := FFlags;
  Result.FBuiltin := FBuiltin;
  Result.FNumParms := FNumParms;
  Result.FTokens := System.Copy(FTokens);
  Result.FParms := System.Copy(FParms);
end;

function TIdParserDefine.FindParm(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FParms) do
    if FParms[LIndex].IsText(AName) then
      Exit(LIndex);
  Result := -1;
end;

procedure TIdParserDefine.AddParm(const AToken: TIdToken);
begin
  SetLength(FParms, System.Length(FParms) + 1);
  FParms[High(FParms)] := AToken;
  Inc(FNumParms);
end;

procedure TIdParserDefine.AddToken(const AToken: TIdToken);
begin
  SetLength(FTokens, System.Length(FTokens) + 1);
  FTokens[High(FTokens)] := AToken;
end;

end.
