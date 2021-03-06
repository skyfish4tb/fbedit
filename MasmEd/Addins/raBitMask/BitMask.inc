
include windows.inc
;include comctl32.inc
include gdi32.inc
include user32.inc
includelib gdi32.lib
includelib user32.lib

include masm32.inc
includelib masm32.lib

include ..\Addins.inc

DialogProc 				proto :DWORD,:DWORD,:DWORD,:DWORD
EditProc 				proto :DWORD,:DWORD,:DWORD,:DWORD
OldEditProc 			proto :DWORD
ResetValues 			proto :DWORD
ParseNumber 			proto :DWORD,:DWORD

EDITSUBCLS struct
	hWnd		HWND	?
	lpOldProc	DWORD	?
EDITSUBCLS EndS

.const
IDD_DLG				EQU 1000
IDC_STATIC1002		EQU 1002
IDC_STATIC1003		EQU 1003
IDC_STATIC1004		EQU 1004
IDC_STATIC1005		EQU 1005
IDC_STATIC1006		EQU 1006
IDC_STATIC1007		EQU 1007
IDC_STATIC1008		EQU 1008
IDC_STATIC1009		EQU 1009
IDC_STATIC1010		EQU 1010
IDC_STATIC1011		EQU 1011
IDC_STATIC1012		EQU 1012
IDC_STATIC1013		EQU 1013
IDC_STATIC1014		EQU 1014
IDC_STATIC1015		EQU 1015
IDC_STATIC1016		EQU 1016
IDC_STATIC1017		EQU 1017
IDC_STATIC1018		EQU 1018
IDC_STATIC1019		EQU 1019
IDC_STATIC1020		EQU 1020
IDC_STATIC1021		EQU 1021
IDC_STATIC1022		EQU 1022
IDC_STATIC1023		EQU 1023
IDC_STATIC1024		EQU 1024
IDC_STATIC1025		EQU 1025
IDC_STATIC1026		EQU 1026
IDC_STATIC1027		EQU 1027
IDC_STATIC1028		EQU 1028
IDC_STATIC1029		EQU 1029
IDC_STATIC1030		EQU 1030
IDC_STATIC1031		EQU 1031
IDC_STATIC1032		EQU 1032
IDC_STATIC1033		EQU 1033
IDC_STATIC1034		EQU 1034
IDC_STATIC1035		EQU 1035
IDC_STATIC1036		EQU 1036
IDC_STATIC1037		EQU 1037
IDC_STATIC1038		EQU 1038
IDC_STATIC1039		EQU 1039
IDC_STATIC1040		EQU 1040
IDC_STATIC1041		EQU 1041
IDC_STATIC1042		EQU 1042
IDC_STATIC1043		EQU 1043
IDC_STATIC1044		EQU 1044
IDC_STATIC1045		EQU 1045
IDC_STATIC1046		EQU 1046
IDC_STATIC1047		EQU 1047
IDC_STATIC1048		EQU 1048
IDC_STATIC1049		EQU 1049
IDC_STATIC1050		EQU 1050
IDC_STATIC1051		EQU 1051
IDC_STATIC1052		EQU 1052
IDC_STATIC1053		EQU 1053
IDC_STATIC1054		EQU 1054
IDC_STATIC1055		EQU 1055
IDC_STATIC1056		EQU 1056
IDC_STATIC1057		EQU 1057
IDC_STATIC1058		EQU 1058
IDC_STATIC1059		EQU 1059
IDC_STATIC1060		EQU 1060
IDC_STATIC1061		EQU 1061
IDC_STATIC1062		EQU 1062
IDC_STATIC1063		EQU 1063
IDC_STATIC1064		EQU 1064
IDC_STATIC1065		EQU 1065
IDC_STATIC1066		EQU 1066
IDC_STATIC1067		EQU 1067
IDC_STATIC1068		EQU 1068
IDC_STATIC1069		EQU 1069
IDC_STATIC1070		EQU 1070
IDC_STATIC1071		EQU 1071
IDC_STATIC1072		EQU 1072
IDC_STATIC1073		EQU 1073
IDC_STATIC1074		EQU 1074
IDC_STATIC1075		EQU 1075
IDC_STATIC1076		EQU 1076
IDC_STATIC1077		EQU 1077
IDC_STATIC1078		EQU 1078
IDC_STATIC1079		EQU 1079
IDC_STATIC1080		EQU 1080
IDC_STATIC1081		EQU 1081
IDC_STATIC1082		EQU 1082
IDC_STATIC1083		EQU 1083
IDC_STATIC1084		EQU 1084
IDC_STATIC1085		EQU 1085
IDC_STATIC1086		EQU 1086
IDC_STATIC1087		EQU 1087
IDC_STATIC1088		EQU 1088
IDC_STATIC1089		EQU 1089
IDC_STATIC1090		EQU 1090
IDC_STATIC1091		EQU 1091
IDC_STATIC1092		EQU 1092
IDC_STATIC1093		EQU 1093
IDC_STATIC1094		EQU 1094
IDC_STATIC1095		EQU 1095
IDC_STATIC1096		EQU 1096
IDC_STATIC1097		EQU 1097
IDC_RADIOBUTTON_HEX		EQU 1121
IDC_RADIOBUTTON_DEC		EQU 1122
IDC_BUTTON_AND		EQU 1113
IDC_BUTTON_OR		EQU 1114
IDC_BUTTON_NOT		EQU 1115
IDC_BUTTON_XOR		EQU 1116
IDC_BUTTON_RESET 	EQU	1117
IDC_EDIT_DEST		EQU 1118
IDC_EDIT_SRC		EQU 1119
IDC_EDIT_RES		EQU 1120

.data?
wOutput				WORD 	?
	
.data
szMenuName				db 			"GBitMask",0
edits 					EDITSUBCLS	2 dup (<0,0>)
flDest 					dd 			0
flSrc 					dd 			0
flRes 					dd 			0
CatchUpdate 			BOOL 		FALSE

;-------------------------------------------------------------------
CTEXT MACRO Text
LOCAL szText

	.DATA
	szText BYTE Text, 0
	.CODE
	ExitM < Offset szText >
ENDM

M2M MACRO M1, M2
	PUSH M2
	POP M1
ENDM

;-------------------------------------------------------------------
LOWORD MACRO DoubleWord	;;Retrieves the low WORD from double WORD argument
	MOV	EAX,DoubleWord
	AND	EAX,0FFFFh		;;Set to low word 
ENDM

;-------------------------------------------------------------------
HIWORD MACRO DoubleWord	;;Retrieves the high word from double word 
	MOV	EAX,DoubleWord
	SHR	EAX,16			;;Shift 16 for high word to set to high WORD
ENDM
;-------------------------------------------------------------------
;Returns formatted hex string without leading zeros
formhex$ MACRO DDValue
LOCAL resstr
LOCAL rvstring
LOCAL _loop
LOCAL _notnull
LOCAL _ecxz
LOCAL _zero
LOCAL _exit

.data
	resstr db 12 dup (0)
	rvstring db 12 dup (0)
	align 4
.code
	push esi
	push edi
	push ebx
	push ecx
	
	lea esi,rvstring
	lea edi,resstr
	invoke dw2hex,DDValue,esi	;get formatted hex string - 8 characters length, with leading zeros
	xor ecx,ecx
_loop:
	movzx ebx,byte ptr [esi]
	test ebx,ebx				;exit on terninated null
	jz _exit
	cmp ebx,48					;check leadin zeros
	jne _notnull				;not zero - copy the character to result string
	jecxz _ecxz					;jump over leadin zeros if no other character has been found before
_notnull:
	inc ecx						;increase counter - from here we accept all zeros
	mov [edi],ebx
	inc edi
_ecxz:
	inc esi
	jmp _loop
_zero:
	inc ecx						;just increase counter and store "0" in result string
	lea edi,resstr
	mov ebx,48
	mov [edi],ebx	
_exit:
	jecxz _zero					;the number is zero - so we must return "0"
	pop ecx
	pop ebx
	pop edi
	pop esi
	EXITM <ADDR resstr>
ENDM
