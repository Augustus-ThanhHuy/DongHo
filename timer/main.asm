GIO EQU R0 ; Khai bao thanh ghi chua gia tri gio
PHUT EQU R1 ; khai bao thanh ghi chua gia tri phut
GIAY EQU R2; khai bao thanh ghi chua gia tri giay
CHUC EQU 30H; bien chuc
DONVI EQU 31H; bien don vi
MODE EQU R3; bien luu che do
	
SDA BIT P3.7; khai bao chan SDA ket noi IC DS1307
SCL BIT p3.6; khai bao chan SDA ket noi IC DS1307
	
HTCHINHGIO EQU 32H; khai bao bien hien thi dau 2 cham chinh gio
HTCHINHPHUT EQU 33H; khai bao bien hien thi dau 2 cham chinh phut
	
ORG 0000h; bat dau chuong trinh
	LJMP MAIN; nhay toi ham MAIN
	
ORG 0008H; vector ngat timer0
CALL DEMTHOIGIAN; goi ham doc thoi gian va chuyen doi BCD sang thap phan 
RETI

ORG 0010h; vector ngat timer1
CALL QUETLED; goi ham quet LED
RETI


ORG 0040H; vung nho bat dau ham main
MAIN:
		MOV P0, #0FFh ; dat du lieu P0 ve FF
		MOV P1, #0 ; dat du lieu P1 ve 0
		MOV P2, #0FFh; dat du lieu P2 ve FF
		MOV MODE, #0; mode ban dau la 0 hien thi gio binh thuong 
		
	CALL		I2C_INIT; goi ham khoi tao chan I2C
	CALL		DS1307_INIT; goi ham khoi tao chip DS1307
	
	MOV TMOD, #11h; dat timer 1 va timer 0 che do 16 bit
		CLR TF1; xoa co ngat timer 1
		SETB ET1; cho phep ngat timer 1
		MOV TH1,#3FH; gan truoc gia tri TH1
		MOV TL1, #0; gan truoc gia tri TL1
		
		CLR TF0; xoa co ngat timer 0
		SETB ET0; cho phep ngat timer 0
		MOV TH0, #1CH ; gan truoc gia tri TH0
		MOV TL0, #0B0H;; gan truoc gia tri TL0 (chu y)
		SETB TR1; khoi dong timer 1
		SETB TR0; khoi dong timer 0
		SETB EA; cho phep ngat toan cuc
		
	MOV HTCHINHGIO, #0FFH; tat dau cham gio
	MOV HTCHINHPHUT, #0FFH; tat dau cham phut
	
LAP:
			JNB P1.0,KTTANG; kiem tra nut MODE
			JB P1.0,$ ; neu co bam nut thi cho nha nut
			INC MODE; chuyen mode
			CJNE MODE, #3, KTMODE; neu mode 3 thi quay ve 0
			MOV MODE, #0; gan mode = 0
		CALL CHUYENDOITHAPPHANBCD; goi ham chuyen doi gio phut giay thap phan sang BCD
		CALL DS1307_WRITE_TIME; ghi gia tri moi vao chip DS1307

KTMODE: CJNE MODE, #0, DUNGDEM;  neu mode la khac 0(vao che do cai dat) thi nhay toi dung dem
				SETB TR0; cho phep timer 0 hoat dong
		MOV HTCHINHGIO, #0FFH; tat dau cham gio
		MOV HTCHINHPHUT, #0FFH; tat dau cham phut
		JMP KTTANG; ngay toi kiem tra nut tang
DUNGDEM:
		CLR TR0; mode khac 0 thi dung timer 0
			CJNE MODE,#1,CHINHPHUT; kiem tra neu mode 1 thi vao che do chinh gio
		MOV HTCHINHGIO, #7FH; hien thi cham gio
			MOV HTCHINHPHUT, #0FFH; tat hien thi cham phut
		JMP KTTANG
CHINHPHUT: ;neu mode = 2 thi vao che do chinh phut
	MOV HTCHINHPHUT, #7FH; hien thi cham
		MOV HTCHINHGIO, #0FFH; tat hien thi cham
		
KTTANG: JNB P1.1, KTGIAM; neu nhan nut tang
				JB P1.1, $; cho nha nut tang
				CJNE MODE, #1, KTPHUT1; neu mode 1 thi tang gio
				INC GIO; tang gio
				CJNE GIO, #24, KTPHUT1; neu gio bang 24 thi gan gio 0
				MOV GIO, #0; gan gio = 0
KTPHUT1: CJNE MODE, #2, KTGIAM;	neu che do cai dat phut
			INC PHUT; tang phut
				CJNE PHUT, #60, KTGIAM; bang 60 thi quay ve 00
				MOV PHUT,#0
KTGIAM: 
		JNB P1.2, LAP; neu nhan nut giam
				JB P1.2,$; cho nha nut giam
				CJNE MODE, #1, KTPHUT2; neu mode 1 thi giam gio
				DEC GIO
				CJNE GIO, #255, KTPHUT2; neu gio bang 255 thi gio = 23
				MOV GIO, #23
KTPHUT2: CJNE MODE, #2, LAP; neu mode 2 thi giam phut
			DEC PHUT
				CJNE PHUT, #255, LAP; neu phut = 255 thi phut bang 59
				MOV PHUT, #59
			
	LJMP LAP
	
DEMTHOIGIAN: ; ham dem thoi gian
	CLR TR0; xoa co ngat timer 0
		MOV TH0, #1CH; gan lai gia tri timer 0
		MOV TL0, #0B0H
		CALL DS1307_READ_TIME; goi ham doc chip DS1307
	CALL CHUYENDOIBCDTHAPPHAN; goi ham chuyen doi BCD sang thap phan
RET

QUETLED: ; ham quet LED
	CLR TR1; dung timer 1
		CLR TF1; xoa co ngat
		MOV TH1, #0BFH; gan gia tri timer 1
		MOV TL1, #0
		
		MOV A, GIO;	bat dau tach hang chuc va hang don vi cua gio
		MOV B, #10; gan 10 vao thanh ghi B
		DIV AB; chia A cho B
		MOV CHUC, A; dua ket qua vao bien chuc
		MOV DONVI, B; dua ket qua vao bien don vi
		MOV DPTR,#MALED; gan bang ma LED
		
		MOV A, CHUC; dua hang chuc vao A de hien thi
		MOVC A, @A+DPTR; lay ma hang chuc
		
	ANL A, HTCHINHGIO; hien thi dau cham neu dang vao che do chinh gio
		MOV P0, A; dua ma led ra port 0
		MOV P2,#0FEh; dua chan P0.0 xuong thap de sang LED thu nha
		CALL DELAY	; goi ham delay
		MOV P2, #0FFh; tat tat ca cac LED
		
		MOV A, DONVI; hien thi don vi
		MOVC A,@A+DPTR
	ANL A, HTCHINHGIO ; dau cham
		MOV P0, A
		MOV P2, #0FDh
		CALL DELAY
		MOV P2, #0FFh
		
		; cac ham ben duoi tuong tu o tren cho phut va giay
		MOV A, #10
		MOVC A,@A+DPTR
		MOV P0,A
		MOV P2, #0FBh
		CALL DELAY
		MOV P2, #0FFh
		
		MOV A, PHUT
		MOV B, #10
		DIV AB
		MOV CHUC, A
		MOV DONVI, B
		MOV DPTR, #MALED
		
		MOV A, CHUC
		MOVC A, @A+DPTR
	ANL A, HTCHINHPHUT; dau cham
		MOV P0, A
		MOV P2, #0F7h
		CALL DELAY
		MOV P2, #0FFh
		
		MOV A, DONVI
		MOVC A, @A+DPTR
	ANL A, HTCHINHPHUT; dau cham
		MOV P0, A
		MOV P2, #0EFh
		CALL DELAY
		MOV P2, #0FFh
		
		MOV A, #10
		MOVC A, @A+DPTR
		MOV P0, A
		MOV P2, #00Fh
		CALL DELAY
		MOV P2, #0FFh
		
		MOV A,GIAY
		MOV B,# 10
		DIV AB
		MOV CHUC, A
		MOV DONVI, B
		MOV DPTR, #MALED
		
		MOV A, CHUC
		MOVC A, @A+DPTR
		MOV P0, A
		MOV P2, #0BFh
		CALL DELAY
		MOV P2, #0FFh
		
		MOV A, DONVI
		MOVC A, @A+DPTR
		MOV P0, A
		MOV P2, #07Fh
		CALL DELAY
		MOV P2, #0FFh
		
	SETB TR1 
	
	
	
RET

CHUYENDOIBCDTHAPPHAN: ;ham chuyen doi gia tri BCD sang thap phan
MOV		A, GIAY; dua gia tri giay vao chuan bi chuyen doi
SWAP 	A; swap 2 phan nible thap va cao thanh gi a
ANL 	A, #0FH; che 4 bit cao
MOV 	B, #0AH; gan thanh gi B gia tri 10
MUL 	AB; nhan A voi B
MOV 	R7, A;  dua ket qua vao thanh gi R7
MOV 	A, GIAY; dua gia tri giay vao lan nua
ANL		A, #0FH; che 4 bit cao
ADD		A, R7; cong gia tri A voi R7
MOV GIAY, A; tra ket qua sau chuyen doi vao thanh ghi giay 


; cac lenh benh duoi tuong tu cho Phut va gio
MOV A,PHUT
SWAP A
ANL A,#0FH
MOV B,#0AH
MUL AB
MOV R7,A
MOV A,PHUT
ANL A,#0FH
ADD A,R7
MOV PHUT, A

MOV A,GIO
SWAP A
ANL A,#0FH
MOV B, #0AH
MUL AB
MOV R7, A
MOV A, GIO
ANL A,#0FH
ADD A, R7
MOV GIO, A

RET

CHUYENDOITHAPPHANBCD:
MOV A, PHUT
MOV B,#0AH; jake 0AH = 10D into B
DIV AB
SWAP A
ANL A, #0FH
ADD A, B
MOV PHUT, A

MOV A, GIO
MOV B,#0AH; Jake 0AH = 10D into B *
DIV AB
SWAP A
ANL A, #0F0H
ADD A,B
MOV GIO,A

RET


DS1307_INIT: ; ham khoi tao DS1307
		CALL I2C_START; goi ham I2C start
		MOV A, #0D0H; dia chi DS1307
		LCALL I2C_WRITE ; goi ham I2C write
		MOV A,#00H ;dia chi thanh ghi D
		LCALL I2C_WRITE; goi ham I2C write
		MOV A, #00H ; ENABLE THE oscillator (CH bit = 0) cho phep DS1307 hoat dong
		LCALL I2C_WRITE; goi ham I2C write
		CALL I2C_STOP; goi ham I2C stop
		RET
		
DS1307_WRITE_TIME: ; ham cap nhat thoi gian cho DS1307 cac lenh ben duoi tuong tu o tren
		CALL I2C_START; goi ham I2C start
		MOV A, #0D0H; dia chi DS1307
		CALL I2C_WRITE ; goi ham I2C write
		MOV A,#00H ;dia chi thanh ghi D
		CALL I2C_WRITE; goi ham I2C write
		MOV A, GIAY;
		CALL I2C_WRITE
		MOV A, PHUT;
		CALL I2C_WRITE
		MOV A, GIO;
		CALL I2C_WRITE
		CALL I2C_STOP
		RET
		
DS1307_READ_TIME: ; ham doc thoi gian
		CALL I2C_START; goi ham I2C start
		MOV A,#0D0H ;dia chi DS1307 VA WRITE
		CALL I2C_WRITE ; goi ham I2C write
		MOV A, #00H ;dia chi thanh ghi 0
		CALL I2C_WRITE
		CALL I2C_RESTART; goi ham I2C restart
		MOV A,#001H ; DIA CHI DS1307 VA READ
		CALL I2C_WRITE
		CALL I2C_READ_ACK;  doc du lieu I2C
		MOV GIAY, A;dua ket qua vao giay
		CALL I2C_READ_ACK
		MOV PHUT, A; dua ket qua vao phut
		CALL I2C_READ_NACK
		MOV GIO, A; dua ket qua vao gio
		CALL I2C_STOP
		RET
		
I2C_WRITE: ; ham ghi I2c
		PUSH 07H; luu trang thai hien tai vao 07H
		MOV R7, #8; gan gia tri R vao R7 *
		__LOOP_I2C_WRITE:
		CLR SCL; xoa chan SCL
		RLC A; xoay thanh ghi A
		MOV SDA, C; du bit ra chan SDA
		NOP; dung
		NOP; dung
		SETB SCL; xoa chan SCL
		NOP
		NOP
		DJNZ R7,__LOOP_I2C_WRITE
		CLR SCL
		NOP 
		NOP
		NOP
		NOP
		SETB SDA; CAU HINH NGO VAO SDA DOC ACK
		SETB SCL
		NOP	
		MOV C, SDA	; KIEM TRA CO "C" DE XAC DINH LOI
		NOP
		NOP
		CLR SCL
		POP 07H; lay lai gia tri trang thai hien tai
		RET
		
		
I2C_READ_ACK: ; ham doc I2C co ACK cac lenh ben duoi tuong tu o tren
		PUSH 07H
		MOV R7,#8
		SETB SDA			;CAU HINH NGO VAO SDA
		__LOOP_I2C_READ_ACK:
		SETB SCL
		NOP
		MOV		C,SDA
		RLC		A			;BYTE DOC VE LUU TRONG THANH GHI "A"
		NOP
		CLR SCL
		NOP 
		NOP
		NOP
		DJNZ	R7,__LOOP_I2C_READ_ACK
		CLR SDA
		NOP
		SETB SCL
		NOP
		NOP
		NOP
		NOP
		CLR SCL
		POP 07H
		RET
		
I2C_READ_NACK: ;ham doc I2C co ACK cac lenh tuong tu o tren
		PUSH 07H
		MOV R7, #8
		SETB SDA 		;CAU HINH NGO VAO SDA
		__LOOP_I2C_READ_NACK:
		SETB SCL
		NOP
		MOV C,SDA
		RLC A; BYTE DOC VE LUU TRONG THANH GHI "A"
		NOP
		CLR SCL
		NOP 
		NOP
		NOP
		DJNZ	R7,__LOOP_I2C_READ_NACK
		CLR SDA
		NOP
		SETB SCL
		NOP
		NOP
		NOP
		NOP
		CLR SCL
		POP 07H
		RET
		
I2C_INIT: ; ham khoi tao I2C

		SETB SCL
		SETB SDA
		RET
		
I2C_START: ; ham start I2C
		SETB SDA
		SETB SCL
		NOP 		;DELAY 4.7US
		NOP			;Bus Free Time Between a STOP and START condition
		NOP
		NOP
		NOP
		CLR SDA
		NOP 		;DELAY 4US
		NOP 		;Hold Time(Repcated) START Condition
		NOP
		NOP
		CLR SCL
		RET
I2C_STOP: ;ham stop I2C
		CLR SDA
		SETB SCL
		NOP 	;DELAY 4.7US
		NOP		;Setup Time for STOP Condition
		NOP
		NOP
		NOP
		SETB SDA
		RET
I2C_RESTART: ; ham star I2C
		SETB SDA
		SETB SCL
		NOP 		;DELAY 4.7US
		NOP			;Setup Time for a Repeated START Condition
		NOP
		NOP
		NOP
		CLR SDA
		NOP			;DELAY 4US
		NOP			;Hold Time (Repeated) START Condition
		NOP
		NOP
		CLR SCL
		NOP
		NOP
		RET
		
SCL_HIGH: ;ham dau cham SCL len cao
		NOP 		;DELAY 4US
		NOP			;high Period of SCL Clock
		SETB SCL
		NOP 
		NOP
		RET
SCL_LOW: ; ham dua chan SCL xuong thap
		NOP			;DELAY 4.7US
		NOP 		;LOW Period of SCL Clock
		CLR SCL
		NOP
		NOP
		NOP
		RET
		
DELAY: ; chuong trinh delay
		MOV R5, #10
WAIT2:  MOV R6, #100
				DJNZ R6, $
				DJNZ R5, WAIT2
RET




MALED:  DB  0C0H,0F9H,0A4H,0B0H,099H,092H,082H,0F8H,080H,090H,0BFH
	
END