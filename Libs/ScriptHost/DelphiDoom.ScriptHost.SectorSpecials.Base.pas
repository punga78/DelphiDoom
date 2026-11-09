{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - base of the classes of the specials of sectors    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Base;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>
  ///   What the classes of the specials share: the gateway and the way the arguments are written.
  ///   A value that does not fit its byte is cut to the low bits, as the scripts have always had it
  /// </summary>
  TScriptSectorSpecialsBase = class
  strict private
    FSpecials: IScriptSectorSpecials;
  strict protected
    property Specials: IScriptSectorSpecials read FSpecials;
    /// <summary>The 8 arguments, all zero</summary>
    class function NewArguments: TScriptSpecialArguments; static;
    /// <summary>Writes the low 8 bits of AValue (the typecast does not check the range)</summary>
    class procedure SetByte(var AArguments: TScriptSpecialArguments; const AIndex, AValue: Integer); static;
    /// <summary>Writes the low 16 bits of AValue in the two bytes from AIndex (native order)</summary>
    class procedure SetSmallInt(var AArguments: TScriptSpecialArguments; const AIndex, AValue: Integer); static;
  public
    /// <param name="ASpecials">The gateway to the specials of the map</param>
    constructor Create(const ASpecials: IScriptSectorSpecials);
  end;

implementation

uses
  System.SysUtils;

{ TScriptSectorSpecialsBase }

constructor TScriptSectorSpecialsBase.Create(const ASpecials: IScriptSectorSpecials);
begin
  inherited Create;
  if not Assigned(ASpecials) then
    raise EArgumentNilException.Create('ASpecials');
  FSpecials := ASpecials;
end;

class function TScriptSectorSpecialsBase.NewArguments: TScriptSpecialArguments;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

class procedure TScriptSectorSpecialsBase.SetByte(var AArguments: TScriptSpecialArguments;
  const AIndex, AValue: Integer);
begin
  AArguments[AIndex] := Byte(AValue);
end;

class procedure TScriptSectorSpecialsBase.SetSmallInt(var AArguments: TScriptSpecialArguments;
  const AIndex, AValue: Integer);
begin
  PSmallInt(@AArguments[AIndex])^ := SmallInt(AValue);
end;

end.
