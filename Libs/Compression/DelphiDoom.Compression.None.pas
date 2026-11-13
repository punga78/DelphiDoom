{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorNone (idCompressor_None)       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.cpp }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.None;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  DelphiDoom.Compression.Types, DelphiDoom.Compression.Intf;

type
  /// <summary>
  ///   idCompressor_None: the compressor that does not compress, it copies to and from the stream. It
  ///   is the base of the others (the stream, the direction and the pass-through members).
  /// </summary>
  TCompressorNone = class(TInterfacedObject, ICompressor)
  strict protected
    FStream: TStream;
    FCompress: Boolean;
    procedure RequireStream;
    /// <summary>
    ///   ( ANumerator ) * 100.0f / ADenominator in single precision; a zero denominator gives infinity or
    ///   NaN as the C float division does (no exception)
    /// </summary>
    class function Percent(ANumerator, ADenominator: Integer): Single; static;
  public
    constructor Create;
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); virtual;
    procedure FinishCompress; virtual;
    function GetCompressionRatio: Single; virtual;
    function Read(AData: PByte; ALength: Integer): Integer; overload; virtual;
    function Write(AData: PByte; ALength: Integer): Integer; overload; virtual;
    function Read(var AData: TBytes; ALength: Integer): Integer; overload;
    function Write(const AData: TBytes): Integer; overload;
    function Length: Integer;
    function Tell: Integer;
    function Seek(AOffset: Integer; AOrigin: TSeekOrigin): Integer;
  end;

implementation

{ TCompressorNone }

constructor TCompressorNone.Create;
begin
  inherited Create;
  FCompress := True;
end;

procedure TCompressorNone.RequireStream;
begin
  if not Assigned(FStream) then
    raise ECompressionException.Create(SCompressorNoStream);
end;

class function TCompressorNone.Percent(ANumerator, ADenominator: Integer): Single;
var
  LScaled: Single;
begin
  LScaled := ANumerator * 100.0;
  if ADenominator = 0 then
  begin
    if LScaled = 0 then
      Exit(NaN);
    if LScaled > 0 then
      Exit(Infinity);
    Exit(NegInfinity);
  end;
  Result := LScaled / ADenominator;
end;

procedure TCompressorNone.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  if not Assigned(AStream) then
    raise ECompressionException.Create(SCompressorNoStream);
  FStream := AStream;
  FCompress := ACompress;
end;

procedure TCompressorNone.FinishCompress;
begin
end;

function TCompressorNone.GetCompressionRatio: Single;
begin
  Result := 0.0;
end;

function TCompressorNone.Write(AData: PByte; ALength: Integer): Integer;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  RequireStream;
  Result := FStream.Write(AData^, ALength);
end;

function TCompressorNone.Read(AData: PByte; ALength: Integer): Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  RequireStream;
  Result := FStream.Read(AData^, ALength);
end;

function TCompressorNone.Read(var AData: TBytes; ALength: Integer): Integer;
begin
  if System.Length(AData) < ALength then
    SetLength(AData, ALength);
  if ALength <= 0 then
    Exit(0);
  Result := Read(PByte(AData), ALength);
end;

function TCompressorNone.Write(const AData: TBytes): Integer;
begin
  if System.Length(AData) = 0 then
    Exit(0);
  Result := Write(PByte(AData), System.Length(AData));
end;

function TCompressorNone.Length: Integer;
begin
  if Assigned(FStream) then
    Result := FStream.Size
  else
    Result := 0;
end;

function TCompressorNone.Tell: Integer;
begin
  if Assigned(FStream) then
    Result := FStream.Position
  else
    Result := 0;
end;

function TCompressorNone.Seek(AOffset: Integer; AOrigin: TSeekOrigin): Integer;
begin
  raise ECompressionException.Create(SCompressorCannotSeek);
end;

end.
