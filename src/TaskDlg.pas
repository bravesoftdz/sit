{ *********************************************************************** }
{                                                                         }
{ Windows Vista Task Dialog Unit                                          }
{                                                                         }
{ Copyright (c) 2011-2015 Philipp Meisberger (PM Code Works)              }
{                                                                         }
{ *********************************************************************** }

unit TaskDlg;

interface

uses
  Windows, Messages;

const
  { TASKDIALOG_ICONS }
  TD_ICON_BLANK                    = 0;
  TD_ICON_WARNING                  = 84;
  TD_ICON_QUESTION                 = 99;
  TD_ICON_ERROR                    = 98;
  TD_ICON_INFORMATION              = 81;
  TD_ICON_SHIELD                   = 78;
  TD_ICON_SHIELD_BANNER            = 65531;
  TD_ICON_SHIELD_WARNING           = 107;
  TD_ICON_SHIELD_WARNING_BANNER    = 65530;
  TD_ICON_SHIELD_QUESTION          = 104;
  TD_ICON_SHIELD_ERROR             = 105;
  TD_ICON_SHIELD_ERROR_BANNER      = 65529;
  TD_ICON_SHIELD_OK                = 106;
  TD_ICON_SHIELD_OK_BANNER         = 65528;

  { TASKDIALOG_ELEMENTS }
  TDE_CONTENT                      = $0000;
  TDE_MAIN_INSTRUCTION             = $0003;

  { Common buttons }
  TDCBF_OK_BUTTON                  = $0001;
  TDCBF_YES_BUTTON                 = $0002;
  TDCBF_NO_BUTTON                  = $0004;
  TDCBF_CANCEL_BUTTON              = $0008;
  TDCBF_RETRY_BUTTON               = $0010;
  TDCBF_CLOSE_BUTTON               = $0020;

  { TASKDIALOG_FLAGS }
  TDF_ENABLE_HYPERLINKS            = $0001;
  TDF_USE_HICON_MAIN               = $0002;
  TDF_USE_HICON_FOOTER             = $0004;
  TDF_ALLOW_DIALOG_CANCELLATION    = $0008;
  TDF_USE_COMMAND_LINKS            = $0010;
  TDF_USE_COMMAND_LINKS_NO_ICON    = $0020;
  TDF_EXPAND_FOOTER_AREA           = $0040;
  TDF_EXPANDED_BY_DEFAULT          = $0080;
  TDF_VERIFICATION_FLAG_CHECKED    = $0100;
  TDF_SHOW_PROGRESS_BAR            = $0200;
  TDF_SHOW_MARQUEE_PROGRESS_BAR    = $0400;
  TDF_CALLBACK_TIMER               = $0800;
  TDF_POSITION_RELATIVE_TO_WINDOW  = $1000;
  TDF_RTL_LAYOUT                   = $2000;
  TDF_NO_DEFAULT_RADIO_BUTTON      = $4000;
  TDF_CAN_BE_MINIMIZED             = $8000;

  { TASKDIALOG_NOTIFICATIONS }
  TDN_CREATED                      = 0;
  TDN_NAVIGATED                    = 1;
  TDN_BUTTON_CLICKED               = 2;  // wParam = Button ID
  TDN_HYPERLINK_CLICKED            = 3;  // lParam = (LPCWSTR)pszHREF
  TDN_TIMER                        = 4;  // wParam = Milliseconds since dialog created or timer reset
  TDN_DESTROYED                    = 5;
  TDN_RADIO_BUTTON_CLICKED         = 6;  // wParam = Radio Button ID
  TDN_DIALOG_CONSTRUCTED           = 7;
  TDN_VERIFICATION_CLICKED         = 8;  // wParam = 1 if checkbox checked; 0 if not; lParam is unused and always 0
  TDN_HELP                         = 9;
  TDN_EXPANDO_BUTTON_CLICKED       = 10; // wParam = 0 (dialog is now collapsed); wParam != 0 (dialog is now expanded)

  { TASKDIALOG_MESSAGES }
  TDM_NAVIGATE_PAGE                = WM_USER + 101;
  TDM_CLICK_BUTTON                 = WM_USER + 102; // wParam = Button ID
  TDM_SET_MARQUEE_PROGRESS_BAR     = WM_USER + 103; // wParam = 0 (nonMarque) wParam != 0 (Marquee)
  TDM_SET_PROGRESS_BAR_STATE       = WM_USER + 104; // wParam = new progress state
  TDM_SET_PROGRESS_BAR_RANGE       = WM_USER + 105; // lParam = MAKELPARAM(nMinRange; nMaxRange)
  TDM_SET_PROGRESS_BAR_POS         = WM_USER + 106; // wParam = new position
  TDM_SET_PROGRESS_BAR_MARQUEE     = WM_USER + 107; // wParam = 0 (stop marquee); wParam != 0 (start marquee); lparam = speed (milliseconds between repaints)
  TDM_SET_ELEMENT_TEXT             = WM_USER + 108; // wParam = element (TASKDIALOG_ELEMENTS); lParam = new element text (LPCWSTR)
  TDM_CLICK_RADIO_BUTTON           = WM_USER + 110; // wParam = Radio Button ID
  TDM_ENABLE_BUTTON                = WM_USER + 111; // lParam = 0 (disable); lParam != 0 (enable); wParam = Button ID
  TDM_ENABLE_RADIO_BUTTON          = WM_USER + 112; // lParam = 0 (disable); lParam != 0 (enable); wParam = Radio Button ID
  TDM_CLICK_VERIFICATION           = WM_USER + 113; // wParam = 0 (unchecked); 1 (checked); lParam = 1 (set key focus)
  TDM_UPDATE_ELEMENT_TEXT          = WM_USER + 114; // wParam = element (TASKDIALOG_ELEMENTS); lParam = new element text (LPCWSTR)
  TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE = WM_USER + 115; // wParam = Button ID; lParam = 0 (elevation not required); lParam != 0 (elevation required)
  TDM_UPDATE_ICON                  = WM_USER + 116;  // wParam = icon element (TASKDIALOG_ICON_ELEMENTS); lParam = new icon (hIcon if TDF_USE_HICON_* was set; PCWSTR otherwise)

type
  { TASKDIALOG_BUTTON }
  TASKDIALOG_BUTTON = packed record
    nButtonId: Integer;
    pszButtonText: PWideChar;
  end;
  PTaskDialogButton = ^TASKDIALOG_BUTTON;
  TTaskDialogButton = TASKDIALOG_BUTTON;

  { Callback event }
  TTaskDialogCallbackEvent = function(hWnd: HWND; Message: UINT; wParam: WPARAM;
    lParam: LPARAM; dwRefData: PDWORD): HRESULT stdcall;

  { TASKDIALOGCONFIG }
  TASKDIALOGCONFIG = packed record
    cbSize: UINT;
    hwndParent: HWND;
    hInstance: HINST;
    dwFlags,
    dwCommonButtons: DWORD;
    pszWindowTitle: PWideChar;
    case Integer of
      0: (hMainIcon: HICON);
      1: (pszMainIcon: PWideChar;
          pszMainInstruction: PWideChar;
          pszContent: PWideChar;
          cButtons: UINT;
          pButtons: PTaskDialogButton;
          nDefaultButton: Integer;
          cRadioButtons: UINT;
          pRadioButtons: PTaskDialogButton;
          nDefaultRadioButton: Integer;
          pszVerificationText,
          pszExpandedInformation,
          pszExpandedControlText,
          pszCollapsedControlText: PWideChar;
          case Integer of
            0: (hFooterIcon: HICON);
            1: (pszFooterIcon: PWideChar;
                pszFooterText: PWideChar;
                pfCallback: TTaskDialogCallbackEvent;
                lpCallbackData: Pointer;
                cxWidth: UINT;
          )
      );
  end;
  PTaskDialogConfig = ^TASKDIALOGCONFIG;
  TTaskDialogConfig = TASKDIALOGCONFIG;

function TaskDialog(hwndParent: HWND; hInstance: LongWord; pszWindowTitle,
  pszMainInstruction, pszContent: PWideChar; dwCommonButtons: DWORD;
  Icon: PWideChar; var pnButton: Integer): HRESULT; stdcall;

function TaskDialogIndirect(ptc: PTaskDialogConfig; pnButton: PInteger;
  pnRadioButton: PInteger; pfVerificationFlagChecked: PBool): HRESULT; stdcall;


implementation

{ TaskDialog

  Creates a TaskDialog. }

function TaskDialog(hwndParent: HWND; hInstance: LongWord; pszWindowTitle,
  pszMainInstruction, pszContent: PWideChar; dwCommonButtons: DWORD;
  Icon: PWideChar; var pnButton: Integer): HRESULT;
type
  TTaskDialog = function(hwndParent: HWND; hInstance: LongWord; pszWindowTitle,
    pszMainInstruction, pszContent: PWideChar; dwCommonButtons: DWORD;
    Icon: PWideChar; var pnButton: Integer): HRESULT; stdcall;

var
  LibraryHandle: HMODULE;
  TaskDialog: TTaskDialog;

begin
  Result := E_FAIL;

  // Init handle
  LibraryHandle := GetModuleHandle(comctl32);

  if (LibraryHandle <> 0) then
  begin
    TaskDialog := GetProcAddress(LibraryHandle, 'TaskDialog');

    // Loading TaskDialog successful?
    if Assigned(TaskDialog) then
      Result := TaskDialog(hwndParent, hInstance, pszWindowTitle,
        pszMainInstruction, pszContent, dwCommonButtons, Icon, pnButton);
  end;  //of begin
end;

{ TaskDialogIndirect

  Creates a TaskDialogIndirect. }

function TaskDialogIndirect(ptc: PTaskDialogConfig; pnButton: PInteger;
  pnRadioButton: PInteger; pfVerificationFlagChecked: PBool): HRESULT;
type
  TTaskDialogIndirect = function(ptc: PTaskDialogConfig; pnButton: PInteger;
    pnRadioButton: PInteger; pfVerificationFlagChecked: PBool): HRESULT; stdcall;

var
  LibraryHandle: HMODULE;
  TaskDialogIndirect: TTaskDialogIndirect;

begin
  Result := E_FAIL;

  // Init handle
  LibraryHandle := GetModuleHandle(comctl32);

  if (LibraryHandle <> 0) then
  begin
    TaskDialogIndirect := GetProcAddress(LibraryHandle, 'TaskDialogIndirect');

    // Loading TaskDialogIndirect successful?
    if Assigned(TaskDialogIndirect) then
      Result := TaskDialogIndirect(ptc, pnButton, pnRadioButton,
        pfVerificationFlagChecked);
  end;  //of begin
end;

end.
