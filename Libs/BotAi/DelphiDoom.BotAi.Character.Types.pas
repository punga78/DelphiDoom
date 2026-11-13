{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - types of the bot characters                            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the constants and   }
{  bot_characteristic_t of code\botlib\be_ai_char.c. Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc.                                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Types;

interface

const
  /// <summary>MAX_CHARACTERISTICS: the characteristics a character can be asked for (0..79)</summary>
  MAX_CHARACTERISTICS = 80;

  /// <summary>The types of a characteristic; 0 is a characteristic that is not set</summary>
  CT_INTEGER = 1;
  CT_FLOAT = 2;
  CT_STRING = 3;

  /// <summary>DEFAULT_CHARACTER: the file whose characteristics fill the ones a character does not have</summary>
  DEFAULT_CHARACTER = 'bots/default_c.c';

type
  /// <summary>
  ///   bot_characteristic_t: a number or a text. The union of the original is not needed: the type tells
  ///   which field is meaningful and the code of the original never reads the other one.
  /// </summary>
  TBotCharacteristic = record
    /// <summary>0 (not set), CT_INTEGER, CT_FLOAT or CT_STRING</summary>
    CharType: Byte;
    IntegerValue: Integer;
    FloatValue: Single;
    StringValue: AnsiString;
  end;

implementation

end.
