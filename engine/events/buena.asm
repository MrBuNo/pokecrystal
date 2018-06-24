BuenasPassword:
	xor a
	ld [wWhichIndexSet], a
	ld hl, .MenuHeader
	call CopyMenuHeader
	ld a, [wBuenasPassword]
	ld c, a
	farcall GetBuenasPassword
	ld a, [wMenuBorderLeftCoord]
	add c
	add $2
	ld [wMenuBorderRightCoord], a
	call PushWindow
	call DoNthMenu ; menu
	farcall Buena_ExitMenu
	ld b, $0
	ld a, [wMenuSelection]
	ld c, a
	ld a, [wBuenasPassword]
	maskbits NUM_PASSWORDS_PER_CATEGORY
	cp c
	jr nz, .wrong
	ld b, $1

.wrong
	ld a, b
	ld [wScriptVar], a
	ret

.MenuHeader: ; 0x8afa9
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 10, 7
	dw .MenuData
	db 1 ; default option
; 0x8afb1

	db 0

.MenuData: ; 0x8afb2
	db STATICMENU_CURSOR | STATICMENU_DISABLE_B ; flags
	db 0 ; items
	dw .PasswordIndices
	dw .PlacePasswordChoices
; 0x8afb4

.PasswordIndices:
	db NUM_PASSWORDS_PER_CATEGORY
x = 0
rept NUM_PASSWORDS_PER_CATEGORY
	db x
x = x + 1
endr
	db -1

.PlacePasswordChoices:
	push de
	ld a, [wBuenasPassword]
	and $f0
	ld c, a
	ld a, [wMenuSelection]
	add c
	ld c, a
	farcall GetBuenasPassword
	pop hl
	call PlaceString
	ret

BuenaPrize:
	xor a
	ld [wMenuScrollPosition], a
	ld a, $1
	ld [wMenuSelection], a
	call Buena_PlacePrizeMenuBox
	call Buena_DisplayBlueCardBalance
	ld hl, .Text_AskWhichPrize
	call PrintText
	jr .okay

.loop
	ld hl, .Text_AskWhichPrize
	call BuenaPrintText

.okay
	call DelayFrame
	call UpdateSprites
	call PrintBlueCardBalance
	call Buena_PrizeMenu
	jr z, .done
	ld [wMenuSelectionQuantity], a
	call Buena_getprize
	ld a, [hl]
	ld [wNamedObjectIndexBuffer], a
	call GetItemName
	ld hl, .Text_IsThatRight
	call BuenaPrintText
	call YesNoBox
	jr c, .loop

	ld a, [wMenuSelectionQuantity]
	call Buena_getprize
	inc hl
	ld a, [hld]
	ld c, a
	ld a, [wBlueCardBalance]
	cp c
	jr c, .InsufficientBalance

	ld a, [hli]
	push hl
	ld [wCurItem], a
	ld a, $1
	ld [wItemQuantityChangeBuffer], a
	ld hl, wNumItems
	call ReceiveItem
	pop hl
	jr nc, .BagFull
	ld a, [hl]
	ld c, a
	ld a, [wBlueCardBalance]
	sub c
	ld [wBlueCardBalance], a
	call PrintBlueCardBalance
	jr .Purchase

.InsufficientBalance:
	ld hl, .Text_NotEnoughPoints
	jr .print

.BagFull:
	ld hl, .Text_NoRoom
	jr .print

.Purchase:
	ld de, SFX_TRANSACTION
	call PlaySFX
	ld hl, .Text_HereYouGo

.print
	call BuenaPrintText
	jr .loop

.done
	call CloseWindow
	call CloseWindow
	ld hl, .Text_PleaseComeBackAgain
	call PrintText
	call JoyWaitAorB
	call PlayClickSFX
	ret

.Text_AskWhichPrize: ; 0x8b072
	; Which prize would you like?
	text_jump UnknownText_0x1c589f
	db "@"
; 0x8b077

.Text_IsThatRight: ; 0x8b077
	; ? Is that right?
	text_jump UnknownText_0x1c58bc
	db "@"
; 0x8b07c

.Text_HereYouGo:	; Here you go!
	text_jump UnknownText_0x1c58d1
	db "@"
; 0x8b081

.Text_NotEnoughPoints: ; 0x8b081
	; You don't have enough points.
	text_jump UnknownText_0x1c58e0
	db "@"
; 0x8b086

.Text_NoRoom: ; 0x8b086
	; You have no room for it.
	text_jump UnknownText_0x1c58ff
	db "@"
; 0x8b08b

.Text_PleaseComeBackAgain: ; 0x8b08b
	; Oh. Please come back again!
	text_jump UnknownText_0x1c591a
	db "@"
; 0x8b090

Buena_DisplayBlueCardBalance:
	ld hl, BlueCardBalanceMenuHeader
	call LoadMenuHeader
	ret

PrintBlueCardBalance:
	ld de, wBlueCardBalance
	call .DrawBox
	ret

.DrawBox:
	push de
	xor a
	ld [hBGMapMode], a
	ld hl, BlueCardBalanceMenuHeader
	call CopyMenuHeader
	call MenuBox
	call UpdateSprites
	call MenuBoxCoord2Tile
	ld bc, SCREEN_WIDTH + 1
	add hl, bc
	ld de, .Points_string
	call PlaceString
	ld h, b
	ld l, c
	inc hl
	ld a, " "
	ld [hli], a
	ld [hld], a
	pop de
	lb bc, 1, 2
	call PrintNum
	ret

.Points_string:
	db "Points@"

BlueCardBalanceMenuHeader: ; 0x8b0d1
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 11, 11, 13

Buena_PlacePrizeMenuBox:
	ld hl, .MenuHeader
	call LoadMenuHeader
	ret

.MenuHeader ; 0x8b0dd
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 17, TEXTBOX_Y - 1

Buena_PrizeMenu:
	ld hl, .MenuHeader
	call CopyMenuHeader
	ld a, [wMenuSelection]
	ld [wMenuCursorBuffer], a
	xor a
	ld [wWhichIndexSet], a
	ld [hBGMapMode], a
	call InitScrollingMenu
	call UpdateSprites
	call ScrollingMenu
	ld a, [wMenuSelection]
	ld c, a
	ld a, [wMenuCursorY]
	ld [wMenuSelection], a
	ld a, [wMenuJoypad]
	cp $2
	jr z, .cancel
	ld a, c
	and a
	ret nz

.cancel
	xor a
	ret

.MenuHeader: ; 0x8b113
	db MENU_BACKUP_TILES ; flags
	menu_coords 1, 1, 16, 9
	dw .MenuData
	db 1 ; default option
; 0x8b11b

	db 0

.MenuData: ; 0x8b11c
	db SCROLLINGMENU_DISPLAY_ARROWS ; flags
	db 4, 13 ; rows, columns
	db 1 ; spacing
	dba .indices
	dba .prizeitem
	dba .prizepoints

NUM_BUENA_PRIZES EQU 9 ; ((BuenaPrizeItems.End - BuenaPrizeItems) / 2)

.indices
	db NUM_BUENA_PRIZES
x = 1
rept NUM_BUENA_PRIZES
	db x
x = x + 1
endr
	db -1

.prizeitem
	ld a, [wMenuSelection]
	call Buena_getprize
	ld a, [hl]
	push de
	ld [wNamedObjectIndexBuffer], a
	call GetItemName
	pop hl
	call PlaceString
	ret

.prizepoints
	ld a, [wMenuSelection]
	call Buena_getprize
	inc hl
	ld a, [hl]
	ld c, "0"
	add c
	ld [de], a
	ret

Buena_getprize:
	dec a
	ld hl, BuenaPrizeItems
	ld b, 0
	ld c, a
	add hl, bc
	add hl, bc
	ret

INCLUDE "data/items/buena_prizes.asm"