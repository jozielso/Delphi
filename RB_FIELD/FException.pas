{**************************************************************************************************}
{                                                                                                  }
{ Project JEDI Code Library (JCL)                                                                  }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is ExceptDlg.pas.                                                              }
{                                                                                                  }
{ The Initial Developer of the Original Code is Petr Vones.                                        }
{ Portions created by Petr Vones are Copyright (C) of Petr Vones.                                  }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Last modified: $Date:: 2010-02-22 18:24:06 +0100 (lun. 22 févr. 2010)                         $ }
{ Revision:      $Rev:: 3199                                                                     $ }
{ Author:        $Author:: outchy                                                                $ }
{                                                                                                  }
{**************************************************************************************************}

unit FException;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, AppEvnts, registry,ShellApi,
  JclSysUtils, JclUnitVersioning, JclUnitVersioningProviders, JclDebug, ComCtrls,
  Grids, Buttons,JclMapi,jpeg;



const
  UM_CREATEDETAILS = WM_USER + $100;

type
  TExceptionDialog = class(TForm)


    TextMemo: TMemo;
    DetailsBtn: TBitBtn;
    BevelDetails: TBevel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    grdGeral: TStringGrid;
    TabSheet2: TTabSheet;
    DetailsMemo: TMemo;
    TabSheet3: TTabSheet;
    grdChamada: TStringGrid;
    OkBtn: TBitBtn;
    che_email: TCheckBox;


    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure DetailsBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure grdGeralClick(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    private
    FDetailsVisible: Boolean;
    FThreadID: DWORD;

    FNonDetailsHeight: Integer;
    FFullHeight: Integer;

    procedure CriaGridGeral;
    function GetReportAsText: string;
    procedure SetDetailsVisible(const Value: Boolean);
    procedure UMCreateDetails(var Message: TMessage); message UM_CREATEDETAILS;
    function UpTime: string;
    procedure CriaGridChamada;
    procedure InsereRegistroChamada(StackList: TJclStackInfoItem);
    procedure EnviaEmail;
  protected
    procedure AfterCreateDetails; dynamic;
    procedure BeforeCreateDetails; dynamic;
    procedure CreateDetails; dynamic;
    procedure CreateReport;
    function ReportMaxColumns: Integer; virtual;
    function ReportNewBlockDelimiterChar: Char; virtual;
    procedure NextDetailBlock;
    procedure UpdateTextMemoScrollbars;
  public
    procedure CopyReportToClipboard;
    class procedure ExceptionHandler(Sender: TObject; E: Exception);
    class procedure ExceptionThreadHandler(Thread: TJclDebugThread);
    class procedure ShowException(E: TObject; Thread: TJclDebugThread;xMostraJanela : Boolean=true);
    class function  TextoErro(E: TObject) : String;
    class procedure MostraException(E: TObject; xTexto : String);
    property DetailsVisible: Boolean read FDetailsVisible
      write SetDetailsVisible;
    property ReportAsText: string read GetReportAsText;
  end;

  TExceptionDialogClass = class of TExceptionDialog;

var
  ExceptionDialogClass: TExceptionDialogClass = TExceptionDialog;
  vTela : TMemoryStream;


implementation

{$R *.dfm}

uses
  ClipBrd, Math,//Bibli,
  JclBase, JclFileUtils, JclHookExcept, JclPeImage, JclStrings, JclSysInfo, JclWin32;

resourcestring
  RsAppError = '%s';
  RsExceptionClass = 'Classe do Erro: %s';
  RsExceptionMessage = 'Mensagem do Erro: %s';
  RsExceptionAddr = 'Endereço do Erro: %p';
  RsStackList = 'Pilha, Gerada %s';
  RsModulesList = 'Módulos Carregados:';
  RsOSVersion = 'Sistema   : %s %s, Versão: %d.%d, Build: %x, "%s"';
  RsProcessor = 'Processador: %s, %s, %d MHz';
  RsMemory = 'Memória: %d; livre %d';
  RsScreenRes = 'Vídeo  : %dx%d pixels, %d bpp';
  RsActiveControl = 'Hierarquia de Controles:';
  RsThread = 'Thread: %s';
  RsMissingVersionInfo = '(no module version info)';
  RsExceptionStack = 'Pilha do Erro';
  RsMainThreadID = 'thread ID = %d';
  RsExceptionThreadID = 'Exception thread ID = %d';
  RsMainThreadCallStack = 'Call stack for main thread';
  RsThreadCallStack = 'Call stack for thread %d %s "%s"';
  RsExceptionThreadCallStack = 'Call stack for exception thread %s';
  RsErrorMessage = 'Ocorreu um problema durante a execução do Programa.' + NativeLineBreak ;
                   //'É recomendado que você salve o seu trabalho e reinicie o sistema' + NativeLineBreak + NativeLineBreak;
  RsDetailsIntro = 'Log de Exceção com Informações Técnicas. Gerado em %s.' + NativeLineBreak +
//                   'You may send it to the application vendor, helping him to understand what had happened.' + NativeLineBreak +
                   ' Nome da Aplicação: %s' + NativeLineBreak +
                   ' Nome do Arquivo: %s';
  RsUnitVersioningIntro = 'Unit versioning information:';

var
  ExceptionDialog: TExceptionDialog;

//============================================================================
// Helper routines
//============================================================================


Function DataExecutavel : TDateTime;
begin
  Result := FileDateToDateTime(FileAge(Application.ExeName));
end;


Function WinTempDir: String;
Var
  Buffer: Array [0 .. 144] of Char;
Begin
  GetTempPath(144, Buffer);
  Result := StrPas(Buffer);
End;


function BMPtoJPG(Var xArquivo: String; xReduz: Boolean = True): Boolean;
Var
  vJPEG: TJpegImage;
  vBmp: TBitMap;
  vArq: String;
  vPerc: Double;
  vw, vh: Integer;
Begin
  vJPEG := TJpegImage.Create;
  vBmp := TBitMap.Create;
  If UpperCase(ExtractFileExt(xArquivo)) = '.JPG' then
  Begin
    vJPEG.LoadFromFile(xArquivo);
    vBmp.Assign(vJPEG);
  End
  else
    vBmp.LoadFromFile(xArquivo);

  if xReduz then
  Begin
    if (vBmp.Width > 800) or (vBmp.Height > 600) then
    Begin
      vPerc := 800 / vBmp.Width;
      vw := Round(vBmp.Width * vPerc);
      vh := Round(vBmp.Height * vPerc);
      vBmp.Canvas.StretchDraw(Rect(0, 0, vw, vh), vBmp);
      vBmp.Width := vw;
      vBmp.Height := vh;
    End;
  End;

  vArq := WinTempDir + ExtractFileName(xArquivo);
  vArq := ChangeFileExt(vArq, '.jpg');
  With vJPEG do
  Begin
    vJPEG.CompressionQuality := 20;
    vJPEG.Assign(vBmp);
    vJPEG.Compress;
    vJPEG.SaveToFile(vArq); // ChangeFileExt(xArquivo,'.jpg'));
  End;
  xArquivo := vArq;
  FreeAndNil(vJPEG);
  FreeAndNil(vBmp);
  Result := True;
End;


procedure CaptureScreenRect;
var
ScreenDC: HDC;
  vTmp : TBitMap;
  vArq : String;
  ARect : TRect;
  vJpg : TJPEGImage;
begin
  Arect.Top := 0;
  ARect.Left := 0;
  ARect.Right := Screen.Width;
  ARect.Bottom := Screen.Height;

  vArq := WinTempDir + 'telapuma.bmp';
  vtmp := TBitmap.Create;
  with vtmp, ARect do
  begin
    Width := Right - Left;
    Height := Bottom - Top;
    ScreenDC := GetDC( 0 );
    try
    BitBlt( Canvas.Handle, 0, 0, Width, Height, ScreenDC, Left, Top, SRCCOPY );
    finally
    ReleaseDC( 0, ScreenDC );
    end;
  end;
  vtmp.SaveToFile(vArq);
  FreeAndNil(vtmp);
  vJpg := TJPEGImage.Create;
  if BMPtoJPG(vArq,FALSE) then
    vJpg.LoadFromFile(ChangeFileExt(varq,'.jpg'))
  else
    vJpg.LoadFromFile(vArq);
  vJPg.SaveToStream(vTela);
  FreeAndNil(vJpg);
  DeleteFile(ChangeFileExt(varq,'.jpg'));
end;




function ParseString(xTexto: String; xDelim: String; var xStringList : TStringList): TStringList;
Var
  I, vTamDelim, VTamTexto, Last: Integer;
Begin
  I := 1;
  vTamDelim := Length(xDelim);
  VTamTexto := Length(xTexto);

  try
    if xStringList <> nil then
      Begin
       if xStringList.Count > 0 then
          xStringList.Clear;
      End
    Else
      xStringList := TStringList.Create;
  except
     xStringList := TStringList.Create;
  end;

  //result := TStringList.Create;
  I := 1;
  Last := 0;
  While I <= VTamTexto do
  Begin
    If Copy(xTexto, I, vTamDelim) = xDelim then
      Inc(I)
    Else
      Break;
  End;
  if Copy(xTexto, 1, vTamDelim) = xDelim then
    xStringList.Add('');
  // No caso de vir assim ';1', sem isso, nao pega como 2 items, mas somente o item depois do ;
  Last := I;
  While I <= VTamTexto do
  Begin
    If Copy(xTexto, I, vTamDelim) = xDelim then
    Begin
      xStringList.Add(Copy(xTexto, Last, I - Last));
      Last := I + vTamDelim;
      Inc(I, vTamDelim);
    End
    Else
      Inc(I);
  End;
  xStringList.Add(Copy(xTexto, Last, VTamTexto));
  result := xStringList;
End;

Function WinEnvVar(const VarName: String): String;
begin
  { Obtém o comprimento da variável }
  Result := GetEnvironmentVariable(VarName);
end;


function Space(N: Integer): string;
var
  I: Integer;
  Dados: string;
begin
  Dados := '';
  for I := 1 to N do
  begin
    Dados := Dados + ' ';
    Application.ProcessMessages;
  end;
  Space := Dados;
end;

function NomeMaquina: string;
var
  N: dword;
  buf: PChar;
const
  rkMachine = { HKEY_LOCAL_MACHINE\ }
    'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName';
  rvMachine = 'ComputerName';
begin
  N := 255;
  buf := StrAlloc(N);
  GetComputerName(buf, N);
  Result := StrPas(buf);
  StrDispose(buf);
  with TRegistry.Create do
  begin
    rootkey := HKEY_LOCAL_MACHINE;
    if OpenKey(rkMachine, false) then
    begin
      if ValueExists(rvMachine) then
        Result := ReadString(rvMachine);
      closekey;
    end;
    Free;
  end;
end;


// SortModulesListByAddressCompare
// sorts module by address
function SortModulesListByAddressCompare(List: TStringList;
  Index1, Index2: Integer): Integer;
var
  Addr1, Addr2: Cardinal;
begin
  Addr1 := Cardinal(List.Objects[Index1]);
  Addr2 := Cardinal(List.Objects[Index2]);
  if Addr1 > Addr2 then
    Result := 1
  else if Addr1 < Addr2 then
    Result := -1
  else
    Result := 0;
end;

//============================================================================
// TApplication.HandleException method code hooking for exceptions from DLLs
//============================================================================

// We need to catch the last line of TApplication.HandleException method:
// [...]
//   end else
//    SysUtils.ShowException(ExceptObject, ExceptAddr);
// end;

procedure HookShowException(ExceptObject: TObject; ExceptAddr: Pointer);
begin
  if JclValidateModuleAddress(ExceptAddr)
    and (ExceptObject.InstanceSize >= Exception.InstanceSize) then
    TExceptionDialog.ExceptionHandler(nil, Exception(ExceptObject))
  else
    SysUtils.ShowException(ExceptObject, ExceptAddr);
end;

//----------------------------------------------------------------------------

function HookTApplicationHandleException: Boolean;
const
  CallOffset      = $86;
  CallOffsetDebug = $94;
type
  PCALLInstruction = ^TCALLInstruction;
  TCALLInstruction = packed record
    Call: Byte;
    Address: Integer;
  end;
var
  TApplicationHandleExceptionAddr, SysUtilsShowExceptionAddr: Pointer;
  CALLInstruction: TCALLInstruction;
  CallAddress: Pointer;
  WrittenBytes: Cardinal;

  function CheckAddressForOffset(Offset: Cardinal): Boolean;
  begin
    try
      CallAddress := Pointer(Cardinal(TApplicationHandleExceptionAddr) + Offset);
      CALLInstruction.Call := $E8;
      Result := PCALLInstruction(CallAddress)^.Call = CALLInstruction.Call;
      if Result then
      begin
        if IsCompiledWithPackages then
          Result := PeMapImgResolvePackageThunk(Pointer(Integer(CallAddress) + Integer(PCALLInstruction(CallAddress)^.Address) + SizeOf(CALLInstruction))) = SysUtilsShowExceptionAddr
        else
          Result := PCALLInstruction(CallAddress)^.Address = Integer(SysUtilsShowExceptionAddr) - Integer(CallAddress) - SizeOf(CALLInstruction);
      end;
    except
      Result := False;
    end;
  end;

begin
  TApplicationHandleExceptionAddr := PeMapImgResolvePackageThunk(@TApplication.HandleException);
  SysUtilsShowExceptionAddr := PeMapImgResolvePackageThunk(@SysUtils.ShowException);
  if Assigned(TApplicationHandleExceptionAddr) and Assigned(SysUtilsShowExceptionAddr) then
  begin
    Result := CheckAddressForOffset(CallOffset) or CheckAddressForOffset(CallOffsetDebug);
    if Result then
    begin
      CALLInstruction.Address := Integer(@HookShowException) - Integer(CallAddress) - SizeOf(CALLInstruction);
      Result := WriteProtectedMemory(CallAddress, @CallInstruction, SizeOf(CallInstruction), WrittenBytes);
    end;
  end
  else
    Result := False;
end;

//============================================================================
// Exception dialog
//============================================================================

var
  ExceptionShowing: Boolean;

//=== { TExceptionDialog } ===============================================

procedure TExceptionDialog.AfterCreateDetails;
begin


end;

//----------------------------------------------------------------------------

procedure TExceptionDialog.BeforeCreateDetails;
begin


end;

//----------------------------------------------------------------------------

function TExceptionDialog.ReportMaxColumns: Integer;
begin
  Result := 78;
end;





//----------------------------------------------------------------------------

procedure TExceptionDialog.CopyReportToClipboard;
begin
  ClipBoard.AsText := ReportAsText;
end;

//----------------------------------------------------------------------------

procedure TExceptionDialog.CreateDetails;
begin
  Screen.Cursor := crHourGlass;
  DetailsMemo.Lines.BeginUpdate;
  try
    CreateReport;

    DetailsMemo.SelStart := 0;
    SendMessage(DetailsMemo.Handle, EM_SCROLLCARET, 0, 0);
    AfterCreateDetails;
  finally
    DetailsMemo.Lines.EndUpdate;
    OkBtn.Enabled := True;
    DetailsBtn.Enabled := True;
    OkBtn.SetFocus;
    Screen.Cursor := crDefault;
  end;
end;

//----------------------------------------------------------------------------

procedure TExceptionDialog.InsereRegistroChamada(StackList: TJclStackInfoItem);
Var
 Info: TJclLocationInfo;
 vFuncao : TStringList;
Begin
   GetLocationInfo(StackList.CallerAddr, Info);
   if info.LineNumber=0 then exit;

   Try
     vFuncao := TStringList.Create;
     ParseString(info.ProcedureName,'.',vFuncao);
     grdChamada.Cells[0,grdChamada.RowCount-1] := ExtractFileName(info.BinaryFileName);
     grdChamada.Cells[1,grdChamada.RowCount-1] := info.UnitName;
     grdChamada.Cells[2,grdChamada.RowCount-1] := IntToStr(info.LineNumber);
     grdChamada.Cells[3,grdChamada.RowCount-1] := vFuncao.Strings[vFuncao.Count-1];
     grdChamada.RowCount :=  grdChamada.RowCount+1;
   Finally
     FreeAndNil(vFuncao);
   End;

End;

procedure TExceptionDialog.CreateReport;
var
  SL: TStringList;
  I: Integer;
  ModuleName: TFileName;
  NtHeaders32: PImageNtHeaders32;
  NtHeaders64: PImageNtHeaders64;
  ModuleBase: Cardinal;
  ImageBaseStr: string;

  CpuInfo: TCpuInfo;
  ProcessorDetails: string;
  StackList: TJclStackInfoList;
  ThreadList: TJclDebugThreadList;
  AThreadID: DWORD;
  PETarget: TJclPeTarget;
  UnitVersioning: TUnitVersioning;
  UnitVersioningModule: TUnitVersioningModule;
  UnitVersion: TUnitVersion;
  ModuleIndex, UnitIndex: Integer;
begin
//  DetailsMemo.Lines.Add(Format(LoadResString(@RsMainThreadID), [MainThreadID]));
//  DetailsMemo.Lines.Add(Format(LoadResString(@RsExceptionThreadID), [MainThreadID]));

   CriaGridGeral;
   CriaGridChamada;

  NextDetailBlock;

  SL := TStringList.Create;
  try
    // Except stack list
    StackList := JclGetExceptStackList(FThreadID);
    if Assigned(StackList) then
    begin
      DetailsMemo.Lines.Add(RsExceptionStack);
      DetailsMemo.Lines.Add(Format(LoadResString(@RsStackList), [DateTimeToStr(StackList.TimeStamp)]));
      //StackList.AddToStrings(DetailsMemo.Lines, True, False, True, False);

      // Insere os Registros de Chamada de funcao na grade de chamadas
      for i  := 0 to StackList.Count-1 do
        InsereRegistroChamada(StackList.Items[i]) ;
      if grdChamada.RowCount>2 then
        grdChamada.RowCount :=  grdChamada.RowCount-1;
      //  

      StackList.AddToStrings(sl, True, False, True, False);
      for I := 0 to sl.Count-1 do
        if Pos('Line',sl.Strings[i])<>0  then
          Begin
            DetailsMemo.Lines.Add(sl.Strings[i]);
          End;
      sl.Clear;
      NextDetailBlock;
    end;

    // Main thread
{    StackList := JclCreateThreadStackTraceFromID(True, MainThreadID);
    if Assigned(StackList) then
    begin
      DetailsMemo.Lines.Add(LoadResString(@RsMainThreadCallStack));
      DetailsMemo.Lines.Add(Format(LoadResString(@RsStackList), [DateTimeToStr(StackList.TimeStamp)]));
      StackList.AddToStrings(DetailsMemo.Lines, True, False, True, False);
      NextDetailBlock;
    end;}

    // All threads
    ThreadList := JclDebugThreadList;
    ThreadList.Lock.Enter; // avoid modifications
    try
      for I := 0 to ThreadList.ThreadIDCount - 1 do
      begin
        AThreadID := ThreadList.ThreadIDs[I];
        if (AThreadID <> FThreadID) then
        begin
          StackList := JclCreateThreadStackTrace(True, ThreadList.ThreadHandles[I]);
          if Assigned(StackList) then
          begin
            DetailsMemo.Lines.Add(Format(RsThreadCallStack, [AThreadID, ThreadList.ThreadInfos[AThreadID], ThreadList.ThreadNames[AThreadID]]));
            DetailsMemo.Lines.Add(Format(LoadResString(@RsStackList), [DateTimeToStr(StackList.TimeStamp)]));
            StackList.AddToStrings(DetailsMemo.Lines, True, False, True, False);
            NextDetailBlock;
          end;
        end;
      end;
    finally
      ThreadList.Lock.Leave;
    end;


    // System and OS information
    DetailsMemo.Lines.Add(Format(RsOSVersion, [GetWindowsVersionString, NtProductTypeString,
      Win32MajorVersion, Win32MinorVersion, Win32BuildNumber, Win32CSDVersion]));
    GetCpuInfo(CpuInfo);
    ProcessorDetails := Format(RsProcessor, [CpuInfo.Manufacturer, CpuInfo.CpuName,
      RoundFrequency(CpuInfo.FrequencyInfo.NormFreq)]);
    if not CpuInfo.IsFDIVOK then
      ProcessorDetails := ProcessorDetails + ' [FDIV Bug]';
    if CpuInfo.ExMMX then
      ProcessorDetails := ProcessorDetails + ' MMXex';
    if CpuInfo.MMX then
      ProcessorDetails := ProcessorDetails + ' MMX';
    if sse in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSE';
    if sse2 in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSE2';
    if sse3 in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSE3';
    if ssse3 in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSSE3';
    if sse4A in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSE4A';
    if sse5 in CpuInfo.SSE then
      ProcessorDetails := ProcessorDetails + ' SSE';
    if CpuInfo.Ex3DNow then
      ProcessorDetails := ProcessorDetails + ' 3DNow!ex';
    if CpuInfo._3DNow then
      ProcessorDetails := ProcessorDetails + ' 3DNow!';
    if CpuInfo.Is64Bits then
      ProcessorDetails := ProcessorDetails + ' 64 bits';
    if CpuInfo.DEPCapable then
      ProcessorDetails := ProcessorDetails + ' DEP';
    DetailsMemo.Lines.Add(ProcessorDetails);
    DetailsMemo.Lines.Add(Format(RsMemory, [GetTotalPhysicalMemory div 1024 div 1024,
      GetFreePhysicalMemory div 1024 div 1024]));
    DetailsMemo.Lines.Add(Format(RsScreenRes, [Screen.Width, Screen.Height, GetBPP]));
    NextDetailBlock;

    for I := 1 to grdGeral.RowCount-1 do
      DetailsMemo.Lines.Add(Copy(grdGeral.Cells[0,I]+Space(30),1,30)+': '+ grdGeral.Cells[1,I]);



    // Modules list
{    if LoadedModulesList(SL, GetCurrentProcessId) then
    begin
      UnitVersioning := GetUnitVersioning;
      UnitVersioning.RegisterProvider(TJclDefaultUnitVersioningProvider);
      DetailsMemo.Lines.Add(RsModulesList);
      SL.CustomSort(SortModulesListByAddressCompare);
      for I := 0 to SL.Count - 1 do
      begin
        ModuleName := SL[I];
        ModuleBase := Cardinal(SL.Objects[I]);
        DetailsMemo.Lines.Add(Format('[%.8x] %s', [ModuleBase, ModuleName]));
        PETarget := PeMapImgTarget(Pointer(ModuleBase));
        NtHeaders32 := nil;
        NtHeaders64 := nil;
        if PETarget = taWin32 then
          NtHeaders32 := PeMapImgNtHeaders32(Pointer(ModuleBase))
        else
        if PETarget = taWin64 then
          NtHeaders64 := PeMapImgNtHeaders64(Pointer(ModuleBase));
        if (NtHeaders32 <> nil) and (NtHeaders32^.OptionalHeader.ImageBase <> ModuleBase) then
          ImageBaseStr := Format('<%.8x> ', [NtHeaders32^.OptionalHeader.ImageBase])
        else
        if (NtHeaders64 <> nil) and (NtHeaders64^.OptionalHeader.ImageBase <> ModuleBase) then
          ImageBaseStr := Format('<%.8x> ', [NtHeaders64^.OptionalHeader.ImageBase])
        else
          ImageBaseStr := StrRepeat(' ', 11);
        if VersionResourceAvailable(ModuleName) then
          with TJclFileVersionInfo.Create(ModuleName) do
          try
            DetailsMemo.Lines.Add(ImageBaseStr + BinFileVersion + ' - ' + FileVersion);
            if FileDescription <> '' then
              DetailsMemo.Lines.Add(StrRepeat(' ', 11) + FileDescription);
          finally
            Free;
          end
        else
          DetailsMemo.Lines.Add(ImageBaseStr + RsMissingVersionInfo);
        for ModuleIndex := 0 to UnitVersioning.ModuleCount - 1 do
        begin
          UnitVersioningModule := UnitVersioning.Modules[ModuleIndex];
          if UnitVersioningModule.Instance = ModuleBase then
          begin
            if UnitVersioningModule.Count > 0 then
              DetailsMemo.Lines.Add(StrRepeat(' ', 11) + LoadResString(@RsUnitVersioningIntro));
            for UnitIndex := 0 to UnitVersioningModule.Count - 1 do
            begin
              UnitVersion := UnitVersioningModule.Items[UnitIndex];
              DetailsMemo.Lines.Add(Format('%s%s %s %s %s', [StrRepeat(' ', 13), UnitVersion.LogPath, UnitVersion.RCSfile, UnitVersion.Revision, UnitVersion.Date]));
            end;
          end;
        end;
      end;
      NextDetailBlock;
    end;
  }
  finally
    SL.Free;
  end;
end;

procedure TExceptionDialog.CriaGridGeral;
Var
  FreeAvailable,TotalSpace,TotalFree : Int64;
  CpuInfo: TCpuInfo;
begin
      GetDiskFreeSpaceEx(PWideChar(ExtractFileDrive(Application.ExeName)),FreeAvailable,TotalSpace,@TotalFree);
      GetCpuInfo(CpuInfo);

      grdGeral.RowCount := 13;
      grdGeral.ColWidths[0] := 130;
      grdGeral.ColWidths[1] := 440;
      grdGeral.Cells[0,0] := 'Descrição';
      grdGeral.Cells[1,0] := 'Valor';

      grdGeral.Cells[0,1] := 'Data/Hora Executável';
      grdGeral.Cells[1,1] := FormatDateTime('dd/mm/yyyy hh:nn:ss',DataExecutavel);
      grdGeral.Cells[0,2] := 'Nome do Executável';
      grdGeral.Cells[1,2] := Application.ExeName;
      grdGeral.Cells[0,3] := 'Computador';
      grdGeral.Cells[1,3] := NomeMaquina;
      grdGeral.Cells[0,4] := 'Usuário TS';
      grdGeral.Cells[1,4] := WinEnvVar('CLIENTNAME');
      grdGeral.Cells[0,5] := 'Memória';
      grdGeral.Cells[1,5] := Format('Total: %d MB; Livre: %d MB', [GetTotalPhysicalMemory div 1024 div 1024,GetFreePhysicalMemory div 1024 div 1024]);
      grdGeral.Cells[0,6] := 'Espaço Livre';
      grdGeral.Cells[1,6] := Format('%d MB', [TotalFree div 1024 div 1024]);
      grdGeral.Cells[0,7] := 'Sistema Operacional';
      grdGeral.Cells[1,7] := Format('%s %s, Versão: %d.%d, Build: %x, "%s"', [GetWindowsVersionString, NtProductTypeString,Win32MajorVersion, Win32MinorVersion, Win32BuildNumber, Win32CSDVersion]);
      grdGeral.Cells[0,8] := 'Windows Ativo';
      grdGeral.Cells[1,8] := UpTime;

      grdGeral.Cells[0,9] := 'Processador';
      try
        grdGeral.Cells[1,9] := Format('%s, %s, %d MHz', [CpuInfo.Manufacturer, CpuInfo.CpuName,RoundFrequency(CpuInfo.FrequencyInfo.NormFreq)]);
      except
      end;
      grdGeral.Cells[0,10] := 'Vídeo';
      grdGeral.Cells[1,10] := Format('%dx%d pixels, %d bpp', [Screen.Width, Screen.Height, GetBPP]);

end;


procedure TExceptionDialog.CriaGridChamada;
begin

      grdChamada.RowCount := 2;
      grdChamada.ColWidths[0] := 120;
      grdChamada.ColWidths[1] := 120;
      grdChamada.ColWidths[2] := 40;
      grdChamada.ColWidths[3] := 160;
      grdChamada.Cells[0,0] := 'Módulo';
      grdChamada.Cells[1,0] := 'Unit';
      grdChamada.Cells[2,0] := 'Linha';
      grdChamada.Cells[3,0] := 'Função';
end;




//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.DetailsBtnClick(Sender: TObject);
begin
  DetailsVisible := not DetailsVisible;
end;

//--------------------------------------------------------------------------------------------------

class procedure TExceptionDialog.ExceptionHandler(Sender: TObject; E: Exception);
begin
  if Assigned(E) then
    if ExceptionShowing then
      Application.ShowException(E)
    else
    begin
      ExceptionShowing := True;
      try
        if IsIgnoredException(E.ClassType) then
          Application.ShowException(E)
        else
          ShowException(E, nil);
      finally
        ExceptionShowing := False;
      end;
    end;
end;

//--------------------------------------------------------------------------------------------------

class procedure TExceptionDialog.ExceptionThreadHandler(Thread: TJclDebugThread);
var
  E: Exception;
begin
  E := Exception(Thread.SyncException);
  if Assigned(E) then
    if ExceptionShowing then
      Application.ShowException(E)
    else
    begin
      ExceptionShowing := True;
      try
        if IsIgnoredException(E.ClassType) then
          Application.ShowException(E)
        else
          ShowException(E, Thread);
      finally
        ExceptionShowing := False;
      end;
    end;
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(vTela);
end;

procedure TExceptionDialog.FormCreate(Sender: TObject);
begin
  FFullHeight := ClientHeight;
  DetailsVisible := False;
  Caption := Format(RsAppError, [Application.Title]);
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormDestroy(Sender: TObject);
begin

end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = Ord('C')) and (ssCtrl in Shift) then
  begin
    CopyReportToClipboard;
    MessageBeep(MB_OK);
  end;
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormPaint(Sender: TObject);
begin
  DrawIcon(Canvas.Handle, TextMemo.Left - GetSystemMetrics(SM_CXICON) - 15,
    TextMemo.Top, LoadIcon(0, IDI_ERROR));
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormResize(Sender: TObject);
begin
  UpdateTextMemoScrollbars;
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.FormShow(Sender: TObject);
begin
  // captura a tela do sistema
  vTela := TMemoryStream.Create;
  CaptureScreenRect;
  //

  BeforeCreateDetails;
  MessageBeep(MB_ICONERROR);
  if (GetCurrentThreadId = MainThreadID) and (GetWindowThreadProcessId(Handle, nil) = MainThreadID) then
    PostMessage(Handle, UM_CREATEDETAILS, 0, 0)
  else
    CreateReport;
end;

//--------------------------------------------------------------------------------------------------

function TExceptionDialog.GetReportAsText: string;
begin
  Result := StrEnsureSuffix(NativeCrLf, TextMemo.Text) + NativeCrLf + DetailsMemo.Text;
end;

procedure TExceptionDialog.grdGeralClick(Sender: TObject);
begin

end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.NextDetailBlock;
begin
  DetailsMemo.Lines.Add(StrRepeat(ReportNewBlockDelimiterChar, ReportMaxColumns));
end;

procedure TExceptionDialog.OkBtnClick(Sender: TObject);
begin
  if che_email.Checked  then
    enviaemail;
end;

//--------------------------------------------------------------------------------------------------

function TExceptionDialog.ReportNewBlockDelimiterChar: Char;
begin
  Result := '-';
end;


//--------------------------------------------------------------------------------------------------


procedure TExceptionDialog.SetDetailsVisible(const Value: Boolean);
const
  DirectionChars: array [0..1] of Char = ( '<', '>' );
var
  DetailsCaption: string;
begin
  PageControl1.ActivePageIndex := 0; 
  FDetailsVisible := Value;
  DetailsCaption := Trim(StrRemoveChars(DetailsBtn.Caption, DirectionChars));
  if Value then
  begin
    Constraints.MinHeight := FNonDetailsHeight + 100;
    Constraints.MaxHeight := Screen.Height;
    DetailsCaption := '<< ' + DetailsCaption;
    ClientHeight := FFullHeight;
    DetailsMemo.Height := FFullHeight - DetailsMemo.Top - 3;
    PageControl1.Height := FFullHeight - PageControl1.Top -3;  
  end
  else
  begin
    FFullHeight := ClientHeight;
    DetailsCaption := DetailsCaption + ' >>';
    if FNonDetailsHeight = 0 then
    begin
      ClientHeight := BevelDetails.Top;
      FNonDetailsHeight := Height;
    end
    else
      Height := FNonDetailsHeight;
    Constraints.MinHeight := FNonDetailsHeight;
    Constraints.MaxHeight := FNonDetailsHeight
  end;
  DetailsBtn.Caption := DetailsCaption;
  DetailsMemo.Enabled := Value;
  grdGeral.Enabled := Value;
  grdChamada.Enabled := Value;  

  Top := Round((Screen.Height/2) - (Height/2));
end;

function TExceptionDialog.UpTime: string;
const
  ticksperday: Integer    = 1000 * 60 * 60 * 24;
  ticksperhour: Integer   = 1000 * 60 * 60;
  ticksperminute: Integer = 1000 * 60;
  tickspersecond: Integer = 1000;
var
  t:          Longword;
  d, h, m, s: Integer;
begin
  try
    t := GetTickCount;
    d := t div ticksperday;
    Dec(t, d * ticksperday);
    h := t div ticksperhour;
    Dec(t, h * ticksperhour);
    m := t div ticksperminute;
    Dec(t, m * ticksperminute);
    s := t div tickspersecond;
    if d > 0 then
      Result := Result + IntToStr(d) + ' dia(s) ';
    if h > 0  then
      Result := Result + IntToStr(h) + ' hora(s) ';
    Result :=  result + IntToStr(m) + ' Minuto(s) ' + IntToStr(s) + ' Segundos';
  except
    result := '';
  end;
end;



//--------------------------------------------------------------------------------------------------

class procedure TExceptionDialog.ShowException(E: TObject; Thread: TJclDebugThread; xMostraJanela : Boolean=true);
begin
  if ExceptionDialog = nil then
    ExceptionDialog := ExceptionDialogClass.Create(Application);
  try
    with ExceptionDialog do
    begin
      if Assigned(Thread) then
        FThreadID := Thread.ThreadID
      else
        FThreadID := MainThreadID;


      // Restante das informacoes do Grid Geral
      grdGeral.Cells[0,11] := 'Classe da Exceção';
      grdGeral.Cells[1,11] := e.ClassName;
      grdGeral.Cells[0,12] := 'Mensagem da Exceção';
      grdGeral.Cells[1,12] := Exception(E).Message;




      if E is Exception then
        TextMemo.Text := RsErrorMessage + AdjustLineBreaks(StrEnsureSuffix('.', Exception(E).Message))
      else
        TextMemo.Text := RsErrorMessage + AdjustLineBreaks(StrEnsureSuffix('.', E.ClassName));
      UpdateTextMemoScrollbars;
      NextDetailBlock;
      //Arioch: some header for possible saving to txt-file/e-mail/clipboard/NTEvent...
      DetailsMemo.Lines.Add(Format(RsDetailsIntro, [DateTimeToStr(Now), Application.Title, Application.ExeName]));
      NextDetailBlock;
      DetailsMemo.Lines.Add(Format(RsExceptionClass, [E.ClassName]));
      if E is Exception then
        DetailsMemo.Lines.Add(Format(RsExceptionMessage, [StrEnsureSuffix('.', Exception(E).Message)]));
      if Thread = nil then
        DetailsMemo.Lines.Add(Format(RsExceptionAddr, [ExceptAddr]))
      else
        DetailsMemo.Lines.Add(Format(RsThread, [Thread.ThreadInfo]));
      NextDetailBlock;
      if xMostraJanela then
        ShowModal;
    end;
  finally
    if xMostraJanela then
      FreeAndNil(ExceptionDialog);
  end;
end;

class function TExceptionDialog.TextoErro(E: TObject) : String;
begin
  Try
    ShowException(E, nil,false);
    //ExceptionDialog.CreateDetails;
    ExceptionDialog.CreateReport;
    Result :=ExceptionDialog.ReportAsText;
  Finally
    FreeAndNil(ExceptionDialog);
  End;
end;

class procedure TExceptionDialog.MostraException(E: TObject; xTexto : String);
begin
  if ExceptionDialog = nil then
    ExceptionDialog := ExceptionDialogClass.Create(Application);
  try
    with ExceptionDialog do
    begin
      FThreadID := MainThreadID;


      // Restante das informacoes do Grid Geral
      grdGeral.Cells[0,11] := 'Classe da Exceção';
      grdGeral.Cells[1,11] := e.ClassName;
      grdGeral.Cells[0,12] := 'Mensagem da Exceção';
      grdGeral.Cells[1,12] := Exception(E).Message;




{      if E is Exception then
        TextMemo.Text := RsErrorMessage + AdjustLineBreaks(StrEnsureSuffix('.', Exception(E).Message))
      else
        TextMemo.Text := RsErrorMessage + AdjustLineBreaks(StrEnsureSuffix('.', E.ClassName));}
      TextMemo.Text := xTexto;

      UpdateTextMemoScrollbars;
      NextDetailBlock;
      //Arioch: some header for possible saving to txt-file/e-mail/clipboard/NTEvent...
      DetailsMemo.Lines.Add(Format(RsDetailsIntro, [DateTimeToStr(Now), Application.Title, Application.ExeName]));
      NextDetailBlock;
      DetailsMemo.Lines.Add(Format(RsExceptionClass, [E.ClassName]));
      if E is Exception then
        DetailsMemo.Lines.Add(Format(RsExceptionMessage, [StrEnsureSuffix('.', Exception(E).Message)]));
      DetailsMemo.Lines.Add(Format(RsExceptionAddr, [ExceptAddr]));
      NextDetailBlock;
      ShowModal;
    end;
  finally
    FreeAndNil(ExceptionDialog);
  end;
end;


//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.UMCreateDetails(var Message: TMessage);
begin
  Update;
  CreateDetails;
end;

//--------------------------------------------------------------------------------------------------

procedure TExceptionDialog.UpdateTextMemoScrollbars;
begin
  Canvas.Font := TextMemo.Font;
  if TextMemo.Lines.Count * Canvas.TextHeight('Wg') > TextMemo.ClientHeight then
    TextMemo.ScrollBars := ssVertical
  else
    TextMemo.ScrollBars := ssNone;
end;

procedure TExceptionDialog.EnviaEmail;
Var
  vArquivo : TStringList;
  vNomeArq,vNomeArqTela : String;
begin
  with TJclEmail.Create do
  try
    ParentWnd := Application.Handle;
    Recipients.Add('pumasistemas@terra.com.br');
    Subject := 'Relatório para suporte';

    // Salve o texto do erro em arquivo para anexar no email
    vNomeArq := WinTempDir+'Relatorio.txt';
    vNomeArqTela := WinTempDir+'tela.jpg';
    vArquivo := TStringList.Create;
    vArquivo.Text := AnsiString(ReportAsText);
    vArquivo.SaveToFile(vNomeArq);


    if FileExists(vNomeArq) then
      Begin
        Body := 'Relatório para análise e suporte';
        Attachments.Add(vNomeArq);
      End
    else
      Body := AnsiString(ReportAsText);

    vTela.SaveToFile(vNomeArqTela);
    if FileExists(vNomeArqTela) then
      Attachments.Add(vNomeArqtela);


    FreeAndNil(vArquivo);
    //

    SaveTaskWindows;
    try
      Send(True);
    finally
      DeleteFile(vNomeArq);
      DeleteFile(vNomeArqTela);
      RestoreTaskWindows;
    end;
  finally
    Free;
  end;
end;



//==================================================================================================
// Exception handler initialization code
//==================================================================================================

var
  AppEvents: TApplicationEvents = nil;

procedure InitializeHandler;
begin
  if AppEvents = nil then
  begin
    AppEvents := TApplicationEvents.Create(nil);
    AppEvents.OnException := TExceptionDialog.ExceptionHandler;



    JclStackTrackingOptions := JclStackTrackingOptions + [stRawMode];
    JclStackTrackingOptions := JclStackTrackingOptions + [stStaticModuleList];
    JclStackTrackingOptions := JclStackTrackingOptions + [stDelayedTrace];
    JclDebugThreadList.OnSyncException := TExceptionDialog.ExceptionThreadHandler;
    JclHookThreads;
    JclStartExceptionTracking;
    JclStackTrackingOptions := JclStackTrackingOptions + [stMainThreadOnly];

    if HookTApplicationHandleException then
      JclTrackExceptionsFromLibraries;
  end;
end;

//--------------------------------------------------------------------------------------------------

procedure UnInitializeHandler;
begin
  if AppEvents <> nil then
  begin
    FreeAndNil(AppEvents);
    JclDebugThreadList.OnSyncException := nil;
    JclUnhookExceptions;
    JclStopExceptionTracking;
    JclUnhookThreads;
  end;
end;


//--------------------------------------------------------------------------------------------------

initialization
  InitializeHandler;

finalization
  UnInitializeHandler;

end.
