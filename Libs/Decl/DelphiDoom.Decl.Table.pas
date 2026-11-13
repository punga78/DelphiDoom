{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclTable, the "table" declaration       }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclTable.h, DeclTable.cpp. Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company.                                               }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Table;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base;

type
  /// <summary>A table of numbers a material or a light reads with a position from 0 to 1 (idDeclTable)</summary>
  IDeclTable = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0010}']
    /// <summary>
    ///   The value at a position: interpolated between the two nearest entries, or the nearest one with
    ///   <c>snap</c>; a position outside 0..1 clamps with <c>clamp</c> and wraps otherwise. A table with
    ///   fewer than three entries gives 1 (as the original does).
    /// </summary>
    function TableLookup(const AIndex: Single): Single;
    function GetSnap: Boolean;
    function GetClamp: Boolean;
    /// <summary>The number of values including the copy of the first one that is appended after the last</summary>
    function GetNumValues: Integer;
    function GetValue(const AIndex: Integer): Single;
  end;

  /// <summary>
  ///   <c>table name { [snap] [clamp] { v0, v1, ... } }</c>. The first value is copied after the last so an
  ///   interpolation does not wrap.
  /// </summary>
  TDeclTable = class(TDecl, IDeclTable)
  strict private
    FSnap: Boolean;
    FClamp: Boolean;
    FValues: TArray<Single>;
  public
    function TableLookup(const AIndex: Single): Single;
    function GetSnap: Boolean;
    function GetClamp: Boolean;
    function GetNumValues: Integer;
    function GetValue(const AIndex: Integer): Single;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings;

{ TDeclTable }

function TDeclTable.TableLookup(const AIndex: Single): Single;
var
  LIndex, LFraction: Single;
  LWhole, LDomain: Integer;
begin
  LDomain := Length(FValues) - 1;
  if LDomain <= 1 then
    Exit(1.0);

  LIndex := AIndex;
  if FClamp then
  begin
    LIndex := LIndex * (LDomain - 1);
    if LIndex >= LDomain - 1 then
      Exit(FValues[LDomain - 1])
    else if LIndex <= 0 then
      Exit(FValues[0]);
    LWhole := TIdMath.Ftoi(LIndex);
    LFraction := LIndex - LWhole;
  end
  else
  begin
    LIndex := LIndex * LDomain;
    if LIndex < 0 then
      LIndex := LIndex + LDomain * TIdMath.Ceil(-LIndex / LDomain);
    LWhole := TIdMath.FtoiFast(TIdMath.Floor(LIndex));
    LFraction := LIndex - LWhole;
    LWhole := LWhole mod LDomain;
  end;

  if not FSnap then
    // the 0 index was duplicated at the end at creation time, so the filter needs no wrap
    Exit(FValues[LWhole] * (1.0 - LFraction) + FValues[LWhole + 1] * LFraction);

  Result := FValues[LWhole];
end;

function TDeclTable.GetSnap: Boolean;
begin
  Result := FSnap;
end;

function TDeclTable.GetClamp: Boolean;
begin
  Result := FClamp;
end;

function TDeclTable.GetNumValues: Integer;
begin
  Result := Length(FValues);
end;

function TDeclTable.GetValue(const AIndex: Integer): Single;
begin
  Result := FValues[AIndex];
end;

function TDeclTable.DefaultDefinition: AnsiString;
begin
  Result := '{ { 0 } }';
end;

procedure TDeclTable.FreeData;
begin
  FSnap := False;
  FClamp := False;
  SetLength(FValues, 0);
end;

function TDeclTable.Size: NativeInt;
begin
  Result := InstanceSize + Length(FValues) * SizeOf(Single);
end;

function TDeclTable.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LValue: Single;
  LErrorFlag: Boolean;
begin
  LSource := OpenLexer(AText);
  try
    FSnap := False;
    FClamp := False;
    SetLength(FValues, 0);

    while True do
    begin
      if not LSource.ReadToken(LToken) then
        Break;
      if LToken.IsText('}') then
        Break;

      if TIdStrings.Icmp(LToken.Text, 'snap') = 0 then
        FSnap := True
      else if TIdStrings.Icmp(LToken.Text, 'clamp') = 0 then
        FClamp := True
      else if TIdStrings.Icmp(LToken.Text, '{') = 0 then
      begin
        while True do
        begin
          LErrorFlag := False;
          LValue := LSource.ParseFloat(@LErrorFlag);
          if LErrorFlag then
          begin
            // we got something non-numeric
            MakeDefault;
            Exit(False);
          end;
          SetLength(FValues, Length(FValues) + 1);
          FValues[High(FValues)] := LValue;

          LSource.ReadToken(LToken);
          if LToken.IsText('}') then
            Break;
          if LToken.IsText(',') then
            Continue;
          LSource.Warning('expected comma or brace', []);
          MakeDefault;
          Exit(False);
        end;
      end
      else
      begin
        LSource.Warning('unknown token ''%s''', [string(LToken.Text)]);
        MakeDefault;
        Exit(False);
      end;
    end;

    // copy the 0 element to the end, so lerping doesn't need to worry about the wrap case.
    // The original reads values[0] of an empty list here; a table without values stays empty.
    if Length(FValues) > 0 then
    begin
      SetLength(FValues, Length(FValues) + 1);
      FValues[High(FValues)] := FValues[0];
    end;
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
