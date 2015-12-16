; lab2.asm
; Φλώρος-Μαλιβίτσης Ορέστης, 7796
; Αντωνιάδου Αλεξάνδρα, 7853

; Τμήμα 1
; Σκοπός του πρώτου τμήματος της εργαστηριακής άσκησης είναι:
; η αποθήκευση στοιχείων μαθημάτων από κάποιο εξάμηνο και για τα δύο άτομα της ομάδας,
; η εμφάνιση τους με συγκεκριμένο τρόπο στα LEDs
; και ο υπολογισμός του μέσου όρου για το κάθε άτομο.

; Κώδικας και σχολιασμός :

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main
; Αρχικά, αποθηκεύουμε τα ζητούμενα στοιχεία στην flash memory με τον εξής τρόπο:
; Δημιουργούμε έναν 16bit αριθμό.
; Στα bit 15-12 υπάρχει ο αριθμός εξαμήνου σε μορφή BCD.
; Στα bit 11-8 ο κωδικός μαθήματος (αριθμός 1 μεχρι 6 σε δυαδική μορφή).
; Στα 5-0 bit ο βαθμός με ανάλυση μισού βαθμού.
; Στο bit 0 αποθηκεύεται το κλασματικό τμήμα (0 ή 0.5).
; Στα bit 1-4 το ακέραιο τμήμα των μονάδων (σε μορφή BCD).
; Στο bit 5 η τιμή του bit της δεκάδας.

; Τα 2 αυτά bytes μετατρέπονται σε δεκαεξαδικό σύστημα και φορτώνονται στην μνήμη προγράμματος κάτω από τα labels gradesa, grades b που αντιστοιχούν στα 2 άτομα της ομάδας.
gradesa: .dw 0x510F,0x5211,0x5311,0x5410,0x550F,0x5620
gradesb: .dw 0x410A,0x4212,0x430D,0x4412,0x4520,0x4610

main:
.def temp=r25

; Αρχικοποίηση του stack pointer.
SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

; Ορίζουμε το PORTB σαν έξοδο.
ser temp
out DDRB,temp
; Σε αρχική κατάσταση σβήνουμε όλα τα LEDs.
out PORTB, temp

; Φόρτωση στον καταχωρητή Z της διεύθυνσης του gradesa εκεί που βρίσκονται τα στοιχεία των μαθημάτων του πρώτου φοιτητή.
; Φόρτωση στον καταχωρητή Χ μιας διεύθυνσης της SRAM.
ldi ZL, low(2*gradesa)
ldi ZH, high(2*gradesa)
ldi XL, low(0x0060)
ldi XH, high(0x0060)

; Προσδιορίσμος καταχωρητών και μηδενισμός τους.
.def i=r24 ; our counter
.def grade=r19
.def sum=r6 ; our sum
.def decades=r4 ; number of decades
.def studentid=r20 ; current student
clr sum
clr decades
clr i
clr studentid

; Φόρτωση στον r16 του 8 χαμηλότερων bit που βρίσκονται στην διεύθυνση Z και στον r17 των 8 σημαντικότερων.
; Εκεί βρίσκεται η πληροφορία για το 1ο μάθημα του 1ου φοιτητή.
; Το ZL αυξάνεται κατά 1 σε κάθε επανάληψη για να δείχνει στην διεύθυνση που βρίσκεται το επόμενο μάθημα.
read_loop:

lpm r16, Z
adiw ZL, 1
lpm r17, Z
adiw ZL, 1

mov grade,r16 ; Backup grade

rcall combine_leds
rcall flash_leds

; Μέτα την κλήση της ρουτίνας flash_leds
; Παράλληλα με την εμφάνιση της πληροφορίας κάθε μαθήματος υπολογίζουμε στον καταχωρήτη sum το άθροισμα των βαθμών του κάθε φοιτητή.
; Στο bit 0 βρίσκεται η πληροφορία για το δεκαδικό του βαθμού (1 για 0,5 και 0 για ακέραιο βαθμό).
; Στα 4-1 βρίσκεται το ακέραιο τμήμα του βαθμού.
; Το 5ο bit είναι 1 αν ο βαθμός είναι 10, αλλιώς 0.
; Αθροίζουμε μόνο τα bit 4-0 και στο τέλος προσθέτουμε τις αντίστοιχες δεκάδες αν υπήρχαν βαθμοί που είναι ίσοι με 10.

; Aν το bit 5 του grade είναι 1 τότε προσθέτουμε 1 στον καταχωρητή decades (που απαριθμεί βαθμούς που είναι 10)
sbrc grade, 5
inc decades

; Άθροιση μόνο των bits του πραγματικού και δεκαδικού τμήματος.
; Το 0.5 είναι δύναμη του 2 οπότε μπορούμε να το αθροίσουμε κατευθείαν.
andi grade,0b00011111
add sum,grade

; Ο μετρητής αυξάνεται κατά 1 και επαναλαμβάνεται η ρουτίνα read_loop και για τα 6 μαθήματα του κάθε φοιτητή (μέχρι το i να γίνει 6).
inc i
cpi i,6
brlo read_loop

; Ο Καταχωρήτης για το id του κάθε ατόμου της ομάδας αυξάνεται κατά 1.
inc studentid

; Στην συνέχεια, υπολογίζεται το ακριβές άθροισμα.
; Εκτελούμε ολίσθηση μία θέση δεξιά για το ακέραιο μέρος του αθροίσματος.
lsr sum

; Πολλαπλασιάζουμε επί 10 τον απαριθμιτή των δεκάδων.
ldi temp, 10
mul decades,temp
movw decades,r0

; Προσθέτουμε τις δεκάδες και καλούμε την ρουτίνα υπολογισμού του μέσου όρου.
add sum, decades
mov r24, sum
rcall find_average

; Σε περίπτωση που ο μέσος όρος ειναι 10 γίνεται branch στο label remove10 οπού φορτώνεται στον τελίκο προς εμφάνιση αριθμό το 32.
; Δηλαδή, ενεργοποίηση μόνο του bit της δεκάδας.
cpi r24, 10
breq remove10
; Αν ο μέσος όρος δεν είναι 10 γίνεται μια θέση ολίσθηση κατά αριστερά και στο bit 0 μπαίνει το bit που δείχνει το δεκαδικό
lsl r24
or r24,r25
mov temp, studentid
; Το id του κάθε ατόμου θέλουμε να εμφανίζεται τα bit 7-6.
; Για αυτό, γινέται swap του καταχωρητη και ολίσθηση κατα 2 στα αριστέρα
; καθώς η πληροφορία βρισκεται στα 2 λιγότερο σημαντικά bit του 8bit καταχωρητή.
swap temp
lsl temp
lsl temp
or r24, temp
; Αφού γίνει ο τελίκος αριθμός σε συμπλήρωμα του 1 αποθηκευεται στην SRAM.
com r24
st X+, r24

continue:

; Επαναλαμβάνεται η read_loop μέχρι το studentid να γίνει 2
; Δηλαδή, μέχρι να γίνουν οι υπολογισμοί και για τα 2 άτομα της ομάδας.
clr i
clr sum
clr decades
cpi studentid,2
brne read_loop

; Φορτώνεται ο 1ος μέσος όρος από την SRAM.
lds r25, 0x0060
; Καλείται η ρουτίνα εμφάνισης του μέσου όρου.
rcall display_average
ser r18
out PORTB,r18
; Λούπα καθυστέρησης για 2 δευτερόλεπτα
rcall delay2

; Φορτώνεται ο 2ος μέσος όρος από την SRAM.
lds r25, 0x0061
; Καλείται η ρουτίνα εμφάνισης του μέσου όρου.
rcall display_average
ser r18
out PORTB,r18

; Τμήμα 2.
; Στο δεύτερο μέρος της εργαστηριακής άσκησης το πρόγραμμα παραμένει σε έναν βρόχο αναμονής έως ότου πατηθούν και απελευθερωθούν οι διακόπτες:
;    sw0, sw1, sw2, sw3, sw4, sw5.
; Ανάλογα τον διακόπτη θα πρέπει να εμφανιστεί στα LED η πληροφορία για το αντίστοιχο μάθημα του πρώτου εκ των 2 φοιτητών για 5 δευτερόλεπτα.
; Με το πάτημα του sw6 θα γίνει εμφάνιση πληροφοριών για τον δεύτερο φοιτητή του ίδιου μαθήματος.
; Με διαδοχικά πατήματα του sw7 εμφανίζεται στα LED ο μέσος όρος του καθενός με αντίστοιχο τρόπο όπως στο Τμήμα 1.


; Σαν είσοδο των σηματών ελέγχου στους διακόπτες χρησιμοποιούμε το PORTD
ser r18
out PORTB,r18
clr r18
out DDRD,r18
.def whichpressed=r23

; Βρόχος αναμονής.
; Aνάλογα με τον διακόπτη που πατήθηκε ο καταχωρητής whichpressed παίρνει την ανάλογη τιμή.
wait_loop:
in r22,PIND
ldi studentid, 1

sbrs r22,0
ldi whichpressed,0
sbrs r22,1
ldi whichpressed,1
sbrs r22,2
ldi whichpressed,2
sbrs r22,3
ldi whichpressed,3
sbrs r22,4
ldi whichpressed,4
sbrs r22,5
ldi whichpressed,5
; Σε περίπτωση που ο χρήστης πατήσει τον διακόπτη 7 γίνεται jump στο display_average_button
sbrs r22,7
jmp display_average_button
; Συγκρίνουμε την τιμή των bits εισόδου με καταχωρήτη που έχει σε όλα τα bit του την τιμή 1
ser temp
cpse r22, temp
; Αν δεν είναι ίσα σημαίνει ότι κάποιο switch πατήθηκε και καλείται η display_grade_button.
rcall display_grade_button

jmp wait_loop
ret

remove10:
    ldi r24, 32 ; set 5-th bit, all other are cleared
    jmp continue

display_average_button:
; To πρόγραμμα παραμένει στον βρόχο επανάληψης sw7_loop μέχρις ότου απελευθερωθεί ο διακόπτης 7.
sw7_loop:
    in r22,PIND
    sbrs r22,7
    jmp sw7_loop
    ;΄Ελέγχει την τιμή του studentid και αναλόγως φορτώνει τον μέσο όρο από την SRAM.
    ; Ο μέσος όρος του 1ου φοιτητή βρίσκεται στην διεύθυνση 0x0060 και του 2ου στην 0x0061.
    cpi studentid, 2
    breq sw7_isstudent2
    lds r25, 0x0060
    ldi studentid, 2
    jmp continue_to_display
sw7_isstudent2:
    lds r25, 0x0061
    ldi studentid, 1
    ; Εμφάνιση στα LEDs.
continue_to_display:
    out PORTB,r25
    ser temp
wait_next_press7:
    ; Το πρόγραμμα επανέρχεται στο sw7_loop με το πάτημα του 7ου διακόπτη προκειμένου να γίνει η εμφανίση του μέσου όρου του άλλου φοιτητή.
    in r22,PIND
    sbrs r22, 7
    jmp sw7_loop
    ; Το πρόγραμμα παραμένει στον βρόχο επανάληψης wait_next_press7 όσο τα bit των switches παραμένουν απάτητα.
    ; Αν πατηθεί κάποιος διακόπτης εκτός του 7ου τότε το πρόγραμμα επανέρχεται στο wait_loop.
    cpse r22, temp
    jmp wait_loop
    jmp wait_next_press7

display_grade_button:
    ser temp
sw_loop:
    in r22, PIND
    ; Το πρόγραμμα παραμένει στην sw_loop μέχρι όλα τα πλήκτρα να αφεθούν.
    cpse r22, temp
    jmp sw_loop
    ; Ελέγχεται την τιμή του studentid (1 ή 2 για πρώτο ή δεύτερο φοιτητή)
    ; και φορτώνεται ανάλογα στον Z καταχωρητή την διεύθυνση του label που περιέχει τους βαθμους του αντίστοιχου φοιτητή.
    cpi studentid, 2
    breq isstudent2

    ; Δείχνει στην μνήμη τους βαθμούς του 1ου φοιτητή και φορτώνει στον καταχωρητή studentid την τιμή 2 .
    ldi ZL, low(2*gradesa)
    ldi ZH, high(2*gradesa)
    ldi studentid, 2
    jmp continue_to_display_grade
isstudent2:
    ; Δείχνει στην μνήμη τους βαθμούς του 2ου φοιτητή και φορτώνει στον καταχωρητή studeintid την τιμή 1.
    ldi ZL, low(2*gradesb)
    ldi ZH, high(2*gradesb)
    ldi studentid, 1
continue_to_display_grade:
    ; Καλείται η read_data που αθροίζει στον Z καταχωρητή (που δείχνει στους βαθμούς είτε του 1ου είτε του 2ου φοιτητή) το whichpressed
    ; προκειμένου να φορτώσουμε τον βαθμό που υποδείκνυε το πάτημα του διακόπτη από τον χρήστη.
    rcall read_data
    ; Στην συνέχεια εμφανίζεται στα LED η πληροφορία με τον ίδιο τρόπο όπως στο PART1.
    rcall combine_leds
    rcall flash_leds

; Το πρόγραμμα παραμένει στον βρόχο επανάληψης wait_next_press όσο ο χρήστης δεν πατάει κανέναν διακόπτη.
    ser temp
wait_next_press:
    in r22,PIND
    ; Άμα πατήσει τον διακόπτη 6 το πρόγραμμα πάει στο sw_loop για να γίνει η εμφάνιση της πληροφορίας του μαθήματος για τον 2ο φοιτητή.
    sbrs r22, 6
    jmp sw_loop
    ; Αν πατηθεί οποιοσδήποτε άλλος διακόπτης το πρόγραμμα βγαίνει από την συνάρτηση και συνεχίζει από εκεί που διακόπηκε.
    cpse r22, temp
    ret
    jmp wait_next_press


display_average:
    out PORTB,r25
    rcall delay5
    ret

read_data:
    add ZL, whichpressed
    add ZL, whichpressed
    lpm r16, Z
    adiw ZL, 1
    lpm r17, Z
    ret

combine_leds:
    ; Η πληροφορία που θέλουμε να εμφανιστεί στα LEDs είναι στα 7-4 ο κωδικός μαθήματος.
    ; Η πληροφορία αυτή βρίσκεται στα 4 χαμηλότερα bit του r17.
    andi r17,0b00001111
    ; Επισης, στα LEDs 3-0 θέλουμε να εμφανιστεί το ακέραιο μέρος του βαθμού του κάθε μαθήματος.
    ; Η πληροφορία αυτη βρίσκεται στα bit 4-1 του r16 για αυτό κάνουμε μια ολίσθηση προς τα δεξία
    lsr r16
    ; και κρατάμε τα 4 λίγοτερο σημαντικά bits.
    andi r16,0b00001111

    ;Στα 4 περισσότερο σημαντικά bit του r16 θέλουμε τα bit 4 χαμηλότερα του r17
    swap r17
    or r16,r17
    com r16

    ; Το αποτέλεσμα φορτώνεται στο PORTB.
    out PORTB,r16
    ret

flash_leds:
    ; Η πληροφορία θέλουμε να εμφανίζεται για 5 δευτερόλεπτα και έπειτα να αναβοσβήνει στα LEDs με περίοδο 0.5 sec για 4 sec.
    ; Αρχικά, καλούμε την λούπα καθυστέρησης για 5 δευτερόλεπτα.
    rcall delay5
    ser temp

    out PORTB,temp
    ; Καλούμε την λούπα καθυστέρησης για 0.5 δευτερόλεπτα.
    rcall delay05
    ; Ξαναφορτώνουμε την πληροφορία του μαθήματος.
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    ret

; Delay 8 000 000 cycles
; 2s at 4 MHz
delay2:
    push r18
    push r19
    push r20
    ldi  r18, 41
    ldi  r19, 150
    ldi  r20, 128
L1delay2:
    dec  r20
    brne L1delay2
    dec  r19
    brne L1delay2
    dec  r18
    brne L1delay2
    ; restore used registers
    pop r20
    pop r19
    pop r18
    ret

; Delay 20 000 000 cycles
; 5s at 4 MHz
delay5:
    push r18
    push r19
    push r20
    ldi  r18, 102
    ldi  r19, 118
    ldi  r20, 194
L1delay5:
    dec  r20
    brne L1delay5
    dec  r19
    brne L1delay5
    dec  r18
    brne L1delay5
    ; restore used registers
    pop r20
    pop r19
    pop r18
    ret

; Delay 2 000 000 cycles
; 500ms at 4 MHz
delay05:
    push r18
    push r19
    push r20
    ldi  r18, 11
    ldi  r19, 38
    ldi  r20, 94
L1delay05:
    dec  r20
    brne L1delay05
    dec  r19
    brne L1delay05
    dec  r18
    brne L1delay05
    rjmp PC+1
    ; restore used registers
    pop r20
    pop r19
    pop r18
    ret

; Το r24 είναι το όρισμα της συνάρτησης που είναι το ακέραιο μέρος του αθροίσματος.
; Δεν χρειαζόμαστε το δεκαδικό μέρος για να κάνουμε διαίρεση με ακρίβεια 0.5 καθώς δεν επηρεάζει ποτέ το αποτέλεσμα.
; Επιστρέφεται στον r24 το ακέραιο μέρος και αν υπάρχει 0.5 στο δεκαδικό μέρος το r25 παίρνει τιμή 1.
find_average:
    ; Ακέραια διαίρεση με το 6.
    ldi r18,171
    mul r24,r18
    ; Παίρνουμε το most significant byte από το αποτέλεσμα.
    ; (το να πετάμε το least significant byte είναι ισάξιο με διαίρεση με το 256).
    mov r18,r1
    ; και το κάνουμε δύο φορές δεξί shift (διαίρεση με το 4).
    lsr r18
    lsr r18
    ; Τώρα στον r18 έχουμε το ακέραιο μέρος της διαίρεσης.
    ; Συνολικά: r24 * 171 / 4 / 256 που είναι περίπου ίσο με r24 / 6

    ; Υπολογίζουμε το r24 % 6 στον r24.
    ; Αρχίζουμε με το ακέραιο μέρος της διαίρεσης (x div 6) και κάνουμε τις πράξεις:
    mov r25,r18
    lsl r25
    add r25,r18
    lsl r25
    ; Το αποτέλεσμα είναι:
    ; r25 = 2*(2*(x div 6) + (x div 6)) = 6 * (x div 6)
    sub r24,r25
    ; x - 6 * (x div 6) = x mod 6
    ; Το r24 είναι τώρα sum % 6
    cpi r24,2
    brlo round_down
    cpi r24,5
    brlo round_half
    ; Αν το mod είναι μεγαλύτερο από 5 στρογγυλοποιούμε προς τα πάνω.
    subi r18,-1
    ldi r25,0
    mov r24,r18
    ret
round_down:
    ; Αν το mod είναι μικρότερο από 2 στρογγυλοποιούμε προς τα κάτω.
    ldi r25,0
    mov r24,r18
    ret
round_half:
    ; Αν το mod είναι μικρότερο από 5 στρογγυλοποιούμε στο μισό.
    ldi r25,1
    mov r24,r18
    ret

; --------------------------------------------------------------------
;
; Breakpoints:
;
; Breakpoints εισήχθησαν στα εξής σημεία :
; 1. Για να ελέγξουμε την σωστή αρχικοποίηση του PORTB
; και στην συνέχεια εκτελώντας μια-μια τις εντολές στις συναρτήσεις combine_leds, flash_leds βλέπουμε την σωστή ένδειξη των ΑΕΜ στα αντίστοιχα LEDs.
; (Χρησιμοποιήσαμε ένα ψευδοdelay για να περάσει την εντολη delay σε ένα κύκλο)
; 2. Στο read_loop ελέγχαμε την τιμή του sum και την τιμή του καταχωρητή decades και για τις 6 επαναλήψεις (και για τα 6 μαθήματα)
; 3. Στην αρχή του δεύτερου μέρους της άσκησης για να εκτελέσουμε μια-μια τις εντολές αρχικά χωρίς να πατάμε κανένα switch για να ελέγξουμε ότι γίνεται σωστά η επαναληπτική διαδικασία.
; Στην συνέχεια, με την επιλογή ενός εκ των 5 switch ελέγχουμε αν το πρόγραμμα πάει στην σωστή ρουτίνα (ανάλογα το switch).
; 4.Στο display_average_button και εντολή-εντολή τρέξαμε το πρόγραμμα για να δούμε αν με τα διαδοχικά πατήματα του sw7 εμφανίζοντα αντίστοιχα οι μέσοι όροι των φοιτητών στα LED.
