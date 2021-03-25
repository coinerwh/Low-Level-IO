TITLE Low-Level I/O Procedures   (low_level_IO.asm)

; Description: Takes string input from user. Validates string values represent valid num
;		Converts strings of ASCII digits to its numberic value representation
;		Stores 10 valid integers from user in array and calculates sum and average of array
;		Converts array of signed integers as well as sum and average to string and prints output

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Reads in user input as a string and saves to array address provided
;
; Preconditions: Provide input array to save string to as well as buffer size
;
; Receives:	
;	prompt = address of prompt string literal
;	userInput = address of array to store input
;	stringLength = buffer size of array
;
; returns: userInput = address of array with stored characters
; ---------------------------------------------------------------------------------
mGetString MACRO prompt, userInput, stringLength
	push	EAX
	push	ECX
	push	EDX

	mDisplayString prompt
	mov		EDX, userInput
	mov		ECX, stringLength
	call	ReadString

	pop		EDX
	pop		ECX
	pop		EAX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints provided string literal
;
; Preconditions: requires address of string array to print
;
; Receives: stringAddr = address of string to print
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString MACRO stringAddr
	push	EDX
	mov		EDX, stringAddr
	call	WriteString
	pop		EDX
ENDM

.data
	; user greeting, instructions, and other general print statements
	titleAndAuthor	BYTE	"Low-Level I/O Procedures. Programmed by Wil Coiner",13,10,0
	extCr1			BYTE	"**EC: Number each line of input and display running subtotal",13,10,13,10,0
	intro1			BYTE	"Please provide 10 signed decimal integers. Limited to 26 characters for each integer.",13,10,0
	intro2			BYTE	"Each number must be small enough to fit inside a 32 bit register.",13,10,
							"After you have entered the numbers the program will display the integers with their sum and average value.",13,10,13,10,0
	farewell		BYTE	13,10,13,10,"Thanks for playing!",13,10,0

	; input and output print statements
	enterNum		BYTE	". Please enter a signed number: ",0
	invalidNum		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
	printNum		BYTE	13,10,"You entered the following numbers: ",13,10,0
	printSum		BYTE	13,10,"The sum of these numbers is: ",0
	printAvg		BYTE	13,10,"The rounded average is: ",0
	comma			BYTE	", ",0
	newline			BYTE	13,10,0
	subTotalPrint	BYTE	"Subtotal: ",0

	; program variables
	inputLength		DWORD	?
	numArray		SDWORD	10 DUP(?)
	numSum			SDWORD	0
	numAvg			SDWORD	?
	 

.code
main PROC
	; intro
	push	OFFSET intro2
	push	OFFSET intro1
	push	OFFSET extCr1
	push	OFFSET titleAndAuthor
	call	Introduction

; --------------------------
; Read input loop.
;	Asks user for 10 integers
;	Converts each string to integer
;	Saves to array, takes sum and average
; --------------------------
	; main integer read loop setup
	mov		ECX, 10
	mov		EDI, OFFSET numArray
	mov		EDX, 1									; counter for extra credit

_readLoop:
	; read input and add to array
	push	EDX
	push	EDI										; current element in array
	push	OFFSET enterNum
	push	OFFSET invalidNum
	call	ReadVal									; has internal loop and will not return until valid input
	
	; add element to sum
	mov		EAX, [EDI]
	add		numSum, EAX								; add element to sum total
	add		EDI, 4
	inc		EDX
	mDisplayString OFFSET subTotalPrint
	push	numSum
	call	WriteVal
	mDisplayString OFFSET newline
	mDisplayString OFFSET newline
	loop	_readLoop

	; find average of array
	mov		EAX, numSum
	mov		EBX, 10
	cdq
	idiv	EBX
	mov		numAvg, EAX

; --------------------------
; Converts each element of array to string
;	Prints each string
;	Prints sum and average
; --------------------------
	mov		ECX, 10
	mov		ESI, OFFSET numArray
	mDisplayString OFFSET printNum

_writeLoop:
	push	[ESI]
	call	WriteVal
	cmp		ECX, 1
	je		_skipComma
	mDisplayString OFFSET comma

_skipComma:
	add		ESI, 4
	loop	_writeLoop

	; print sum
	mDisplayString OFFSET printSum
	push	numSum
	call	WriteVal

	; print average
	mDisplayString OFFSET printAvg
	push	numAvg
	call	WriteVal


	; farewell to user
	push	OFFSET farewell
	call	FarewellProc

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------------------
; Name: Introduction
;
; This procedure provides the title and introduces the program to the user
;
; Precondtions:  input for print statements must be string literals. Need constant value to display
;
; Postconditions: All registers are saved and returned to their original state
; 
; Receives: 
;	[EBP+8] = title and author string address
;	[EBP+12] = extra credit 1 print statement address
;	[EBP+16] = intro print statement 1 address
;	[EBP+20] = intro print statement 2 address
;
; Returns: none
;
; ---------------------------------------------------------------------------------------------
Introduction PROC
	; complete stack frame
	push	EBP
	mov		EBP, ESP

	; print title and intro
	mDisplayString [EBP+8]
	mDisplayString [EBP+12]
	mDisplayString [EBP+16]
	mDisplayString [EBP+20]

	; clean up stack frame
	pop		EBP
	ret		16
Introduction ENDP

; ---------------------------------------------------------------------------------------------
; Name: ReadVal
;
; Receives user input, converts string of ascii digits to numeric value, and validates is valid number
;	Also verifies input is within signed 32-bit range
;
; Precondtions:  Requires two print statements for asking user and returning invalid input error
;	Also requires address of current array index to place the numeric value after validated
;
; Postconditions: All registers saved and restored
; 
; Receives: 
;	[EBP+8] = invalid value print statement
;	[EBP+12] = user input print statement
;	[EBP+16] = address of current array index
;	[EBP+20] = Counter for user input (EC1)
;
; Returns: valid input placed in input array address provided in [EBP+16]
;
; ---------------------------------------------------------------------------------------------
ReadVal PROC
	LOCAL input[26]:BYTE, num:SDWORD, negNum:SDWORD, lowerBound:DWORD
	pushad


_inputLoop:
	; EC1 print user input count
	push	[EBP+20]
	call	WriteVal
	; ask user for string input
	mov		EAX, [EBP+12]
	lea		EBX, input
	mGetString	EAX, EBX, LENGTHOF input
	lea		EAX, input
	mov		ESI, EAX
	mov		ECX, LENGTHOF input
	cld

_checkString:
	lodsb
	cmp		al, 0
	je		_checkNull							; checks if nothing entered
	cmp		al, 48
	jl		_checkNegPos

	cmp		al, 57
	jg		_notNum

_continueCheck:
	loop	_checkString

_checkNegPos:
	cmp		al, 43								; positive symbol
	je		_checkPosition
	cmp		al, 45								; negative symbol
	je		_checkPosition
	jmp		_notNum

_checkPosition:
	cmp		ECX, LENGTHOF input					; checks if + or - not in first index
	jne		_notNum
	jmp		_continueCheck

_checkNull:
	cmp		ECX, LENGTHOF input
	je		_notNum
	jmp		_endInputLoop

_endInputLoop:
	mov		ECX, LENGTHOF input
	mov		num, 0								; initialize num 
	mov		negNum, 1							; initialize negNum with 1
	lea		EAX, input
	mov		ESI, EAX
	mov		EAX, 0
	mov		EDX, 0
	mov		lowerBound, 0						; initialize lower bound Boolean
	cld	

_convertToNum:
	lodsb
	cmp		EAX, 0
	je		_end								; done with conversion
	cmp		EAX, 43								; if positive symbol
	je		_convertToNum
	cmp		EAX, 45
	je		_negative
	sub		EAX, 48
	mov		EBX, EAX
	mov		EAX, num
	mov		EDX, 10
	imul	EDX
	jo		_checkLowerBound					; number too large for 32-bit
	add		EAX, EBX
	jo		_checkLowerBound

_continueConversion:
	mov		num, EAX
	mov		EAX, 0								; clear entire register for lodsb

_continueAfterNeg:
	loop	_convertToNum
	jmp		_end

_negative:
	mov		negNum, -1
	jmp		_continueAfterNeg

; checks if lower bound of signed 32-bit signed integer
_checkLowerBound:
	cmp		negNum, -1
	jne		_notNum
	cmp		EAX, 2147483648
	jne		_notNum
	mov		lowerBound, 1
	imul	negNum
	jmp		_continueConversion

_notNum:
	mDisplayString	[EBP+8]
	jmp		_inputLoop

_end:	
	; set as negative or positive
	cmp		lowerBound, 1
	mov		EAX, num
	je		_addToArray
	mov		EDX, negNum
	imul	EDX
	jo		_notNum

_addToArray:
	mov		EBX, [EBP+16]
	mov		[EBX], EAX

	popad
	ret		16
ReadVal	ENDP

; ---------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Reads in numeric SDWORD and converts to string of ascii digits
;	Invokes mDisplayString to print string representation of numeric input
;
; Precondtions:  SDWORD value that can be interpreted as a numeric value
;
; Postconditions: No variables or registers changed
; 
; Receives: [EBP+8] = SDWORD numeric value
;
; Returns: none
;
; ---------------------------------------------------------------------------------------------
WriteVal PROC
	LOCAL	digit:DWORD, numString[27]:SDWORD, negBool:BYTE
	pushad

	mov		EAX, [EBP+8]
	lea		EDI, numString
	mov		ECX, 0
	mov		negBool, 0

	cmp		EAX, 0
	jge		_divLoop						; check if number is negative
	mov		EBX, -1
	mul		EBX								
	mov		negBool, 1

_divLoop:
	mov		EDX, 0
	mov		EBX, 10
	div		EBX
	push	EDX								; pushing remainder to pop into digit variable to build string
	inc		ECX
	cmp		EAX, 0
	jne		_divLoop		

	lea		EDI, numString

	cmp		negBool, 1
	jne		_stringGenLoop
	mov		al, 45							; add negative symbol ascii
	stosb

_stringGenLoop:
	pop		digit
	mov		al, BYTE PTR digit
	add		al, 48							; converting to ascii
	stosb
	loop	_stringGenLoop

	mov		al, 0
	stosb

	lea		ESI, numString
	mDisplayString ESI

	popad
	ret		4
WriteVal ENDP

; ---------------------------------------------------------------------------------------------
; Name: Farewell
;
; This procedure displays a farewell to the user
;
; Precondtions:  input for print statement must be string literal
;
; Postconditions: All registers are saved and returned to original state
; 
; Receives: [EBP+8] = farewell print statement string address
;
; Returns: none
;
; ---------------------------------------------------------------------------------------------
FarewellProc PROC
	push	EBP
	mov		EBP, ESP

	mDisplayString [EBP+8]

	pop		EBP
	ret		4
FarewellProc ENDP

END main
