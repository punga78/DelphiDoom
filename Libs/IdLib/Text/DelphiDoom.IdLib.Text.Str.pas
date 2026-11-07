{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - TIdStr, the value string of idStr                  }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): the instance methods of idStr  }
{  (idlib\Str.h, Str.cpp). Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Str;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A value string with the methods of idStr. The text is an 8-bit AnsiString (idStr holds
  ///   bytes); assigning a TIdStr copies it, as the copy constructor of idStr does. The methods
  ///   that idStr declares as <c>idStr &amp;Method()</c> (chainable) are procedures here and change
  ///   the string in place; the ones that return a piece of the string are functions.
  ///   Indexes are 0-based like the original; <c>Chars[Length]</c> is #0 (the C terminator).
  ///   Not ported: the memory management (Allocated, Size, ReAllocate, FreeData), sprintf-style
  ///   formatting (use Format), BestUnit/SetUnit (printf format strings).
  /// </summary>
  TIdStr = record
  private
    FText: AnsiString;
    function GetChar(const AIndex: Integer): AnsiChar;
    procedure SetChar(const AIndex: Integer; const AValue: AnsiChar);
  public
    // --- creation and conversion ---
    class function Create(const AText: AnsiString): TIdStr; overload; static;
    /// <summary>idStr(text, start, end): the characters [start, end), clamped as the original does</summary>
    class function Create(const AText: AnsiString; AStart, AEnd: Integer): TIdStr; overload; static;
    class function FromBoolean(const AValue: Boolean): TIdStr; static;
    class function FromChar(const AValue: AnsiChar): TIdStr; static;
    class function FromInteger(const AValue: Integer): TIdStr; static;
    class function FromCardinal(const AValue: Cardinal): TIdStr; static;
    /// <summary>idStr(float): "%f" without trailing zeros and dot</summary>
    class function FromFloat(const AValue: Single): TIdStr; static;
    class operator Implicit(const AText: AnsiString): TIdStr;
    class operator Implicit(const AValue: TIdStr): AnsiString;
    class operator Add(const A, B: TIdStr): TIdStr;
    class operator Equal(const A, B: TIdStr): Boolean;
    class operator NotEqual(const A, B: TIdStr): Boolean;

    property Text: AnsiString read FText write FText;
    /// <summary>operator[]: 0-based, valid up to and including Length (the terminator)</summary>
    property Chars[const AIndex: Integer]: AnsiChar read GetChar write SetChar; default;

    // --- comparison ---
    function Cmp(const AText: AnsiString): Integer;
    function Cmpn(const AText: AnsiString; const ACount: Integer): Integer;
    function CmpPrefix(const AText: AnsiString): Integer;
    function Icmp(const AText: AnsiString): Integer;
    function Icmpn(const AText: AnsiString; const ACount: Integer): Integer;
    function IcmpPrefix(const AText: AnsiString): Integer;
    function IcmpNoColor(const AText: AnsiString): Integer;
    function IcmpPath(const AText: AnsiString): Integer;
    function IcmpnPath(const AText: AnsiString; const ACount: Integer): Integer;
    function IcmpPrefixPath(const AText: AnsiString): Integer;

    // --- size and content ---
    function Length: Integer;
    procedure Empty;
    function IsEmpty: Boolean;
    procedure Clear;
    procedure Append(const AChar: AnsiChar); overload;
    procedure Append(const AText: AnsiString); overload;
    /// <summary>idStr::Append(text, len): at most <c>ALength</c> characters of the text, up to its end</summary>
    procedure Append(const AText: AnsiString; const ALength: Integer); overload;
    procedure AppendInteger(const AValue: Integer);
    procedure AppendCardinal(const AValue: Cardinal);
    procedure AppendBoolean(const AValue: Boolean);
    /// <summary>operator+=(float): plain "%f"</summary>
    procedure AppendFloat(const AValue: Single);
    procedure Insert(const AChar: AnsiChar; AIndex: Integer); overload;
    procedure Insert(const AText: AnsiString; AIndex: Integer); overload;
    procedure ToLower;
    procedure ToUpper;
    function IsNumeric: Boolean;
    function IsColor: Boolean;
    function HasLower: Boolean;
    function HasUpper: Boolean;
    function LengthWithoutColors: Integer;
    procedure RemoveColors;
    procedure CapLength(const ANewLength: Integer);
    procedure Fill(const AChar: AnsiChar; const ANewLength: Integer);

    // --- search ---
    function Find(const AChar: AnsiChar; const AStart: Integer = 0; const AEnd: Integer = -1): Integer; overload;
    function Find(const AText: AnsiString; const ACaseSensitive: Boolean = True; const AStart: Integer = 0;
      const AEnd: Integer = -1): Integer; overload;
    function Filter(const AFilter: AnsiString; const ACaseSensitive: Boolean): Boolean;
    /// <summary>The index of the last occurrence of the character, -1 if there is none</summary>
    function Last(const AChar: AnsiChar): Integer;

    // --- pieces ---
    function Left(const ALength: Integer): TIdStr;
    function Right(const ALength: Integer): TIdStr;
    function Mid(const AStart, ALength: Integer): TIdStr;

    // --- stripping and replacing ---
    procedure StripLeading(const AChar: AnsiChar); overload;
    procedure StripLeading(const AText: AnsiString); overload;
    function StripLeadingOnce(const AText: AnsiString): Boolean;
    procedure StripTrailing(const AChar: AnsiChar); overload;
    procedure StripTrailing(const AText: AnsiString); overload;
    function StripTrailingOnce(const AText: AnsiString): Boolean;
    procedure Strip(const AChar: AnsiChar); overload;
    procedure Strip(const AText: AnsiString); overload;
    procedure StripTrailingWhitespace;
    procedure StripQuotes;
    /// <summary>Replaces every non overlapping occurrence; an empty <c>AOld</c> does nothing (the original loops forever)</summary>
    procedure Replace(const AOld, ANew: AnsiString);

    // --- file names ---
    function FileNameHash: Integer;
    procedure BackSlashesToSlashes;
    procedure SetFileExtension(const AExtension: AnsiString);
    procedure StripFileExtension;
    procedure StripAbsoluteFileExtension;
    procedure DefaultFileExtension(const AExtension: AnsiString);
    procedure DefaultPath(const ABasePath: AnsiString);
    procedure AppendPath(const AText: AnsiString);
    procedure StripFilename;
    procedure StripPath;
    function ExtractFilePath: TIdStr;
    function ExtractFileName: TIdStr;
    function ExtractFileBase: TIdStr;
    function ExtractFileExtension: TIdStr;
    function CheckExtension(const AExtension: AnsiString): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings;

{ TIdStr }

class function TIdStr.Create(const AText: AnsiString): TIdStr;
begin
  Result.FText := Copy(AText, 1, TIdStrings.Length(AText));
end;

class function TIdStr.Create(const AText: AnsiString; AStart, AEnd: Integer): TIdStr;
var
  LLength, LCount: Integer;
begin
  LLength := TIdStrings.Length(AText);
  if AEnd > LLength then
    AEnd := LLength;
  if AStart > LLength then
    AStart := LLength
  else if AStart < 0 then
    AStart := 0;
  LCount := AEnd - AStart;
  if LCount < 0 then
    LCount := 0;
  Result.FText := Copy(AText, AStart + 1, LCount);
end;

class function TIdStr.FromBoolean(const AValue: Boolean): TIdStr;
begin
  if AValue then
    Result.FText := '1'
  else
    Result.FText := '0';
end;

class function TIdStr.FromChar(const AValue: AnsiChar): TIdStr;
begin
  Result.FText := AValue;
end;

class function TIdStr.FromInteger(const AValue: Integer): TIdStr;
begin
  Result.FText := AnsiString(IntToStr(AValue));
end;

class function TIdStr.FromCardinal(const AValue: Cardinal): TIdStr;
begin
  Result.FText := AnsiString(UIntToStr(AValue));
end;

class function TIdStr.FromFloat(const AValue: Single): TIdStr;
begin
  Result.FText := TIdStrings.FloatToText(AValue);
end;

class operator TIdStr.Implicit(const AText: AnsiString): TIdStr;
begin
  Result.FText := AText;
end;

class operator TIdStr.Implicit(const AValue: TIdStr): AnsiString;
begin
  Result := AValue.FText;
end;

class operator TIdStr.Add(const A, B: TIdStr): TIdStr;
begin
  Result.FText := A.FText + B.FText;
end;

class operator TIdStr.Equal(const A, B: TIdStr): Boolean;
begin
  Result := TIdStrings.Cmp(A.FText, B.FText) = 0;
end;

class operator TIdStr.NotEqual(const A, B: TIdStr): Boolean;
begin
  Result := TIdStrings.Cmp(A.FText, B.FText) <> 0;
end;

function TIdStr.GetChar(const AIndex: Integer): AnsiChar;
begin
  if (AIndex < 0) or (AIndex > System.Length(FText)) then
    raise ERangeError.CreateFmt('TIdStr: index %d out of range 0..%d', [AIndex, System.Length(FText)]);
  if AIndex = System.Length(FText) then
    Result := #0
  else
    Result := FText[AIndex + 1];
end;

procedure TIdStr.SetChar(const AIndex: Integer; const AValue: AnsiChar);
begin
  if (AIndex < 0) or (AIndex >= System.Length(FText)) then
    raise ERangeError.CreateFmt('TIdStr: index %d out of range 0..%d', [AIndex, System.Length(FText) - 1]);
  FText[AIndex + 1] := AValue;
end;

function TIdStr.Cmp(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.Cmp(FText, AText);
end;

function TIdStr.Cmpn(const AText: AnsiString; const ACount: Integer): Integer;
begin
  Result := TIdStrings.Cmpn(FText, AText, ACount);
end;

function TIdStr.CmpPrefix(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.Cmpn(FText, AText, TIdStrings.Length(AText));
end;

function TIdStr.Icmp(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.Icmp(FText, AText);
end;

function TIdStr.Icmpn(const AText: AnsiString; const ACount: Integer): Integer;
begin
  Result := TIdStrings.Icmpn(FText, AText, ACount);
end;

function TIdStr.IcmpPrefix(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.Icmpn(FText, AText, TIdStrings.Length(AText));
end;

function TIdStr.IcmpNoColor(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.IcmpNoColor(FText, AText);
end;

function TIdStr.IcmpPath(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.IcmpPath(FText, AText);
end;

function TIdStr.IcmpnPath(const AText: AnsiString; const ACount: Integer): Integer;
begin
  Result := TIdStrings.IcmpnPath(FText, AText, ACount);
end;

function TIdStr.IcmpPrefixPath(const AText: AnsiString): Integer;
begin
  Result := TIdStrings.IcmpnPath(FText, AText, TIdStrings.Length(AText));
end;

function TIdStr.Length: Integer;
begin
  Result := System.Length(FText);
end;

procedure TIdStr.Empty;
begin
  FText := '';
end;

function TIdStr.IsEmpty: Boolean;
begin
  Result := TIdStrings.Cmp(FText, '') = 0;
end;

procedure TIdStr.Clear;
begin
  FText := '';
end;

procedure TIdStr.Append(const AChar: AnsiChar);
begin
  FText := FText + AChar;
end;

procedure TIdStr.Append(const AText: AnsiString);
begin
  FText := FText + AText;
end;

procedure TIdStr.Append(const AText: AnsiString; const ALength: Integer);
var
  LCount: Integer;
begin
  if ALength <= 0 then
    Exit;
  LCount := TIdStrings.Length(AText);
  if LCount > ALength then
    LCount := ALength;
  FText := FText + Copy(AText, 1, LCount);
end;

procedure TIdStr.AppendInteger(const AValue: Integer);
begin
  FText := FText + AnsiString(IntToStr(AValue));
end;

procedure TIdStr.AppendCardinal(const AValue: Cardinal);
begin
  FText := FText + AnsiString(UIntToStr(AValue));
end;

procedure TIdStr.AppendBoolean(const AValue: Boolean);
begin
  if AValue then
    FText := FText + 'true'
  else
    FText := FText + 'false';
end;

procedure TIdStr.AppendFloat(const AValue: Single);
begin
  FText := FText + TIdStrings.FloatToPlainText(AValue);
end;

procedure TIdStr.Insert(const AChar: AnsiChar; AIndex: Integer);
begin
  if AIndex < 0 then
    AIndex := 0
  else if AIndex > System.Length(FText) then
    AIndex := System.Length(FText);
  System.Insert(AChar, FText, AIndex + 1);
end;

procedure TIdStr.Insert(const AText: AnsiString; AIndex: Integer);
begin
  if AIndex < 0 then
    AIndex := 0
  else if AIndex > System.Length(FText) then
    AIndex := System.Length(FText);
  System.Insert(AText, FText, AIndex + 1);
end;

procedure TIdStr.ToLower;
begin
  FText := TIdStrings.ToLower(FText);
end;

procedure TIdStr.ToUpper;
begin
  FText := TIdStrings.ToUpper(FText);
end;

function TIdStr.IsNumeric: Boolean;
begin
  Result := TIdStrings.IsNumeric(FText);
end;

function TIdStr.IsColor: Boolean;
begin
  Result := TIdStrings.IsColor(FText);
end;

function TIdStr.HasLower: Boolean;
begin
  Result := TIdStrings.HasLower(FText);
end;

function TIdStr.HasUpper: Boolean;
begin
  Result := TIdStrings.HasUpper(FText);
end;

function TIdStr.LengthWithoutColors: Integer;
begin
  Result := TIdStrings.LengthWithoutColors(FText);
end;

procedure TIdStr.RemoveColors;
begin
  FText := TIdStrings.RemoveColors(FText);
end;

procedure TIdStr.CapLength(const ANewLength: Integer);
begin
  if System.Length(FText) <= ANewLength then
    Exit;
  SetLength(FText, ANewLength);
end;

procedure TIdStr.Fill(const AChar: AnsiChar; const ANewLength: Integer);
begin
  SetLength(FText, ANewLength);
  if ANewLength > 0 then
    FillChar(FText[1], ANewLength, AChar);
end;

function TIdStr.Find(const AChar: AnsiChar; const AStart, AEnd: Integer): Integer;
var
  LEnd: Integer;
begin
  LEnd := AEnd;
  if LEnd = -1 then
    LEnd := System.Length(FText);
  Result := TIdStrings.FindChar(FText, AChar, AStart, LEnd);
end;

function TIdStr.Find(const AText: AnsiString; const ACaseSensitive: Boolean; const AStart, AEnd: Integer): Integer;
var
  LEnd: Integer;
begin
  LEnd := AEnd;
  if LEnd = -1 then
    LEnd := System.Length(FText);
  Result := TIdStrings.FindText(FText, AText, ACaseSensitive, AStart, LEnd);
end;

function TIdStr.Filter(const AFilter: AnsiString; const ACaseSensitive: Boolean): Boolean;
begin
  Result := TIdStrings.Filter(AFilter, FText, ACaseSensitive);
end;

function TIdStr.Last(const AChar: AnsiChar): Integer;
var
  LIndex: Integer;
begin
  for LIndex := System.Length(FText) downto 1 do
    if FText[LIndex] = AChar then
      Exit(LIndex - 1);
  Result := -1;
end;

function TIdStr.Mid(const AStart, ALength: Integer): TIdStr;
var
  LLength, LStart, LCount: Integer;
begin
  Result.FText := '';
  LLength := System.Length(FText);
  LStart := AStart;
  LCount := ALength;
  if (LLength = 0) or (LCount <= 0) or (LStart >= LLength) then
    Exit;
  if LStart < 0 then
  begin
    // the original reads before the buffer: here the part before the start is dropped
    Inc(LCount, LStart);
    LStart := 0;
    if LCount <= 0 then
      Exit;
  end;
  if LStart + LCount >= LLength then
    LCount := LLength - LStart;
  Result.FText := Copy(FText, LStart + 1, LCount);
end;

function TIdStr.Left(const ALength: Integer): TIdStr;
begin
  Result := Mid(0, ALength);
end;

function TIdStr.Right(const ALength: Integer): TIdStr;
begin
  if ALength >= System.Length(FText) then
    Result := Self
  else
    Result := Mid(System.Length(FText) - ALength, ALength);
end;

procedure TIdStr.StripLeading(const AChar: AnsiChar);
var
  LCount: Integer;
begin
  LCount := 0;
  while (LCount < System.Length(FText)) and (FText[LCount + 1] = AChar) do
    Inc(LCount);
  Delete(FText, 1, LCount);
end;

procedure TIdStr.StripLeading(const AText: AnsiString);
var
  LLength: Integer;
begin
  LLength := TIdStrings.Length(AText);
  if LLength > 0 then
    while TIdStrings.Cmpn(AText, FText, LLength) = 0 do
    begin
      if System.Length(FText) < LLength then
        Break;
      Delete(FText, 1, LLength);
    end;
end;

function TIdStr.StripLeadingOnce(const AText: AnsiString): Boolean;
var
  LLength: Integer;
begin
  LLength := TIdStrings.Length(AText);
  Result := (LLength > 0) and (System.Length(FText) >= LLength) and (TIdStrings.Cmpn(AText, FText, LLength) = 0);
  if Result then
    Delete(FText, 1, LLength);
end;

procedure TIdStr.StripTrailing(const AChar: AnsiChar);
var
  LLength: Integer;
begin
  LLength := System.Length(FText);
  while (LLength > 0) and (FText[LLength] = AChar) do
    Dec(LLength);
  SetLength(FText, LLength);
end;

procedure TIdStr.StripTrailing(const AText: AnsiString);
var
  LLength: Integer;
begin
  LLength := TIdStrings.Length(AText);
  if LLength > 0 then
    while (System.Length(FText) >= LLength) and
      (TIdStrings.Cmpn(AText, Copy(FText, System.Length(FText) - LLength + 1, LLength), LLength) = 0) do
      SetLength(FText, System.Length(FText) - LLength);
end;

function TIdStr.StripTrailingOnce(const AText: AnsiString): Boolean;
var
  LLength: Integer;
begin
  LLength := TIdStrings.Length(AText);
  Result := (LLength > 0) and (System.Length(FText) >= LLength) and
    (TIdStrings.Cmpn(AText, Copy(FText, System.Length(FText) - LLength + 1, LLength), LLength) = 0);
  if Result then
    SetLength(FText, System.Length(FText) - LLength);
end;

procedure TIdStr.Strip(const AChar: AnsiChar);
begin
  StripLeading(AChar);
  StripTrailing(AChar);
end;

procedure TIdStr.Strip(const AText: AnsiString);
begin
  StripLeading(AText);
  StripTrailing(AText);
end;

procedure TIdStr.StripTrailingWhitespace;
var
  LLength: Integer;
begin
  LLength := System.Length(FText);
  // unsigned comparison: the high ASCII characters are not stripped
  while (LLength > 0) and (Byte(FText[LLength]) <= Ord(' ')) do
    Dec(LLength);
  SetLength(FText, LLength);
end;

procedure TIdStr.StripQuotes;
begin
  if (System.Length(FText) = 0) or (FText[1] <> '"') then
    Exit;
  if (System.Length(FText) > 0) and (FText[System.Length(FText)] = '"') then
    SetLength(FText, System.Length(FText) - 1);
  Delete(FText, 1, 1);
end;

procedure TIdStr.Replace(const AOld, ANew: AnsiString);
var
  LOldLength, LIndex: Integer;
  LResult: AnsiString;
begin
  LOldLength := TIdStrings.Length(AOld);
  if LOldLength = 0 then
    Exit;
  LResult := '';
  LIndex := 1;
  while LIndex <= System.Length(FText) do
  begin
    if (LIndex + LOldLength - 1 <= System.Length(FText)) and (Copy(FText, LIndex, LOldLength) = Copy(AOld, 1, LOldLength)) then
    begin
      LResult := LResult + Copy(ANew, 1, TIdStrings.Length(ANew));
      Inc(LIndex, LOldLength);
    end
    else
    begin
      LResult := LResult + FText[LIndex];
      Inc(LIndex);
    end;
  end;
  FText := LResult;
end;

function TIdStr.FileNameHash: Integer;
begin
  Result := TIdStrings.FileNameHash(FText);
end;

procedure TIdStr.BackSlashesToSlashes;
var
  LIndex: Integer;
begin
  for LIndex := 1 to System.Length(FText) do
    if FText[LIndex] = '\' then
      FText[LIndex] := '/';
end;

procedure TIdStr.StripFileExtension;
var
  LIndex: Integer;
begin
  for LIndex := System.Length(FText) downto 1 do
    if FText[LIndex] = '.' then
    begin
      SetLength(FText, LIndex - 1);
      Exit;
    end;
end;

procedure TIdStr.StripAbsoluteFileExtension;
var
  LIndex: Integer;
begin
  for LIndex := 1 to System.Length(FText) do
    if FText[LIndex] = '.' then
    begin
      SetLength(FText, LIndex - 1);
      Exit;
    end;
end;

procedure TIdStr.SetFileExtension(const AExtension: AnsiString);
begin
  StripFileExtension;
  if (System.Length(AExtension) = 0) or (AExtension[1] <> '.') then
    Append('.');
  Append(AExtension);
end;

procedure TIdStr.DefaultFileExtension(const AExtension: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := System.Length(FText) downto 1 do
    if FText[LIndex] = '.' then
      Exit;
  if (System.Length(AExtension) = 0) or (AExtension[1] <> '.') then
    Append('.');
  Append(AExtension);
end;

procedure TIdStr.DefaultPath(const ABasePath: AnsiString);
begin
  if (System.Length(FText) > 0) and ((FText[1] = '/') or (FText[1] = '\')) then
    Exit;
  FText := ABasePath + FText;
end;

procedure TIdStr.AppendPath(const AText: AnsiString);
var
  LIndex: Integer;
begin
  if System.Length(AText) = 0 then
    Exit;
  if System.Length(FText) > 0 then
    if FText[System.Length(FText)] <> '/' then
      FText := FText + '/';
  LIndex := 1;
  if AText[LIndex] = '/' then
    Inc(LIndex);
  while LIndex <= System.Length(AText) do
  begin
    if AText[LIndex] = '\' then
      FText := FText + '/'
    else
      FText := FText + AText[LIndex];
    Inc(LIndex);
  end;
end;

procedure TIdStr.StripFilename;
var
  LPosition: Integer;
begin
  LPosition := System.Length(FText) - 1;
  while (LPosition > 0) and (FText[LPosition + 1] <> '/') and (FText[LPosition + 1] <> '\') do
    Dec(LPosition);
  if LPosition < 0 then
    LPosition := 0;
  CapLength(LPosition);
end;

procedure TIdStr.StripPath;
var
  LPosition: Integer;
begin
  LPosition := System.Length(FText);
  while (LPosition > 0) and (FText[LPosition] <> '/') and (FText[LPosition] <> '\') do
    Dec(LPosition);
  Self := Right(System.Length(FText) - LPosition);
end;

function TIdStr.ExtractFilePath: TIdStr;
var
  LPosition: Integer;
begin
  LPosition := System.Length(FText);
  while (LPosition > 0) and (FText[LPosition] <> '/') and (FText[LPosition] <> '\') do
    Dec(LPosition);
  Result := Left(LPosition);
end;

function TIdStr.ExtractFileName: TIdStr;
var
  LPosition: Integer;
begin
  LPosition := System.Length(FText) - 1;
  while (LPosition > 0) and (FText[LPosition] <> '/') and (FText[LPosition] <> '\') do
    Dec(LPosition);
  Result := Right(System.Length(FText) - LPosition);
end;

function TIdStr.ExtractFileBase: TIdStr;
var
  LPosition, LStart: Integer;
begin
  LPosition := System.Length(FText) - 1;
  while (LPosition > 0) and (FText[LPosition] <> '/') and (FText[LPosition] <> '\') do
    Dec(LPosition);
  LStart := LPosition;
  // for an empty string the position is -1: the original reads the byte before the buffer, here it is "not a dot"
  while (LPosition < System.Length(FText)) and ((LPosition < 0) or (FText[LPosition + 1] <> '.')) do
    Inc(LPosition);
  Result := Mid(LStart, LPosition - LStart);
end;

function TIdStr.ExtractFileExtension: TIdStr;
var
  LPosition: Integer;
begin
  LPosition := System.Length(FText) - 1;
  while (LPosition > 0) and (FText[LPosition] <> '.') do
    Dec(LPosition);
  if LPosition = 0 then
    Result.FText := ''
  else
    Result := Right(System.Length(FText) - LPosition);
end;

function TIdStr.CheckExtension(const AExtension: AnsiString): Boolean;
begin
  Result := TIdStrings.CheckExtension(FText, AExtension);
end;

end.
