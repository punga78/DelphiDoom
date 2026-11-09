{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - shared types (alignments, popups)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Base of the errors of the xcom interface library</summary>
  EXcomUiException = class(Exception);

  /// <summary>TextHAlign: the horizontal alignment of a text</summary>
  TXcomTextHAlign = (haLeft, haCenter, haRight);

  /// <summary>TextVAlign: the vertical alignment of a text</summary>
  TXcomTextVAlign = (vaTop, vaMiddle, vaBottom);

  /// <summary>WindowPopup: how a window opens</summary>
  TXcomWindowPopup = (wpNone, wpHorizontal, wpVertical, wpBoth);

  /// <summary>ArrowShape: the drawing of an arrow button</summary>
  TXcomArrowShape = (arBigUp, arBigDown, arSmallUp, arSmallDown, arSmallLeft, arSmallRight);

  /// <summary>ArrowOrientation: the arrows beside the rows of a list</summary>
  TXcomArrowOrientation = (aoVertical, aoHorizontal);

const
  /// <summary>Unicode::TOK_NL_SMALL: a line break and the small font</summary>
  XCOM_TOKEN_NEWLINE_SMALL = 2;
  /// <summary>Unicode::TOK_COLOR_FLIP: alternates between the primary and the secondary color</summary>
  XCOM_TOKEN_COLOR_FLIP = 1;
  /// <summary>Unicode::TOK_NBSP</summary>
  XCOM_TOKEN_NBSP = $A0;

implementation

end.
