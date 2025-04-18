{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2005-2023, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Utility functions used when processing RTF.
}


unit URTFUtils;


interface


uses
  // Delphi
  SysUtils, Classes,
  // Project
  UEncodings;


type
  ///  <summary>Enumeration containing identifiers for each supported RTF
  ///  control word.</summary>
  TRTFControl = (
    rcRTF,                  // RTF version
    rcAnsi,                 // use ANSI character set
    rcAnsiCodePage,         // specifies ANSI code page
    rcDefFontNum,           // default font number
    rcDefLanguage,          // default language
    rcFontTable,            // introduces font table
    rcFontPitch,            // font pitch
    rcFontCharset,          // font character set
    rcFontFamilyNil,        // unknown font family
    rcFontFamilyRoman,      // serif, proportional fonts
    rcFontFamilySwiss,      // sans-serif, proportional fonts
    rcFontFamilyModern,     // fixed pitch serif and sans-serif fonts
    rcFontFamilyScript,     // script fonts
    rcFontFamilyDecor,      // decorative fonts
    rcFontFamilyTech,       // technical, symbol and maths fonts
    rcColorTable,           // introduces colour table
    rcRed,                  // defines red colour component
    rcGreen,                // defines gree colour component
    rcBlue,                 // defines blue colour component
    rcInfo,                 // introduces information group
    rcTitle,                // sets document title
    rcPard,                 // resets to default paragraph format
    rcPar,                  // begins new paragraph
    rcPlain,                // reset font (character) formatting properties
    rcFontNum,              // font number (index to font table)
    rcForeColorNum,         // foreground colour number (index to colour table)
    rcBold,                 // sets or toggles bold style
    rcItalic,               // sets or toggles italic style
    rcUnderline,            // sets or toggles underline style
    rcFontSize,             // font size in 1/2 points
    rcSpaceBefore,          // space before paragraphs in twips
    rcSpaceAfter,           // space after paragraph in twips
    rcUnicodeChar,          // defines a Unicode character as signed 16bit value
    rcUnicodePair,          // introduces pair of ANSI and Unicode destinations
    rcUnicodeDest,          // introduces Unicode destination
    rcIgnore,               // denotes following control can be ignored
    rcFirstLineOffset,      // first line indent in twips (relative to \li)
    rcLeftIndent,           // left indent in twips
    rcTabStop               // sets a tab stop in twips
  );

type
  ///  <summary>Container for related methods for generating valid RTF control
  ///  words and destinations.</summary>
  TRTF = record
  strict private
    const
      ///  <summary>Map of RTF control ids to control words.</summary>
      Controls: array[TRTFControl] of ASCIIString = (
        'rtf', 'ansi', 'ansicpg', 'deff', 'deflang', 'fonttbl', 'fprq',
        'fcharset', 'fnil', 'froman', 'fswiss', 'fmodern', 'fscript', 'fdecor',
        'ftech', 'colortbl', 'red', 'green', 'blue', 'info', 'title', 'pard',
        'par', 'plain', 'f', 'cf', 'b', 'i', 'ul', 'fs', 'sb', 'sa', 'u', 'upr',
        'ud', '*', 'fi', 'li', 'tx'
      );
  strict private

    ///  <summary>Returns an RTF escape sequence for an ASCII character.
    ///  </summary>
    ///  <param name="ACh"><c>AnsiChar</c> [in] Character to be escaped.</param>
    ///  <returns><c>ASCIIString</c>. The required escape sequence.</returns>
    ///  <remarks><c>ACh</c> should be a valid ASCII character, but this is not
    ///  checked.</remarks>
    class function Escape(const ACh: AnsiChar): ASCIIString; static;

    ///  <summary>Returns an RTF hex escape sequence for a single byte
    ///  character.</summary>
    ///  <param name="ACh"><c>AnsiChar</c> [in] Character to be escaped.</param>
    ///  <returns><c>ASCIIString</c>. The required hex escape sequence.
    ///  </returns>
    class function HexEscape(const Ch: AnsiChar): ASCIIString; static;

  public
    const
      ///  <summary>RTF major version number.</summary>
      Version = 1;

  public

    ///  <summary>Returns a parameterless RTF control word.</summary>
    ///  <param name="ACtrlID"><c>TRTFControl</c> [in] Identifies the required
    ///  control.</param>
    ///  <returns><c>ASCIIString</c>. The required control word.</returns>
    class function ControlWord(const ACtrlID: TRTFControl): ASCIIString;
      overload; static;

    ///  <summary>Returns a parameterised RTF control word.</summary>
    ///  <param name="ACtrlID"><c>TRTFControl</c> [in] Identifies the required
    ///  control.</param>
    ///  <param name="AParam"><c>Int16</c> [in] The control's parameter value.
    ///  </param>
    ///  <returns><c>ASCIIString</c>. The required control word.</returns>
    ///  control word identified by <c>Ctrl</c> with the parameter specified
    class function ControlWord(const ACtrlID: TRTFControl; const AParam: Int16):
      ASCIIString; overload; static;

    ///  <summary>Converts Unicode text into valid RTF when encoded in a given
    ///  ANSI code page.</summary>
    ///  <param name="AText"><c>string</c> [in] The Unicode text to be
    ///  processed.</param>
    ///  <param name="ACodePage"><c>Integer</c> [in] ANSI code to be used for
    ///  encoding the Unicode text.</param>
    ///  <returns><c>ASCIIString</c>. Valid RTF code for the given code page.
    ///  </returns>
    ///  <remarks>Converted characters are escaped if necessary. Any characters
    ///  that are not valid in the required code page are encoded in a Unicode
    ///  RTF control word with <c>?</c> as the non-Unicode fallback.</remarks>
    class function MakeSafeText(const AText: string; const ACodePage: Integer):
      ASCIIString; static;

    ///  <summary>Creates an RTF destination in a Unicode safe way.</summary>
    ///  <param name="ADestCtrl"><c>TRTFControl</c> [in] Required destination
    ///   control.</param>
    ///  <param name="ADestText"><c>string</c> [in] Unicode text to be included
    ///  in the destination.</param>
    ///  <param name="ACodePage"><c>Integer</c> [in] ANSI Code page to use for
    ///  encoding the Unicode text.</param>
    ///  <returns><c>ASCIIString</c>. Destination RTF, containing ANSI and
    ///  Unicode sub-destinations if necessary.</returns>
    ///  <remarks>If <c>ADestText</c> contains only characters supported by
    ///  <c>ACodePage</c> then a single, normal destination is returned,
    ///  containing the encoded text, escaped as necessary. Should any
    ///  characters in <c>ADestText</c> be incompatible with the code page then
    ///  two sub-destinations are created, one containing Unicode characters and
    ///  the other containing ANSI text, with unknown characters flagged with
    ///  &quot;error&quot; characters such as <c>?</c>.</remarks>
    class function UnicodeSafeDestination(const ADestCtrl: TRTFControl;
      const ADestText: string; const ACodePage: Integer): ASCIIString; static;
  end;

type
  ///  <summary>Encapsulate rich text markup code.</summary>
  ///  <remarks>Valid rich text markup contains only ASCII characters.</remarks>
  TRTFMarkup = record
  strict private
    var
      ///  <summary>Byte array that stores RTF code as bytes</summary>
      fData: TBytes;
  public
    ///  <summary>Initialises record from raw binary data.</summary>
    ///  <param name="ABytes">TBytes [in] Array storing RTF code as bytes.
    ///  </param>
    constructor Create(const ABytes: TBytes); overload;
    ///  <summary>Initialises record from a stream of character data.</summary>
    ///  <param name="AStream">TStream [in] Stream containing RTF code.</param>
    ///  <param name="AEncoding">TEncoding [in] Encoding to be used to decode
    ///  characters in stream.</param>
    ///  <param name="ReadAll">Boolean [in] Flag that indicates if the whole
    ///  stream is to be read (True) or stream is to be read from current
    ///  position (False).</param>
    constructor Create(const AStream: TStream; const ReadAll: Boolean = False);
      overload;
    ///  <summary>Initialises record from ASCII RTF code.</summary>
    ///  <param name="ARTFCode">ASCIIString [in] ASCII string containing RTF
    ///  code.</param>
    constructor Create(const ARTFCode: ASCIIString); overload;
    ///  <summary>Initialises record from RTF code stored in Unicode string.
    ///  </summary>
    ///  <param name="AStr">UnicodeString [in] Unicode string containing ASCII
    ///  code.</param>
    ///  <remarks>An exception is raised if AStr contains any non-ASCII
    ///  characters.</remarks>
    constructor Create(const AStr: UnicodeString); overload;
    ///  <summary>Initialises record from encoded data.</summary>
    ///  <param name="AData">TEncodedData [in] Encoded data record containing
    ///  RTF code.</param>
    ///  <remarks>An exception is raised if AData contains any non-ASCII
    ///  characters.</remarks>
    constructor Create(const AData: TEncodedData); overload;
    ///  <summary>Returns RTF code as an array of bytes.</summary>
    function ToBytes: TBytes;
    ///  <summary>Returns RTF code as an ASCII string.</summary>
    function ToRTFCode: ASCIIString;
    ///  <summary>Returns RTF code as a Unicode string.</summary>
    ///  <remarks>Returned string contains only ASCII characters.</remarks>
    function ToString: UnicodeString;
    ///  <summary>Copies RTF code to a stream, optionally overwriting any
    ///  existing content in the stream.</summary>
    procedure ToStream(const Stream: TStream; const Overwrite: Boolean = False);
    ///  <summary>Checks if a Unicode string contains only valid RTF characters.
    ///  </summary>
    function IsValidRTFCode(const AStr: UnicodeString): Boolean;
  end;

type
  ///  <summary>Class of exception raised by TRTFMarkup</summary>
  ERTFMarkup = class(Exception);


implementation


uses
  // Project
  UExceptions;


{ TRTF }

class function TRTF.ControlWord(const ACtrlID: TRTFControl): ASCIIString;
begin
  Result := '\' + Controls[ACtrlID];
end;

class function TRTF.ControlWord(const ACtrlID: TRTFControl;
  const AParam: Int16): ASCIIString;
begin
  Result := ControlWord(ACtrlID) + StringToASCIIString(IntToStr(AParam));
end;

class function TRTF.Escape(const ACh: AnsiChar): ASCIIString;
begin
  Result := AnsiChar('\') + ACh;
end;

class function TRTF.HexEscape(const Ch: AnsiChar): ASCIIString;
begin
  Result := StringToASCIIString('\''' + IntToHex(Ord(Ch), 2));
end;

class function TRTF.MakeSafeText(const AText: string; const ACodePage: Integer):
  ASCIIString;
var
  Ch: Char;                     // each Unicode character in TheText
  AnsiChars: TArray<AnsiChar>;  // translation of a Ch into the ANSI code page
  AnsiCh: AnsiChar;             // each ANSI char in AnsiChars
begin
  Result := '';
  // Process each Unicode character in turn
  for Ch in AText do
  begin
    // Convert Unicode char into one or more ANSI chars in required code page
    if WideCharToChar(Ch, ACodePage, AnsiChars) then
    begin
      // Conversion succeeded: check process each ANSI char
      for AnsiCh in AnsiChars do
      begin
        if (AnsiCh < #$20) or ((AnsiCh >= #$7F) and (AnsiCh <= #$FF)) then
          // Not an ASCII character
          Result := Result + HexEscape(AnsiCh)
        else if (Ch = '{') or (Ch = '\') or (Ch = '}') then
          // Reserved RTF character: must be escaped
          Result := Result + Escape(AnsiCh)
        else
          // Valid character, use as is
          Result := Result + ASCIIString(AnsiCh);
      end;
    end
    else
      // Conversion failed: we store Unicode char in a Unicode control word
      Result := Result
        + ControlWord(rcUnicodeChar, SmallInt(Ord(Ch)))
        + ' ?';   // fallback "unprintable" value
  end;
end;

class function TRTF.UnicodeSafeDestination(const ADestCtrl: TRTFControl;
  const ADestText: string; const ACodePage: Integer): ASCIIString;

  //  Makes a destination for ADestCtrl using given text.
  function MakeDestination(const S: string): ASCIIString;
  begin
    Result := '{'
      + ControlWord(ADestCtrl)
      + ' '
      + MakeSafeText(S, ACodePage)
      + '}'
  end;

var
  Encoding: TEncoding;  // encoding for ACodePage
  AnsiStr: string;      // Unicode string containing only chars from ACodePage
begin
  if CodePageSupportsString(ADestText, ACodePage) then
    // All chars of ADestText supported in code page => RTF text won't have any
    // \u characters => we can just output destination as normal
    Result := MakeDestination(ADestText)
  else
  begin
    // ADestText contains characters not supported by code page. We create twin
    // destinations, one ANSI only and the other that includes Unicode
    // characters.
    Encoding := TMBCSEncoding.Create(ACodePage);
    try
      // Create a Unicode string that contains only characters supported in
      // given code page (+ some "error" characters (e.g. "?")
      AnsiStr := Encoding.GetString(Encoding.GetBytes(ADestText));
    finally
      Encoding.Free;
    end;
    Result := '{'
      + ControlWord(rcUnicodePair)
      + MakeDestination(AnsiStr)    // ANSI only destination
      + '{'
      + ControlWord(rcIgnore)
      + ControlWord(rcUnicodeDest)
      + MakeDestination(ADestText)   // Unicode destinatation
      + '}'
      + '}';
  end;
end;

{ TRTFMarkup }

constructor TRTFMarkup.Create(const AStream: TStream; const ReadAll: Boolean);
var
  ByteCount: Integer;
begin
  if ReadAll then
    AStream.Position := 0;
  ByteCount := AStream.Size - AStream.Position;
  SetLength(fData, ByteCount);
  AStream.ReadBuffer(Pointer(fData)^, ByteCount);
end;

constructor TRTFMarkup.Create(const ABytes: TBytes);
begin
  fData := Copy(ABytes);
end;

constructor TRTFMarkup.Create(const AData: TEncodedData);
resourcestring
  sErrorMsg = 'Encoded data must contain only valid ASCII characters';
var
  DataStr: string;
begin
  if AData.EncodingType = etASCII then
    fData := Copy(AData.Data)
  else
  begin
    DataStr := AData.ToString;
    if not IsValidRTFCode(DataStr) then
      raise ERTFMarkup.Create(sErrorMsg);
    fData := TEncoding.ASCII.GetBytes(DataStr);
  end;
end;

constructor TRTFMarkup.Create(const ARTFCode: ASCIIString);
begin
  fData := BytesOf(ARTFCode);
end;

constructor TRTFMarkup.Create(const AStr: UnicodeString);
resourcestring
  sErrorMsg = 'String "%s" must contain only valid ASCII characters';
begin
  if not IsValidRTFCode(AStr) then
    raise ERTFMarkup.CreateFmt(sErrorMsg, [AStr]);
  fData := TEncoding.ASCII.GetBytes(AStr);
end;

function TRTFMarkup.IsValidRTFCode(const AStr: UnicodeString): Boolean;
begin
  Result := EncodingSupportsString(AStr, TEncoding.ASCII);
end;

function TRTFMarkup.ToBytes: TBytes;
begin
  Result := Copy(fData);
end;

function TRTFMarkup.ToRTFCode: ASCIIString;
begin
  Result := BytesToASCIIString(fData);
end;

procedure TRTFMarkup.ToStream(const Stream: TStream; const Overwrite: Boolean);
begin
  if Overwrite then
  begin
    Stream.Size := Length(fData);
    Stream.Position := 0;
  end;
  Stream.WriteBuffer(Pointer(fData)^, Length(fData));
end;

function TRTFMarkup.ToString: UnicodeString;
begin
  Result := TEncoding.ASCII.GetString(fData);
end;

end.

