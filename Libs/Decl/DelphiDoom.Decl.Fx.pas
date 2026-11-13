{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclFx, the "fx" declaration             }
{                                                                              }
{  Port of the effects of Doom 3 (id Software, GPL v3): framework\DeclFX.h,    }
{  DeclFX.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Fx;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base, DelphiDoom.Decl.Fx.Types, DelphiDoom.Decl.Fx.Intf;

type
  /// <summary>
  ///   <c>fx name { bindto "joint"  { sound x  delay 0.5 } { ... } }</c>: the actions of an effect. Like the
  ///   original it ignores a word outside the braces of an action and, when the lexer found an error, writes a warning and
  ///   says false but keeps the actions it read (the manager does not make it default).
  ///   <c>FreeData</c> clears the actions and not the joint.
  /// </summary>
  TDeclFx = class(TDecl, IDeclFx)
  strict private
    FEvents: TArray<TFxAction>;
    FJoint: AnsiString;
  public
    function GetNumEvents: Integer;
    function GetEvent(const AIndex: Integer): TFxAction;
    function GetJoint: AnsiString;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
    /// <summary>idDeclFX::Print: the number of actions and one line per action with its type and name</summary>
    procedure Print; override;
    /// <summary>idDeclFX::List: <c>name, N stages</c></summary>
    procedure List; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Fx.ActionParser;

const
  FX_TYPE_NAMES: array[FX_LIGHT..FX_SHOCKWAVE] of string = ('FX_LIGHT', 'FX_PARTICLE', 'FX_DECAL', 'FX_MODEL',
    'FX_SOUND', 'FX_SHAKE', 'FX_ATTACHLIGHT', 'FX_ATTACHENTITY', 'FX_LAUNCH', 'FX_SHOCKWAVE');

{ TDeclFx }

function TDeclFx.GetNumEvents: Integer;
begin
  Result := Length(FEvents);
end;

function TDeclFx.GetEvent(const AIndex: Integer): TFxAction;
begin
  if (AIndex < 0) or (AIndex >= Length(FEvents)) then
    raise EDeclFxException.CreateFmt('effect action %d out of range', [AIndex]);
  Result := FEvents[AIndex];
end;

function TDeclFx.GetJoint: AnsiString;
begin
  Result := FJoint;
end;

function TDeclFx.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclFx.FreeData;
begin
  FEvents := nil;
end;

function TDeclFx.DefaultDefinition: AnsiString;
begin
  Result := '{'#10 +
    #9'{'#10 +
    #9#9'duration'#9'5'#10 +
    #9#9'model'#9#9'_default'#10 +
    #9'}'#10 +
    '}';
end;

function TDeclFx.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LParser: TFxActionParser;
  LAction: TFxAction;
begin
  LToken := TIdToken.Create;
  LSource := OpenLexer(AText);
  try
    LParser := TFxActionParser.Create(GetFinder);
    try
      // scan through, identifying each individual parameter
      while True do
      begin
        if not LSource.ReadToken(LToken) then
          Break;

        if LToken.Text = '}' then
          Break;

        if TIdStrings.Icmp(LToken.Text, 'bindto') = 0 then
        begin
          LSource.ReadToken(LToken);
          FJoint := LToken.Text;
          Continue;
        end;

        if TIdStrings.Icmp(LToken.Text, '{') = 0 then
        begin
          LAction := LParser.ParseAction(LSource, FEvents);
          SetLength(FEvents, Length(FEvents) + 1);
          FEvents[High(FEvents)] := LAction;
          Continue;
        end;
      end;
    finally
      LParser.Free;
    end;

    if LSource.HadError then
    begin
      LSource.Warning('FX decl ''%s'' had a parse error', [string(GetName)]);
      Exit(False);
    end;
  finally
    LSource.Free;
  end;
  Result := True;
end;

procedure TDeclFx.Print;
var
  LLog: IIdLibLog;
  LIndex: Integer;
begin
  LLog := GetLog;
  if not Assigned(LLog) then
    Exit;
  LLog.Printf(Format('%d events'#10, [Length(FEvents)]));
  for LIndex := 0 to High(FEvents) do
    if (FEvents[LIndex].ActionType >= FX_LIGHT) and (FEvents[LIndex].ActionType <= FX_SHOCKWAVE) then
      LLog.Printf(Format('%s %s'#10, [FX_TYPE_NAMES[FEvents[LIndex].ActionType], string(FEvents[LIndex].Data)]));
end;

procedure TDeclFx.List;
var
  LLog: IIdLibLog;
begin
  LLog := GetLog;
  if Assigned(LLog) then
    LLog.Printf(Format('%s, %d stages'#10, [string(GetName), Length(FEvents)]));
end;

end.
