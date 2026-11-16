{******************************************************************************}
{                                                                              }
{  DelphiDoom: id Tech library - generations and versions of the engine        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdTech.Types;

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

type
  /// <summary>Raised for generations or version numbers that do not exist</summary>
  EIdTechException = class(Exception);

  /// <summary>
  ///   The generations of the engines of id Software. DelphiDoom, Heretic, Hexen and Strife
  ///   are id Tech 1 (the Doom engine)
  /// </summary>
  TIdTechGeneration = (IdTech1, IdTech2, IdTech3, IdTech4, IdTech5, IdTech6, IdTech7);

  TIdTechGenerationHelper = record helper for TIdTechGeneration
    /// <summary>1 for id Tech 1 ... 7 for id Tech 7</summary>
    function Number: Integer;
    /// <summary>'id Tech 1' ...</summary>
    function Name: string;
  end;

  /// <summary>
  ///   Version of an engine as the engine writes it: 207 is 2.07, 110 is 1.10. Major and Minor
  ///   are the two parts; Minor goes from 0 to 99
  /// </summary>
  TIdTechVersion = record
  private
    FMajor: Integer;
    FMinor: Integer;
  public
    /// <summary>Raises EIdTechException when ANumber is negative</summary>
    class function FromNumber(ANumber: Integer): TIdTechVersion; static;
    /// <summary>Raises EIdTechException when AMajor is negative or AMinor is not between 0 and 99</summary>
    class function Create(AMajor, AMinor: Integer): TIdTechVersion; static;
    /// <summary>-1, 0 or 1</summary>
    class function Compare(const ALeft, ARight: TIdTechVersion): Integer; static;
    /// <summary>207 for 2.07</summary>
    function Number: Integer;
    /// <summary>'2.07'</summary>
    function ToString: string;
    class operator Equal(const ALeft, ARight: TIdTechVersion): Boolean;
    class operator NotEqual(const ALeft, ARight: TIdTechVersion): Boolean;
    class operator LessThan(const ALeft, ARight: TIdTechVersion): Boolean;
    class operator LessThanOrEqual(const ALeft, ARight: TIdTechVersion): Boolean;
    class operator GreaterThan(const ALeft, ARight: TIdTechVersion): Boolean;
    class operator GreaterThanOrEqual(const ALeft, ARight: TIdTechVersion): Boolean;
    property Major: Integer read FMajor;
    property Minor: Integer read FMinor;
  end;

implementation

const
  SBadVersionNumber = 'The version number %d does not exist';
  SBadMinor = 'The minor version %d must be between 0 and 99';

{ TIdTechGenerationHelper }

function TIdTechGenerationHelper.Number: Integer;
begin
  Result := Ord(Self) + 1;
end;

function TIdTechGenerationHelper.Name: string;
begin
  Result := 'id Tech ' + IntToStr(Number);
end;

{ TIdTechVersion }

class function TIdTechVersion.FromNumber(ANumber: Integer): TIdTechVersion;
begin
  if ANumber < 0 then
    raise EIdTechException.CreateFmt(SBadVersionNumber, [ANumber]);
  Result.FMajor := ANumber div 100;
  Result.FMinor := ANumber mod 100;
end;

class function TIdTechVersion.Create(AMajor, AMinor: Integer): TIdTechVersion;
begin
  if AMajor < 0 then
    raise EIdTechException.CreateFmt(SBadVersionNumber, [AMajor]);
  if (AMinor < 0) or (AMinor > 99) then
    raise EIdTechException.CreateFmt(SBadMinor, [AMinor]);
  Result.FMajor := AMajor;
  Result.FMinor := AMinor;
end;

class function TIdTechVersion.Compare(const ALeft, ARight: TIdTechVersion): Integer;
begin
  if ALeft.Number < ARight.Number then
    Result := -1
  else if ALeft.Number > ARight.Number then
    Result := 1
  else
    Result := 0;
end;

function TIdTechVersion.Number: Integer;
begin
  Result := FMajor * 100 + FMinor;
end;

function TIdTechVersion.ToString: string;
begin
  Result := Format('%d.%.2d', [FMajor, FMinor]);
end;

class operator TIdTechVersion.Equal(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) = 0;
end;

class operator TIdTechVersion.NotEqual(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) <> 0;
end;

class operator TIdTechVersion.LessThan(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) < 0;
end;

class operator TIdTechVersion.LessThanOrEqual(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) <= 0;
end;

class operator TIdTechVersion.GreaterThan(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) > 0;
end;

class operator TIdTechVersion.GreaterThanOrEqual(const ALeft, ARight: TIdTechVersion): Boolean;
begin
  Result := Compare(ALeft, ARight) >= 0;
end;

end.
