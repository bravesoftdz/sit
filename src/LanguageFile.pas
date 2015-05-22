{ *********************************************************************** }
{                                                                         }
{ PM Code Works Cross Plattform Language Handler Unit v1.4                }
{                                                                         }
{ Copyright (c) 2011-2015 Philipp Meisberger (PM Code Works)              }
{                                                                         }
{ *********************************************************************** }

unit LanguageFile;

{$IFDEF LINUX} {$mode objfpc}{$H+} {$ENDIF}

interface

uses
  Classes, SysUtils, Forms,
{$IFDEF MSWINDOWS}
  Windows, AddDialogs;
{$ELSE}
  IniFileParser, LCLType;
{$ENDIF}

const
  { Flag indicating line feed }
  NEW_LINE = 1023;

{$IFDEF LINUX}
  { Interval for next language }
  LANGUAGE_INTERVAL = 100;
{$ENDIF}

type
  { Exception class }
  ELanguageException = class(Exception);

  { IChangeLanguageListener }
  IChangeLanguageListener = interface
  ['{FF4AAD19-49DC-403B-8EA0-3E24D984B603}']
    procedure SetLanguage(Sender: TObject);
  end;

  { MessageBox look }
  TMessageType = (mtInfo, mtWarning, mtQuestion, mtConfirm, mtError);

  { TLanguageFile }
  TLanguageFile = class(TObject)
  private
  {$IFDEF LINUX}
    FLang: string;
    FIni: TIniFile;
  {$ELSE}
    FLang: Word;
  {$ENDIF}
    FApplication: TApplication;
  protected
    FListeners: TInterfaceList;
  public
  {$IFDEF MSWINDOWS}
    constructor Create(ALanguage: Word; AApplication: TApplication);
  {$ELSE}
    constructor Create(ALanguage: string; AConfig: string = '';
      AApplication: TApplication = nil);
  {$ENDIF}
    destructor Destroy; override;
    procedure AddListener(AListener: IChangeLanguageListener);
    procedure ChangeLanguage(ASender: TObject;
      {$IFDEF MSWINDOWS}ALangID: Word{$ELSE}ALang: string{$ENDIF});
    function Format(const AIndex: Word; const AArgs: array of
      {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string; overload;
    function Format(const AIndexes: array of Word; const AArgs: array of
      {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string; overload;
  {$IFDEF LINUX}
    procedure GetLanguages(ASections: TStrings);
  {$ENDIF}
    function GetString(const AIndex: Word): string; overload;
    function GetString(const AIndexes: array of Word): string; overload;
    function MessageBox(AText: string; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function MessageBox(AText: Word; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function MessageBox(AIndexes: array of Word; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function MessageBox(AIndexes: array of Word;
      AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
      AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer; overload;
    procedure ShowException(AContent, AInformation: string;
      AOptions: TTaskDialogOptions = []);
    function TaskDialog(AText: string; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function TaskDialog(APrompt, AText: string; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function TaskDialog(APrompt, AText: Word; AType: TMessageType = mtInfo;
      AUpdate: Boolean = False): Integer; overload;
    function TaskDialog(APrompt: Word; AIndexes: array of Word;
      AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer; overload;
    function TaskDialog(APrompt: Word; AIndexes: array of Word;
      AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
      AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer; overload;
    procedure RemoveListener(AListener: IChangeLanguageListener);
    { external }
    property Lang: {$IFDEF LINUX}string{$ELSE}Word{$ENDIF} read FLang write FLang;
  end;

implementation

{ TLanguageFile }

{ public TLanguageFile.Create

  Constructor for creating a TLanguageFile instance. }

{$IFDEF MSWINDOWS}
{$R 'lang.res' 'lang.rc'}

constructor TLanguageFile.Create(ALanguage: Word; AApplication: TApplication);
begin
  inherited Create;
  FLang := ALanguage;
  FApplication := AApplication;
  FListeners := TInterfaceList.Create;
end;

{ public TLanguageFile.Destroy

  Destructor for destroying a TLanguageFile instance. }

destructor TLanguageFile.Destroy;
begin
  FreeAndNil(FListeners);
  inherited Destroy;
end;
{$ENDIF}

{$IFDEF LINUX}
constructor TLanguageFile.Create(ALanguage: string; AConfig: string = '';
  AApplication: TApplication = nil);
begin
  if (AConfig = '') then
    AConfig := ExtractFilePath(ParamStr(0)) +'lang';

  if not FileExists(AConfig) then
    raise ELanguageException.Create('"'+ AConfig +'" not found!');

  FLang := ALanguage;
  FIni := TIniFile.Create(AConfig);
  FApplication := AApplication;
  FListeners := TInterfaceList.Create;
end;

{ public TLanguageFile.Destroy

  Destructor for destroying a TLanguageFile instance. }

destructor TLanguageFile.Destroy;
begin
  FIni.Free;
  FreeAndNil(FListeners);
  inherited Destroy;
end;

{ public TLanguageFile.GetString

  Loads a string from a *.ini file based language file. }

function TLanguageFile.GetString(const AIndex: Word): string;
begin
  Result := FIni.ReadString(FLang, IntToStr(AIndex + LANGUAGE_INTERVAL));
end;

{ public TLanguageFile.GetLanguages

  Returns a list containing all available languages. }

procedure TLanguageFile.GetLanguages(ASections: TStrings);
begin
  FIni.GetSections(ASections);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

{ public TLanguageFile.GetString

  Loads a single string from a StringTable file based language file. }

function TLanguageFile.GetString(const AIndex: Word): string;
var
  Buffer: array[0..80] of Char;

begin
  if (LoadString(HInstance, FLang + AIndex, Buffer, SizeOf(Buffer)) = 0) then
    raise ELanguageException.Create(SysUtils.Format(SysErrorMessage(
      ERROR_RESOURCE_LANG_NOT_FOUND) +'. ID %d', [AIndex]));

  Result := Buffer;
end;
{$ENDIF}

{ public TLanguageFile.GetString

  Loads multiple strings from a StringTable file based language file. }

function TLanguageFile.GetString(const AIndexes: array of Word): string;
var
  i: Word;
  Text: string;

begin
  for i := 0 to Length(AIndexes) -1 do
    if (AIndexes[i] = NEW_LINE) then
      Text := Text + sLineBreak
    else
      Text := Text + GetString(AIndexes[i]);

  Result := Text;
end;

{ public TLanguageFile.AddListener

  Adds a listener to the notification list. }

procedure TLanguageFile.AddListener(AListener: IChangeLanguageListener);
begin
  FListeners.Add(AListener);
end;

{ public TLanguageFile.ChangeLanguage

  Allows users to change the language. }

procedure TLanguageFile.ChangeLanguage(ASender: TObject;
  {$IFDEF MSWINDOWS}ALangID: Word{$ELSE}ALang: string{$ENDIF});
var
  i: Word;
  Listener: IChangeLanguageListener;

begin
  // Only change language when it differs from current
  if (FLang = ALangID) then
    Exit;

{$IFDEF MSWINDOWS}
  FLang := ALangID;
{$ELSE}
  FLang := ALang;
{$ENDIF}

  // Notify all listeners
  for i := 0 to FListeners.Count - 1 do
    if Supports(FListeners[i], IChangeLanguageListener, Listener) then
      Listener.SetLanguage(Self);
end;

{ public TLanguageFile.Format

  Embeds data into a single string by replacing a special flag starting with %. }

function TLanguageFile.Format(const AIndex: Word; const AArgs: array of
  {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string;
begin
  Result := SysUtils.Format(GetString(AIndex), AArgs);
end;

{ public TLanguageFile.Format

  Embeds data into a multiple strings by replacing a special flag starting with %. }

function TLanguageFile.Format(const AIndexes: array of Word;
  const AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string;
var
  i: Word;
  Text: string;

begin
  for i := 0 to Length(AIndexes) -1 do
    if (AIndexes[i] = NEW_LINE) then
      Text := Text + sLineBreak
    else
      Text := Text + Format(AIndexes[i], AArgs);

  Result := Text;
end;

{ public TLanguageFile.MessageBox

  Shows a MessageBox with text and specific look. }

function TLanguageFile.MessageBox(AText: string; AType: TMessageType = mtInfo;
  AUpdate: Boolean = False): Integer;
var
  Title: string;
  Flags: Integer;

begin
  Flags := 0;

  case AType of
    mtInfo:
      begin
        Title := GetString(0);
        Flags := MB_ICONINFORMATION;
      end;

    mtWarning:
      begin
        Title := GetString(1);
        Flags := MB_ICONWARNING;
      end;

    mtQuestion:
      begin
        Title := GetString(3);
        Flags := MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON1;
      end;

    mtConfirm:
      begin
        Title := GetString(4);
        Flags := MB_ICONWARNING or MB_YESNO or MB_DEFBUTTON2;
      end;

    mtError:
      begin
        Title := GetString(2);
        Flags := MB_ICONERROR;
      end;
  end;  //of case

  if AUpdate then
    Title := GetString(5);

  Result := FApplication.MessageBox(PChar(AText), PChar(Title), Flags);
end;

{ public TLanguageFile.MessageBox

  Shows a MessageBox with text and specific look. }

function TLanguageFile.MessageBox(AText: Word; AType: TMessageType = mtInfo;
  AUpdate: Boolean = False): Integer;
begin
  Result := MessageBox(GetString(AText), AType, AUpdate);
end;

{ public TLanguageFile.MessageBox

  Shows a MessageBox with multiple string text and specific look. }

function TLanguageFile.MessageBox(AIndexes: array of Word;
  AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer;
begin
  Result := MessageBox(GetString(AIndexes), AType, AUpdate);
end;

{ public TLanguageFile.MessageBox

  Shows a MessageBox with multiple formatted string text and specific look. }

function TLanguageFile.MessageBox(AIndexes: array of Word;
  AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
  AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer;
begin
  Result := MessageBox(Format(AIndexes, AArgs), AType, AUpdate);
end;

{ public TLanguageFile.ShowException

  Shows an exception with additional information. }

procedure TLanguageFile.ShowException(AContent, AInformation: string;
  AOptions: TTaskDialogOptions = []);
{$IFDEF MSWINDOWS}

  function EncodeUri(const AText: string): string;
  begin
    Result := StringReplace(AText, '!', '%21', [rfReplaceAll]);
    Result := StringReplace(Result, ' ', '%20', [rfReplaceAll]);
  end;

var
  TaskDialog: TTaskDialog;
  MailSubject, MailBody: string;

{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  // TaskDialogIndirect only possible for Windows >= Vista!
  if not ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion >= 6)) then
  begin
    MessageBox(GetString(31) +': '+ AContent + sLineBreak + AInformation, mtError);
    Exit;
  end;  //of begin

  TaskDialog := TTaskDialog.Create(FApplication.MainForm);

  try
    with TaskDialog do
    begin
      Title := FApplication.Name;
      Icon := tiError;
      Instruction := GetString(31);
      Content := AContent;
      ExpandedInformation := AInformation;
      ExpandedControlText := GetString(33);
      CollapsedControlText := GetString(32);
      MailSubject := EncodeUri('Bug Report '+ FApplication.Title);
      MailBody := EncodeUri('Dear PM Code Works,%0A%0AI found a possible '+
        'bug:%0A'+ AInformation);
      Footer := '<a href="mailto:team@pm-codeworks.de?subject='+ MailSubject +
        '&body='+ MailBody +'">'+ GetString(26) +'</a>';
      Options := [doExpandFooter, doHyperlinks] + AOptions;
      CommonButtons := [cbClose];
    end;  //of with

    MessageBeep(MB_ICONERROR);

    if not TaskDialog.Execute() then
      MessageBox(GetString(31) +': '+ AContent + sLineBreak + AInformation, mtError);
    
  finally
    TaskDialog.Free;
  end;  //of try
{$ELSE}
  Result := MessageBox(GetString(31) +': '+ AContent + sLineBreak + AInformation,
    mtError);
{$ENDIF}
end;

{ public TLanguageFile.TaskDialog

  Shows a TaskDialog with text and specific look. }

function TLanguageFile.TaskDialog(AText: string; AType: TMessageType = mtInfo;
  AUpdate: Boolean = False): Integer;
begin
  Result := TaskDialog('', AText, AType, AUpdate);
end;

{ public TLanguageFile.TaskDialog

  Shows a TaskDialog with text and specific look. }

function TLanguageFile.TaskDialog(APrompt, AText: string; AType: TMessageType = mtInfo;
  AUpdate: Boolean = False): Integer;
{$IFDEF MSWINDOWS}
var
  Title: string;
  Buttons: TCommonButtons;
  Icon: TTaskDialogIcon;

begin
  // TaskDialog only possible for Windows >= Vista!
  if not ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion >= 6)) then
  begin
    Result := MessageBox(APrompt + sLineBreak + AText, AType, AUpdate);
    Exit;
  end;  //of begin

  Buttons := [cbOk];
  Icon := tiBlank;

  case AType of
    mtInfo:
      begin
        Title := GetString(0);
        Icon := tiInformation;
        MessageBeep(MB_ICONINFORMATION);
      end;

    mtWarning:
      begin
        Title := GetString(1);
        Icon := tiWarning;
        MessageBeep(MB_ICONWARNING);
      end;

    mtQuestion:
      begin
        Title := GetString(3);
        Buttons := [cbYes, cbNo];
        Icon := tiQuestion;
        MessageBeep(MB_ICONQUESTION);
      end;

    mtConfirm:
      begin
        Title := GetString(4);
        Buttons := [cbYes, cbNo];
        Icon := tiWarning;
        MessageBeep(MB_ICONWARNING);
      end;

    mtError:
      begin
        Title := GetString(2);
        Buttons := [cbClose];
        Icon := tiError;
        MessageBeep(MB_ICONERROR);
      end;
  end;  //of case

  if AUpdate then
    Title := GetString(5);

  try
    Result := ShowTaskDialog(FApplication.MainForm, Title, APrompt, AText,
      Buttons, Icon);

  except
    Result := MessageBox(APrompt + sLineBreak + AText, AType, AUpdate);
  end;  //of try
{$ELSE}
  Result := MessageBox(APrompt + sLineBreak + AText, AType, AUpdate);
{$ENDIF}
end;

{ public TLanguageFile.TaskDialog

  Shows a TaskDialog with text and specific look. }

function TLanguageFile.TaskDialog(APrompt, AText: Word; AType: TMessageType = mtInfo;
  AUpdate: Boolean = False): Integer;
begin
  Result := TaskDialog(GetString(APrompt), GetString(AText), AType, AUpdate);
end;

{ public TLanguageFile.TaskDialog

  Shows a TaskDialog with multiple string text and specific look. }

function TLanguageFile.TaskDialog(APrompt: Word; AIndexes: array of Word;
  AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer;
begin
  Result := TaskDialog(GetString(APrompt), GetString(AIndexes), AType, AUpdate);
end;

{ public TLanguageFile.TaskDialog

  Shows a TaskDialog with multiple formatted string text and specific look. }

function TLanguageFile.TaskDialog(APrompt: Word; AIndexes: array of Word;
  AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
  AType: TMessageType = mtInfo; AUpdate: Boolean = False): Integer;
begin
  Result := TaskDialog(GetString(APrompt), Format(AIndexes, AArgs), AType, AUpdate);
end;

{ public TLanguageFile.RemoveListener

  Removes a listener from the notification list. }

procedure TLanguageFile.RemoveListener(AListener: IChangeLanguageListener);
begin
  FListeners.Remove(AListener);
end;

end.
