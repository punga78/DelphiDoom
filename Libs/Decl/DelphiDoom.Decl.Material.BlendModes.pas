{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialBlendModes                       }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (NameToSrcBlendMode, NameToDstBlendMode).             }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.BlendModes;

interface

uses
  System.SysUtils;

type
  /// <summary>The names of the OpenGL blend factors a stage can use ("GL_ONE", "GL_SRC_ALPHA"...)</summary>
  TMaterialBlendModes = class sealed
  public
    /// <summary>The GLS_SRCBLEND_* bits of a source factor (case is ignored); false if the name is unknown</summary>
    class function TryGetSource(const AName: AnsiString; out ABits: Integer): Boolean; static;
    /// <summary>The GLS_DSTBLEND_* bits of a destination factor; false if the name is unknown</summary>
    class function TryGetDestination(const AName: AnsiString; out ABits: Integer): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Material.Types;

{ TMaterialBlendModes }

class function TMaterialBlendModes.TryGetSource(const AName: AnsiString; out ABits: Integer): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'GL_ONE') = 0 then
    ABits := GLS_SRCBLEND_ONE
  else if TIdStrings.Icmp(AName, 'GL_ZERO') = 0 then
    ABits := GLS_SRCBLEND_ZERO
  else if TIdStrings.Icmp(AName, 'GL_DST_COLOR') = 0 then
    ABits := GLS_SRCBLEND_DST_COLOR
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_DST_COLOR') = 0 then
    ABits := GLS_SRCBLEND_ONE_MINUS_DST_COLOR
  else if TIdStrings.Icmp(AName, 'GL_SRC_ALPHA') = 0 then
    ABits := GLS_SRCBLEND_SRC_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_SRC_ALPHA') = 0 then
    ABits := GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_DST_ALPHA') = 0 then
    ABits := GLS_SRCBLEND_DST_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_DST_ALPHA') = 0 then
    ABits := GLS_SRCBLEND_ONE_MINUS_DST_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_SRC_ALPHA_SATURATE') = 0 then
    ABits := GLS_SRCBLEND_ALPHA_SATURATE
  else
  begin
    ABits := GLS_SRCBLEND_ONE;
    Result := False;
  end;
end;

class function TMaterialBlendModes.TryGetDestination(const AName: AnsiString; out ABits: Integer): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'GL_ONE') = 0 then
    ABits := GLS_DSTBLEND_ONE
  else if TIdStrings.Icmp(AName, 'GL_ZERO') = 0 then
    ABits := GLS_DSTBLEND_ZERO
  else if TIdStrings.Icmp(AName, 'GL_SRC_ALPHA') = 0 then
    ABits := GLS_DSTBLEND_SRC_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_SRC_ALPHA') = 0 then
    ABits := GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_DST_ALPHA') = 0 then
    ABits := GLS_DSTBLEND_DST_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_DST_ALPHA') = 0 then
    ABits := GLS_DSTBLEND_ONE_MINUS_DST_ALPHA
  else if TIdStrings.Icmp(AName, 'GL_SRC_COLOR') = 0 then
    ABits := GLS_DSTBLEND_SRC_COLOR
  else if TIdStrings.Icmp(AName, 'GL_ONE_MINUS_SRC_COLOR') = 0 then
    ABits := GLS_DSTBLEND_ONE_MINUS_SRC_COLOR
  else
  begin
    ABits := GLS_DSTBLEND_ONE;
    Result := False;
  end;
end;

end.
