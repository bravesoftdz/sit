{ *********************************************************************** }
{                                                                         }
{ PM Code Works Cross Plattform Language Handler Unit v1.5                }
{                                                                         }
{ Copyright (c) 2011-2015 Philipp Meisberger (PM Code Works)              }
{                                                                         }
{ *********************************************************************** }

unit PMCW.LanguageFile;

{$IFDEF LINUX} {$mode objfpc}{$H+} {$ENDIF}

interface

uses
  Classes, SysUtils, Forms, IdURI,
{$IFDEF MSWINDOWS}
  Windows, Dialogs, CommCtrl, System.Generics.Collections, ShellAPI;
{$ELSE}
  IniFileParser, LCLType;
{$ENDIF}

const
  { Flag indicating line feed }
  NEW_LINE     = 1023;

{$IFDEF MSWINDOWS}
  { Flag to load user language }
  LANG_USER    = 0;
{$ELSE}
  LANG_USER    = '';
  LANG_GERMAN  = $07;
  LANG_ENGLISH = $09;
  LANG_FRENCH  = $0c;
{$ENDIF}

type
  { Exception class }
  ELanguageException = class(Exception);

  { IChangeLanguageListener }
  IChangeLanguageListener = interface
  ['{FF4AAD19-49DC-403B-8EA0-3E24D984B603}']
    procedure SetLanguage(Sender: TObject);
  end;

{$IFDEF MSWINDOWS}
  { Balloon tip icon }
  TBalloonIcon = (biNone, biInfo, biWarning, biError, biInfoLarge,
    biWarningLarge, biErrorLarge);
{$ENDIF}

  { TLanguageFile }
  TLanguageFile = class(TObject)
  private
    FLocale: Word;
    FOwner: TComponent;
  {$IFDEF LINUX}
    FLangId: string;
    FIni: TIniFile;
    FLanguages: TDictionary<Word, string>;
  {$ELSE}
    FLangId: Word;
    FLanguages: TDictionary<Word, Word>;
    procedure HyperlinkClicked(Sender: TObject);
  {$ENDIF}
  protected
    FListeners: TInterfaceList;
  public
  {$IFDEF MSWINDOWS}
    constructor Create(AOwner: TComponent);
  {$ELSE}
    constructor Create(AOwner: TComponent; AConfig: string = '');
  {$ENDIF}
    destructor Destroy; override;
    procedure AddListener(AListener: IChangeLanguageListener);
    procedure AddLanguage(ALanguage: Word;
      ALanguageId: {$IFDEF MSWINDOWS}Word{$ELSE}string{$ENDIF});
    procedure ChangeLanguage(ALanguage: Word);
    function Format(const AIndex: Word; const AArgs: array of
      {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string; overload;
    function Format(const AIndexes: array of Word; const AArgs: array of
      {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF}): string; overload;
  {$IFDEF MSWINDOWS}
    function EditBalloonTip(AEditHandle: THandle; ATitle, AText: WideString;
      AIcon: TBalloonIcon = biInfo): Boolean; overload;
    function EditBalloonTip(AEditHandle: THandle; ATitle, AText: Word;
      AIcon: TBalloonIcon = biInfo): Boolean; overload;
  {$ELSE}
    procedure GetLanguages(ALanguageFile: string; ASections: TStrings);
  {$ENDIF}
    function GetString(const AIndex: Word): string; overload;
    function GetString(const AIndexes: array of Word): string; overload;
    procedure RemoveLanguage(ALocale: Word);
    procedure RemoveListener(AListener: IChangeLanguageListener);
    function ShowMessage(AText: string;
      AMessageType: TMsgDlgType = mtInformation): Integer; overload;
    function ShowMessage(ATitle, AText: string;
      AMessageType: TMsgDlgType = mtInformation): Integer; overload;
    function ShowMessage(ATitle, AText: Word;
      AMessageType: TMsgDlgType = mtInformation): Integer; overload;
    function ShowMessage(ATitle: Word; AIndexes: array of Word;
      AMessageType: TMsgDlgType = mtInformation): Integer; overload;
    function ShowMessage(ATitle: Word; AIndexes: array of Word;
      AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
      AMessageType: TMsgDlgType = mtInformation): Integer; overload;
    procedure ShowException(AText, AInformation: string;
      AOptions: TTaskDialogFlags = []);
    { external }
    property Id: {$IFDEF MSWINDOWS}Word{$ELSE}string{$ENDIF} read FLangId;
    property Locale: Word read FLocale;
  end;

implementation

{ TLanguageFile }

{ public TLanguageFile.Create

  Constructor for creating a TLanguageFile instance. }

{$IFDEF MSWINDOWS}
{$R 'lang.res' 'lang.rc'}

constructor TLanguageFile.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FListeners := TInterfaceList.Create;
  FListeners.Add(AOwner);
{$IFDEF LINUX}
  FLanguages := TDictionary<Word, string>.Create;
{$ELSE}
  FLanguages := TDictionary<Word, Word>.Create;
{$ENDIF}
  FLocale := LANG_USER;
end;

{ public TLanguageFile.Destroy

  Destructor for destroying a TLanguageFile instance. }

destructor TLanguageFile.Destroy;
begin
{$IFDEF LINUX}
  if Assigned(FIni) then
    FIni.Free;
{$ENDIF}
  FLanguages.Free;
  FreeAndNil(FListeners);
  inherited Destroy;
end;

{ private TLanguageFile.HyperlinkClicked

  Event that is called when user clicked on hyperlink. }

procedure TLanguageFile.HyperlinkClicked(Sender: TObject);
begin
  if (Sender is TTaskDialog) then
    ShellExecute(0, 'open', PChar((Sender as TTaskDialog).URL), nil, nil, SW_SHOWNORMAL);
end;
{$ELSE}
{ public TLanguageFile.GetString

  Loads a string from a *.ini file based language file. }

function TLanguageFile.GetString(const AIndex: Word): string;
begin
  Result := FIni.ReadString(FLangId, IntToStr(AIndex + 100));
end;

{ public TLanguageFile.GetLanguages

  Returns a list containing all available languages. }

procedure TLanguageFile.GetLanguages(ALanguageFile: string; ASections: TStrings);
begin
  if (ALanguageFile = '') then
    ALanguageFile := ExtractFilePath(ParamStr(0)) +'lang';

  FIni := TIniFile.Create(ALanguageFile);
  FIni.GetSections(ASections);
end;
{$ENDIF}
{$IFDEF MSWINDOWS}
{ public TLanguageFile.EditBalloonTip

  Shows a balloon tip inside an edit field with more comfortable usage. }

function TLanguageFile.EditBalloonTip(AEditHandle: THandle; ATitle, AText: WideString;
  AIcon: TBalloonIcon = biInfo): Boolean;
var
  BalloonTip: TEditBalloonTip;

begin
  FillChar(BalloonTip, SizeOf(BalloonTip), 0);

  with BalloonTip do
  begin
    cbStruct := SizeOf(BalloonTip);
    pszTitle := PChar(ATitle);
    pszText := PChar(AText);
    ttiIcon := Ord(AIcon);
  end;  //of with

  Result := Edit_ShowBalloonTip(AEditHandle, BalloonTip);
end;

function TLanguageFile.EditBalloonTip(AEditHandle: THandle; ATitle, AText: Word;
  AIcon: TBalloonIcon): Boolean;
begin
  Result := EditBalloonTip(AEditHandle, GetString(ATitle), GetString(AText), AIcon);
end;

{ public TLanguageFile.GetString

  Loads a single string from a StringTable file based language file. }

function TLanguageFile.GetString(const AIndex: Word): string;
var
  Buffer: array[0..80] of Char;

begin
  if (LoadString(HInstance, FLangId + AIndex, Buffer, SizeOf(Buffer)) = 0) then
    if (GetLastError() <> 0) then
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

{ public TLanguageFile.AddLanguage

  Adds a language to the list. }
{$IFDEF MSWINDOWS}
procedure TLanguageFile.AddLanguage(ALanguage, ALanguageId: Word);
begin
  FLanguages.Add(MAKELANGID(ALanguage, SUBLANG_DEFAULT), ALanguageId);
end;
{$ELSE}
procedure TLanguageFile.AddLanguage(ALanguage: Word; ALanguageId: string);
begin
  FLanguages.Add(ALanguage, ALanguageId);
end;
{$ENDIF}

{ public TLanguageFile.ChangeLanguage

  Allows users to change the language. }

procedure TLanguageFile.ChangeLanguage(ALanguage: Word);
var
  Locale, i: Word;
  Listener: IChangeLanguageListener;

begin
  // Get user language
  if (ALanguage = LANG_USER) then
    Locale := GetSystemDefaultLCID()
  else
    Locale := MAKELANGID(ALanguage, SUBLANG_DEFAULT);

  // Load default language
  if not FLanguages.ContainsKey(Locale) then
  begin
    Locale := MAKELANGID(LANG_GERMAN, SUBLANG_DEFAULT);

    // Language file contains no default language?
    if not FLanguages.ContainsKey(Locale) then
      raise ELanguageException.Create('No languages not found in language file!');
  end;  //of begin

  FLangId := FLanguages[Locale];
  FLocale := Locale;

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

{ public TLanguageFile.ShowMessage

  Shows a message with text and specific look. }

function TLanguageFile.ShowMessage(AText: string;
  AMessageType: TMsgDlgType = mtInformation): Integer;
begin
  Result := ShowMessage('', AText, AMessageType);
end;

{ public TLanguageFile.ShowMessage

  Shows a message with text and specific look. }

function TLanguageFile.ShowMessage(ATitle, AText: string;
  AMessageType: TMsgDlgType = mtInformation): Integer;
var
  Buttons: TMsgDlgButtons;
  DefaultButton: TMsgDlgBtn;

begin
  DefaultButton := mbOK;

  case AMessageType of
    mtInformation:
      begin
        Buttons := [mbOK];
        DefaultButton := mbOK;
        MessageBeep(MB_ICONINFORMATION);
      end;

    mtWarning:
      begin
        Buttons := [mbOK];
        MessageBeep(MB_ICONWARNING);
      end;

    mtConfirmation:
      begin
        Buttons := mbYesNo;
        DefaultButton := mbYes;
        MessageBeep(MB_ICONWARNING);
      end;

    mtCustom:
      begin
        Buttons := mbYesNo;
        DefaultButton := mbNo;
        AMessageType := mtWarning;
      end;

    mtError:
      begin
        Buttons := [mbClose];
        DefaultButton := mbClose;
        MessageBeep(MB_ICONERROR);
      end;
  end;  //of case

{$IFDEF MSWINDOWS}
  Result := TaskMessageDlg(ATitle, AText, AMessageType, Buttons, 0, DefaultButton);
{$ELSE}
  if (ATitle <> '') then
    Result := MessageDlg(ATitle + sLineBreak + AText, AMessageType, Buttons, 0)
  else
    Result := MessageDlg(AText, AMessageType, Buttons, 0);
{$ENDIF}
end;

{ public TLanguageFile.ShowMessage

  Shows a message with text and specific look. }

function TLanguageFile.ShowMessage(ATitle, AText: Word;
  AMessageType: TMsgDlgType = mtInformation): Integer;
begin
  Result := ShowMessage(GetString(ATitle), GetString(AText), AMessageType);
end;

{ public TLanguageFile.ShowMessage

  Shows a message with multiple string text and specific look. }

function TLanguageFile.ShowMessage(ATitle: Word; AIndexes: array of Word;
  AMessageType: TMsgDlgType = mtInformation): Integer;
begin
  Result := ShowMessage(GetString(ATitle), GetString(AIndexes), AMessageType);
end;

{ public TLanguageFile.ShowMessage

  Shows a message with multiple formatted string text and specific look. }

function TLanguageFile.ShowMessage(ATitle: Word; AIndexes: array of Word;
  AArgs: array of {$IFDEF MSWINDOWS}TVarRec{$ELSE}const{$ENDIF};
  AMessageType: TMsgDlgType = mtInformation): Integer;
begin
  Result := ShowMessage(GetString(ATitle), Format(AIndexes, AArgs), AMessageType);
end;

{ public TLanguageFile.ShowException

  Shows an exception message with additional information. }

procedure TLanguageFile.ShowException(AText, AInformation: string;
  AOptions: TTaskDialogFlags = []);
{$IFDEF MSWINDOWS}
var
  TaskDialog: TTaskDialog;
  MailSubject, MailBody: string;

begin
  // TaskDialogIndirect only possible for Windows >= Vista!
  if (Win32MajorVersion < 6) then
  begin
    ShowMessage(GetString(31) +': '+ AText + sLineBreak + AInformation, mtError);
    Exit;
  end;  //of begin

  TaskDialog := TTaskDialog.Create(FOwner);

  try
    with TaskDialog do
    begin
      Caption := Application.Title;
      MainIcon := tdiError;
      Title := GetString(31);
      Text := AText;
      ExpandedText := AInformation;
      ExpandButtonCaption := GetString(32);
      MailSubject := TIdURI.ParamsEncode('Bug Report "'+ Application.Title +'"');
      MailBody := TIdURI.ParamsEncode('Dear PM Code Works,'+ sLineBreak + sLineBreak +
        'I found a possible bug:'+ sLineBreak + AText +' '+ AInformation);
      FooterText := '<a href="mailto:team@pm-codeworks.de?subject='+ MailSubject +
        '&body='+ MailBody +'">'+ GetString(26) +'</a>';
      Flags := [tfExpandFooterArea, tfEnableHyperlinks] + AOptions;
      CommonButtons := [tcbClose];
      OnHyperlinkClicked := HyperlinkClicked;
    end;  //of with

    MessageBeep(MB_ICONERROR);

    if not TaskDialog.Execute() then
      ShowMessage(GetString(31) +': '+ AText + sLineBreak + AInformation, mtError);

  finally
    TaskDialog.Free;
  end;  //of try
{$ELSE}
begin
  Result := ShowMessage(GetString(31) +': '+ AText + sLineBreak + AInformation,
    mtError);
{$ENDIF}
end;

{ public TLanguageFile.RemoveLanguage

  Removes a language from the list. }

procedure TLanguageFile.RemoveLanguage(ALocale: Word);
begin
  FLanguages.Remove(ALocale);
end;

{ public TLanguageFile.RemoveListener

  Removes a listener from the notification list. }

procedure TLanguageFile.RemoveListener(AListener: IChangeLanguageListener);
begin
  FListeners.Remove(AListener);
end;

end.
