{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - TImagingImageProgram, the interpreter of the  }
{  image programs of idTech 4, such as                                         }
{  addnormals( heightmap( textures/a_h, 4 ), textures/a_local )                }
{                                                                              }
{  Port of renderer\Image_program.cpp (id Software, Doom 3, GPL v3):           }
{  R_ParseImageProgram_r, R_LoadImageProgram, R_ParsePastImageProgram.         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ImageProgram.Interpreter;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Rgba.Image,
  DelphiDoom.Imaging.ImageProgram.Intf, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.IdLib.Text.Token;

const
  /// <summary>MAX_IMAGE_NAME: the canonical text of a program is cut to 255 characters</summary>
  IMAGING_PROGRAM_MAX_NAME = 256;

type
  /// <summary>What a program gives: the image, the newest timestamp of the files it used, and its kind</summary>
  TImagingProgramResult = record
    Image: TImagingRgbaImage;
    /// <summary>The biggest timestamp of the images that the program read (0 when it read none)</summary>
    Timestamp: Int64;
    /// <summary>True when heightmap, addnormals or smoothnormals made the image (the C++ sets TD_BUMP)</summary>
    IsBump: Boolean;
  end;

  /// <summary>
  ///   Runs image programs. The expression is read with an idLexer (LEXFL_NOFATALERRORS,
  ///   NOSTRINGCONCAT, NOSTRINGESCAPECHARS, ALLOWPATHNAMES) so file names with slashes and dots are
  ///   single tokens; a plain file name is a program too. The images come from the injected source
  /// </summary>
  /// <remarks>
  ///   Differences from the C++: the static <c>parseBuffer</c> is the property CanonicalName of the
  ///   instance; a nested program that fails (a missing file) makes the whole program fail also for
  ///   scale, invertAlpha, invertColor, makeIntensity and makeAlpha (the C++ ignores the result
  ///   there and then reads a null pointer)
  /// </remarks>
  TImagingImageProgram = class
  strict private
    FSource: IImagingProgramSource;
    FLog: IIdLibLog;
    FCanonicalName: AnsiString;
    procedure Append(const AText: AnsiString);
    procedure AppendToken(const AToken: TIdToken);
    procedure MatchAndAppend(const ALexer: TIdLexer; const AMatch: AnsiString);
    function ParseNode(const ALexer: TIdLexer; const AGenerate, AWantTimestamp: Boolean;
      var AImage: TImagingRgbaImage; var ATimestamp: Int64; var AIsBump: Boolean): Boolean;
    function ParseUnary(const ALexer: TIdLexer; const AGenerate, AWantTimestamp: Boolean;
      var AImage: TImagingRgbaImage; var ATimestamp: Int64; var AIsBump: Boolean): Boolean;
    function ParseBinary(const ALexer: TIdLexer; const AGenerate, AWantTimestamp: Boolean;
      var AImage: TImagingRgbaImage; var ATimestamp: Int64; var AIsBump: Boolean;
      const AKeyword: AnsiString): Boolean;
  public
    constructor Create(const ASource: IImagingProgramSource; const ALog: IIdLibLog = nil);
    /// <summary>R_LoadImageProgram with pixels: false when an image is missing or the program is wrong</summary>
    function Load(const AProgramText: string; out AResult: TImagingProgramResult): Boolean;
    /// <summary>R_LoadImageProgram with pic = NULL: only the timestamp of the newest file, no pixels</summary>
    function GetTimestamp(const AProgramText: string; out ATimestamp: Int64): Boolean;
    /// <summary>
    ///   R_ParsePastImageProgram: reads one program from a lexer that is in the middle of
    ///   another text (a material), loads nothing and gives the canonical text of what it read
    /// </summary>
    function SkipProgram(const ALexer: TIdLexer): string;
    /// <summary>The text of the last program that was read: tokens separated by a space, none around ( , )</summary>
    property CanonicalName: AnsiString read FCanonicalName;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Imaging.ImageProgram.Operations;

{ TImagingImageProgram }

constructor TImagingImageProgram.Create(const ASource: IImagingProgramSource;
  const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FLog := ALog;
end;

procedure TImagingImageProgram.Append(const AText: AnsiString);
var
  LRoom: Integer;
begin
  // idStr::Append into a buffer of MAX_IMAGE_NAME bytes: what does not fit is cut
  LRoom := IMAGING_PROGRAM_MAX_NAME - 1 - Length(FCanonicalName);
  if LRoom > 0 then
    FCanonicalName := FCanonicalName + Copy(AText, 1, LRoom);
end;

procedure TImagingImageProgram.AppendToken(const AToken: TIdToken);
begin
  if FCanonicalName <> '' then
    Append(' ');
  Append(AToken.Text);
end;

procedure TImagingImageProgram.MatchAndAppend(const ALexer: TIdLexer; const AMatch: AnsiString);
begin
  if not ALexer.ExpectTokenString(AMatch) then
    Exit;
  Append(AMatch);
end;

function TImagingImageProgram.ParseUnary(const ALexer: TIdLexer; const AGenerate,
  AWantTimestamp: Boolean; var AImage: TImagingRgbaImage; var ATimestamp: Int64;
  var AIsBump: Boolean): Boolean;
begin
  Result := ParseNode(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump);
end;

function TImagingImageProgram.ParseBinary(const ALexer: TIdLexer; const AGenerate,
  AWantTimestamp: Boolean; var AImage: TImagingRgbaImage; var ATimestamp: Int64;
  var AIsBump: Boolean; const AKeyword: AnsiString): Boolean;
var
  LOther: TImagingRgbaImage;
begin
  Result := False;
  MatchAndAppend(ALexer, '(');
  if not ParseNode(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump) then
    Exit;
  MatchAndAppend(ALexer, ',');
  LOther := Default(TImagingRgbaImage);
  if not ParseNode(ALexer, AGenerate, AWantTimestamp, LOther, ATimestamp, AIsBump) then
  begin
    AImage := Default(TImagingRgbaImage);
    Exit;
  end;
  if AGenerate then
  begin
    if TIdStrings.Icmp(AKeyword, 'add') = 0 then
      TImagingProgramOperations.Add(AImage, LOther)
    else
    begin
      TImagingProgramOperations.AddNormalMaps(AImage, LOther);
      AIsBump := True;
    end;
  end;
  MatchAndAppend(ALexer, ')');
  Result := True;
end;

function TImagingImageProgram.ParseNode(const ALexer: TIdLexer; const AGenerate,
  AWantTimestamp: Boolean; var AImage: TImagingRgbaImage; var ATimestamp: Int64;
  var AIsBump: Boolean): Boolean;
var
  LToken: TIdToken;
  LKeyword: AnsiString;
  LScale: array[0..3] of Single;
  LHeightScale: Single;
  LIndex: Integer;
  LFound: Boolean;
  LLoaded: TImagingRgbaImage;
  LStamp: Int64;

  function Is_(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LKeyword, AName) = 0;
  end;

begin
  LToken := TIdToken.Create;
  ALexer.ReadToken(LToken);
  AppendToken(LToken);
  LKeyword := LToken.Text;

  if Is_('heightmap') then
  begin
    MatchAndAppend(ALexer, '(');
    if not ParseUnary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump) then
      Exit(False);
    MatchAndAppend(ALexer, ',');
    ALexer.ReadToken(LToken);
    AppendToken(LToken);
    LHeightScale := LToken.GetFloatValue;
    if AGenerate then
    begin
      TImagingProgramOperations.HeightmapToNormalMap(AImage, LHeightScale);
      AIsBump := True;
    end;
    MatchAndAppend(ALexer, ')');
    Exit(True);
  end;

  if Is_('addnormals') then
    Exit(ParseBinary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump, 'addnormals'));

  if Is_('smoothnormals') then
  begin
    MatchAndAppend(ALexer, '(');
    if not ParseUnary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump) then
      Exit(False);
    if AGenerate then
    begin
      TImagingProgramOperations.SmoothNormalMap(AImage);
      AIsBump := True;
    end;
    MatchAndAppend(ALexer, ')');
    Exit(True);
  end;

  if Is_('add') then
    Exit(ParseBinary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump, 'add'));

  if Is_('scale') then
  begin
    MatchAndAppend(ALexer, '(');
    if not ParseUnary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump) then
      Exit(False);
    for LIndex := 0 to 3 do
    begin
      MatchAndAppend(ALexer, ',');
      ALexer.ReadToken(LToken);
      AppendToken(LToken);
      LScale[LIndex] := LToken.GetFloatValue;
    end;
    if AGenerate then
      TImagingProgramOperations.Scale(AImage, LScale);
    MatchAndAppend(ALexer, ')');
    Exit(True);
  end;

  if Is_('invertAlpha') or Is_('invertColor') or Is_('makeIntensity') or Is_('makeAlpha') then
  begin
    MatchAndAppend(ALexer, '(');
    if not ParseUnary(ALexer, AGenerate, AWantTimestamp, AImage, ATimestamp, AIsBump) then
      Exit(False);
    if AGenerate then
    begin
      if Is_('invertAlpha') then
        TImagingProgramOperations.InvertAlpha(AImage)
      else if Is_('invertColor') then
        TImagingProgramOperations.InvertColor(AImage)
      else if Is_('makeIntensity') then
        TImagingProgramOperations.MakeIntensity(AImage)
      else
        TImagingProgramOperations.MakeAlpha(AImage);
    end;
    MatchAndAppend(ALexer, ')');
    Exit(True);
  end;

  // only parsing: do not load the image
  if (not AGenerate) and (not AWantTimestamp) then
    Exit(True);

  LLoaded := Default(TImagingRgbaImage);
  LStamp := IMAGING_TIMESTAMP_NOT_FOUND;
  LFound := FSource.TryLoad(string(LToken.Text), AGenerate, LLoaded, LStamp);
  if (not LFound) or (LStamp = IMAGING_TIMESTAMP_NOT_FOUND) then
    Exit(False);
  if AGenerate then
    AImage := LLoaded;
  if AWantTimestamp and (LStamp > ATimestamp) then
    ATimestamp := LStamp;
  Result := True;
end;

function TImagingImageProgram.Load(const AProgramText: string;
  out AResult: TImagingProgramResult): Boolean;
var
  LLexer: TIdLexer;
  LText: AnsiString;
begin
  AResult := Default(TImagingProgramResult);
  FCanonicalName := '';
  LText := AnsiString(AProgramText);
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES, FLog);
  try
    LLexer.LoadMemory(LText, Length(LText), LText);
    Result := ParseNode(LLexer, True, True, AResult.Image, AResult.Timestamp, AResult.IsBump);
    if not Result then
      AResult.Image := Default(TImagingRgbaImage);
  finally
    LLexer.Free;
  end;
end;

function TImagingImageProgram.GetTimestamp(const AProgramText: string;
  out ATimestamp: Int64): Boolean;
var
  LLexer: TIdLexer;
  LText: AnsiString;
  LImage: TImagingRgbaImage;
  LIsBump: Boolean;
begin
  ATimestamp := 0;
  FCanonicalName := '';
  LText := AnsiString(AProgramText);
  LImage := Default(TImagingRgbaImage);
  LIsBump := False;
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES, FLog);
  try
    LLexer.LoadMemory(LText, Length(LText), LText);
    Result := ParseNode(LLexer, False, True, LImage, ATimestamp, LIsBump);
  finally
    LLexer.Free;
  end;
end;

function TImagingImageProgram.SkipProgram(const ALexer: TIdLexer): string;
var
  LImage: TImagingRgbaImage;
  LTimestamp: Int64;
  LIsBump: Boolean;
begin
  FCanonicalName := '';
  LImage := Default(TImagingRgbaImage);
  LTimestamp := 0;
  LIsBump := False;
  ParseNode(ALexer, False, False, LImage, LTimestamp, LIsBump);
  Result := string(FCanonicalName);
end;

end.
