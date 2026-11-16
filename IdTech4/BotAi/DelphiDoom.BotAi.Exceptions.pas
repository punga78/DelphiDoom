{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - EBotAiException, a misuse of the library               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software), botlib.         }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Exceptions;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The caller asked for something the original would have read or written outside its memory
  ///   (an inventory index that does not exist, a field outside its structure): the original has
  ///   undefined behaviour there, here it is an error.
  /// </summary>
  EBotAiException = class(Exception);

implementation

end.
