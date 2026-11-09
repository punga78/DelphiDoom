{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - LocalizedText of OpenXcom                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.LocalizedText;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A translated string with markers {0}, {1}... that Arg replaces one after the other. It converts to and
  ///   from string. The text is the code points of the file (UTF-16 here, UTF-8 in the C++): the control tokens
  ///   of the language are #1 (alternate color) and #2 (new line in the small font)
  /// </summary>
  TXcomLocalizedText = record
  strict private
    FText: string;
    FNextArg: Integer;
  public
    constructor Create(const AText: string; ANextArg: Integer = 0);
    /// <summary>
    ///   LocalizedText::arg (the one of a temporary, as tr("X").arg(a).arg(b) uses): a copy where the marker of
    ///   the next argument is replaced by the value and the next argument advances; when the text has no such
    ///   marker the copy is the same text and the number does not advance
    /// </summary>
    function Arg(const AValue: string): TXcomLocalizedText; overload;
    function Arg(AValue: Integer): TXcomLocalizedText; overload;
    function Text: string;
    class operator Implicit(const AValue: string): TXcomLocalizedText;
    class operator Implicit(const AValue: TXcomLocalizedText): string;
  end;

implementation

constructor TXcomLocalizedText.Create(const AText: string; ANextArg: Integer);
begin
  FText := AText;
  FNextArg := ANextArg;
end;

function TXcomLocalizedText.Arg(const AValue: string): TXcomLocalizedText;
var
  LMarker: string;
begin
  LMarker := '{' + IntToStr(FNextArg) + '}';
  if Pos(LMarker, FText) = 0 then
    Exit(Self);
  // all the occurrences are replaced, and the text of the value is not searched again
  Result := TXcomLocalizedText.Create(StringReplace(FText, LMarker, AValue, [rfReplaceAll]), FNextArg + 1);
end;

function TXcomLocalizedText.Arg(AValue: Integer): TXcomLocalizedText;
begin
  Result := Arg(IntToStr(AValue));
end;

function TXcomLocalizedText.Text: string;
begin
  Result := FText;
end;

class operator TXcomLocalizedText.Implicit(const AValue: string): TXcomLocalizedText;
begin
  Result := TXcomLocalizedText.Create(AValue);
end;

class operator TXcomLocalizedText.Implicit(const AValue: TXcomLocalizedText): string;
begin
  Result := AValue.FText;
end;

end.
