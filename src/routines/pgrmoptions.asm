RenameProgram:
	call	CheckIfCurrentProgramIsUs
	jp	z,DrawSettingsMenu
RenameGood:
	
	ld	hl,skinColor
	ld	a,(hl)
	push	af
	ld	a,255
	ld	(hl),a
	drawRectFilled(199,173,313,215)
	pop	af
	ld	(skinColor),a
	print(NewNameStr,199,173)
	
	ld	hl,199
	ld	(posX),hl
	ld	a,195
	ld	(posY),a
	
	ld	a,(currInputMode)
	call	DrawChar
	ld	hl,199
	ld	(posX),hl

	xor	a,a
	ld	(cursor),a
	dec	a
	ld	(currInputMode),a
	ld	hl,NameBuffer+1
	ld	(NameBufferPtr),hl

GetNewName:
	call	DrawTime
	call	FullBufCpy
	call	_GetCSC
	or	a,a
	call	z,DecrementAPD
	cp	a,skDel
	jr	z,RenameGood
	cp	a,skLeft
	jr	z,RenameGood
	cp	a,skAlpha
	jr	z,ToggleInput
	cp	a,skClear
	jp	z,ReturnHome
	cp	a,sk2nd
	jp	z,ConfirmRename
	cp	a,skEnter
	jp	z,ConfirmRename
	sub	a,skAdd
	jp	c,GetNewName
	cp	a,skMath-skAdd+1
	jp	nc,GetNewName
charTableCur =$+1
	ld	hl,CharTableNormal
	call	_AddHLAndA		; find the offset
	ld	a,(hl)
	or	a,a
	jr	z,GetNewName
	ld	e,a
cursor = $+1
	ld	a,0
	cp	a,8
	jr	z,GetNewName
	or	a,a
	jr	nz,+_
	push	de
	ld	hl,(charTableCur)
	ld	de,CharTableNumber
	call	_CpHLDE
	pop	bc
	jr	z,GetNewName
	ld	e,c
_:	ld	a,e
	ld	hl,(NameBufferPtr)
	ld	(hl),a
	call	DrawChar
	ld	hl,cursor
	inc	(hl)
currInputMode =$+1
	ld	a,255
	call	DrawChar
	ld	hl,(posX)
	ld	de,-9
	add	hl,de
	ld	(posX),hl
	ld	hl,(NameBufferPtr)
	inc	hl
	ld	(NameBufferPtr),hl
	jp	GetNewName

ToggleInput:
	ld	hl,CharTableNormal
	ld	e,255
	ld	a,(currInputMode)
	cp	a,254
	jr	z,+_
	dec	e
	ld	hl,CharTableNumber
_:	ld	(charTableCur),hl
	ld	a,e
	ld	(currInputMode),a
	call	DrawChar
	ld	hl,(posX)
	ld	de,-9
	add	hl,de
	ld	(posX),hl
	jp	GetNewName
	
ConfirmRename:
	ld	hl,_Arc_Unarc
	ld	(jump_SMC),hl
	ld	hl,(NameBufferPtr)
	ld	(hl),0
	ld	de,OP1
	ld	a,(de)
	ld	hl,NameBuffer
	ld	(hl),a
	inc	de
	inc	hl
	ld	a,(de)
	cp	a,65
	jr	nc,+_				; check if program is hidden
	ld	a,(hl)
	sub	a,64
	ld	(hl),a
_:	call	_PushOP1
	ld	hl,NameBuffer
	call	_Mov9ToOP1
	call	_ChkFindSym
	push	af
	call	_PopOP1
	pop	af
	jp	nc,GetNewName			; check if name already exists
_:	call	_ChkFindSym
	call	_ChkInRam
	jr	nz,+_
	ld	hl,$0003D8
	ld	(jump_SMC),hl
	call	_PushOP1
	call	_Arc_Unarc
	call	_PopOP1
	jr	-_
_:	ex	de,hl
	ld	de,9
	add	hl,de				; skip VAT stuff
	ld	e,(hl)
	add	hl,de
	inc	hl				; size of name
	call	_LoadDEInd_s
	push	hl
	push	de
	call	_PushOP1
	ld	hl,NameBuffer
	call	_Mov9ToOP1
	call	_PushOP1
	pop	hl
	push	hl
	ld	a,(OP1)
	call	_CreateVar
	inc	de
	inc	de
	pop	bc
	pop	hl
	call	_ChkBCIs0
	jr	z,+_
	ldir	
_:	call	_PopOP1
jump_SMC =$+1	
	call	_Arc_Unarc
	call	_PopOP1
	call	_ChkFindSym
	call	_DelVarArc
	ld	hl,pixelshadow2
	ld	(programNameLocationsPtr),hl
	xor	a,a
	sbc	hl,hl
	ld	(numprograms),hl
	call	sort				; sort the VAT alphabetically
	call	FindPrograms			; find available assembly programs in the VAT
	call	MoveCommonToSafeRAM
	ld	hl,NameBuffer+1
	jp	SearchAlphaName
ReturnHome:
	jp	MAIN_START_LOOP

NameBuffer	equ CursorImage
NameBufferPtr:
	.dl	NameBuffer+1

LoadProgramOptions:
	call	CheckIfCurrentProgramIsUs
	jp	z,DrawSettingsMenu			; don't change the options if we are the program!
	ld	hl,PgrmOptions
	ld	bc,4
	call	_MemClear
	cpl						; A=0FFh
	bit	pgrmArchived,(iy+pgrmStatus)
	jr	z,NotInArc
	ld	(ArchiveSet),a				; mark archive as set
NotInArc:
	bit	pgrmLocked,(iy+pgrmStatus)
	jr	z,NotLocked
	ld	(LockSet),a
NotLocked:
	bit	pgrmHidden,(iy+pgrmStatus)
	jr	z,DrawPrgmOptions
	ld	(HideSet),a
DrawPrgmOptions:
	call	GetOptionPixelOffset
	ld	a,230
	ld	(backColor),a
	ld	a,(currMenuSel)
	call	GetRightString
	ld	bc,199
	ld	(posX),bc
	call	DrawString
	SetDefaultTextColor()

_:	call	FullBufCpy
	call	_GetCSC
	ld	hl,DrawPrgmOptions
	push	hl
	cp	a,skDown
	jp	z,incrementOption
	cp	a,skUp
	jp	z,decrementOption
	pop	hl
	cp	a,skAlpha
	jp	z,SetOptions
	cp	a,skMode
	jp	z,SetOptions
	cp	a,skClear
	jp	z,SetOptions
	cp	a,skDel
	jp	z,SetOptions
	cp	a,sk2nd
	jp	z,CheckWhatToDo
	cp	a,skEnter
	jr	nz,-_
	jp	CheckWhatToDo
 
incrementOption:
	call	EraseSel
	cp	a,2
	ret	z
	inc	a
	ld	(currMenuSel),a
	ret
GetOptionPixelOffset:
	ld	a,(currMenuSel)
	ld	l,a
	ld	h,11
	mlt	hl
	ld	a,118
	add	a,l
	ld	bc,199
	ld	(posX),bc
	ld	(posY),a
	ret
decrementOption:
	call	EraseSel
	or	a,a
	ret	z
	dec	a
	ld	(currMenuSel),a
	ret
	
EraseSel:
	call	GetOptionPixelOffset
	ld	a,(currMenuSel)
	call	GetRightString
	call	DrawString
	ld	a,(currMenuSel)
	ret
GetRightString:
	ld	hl,ArchiveStatusStr
	or	a,a
	ret	z
	ld	hl,EditStatusStr
	dec	a
	ret	z
	ld	hl,HiddenStr
	dec	a
	ret

;-------------------------------------------------------------------------------
CheckWhatToDo:
	ld	hl,DrawPrgmOptions
	push	hl
	ld	hl,PgrmOptions
	ld	a,(currMenuSel)
	dec	a
	jr	nz,NotOnLock
	ld	a,(prgmbyte)
	cp	a,$BB
	ret	nz					; only want to be able to lock and unlock BASIC programs
NotOnLock:
	ld	a,(currMenuSel)
	call	_AddHLAndA
	ld	a,(hl)					; get the status of the current byte
	cpl
	ld	(hl),a					; invert it, so we can check it later
	ld	hl,skinColor
	ld	a,(hl)
	push	af
	ld	a,255
	ld	(hl),a
	drawRectFilled(302,120,307,125)  		; now let's redraw all the options :P
	drawRectFilled(302,120+11,307,125+11)
	drawRectFilled(302,120+22,307,125+22)
	pop	af
	ld	(skinColor),a
	ld	a,(ArchiveSet)
	or	a,a
	jr	z,_j1
	drawRectFilled(302,120,307,125) 
_j1:
	ld	a,(LockSet)
	or	a,a
	jr	z,_j2
	drawRectFilled(302,120+11,307,125+11)
_j2:
	ld	a,(HideSet)
	or	a,a
	jr	z,_j3
	drawRectFilled(302,120+22,307,125+22)
_j3:
	ret
SetOptions:
	ld	hl,(prgmNamePtr)
	call	NamePtrToOP1				; if 255, archive it
	call	_ChkFindSym
	call	_ChkInRam
	push	af
	ld	a,(ArchiveSet)
	or	a,a
	jr	z,UnarchivePrgm
ArchivePrgm:
	pop	af
	call	z,_Arc_Unarc
	jr	CheckLock
UnarchivePrgm:
	pop	af
	call	nz,_Arc_Unarc

;-------------------------------------------------------------------------------
CheckLock:
	ld	hl,(prgmNamePtr)
	call	NamePtrToOP1
	call	_ChkFindSym
	ld	a,(LockSet)
	or	a,a
	jr	z,UnlockPrgm

;-------------------------------------------------------------------------------
LockPrgm:
	ld	(hl),$06
	jr	CheckHide
UnlockPrgm:
	ld	(hl),$05
CheckHide:
	ld	hl,(prgmNamePtr)
	ld	hl,(hl)
	dec	hl						; bypass name totalPrgmSize byte
	ld	a,(hl)
	cp	a,64
	push	af
	ld	a,(HideSet)
	or	a,a
	jr	z,Unhide
Hide:
	pop	af
	jr	c,ReturnToMain				; already hidden
	sub	a,64
	ld	(hl),a
	jr	ReturnToMain
Unhide:
	pop	af
	jr	nc,ReturnToMain				; already hidden
	add	a,64
	ld	(hl),a
ReturnToMain:
	jp	MAIN_START_LOOP

;-------------------------------------------------------------------------------
CharTableNormal:
	.db 0,"WRMH",0,0   		; + - × ÷ ^ undefined
	.db 0,'Z'+1,"VQLG",0,0 		; (-) 3 6 9 ) TAN VARS undefined
	.db 0,"ZUPKFC",0   		; . 2 5 8 ( COS PRGM STAT
	.db " YTOJEB",0,0		; 0 1 4 7 , SIN APPS XT?n undefined
	.db "XSNIDA"			; STO LN LOG x2 x-1 MATH

;-------------------------------------------------------------------------------
CharTableNumber:
	.db 0,0,0,0,0,0,0   		; + - × ÷ ^ undefined
	.db 0,"369",0,0,0,0 		; (-) 3 6 9 ) TAN VARS undefined
	.db 0,"258",0,0,0,0		; . 2 5 8 ( COS PRGM STAT
	.db "0147",0,0,0,0,0		; 0 1 4 7 , SIN APPS XT?n undefined
	.db 0,0,0,0,0,0,0		; STO LN LOG x2 x-1 MATH