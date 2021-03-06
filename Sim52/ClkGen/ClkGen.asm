.586
.model flat, stdcall
option casemap :none   ; case sensitive

include ClkGen.inc

.code

DecToBin proc uses ebx esi,lpStr:DWORD
	LOCAL	fNeg:DWORD

    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    ret

DecToBin endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

BinToDec endp

GetItemInt proc uses esi edi,lpBuff:DWORD,nDefVal:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBin,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		invoke lstrcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

ClkGenProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		mov		esi,offset szPortBits
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOOUT,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.right
		sub		eax,rect.left
		invoke MoveWindow,hWin,rect.left,rect.top,eax,80,TRUE
		invoke SendDlgItemMessage,hWin,IDC_EDTDIVISOR,EM_LIMITTEXT,5,0
		invoke SendDlgItemMessage,hWin,IDC_UDNDIVISOR,UDM_SETRANGE,0,(1 shl 16) or 32767
		mov		portbit,0
		mov		portaddr,-1
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_CHKACTIVE
				xor		fActive,TRUE
			.elseif eax==IDC_BTNEXPAND
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.right
				sub		eax,rect.left
				mov		edx,rect.bottom
				sub		edx,rect.top
				.if edx==80
					mov		edx,160
					push	offset szShrink
				.else
					mov		edx,80
					push	offset szExpand
				.endif
				invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
				pop		eax
				invoke SetDlgItemText,hWin,IDC_BTNEXPAND,eax
			.endif
		.elseif edx==EN_CHANGE
			invoke GetDlgItemInt,hWin,IDC_EDTDIVISOR,NULL,FALSE
			.if !eax
				inc		eax
				push	eax
				invoke SetDlgItemInt,hWin,IDC_EDTDIVISOR,eax,FALSE
				pop		eax
			.elseif eax>32767
				mov		eax,32767
				push	eax
				invoke SetDlgItemInt,hWin,IDC_EDTDIVISOR,eax,FALSE
				pop		eax
			.endif
			mov		Divisor,eax
			invoke wsprintf,addr buffer,addr szFmtDiv,Divisor
			invoke SetDlgItemText,hWin,IDC_STCDIVISOR,addr buffer
		.elseif edx==CBN_SELCHANGE
			call	SetPort
		.endif
	.elseif eax==WM_ACTIVATE
		.if wParam!=WA_INACTIVE
			mov		eax,hWin
			mov		ebx,lpAddin
			mov		[ebx].ADDIN.hActive,eax
		.endif
	.elseif eax==WM_CLOSE
		invoke ShowWindow,hWin,SW_HIDE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

SetPort:
	mov		ebx,lpAddin
	invoke SendDlgItemMessage,hWin,IDC_CBOOUT,CB_GETCURSEL,0,0
	mov		ecx,eax
	mov		eax,1
	.if !ecx
		xor		eax,eax
		mov		edx,-2
	.elseif ecx>=P0_0 && ecx<=P0_7
		lea		ecx,[ecx-P0_0]
		shl		eax,cl
		mov		edx,80h
		lea		edx,[ebx].ADDIN.Sfr[edx]
	.elseif ecx>=P1_0 && ecx<=P1_7
		lea		ecx,[ecx-P1_0]
		shl		eax,cl
		mov		edx,90h
		lea		edx,[ebx].ADDIN.Sfr[edx]
	.elseif ecx>=P2_0 && ecx<=P2_7
		lea		ecx,[ecx-P2_0]
		shl		eax,cl
		mov		edx,0A0h
		lea		edx,[ebx].ADDIN.Sfr[edx]
	.elseif ecx>=P3_0 && ecx<=P3_7
		lea		ecx,[ecx-P3_0]
		shl		eax,cl
		mov		edx,0B0h
		lea		edx,[ebx].ADDIN.Sfr[edx]
	.elseif ecx>=MMI0_0 && ecx<=MMI0_7
		lea		ecx,[ecx-MMI0_0]
		mov		edx,[ebx].ADDIN.mminport[0]
		.if sdword ptr ecx>0
			lea		edx,[ebx].ADDIN.XRam[edx]
		.endif
	.elseif ecx>=MMI1_0 && ecx<=MMI1_7
		lea		ecx,[ecx-MMI1_0]
		mov		edx,[ebx].ADDIN.mminport[4]
		.if sdword ptr ecx>0
			lea		edx,[ebx].ADDIN.XRam[edx]
		.endif
	.elseif ecx>=MMI2_0 && ecx<=MMI2_7
		lea		ecx,[ecx-MMI2_0]
		mov		edx,[ebx].ADDIN.mminport[8]
		.if sdword ptr ecx>0
			lea		edx,[ebx].ADDIN.XRam[edx]
		.endif
	.elseif ecx>=MMI3_0 && ecx<=MMI3_7
		lea		ecx,[ecx-MMI3_0]
		mov		edx,[ebx].ADDIN.mminport[12]
		.if sdword ptr ecx>0
			lea		edx,[ebx].ADDIN.XRam[edx]
		.endif
	.endif
	mov		portbit,eax
	mov		portaddr,edx
	retn

ClkGenProc endp

AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	mii:MENUITEMINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==AM_INIT
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_SUBMENU
		invoke GetMenuItemInfo,[ebx].ADDIN.hMenu,IDM_VIEW,FALSE,addr mii
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuClkGen
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGCLKGEN,hWin,addr ClkGenProc,0
		;Return hook flags
		mov		eax,AH_ALECHANGED or AH_COMMAND or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
	.elseif eax==AM_ALECHANGED
		.if fActive
			mov		eax,nCount
			lea		eax,[eax+1]
			.if eax>=Divisor
				xor		ClkOut,TRUE
				.if sdword ptr portaddr>0
					mov		eax,portbit
					mov		edx,portaddr
					xor		ebx,TRUE
					.if ClkOut
						or		byte ptr [edx],al
					.else
						xor		eax,0FFh
						and		byte ptr [edx],al
					.endif
				.endif
				mov		eax,lpAddin
				push	0
				push	ebx
				push	AM_CLOCKOUT
				push	[eax].ADDIN.hWnd
				push	AH_CLOCKOUT
				call	[eax].ADDIN.lpSendAddinMessage
				xor		eax,eax
			.endif
			mov		nCount,eax
		.endif
	.elseif eax==AM_COMMAND
		mov		eax,lParam
		.if eax==IDAddin
			invoke IsWindowVisible,hDlg
			.if eax
				invoke ShowWindow,hDlg,SW_HIDE
			.else
				invoke ShowWindow,hDlg,SW_SHOW
			.endif
		.endif
	.elseif eax==AM_PROJECTOPEN
		;Load settings from project file
		invoke GetPrivateProfileString,addr szProClkGen,addr szProClkGen,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		invoke GetItemInt,addr buffer,1
		mov		Divisor,eax
		invoke SetDlgItemInt,hDlg,IDC_EDTDIVISOR,eax,FALSE
		invoke GetItemInt,addr buffer,0
		mov		fActive,eax
		invoke CheckDlgButton,hDlg,IDC_CHKACTIVE,eax
		invoke GetItemInt,addr buffer,1
		invoke SendDlgItemMessage,hDlg,IDC_CBOOUT,CB_SETCURSEL,eax,0
		invoke SendMessage,hDlg,WM_COMMAND,(CBN_SELCHANGE shl 16) or IDC_CBOOUT,0
		invoke GetWindowRect,hDlg,addr rect
		mov		eax,rect.left
		sub		rect.right,eax
		mov		eax,rect.top
		sub		rect.bottom,eax
		invoke GetItemInt,addr buffer,10
		mov		rect.left,eax
		invoke GetItemInt,addr buffer,10
		mov		rect.top,eax
		invoke MoveWindow,hDlg,rect.left,rect.top,rect.right,rect.bottom,TRUE
	.elseif eax==AM_PROJECTCLOSE
		;Save settings to project file
		mov		buffer,0
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		invoke PutItemInt,addr buffer,Divisor
		invoke PutItemInt,addr buffer,fActive
		invoke SendDlgItemMessage,hDlg,IDC_CBOOUT,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke GetWindowRect,hDlg,addr rect
		invoke PutItemInt,addr buffer,rect.left
		invoke PutItemInt,addr buffer,rect.top
		invoke WritePrivateProfileString,addr szProClkGen,addr szProClkGen,addr buffer[1],lParam
	.endif
	xor		eax,eax
  Ex:
	ret

AddinProc endp

InstallClkGen proc

	ret

InstallClkGen endp

UnInstallClkGen proc

	invoke DestroyWindow,hDlg
	ret

UnInstallClkGen endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
		invoke InstallClkGen
	.elseif reason==DLL_PROCESS_DETACH
		invoke UnInstallClkGen
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
