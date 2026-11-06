{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - a configuration file that was read      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Document;

interface

uses
  System.SysUtils, DelphiDoom.Configuration.Intf;

type
  /// <summary>The lines of a configuration file: the header and "name=value" lines</summary>
  TConfigurationDocument = class(TInterfacedObject, IConfigurationDocument)
  private
    FHeader: string;
    FLines: TArray<string>;
  public
    /// <summary>ALines is the whole file: the first line is the header</summary>
    constructor Create(const ALines: TArray<string>);
    function GetHeader: string;
    function GetCount: Integer;
    function NameAt(AIndex: Integer): string;
    function ValueOf(const AName: string): string;
  end;

implementation

uses
  DelphiDoom.Configuration.Types;

const
  SBadLine = 'The line %d does not exist (there are %d)';

{ TConfigurationDocument }

constructor TConfigurationDocument.Create(const ALines: TArray<string>);
begin
  inherited Create;
  if Length(ALines) > 0 then
  begin
    FHeader := ALines[0];
    FLines := Copy(ALines, 1, Length(ALines) - 1);
  end;
end;

function TConfigurationDocument.GetHeader: string;
begin
  Result := FHeader;
end;

function TConfigurationDocument.GetCount: Integer;
begin
  Result := Length(FLines);
end;

function TConfigurationDocument.NameAt(AIndex: Integer): string;
var
  LPosition: Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(FLines)) then
    raise EConfigurationException.CreateFmt(SBadLine, [AIndex, Length(FLines)]);
  LPosition := Pos('=', FLines[AIndex]);
  if LPosition = 0 then
    Exit('');
  Result := LowerCase(Copy(FLines[AIndex], 1, LPosition - 1));
end;

function TConfigurationDocument.ValueOf(const AName: string): string;
var
  LIndex, LPosition: Integer;
  LName: string;
begin
  LName := LowerCase(AName);
  for LIndex := 0 to High(FLines) do
    if NameAt(LIndex) = LName then
    begin
      LPosition := Pos('=', FLines[LIndex]);
      Exit(Copy(FLines[LIndex], LPosition + 1, MaxInt));
    end;
  Result := '';
end;

end.
