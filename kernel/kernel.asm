
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b2013103          	ld	sp,-1248(sp) # 80008b20 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	b3070713          	addi	a4,a4,-1232 # 80008b80 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	fee78793          	addi	a5,a5,-18 # 80006050 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc00f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	656080e7          	jalr	1622(ra) # 80002780 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	b3650513          	addi	a0,a0,-1226 # 80010cc0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b2648493          	addi	s1,s1,-1242 # 80010cc0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bb690913          	addi	s2,s2,-1098 # 80010d58 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	88a080e7          	jalr	-1910(ra) # 80001a4a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	402080e7          	jalr	1026(ra) # 800025ca <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	14c080e7          	jalr	332(ra) # 80002322 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	518080e7          	jalr	1304(ra) # 8000272a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	a9a50513          	addi	a0,a0,-1382 # 80010cc0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a8450513          	addi	a0,a0,-1404 # 80010cc0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	aef72323          	sw	a5,-1306(a4) # 80010d58 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	9f450513          	addi	a0,a0,-1548 # 80010cc0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	4e4080e7          	jalr	1252(ra) # 800027d6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	9c650513          	addi	a0,a0,-1594 # 80010cc0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9a270713          	addi	a4,a4,-1630 # 80010cc0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	97878793          	addi	a5,a5,-1672 # 80010cc0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9e27a783          	lw	a5,-1566(a5) # 80010d58 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	93670713          	addi	a4,a4,-1738 # 80010cc0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	92648493          	addi	s1,s1,-1754 # 80010cc0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	8ea70713          	addi	a4,a4,-1814 # 80010cc0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	96f72a23          	sw	a5,-1676(a4) # 80010d60 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8ae78793          	addi	a5,a5,-1874 # 80010cc0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	92c7a323          	sw	a2,-1754(a5) # 80010d5c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	91a50513          	addi	a0,a0,-1766 # 80010d58 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f40080e7          	jalr	-192(ra) # 80002386 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	86050513          	addi	a0,a0,-1952 # 80010cc0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	1e078793          	addi	a5,a5,480 # 80021658 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8207aa23          	sw	zero,-1996(a5) # 80010d80 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	5cf72023          	sw	a5,1472(a4) # 80008b40 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	7c4dad83          	lw	s11,1988(s11) # 80010d80 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	76e50513          	addi	a0,a0,1902 # 80010d68 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	61050513          	addi	a0,a0,1552 # 80010d68 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	5f448493          	addi	s1,s1,1524 # 80010d68 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	5b450513          	addi	a0,a0,1460 # 80010d88 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3407a783          	lw	a5,832(a5) # 80008b40 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3107b783          	ld	a5,784(a5) # 80008b48 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	31073703          	ld	a4,784(a4) # 80008b50 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	526a0a13          	addi	s4,s4,1318 # 80010d88 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	2de48493          	addi	s1,s1,734 # 80008b48 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	2de98993          	addi	s3,s3,734 # 80008b50 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	af2080e7          	jalr	-1294(ra) # 80002386 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	4b850513          	addi	a0,a0,1208 # 80010d88 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2607a783          	lw	a5,608(a5) # 80008b40 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	26673703          	ld	a4,614(a4) # 80008b50 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2567b783          	ld	a5,598(a5) # 80008b48 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	48a98993          	addi	s3,s3,1162 # 80010d88 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	24248493          	addi	s1,s1,578 # 80008b48 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	24290913          	addi	s2,s2,578 # 80008b50 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a04080e7          	jalr	-1532(ra) # 80002322 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	45448493          	addi	s1,s1,1108 # 80010d88 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	20e7b423          	sd	a4,520(a5) # 80008b50 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	3ce48493          	addi	s1,s1,974 # 80010d88 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	df478793          	addi	a5,a5,-524 # 800227f0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	3a490913          	addi	s2,s2,932 # 80010dc0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	30650513          	addi	a0,a0,774 # 80010dc0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	d2250513          	addi	a0,a0,-734 # 800227f0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	2d048493          	addi	s1,s1,720 # 80010dc0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	2b850513          	addi	a0,a0,696 # 80010dc0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	28c50513          	addi	a0,a0,652 # 80010dc0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	ebe080e7          	jalr	-322(ra) # 80001a2e <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e8c080e7          	jalr	-372(ra) # 80001a2e <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e80080e7          	jalr	-384(ra) # 80001a2e <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e68080e7          	jalr	-408(ra) # 80001a2e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	e28080e7          	jalr	-472(ra) # 80001a2e <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dfc080e7          	jalr	-516(ra) # 80001a2e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc811>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b9e080e7          	jalr	-1122(ra) # 80001a1e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	cd070713          	addi	a4,a4,-816 # 80008b58 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b82080e7          	jalr	-1150(ra) # 80001a1e <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	ab8080e7          	jalr	-1352(ra) # 80002976 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	1ca080e7          	jalr	458(ra) # 80006090 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	302080e7          	jalr	770(ra) # 800021d0 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	a3c080e7          	jalr	-1476(ra) # 8000196a <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a18080e7          	jalr	-1512(ra) # 8000294e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a38080e7          	jalr	-1480(ra) # 80002976 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	134080e7          	jalr	308(ra) # 8000607a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	142080e7          	jalr	322(ra) # 80006090 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2da080e7          	jalr	730(ra) # 80003230 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	97a080e7          	jalr	-1670(ra) # 800038d8 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	920080e7          	jalr	-1760(ra) # 80004886 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	22a080e7          	jalr	554(ra) # 80006198 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	dd2080e7          	jalr	-558(ra) # 80001d48 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	bcf72a23          	sw	a5,-1068(a4) # 80008b58 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	bc87b783          	ld	a5,-1080(a5) # 80008b60 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc807>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	6a6080e7          	jalr	1702(ra) # 800018d4 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	90a7b623          	sd	a0,-1780(a5) # 80008b60 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc810>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <random>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
uint64
random(void)
{
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
  // Take from http://stackoverflow.com/questions/1167253/implementation-of-rand
  static unsigned int z1 = 12345, z2 = 12345, z3 = 12345, z4 = 12345;
  unsigned int b;
  b = ((z1 << 6) ^ z1) >> 13;
    8000183c:	00007697          	auipc	a3,0x7
    80001840:	11468693          	addi	a3,a3,276 # 80008950 <z1.5>
    80001844:	429c                	lw	a5,0(a3)
    80001846:	0067971b          	slliw	a4,a5,0x6
    8000184a:	8f3d                	xor	a4,a4,a5
    8000184c:	00d7571b          	srliw	a4,a4,0xd
  z1 = ((z1 & 4294967294U) << 18) ^ b;
    80001850:	0127951b          	slliw	a0,a5,0x12
    80001854:	fff807b7          	lui	a5,0xfff80
    80001858:	8d7d                	and	a0,a0,a5
    8000185a:	8d39                	xor	a0,a0,a4
    8000185c:	2501                	sext.w	a0,a0
    8000185e:	c288                	sw	a0,0(a3)
  b = ((z2 << 2) ^ z2) >> 27;
    80001860:	00007717          	auipc	a4,0x7
    80001864:	0ec70713          	addi	a4,a4,236 # 8000894c <z2.4>
    80001868:	431c                	lw	a5,0(a4)
    8000186a:	0027969b          	slliw	a3,a5,0x2
    8000186e:	8fb5                	xor	a5,a5,a3
    80001870:	01b7d79b          	srliw	a5,a5,0x1b
  z2 = ((z2 & 4294967288U) << 2) ^ b;
    80001874:	9a81                	andi	a3,a3,-32
    80001876:	8ebd                	xor	a3,a3,a5
    80001878:	2681                	sext.w	a3,a3
    8000187a:	c314                	sw	a3,0(a4)
  b = ((z3 << 13) ^ z3) >> 21;
    8000187c:	00007597          	auipc	a1,0x7
    80001880:	0cc58593          	addi	a1,a1,204 # 80008948 <z3.3>
    80001884:	419c                	lw	a5,0(a1)
    80001886:	00d7961b          	slliw	a2,a5,0xd
    8000188a:	8e3d                	xor	a2,a2,a5
    8000188c:	0156561b          	srliw	a2,a2,0x15
  z3 = ((z3 & 4294967280U) << 7) ^ b;
    80001890:	0077971b          	slliw	a4,a5,0x7
    80001894:	80077713          	andi	a4,a4,-2048
    80001898:	8f31                	xor	a4,a4,a2
    8000189a:	2701                	sext.w	a4,a4
    8000189c:	c198                	sw	a4,0(a1)
  b = ((z4 << 3) ^ z4) >> 12;
    8000189e:	00007597          	auipc	a1,0x7
    800018a2:	0a658593          	addi	a1,a1,166 # 80008944 <z4.2>
    800018a6:	419c                	lw	a5,0(a1)
    800018a8:	0037961b          	slliw	a2,a5,0x3
    800018ac:	8e3d                	xor	a2,a2,a5
    800018ae:	00c6561b          	srliw	a2,a2,0xc
  z4 = ((z4 & 4294967168U) << 13) ^ b;
    800018b2:	00d7979b          	slliw	a5,a5,0xd
    800018b6:	fff00837          	lui	a6,0xfff00
    800018ba:	0107f7b3          	and	a5,a5,a6
    800018be:	8fb1                	xor	a5,a5,a2
    800018c0:	2781                	sext.w	a5,a5
    800018c2:	c19c                	sw	a5,0(a1)

  return (z1 ^ z2 ^ z3 ^ z4) / 2;
    800018c4:	8d35                	xor	a0,a0,a3
    800018c6:	8d39                	xor	a0,a0,a4
    800018c8:	8d3d                	xor	a0,a0,a5
}
    800018ca:	0015551b          	srliw	a0,a0,0x1
    800018ce:	6422                	ld	s0,8(sp)
    800018d0:	0141                	addi	sp,sp,16
    800018d2:	8082                	ret

00000000800018d4 <proc_mapstacks>:

void proc_mapstacks(pagetable_t kpgtbl)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
    800018e8:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018ea:	00010497          	auipc	s1,0x10
    800018ee:	92648493          	addi	s1,s1,-1754 # 80011210 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018f2:	8b26                	mv	s6,s1
    800018f4:	00006a97          	auipc	s5,0x6
    800018f8:	70ca8a93          	addi	s5,s5,1804 # 80008000 <etext>
    800018fc:	04000937          	lui	s2,0x4000
    80001900:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001902:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001904:	00016a17          	auipc	s4,0x16
    80001908:	b0ca0a13          	addi	s4,s4,-1268 # 80017410 <tickslock>
    char *pa = kalloc();
    8000190c:	fffff097          	auipc	ra,0xfffff
    80001910:	1da080e7          	jalr	474(ra) # 80000ae6 <kalloc>
    80001914:	862a                	mv	a2,a0
    if (pa == 0)
    80001916:	c131                	beqz	a0,8000195a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001918:	416485b3          	sub	a1,s1,s6
    8000191c:	858d                	srai	a1,a1,0x3
    8000191e:	000ab783          	ld	a5,0(s5)
    80001922:	02f585b3          	mul	a1,a1,a5
    80001926:	2585                	addiw	a1,a1,1
    80001928:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000192c:	4719                	li	a4,6
    8000192e:	6685                	lui	a3,0x1
    80001930:	40b905b3          	sub	a1,s2,a1
    80001934:	854e                	mv	a0,s3
    80001936:	00000097          	auipc	ra,0x0
    8000193a:	808080e7          	jalr	-2040(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000193e:	18848493          	addi	s1,s1,392
    80001942:	fd4495e3          	bne	s1,s4,8000190c <proc_mapstacks+0x38>
  }
}
    80001946:	70e2                	ld	ra,56(sp)
    80001948:	7442                	ld	s0,48(sp)
    8000194a:	74a2                	ld	s1,40(sp)
    8000194c:	7902                	ld	s2,32(sp)
    8000194e:	69e2                	ld	s3,24(sp)
    80001950:	6a42                	ld	s4,16(sp)
    80001952:	6aa2                	ld	s5,8(sp)
    80001954:	6b02                	ld	s6,0(sp)
    80001956:	6121                	addi	sp,sp,64
    80001958:	8082                	ret
      panic("kalloc");
    8000195a:	00007517          	auipc	a0,0x7
    8000195e:	87e50513          	addi	a0,a0,-1922 # 800081d8 <digits+0x198>
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	bde080e7          	jalr	-1058(ra) # 80000540 <panic>

000000008000196a <procinit>:

// initialize the proc table.
void procinit(void)
{
    8000196a:	7139                	addi	sp,sp,-64
    8000196c:	fc06                	sd	ra,56(sp)
    8000196e:	f822                	sd	s0,48(sp)
    80001970:	f426                	sd	s1,40(sp)
    80001972:	f04a                	sd	s2,32(sp)
    80001974:	ec4e                	sd	s3,24(sp)
    80001976:	e852                	sd	s4,16(sp)
    80001978:	e456                	sd	s5,8(sp)
    8000197a:	e05a                	sd	s6,0(sp)
    8000197c:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000197e:	00007597          	auipc	a1,0x7
    80001982:	86258593          	addi	a1,a1,-1950 # 800081e0 <digits+0x1a0>
    80001986:	0000f517          	auipc	a0,0xf
    8000198a:	45a50513          	addi	a0,a0,1114 # 80010de0 <pid_lock>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	1b8080e7          	jalr	440(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001996:	00007597          	auipc	a1,0x7
    8000199a:	85258593          	addi	a1,a1,-1966 # 800081e8 <digits+0x1a8>
    8000199e:	0000f517          	auipc	a0,0xf
    800019a2:	45a50513          	addi	a0,a0,1114 # 80010df8 <wait_lock>
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	1a0080e7          	jalr	416(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019ae:	00010497          	auipc	s1,0x10
    800019b2:	86248493          	addi	s1,s1,-1950 # 80011210 <proc>
  {
    initlock(&p->lock, "proc");
    800019b6:	00007b17          	auipc	s6,0x7
    800019ba:	842b0b13          	addi	s6,s6,-1982 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019be:	8aa6                	mv	s5,s1
    800019c0:	00006a17          	auipc	s4,0x6
    800019c4:	640a0a13          	addi	s4,s4,1600 # 80008000 <etext>
    800019c8:	04000937          	lui	s2,0x4000
    800019cc:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019ce:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019d0:	00016997          	auipc	s3,0x16
    800019d4:	a4098993          	addi	s3,s3,-1472 # 80017410 <tickslock>
    initlock(&p->lock, "proc");
    800019d8:	85da                	mv	a1,s6
    800019da:	8526                	mv	a0,s1
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	16a080e7          	jalr	362(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    800019e4:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019e8:	415487b3          	sub	a5,s1,s5
    800019ec:	878d                	srai	a5,a5,0x3
    800019ee:	000a3703          	ld	a4,0(s4)
    800019f2:	02e787b3          	mul	a5,a5,a4
    800019f6:	2785                	addiw	a5,a5,1 # fffffffffff80001 <end+0xffffffff7ff5d811>
    800019f8:	00d7979b          	slliw	a5,a5,0xd
    800019fc:	40f907b3          	sub	a5,s2,a5
    80001a00:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a02:	18848493          	addi	s1,s1,392
    80001a06:	fd3499e3          	bne	s1,s3,800019d8 <procinit+0x6e>
  }
}
    80001a0a:	70e2                	ld	ra,56(sp)
    80001a0c:	7442                	ld	s0,48(sp)
    80001a0e:	74a2                	ld	s1,40(sp)
    80001a10:	7902                	ld	s2,32(sp)
    80001a12:	69e2                	ld	s3,24(sp)
    80001a14:	6a42                	ld	s4,16(sp)
    80001a16:	6aa2                	ld	s5,8(sp)
    80001a18:	6b02                	ld	s6,0(sp)
    80001a1a:	6121                	addi	sp,sp,64
    80001a1c:	8082                	ret

0000000080001a1e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a24:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a26:	2501                	sext.w	a0,a0
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e422                	sd	s0,8(sp)
    80001a32:	0800                	addi	s0,sp,16
    80001a34:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a36:	2781                	sext.w	a5,a5
    80001a38:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a3a:	0000f517          	auipc	a0,0xf
    80001a3e:	3d650513          	addi	a0,a0,982 # 80010e10 <cpus>
    80001a42:	953e                	add	a0,a0,a5
    80001a44:	6422                	ld	s0,8(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	1000                	addi	s0,sp,32
  push_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	136080e7          	jalr	310(ra) # 80000b8a <push_off>
    80001a5c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	079e                	slli	a5,a5,0x7
    80001a62:	0000f717          	auipc	a4,0xf
    80001a66:	37e70713          	addi	a4,a4,894 # 80010de0 <pid_lock>
    80001a6a:	97ba                	add	a5,a5,a4
    80001a6c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	1bc080e7          	jalr	444(ra) # 80000c2a <pop_off>
  return p;
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6105                	addi	sp,sp,32
    80001a80:	8082                	ret

0000000080001a82 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a82:	1141                	addi	sp,sp,-16
    80001a84:	e406                	sd	ra,8(sp)
    80001a86:	e022                	sd	s0,0(sp)
    80001a88:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	fc0080e7          	jalr	-64(ra) # 80001a4a <myproc>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	1f8080e7          	jalr	504(ra) # 80000c8a <release>

  if (first)
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	ea67a783          	lw	a5,-346(a5) # 80008940 <first.1>
    80001aa2:	eb89                	bnez	a5,80001ab4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aa4:	00001097          	auipc	ra,0x1
    80001aa8:	eea080e7          	jalr	-278(ra) # 8000298e <usertrapret>
}
    80001aac:	60a2                	ld	ra,8(sp)
    80001aae:	6402                	ld	s0,0(sp)
    80001ab0:	0141                	addi	sp,sp,16
    80001ab2:	8082                	ret
    first = 0;
    80001ab4:	00007797          	auipc	a5,0x7
    80001ab8:	e807a623          	sw	zero,-372(a5) # 80008940 <first.1>
    fsinit(ROOTDEV);
    80001abc:	4505                	li	a0,1
    80001abe:	00002097          	auipc	ra,0x2
    80001ac2:	d9a080e7          	jalr	-614(ra) # 80003858 <fsinit>
    80001ac6:	bff9                	j	80001aa4 <forkret+0x22>

0000000080001ac8 <allocpid>:
{
    80001ac8:	1101                	addi	sp,sp,-32
    80001aca:	ec06                	sd	ra,24(sp)
    80001acc:	e822                	sd	s0,16(sp)
    80001ace:	e426                	sd	s1,8(sp)
    80001ad0:	e04a                	sd	s2,0(sp)
    80001ad2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad4:	0000f917          	auipc	s2,0xf
    80001ad8:	30c90913          	addi	s2,s2,780 # 80010de0 <pid_lock>
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	0f8080e7          	jalr	248(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001ae6:	00007797          	auipc	a5,0x7
    80001aea:	e6e78793          	addi	a5,a5,-402 # 80008954 <nextpid>
    80001aee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af0:	0014871b          	addiw	a4,s1,1
    80001af4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	192080e7          	jalr	402(ra) # 80000c8a <release>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6902                	ld	s2,0(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret

0000000080001b0e <proc_pagetable>:
{
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
    80001b1a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	80c080e7          	jalr	-2036(ra) # 80001328 <uvmcreate>
    80001b24:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b26:	c121                	beqz	a0,80001b66 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b28:	4729                	li	a4,10
    80001b2a:	00005697          	auipc	a3,0x5
    80001b2e:	4d668693          	addi	a3,a3,1238 # 80007000 <_trampoline>
    80001b32:	6605                	lui	a2,0x1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	562080e7          	jalr	1378(ra) # 8000109e <mappages>
    80001b44:	02054863          	bltz	a0,80001b74 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b48:	4719                	li	a4,6
    80001b4a:	06093683          	ld	a3,96(s2)
    80001b4e:	6605                	lui	a2,0x1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	544080e7          	jalr	1348(ra) # 8000109e <mappages>
    80001b62:	02054163          	bltz	a0,80001b84 <proc_pagetable+0x76>
}
    80001b66:	8526                	mv	a0,s1
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	9b6080e7          	jalr	-1610(ra) # 8000152e <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	b7d5                	j	80001b66 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b84:	4681                	li	a3,0
    80001b86:	4605                	li	a2,1
    80001b88:	040005b7          	lui	a1,0x4000
    80001b8c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b8e:	05b2                	slli	a1,a1,0xc
    80001b90:	8526                	mv	a0,s1
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	6d2080e7          	jalr	1746(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b9a:	4581                	li	a1,0
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	990080e7          	jalr	-1648(ra) # 8000152e <uvmfree>
    return 0;
    80001ba6:	4481                	li	s1,0
    80001ba8:	bf7d                	j	80001b66 <proc_pagetable+0x58>

0000000080001baa <proc_freepagetable>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	e04a                	sd	s2,0(sp)
    80001bb4:	1000                	addi	s0,sp,32
    80001bb6:	84aa                	mv	s1,a0
    80001bb8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bba:	4681                	li	a3,0
    80001bbc:	4605                	li	a2,1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	69e080e7          	jalr	1694(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bce:	4681                	li	a3,0
    80001bd0:	4605                	li	a2,1
    80001bd2:	020005b7          	lui	a1,0x2000
    80001bd6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd8:	05b6                	slli	a1,a1,0xd
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	688080e7          	jalr	1672(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001be4:	85ca                	mv	a1,s2
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	946080e7          	jalr	-1722(ra) # 8000152e <uvmfree>
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6902                	ld	s2,0(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <freeproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c08:	7128                	ld	a0,96(a0)
    80001c0a:	c509                	beqz	a0,80001c14 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	ddc080e7          	jalr	-548(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001c14:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001c18:	6ca8                	ld	a0,88(s1)
    80001c1a:	c511                	beqz	a0,80001c26 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c1c:	64ac                	ld	a1,72(s1)
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	f8c080e7          	jalr	-116(ra) # 80001baa <proc_freepagetable>
  p->pagetable = 0;
    80001c26:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c2a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c2e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c32:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c36:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c3a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c3e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c42:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c46:	0004ac23          	sw	zero,24(s1)
  p->strace_bit = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->birth_time = __INT_MAX__;
    80001c4e:	800007b7          	lui	a5,0x80000
    80001c52:	fff7c793          	not	a5,a5
    80001c56:	16f4bc23          	sd	a5,376(s1)
  p->num_tickets = 0;
    80001c5a:	1804b023          	sd	zero,384(s1)
}
    80001c5e:	60e2                	ld	ra,24(sp)
    80001c60:	6442                	ld	s0,16(sp)
    80001c62:	64a2                	ld	s1,8(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret

0000000080001c68 <allocproc>:
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	e04a                	sd	s2,0(sp)
    80001c72:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c74:	0000f497          	auipc	s1,0xf
    80001c78:	59c48493          	addi	s1,s1,1436 # 80011210 <proc>
    80001c7c:	00015917          	auipc	s2,0x15
    80001c80:	79490913          	addi	s2,s2,1940 # 80017410 <tickslock>
    acquire(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	f50080e7          	jalr	-176(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001c8e:	4c9c                	lw	a5,24(s1)
    80001c90:	cf81                	beqz	a5,80001ca8 <allocproc+0x40>
      release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	ff6080e7          	jalr	-10(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c9c:	18848493          	addi	s1,s1,392
    80001ca0:	ff2492e3          	bne	s1,s2,80001c84 <allocproc+0x1c>
  return 0;
    80001ca4:	4481                	li	s1,0
    80001ca6:	a095                	j	80001d0a <allocproc+0xa2>
  p->pid = allocpid();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	e20080e7          	jalr	-480(ra) # 80001ac8 <allocpid>
    80001cb0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cb2:	4785                	li	a5,1
    80001cb4:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	e30080e7          	jalr	-464(ra) # 80000ae6 <kalloc>
    80001cbe:	892a                	mv	s2,a0
    80001cc0:	f0a8                	sd	a0,96(s1)
    80001cc2:	c939                	beqz	a0,80001d18 <allocproc+0xb0>
  p->pagetable = proc_pagetable(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	e48080e7          	jalr	-440(ra) # 80001b0e <proc_pagetable>
    80001cce:	892a                	mv	s2,a0
    80001cd0:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001cd2:	cd39                	beqz	a0,80001d30 <allocproc+0xc8>
  memset(&p->context, 0, sizeof(p->context));
    80001cd4:	07000613          	li	a2,112
    80001cd8:	4581                	li	a1,0
    80001cda:	06848513          	addi	a0,s1,104
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	ff4080e7          	jalr	-12(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001ce6:	00000797          	auipc	a5,0x0
    80001cea:	d9c78793          	addi	a5,a5,-612 # 80001a82 <forkret>
    80001cee:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cf0:	60bc                	ld	a5,64(s1)
    80001cf2:	6705                	lui	a4,0x1
    80001cf4:	97ba                	add	a5,a5,a4
    80001cf6:	f8bc                	sd	a5,112(s1)
  p->birth_time = sys_uptime(); // sys_uptime - gives number of ticks since start
    80001cf8:	00001097          	auipc	ra,0x1
    80001cfc:	490080e7          	jalr	1168(ra) # 80003188 <sys_uptime>
    80001d00:	16a4bc23          	sd	a0,376(s1)
  p->num_tickets = 1;           // # tickets = 1 by default for every process
    80001d04:	4785                	li	a5,1
    80001d06:	18f4b023          	sd	a5,384(s1)
}
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6902                	ld	s2,0(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret
    freeproc(p);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	ee2080e7          	jalr	-286(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	f66080e7          	jalr	-154(ra) # 80000c8a <release>
    return 0;
    80001d2c:	84ca                	mv	s1,s2
    80001d2e:	bff1                	j	80001d0a <allocproc+0xa2>
    freeproc(p);
    80001d30:	8526                	mv	a0,s1
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	eca080e7          	jalr	-310(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f4e080e7          	jalr	-178(ra) # 80000c8a <release>
    return 0;
    80001d44:	84ca                	mv	s1,s2
    80001d46:	b7d1                	j	80001d0a <allocproc+0xa2>

0000000080001d48 <userinit>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	f16080e7          	jalr	-234(ra) # 80001c68 <allocproc>
    80001d5a:	84aa                	mv	s1,a0
  initproc = p;
    80001d5c:	00007797          	auipc	a5,0x7
    80001d60:	e0a7b623          	sd	a0,-500(a5) # 80008b68 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d64:	03400613          	li	a2,52
    80001d68:	00007597          	auipc	a1,0x7
    80001d6c:	bf858593          	addi	a1,a1,-1032 # 80008960 <initcode>
    80001d70:	6d28                	ld	a0,88(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	5e4080e7          	jalr	1508(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d7a:	6785                	lui	a5,0x1
    80001d7c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d7e:	70b8                	ld	a4,96(s1)
    80001d80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d84:	70b8                	ld	a4,96(s1)
    80001d86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d88:	4641                	li	a2,16
    80001d8a:	00006597          	auipc	a1,0x6
    80001d8e:	47658593          	addi	a1,a1,1142 # 80008200 <digits+0x1c0>
    80001d92:	16048513          	addi	a0,s1,352
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	086080e7          	jalr	134(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d9e:	00006517          	auipc	a0,0x6
    80001da2:	47250513          	addi	a0,a0,1138 # 80008210 <digits+0x1d0>
    80001da6:	00002097          	auipc	ra,0x2
    80001daa:	4dc080e7          	jalr	1244(ra) # 80004282 <namei>
    80001dae:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001db2:	478d                	li	a5,3
    80001db4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	ed2080e7          	jalr	-302(ra) # 80000c8a <release>
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret

0000000080001dca <growproc>:
{
    80001dca:	1101                	addi	sp,sp,-32
    80001dcc:	ec06                	sd	ra,24(sp)
    80001dce:	e822                	sd	s0,16(sp)
    80001dd0:	e426                	sd	s1,8(sp)
    80001dd2:	e04a                	sd	s2,0(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	c72080e7          	jalr	-910(ra) # 80001a4a <myproc>
    80001de0:	84aa                	mv	s1,a0
  sz = p->sz;
    80001de2:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001de4:	01204c63          	bgtz	s2,80001dfc <growproc+0x32>
  else if (n < 0)
    80001de8:	02094663          	bltz	s2,80001e14 <growproc+0x4a>
  p->sz = sz;
    80001dec:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dee:	4501                	li	a0,0
}
    80001df0:	60e2                	ld	ra,24(sp)
    80001df2:	6442                	ld	s0,16(sp)
    80001df4:	64a2                	ld	s1,8(sp)
    80001df6:	6902                	ld	s2,0(sp)
    80001df8:	6105                	addi	sp,sp,32
    80001dfa:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001dfc:	4691                	li	a3,4
    80001dfe:	00b90633          	add	a2,s2,a1
    80001e02:	6d28                	ld	a0,88(a0)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	60c080e7          	jalr	1548(ra) # 80001410 <uvmalloc>
    80001e0c:	85aa                	mv	a1,a0
    80001e0e:	fd79                	bnez	a0,80001dec <growproc+0x22>
      return -1;
    80001e10:	557d                	li	a0,-1
    80001e12:	bff9                	j	80001df0 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e14:	00b90633          	add	a2,s2,a1
    80001e18:	6d28                	ld	a0,88(a0)
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	5ae080e7          	jalr	1454(ra) # 800013c8 <uvmdealloc>
    80001e22:	85aa                	mv	a1,a0
    80001e24:	b7e1                	j	80001dec <growproc+0x22>

0000000080001e26 <fork>:
{
    80001e26:	7139                	addi	sp,sp,-64
    80001e28:	fc06                	sd	ra,56(sp)
    80001e2a:	f822                	sd	s0,48(sp)
    80001e2c:	f426                	sd	s1,40(sp)
    80001e2e:	f04a                	sd	s2,32(sp)
    80001e30:	ec4e                	sd	s3,24(sp)
    80001e32:	e852                	sd	s4,16(sp)
    80001e34:	e456                	sd	s5,8(sp)
    80001e36:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	c12080e7          	jalr	-1006(ra) # 80001a4a <myproc>
    80001e40:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	e26080e7          	jalr	-474(ra) # 80001c68 <allocproc>
    80001e4a:	12050463          	beqz	a0,80001f72 <fork+0x14c>
    80001e4e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e50:	048ab603          	ld	a2,72(s5)
    80001e54:	6d2c                	ld	a1,88(a0)
    80001e56:	058ab503          	ld	a0,88(s5)
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	70e080e7          	jalr	1806(ra) # 80001568 <uvmcopy>
    80001e62:	04054863          	bltz	a0,80001eb2 <fork+0x8c>
  np->sz = p->sz;
    80001e66:	048ab783          	ld	a5,72(s5)
    80001e6a:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e6e:	060ab683          	ld	a3,96(s5)
    80001e72:	87b6                	mv	a5,a3
    80001e74:	0609b703          	ld	a4,96(s3)
    80001e78:	12068693          	addi	a3,a3,288
    80001e7c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e80:	6788                	ld	a0,8(a5)
    80001e82:	6b8c                	ld	a1,16(a5)
    80001e84:	6f90                	ld	a2,24(a5)
    80001e86:	01073023          	sd	a6,0(a4)
    80001e8a:	e708                	sd	a0,8(a4)
    80001e8c:	eb0c                	sd	a1,16(a4)
    80001e8e:	ef10                	sd	a2,24(a4)
    80001e90:	02078793          	addi	a5,a5,32
    80001e94:	02070713          	addi	a4,a4,32
    80001e98:	fed792e3          	bne	a5,a3,80001e7c <fork+0x56>
  np->trapframe->a0 = 0;
    80001e9c:	0609b783          	ld	a5,96(s3)
    80001ea0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001ea4:	0d8a8493          	addi	s1,s5,216
    80001ea8:	0d898913          	addi	s2,s3,216
    80001eac:	158a8a13          	addi	s4,s5,344
    80001eb0:	a00d                	j	80001ed2 <fork+0xac>
    freeproc(np);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	d48080e7          	jalr	-696(ra) # 80001bfc <freeproc>
    release(&np->lock);
    80001ebc:	854e                	mv	a0,s3
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	dcc080e7          	jalr	-564(ra) # 80000c8a <release>
    return -1;
    80001ec6:	597d                	li	s2,-1
    80001ec8:	a859                	j	80001f5e <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    80001eca:	04a1                	addi	s1,s1,8
    80001ecc:	0921                	addi	s2,s2,8
    80001ece:	01448b63          	beq	s1,s4,80001ee4 <fork+0xbe>
    if (p->ofile[i])
    80001ed2:	6088                	ld	a0,0(s1)
    80001ed4:	d97d                	beqz	a0,80001eca <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed6:	00003097          	auipc	ra,0x3
    80001eda:	a42080e7          	jalr	-1470(ra) # 80004918 <filedup>
    80001ede:	00a93023          	sd	a0,0(s2)
    80001ee2:	b7e5                	j	80001eca <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ee4:	158ab503          	ld	a0,344(s5)
    80001ee8:	00002097          	auipc	ra,0x2
    80001eec:	bb0080e7          	jalr	-1104(ra) # 80003a98 <idup>
    80001ef0:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef4:	4641                	li	a2,16
    80001ef6:	160a8593          	addi	a1,s5,352
    80001efa:	16098513          	addi	a0,s3,352
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	f1e080e7          	jalr	-226(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f06:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f0a:	854e                	mv	a0,s3
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d7e080e7          	jalr	-642(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001f14:	0000f497          	auipc	s1,0xf
    80001f18:	ee448493          	addi	s1,s1,-284 # 80010df8 <wait_lock>
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cb8080e7          	jalr	-840(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f26:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	d5e080e7          	jalr	-674(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f34:	854e                	mv	a0,s3
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	ca0080e7          	jalr	-864(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f3e:	478d                	li	a5,3
    80001f40:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f44:	854e                	mv	a0,s3
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d44080e7          	jalr	-700(ra) # 80000c8a <release>
  np->strace_bit = p->strace_bit;
    80001f4e:	170aa783          	lw	a5,368(s5)
    80001f52:	16f9a823          	sw	a5,368(s3)
  np->birth_time = p->birth_time;
    80001f56:	178ab783          	ld	a5,376(s5)
    80001f5a:	16f9bc23          	sd	a5,376(s3)
}
    80001f5e:	854a                	mv	a0,s2
    80001f60:	70e2                	ld	ra,56(sp)
    80001f62:	7442                	ld	s0,48(sp)
    80001f64:	74a2                	ld	s1,40(sp)
    80001f66:	7902                	ld	s2,32(sp)
    80001f68:	69e2                	ld	s3,24(sp)
    80001f6a:	6a42                	ld	s4,16(sp)
    80001f6c:	6aa2                	ld	s5,8(sp)
    80001f6e:	6121                	addi	sp,sp,64
    80001f70:	8082                	ret
    return -1;
    80001f72:	597d                	li	s2,-1
    80001f74:	b7ed                	j	80001f5e <fork+0x138>

0000000080001f76 <roundRobin>:
{
    80001f76:	7139                	addi	sp,sp,-64
    80001f78:	fc06                	sd	ra,56(sp)
    80001f7a:	f822                	sd	s0,48(sp)
    80001f7c:	f426                	sd	s1,40(sp)
    80001f7e:	f04a                	sd	s2,32(sp)
    80001f80:	ec4e                	sd	s3,24(sp)
    80001f82:	e852                	sd	s4,16(sp)
    80001f84:	e456                	sd	s5,8(sp)
    80001f86:	e05a                	sd	s6,0(sp)
    80001f88:	0080                	addi	s0,sp,64
    80001f8a:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    80001f8c:	0000f497          	auipc	s1,0xf
    80001f90:	28448493          	addi	s1,s1,644 # 80011210 <proc>
    if (p->state == RUNNABLE)
    80001f94:	498d                	li	s3,3
      p->state = RUNNING;
    80001f96:	4b11                	li	s6,4
      swtch(&c->context, &p->context);
    80001f98:	00850a93          	addi	s5,a0,8
  for (p = proc; p < &proc[NPROC]; p++)
    80001f9c:	00015917          	auipc	s2,0x15
    80001fa0:	47490913          	addi	s2,s2,1140 # 80017410 <tickslock>
    80001fa4:	a811                	j	80001fb8 <roundRobin+0x42>
    release(&p->lock);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	ce2080e7          	jalr	-798(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001fb0:	18848493          	addi	s1,s1,392
    80001fb4:	03248863          	beq	s1,s2,80001fe4 <roundRobin+0x6e>
    acquire(&p->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	c1c080e7          	jalr	-996(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE)
    80001fc2:	4c9c                	lw	a5,24(s1)
    80001fc4:	ff3791e3          	bne	a5,s3,80001fa6 <roundRobin+0x30>
      p->state = RUNNING;
    80001fc8:	0164ac23          	sw	s6,24(s1)
      c->proc = p;
    80001fcc:	009a3023          	sd	s1,0(s4)
      swtch(&c->context, &p->context);
    80001fd0:	06848593          	addi	a1,s1,104
    80001fd4:	8556                	mv	a0,s5
    80001fd6:	00001097          	auipc	ra,0x1
    80001fda:	90e080e7          	jalr	-1778(ra) # 800028e4 <swtch>
      c->proc = 0;
    80001fde:	000a3023          	sd	zero,0(s4)
    80001fe2:	b7d1                	j	80001fa6 <roundRobin+0x30>
}
    80001fe4:	70e2                	ld	ra,56(sp)
    80001fe6:	7442                	ld	s0,48(sp)
    80001fe8:	74a2                	ld	s1,40(sp)
    80001fea:	7902                	ld	s2,32(sp)
    80001fec:	69e2                	ld	s3,24(sp)
    80001fee:	6a42                	ld	s4,16(sp)
    80001ff0:	6aa2                	ld	s5,8(sp)
    80001ff2:	6b02                	ld	s6,0(sp)
    80001ff4:	6121                	addi	sp,sp,64
    80001ff6:	8082                	ret

0000000080001ff8 <fcfs>:
{
    80001ff8:	7139                	addi	sp,sp,-64
    80001ffa:	fc06                	sd	ra,56(sp)
    80001ffc:	f822                	sd	s0,48(sp)
    80001ffe:	f426                	sd	s1,40(sp)
    80002000:	f04a                	sd	s2,32(sp)
    80002002:	ec4e                	sd	s3,24(sp)
    80002004:	e852                	sd	s4,16(sp)
    80002006:	e456                	sd	s5,8(sp)
    80002008:	e05a                	sd	s6,0(sp)
    8000200a:	0080                	addi	s0,sp,64
    8000200c:	8b2a                	mv	s6,a0
  for (int i = 0; i < NPROC; i++)
    8000200e:	0000f497          	auipc	s1,0xf
    80002012:	20248493          	addi	s1,s1,514 # 80011210 <proc>
    80002016:	00015a17          	auipc	s4,0x15
    8000201a:	3faa0a13          	addi	s4,s4,1018 # 80017410 <tickslock>
  struct proc *oldestproc = 0;
    8000201e:	4981                	li	s3,0
      if (p->state == RUNNABLE)
    80002020:	4a8d                	li	s5,3
    80002022:	a0ad                	j	8000208c <fcfs+0x94>
  if (!oldestproc) // change state of the newly selected process
    80002024:	00098763          	beqz	s3,80002032 <fcfs+0x3a>
  if (oldestproc->state == RUNNABLE)
    80002028:	0189a703          	lw	a4,24(s3)
    8000202c:	478d                	li	a5,3
    8000202e:	00f70c63          	beq	a4,a5,80002046 <fcfs+0x4e>
}
    80002032:	70e2                	ld	ra,56(sp)
    80002034:	7442                	ld	s0,48(sp)
    80002036:	74a2                	ld	s1,40(sp)
    80002038:	7902                	ld	s2,32(sp)
    8000203a:	69e2                	ld	s3,24(sp)
    8000203c:	6a42                	ld	s4,16(sp)
    8000203e:	6aa2                	ld	s5,8(sp)
    80002040:	6b02                	ld	s6,0(sp)
    80002042:	6121                	addi	sp,sp,64
    80002044:	8082                	ret
    oldestproc->state = RUNNING;
    80002046:	4791                	li	a5,4
    80002048:	00f9ac23          	sw	a5,24(s3)
    c->proc = oldestproc;
    8000204c:	013b3023          	sd	s3,0(s6)
    swtch(&c->context, &oldestproc->context);
    80002050:	06898593          	addi	a1,s3,104
    80002054:	008b0513          	addi	a0,s6,8
    80002058:	00001097          	auipc	ra,0x1
    8000205c:	88c080e7          	jalr	-1908(ra) # 800028e4 <swtch>
    c->proc = 0;
    80002060:	000b3023          	sd	zero,0(s6)
    release(&oldestproc->lock);
    80002064:	854e                	mv	a0,s3
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	c24080e7          	jalr	-988(ra) # 80000c8a <release>
    8000206e:	b7d1                	j	80002032 <fcfs+0x3a>
      if (p->state == RUNNABLE)
    80002070:	4c9c                	lw	a5,24(s1)
    80002072:	05578363          	beq	a5,s5,800020b8 <fcfs+0xc0>
    if (oldestproc != p) // if the selected proc is not the last proc, release last proc
    80002076:	01390763          	beq	s2,s3,80002084 <fcfs+0x8c>
      release(&p->lock);
    8000207a:	854a                	mv	a0,s2
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c0e080e7          	jalr	-1010(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    80002084:	18848493          	addi	s1,s1,392
    80002088:	f9448ee3          	beq	s1,s4,80002024 <fcfs+0x2c>
    struct proc *p = &proc[i];
    8000208c:	8926                	mv	s2,s1
    acquire(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b46080e7          	jalr	-1210(ra) # 80000bd6 <acquire>
    if (oldestproc)
    80002098:	fc098ce3          	beqz	s3,80002070 <fcfs+0x78>
    if ((oldesttime > p->birth_time) || !oldestproc)
    8000209c:	1784b703          	ld	a4,376(s1)
    800020a0:	1789b783          	ld	a5,376(s3)
    800020a4:	fcf779e3          	bgeu	a4,a5,80002076 <fcfs+0x7e>
      if (p->state == RUNNABLE)
    800020a8:	4c9c                	lw	a5,24(s1)
    800020aa:	fd5796e3          	bne	a5,s5,80002076 <fcfs+0x7e>
          release(&oldestproc->lock); // release the prev selected proc, and lock newly selected proc
    800020ae:	854e                	mv	a0,s3
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
  struct proc *oldestproc = 0;
    800020b8:	89ca                	mv	s3,s2
    800020ba:	b7e9                	j	80002084 <fcfs+0x8c>

00000000800020bc <lotteryBased>:
{
    800020bc:	715d                	addi	sp,sp,-80
    800020be:	e486                	sd	ra,72(sp)
    800020c0:	e0a2                	sd	s0,64(sp)
    800020c2:	fc26                	sd	s1,56(sp)
    800020c4:	f84a                	sd	s2,48(sp)
    800020c6:	f44e                	sd	s3,40(sp)
    800020c8:	f052                	sd	s4,32(sp)
    800020ca:	ec56                	sd	s5,24(sp)
    800020cc:	e85a                	sd	s6,16(sp)
    800020ce:	e45e                	sd	s7,8(sp)
    800020d0:	e062                	sd	s8,0(sp)
    800020d2:	0880                	addi	s0,sp,80
    800020d4:	8baa                	mv	s7,a0
  for (int i = 0; i < NPROC; i++)
    800020d6:	0000f997          	auipc	s3,0xf
    800020da:	13a98993          	addi	s3,s3,314 # 80011210 <proc>
    800020de:	00015a17          	auipc	s4,0x15
    800020e2:	332a0a13          	addi	s4,s4,818 # 80017410 <tickslock>
{
    800020e6:	84ce                	mv	s1,s3
  uint64 totalNumTickets = 0, ticketCnt = 0;
    800020e8:	4c01                	li	s8,0
    if (p->state == RUNNABLE)
    800020ea:	4a8d                	li	s5,3
    800020ec:	a811                	j	80002100 <lotteryBased+0x44>
    release(&p->lock);
    800020ee:	854a                	mv	a0,s2
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b9a080e7          	jalr	-1126(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    800020f8:	18848493          	addi	s1,s1,392
    800020fc:	01448f63          	beq	s1,s4,8000211a <lotteryBased+0x5e>
    acquire(&p->lock);
    80002100:	8926                	mv	s2,s1
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	ad2080e7          	jalr	-1326(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE)
    8000210c:	4c9c                	lw	a5,24(s1)
    8000210e:	ff5790e3          	bne	a5,s5,800020ee <lotteryBased+0x32>
      totalNumTickets += p->num_tickets;
    80002112:	1804b783          	ld	a5,384(s1)
    80002116:	9c3e                	add	s8,s8,a5
    80002118:	bfd9                	j	800020ee <lotteryBased+0x32>
  uint64 randNum = random() % totalNumTickets;
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	71c080e7          	jalr	1820(ra) # 80001836 <random>
    80002122:	03857c33          	remu	s8,a0,s8
  struct proc *chosenproc = 0;
    80002126:	4a81                	li	s5,0
  uint64 totalNumTickets = 0, ticketCnt = 0;
    80002128:	4901                	li	s2,0
    if (p->state != RUNNABLE)
    8000212a:	4b0d                	li	s6,3
    8000212c:	a00d                	j	8000214e <lotteryBased+0x92>
      release(&p->lock);
    8000212e:	854e                	mv	a0,s3
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b5a080e7          	jalr	-1190(ra) # 80000c8a <release>
      continue;
    80002138:	a039                	j	80002146 <lotteryBased+0x8a>
    ticketCnt += p->num_tickets;
    8000213a:	1804b783          	ld	a5,384(s1)
    8000213e:	993e                	add	s2,s2,a5
    if (ticketCnt >= randNum)
    80002140:	03897c63          	bgeu	s2,s8,80002178 <lotteryBased+0xbc>
    struct proc *p = &proc[i];
    80002144:	8aa6                	mv	s5,s1
  for (int i = 0; i < NPROC; i++)
    80002146:	18898993          	addi	s3,s3,392
    8000214a:	03498463          	beq	s3,s4,80002172 <lotteryBased+0xb6>
    struct proc *p = &proc[i];
    8000214e:	84ce                	mv	s1,s3
    acquire(&p->lock);
    80002150:	854e                	mv	a0,s3
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a84080e7          	jalr	-1404(ra) # 80000bd6 <acquire>
    if (p->state != RUNNABLE)
    8000215a:	0189a783          	lw	a5,24(s3)
    8000215e:	fd6798e3          	bne	a5,s6,8000212e <lotteryBased+0x72>
    if (chosenproc)
    80002162:	fc0a8ce3          	beqz	s5,8000213a <lotteryBased+0x7e>
      release(&chosenproc->lock);
    80002166:	8556                	mv	a0,s5
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b22080e7          	jalr	-1246(ra) # 80000c8a <release>
    80002170:	b7e9                	j	8000213a <lotteryBased+0x7e>
  if (chosenproc)
    80002172:	020a8a63          	beqz	s5,800021a6 <lotteryBased+0xea>
    80002176:	84d6                	mv	s1,s5
    if (chosenproc->state != RUNNABLE)
    80002178:	4c8c                	lw	a1,24(s1)
    8000217a:	478d                	li	a5,3
    8000217c:	04f59163          	bne	a1,a5,800021be <lotteryBased+0x102>
    chosenproc->state = RUNNING;
    80002180:	4791                	li	a5,4
    80002182:	cc9c                	sw	a5,24(s1)
    c->proc = chosenproc;
    80002184:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffdc810>
    swtch(&c->context, &chosenproc->context);
    80002188:	06848593          	addi	a1,s1,104
    8000218c:	008b8513          	addi	a0,s7,8
    80002190:	00000097          	auipc	ra,0x0
    80002194:	754080e7          	jalr	1876(ra) # 800028e4 <swtch>
    c->proc = 0;
    80002198:	000bb023          	sd	zero,0(s7)
    release(&chosenproc->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
}
    800021a6:	60a6                	ld	ra,72(sp)
    800021a8:	6406                	ld	s0,64(sp)
    800021aa:	74e2                	ld	s1,56(sp)
    800021ac:	7942                	ld	s2,48(sp)
    800021ae:	79a2                	ld	s3,40(sp)
    800021b0:	7a02                	ld	s4,32(sp)
    800021b2:	6ae2                	ld	s5,24(sp)
    800021b4:	6b42                	ld	s6,16(sp)
    800021b6:	6ba2                	ld	s7,8(sp)
    800021b8:	6c02                	ld	s8,0(sp)
    800021ba:	6161                	addi	sp,sp,80
    800021bc:	8082                	ret
      printf("%s\n", chosenproc->state);
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	05a50513          	addi	a0,a0,90 # 80008218 <digits+0x1d8>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	3c4080e7          	jalr	964(ra) # 8000058a <printf>
    800021ce:	bf4d                	j	80002180 <lotteryBased+0xc4>

00000000800021d0 <scheduler>:
{
    800021d0:	1101                	addi	sp,sp,-32
    800021d2:	ec06                	sd	ra,24(sp)
    800021d4:	e822                	sd	s0,16(sp)
    800021d6:	e426                	sd	s1,8(sp)
    800021d8:	1000                	addi	s0,sp,32
    800021da:	8792                	mv	a5,tp
  int id = r_tp();
    800021dc:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    800021de:	079e                	slli	a5,a5,0x7
    800021e0:	0000f497          	auipc	s1,0xf
    800021e4:	c3048493          	addi	s1,s1,-976 # 80010e10 <cpus>
    800021e8:	94be                	add	s1,s1,a5
  c->proc = 0;
    800021ea:	0000f717          	auipc	a4,0xf
    800021ee:	bf670713          	addi	a4,a4,-1034 # 80010de0 <pid_lock>
    800021f2:	97ba                	add	a5,a5,a4
    800021f4:	0207b823          	sd	zero,48(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021fc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002200:	10079073          	csrw	sstatus,a5
    lotteryBased(c);
    80002204:	8526                	mv	a0,s1
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	eb6080e7          	jalr	-330(ra) # 800020bc <lotteryBased>
  for (;;)
    8000220e:	b7ed                	j	800021f8 <scheduler+0x28>

0000000080002210 <sched>:
{
    80002210:	7179                	addi	sp,sp,-48
    80002212:	f406                	sd	ra,40(sp)
    80002214:	f022                	sd	s0,32(sp)
    80002216:	ec26                	sd	s1,24(sp)
    80002218:	e84a                	sd	s2,16(sp)
    8000221a:	e44e                	sd	s3,8(sp)
    8000221c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	82c080e7          	jalr	-2004(ra) # 80001a4a <myproc>
    80002226:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	934080e7          	jalr	-1740(ra) # 80000b5c <holding>
    80002230:	c93d                	beqz	a0,800022a6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002232:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002234:	2781                	sext.w	a5,a5
    80002236:	079e                	slli	a5,a5,0x7
    80002238:	0000f717          	auipc	a4,0xf
    8000223c:	ba870713          	addi	a4,a4,-1112 # 80010de0 <pid_lock>
    80002240:	97ba                	add	a5,a5,a4
    80002242:	0a87a703          	lw	a4,168(a5)
    80002246:	4785                	li	a5,1
    80002248:	06f71763          	bne	a4,a5,800022b6 <sched+0xa6>
  if (p->state == RUNNING)
    8000224c:	4c98                	lw	a4,24(s1)
    8000224e:	4791                	li	a5,4
    80002250:	06f70b63          	beq	a4,a5,800022c6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002254:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002258:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000225a:	efb5                	bnez	a5,800022d6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000225c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000225e:	0000f917          	auipc	s2,0xf
    80002262:	b8290913          	addi	s2,s2,-1150 # 80010de0 <pid_lock>
    80002266:	2781                	sext.w	a5,a5
    80002268:	079e                	slli	a5,a5,0x7
    8000226a:	97ca                	add	a5,a5,s2
    8000226c:	0ac7a983          	lw	s3,172(a5)
    80002270:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002272:	2781                	sext.w	a5,a5
    80002274:	079e                	slli	a5,a5,0x7
    80002276:	0000f597          	auipc	a1,0xf
    8000227a:	ba258593          	addi	a1,a1,-1118 # 80010e18 <cpus+0x8>
    8000227e:	95be                	add	a1,a1,a5
    80002280:	06848513          	addi	a0,s1,104
    80002284:	00000097          	auipc	ra,0x0
    80002288:	660080e7          	jalr	1632(ra) # 800028e4 <swtch>
    8000228c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000228e:	2781                	sext.w	a5,a5
    80002290:	079e                	slli	a5,a5,0x7
    80002292:	993e                	add	s2,s2,a5
    80002294:	0b392623          	sw	s3,172(s2)
}
    80002298:	70a2                	ld	ra,40(sp)
    8000229a:	7402                	ld	s0,32(sp)
    8000229c:	64e2                	ld	s1,24(sp)
    8000229e:	6942                	ld	s2,16(sp)
    800022a0:	69a2                	ld	s3,8(sp)
    800022a2:	6145                	addi	sp,sp,48
    800022a4:	8082                	ret
    panic("sched p->lock");
    800022a6:	00006517          	auipc	a0,0x6
    800022aa:	f7a50513          	addi	a0,a0,-134 # 80008220 <digits+0x1e0>
    800022ae:	ffffe097          	auipc	ra,0xffffe
    800022b2:	292080e7          	jalr	658(ra) # 80000540 <panic>
    panic("sched locks");
    800022b6:	00006517          	auipc	a0,0x6
    800022ba:	f7a50513          	addi	a0,a0,-134 # 80008230 <digits+0x1f0>
    800022be:	ffffe097          	auipc	ra,0xffffe
    800022c2:	282080e7          	jalr	642(ra) # 80000540 <panic>
    panic("sched running");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	f7a50513          	addi	a0,a0,-134 # 80008240 <digits+0x200>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	272080e7          	jalr	626(ra) # 80000540 <panic>
    panic("sched interruptible");
    800022d6:	00006517          	auipc	a0,0x6
    800022da:	f7a50513          	addi	a0,a0,-134 # 80008250 <digits+0x210>
    800022de:	ffffe097          	auipc	ra,0xffffe
    800022e2:	262080e7          	jalr	610(ra) # 80000540 <panic>

00000000800022e6 <yield>:
{
    800022e6:	1101                	addi	sp,sp,-32
    800022e8:	ec06                	sd	ra,24(sp)
    800022ea:	e822                	sd	s0,16(sp)
    800022ec:	e426                	sd	s1,8(sp)
    800022ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	75a080e7          	jalr	1882(ra) # 80001a4a <myproc>
    800022f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8dc080e7          	jalr	-1828(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002302:	478d                	li	a5,3
    80002304:	cc9c                	sw	a5,24(s1)
  sched();
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	f0a080e7          	jalr	-246(ra) # 80002210 <sched>
  release(&p->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	97a080e7          	jalr	-1670(ra) # 80000c8a <release>
}
    80002318:	60e2                	ld	ra,24(sp)
    8000231a:	6442                	ld	s0,16(sp)
    8000231c:	64a2                	ld	s1,8(sp)
    8000231e:	6105                	addi	sp,sp,32
    80002320:	8082                	ret

0000000080002322 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002322:	7179                	addi	sp,sp,-48
    80002324:	f406                	sd	ra,40(sp)
    80002326:	f022                	sd	s0,32(sp)
    80002328:	ec26                	sd	s1,24(sp)
    8000232a:	e84a                	sd	s2,16(sp)
    8000232c:	e44e                	sd	s3,8(sp)
    8000232e:	1800                	addi	s0,sp,48
    80002330:	89aa                	mv	s3,a0
    80002332:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	716080e7          	jalr	1814(ra) # 80001a4a <myproc>
    8000233c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	898080e7          	jalr	-1896(ra) # 80000bd6 <acquire>
  release(lk);
    80002346:	854a                	mv	a0,s2
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	942080e7          	jalr	-1726(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002350:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002354:	4789                	li	a5,2
    80002356:	cc9c                	sw	a5,24(s1)

  sched();
    80002358:	00000097          	auipc	ra,0x0
    8000235c:	eb8080e7          	jalr	-328(ra) # 80002210 <sched>

  // Tidy up.
  p->chan = 0;
    80002360:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	924080e7          	jalr	-1756(ra) # 80000c8a <release>
  acquire(lk);
    8000236e:	854a                	mv	a0,s2
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	866080e7          	jalr	-1946(ra) # 80000bd6 <acquire>
}
    80002378:	70a2                	ld	ra,40(sp)
    8000237a:	7402                	ld	s0,32(sp)
    8000237c:	64e2                	ld	s1,24(sp)
    8000237e:	6942                	ld	s2,16(sp)
    80002380:	69a2                	ld	s3,8(sp)
    80002382:	6145                	addi	sp,sp,48
    80002384:	8082                	ret

0000000080002386 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002386:	7139                	addi	sp,sp,-64
    80002388:	fc06                	sd	ra,56(sp)
    8000238a:	f822                	sd	s0,48(sp)
    8000238c:	f426                	sd	s1,40(sp)
    8000238e:	f04a                	sd	s2,32(sp)
    80002390:	ec4e                	sd	s3,24(sp)
    80002392:	e852                	sd	s4,16(sp)
    80002394:	e456                	sd	s5,8(sp)
    80002396:	0080                	addi	s0,sp,64
    80002398:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	e7648493          	addi	s1,s1,-394 # 80011210 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800023a2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800023a4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800023a6:	00015917          	auipc	s2,0x15
    800023aa:	06a90913          	addi	s2,s2,106 # 80017410 <tickslock>
    800023ae:	a811                	j	800023c2 <wakeup+0x3c>
      }
      release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8d8080e7          	jalr	-1832(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023ba:	18848493          	addi	s1,s1,392
    800023be:	03248663          	beq	s1,s2,800023ea <wakeup+0x64>
    if (p != myproc())
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	688080e7          	jalr	1672(ra) # 80001a4a <myproc>
    800023ca:	fea488e3          	beq	s1,a0,800023ba <wakeup+0x34>
      acquire(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800023d8:	4c9c                	lw	a5,24(s1)
    800023da:	fd379be3          	bne	a5,s3,800023b0 <wakeup+0x2a>
    800023de:	709c                	ld	a5,32(s1)
    800023e0:	fd4798e3          	bne	a5,s4,800023b0 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023e4:	0154ac23          	sw	s5,24(s1)
    800023e8:	b7e1                	j	800023b0 <wakeup+0x2a>
    }
  }
}
    800023ea:	70e2                	ld	ra,56(sp)
    800023ec:	7442                	ld	s0,48(sp)
    800023ee:	74a2                	ld	s1,40(sp)
    800023f0:	7902                	ld	s2,32(sp)
    800023f2:	69e2                	ld	s3,24(sp)
    800023f4:	6a42                	ld	s4,16(sp)
    800023f6:	6aa2                	ld	s5,8(sp)
    800023f8:	6121                	addi	sp,sp,64
    800023fa:	8082                	ret

00000000800023fc <reparent>:
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	e052                	sd	s4,0(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240e:	0000f497          	auipc	s1,0xf
    80002412:	e0248493          	addi	s1,s1,-510 # 80011210 <proc>
      pp->parent = initproc;
    80002416:	00006a17          	auipc	s4,0x6
    8000241a:	752a0a13          	addi	s4,s4,1874 # 80008b68 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241e:	00015997          	auipc	s3,0x15
    80002422:	ff298993          	addi	s3,s3,-14 # 80017410 <tickslock>
    80002426:	a029                	j	80002430 <reparent+0x34>
    80002428:	18848493          	addi	s1,s1,392
    8000242c:	01348d63          	beq	s1,s3,80002446 <reparent+0x4a>
    if (pp->parent == p)
    80002430:	7c9c                	ld	a5,56(s1)
    80002432:	ff279be3          	bne	a5,s2,80002428 <reparent+0x2c>
      pp->parent = initproc;
    80002436:	000a3503          	ld	a0,0(s4)
    8000243a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000243c:	00000097          	auipc	ra,0x0
    80002440:	f4a080e7          	jalr	-182(ra) # 80002386 <wakeup>
    80002444:	b7d5                	j	80002428 <reparent+0x2c>
}
    80002446:	70a2                	ld	ra,40(sp)
    80002448:	7402                	ld	s0,32(sp)
    8000244a:	64e2                	ld	s1,24(sp)
    8000244c:	6942                	ld	s2,16(sp)
    8000244e:	69a2                	ld	s3,8(sp)
    80002450:	6a02                	ld	s4,0(sp)
    80002452:	6145                	addi	sp,sp,48
    80002454:	8082                	ret

0000000080002456 <exit>:
{
    80002456:	7179                	addi	sp,sp,-48
    80002458:	f406                	sd	ra,40(sp)
    8000245a:	f022                	sd	s0,32(sp)
    8000245c:	ec26                	sd	s1,24(sp)
    8000245e:	e84a                	sd	s2,16(sp)
    80002460:	e44e                	sd	s3,8(sp)
    80002462:	e052                	sd	s4,0(sp)
    80002464:	1800                	addi	s0,sp,48
    80002466:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	5e2080e7          	jalr	1506(ra) # 80001a4a <myproc>
    80002470:	89aa                	mv	s3,a0
  if (p == initproc)
    80002472:	00006797          	auipc	a5,0x6
    80002476:	6f67b783          	ld	a5,1782(a5) # 80008b68 <initproc>
    8000247a:	0d850493          	addi	s1,a0,216
    8000247e:	15850913          	addi	s2,a0,344
    80002482:	02a79363          	bne	a5,a0,800024a8 <exit+0x52>
    panic("init exiting");
    80002486:	00006517          	auipc	a0,0x6
    8000248a:	de250513          	addi	a0,a0,-542 # 80008268 <digits+0x228>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	0b2080e7          	jalr	178(ra) # 80000540 <panic>
      fileclose(f);
    80002496:	00002097          	auipc	ra,0x2
    8000249a:	4d4080e7          	jalr	1236(ra) # 8000496a <fileclose>
      p->ofile[fd] = 0;
    8000249e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800024a2:	04a1                	addi	s1,s1,8
    800024a4:	01248563          	beq	s1,s2,800024ae <exit+0x58>
    if (p->ofile[fd])
    800024a8:	6088                	ld	a0,0(s1)
    800024aa:	f575                	bnez	a0,80002496 <exit+0x40>
    800024ac:	bfdd                	j	800024a2 <exit+0x4c>
  begin_op();
    800024ae:	00002097          	auipc	ra,0x2
    800024b2:	ff4080e7          	jalr	-12(ra) # 800044a2 <begin_op>
  iput(p->cwd);
    800024b6:	1589b503          	ld	a0,344(s3)
    800024ba:	00001097          	auipc	ra,0x1
    800024be:	7d6080e7          	jalr	2006(ra) # 80003c90 <iput>
  end_op();
    800024c2:	00002097          	auipc	ra,0x2
    800024c6:	05e080e7          	jalr	94(ra) # 80004520 <end_op>
  p->cwd = 0;
    800024ca:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800024ce:	0000f497          	auipc	s1,0xf
    800024d2:	92a48493          	addi	s1,s1,-1750 # 80010df8 <wait_lock>
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	6fe080e7          	jalr	1790(ra) # 80000bd6 <acquire>
  reparent(p);
    800024e0:	854e                	mv	a0,s3
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	f1a080e7          	jalr	-230(ra) # 800023fc <reparent>
  wakeup(p->parent);
    800024ea:	0389b503          	ld	a0,56(s3)
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	e98080e7          	jalr	-360(ra) # 80002386 <wakeup>
  acquire(&p->lock);
    800024f6:	854e                	mv	a0,s3
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	6de080e7          	jalr	1758(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002500:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002504:	4795                	li	a5,5
    80002506:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	77e080e7          	jalr	1918(ra) # 80000c8a <release>
  sched();
    80002514:	00000097          	auipc	ra,0x0
    80002518:	cfc080e7          	jalr	-772(ra) # 80002210 <sched>
  panic("zombie exit");
    8000251c:	00006517          	auipc	a0,0x6
    80002520:	d5c50513          	addi	a0,a0,-676 # 80008278 <digits+0x238>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	01c080e7          	jalr	28(ra) # 80000540 <panic>

000000008000252c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000252c:	7179                	addi	sp,sp,-48
    8000252e:	f406                	sd	ra,40(sp)
    80002530:	f022                	sd	s0,32(sp)
    80002532:	ec26                	sd	s1,24(sp)
    80002534:	e84a                	sd	s2,16(sp)
    80002536:	e44e                	sd	s3,8(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000253c:	0000f497          	auipc	s1,0xf
    80002540:	cd448493          	addi	s1,s1,-812 # 80011210 <proc>
    80002544:	00015997          	auipc	s3,0x15
    80002548:	ecc98993          	addi	s3,s3,-308 # 80017410 <tickslock>
  {
    acquire(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	688080e7          	jalr	1672(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002556:	589c                	lw	a5,48(s1)
    80002558:	01278d63          	beq	a5,s2,80002572 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	72c080e7          	jalr	1836(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002566:	18848493          	addi	s1,s1,392
    8000256a:	ff3491e3          	bne	s1,s3,8000254c <kill+0x20>
  }
  return -1;
    8000256e:	557d                	li	a0,-1
    80002570:	a829                	j	8000258a <kill+0x5e>
      p->killed = 1;
    80002572:	4785                	li	a5,1
    80002574:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002576:	4c98                	lw	a4,24(s1)
    80002578:	4789                	li	a5,2
    8000257a:	00f70f63          	beq	a4,a5,80002598 <kill+0x6c>
      release(&p->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	70a080e7          	jalr	1802(ra) # 80000c8a <release>
      return 0;
    80002588:	4501                	li	a0,0
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6145                	addi	sp,sp,48
    80002596:	8082                	ret
        p->state = RUNNABLE;
    80002598:	478d                	li	a5,3
    8000259a:	cc9c                	sw	a5,24(s1)
    8000259c:	b7cd                	j	8000257e <kill+0x52>

000000008000259e <setkilled>:

void setkilled(struct proc *p)
{
    8000259e:	1101                	addi	sp,sp,-32
    800025a0:	ec06                	sd	ra,24(sp)
    800025a2:	e822                	sd	s0,16(sp)
    800025a4:	e426                	sd	s1,8(sp)
    800025a6:	1000                	addi	s0,sp,32
    800025a8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	62c080e7          	jalr	1580(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800025b2:	4785                	li	a5,1
    800025b4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025b6:	8526                	mv	a0,s1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	6d2080e7          	jalr	1746(ra) # 80000c8a <release>
}
    800025c0:	60e2                	ld	ra,24(sp)
    800025c2:	6442                	ld	s0,16(sp)
    800025c4:	64a2                	ld	s1,8(sp)
    800025c6:	6105                	addi	sp,sp,32
    800025c8:	8082                	ret

00000000800025ca <killed>:

int killed(struct proc *p)
{
    800025ca:	1101                	addi	sp,sp,-32
    800025cc:	ec06                	sd	ra,24(sp)
    800025ce:	e822                	sd	s0,16(sp)
    800025d0:	e426                	sd	s1,8(sp)
    800025d2:	e04a                	sd	s2,0(sp)
    800025d4:	1000                	addi	s0,sp,32
    800025d6:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	5fe080e7          	jalr	1534(ra) # 80000bd6 <acquire>
  k = p->killed;
    800025e0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025e4:	8526                	mv	a0,s1
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6a4080e7          	jalr	1700(ra) # 80000c8a <release>
  return k;
}
    800025ee:	854a                	mv	a0,s2
    800025f0:	60e2                	ld	ra,24(sp)
    800025f2:	6442                	ld	s0,16(sp)
    800025f4:	64a2                	ld	s1,8(sp)
    800025f6:	6902                	ld	s2,0(sp)
    800025f8:	6105                	addi	sp,sp,32
    800025fa:	8082                	ret

00000000800025fc <wait>:
{
    800025fc:	715d                	addi	sp,sp,-80
    800025fe:	e486                	sd	ra,72(sp)
    80002600:	e0a2                	sd	s0,64(sp)
    80002602:	fc26                	sd	s1,56(sp)
    80002604:	f84a                	sd	s2,48(sp)
    80002606:	f44e                	sd	s3,40(sp)
    80002608:	f052                	sd	s4,32(sp)
    8000260a:	ec56                	sd	s5,24(sp)
    8000260c:	e85a                	sd	s6,16(sp)
    8000260e:	e45e                	sd	s7,8(sp)
    80002610:	e062                	sd	s8,0(sp)
    80002612:	0880                	addi	s0,sp,80
    80002614:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	434080e7          	jalr	1076(ra) # 80001a4a <myproc>
    8000261e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002620:	0000e517          	auipc	a0,0xe
    80002624:	7d850513          	addi	a0,a0,2008 # 80010df8 <wait_lock>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	5ae080e7          	jalr	1454(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002630:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002632:	4a15                	li	s4,5
        havekids = 1;
    80002634:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002636:	00015997          	auipc	s3,0x15
    8000263a:	dda98993          	addi	s3,s3,-550 # 80017410 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000263e:	0000ec17          	auipc	s8,0xe
    80002642:	7bac0c13          	addi	s8,s8,1978 # 80010df8 <wait_lock>
    havekids = 0;
    80002646:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	bc848493          	addi	s1,s1,-1080 # 80011210 <proc>
    80002650:	a0bd                	j	800026be <wait+0xc2>
          pid = pp->pid;
    80002652:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002656:	000b0e63          	beqz	s6,80002672 <wait+0x76>
    8000265a:	4691                	li	a3,4
    8000265c:	02c48613          	addi	a2,s1,44
    80002660:	85da                	mv	a1,s6
    80002662:	05893503          	ld	a0,88(s2)
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	006080e7          	jalr	6(ra) # 8000166c <copyout>
    8000266e:	02054563          	bltz	a0,80002698 <wait+0x9c>
          freeproc(pp);
    80002672:	8526                	mv	a0,s1
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	588080e7          	jalr	1416(ra) # 80001bfc <freeproc>
          release(&pp->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	60c080e7          	jalr	1548(ra) # 80000c8a <release>
          release(&wait_lock);
    80002686:	0000e517          	auipc	a0,0xe
    8000268a:	77250513          	addi	a0,a0,1906 # 80010df8 <wait_lock>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5fc080e7          	jalr	1532(ra) # 80000c8a <release>
          return pid;
    80002696:	a0b5                	j	80002702 <wait+0x106>
            release(&pp->lock);
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>
            release(&wait_lock);
    800026a2:	0000e517          	auipc	a0,0xe
    800026a6:	75650513          	addi	a0,a0,1878 # 80010df8 <wait_lock>
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	5e0080e7          	jalr	1504(ra) # 80000c8a <release>
            return -1;
    800026b2:	59fd                	li	s3,-1
    800026b4:	a0b9                	j	80002702 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b6:	18848493          	addi	s1,s1,392
    800026ba:	03348463          	beq	s1,s3,800026e2 <wait+0xe6>
      if (pp->parent == p)
    800026be:	7c9c                	ld	a5,56(s1)
    800026c0:	ff279be3          	bne	a5,s2,800026b6 <wait+0xba>
        acquire(&pp->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	510080e7          	jalr	1296(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    800026ce:	4c9c                	lw	a5,24(s1)
    800026d0:	f94781e3          	beq	a5,s4,80002652 <wait+0x56>
        release(&pp->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5b4080e7          	jalr	1460(ra) # 80000c8a <release>
        havekids = 1;
    800026de:	8756                	mv	a4,s5
    800026e0:	bfd9                	j	800026b6 <wait+0xba>
    if (!havekids || killed(p))
    800026e2:	c719                	beqz	a4,800026f0 <wait+0xf4>
    800026e4:	854a                	mv	a0,s2
    800026e6:	00000097          	auipc	ra,0x0
    800026ea:	ee4080e7          	jalr	-284(ra) # 800025ca <killed>
    800026ee:	c51d                	beqz	a0,8000271c <wait+0x120>
      release(&wait_lock);
    800026f0:	0000e517          	auipc	a0,0xe
    800026f4:	70850513          	addi	a0,a0,1800 # 80010df8 <wait_lock>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	592080e7          	jalr	1426(ra) # 80000c8a <release>
      return -1;
    80002700:	59fd                	li	s3,-1
}
    80002702:	854e                	mv	a0,s3
    80002704:	60a6                	ld	ra,72(sp)
    80002706:	6406                	ld	s0,64(sp)
    80002708:	74e2                	ld	s1,56(sp)
    8000270a:	7942                	ld	s2,48(sp)
    8000270c:	79a2                	ld	s3,40(sp)
    8000270e:	7a02                	ld	s4,32(sp)
    80002710:	6ae2                	ld	s5,24(sp)
    80002712:	6b42                	ld	s6,16(sp)
    80002714:	6ba2                	ld	s7,8(sp)
    80002716:	6c02                	ld	s8,0(sp)
    80002718:	6161                	addi	sp,sp,80
    8000271a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000271c:	85e2                	mv	a1,s8
    8000271e:	854a                	mv	a0,s2
    80002720:	00000097          	auipc	ra,0x0
    80002724:	c02080e7          	jalr	-1022(ra) # 80002322 <sleep>
    havekids = 0;
    80002728:	bf39                	j	80002646 <wait+0x4a>

000000008000272a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000272a:	7179                	addi	sp,sp,-48
    8000272c:	f406                	sd	ra,40(sp)
    8000272e:	f022                	sd	s0,32(sp)
    80002730:	ec26                	sd	s1,24(sp)
    80002732:	e84a                	sd	s2,16(sp)
    80002734:	e44e                	sd	s3,8(sp)
    80002736:	e052                	sd	s4,0(sp)
    80002738:	1800                	addi	s0,sp,48
    8000273a:	84aa                	mv	s1,a0
    8000273c:	892e                	mv	s2,a1
    8000273e:	89b2                	mv	s3,a2
    80002740:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002742:	fffff097          	auipc	ra,0xfffff
    80002746:	308080e7          	jalr	776(ra) # 80001a4a <myproc>
  if (user_dst)
    8000274a:	c08d                	beqz	s1,8000276c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000274c:	86d2                	mv	a3,s4
    8000274e:	864e                	mv	a2,s3
    80002750:	85ca                	mv	a1,s2
    80002752:	6d28                	ld	a0,88(a0)
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	f18080e7          	jalr	-232(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000275c:	70a2                	ld	ra,40(sp)
    8000275e:	7402                	ld	s0,32(sp)
    80002760:	64e2                	ld	s1,24(sp)
    80002762:	6942                	ld	s2,16(sp)
    80002764:	69a2                	ld	s3,8(sp)
    80002766:	6a02                	ld	s4,0(sp)
    80002768:	6145                	addi	sp,sp,48
    8000276a:	8082                	ret
    memmove((char *)dst, src, len);
    8000276c:	000a061b          	sext.w	a2,s4
    80002770:	85ce                	mv	a1,s3
    80002772:	854a                	mv	a0,s2
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	5ba080e7          	jalr	1466(ra) # 80000d2e <memmove>
    return 0;
    8000277c:	8526                	mv	a0,s1
    8000277e:	bff9                	j	8000275c <either_copyout+0x32>

0000000080002780 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	e052                	sd	s4,0(sp)
    8000278e:	1800                	addi	s0,sp,48
    80002790:	892a                	mv	s2,a0
    80002792:	84ae                	mv	s1,a1
    80002794:	89b2                	mv	s3,a2
    80002796:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002798:	fffff097          	auipc	ra,0xfffff
    8000279c:	2b2080e7          	jalr	690(ra) # 80001a4a <myproc>
  if (user_src)
    800027a0:	c08d                	beqz	s1,800027c2 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027a2:	86d2                	mv	a3,s4
    800027a4:	864e                	mv	a2,s3
    800027a6:	85ca                	mv	a1,s2
    800027a8:	6d28                	ld	a0,88(a0)
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	f4e080e7          	jalr	-178(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027b2:	70a2                	ld	ra,40(sp)
    800027b4:	7402                	ld	s0,32(sp)
    800027b6:	64e2                	ld	s1,24(sp)
    800027b8:	6942                	ld	s2,16(sp)
    800027ba:	69a2                	ld	s3,8(sp)
    800027bc:	6a02                	ld	s4,0(sp)
    800027be:	6145                	addi	sp,sp,48
    800027c0:	8082                	ret
    memmove(dst, (char *)src, len);
    800027c2:	000a061b          	sext.w	a2,s4
    800027c6:	85ce                	mv	a1,s3
    800027c8:	854a                	mv	a0,s2
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	564080e7          	jalr	1380(ra) # 80000d2e <memmove>
    return 0;
    800027d2:	8526                	mv	a0,s1
    800027d4:	bff9                	j	800027b2 <either_copyin+0x32>

00000000800027d6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027d6:	715d                	addi	sp,sp,-80
    800027d8:	e486                	sd	ra,72(sp)
    800027da:	e0a2                	sd	s0,64(sp)
    800027dc:	fc26                	sd	s1,56(sp)
    800027de:	f84a                	sd	s2,48(sp)
    800027e0:	f44e                	sd	s3,40(sp)
    800027e2:	f052                	sd	s4,32(sp)
    800027e4:	ec56                	sd	s5,24(sp)
    800027e6:	e85a                	sd	s6,16(sp)
    800027e8:	e45e                	sd	s7,8(sp)
    800027ea:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027ec:	00006517          	auipc	a0,0x6
    800027f0:	8dc50513          	addi	a0,a0,-1828 # 800080c8 <digits+0x88>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	d96080e7          	jalr	-618(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027fc:	0000f497          	auipc	s1,0xf
    80002800:	b7448493          	addi	s1,s1,-1164 # 80011370 <proc+0x160>
    80002804:	00015917          	auipc	s2,0x15
    80002808:	d6c90913          	addi	s2,s2,-660 # 80017570 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000280c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000280e:	00006997          	auipc	s3,0x6
    80002812:	a7a98993          	addi	s3,s3,-1414 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002816:	00006a97          	auipc	s5,0x6
    8000281a:	a7aa8a93          	addi	s5,s5,-1414 # 80008290 <digits+0x250>
    printf("\n");
    8000281e:	00006a17          	auipc	s4,0x6
    80002822:	8aaa0a13          	addi	s4,s4,-1878 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002826:	00006b97          	auipc	s7,0x6
    8000282a:	aaab8b93          	addi	s7,s7,-1366 # 800082d0 <states.0>
    8000282e:	a00d                	j	80002850 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002830:	ed06a583          	lw	a1,-304(a3)
    80002834:	8556                	mv	a0,s5
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d54080e7          	jalr	-684(ra) # 8000058a <printf>
    printf("\n");
    8000283e:	8552                	mv	a0,s4
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	d4a080e7          	jalr	-694(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002848:	18848493          	addi	s1,s1,392
    8000284c:	03248263          	beq	s1,s2,80002870 <procdump+0x9a>
    if (p->state == UNUSED)
    80002850:	86a6                	mv	a3,s1
    80002852:	eb84a783          	lw	a5,-328(s1)
    80002856:	dbed                	beqz	a5,80002848 <procdump+0x72>
      state = "???";
    80002858:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285a:	fcfb6be3          	bltu	s6,a5,80002830 <procdump+0x5a>
    8000285e:	02079713          	slli	a4,a5,0x20
    80002862:	01d75793          	srli	a5,a4,0x1d
    80002866:	97de                	add	a5,a5,s7
    80002868:	6390                	ld	a2,0(a5)
    8000286a:	f279                	bnez	a2,80002830 <procdump+0x5a>
      state = "???";
    8000286c:	864e                	mv	a2,s3
    8000286e:	b7c9                	j	80002830 <procdump+0x5a>
  }
}
    80002870:	60a6                	ld	ra,72(sp)
    80002872:	6406                	ld	s0,64(sp)
    80002874:	74e2                	ld	s1,56(sp)
    80002876:	7942                	ld	s2,48(sp)
    80002878:	79a2                	ld	s3,40(sp)
    8000287a:	7a02                	ld	s4,32(sp)
    8000287c:	6ae2                	ld	s5,24(sp)
    8000287e:	6b42                	ld	s6,16(sp)
    80002880:	6ba2                	ld	s7,8(sp)
    80002882:	6161                	addi	sp,sp,80
    80002884:	8082                	ret

0000000080002886 <strace>:

void strace(int strace_mask)
{
    80002886:	1101                	addi	sp,sp,-32
    80002888:	ec06                	sd	ra,24(sp)
    8000288a:	e822                	sd	s0,16(sp)
    8000288c:	e426                	sd	s1,8(sp)
    8000288e:	1000                	addi	s0,sp,32
    80002890:	84aa                	mv	s1,a0
  struct proc *p;
  p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	1b8080e7          	jalr	440(ra) # 80001a4a <myproc>
  if (!p)
    8000289a:	c519                	beqz	a0,800028a8 <strace+0x22>
    return;

  myproc()->strace_bit = strace_mask;
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	1ae080e7          	jalr	430(ra) # 80001a4a <myproc>
    800028a4:	16952823          	sw	s1,368(a0)
  return;
}
    800028a8:	60e2                	ld	ra,24(sp)
    800028aa:	6442                	ld	s0,16(sp)
    800028ac:	64a2                	ld	s1,8(sp)
    800028ae:	6105                	addi	sp,sp,32
    800028b0:	8082                	ret

00000000800028b2 <settickets>:

int settickets(int numTickets)
{
    800028b2:	1101                	addi	sp,sp,-32
    800028b4:	ec06                	sd	ra,24(sp)
    800028b6:	e822                	sd	s0,16(sp)
    800028b8:	e426                	sd	s1,8(sp)
    800028ba:	1000                	addi	s0,sp,32
    800028bc:	84aa                	mv	s1,a0
  struct proc *p;
  p = myproc();
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	18c080e7          	jalr	396(ra) # 80001a4a <myproc>
  if (!p)
    800028c6:	cd09                	beqz	a0,800028e0 <settickets+0x2e>
    return -1;

  myproc()->num_tickets = numTickets;
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	182080e7          	jalr	386(ra) # 80001a4a <myproc>
    800028d0:	18953023          	sd	s1,384(a0)
  return numTickets;
    800028d4:	8526                	mv	a0,s1
    800028d6:	60e2                	ld	ra,24(sp)
    800028d8:	6442                	ld	s0,16(sp)
    800028da:	64a2                	ld	s1,8(sp)
    800028dc:	6105                	addi	sp,sp,32
    800028de:	8082                	ret
    return -1;
    800028e0:	557d                	li	a0,-1
    800028e2:	bfd5                	j	800028d6 <settickets+0x24>

00000000800028e4 <swtch>:
    800028e4:	00153023          	sd	ra,0(a0)
    800028e8:	00253423          	sd	sp,8(a0)
    800028ec:	e900                	sd	s0,16(a0)
    800028ee:	ed04                	sd	s1,24(a0)
    800028f0:	03253023          	sd	s2,32(a0)
    800028f4:	03353423          	sd	s3,40(a0)
    800028f8:	03453823          	sd	s4,48(a0)
    800028fc:	03553c23          	sd	s5,56(a0)
    80002900:	05653023          	sd	s6,64(a0)
    80002904:	05753423          	sd	s7,72(a0)
    80002908:	05853823          	sd	s8,80(a0)
    8000290c:	05953c23          	sd	s9,88(a0)
    80002910:	07a53023          	sd	s10,96(a0)
    80002914:	07b53423          	sd	s11,104(a0)
    80002918:	0005b083          	ld	ra,0(a1)
    8000291c:	0085b103          	ld	sp,8(a1)
    80002920:	6980                	ld	s0,16(a1)
    80002922:	6d84                	ld	s1,24(a1)
    80002924:	0205b903          	ld	s2,32(a1)
    80002928:	0285b983          	ld	s3,40(a1)
    8000292c:	0305ba03          	ld	s4,48(a1)
    80002930:	0385ba83          	ld	s5,56(a1)
    80002934:	0405bb03          	ld	s6,64(a1)
    80002938:	0485bb83          	ld	s7,72(a1)
    8000293c:	0505bc03          	ld	s8,80(a1)
    80002940:	0585bc83          	ld	s9,88(a1)
    80002944:	0605bd03          	ld	s10,96(a1)
    80002948:	0685bd83          	ld	s11,104(a1)
    8000294c:	8082                	ret

000000008000294e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e406                	sd	ra,8(sp)
    80002952:	e022                	sd	s0,0(sp)
    80002954:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002956:	00006597          	auipc	a1,0x6
    8000295a:	9aa58593          	addi	a1,a1,-1622 # 80008300 <states.0+0x30>
    8000295e:	00015517          	auipc	a0,0x15
    80002962:	ab250513          	addi	a0,a0,-1358 # 80017410 <tickslock>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	1e0080e7          	jalr	480(ra) # 80000b46 <initlock>
}
    8000296e:	60a2                	ld	ra,8(sp)
    80002970:	6402                	ld	s0,0(sp)
    80002972:	0141                	addi	sp,sp,16
    80002974:	8082                	ret

0000000080002976 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002976:	1141                	addi	sp,sp,-16
    80002978:	e422                	sd	s0,8(sp)
    8000297a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297c:	00003797          	auipc	a5,0x3
    80002980:	64478793          	addi	a5,a5,1604 # 80005fc0 <kernelvec>
    80002984:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002988:	6422                	ld	s0,8(sp)
    8000298a:	0141                	addi	sp,sp,16
    8000298c:	8082                	ret

000000008000298e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000298e:	1141                	addi	sp,sp,-16
    80002990:	e406                	sd	ra,8(sp)
    80002992:	e022                	sd	s0,0(sp)
    80002994:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	0b4080e7          	jalr	180(ra) # 80001a4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029a8:	00004697          	auipc	a3,0x4
    800029ac:	65868693          	addi	a3,a3,1624 # 80007000 <_trampoline>
    800029b0:	00004717          	auipc	a4,0x4
    800029b4:	65070713          	addi	a4,a4,1616 # 80007000 <_trampoline>
    800029b8:	8f15                	sub	a4,a4,a3
    800029ba:	040007b7          	lui	a5,0x4000
    800029be:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029c0:	07b2                	slli	a5,a5,0xc
    800029c2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c4:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029c8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ca:	18002673          	csrr	a2,satp
    800029ce:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029d0:	7130                	ld	a2,96(a0)
    800029d2:	6138                	ld	a4,64(a0)
    800029d4:	6585                	lui	a1,0x1
    800029d6:	972e                	add	a4,a4,a1
    800029d8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029da:	7138                	ld	a4,96(a0)
    800029dc:	00000617          	auipc	a2,0x0
    800029e0:	13060613          	addi	a2,a2,304 # 80002b0c <usertrap>
    800029e4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029e6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029e8:	8612                	mv	a2,tp
    800029ea:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ec:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029f0:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029f4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029fc:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029fe:	6f18                	ld	a4,24(a4)
    80002a00:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a04:	6d28                	ld	a0,88(a0)
    80002a06:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a08:	00004717          	auipc	a4,0x4
    80002a0c:	69470713          	addi	a4,a4,1684 # 8000709c <userret>
    80002a10:	8f15                	sub	a4,a4,a3
    80002a12:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a14:	577d                	li	a4,-1
    80002a16:	177e                	slli	a4,a4,0x3f
    80002a18:	8d59                	or	a0,a0,a4
    80002a1a:	9782                	jalr	a5
}
    80002a1c:	60a2                	ld	ra,8(sp)
    80002a1e:	6402                	ld	s0,0(sp)
    80002a20:	0141                	addi	sp,sp,16
    80002a22:	8082                	ret

0000000080002a24 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a24:	1101                	addi	sp,sp,-32
    80002a26:	ec06                	sd	ra,24(sp)
    80002a28:	e822                	sd	s0,16(sp)
    80002a2a:	e426                	sd	s1,8(sp)
    80002a2c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2e:	00015497          	auipc	s1,0x15
    80002a32:	9e248493          	addi	s1,s1,-1566 # 80017410 <tickslock>
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	19e080e7          	jalr	414(ra) # 80000bd6 <acquire>
  ticks++;
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	13050513          	addi	a0,a0,304 # 80008b70 <ticks>
    80002a48:	411c                	lw	a5,0(a0)
    80002a4a:	2785                	addiw	a5,a5,1
    80002a4c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	938080e7          	jalr	-1736(ra) # 80002386 <wakeup>
  release(&tickslock);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	232080e7          	jalr	562(ra) # 80000c8a <release>
}
    80002a60:	60e2                	ld	ra,24(sp)
    80002a62:	6442                	ld	s0,16(sp)
    80002a64:	64a2                	ld	s1,8(sp)
    80002a66:	6105                	addi	sp,sp,32
    80002a68:	8082                	ret

0000000080002a6a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a6a:	1101                	addi	sp,sp,-32
    80002a6c:	ec06                	sd	ra,24(sp)
    80002a6e:	e822                	sd	s0,16(sp)
    80002a70:	e426                	sd	s1,8(sp)
    80002a72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a78:	00074d63          	bltz	a4,80002a92 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a7c:	57fd                	li	a5,-1
    80002a7e:	17fe                	slli	a5,a5,0x3f
    80002a80:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a82:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a84:	06f70363          	beq	a4,a5,80002aea <devintr+0x80>
  }
}
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret
     (scause & 0xff) == 9){
    80002a92:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a96:	46a5                	li	a3,9
    80002a98:	fed792e3          	bne	a5,a3,80002a7c <devintr+0x12>
    int irq = plic_claim();
    80002a9c:	00003097          	auipc	ra,0x3
    80002aa0:	62c080e7          	jalr	1580(ra) # 800060c8 <plic_claim>
    80002aa4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa6:	47a9                	li	a5,10
    80002aa8:	02f50763          	beq	a0,a5,80002ad6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aac:	4785                	li	a5,1
    80002aae:	02f50963          	beq	a0,a5,80002ae0 <devintr+0x76>
    return 1;
    80002ab2:	4505                	li	a0,1
    } else if(irq){
    80002ab4:	d8f1                	beqz	s1,80002a88 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab6:	85a6                	mv	a1,s1
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	85050513          	addi	a0,a0,-1968 # 80008308 <states.0+0x38>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	aca080e7          	jalr	-1334(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	00003097          	auipc	ra,0x3
    80002ace:	622080e7          	jalr	1570(ra) # 800060ec <plic_complete>
    return 1;
    80002ad2:	4505                	li	a0,1
    80002ad4:	bf55                	j	80002a88 <devintr+0x1e>
      uartintr();
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ec2080e7          	jalr	-318(ra) # 80000998 <uartintr>
    80002ade:	b7ed                	j	80002ac8 <devintr+0x5e>
      virtio_disk_intr();
    80002ae0:	00004097          	auipc	ra,0x4
    80002ae4:	ad4080e7          	jalr	-1324(ra) # 800065b4 <virtio_disk_intr>
    80002ae8:	b7c5                	j	80002ac8 <devintr+0x5e>
    if(cpuid() == 0){
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	f34080e7          	jalr	-204(ra) # 80001a1e <cpuid>
    80002af2:	c901                	beqz	a0,80002b02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002afa:	14479073          	csrw	sip,a5
    return 2;
    80002afe:	4509                	li	a0,2
    80002b00:	b761                	j	80002a88 <devintr+0x1e>
      clockintr();
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	f22080e7          	jalr	-222(ra) # 80002a24 <clockintr>
    80002b0a:	b7ed                	j	80002af4 <devintr+0x8a>

0000000080002b0c <usertrap>:
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	e04a                	sd	s2,0(sp)
    80002b16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b1c:	1007f793          	andi	a5,a5,256
    80002b20:	e3b1                	bnez	a5,80002b64 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b22:	00003797          	auipc	a5,0x3
    80002b26:	49e78793          	addi	a5,a5,1182 # 80005fc0 <kernelvec>
    80002b2a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	f1c080e7          	jalr	-228(ra) # 80001a4a <myproc>
    80002b36:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b38:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3a:	14102773          	csrr	a4,sepc
    80002b3e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b40:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b44:	47a1                	li	a5,8
    80002b46:	02f70763          	beq	a4,a5,80002b74 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	f20080e7          	jalr	-224(ra) # 80002a6a <devintr>
    80002b52:	892a                	mv	s2,a0
    80002b54:	c151                	beqz	a0,80002bd8 <usertrap+0xcc>
  if(killed(p))
    80002b56:	8526                	mv	a0,s1
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	a72080e7          	jalr	-1422(ra) # 800025ca <killed>
    80002b60:	c929                	beqz	a0,80002bb2 <usertrap+0xa6>
    80002b62:	a099                	j	80002ba8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b64:	00005517          	auipc	a0,0x5
    80002b68:	7c450513          	addi	a0,a0,1988 # 80008328 <states.0+0x58>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	9d4080e7          	jalr	-1580(ra) # 80000540 <panic>
    if(killed(p))
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	a56080e7          	jalr	-1450(ra) # 800025ca <killed>
    80002b7c:	e921                	bnez	a0,80002bcc <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b7e:	70b8                	ld	a4,96(s1)
    80002b80:	6f1c                	ld	a5,24(a4)
    80002b82:	0791                	addi	a5,a5,4
    80002b84:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	39c080e7          	jalr	924(ra) # 80002f2e <syscall>
  if(killed(p))
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	a2e080e7          	jalr	-1490(ra) # 800025ca <killed>
    80002ba4:	c911                	beqz	a0,80002bb8 <usertrap+0xac>
    80002ba6:	4901                	li	s2,0
    exit(-1);
    80002ba8:	557d                	li	a0,-1
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	8ac080e7          	jalr	-1876(ra) # 80002456 <exit>
  if(which_dev == 2)
    80002bb2:	4789                	li	a5,2
    80002bb4:	04f90f63          	beq	s2,a5,80002c12 <usertrap+0x106>
  usertrapret();
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	dd6080e7          	jalr	-554(ra) # 8000298e <usertrapret>
}
    80002bc0:	60e2                	ld	ra,24(sp)
    80002bc2:	6442                	ld	s0,16(sp)
    80002bc4:	64a2                	ld	s1,8(sp)
    80002bc6:	6902                	ld	s2,0(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
      exit(-1);
    80002bcc:	557d                	li	a0,-1
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	888080e7          	jalr	-1912(ra) # 80002456 <exit>
    80002bd6:	b765                	j	80002b7e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bdc:	5890                	lw	a2,48(s1)
    80002bde:	00005517          	auipc	a0,0x5
    80002be2:	76a50513          	addi	a0,a0,1898 # 80008348 <states.0+0x78>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	9a4080e7          	jalr	-1628(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	78250513          	addi	a0,a0,1922 # 80008378 <states.0+0xa8>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	98c080e7          	jalr	-1652(ra) # 8000058a <printf>
    setkilled(p);
    80002c06:	8526                	mv	a0,s1
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	996080e7          	jalr	-1642(ra) # 8000259e <setkilled>
    80002c10:	b769                	j	80002b9a <usertrap+0x8e>
      yield();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	6d4080e7          	jalr	1748(ra) # 800022e6 <yield>
    80002c1a:	bf79                	j	80002bb8 <usertrap+0xac>

0000000080002c1c <kerneltrap>:
{
    80002c1c:	7179                	addi	sp,sp,-48
    80002c1e:	f406                	sd	ra,40(sp)
    80002c20:	f022                	sd	s0,32(sp)
    80002c22:	ec26                	sd	s1,24(sp)
    80002c24:	e84a                	sd	s2,16(sp)
    80002c26:	e44e                	sd	s3,8(sp)
    80002c28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c36:	1004f793          	andi	a5,s1,256
    80002c3a:	cb85                	beqz	a5,80002c6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c42:	ef85                	bnez	a5,80002c7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	e26080e7          	jalr	-474(ra) # 80002a6a <devintr>
    80002c4c:	cd1d                	beqz	a0,80002c8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c4e:	4789                	li	a5,2
    80002c50:	06f50a63          	beq	a0,a5,80002cc4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c58:	10049073          	csrw	sstatus,s1
}
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6942                	ld	s2,16(sp)
    80002c64:	69a2                	ld	s3,8(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	72e50513          	addi	a0,a0,1838 # 80008398 <states.0+0xc8>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	74650513          	addi	a0,a0,1862 # 800083c0 <states.0+0xf0>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c8a:	85ce                	mv	a1,s3
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	75450513          	addi	a0,a0,1876 # 800083e0 <states.0+0x110>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8f6080e7          	jalr	-1802(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	74c50513          	addi	a0,a0,1868 # 800083f0 <states.0+0x120>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8de080e7          	jalr	-1826(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	75450513          	addi	a0,a0,1876 # 80008408 <states.0+0x138>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	884080e7          	jalr	-1916(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	d86080e7          	jalr	-634(ra) # 80001a4a <myproc>
    80002ccc:	d541                	beqz	a0,80002c54 <kerneltrap+0x38>
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	d7c080e7          	jalr	-644(ra) # 80001a4a <myproc>
    80002cd6:	4d18                	lw	a4,24(a0)
    80002cd8:	4791                	li	a5,4
    80002cda:	f6f71de3          	bne	a4,a5,80002c54 <kerneltrap+0x38>
      yield();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	608080e7          	jalr	1544(ra) # 800022e6 <yield>
    80002ce6:	b7bd                	j	80002c54 <kerneltrap+0x38>

0000000080002ce8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce8:	1101                	addi	sp,sp,-32
    80002cea:	ec06                	sd	ra,24(sp)
    80002cec:	e822                	sd	s0,16(sp)
    80002cee:	e426                	sd	s1,8(sp)
    80002cf0:	1000                	addi	s0,sp,32
    80002cf2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	d56080e7          	jalr	-682(ra) # 80001a4a <myproc>
  switch (n)
    80002cfc:	4795                	li	a5,5
    80002cfe:	0497e163          	bltu	a5,s1,80002d40 <argraw+0x58>
    80002d02:	048a                	slli	s1,s1,0x2
    80002d04:	00006717          	auipc	a4,0x6
    80002d08:	82c70713          	addi	a4,a4,-2004 # 80008530 <states.0+0x260>
    80002d0c:	94ba                	add	s1,s1,a4
    80002d0e:	409c                	lw	a5,0(s1)
    80002d10:	97ba                	add	a5,a5,a4
    80002d12:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d14:	713c                	ld	a5,96(a0)
    80002d16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret
    return p->trapframe->a1;
    80002d22:	713c                	ld	a5,96(a0)
    80002d24:	7fa8                	ld	a0,120(a5)
    80002d26:	bfcd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a2;
    80002d28:	713c                	ld	a5,96(a0)
    80002d2a:	63c8                	ld	a0,128(a5)
    80002d2c:	b7f5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a3;
    80002d2e:	713c                	ld	a5,96(a0)
    80002d30:	67c8                	ld	a0,136(a5)
    80002d32:	b7dd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a4;
    80002d34:	713c                	ld	a5,96(a0)
    80002d36:	6bc8                	ld	a0,144(a5)
    80002d38:	b7c5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a5;
    80002d3a:	713c                	ld	a5,96(a0)
    80002d3c:	6fc8                	ld	a0,152(a5)
    80002d3e:	bfe9                	j	80002d18 <argraw+0x30>
  panic("argraw");
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	6d850513          	addi	a0,a0,1752 # 80008418 <states.0+0x148>
    80002d48:	ffffd097          	auipc	ra,0xffffd
    80002d4c:	7f8080e7          	jalr	2040(ra) # 80000540 <panic>

0000000080002d50 <fetchaddr>:
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	e04a                	sd	s2,0(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84aa                	mv	s1,a0
    80002d5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	cea080e7          	jalr	-790(ra) # 80001a4a <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d68:	653c                	ld	a5,72(a0)
    80002d6a:	02f4f863          	bgeu	s1,a5,80002d9a <fetchaddr+0x4a>
    80002d6e:	00848713          	addi	a4,s1,8
    80002d72:	02e7e663          	bltu	a5,a4,80002d9e <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d76:	46a1                	li	a3,8
    80002d78:	8626                	mv	a2,s1
    80002d7a:	85ca                	mv	a1,s2
    80002d7c:	6d28                	ld	a0,88(a0)
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	97a080e7          	jalr	-1670(ra) # 800016f8 <copyin>
    80002d86:	00a03533          	snez	a0,a0
    80002d8a:	40a00533          	neg	a0,a0
}
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	64a2                	ld	s1,8(sp)
    80002d94:	6902                	ld	s2,0(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret
    return -1;
    80002d9a:	557d                	li	a0,-1
    80002d9c:	bfcd                	j	80002d8e <fetchaddr+0x3e>
    80002d9e:	557d                	li	a0,-1
    80002da0:	b7fd                	j	80002d8e <fetchaddr+0x3e>

0000000080002da2 <fetchstr>:
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	e84a                	sd	s2,16(sp)
    80002dac:	e44e                	sd	s3,8(sp)
    80002dae:	1800                	addi	s0,sp,48
    80002db0:	892a                	mv	s2,a0
    80002db2:	84ae                	mv	s1,a1
    80002db4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	c94080e7          	jalr	-876(ra) # 80001a4a <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002dbe:	86ce                	mv	a3,s3
    80002dc0:	864a                	mv	a2,s2
    80002dc2:	85a6                	mv	a1,s1
    80002dc4:	6d28                	ld	a0,88(a0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	9c0080e7          	jalr	-1600(ra) # 80001786 <copyinstr>
    80002dce:	00054e63          	bltz	a0,80002dea <fetchstr+0x48>
  return strlen(buf);
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	07a080e7          	jalr	122(ra) # 80000e4e <strlen>
}
    80002ddc:	70a2                	ld	ra,40(sp)
    80002dde:	7402                	ld	s0,32(sp)
    80002de0:	64e2                	ld	s1,24(sp)
    80002de2:	6942                	ld	s2,16(sp)
    80002de4:	69a2                	ld	s3,8(sp)
    80002de6:	6145                	addi	sp,sp,48
    80002de8:	8082                	ret
    return -1;
    80002dea:	557d                	li	a0,-1
    80002dec:	bfc5                	j	80002ddc <fetchstr+0x3a>

0000000080002dee <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	e426                	sd	s1,8(sp)
    80002df6:	1000                	addi	s0,sp,32
    80002df8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	eee080e7          	jalr	-274(ra) # 80002ce8 <argraw>
    80002e02:	c088                	sw	a0,0(s1)
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	e426                	sd	s1,8(sp)
    80002e16:	1000                	addi	s0,sp,32
    80002e18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	ece080e7          	jalr	-306(ra) # 80002ce8 <argraw>
    80002e22:	e088                	sd	a0,0(s1)
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e2e:	7179                	addi	sp,sp,-48
    80002e30:	f406                	sd	ra,40(sp)
    80002e32:	f022                	sd	s0,32(sp)
    80002e34:	ec26                	sd	s1,24(sp)
    80002e36:	e84a                	sd	s2,16(sp)
    80002e38:	1800                	addi	s0,sp,48
    80002e3a:	84ae                	mv	s1,a1
    80002e3c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e3e:	fd840593          	addi	a1,s0,-40
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	fcc080e7          	jalr	-52(ra) # 80002e0e <argaddr>
  return fetchstr(addr, buf, max);
    80002e4a:	864a                	mv	a2,s2
    80002e4c:	85a6                	mv	a1,s1
    80002e4e:	fd843503          	ld	a0,-40(s0)
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	f50080e7          	jalr	-176(ra) # 80002da2 <fetchstr>
}
    80002e5a:	70a2                	ld	ra,40(sp)
    80002e5c:	7402                	ld	s0,32(sp)
    80002e5e:	64e2                	ld	s1,24(sp)
    80002e60:	6942                	ld	s2,16(sp)
    80002e62:	6145                	addi	sp,sp,48
    80002e64:	8082                	ret

0000000080002e66 <prompt_strace>:
    [SYS_strace].numArgs = 1,
    [SYS_settickets].numArgs = 1,
};

void prompt_strace(struct proc *p, int num)
{
    80002e66:	715d                	addi	sp,sp,-80
    80002e68:	e486                	sd	ra,72(sp)
    80002e6a:	e0a2                	sd	s0,64(sp)
    80002e6c:	fc26                	sd	s1,56(sp)
    80002e6e:	f84a                	sd	s2,48(sp)
    80002e70:	f44e                	sd	s3,40(sp)
    80002e72:	f052                	sd	s4,32(sp)
    80002e74:	ec56                	sd	s5,24(sp)
    80002e76:	0880                	addi	s0,sp,80
    80002e78:	8a2a                	mv	s4,a0
    80002e7a:	892e                	mv	s2,a1
  printf("%d: syscall %s (", p->pid, syscall_info[num].name);
    80002e7c:	00459793          	slli	a5,a1,0x4
    80002e80:	00006497          	auipc	s1,0x6
    80002e84:	b1848493          	addi	s1,s1,-1256 # 80008998 <syscall_info>
    80002e88:	94be                	add	s1,s1,a5
    80002e8a:	6090                	ld	a2,0(s1)
    80002e8c:	590c                	lw	a1,48(a0)
    80002e8e:	00005517          	auipc	a0,0x5
    80002e92:	59250513          	addi	a0,a0,1426 # 80008420 <states.0+0x150>
    80002e96:	ffffd097          	auipc	ra,0xffffd
    80002e9a:	6f4080e7          	jalr	1780(ra) # 8000058a <printf>
  int arg;
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80002e9e:	449c                	lw	a5,8(s1)
    80002ea0:	06f05363          	blez	a5,80002f06 <prompt_strace+0xa0>
    80002ea4:	4481                	li	s1,0
  {
    argint(i, &arg);
    if (i == syscall_info[num].numArgs - 1)
    80002ea6:	00491593          	slli	a1,s2,0x4
    80002eaa:	00006917          	auipc	s2,0x6
    80002eae:	aee90913          	addi	s2,s2,-1298 # 80008998 <syscall_info>
    80002eb2:	992e                	add	s2,s2,a1
      printf("%d", arg);
    else
      printf("%d ", arg);
    80002eb4:	00005997          	auipc	s3,0x5
    80002eb8:	58c98993          	addi	s3,s3,1420 # 80008440 <states.0+0x170>
      printf("%d", arg);
    80002ebc:	00005a97          	auipc	s5,0x5
    80002ec0:	57ca8a93          	addi	s5,s5,1404 # 80008438 <states.0+0x168>
    80002ec4:	a829                	j	80002ede <prompt_strace+0x78>
    80002ec6:	fbc42583          	lw	a1,-68(s0)
    80002eca:	8556                	mv	a0,s5
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6be080e7          	jalr	1726(ra) # 8000058a <printf>
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80002ed4:	2485                	addiw	s1,s1,1
    80002ed6:	00892783          	lw	a5,8(s2)
    80002eda:	02f4d663          	bge	s1,a5,80002f06 <prompt_strace+0xa0>
    argint(i, &arg);
    80002ede:	fbc40593          	addi	a1,s0,-68
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	f0a080e7          	jalr	-246(ra) # 80002dee <argint>
    if (i == syscall_info[num].numArgs - 1)
    80002eec:	00892783          	lw	a5,8(s2)
    80002ef0:	37fd                	addiw	a5,a5,-1
    80002ef2:	fc978ae3          	beq	a5,s1,80002ec6 <prompt_strace+0x60>
      printf("%d ", arg);
    80002ef6:	fbc42583          	lw	a1,-68(s0)
    80002efa:	854e                	mv	a0,s3
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	68e080e7          	jalr	1678(ra) # 8000058a <printf>
    80002f04:	bfc1                	j	80002ed4 <prompt_strace+0x6e>
  }
  printf(") -> %d\n", p->trapframe->a0);
    80002f06:	060a3783          	ld	a5,96(s4)
    80002f0a:	7bac                	ld	a1,112(a5)
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	53c50513          	addi	a0,a0,1340 # 80008448 <states.0+0x178>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	676080e7          	jalr	1654(ra) # 8000058a <printf>
  return;
}
    80002f1c:	60a6                	ld	ra,72(sp)
    80002f1e:	6406                	ld	s0,64(sp)
    80002f20:	74e2                	ld	s1,56(sp)
    80002f22:	7942                	ld	s2,48(sp)
    80002f24:	79a2                	ld	s3,40(sp)
    80002f26:	7a02                	ld	s4,32(sp)
    80002f28:	6ae2                	ld	s5,24(sp)
    80002f2a:	6161                	addi	sp,sp,80
    80002f2c:	8082                	ret

0000000080002f2e <syscall>:

void syscall(void)
{
    80002f2e:	7179                	addi	sp,sp,-48
    80002f30:	f406                	sd	ra,40(sp)
    80002f32:	f022                	sd	s0,32(sp)
    80002f34:	ec26                	sd	s1,24(sp)
    80002f36:	e84a                	sd	s2,16(sp)
    80002f38:	e44e                	sd	s3,8(sp)
    80002f3a:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	b0e080e7          	jalr	-1266(ra) # 80001a4a <myproc>
    80002f44:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f46:	06053983          	ld	s3,96(a0)
    80002f4a:	0a89b783          	ld	a5,168(s3)
    80002f4e:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f52:	37fd                	addiw	a5,a5,-1
    80002f54:	4759                	li	a4,22
    80002f56:	02f76b63          	bltu	a4,a5,80002f8c <syscall+0x5e>
    80002f5a:	00391713          	slli	a4,s2,0x3
    80002f5e:	00005797          	auipc	a5,0x5
    80002f62:	5ea78793          	addi	a5,a5,1514 # 80008548 <syscalls>
    80002f66:	97ba                	add	a5,a5,a4
    80002f68:	639c                	ld	a5,0(a5)
    80002f6a:	c7b9                	beqz	a5,80002fb8 <syscall+0x8a>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f6c:	9782                	jalr	a5
    80002f6e:	06a9b823          	sd	a0,112(s3)
  {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }

  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && ((p->strace_bit>>num) & 1))
    80002f72:	1704a783          	lw	a5,368(s1)
    80002f76:	0127d7bb          	srlw	a5,a5,s2
    80002f7a:	8b85                	andi	a5,a5,1
    80002f7c:	c79d                	beqz	a5,80002faa <syscall+0x7c>
  {
    prompt_strace(p, num);
    80002f7e:	85ca                	mv	a1,s2
    80002f80:	8526                	mv	a0,s1
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	ee4080e7          	jalr	-284(ra) # 80002e66 <prompt_strace>
  }
  return;
    80002f8a:	a005                	j	80002faa <syscall+0x7c>
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80002f8c:	86ca                	mv	a3,s2
    80002f8e:	16050613          	addi	a2,a0,352
    80002f92:	590c                	lw	a1,48(a0)
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	4c450513          	addi	a0,a0,1220 # 80008458 <states.0+0x188>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	5ee080e7          	jalr	1518(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80002fa4:	70bc                	ld	a5,96(s1)
    80002fa6:	577d                	li	a4,-1
    80002fa8:	fbb8                	sd	a4,112(a5)
}
    80002faa:	70a2                	ld	ra,40(sp)
    80002fac:	7402                	ld	s0,32(sp)
    80002fae:	64e2                	ld	s1,24(sp)
    80002fb0:	6942                	ld	s2,16(sp)
    80002fb2:	69a2                	ld	s3,8(sp)
    80002fb4:	6145                	addi	sp,sp,48
    80002fb6:	8082                	ret
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80002fb8:	86ca                	mv	a3,s2
    80002fba:	16050613          	addi	a2,a0,352
    80002fbe:	590c                	lw	a1,48(a0)
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	49850513          	addi	a0,a0,1176 # 80008458 <states.0+0x188>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	5c2080e7          	jalr	1474(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80002fd0:	70bc                	ld	a5,96(s1)
    80002fd2:	577d                	li	a4,-1
    80002fd4:	fbb8                	sd	a4,112(a5)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && ((p->strace_bit>>num) & 1))
    80002fd6:	00391713          	slli	a4,s2,0x3
    80002fda:	00005797          	auipc	a5,0x5
    80002fde:	56e78793          	addi	a5,a5,1390 # 80008548 <syscalls>
    80002fe2:	97ba                	add	a5,a5,a4
    80002fe4:	639c                	ld	a5,0(a5)
    80002fe6:	d3f1                	beqz	a5,80002faa <syscall+0x7c>
    80002fe8:	b769                	j	80002f72 <syscall+0x44>

0000000080002fea <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fea:	1101                	addi	sp,sp,-32
    80002fec:	ec06                	sd	ra,24(sp)
    80002fee:	e822                	sd	s0,16(sp)
    80002ff0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ff2:	fec40593          	addi	a1,s0,-20
    80002ff6:	4501                	li	a0,0
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	df6080e7          	jalr	-522(ra) # 80002dee <argint>
  exit(n);
    80003000:	fec42503          	lw	a0,-20(s0)
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	452080e7          	jalr	1106(ra) # 80002456 <exit>
  return 0;  // not reached
}
    8000300c:	4501                	li	a0,0
    8000300e:	60e2                	ld	ra,24(sp)
    80003010:	6442                	ld	s0,16(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003016:	1141                	addi	sp,sp,-16
    80003018:	e406                	sd	ra,8(sp)
    8000301a:	e022                	sd	s0,0(sp)
    8000301c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	a2c080e7          	jalr	-1492(ra) # 80001a4a <myproc>
}
    80003026:	5908                	lw	a0,48(a0)
    80003028:	60a2                	ld	ra,8(sp)
    8000302a:	6402                	ld	s0,0(sp)
    8000302c:	0141                	addi	sp,sp,16
    8000302e:	8082                	ret

0000000080003030 <sys_fork>:

uint64
sys_fork(void)
{
    80003030:	1141                	addi	sp,sp,-16
    80003032:	e406                	sd	ra,8(sp)
    80003034:	e022                	sd	s0,0(sp)
    80003036:	0800                	addi	s0,sp,16
  return fork();
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	dee080e7          	jalr	-530(ra) # 80001e26 <fork>
}
    80003040:	60a2                	ld	ra,8(sp)
    80003042:	6402                	ld	s0,0(sp)
    80003044:	0141                	addi	sp,sp,16
    80003046:	8082                	ret

0000000080003048 <sys_wait>:

uint64
sys_wait(void)
{
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003050:	fe840593          	addi	a1,s0,-24
    80003054:	4501                	li	a0,0
    80003056:	00000097          	auipc	ra,0x0
    8000305a:	db8080e7          	jalr	-584(ra) # 80002e0e <argaddr>
  return wait(p);
    8000305e:	fe843503          	ld	a0,-24(s0)
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	59a080e7          	jalr	1434(ra) # 800025fc <wait>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003072:	7179                	addi	sp,sp,-48
    80003074:	f406                	sd	ra,40(sp)
    80003076:	f022                	sd	s0,32(sp)
    80003078:	ec26                	sd	s1,24(sp)
    8000307a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000307c:	fdc40593          	addi	a1,s0,-36
    80003080:	4501                	li	a0,0
    80003082:	00000097          	auipc	ra,0x0
    80003086:	d6c080e7          	jalr	-660(ra) # 80002dee <argint>
  addr = myproc()->sz;
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	9c0080e7          	jalr	-1600(ra) # 80001a4a <myproc>
    80003092:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003094:	fdc42503          	lw	a0,-36(s0)
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	d32080e7          	jalr	-718(ra) # 80001dca <growproc>
    800030a0:	00054863          	bltz	a0,800030b0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030a4:	8526                	mv	a0,s1
    800030a6:	70a2                	ld	ra,40(sp)
    800030a8:	7402                	ld	s0,32(sp)
    800030aa:	64e2                	ld	s1,24(sp)
    800030ac:	6145                	addi	sp,sp,48
    800030ae:	8082                	ret
    return -1;
    800030b0:	54fd                	li	s1,-1
    800030b2:	bfcd                	j	800030a4 <sys_sbrk+0x32>

00000000800030b4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030b4:	7139                	addi	sp,sp,-64
    800030b6:	fc06                	sd	ra,56(sp)
    800030b8:	f822                	sd	s0,48(sp)
    800030ba:	f426                	sd	s1,40(sp)
    800030bc:	f04a                	sd	s2,32(sp)
    800030be:	ec4e                	sd	s3,24(sp)
    800030c0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030c2:	fcc40593          	addi	a1,s0,-52
    800030c6:	4501                	li	a0,0
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	d26080e7          	jalr	-730(ra) # 80002dee <argint>
  acquire(&tickslock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	34050513          	addi	a0,a0,832 # 80017410 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	afe080e7          	jalr	-1282(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800030e0:	00006917          	auipc	s2,0x6
    800030e4:	a9092903          	lw	s2,-1392(s2) # 80008b70 <ticks>
  while(ticks - ticks0 < n){
    800030e8:	fcc42783          	lw	a5,-52(s0)
    800030ec:	cf9d                	beqz	a5,8000312a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030ee:	00014997          	auipc	s3,0x14
    800030f2:	32298993          	addi	s3,s3,802 # 80017410 <tickslock>
    800030f6:	00006497          	auipc	s1,0x6
    800030fa:	a7a48493          	addi	s1,s1,-1414 # 80008b70 <ticks>
    if(killed(myproc())){
    800030fe:	fffff097          	auipc	ra,0xfffff
    80003102:	94c080e7          	jalr	-1716(ra) # 80001a4a <myproc>
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	4c4080e7          	jalr	1220(ra) # 800025ca <killed>
    8000310e:	ed15                	bnez	a0,8000314a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003110:	85ce                	mv	a1,s3
    80003112:	8526                	mv	a0,s1
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	20e080e7          	jalr	526(ra) # 80002322 <sleep>
  while(ticks - ticks0 < n){
    8000311c:	409c                	lw	a5,0(s1)
    8000311e:	412787bb          	subw	a5,a5,s2
    80003122:	fcc42703          	lw	a4,-52(s0)
    80003126:	fce7ece3          	bltu	a5,a4,800030fe <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	2e650513          	addi	a0,a0,742 # 80017410 <tickslock>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b58080e7          	jalr	-1192(ra) # 80000c8a <release>
  return 0;
    8000313a:	4501                	li	a0,0
}
    8000313c:	70e2                	ld	ra,56(sp)
    8000313e:	7442                	ld	s0,48(sp)
    80003140:	74a2                	ld	s1,40(sp)
    80003142:	7902                	ld	s2,32(sp)
    80003144:	69e2                	ld	s3,24(sp)
    80003146:	6121                	addi	sp,sp,64
    80003148:	8082                	ret
      release(&tickslock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	2c650513          	addi	a0,a0,710 # 80017410 <tickslock>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b38080e7          	jalr	-1224(ra) # 80000c8a <release>
      return -1;
    8000315a:	557d                	li	a0,-1
    8000315c:	b7c5                	j	8000313c <sys_sleep+0x88>

000000008000315e <sys_kill>:

uint64
sys_kill(void)
{
    8000315e:	1101                	addi	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003166:	fec40593          	addi	a1,s0,-20
    8000316a:	4501                	li	a0,0
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	c82080e7          	jalr	-894(ra) # 80002dee <argint>
  return kill(pid);
    80003174:	fec42503          	lw	a0,-20(s0)
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	3b4080e7          	jalr	948(ra) # 8000252c <kill>
}
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	e426                	sd	s1,8(sp)
    80003190:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003192:	00014517          	auipc	a0,0x14
    80003196:	27e50513          	addi	a0,a0,638 # 80017410 <tickslock>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	a3c080e7          	jalr	-1476(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800031a2:	00006497          	auipc	s1,0x6
    800031a6:	9ce4a483          	lw	s1,-1586(s1) # 80008b70 <ticks>
  release(&tickslock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	26650513          	addi	a0,a0,614 # 80017410 <tickslock>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
  return xticks;
}
    800031ba:	02049513          	slli	a0,s1,0x20
    800031be:	9101                	srli	a0,a0,0x20
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret

00000000800031ca <sys_strace>:

uint64
sys_strace(void)
{
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031d2:	fec40593          	addi	a1,s0,-20
    800031d6:	4501                	li	a0,0
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	c16080e7          	jalr	-1002(ra) # 80002dee <argint>
  strace(n);
    800031e0:	fec42503          	lw	a0,-20(s0)
    800031e4:	fffff097          	auipc	ra,0xfffff
    800031e8:	6a2080e7          	jalr	1698(ra) # 80002886 <strace>
  return 0;
}
    800031ec:	4501                	li	a0,0
    800031ee:	60e2                	ld	ra,24(sp)
    800031f0:	6442                	ld	s0,16(sp)
    800031f2:	6105                	addi	sp,sp,32
    800031f4:	8082                	ret

00000000800031f6 <sys_settickets>:

uint64
sys_settickets(void)
{
    800031f6:	1101                	addi	sp,sp,-32
    800031f8:	ec06                	sd	ra,24(sp)
    800031fa:	e822                	sd	s0,16(sp)
    800031fc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031fe:	fec40593          	addi	a1,s0,-20
    80003202:	4501                	li	a0,0
    80003204:	00000097          	auipc	ra,0x0
    80003208:	bea080e7          	jalr	-1046(ra) # 80002dee <argint>
  int m = settickets(n);
    8000320c:	fec42503          	lw	a0,-20(s0)
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	6a2080e7          	jalr	1698(ra) # 800028b2 <settickets>

  if(m == n)  // correct number of tickets set
    80003218:	fec42783          	lw	a5,-20(s0)
    8000321c:	40a78533          	sub	a0,a5,a0
    80003220:	00a03533          	snez	a0,a0
    return 0;
  return -1;
}
    80003224:	40a00533          	neg	a0,a0
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret

0000000080003230 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003230:	7179                	addi	sp,sp,-48
    80003232:	f406                	sd	ra,40(sp)
    80003234:	f022                	sd	s0,32(sp)
    80003236:	ec26                	sd	s1,24(sp)
    80003238:	e84a                	sd	s2,16(sp)
    8000323a:	e44e                	sd	s3,8(sp)
    8000323c:	e052                	sd	s4,0(sp)
    8000323e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003240:	00005597          	auipc	a1,0x5
    80003244:	3c858593          	addi	a1,a1,968 # 80008608 <syscalls+0xc0>
    80003248:	00014517          	auipc	a0,0x14
    8000324c:	1e050513          	addi	a0,a0,480 # 80017428 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	8f6080e7          	jalr	-1802(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003258:	0001c797          	auipc	a5,0x1c
    8000325c:	1d078793          	addi	a5,a5,464 # 8001f428 <bcache+0x8000>
    80003260:	0001c717          	auipc	a4,0x1c
    80003264:	43070713          	addi	a4,a4,1072 # 8001f690 <bcache+0x8268>
    80003268:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000326c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003270:	00014497          	auipc	s1,0x14
    80003274:	1d048493          	addi	s1,s1,464 # 80017440 <bcache+0x18>
    b->next = bcache.head.next;
    80003278:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000327a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000327c:	00005a17          	auipc	s4,0x5
    80003280:	394a0a13          	addi	s4,s4,916 # 80008610 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003284:	2b893783          	ld	a5,696(s2)
    80003288:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000328a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000328e:	85d2                	mv	a1,s4
    80003290:	01048513          	addi	a0,s1,16
    80003294:	00001097          	auipc	ra,0x1
    80003298:	4c8080e7          	jalr	1224(ra) # 8000475c <initsleeplock>
    bcache.head.next->prev = b;
    8000329c:	2b893783          	ld	a5,696(s2)
    800032a0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032a2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032a6:	45848493          	addi	s1,s1,1112
    800032aa:	fd349de3          	bne	s1,s3,80003284 <binit+0x54>
  }
}
    800032ae:	70a2                	ld	ra,40(sp)
    800032b0:	7402                	ld	s0,32(sp)
    800032b2:	64e2                	ld	s1,24(sp)
    800032b4:	6942                	ld	s2,16(sp)
    800032b6:	69a2                	ld	s3,8(sp)
    800032b8:	6a02                	ld	s4,0(sp)
    800032ba:	6145                	addi	sp,sp,48
    800032bc:	8082                	ret

00000000800032be <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032be:	7179                	addi	sp,sp,-48
    800032c0:	f406                	sd	ra,40(sp)
    800032c2:	f022                	sd	s0,32(sp)
    800032c4:	ec26                	sd	s1,24(sp)
    800032c6:	e84a                	sd	s2,16(sp)
    800032c8:	e44e                	sd	s3,8(sp)
    800032ca:	1800                	addi	s0,sp,48
    800032cc:	892a                	mv	s2,a0
    800032ce:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032d0:	00014517          	auipc	a0,0x14
    800032d4:	15850513          	addi	a0,a0,344 # 80017428 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032e0:	0001c497          	auipc	s1,0x1c
    800032e4:	4004b483          	ld	s1,1024(s1) # 8001f6e0 <bcache+0x82b8>
    800032e8:	0001c797          	auipc	a5,0x1c
    800032ec:	3a878793          	addi	a5,a5,936 # 8001f690 <bcache+0x8268>
    800032f0:	02f48f63          	beq	s1,a5,8000332e <bread+0x70>
    800032f4:	873e                	mv	a4,a5
    800032f6:	a021                	j	800032fe <bread+0x40>
    800032f8:	68a4                	ld	s1,80(s1)
    800032fa:	02e48a63          	beq	s1,a4,8000332e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032fe:	449c                	lw	a5,8(s1)
    80003300:	ff279ce3          	bne	a5,s2,800032f8 <bread+0x3a>
    80003304:	44dc                	lw	a5,12(s1)
    80003306:	ff3799e3          	bne	a5,s3,800032f8 <bread+0x3a>
      b->refcnt++;
    8000330a:	40bc                	lw	a5,64(s1)
    8000330c:	2785                	addiw	a5,a5,1
    8000330e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003310:	00014517          	auipc	a0,0x14
    80003314:	11850513          	addi	a0,a0,280 # 80017428 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003320:	01048513          	addi	a0,s1,16
    80003324:	00001097          	auipc	ra,0x1
    80003328:	472080e7          	jalr	1138(ra) # 80004796 <acquiresleep>
      return b;
    8000332c:	a8b9                	j	8000338a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000332e:	0001c497          	auipc	s1,0x1c
    80003332:	3aa4b483          	ld	s1,938(s1) # 8001f6d8 <bcache+0x82b0>
    80003336:	0001c797          	auipc	a5,0x1c
    8000333a:	35a78793          	addi	a5,a5,858 # 8001f690 <bcache+0x8268>
    8000333e:	00f48863          	beq	s1,a5,8000334e <bread+0x90>
    80003342:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003344:	40bc                	lw	a5,64(s1)
    80003346:	cf81                	beqz	a5,8000335e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003348:	64a4                	ld	s1,72(s1)
    8000334a:	fee49de3          	bne	s1,a4,80003344 <bread+0x86>
  panic("bget: no buffers");
    8000334e:	00005517          	auipc	a0,0x5
    80003352:	2ca50513          	addi	a0,a0,714 # 80008618 <syscalls+0xd0>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	1ea080e7          	jalr	490(ra) # 80000540 <panic>
      b->dev = dev;
    8000335e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003362:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003366:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000336a:	4785                	li	a5,1
    8000336c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000336e:	00014517          	auipc	a0,0x14
    80003372:	0ba50513          	addi	a0,a0,186 # 80017428 <bcache>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000337e:	01048513          	addi	a0,s1,16
    80003382:	00001097          	auipc	ra,0x1
    80003386:	414080e7          	jalr	1044(ra) # 80004796 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000338a:	409c                	lw	a5,0(s1)
    8000338c:	cb89                	beqz	a5,8000339e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000338e:	8526                	mv	a0,s1
    80003390:	70a2                	ld	ra,40(sp)
    80003392:	7402                	ld	s0,32(sp)
    80003394:	64e2                	ld	s1,24(sp)
    80003396:	6942                	ld	s2,16(sp)
    80003398:	69a2                	ld	s3,8(sp)
    8000339a:	6145                	addi	sp,sp,48
    8000339c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000339e:	4581                	li	a1,0
    800033a0:	8526                	mv	a0,s1
    800033a2:	00003097          	auipc	ra,0x3
    800033a6:	fe0080e7          	jalr	-32(ra) # 80006382 <virtio_disk_rw>
    b->valid = 1;
    800033aa:	4785                	li	a5,1
    800033ac:	c09c                	sw	a5,0(s1)
  return b;
    800033ae:	b7c5                	j	8000338e <bread+0xd0>

00000000800033b0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	1000                	addi	s0,sp,32
    800033ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033bc:	0541                	addi	a0,a0,16
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	472080e7          	jalr	1138(ra) # 80004830 <holdingsleep>
    800033c6:	cd01                	beqz	a0,800033de <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033c8:	4585                	li	a1,1
    800033ca:	8526                	mv	a0,s1
    800033cc:	00003097          	auipc	ra,0x3
    800033d0:	fb6080e7          	jalr	-74(ra) # 80006382 <virtio_disk_rw>
}
    800033d4:	60e2                	ld	ra,24(sp)
    800033d6:	6442                	ld	s0,16(sp)
    800033d8:	64a2                	ld	s1,8(sp)
    800033da:	6105                	addi	sp,sp,32
    800033dc:	8082                	ret
    panic("bwrite");
    800033de:	00005517          	auipc	a0,0x5
    800033e2:	25250513          	addi	a0,a0,594 # 80008630 <syscalls+0xe8>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	15a080e7          	jalr	346(ra) # 80000540 <panic>

00000000800033ee <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033ee:	1101                	addi	sp,sp,-32
    800033f0:	ec06                	sd	ra,24(sp)
    800033f2:	e822                	sd	s0,16(sp)
    800033f4:	e426                	sd	s1,8(sp)
    800033f6:	e04a                	sd	s2,0(sp)
    800033f8:	1000                	addi	s0,sp,32
    800033fa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033fc:	01050913          	addi	s2,a0,16
    80003400:	854a                	mv	a0,s2
    80003402:	00001097          	auipc	ra,0x1
    80003406:	42e080e7          	jalr	1070(ra) # 80004830 <holdingsleep>
    8000340a:	c92d                	beqz	a0,8000347c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000340c:	854a                	mv	a0,s2
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	3de080e7          	jalr	990(ra) # 800047ec <releasesleep>

  acquire(&bcache.lock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	01250513          	addi	a0,a0,18 # 80017428 <bcache>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	7b8080e7          	jalr	1976(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003426:	40bc                	lw	a5,64(s1)
    80003428:	37fd                	addiw	a5,a5,-1
    8000342a:	0007871b          	sext.w	a4,a5
    8000342e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003430:	eb05                	bnez	a4,80003460 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003432:	68bc                	ld	a5,80(s1)
    80003434:	64b8                	ld	a4,72(s1)
    80003436:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003438:	64bc                	ld	a5,72(s1)
    8000343a:	68b8                	ld	a4,80(s1)
    8000343c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000343e:	0001c797          	auipc	a5,0x1c
    80003442:	fea78793          	addi	a5,a5,-22 # 8001f428 <bcache+0x8000>
    80003446:	2b87b703          	ld	a4,696(a5)
    8000344a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000344c:	0001c717          	auipc	a4,0x1c
    80003450:	24470713          	addi	a4,a4,580 # 8001f690 <bcache+0x8268>
    80003454:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003456:	2b87b703          	ld	a4,696(a5)
    8000345a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000345c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003460:	00014517          	auipc	a0,0x14
    80003464:	fc850513          	addi	a0,a0,-56 # 80017428 <bcache>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
}
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6902                	ld	s2,0(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret
    panic("brelse");
    8000347c:	00005517          	auipc	a0,0x5
    80003480:	1bc50513          	addi	a0,a0,444 # 80008638 <syscalls+0xf0>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	0bc080e7          	jalr	188(ra) # 80000540 <panic>

000000008000348c <bpin>:

void
bpin(struct buf *b) {
    8000348c:	1101                	addi	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	e426                	sd	s1,8(sp)
    80003494:	1000                	addi	s0,sp,32
    80003496:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003498:	00014517          	auipc	a0,0x14
    8000349c:	f9050513          	addi	a0,a0,-112 # 80017428 <bcache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	736080e7          	jalr	1846(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800034a8:	40bc                	lw	a5,64(s1)
    800034aa:	2785                	addiw	a5,a5,1
    800034ac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ae:	00014517          	auipc	a0,0x14
    800034b2:	f7a50513          	addi	a0,a0,-134 # 80017428 <bcache>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
}
    800034be:	60e2                	ld	ra,24(sp)
    800034c0:	6442                	ld	s0,16(sp)
    800034c2:	64a2                	ld	s1,8(sp)
    800034c4:	6105                	addi	sp,sp,32
    800034c6:	8082                	ret

00000000800034c8 <bunpin>:

void
bunpin(struct buf *b) {
    800034c8:	1101                	addi	sp,sp,-32
    800034ca:	ec06                	sd	ra,24(sp)
    800034cc:	e822                	sd	s0,16(sp)
    800034ce:	e426                	sd	s1,8(sp)
    800034d0:	1000                	addi	s0,sp,32
    800034d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034d4:	00014517          	auipc	a0,0x14
    800034d8:	f5450513          	addi	a0,a0,-172 # 80017428 <bcache>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	6fa080e7          	jalr	1786(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034e4:	40bc                	lw	a5,64(s1)
    800034e6:	37fd                	addiw	a5,a5,-1
    800034e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ea:	00014517          	auipc	a0,0x14
    800034ee:	f3e50513          	addi	a0,a0,-194 # 80017428 <bcache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	798080e7          	jalr	1944(ra) # 80000c8a <release>
}
    800034fa:	60e2                	ld	ra,24(sp)
    800034fc:	6442                	ld	s0,16(sp)
    800034fe:	64a2                	ld	s1,8(sp)
    80003500:	6105                	addi	sp,sp,32
    80003502:	8082                	ret

0000000080003504 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	e426                	sd	s1,8(sp)
    8000350c:	e04a                	sd	s2,0(sp)
    8000350e:	1000                	addi	s0,sp,32
    80003510:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003512:	00d5d59b          	srliw	a1,a1,0xd
    80003516:	0001c797          	auipc	a5,0x1c
    8000351a:	5ee7a783          	lw	a5,1518(a5) # 8001fb04 <sb+0x1c>
    8000351e:	9dbd                	addw	a1,a1,a5
    80003520:	00000097          	auipc	ra,0x0
    80003524:	d9e080e7          	jalr	-610(ra) # 800032be <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003528:	0074f713          	andi	a4,s1,7
    8000352c:	4785                	li	a5,1
    8000352e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003532:	14ce                	slli	s1,s1,0x33
    80003534:	90d9                	srli	s1,s1,0x36
    80003536:	00950733          	add	a4,a0,s1
    8000353a:	05874703          	lbu	a4,88(a4)
    8000353e:	00e7f6b3          	and	a3,a5,a4
    80003542:	c69d                	beqz	a3,80003570 <bfree+0x6c>
    80003544:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003546:	94aa                	add	s1,s1,a0
    80003548:	fff7c793          	not	a5,a5
    8000354c:	8f7d                	and	a4,a4,a5
    8000354e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003552:	00001097          	auipc	ra,0x1
    80003556:	126080e7          	jalr	294(ra) # 80004678 <log_write>
  brelse(bp);
    8000355a:	854a                	mv	a0,s2
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	e92080e7          	jalr	-366(ra) # 800033ee <brelse>
}
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	64a2                	ld	s1,8(sp)
    8000356a:	6902                	ld	s2,0(sp)
    8000356c:	6105                	addi	sp,sp,32
    8000356e:	8082                	ret
    panic("freeing free block");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	0d050513          	addi	a0,a0,208 # 80008640 <syscalls+0xf8>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fc8080e7          	jalr	-56(ra) # 80000540 <panic>

0000000080003580 <balloc>:
{
    80003580:	711d                	addi	sp,sp,-96
    80003582:	ec86                	sd	ra,88(sp)
    80003584:	e8a2                	sd	s0,80(sp)
    80003586:	e4a6                	sd	s1,72(sp)
    80003588:	e0ca                	sd	s2,64(sp)
    8000358a:	fc4e                	sd	s3,56(sp)
    8000358c:	f852                	sd	s4,48(sp)
    8000358e:	f456                	sd	s5,40(sp)
    80003590:	f05a                	sd	s6,32(sp)
    80003592:	ec5e                	sd	s7,24(sp)
    80003594:	e862                	sd	s8,16(sp)
    80003596:	e466                	sd	s9,8(sp)
    80003598:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000359a:	0001c797          	auipc	a5,0x1c
    8000359e:	5527a783          	lw	a5,1362(a5) # 8001faec <sb+0x4>
    800035a2:	cff5                	beqz	a5,8000369e <balloc+0x11e>
    800035a4:	8baa                	mv	s7,a0
    800035a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035a8:	0001cb17          	auipc	s6,0x1c
    800035ac:	540b0b13          	addi	s6,s6,1344 # 8001fae8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035b6:	6c89                	lui	s9,0x2
    800035b8:	a061                	j	80003640 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035ba:	97ca                	add	a5,a5,s2
    800035bc:	8e55                	or	a2,a2,a3
    800035be:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	0b4080e7          	jalr	180(ra) # 80004678 <log_write>
        brelse(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	e20080e7          	jalr	-480(ra) # 800033ee <brelse>
  bp = bread(dev, bno);
    800035d6:	85a6                	mv	a1,s1
    800035d8:	855e                	mv	a0,s7
    800035da:	00000097          	auipc	ra,0x0
    800035de:	ce4080e7          	jalr	-796(ra) # 800032be <bread>
    800035e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035e4:	40000613          	li	a2,1024
    800035e8:	4581                	li	a1,0
    800035ea:	05850513          	addi	a0,a0,88
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	6e4080e7          	jalr	1764(ra) # 80000cd2 <memset>
  log_write(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	080080e7          	jalr	128(ra) # 80004678 <log_write>
  brelse(bp);
    80003600:	854a                	mv	a0,s2
    80003602:	00000097          	auipc	ra,0x0
    80003606:	dec080e7          	jalr	-532(ra) # 800033ee <brelse>
}
    8000360a:	8526                	mv	a0,s1
    8000360c:	60e6                	ld	ra,88(sp)
    8000360e:	6446                	ld	s0,80(sp)
    80003610:	64a6                	ld	s1,72(sp)
    80003612:	6906                	ld	s2,64(sp)
    80003614:	79e2                	ld	s3,56(sp)
    80003616:	7a42                	ld	s4,48(sp)
    80003618:	7aa2                	ld	s5,40(sp)
    8000361a:	7b02                	ld	s6,32(sp)
    8000361c:	6be2                	ld	s7,24(sp)
    8000361e:	6c42                	ld	s8,16(sp)
    80003620:	6ca2                	ld	s9,8(sp)
    80003622:	6125                	addi	sp,sp,96
    80003624:	8082                	ret
    brelse(bp);
    80003626:	854a                	mv	a0,s2
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	dc6080e7          	jalr	-570(ra) # 800033ee <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003630:	015c87bb          	addw	a5,s9,s5
    80003634:	00078a9b          	sext.w	s5,a5
    80003638:	004b2703          	lw	a4,4(s6)
    8000363c:	06eaf163          	bgeu	s5,a4,8000369e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003640:	41fad79b          	sraiw	a5,s5,0x1f
    80003644:	0137d79b          	srliw	a5,a5,0x13
    80003648:	015787bb          	addw	a5,a5,s5
    8000364c:	40d7d79b          	sraiw	a5,a5,0xd
    80003650:	01cb2583          	lw	a1,28(s6)
    80003654:	9dbd                	addw	a1,a1,a5
    80003656:	855e                	mv	a0,s7
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	c66080e7          	jalr	-922(ra) # 800032be <bread>
    80003660:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003662:	004b2503          	lw	a0,4(s6)
    80003666:	000a849b          	sext.w	s1,s5
    8000366a:	8762                	mv	a4,s8
    8000366c:	faa4fde3          	bgeu	s1,a0,80003626 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003670:	00777693          	andi	a3,a4,7
    80003674:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003678:	41f7579b          	sraiw	a5,a4,0x1f
    8000367c:	01d7d79b          	srliw	a5,a5,0x1d
    80003680:	9fb9                	addw	a5,a5,a4
    80003682:	4037d79b          	sraiw	a5,a5,0x3
    80003686:	00f90633          	add	a2,s2,a5
    8000368a:	05864603          	lbu	a2,88(a2)
    8000368e:	00c6f5b3          	and	a1,a3,a2
    80003692:	d585                	beqz	a1,800035ba <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003694:	2705                	addiw	a4,a4,1
    80003696:	2485                	addiw	s1,s1,1
    80003698:	fd471ae3          	bne	a4,s4,8000366c <balloc+0xec>
    8000369c:	b769                	j	80003626 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000369e:	00005517          	auipc	a0,0x5
    800036a2:	fba50513          	addi	a0,a0,-70 # 80008658 <syscalls+0x110>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	ee4080e7          	jalr	-284(ra) # 8000058a <printf>
  return 0;
    800036ae:	4481                	li	s1,0
    800036b0:	bfa9                	j	8000360a <balloc+0x8a>

00000000800036b2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036b2:	7179                	addi	sp,sp,-48
    800036b4:	f406                	sd	ra,40(sp)
    800036b6:	f022                	sd	s0,32(sp)
    800036b8:	ec26                	sd	s1,24(sp)
    800036ba:	e84a                	sd	s2,16(sp)
    800036bc:	e44e                	sd	s3,8(sp)
    800036be:	e052                	sd	s4,0(sp)
    800036c0:	1800                	addi	s0,sp,48
    800036c2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036c4:	47ad                	li	a5,11
    800036c6:	02b7e863          	bltu	a5,a1,800036f6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036ca:	02059793          	slli	a5,a1,0x20
    800036ce:	01e7d593          	srli	a1,a5,0x1e
    800036d2:	00b504b3          	add	s1,a0,a1
    800036d6:	0504a903          	lw	s2,80(s1)
    800036da:	06091e63          	bnez	s2,80003756 <bmap+0xa4>
      addr = balloc(ip->dev);
    800036de:	4108                	lw	a0,0(a0)
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	ea0080e7          	jalr	-352(ra) # 80003580 <balloc>
    800036e8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036ec:	06090563          	beqz	s2,80003756 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800036f0:	0524a823          	sw	s2,80(s1)
    800036f4:	a08d                	j	80003756 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036f6:	ff45849b          	addiw	s1,a1,-12
    800036fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036fe:	0ff00793          	li	a5,255
    80003702:	08e7e563          	bltu	a5,a4,8000378c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003706:	08052903          	lw	s2,128(a0)
    8000370a:	00091d63          	bnez	s2,80003724 <bmap+0x72>
      addr = balloc(ip->dev);
    8000370e:	4108                	lw	a0,0(a0)
    80003710:	00000097          	auipc	ra,0x0
    80003714:	e70080e7          	jalr	-400(ra) # 80003580 <balloc>
    80003718:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000371c:	02090d63          	beqz	s2,80003756 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003720:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003724:	85ca                	mv	a1,s2
    80003726:	0009a503          	lw	a0,0(s3)
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	b94080e7          	jalr	-1132(ra) # 800032be <bread>
    80003732:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003734:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003738:	02049713          	slli	a4,s1,0x20
    8000373c:	01e75593          	srli	a1,a4,0x1e
    80003740:	00b784b3          	add	s1,a5,a1
    80003744:	0004a903          	lw	s2,0(s1)
    80003748:	02090063          	beqz	s2,80003768 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000374c:	8552                	mv	a0,s4
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	ca0080e7          	jalr	-864(ra) # 800033ee <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003756:	854a                	mv	a0,s2
    80003758:	70a2                	ld	ra,40(sp)
    8000375a:	7402                	ld	s0,32(sp)
    8000375c:	64e2                	ld	s1,24(sp)
    8000375e:	6942                	ld	s2,16(sp)
    80003760:	69a2                	ld	s3,8(sp)
    80003762:	6a02                	ld	s4,0(sp)
    80003764:	6145                	addi	sp,sp,48
    80003766:	8082                	ret
      addr = balloc(ip->dev);
    80003768:	0009a503          	lw	a0,0(s3)
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	e14080e7          	jalr	-492(ra) # 80003580 <balloc>
    80003774:	0005091b          	sext.w	s2,a0
      if(addr){
    80003778:	fc090ae3          	beqz	s2,8000374c <bmap+0x9a>
        a[bn] = addr;
    8000377c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003780:	8552                	mv	a0,s4
    80003782:	00001097          	auipc	ra,0x1
    80003786:	ef6080e7          	jalr	-266(ra) # 80004678 <log_write>
    8000378a:	b7c9                	j	8000374c <bmap+0x9a>
  panic("bmap: out of range");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	ee450513          	addi	a0,a0,-284 # 80008670 <syscalls+0x128>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	dac080e7          	jalr	-596(ra) # 80000540 <panic>

000000008000379c <iget>:
{
    8000379c:	7179                	addi	sp,sp,-48
    8000379e:	f406                	sd	ra,40(sp)
    800037a0:	f022                	sd	s0,32(sp)
    800037a2:	ec26                	sd	s1,24(sp)
    800037a4:	e84a                	sd	s2,16(sp)
    800037a6:	e44e                	sd	s3,8(sp)
    800037a8:	e052                	sd	s4,0(sp)
    800037aa:	1800                	addi	s0,sp,48
    800037ac:	89aa                	mv	s3,a0
    800037ae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037b0:	0001c517          	auipc	a0,0x1c
    800037b4:	35850513          	addi	a0,a0,856 # 8001fb08 <itable>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	41e080e7          	jalr	1054(ra) # 80000bd6 <acquire>
  empty = 0;
    800037c0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c2:	0001c497          	auipc	s1,0x1c
    800037c6:	35e48493          	addi	s1,s1,862 # 8001fb20 <itable+0x18>
    800037ca:	0001e697          	auipc	a3,0x1e
    800037ce:	de668693          	addi	a3,a3,-538 # 800215b0 <log>
    800037d2:	a039                	j	800037e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037d4:	02090b63          	beqz	s2,8000380a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037d8:	08848493          	addi	s1,s1,136
    800037dc:	02d48a63          	beq	s1,a3,80003810 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037e0:	449c                	lw	a5,8(s1)
    800037e2:	fef059e3          	blez	a5,800037d4 <iget+0x38>
    800037e6:	4098                	lw	a4,0(s1)
    800037e8:	ff3716e3          	bne	a4,s3,800037d4 <iget+0x38>
    800037ec:	40d8                	lw	a4,4(s1)
    800037ee:	ff4713e3          	bne	a4,s4,800037d4 <iget+0x38>
      ip->ref++;
    800037f2:	2785                	addiw	a5,a5,1
    800037f4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037f6:	0001c517          	auipc	a0,0x1c
    800037fa:	31250513          	addi	a0,a0,786 # 8001fb08 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	48c080e7          	jalr	1164(ra) # 80000c8a <release>
      return ip;
    80003806:	8926                	mv	s2,s1
    80003808:	a03d                	j	80003836 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000380a:	f7f9                	bnez	a5,800037d8 <iget+0x3c>
    8000380c:	8926                	mv	s2,s1
    8000380e:	b7e9                	j	800037d8 <iget+0x3c>
  if(empty == 0)
    80003810:	02090c63          	beqz	s2,80003848 <iget+0xac>
  ip->dev = dev;
    80003814:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003818:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000381c:	4785                	li	a5,1
    8000381e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003822:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003826:	0001c517          	auipc	a0,0x1c
    8000382a:	2e250513          	addi	a0,a0,738 # 8001fb08 <itable>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	45c080e7          	jalr	1116(ra) # 80000c8a <release>
}
    80003836:	854a                	mv	a0,s2
    80003838:	70a2                	ld	ra,40(sp)
    8000383a:	7402                	ld	s0,32(sp)
    8000383c:	64e2                	ld	s1,24(sp)
    8000383e:	6942                	ld	s2,16(sp)
    80003840:	69a2                	ld	s3,8(sp)
    80003842:	6a02                	ld	s4,0(sp)
    80003844:	6145                	addi	sp,sp,48
    80003846:	8082                	ret
    panic("iget: no inodes");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	e4050513          	addi	a0,a0,-448 # 80008688 <syscalls+0x140>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cf0080e7          	jalr	-784(ra) # 80000540 <panic>

0000000080003858 <fsinit>:
fsinit(int dev) {
    80003858:	7179                	addi	sp,sp,-48
    8000385a:	f406                	sd	ra,40(sp)
    8000385c:	f022                	sd	s0,32(sp)
    8000385e:	ec26                	sd	s1,24(sp)
    80003860:	e84a                	sd	s2,16(sp)
    80003862:	e44e                	sd	s3,8(sp)
    80003864:	1800                	addi	s0,sp,48
    80003866:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003868:	4585                	li	a1,1
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	a54080e7          	jalr	-1452(ra) # 800032be <bread>
    80003872:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003874:	0001c997          	auipc	s3,0x1c
    80003878:	27498993          	addi	s3,s3,628 # 8001fae8 <sb>
    8000387c:	02000613          	li	a2,32
    80003880:	05850593          	addi	a1,a0,88
    80003884:	854e                	mv	a0,s3
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	4a8080e7          	jalr	1192(ra) # 80000d2e <memmove>
  brelse(bp);
    8000388e:	8526                	mv	a0,s1
    80003890:	00000097          	auipc	ra,0x0
    80003894:	b5e080e7          	jalr	-1186(ra) # 800033ee <brelse>
  if(sb.magic != FSMAGIC)
    80003898:	0009a703          	lw	a4,0(s3)
    8000389c:	102037b7          	lui	a5,0x10203
    800038a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038a4:	02f71263          	bne	a4,a5,800038c8 <fsinit+0x70>
  initlog(dev, &sb);
    800038a8:	0001c597          	auipc	a1,0x1c
    800038ac:	24058593          	addi	a1,a1,576 # 8001fae8 <sb>
    800038b0:	854a                	mv	a0,s2
    800038b2:	00001097          	auipc	ra,0x1
    800038b6:	b4a080e7          	jalr	-1206(ra) # 800043fc <initlog>
}
    800038ba:	70a2                	ld	ra,40(sp)
    800038bc:	7402                	ld	s0,32(sp)
    800038be:	64e2                	ld	s1,24(sp)
    800038c0:	6942                	ld	s2,16(sp)
    800038c2:	69a2                	ld	s3,8(sp)
    800038c4:	6145                	addi	sp,sp,48
    800038c6:	8082                	ret
    panic("invalid file system");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	dd050513          	addi	a0,a0,-560 # 80008698 <syscalls+0x150>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	c70080e7          	jalr	-912(ra) # 80000540 <panic>

00000000800038d8 <iinit>:
{
    800038d8:	7179                	addi	sp,sp,-48
    800038da:	f406                	sd	ra,40(sp)
    800038dc:	f022                	sd	s0,32(sp)
    800038de:	ec26                	sd	s1,24(sp)
    800038e0:	e84a                	sd	s2,16(sp)
    800038e2:	e44e                	sd	s3,8(sp)
    800038e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038e6:	00005597          	auipc	a1,0x5
    800038ea:	dca58593          	addi	a1,a1,-566 # 800086b0 <syscalls+0x168>
    800038ee:	0001c517          	auipc	a0,0x1c
    800038f2:	21a50513          	addi	a0,a0,538 # 8001fb08 <itable>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	250080e7          	jalr	592(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038fe:	0001c497          	auipc	s1,0x1c
    80003902:	23248493          	addi	s1,s1,562 # 8001fb30 <itable+0x28>
    80003906:	0001e997          	auipc	s3,0x1e
    8000390a:	cba98993          	addi	s3,s3,-838 # 800215c0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000390e:	00005917          	auipc	s2,0x5
    80003912:	daa90913          	addi	s2,s2,-598 # 800086b8 <syscalls+0x170>
    80003916:	85ca                	mv	a1,s2
    80003918:	8526                	mv	a0,s1
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	e42080e7          	jalr	-446(ra) # 8000475c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003922:	08848493          	addi	s1,s1,136
    80003926:	ff3498e3          	bne	s1,s3,80003916 <iinit+0x3e>
}
    8000392a:	70a2                	ld	ra,40(sp)
    8000392c:	7402                	ld	s0,32(sp)
    8000392e:	64e2                	ld	s1,24(sp)
    80003930:	6942                	ld	s2,16(sp)
    80003932:	69a2                	ld	s3,8(sp)
    80003934:	6145                	addi	sp,sp,48
    80003936:	8082                	ret

0000000080003938 <ialloc>:
{
    80003938:	715d                	addi	sp,sp,-80
    8000393a:	e486                	sd	ra,72(sp)
    8000393c:	e0a2                	sd	s0,64(sp)
    8000393e:	fc26                	sd	s1,56(sp)
    80003940:	f84a                	sd	s2,48(sp)
    80003942:	f44e                	sd	s3,40(sp)
    80003944:	f052                	sd	s4,32(sp)
    80003946:	ec56                	sd	s5,24(sp)
    80003948:	e85a                	sd	s6,16(sp)
    8000394a:	e45e                	sd	s7,8(sp)
    8000394c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000394e:	0001c717          	auipc	a4,0x1c
    80003952:	1a672703          	lw	a4,422(a4) # 8001faf4 <sb+0xc>
    80003956:	4785                	li	a5,1
    80003958:	04e7fa63          	bgeu	a5,a4,800039ac <ialloc+0x74>
    8000395c:	8aaa                	mv	s5,a0
    8000395e:	8bae                	mv	s7,a1
    80003960:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003962:	0001ca17          	auipc	s4,0x1c
    80003966:	186a0a13          	addi	s4,s4,390 # 8001fae8 <sb>
    8000396a:	00048b1b          	sext.w	s6,s1
    8000396e:	0044d593          	srli	a1,s1,0x4
    80003972:	018a2783          	lw	a5,24(s4)
    80003976:	9dbd                	addw	a1,a1,a5
    80003978:	8556                	mv	a0,s5
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	944080e7          	jalr	-1724(ra) # 800032be <bread>
    80003982:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003984:	05850993          	addi	s3,a0,88
    80003988:	00f4f793          	andi	a5,s1,15
    8000398c:	079a                	slli	a5,a5,0x6
    8000398e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003990:	00099783          	lh	a5,0(s3)
    80003994:	c3a1                	beqz	a5,800039d4 <ialloc+0x9c>
    brelse(bp);
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	a58080e7          	jalr	-1448(ra) # 800033ee <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000399e:	0485                	addi	s1,s1,1
    800039a0:	00ca2703          	lw	a4,12(s4)
    800039a4:	0004879b          	sext.w	a5,s1
    800039a8:	fce7e1e3          	bltu	a5,a4,8000396a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039ac:	00005517          	auipc	a0,0x5
    800039b0:	d1450513          	addi	a0,a0,-748 # 800086c0 <syscalls+0x178>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	bd6080e7          	jalr	-1066(ra) # 8000058a <printf>
  return 0;
    800039bc:	4501                	li	a0,0
}
    800039be:	60a6                	ld	ra,72(sp)
    800039c0:	6406                	ld	s0,64(sp)
    800039c2:	74e2                	ld	s1,56(sp)
    800039c4:	7942                	ld	s2,48(sp)
    800039c6:	79a2                	ld	s3,40(sp)
    800039c8:	7a02                	ld	s4,32(sp)
    800039ca:	6ae2                	ld	s5,24(sp)
    800039cc:	6b42                	ld	s6,16(sp)
    800039ce:	6ba2                	ld	s7,8(sp)
    800039d0:	6161                	addi	sp,sp,80
    800039d2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039d4:	04000613          	li	a2,64
    800039d8:	4581                	li	a1,0
    800039da:	854e                	mv	a0,s3
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	2f6080e7          	jalr	758(ra) # 80000cd2 <memset>
      dip->type = type;
    800039e4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	c8e080e7          	jalr	-882(ra) # 80004678 <log_write>
      brelse(bp);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	9fa080e7          	jalr	-1542(ra) # 800033ee <brelse>
      return iget(dev, inum);
    800039fc:	85da                	mv	a1,s6
    800039fe:	8556                	mv	a0,s5
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	d9c080e7          	jalr	-612(ra) # 8000379c <iget>
    80003a08:	bf5d                	j	800039be <ialloc+0x86>

0000000080003a0a <iupdate>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	e04a                	sd	s2,0(sp)
    80003a14:	1000                	addi	s0,sp,32
    80003a16:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a18:	415c                	lw	a5,4(a0)
    80003a1a:	0047d79b          	srliw	a5,a5,0x4
    80003a1e:	0001c597          	auipc	a1,0x1c
    80003a22:	0e25a583          	lw	a1,226(a1) # 8001fb00 <sb+0x18>
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	4108                	lw	a0,0(a0)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	894080e7          	jalr	-1900(ra) # 800032be <bread>
    80003a32:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a34:	05850793          	addi	a5,a0,88
    80003a38:	40d8                	lw	a4,4(s1)
    80003a3a:	8b3d                	andi	a4,a4,15
    80003a3c:	071a                	slli	a4,a4,0x6
    80003a3e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a40:	04449703          	lh	a4,68(s1)
    80003a44:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a48:	04649703          	lh	a4,70(s1)
    80003a4c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a50:	04849703          	lh	a4,72(s1)
    80003a54:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a58:	04a49703          	lh	a4,74(s1)
    80003a5c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a60:	44f8                	lw	a4,76(s1)
    80003a62:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a64:	03400613          	li	a2,52
    80003a68:	05048593          	addi	a1,s1,80
    80003a6c:	00c78513          	addi	a0,a5,12
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	2be080e7          	jalr	702(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	bfe080e7          	jalr	-1026(ra) # 80004678 <log_write>
  brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	96a080e7          	jalr	-1686(ra) # 800033ee <brelse>
}
    80003a8c:	60e2                	ld	ra,24(sp)
    80003a8e:	6442                	ld	s0,16(sp)
    80003a90:	64a2                	ld	s1,8(sp)
    80003a92:	6902                	ld	s2,0(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret

0000000080003a98 <idup>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	1000                	addi	s0,sp,32
    80003aa2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	06450513          	addi	a0,a0,100 # 8001fb08 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	12a080e7          	jalr	298(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003ab4:	449c                	lw	a5,8(s1)
    80003ab6:	2785                	addiw	a5,a5,1
    80003ab8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	04e50513          	addi	a0,a0,78 # 8001fb08 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	1c8080e7          	jalr	456(ra) # 80000c8a <release>
}
    80003aca:	8526                	mv	a0,s1
    80003acc:	60e2                	ld	ra,24(sp)
    80003ace:	6442                	ld	s0,16(sp)
    80003ad0:	64a2                	ld	s1,8(sp)
    80003ad2:	6105                	addi	sp,sp,32
    80003ad4:	8082                	ret

0000000080003ad6 <ilock>:
{
    80003ad6:	1101                	addi	sp,sp,-32
    80003ad8:	ec06                	sd	ra,24(sp)
    80003ada:	e822                	sd	s0,16(sp)
    80003adc:	e426                	sd	s1,8(sp)
    80003ade:	e04a                	sd	s2,0(sp)
    80003ae0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ae2:	c115                	beqz	a0,80003b06 <ilock+0x30>
    80003ae4:	84aa                	mv	s1,a0
    80003ae6:	451c                	lw	a5,8(a0)
    80003ae8:	00f05f63          	blez	a5,80003b06 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003aec:	0541                	addi	a0,a0,16
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	ca8080e7          	jalr	-856(ra) # 80004796 <acquiresleep>
  if(ip->valid == 0){
    80003af6:	40bc                	lw	a5,64(s1)
    80003af8:	cf99                	beqz	a5,80003b16 <ilock+0x40>
}
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6902                	ld	s2,0(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret
    panic("ilock");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	bd250513          	addi	a0,a0,-1070 # 800086d8 <syscalls+0x190>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a32080e7          	jalr	-1486(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b16:	40dc                	lw	a5,4(s1)
    80003b18:	0047d79b          	srliw	a5,a5,0x4
    80003b1c:	0001c597          	auipc	a1,0x1c
    80003b20:	fe45a583          	lw	a1,-28(a1) # 8001fb00 <sb+0x18>
    80003b24:	9dbd                	addw	a1,a1,a5
    80003b26:	4088                	lw	a0,0(s1)
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	796080e7          	jalr	1942(ra) # 800032be <bread>
    80003b30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b32:	05850593          	addi	a1,a0,88
    80003b36:	40dc                	lw	a5,4(s1)
    80003b38:	8bbd                	andi	a5,a5,15
    80003b3a:	079a                	slli	a5,a5,0x6
    80003b3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b3e:	00059783          	lh	a5,0(a1)
    80003b42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b46:	00259783          	lh	a5,2(a1)
    80003b4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b4e:	00459783          	lh	a5,4(a1)
    80003b52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b56:	00659783          	lh	a5,6(a1)
    80003b5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b5e:	459c                	lw	a5,8(a1)
    80003b60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b62:	03400613          	li	a2,52
    80003b66:	05b1                	addi	a1,a1,12
    80003b68:	05048513          	addi	a0,s1,80
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	1c2080e7          	jalr	450(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	878080e7          	jalr	-1928(ra) # 800033ee <brelse>
    ip->valid = 1;
    80003b7e:	4785                	li	a5,1
    80003b80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b82:	04449783          	lh	a5,68(s1)
    80003b86:	fbb5                	bnez	a5,80003afa <ilock+0x24>
      panic("ilock: no type");
    80003b88:	00005517          	auipc	a0,0x5
    80003b8c:	b5850513          	addi	a0,a0,-1192 # 800086e0 <syscalls+0x198>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	9b0080e7          	jalr	-1616(ra) # 80000540 <panic>

0000000080003b98 <iunlock>:
{
    80003b98:	1101                	addi	sp,sp,-32
    80003b9a:	ec06                	sd	ra,24(sp)
    80003b9c:	e822                	sd	s0,16(sp)
    80003b9e:	e426                	sd	s1,8(sp)
    80003ba0:	e04a                	sd	s2,0(sp)
    80003ba2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ba4:	c905                	beqz	a0,80003bd4 <iunlock+0x3c>
    80003ba6:	84aa                	mv	s1,a0
    80003ba8:	01050913          	addi	s2,a0,16
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	c82080e7          	jalr	-894(ra) # 80004830 <holdingsleep>
    80003bb6:	cd19                	beqz	a0,80003bd4 <iunlock+0x3c>
    80003bb8:	449c                	lw	a5,8(s1)
    80003bba:	00f05d63          	blez	a5,80003bd4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	c2c080e7          	jalr	-980(ra) # 800047ec <releasesleep>
}
    80003bc8:	60e2                	ld	ra,24(sp)
    80003bca:	6442                	ld	s0,16(sp)
    80003bcc:	64a2                	ld	s1,8(sp)
    80003bce:	6902                	ld	s2,0(sp)
    80003bd0:	6105                	addi	sp,sp,32
    80003bd2:	8082                	ret
    panic("iunlock");
    80003bd4:	00005517          	auipc	a0,0x5
    80003bd8:	b1c50513          	addi	a0,a0,-1252 # 800086f0 <syscalls+0x1a8>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	964080e7          	jalr	-1692(ra) # 80000540 <panic>

0000000080003be4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003be4:	7179                	addi	sp,sp,-48
    80003be6:	f406                	sd	ra,40(sp)
    80003be8:	f022                	sd	s0,32(sp)
    80003bea:	ec26                	sd	s1,24(sp)
    80003bec:	e84a                	sd	s2,16(sp)
    80003bee:	e44e                	sd	s3,8(sp)
    80003bf0:	e052                	sd	s4,0(sp)
    80003bf2:	1800                	addi	s0,sp,48
    80003bf4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bf6:	05050493          	addi	s1,a0,80
    80003bfa:	08050913          	addi	s2,a0,128
    80003bfe:	a021                	j	80003c06 <itrunc+0x22>
    80003c00:	0491                	addi	s1,s1,4
    80003c02:	01248d63          	beq	s1,s2,80003c1c <itrunc+0x38>
    if(ip->addrs[i]){
    80003c06:	408c                	lw	a1,0(s1)
    80003c08:	dde5                	beqz	a1,80003c00 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c0a:	0009a503          	lw	a0,0(s3)
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	8f6080e7          	jalr	-1802(ra) # 80003504 <bfree>
      ip->addrs[i] = 0;
    80003c16:	0004a023          	sw	zero,0(s1)
    80003c1a:	b7dd                	j	80003c00 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c1c:	0809a583          	lw	a1,128(s3)
    80003c20:	e185                	bnez	a1,80003c40 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c22:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c26:	854e                	mv	a0,s3
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	de2080e7          	jalr	-542(ra) # 80003a0a <iupdate>
}
    80003c30:	70a2                	ld	ra,40(sp)
    80003c32:	7402                	ld	s0,32(sp)
    80003c34:	64e2                	ld	s1,24(sp)
    80003c36:	6942                	ld	s2,16(sp)
    80003c38:	69a2                	ld	s3,8(sp)
    80003c3a:	6a02                	ld	s4,0(sp)
    80003c3c:	6145                	addi	sp,sp,48
    80003c3e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c40:	0009a503          	lw	a0,0(s3)
    80003c44:	fffff097          	auipc	ra,0xfffff
    80003c48:	67a080e7          	jalr	1658(ra) # 800032be <bread>
    80003c4c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c4e:	05850493          	addi	s1,a0,88
    80003c52:	45850913          	addi	s2,a0,1112
    80003c56:	a021                	j	80003c5e <itrunc+0x7a>
    80003c58:	0491                	addi	s1,s1,4
    80003c5a:	01248b63          	beq	s1,s2,80003c70 <itrunc+0x8c>
      if(a[j])
    80003c5e:	408c                	lw	a1,0(s1)
    80003c60:	dde5                	beqz	a1,80003c58 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c62:	0009a503          	lw	a0,0(s3)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	89e080e7          	jalr	-1890(ra) # 80003504 <bfree>
    80003c6e:	b7ed                	j	80003c58 <itrunc+0x74>
    brelse(bp);
    80003c70:	8552                	mv	a0,s4
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	77c080e7          	jalr	1916(ra) # 800033ee <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c7a:	0809a583          	lw	a1,128(s3)
    80003c7e:	0009a503          	lw	a0,0(s3)
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	882080e7          	jalr	-1918(ra) # 80003504 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c8a:	0809a023          	sw	zero,128(s3)
    80003c8e:	bf51                	j	80003c22 <itrunc+0x3e>

0000000080003c90 <iput>:
{
    80003c90:	1101                	addi	sp,sp,-32
    80003c92:	ec06                	sd	ra,24(sp)
    80003c94:	e822                	sd	s0,16(sp)
    80003c96:	e426                	sd	s1,8(sp)
    80003c98:	e04a                	sd	s2,0(sp)
    80003c9a:	1000                	addi	s0,sp,32
    80003c9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c9e:	0001c517          	auipc	a0,0x1c
    80003ca2:	e6a50513          	addi	a0,a0,-406 # 8001fb08 <itable>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	f30080e7          	jalr	-208(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cae:	4498                	lw	a4,8(s1)
    80003cb0:	4785                	li	a5,1
    80003cb2:	02f70363          	beq	a4,a5,80003cd8 <iput+0x48>
  ip->ref--;
    80003cb6:	449c                	lw	a5,8(s1)
    80003cb8:	37fd                	addiw	a5,a5,-1
    80003cba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cbc:	0001c517          	auipc	a0,0x1c
    80003cc0:	e4c50513          	addi	a0,a0,-436 # 8001fb08 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	fc6080e7          	jalr	-58(ra) # 80000c8a <release>
}
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6902                	ld	s2,0(sp)
    80003cd4:	6105                	addi	sp,sp,32
    80003cd6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cd8:	40bc                	lw	a5,64(s1)
    80003cda:	dff1                	beqz	a5,80003cb6 <iput+0x26>
    80003cdc:	04a49783          	lh	a5,74(s1)
    80003ce0:	fbf9                	bnez	a5,80003cb6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ce2:	01048913          	addi	s2,s1,16
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	aae080e7          	jalr	-1362(ra) # 80004796 <acquiresleep>
    release(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	e1850513          	addi	a0,a0,-488 # 8001fb08 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	f92080e7          	jalr	-110(ra) # 80000c8a <release>
    itrunc(ip);
    80003d00:	8526                	mv	a0,s1
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	ee2080e7          	jalr	-286(ra) # 80003be4 <itrunc>
    ip->type = 0;
    80003d0a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d0e:	8526                	mv	a0,s1
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	cfa080e7          	jalr	-774(ra) # 80003a0a <iupdate>
    ip->valid = 0;
    80003d18:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	ace080e7          	jalr	-1330(ra) # 800047ec <releasesleep>
    acquire(&itable.lock);
    80003d26:	0001c517          	auipc	a0,0x1c
    80003d2a:	de250513          	addi	a0,a0,-542 # 8001fb08 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	ea8080e7          	jalr	-344(ra) # 80000bd6 <acquire>
    80003d36:	b741                	j	80003cb6 <iput+0x26>

0000000080003d38 <iunlockput>:
{
    80003d38:	1101                	addi	sp,sp,-32
    80003d3a:	ec06                	sd	ra,24(sp)
    80003d3c:	e822                	sd	s0,16(sp)
    80003d3e:	e426                	sd	s1,8(sp)
    80003d40:	1000                	addi	s0,sp,32
    80003d42:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	e54080e7          	jalr	-428(ra) # 80003b98 <iunlock>
  iput(ip);
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	f42080e7          	jalr	-190(ra) # 80003c90 <iput>
}
    80003d56:	60e2                	ld	ra,24(sp)
    80003d58:	6442                	ld	s0,16(sp)
    80003d5a:	64a2                	ld	s1,8(sp)
    80003d5c:	6105                	addi	sp,sp,32
    80003d5e:	8082                	ret

0000000080003d60 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d60:	1141                	addi	sp,sp,-16
    80003d62:	e422                	sd	s0,8(sp)
    80003d64:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d66:	411c                	lw	a5,0(a0)
    80003d68:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d6a:	415c                	lw	a5,4(a0)
    80003d6c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d6e:	04451783          	lh	a5,68(a0)
    80003d72:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d76:	04a51783          	lh	a5,74(a0)
    80003d7a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d7e:	04c56783          	lwu	a5,76(a0)
    80003d82:	e99c                	sd	a5,16(a1)
}
    80003d84:	6422                	ld	s0,8(sp)
    80003d86:	0141                	addi	sp,sp,16
    80003d88:	8082                	ret

0000000080003d8a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d8a:	457c                	lw	a5,76(a0)
    80003d8c:	0ed7e963          	bltu	a5,a3,80003e7e <readi+0xf4>
{
    80003d90:	7159                	addi	sp,sp,-112
    80003d92:	f486                	sd	ra,104(sp)
    80003d94:	f0a2                	sd	s0,96(sp)
    80003d96:	eca6                	sd	s1,88(sp)
    80003d98:	e8ca                	sd	s2,80(sp)
    80003d9a:	e4ce                	sd	s3,72(sp)
    80003d9c:	e0d2                	sd	s4,64(sp)
    80003d9e:	fc56                	sd	s5,56(sp)
    80003da0:	f85a                	sd	s6,48(sp)
    80003da2:	f45e                	sd	s7,40(sp)
    80003da4:	f062                	sd	s8,32(sp)
    80003da6:	ec66                	sd	s9,24(sp)
    80003da8:	e86a                	sd	s10,16(sp)
    80003daa:	e46e                	sd	s11,8(sp)
    80003dac:	1880                	addi	s0,sp,112
    80003dae:	8b2a                	mv	s6,a0
    80003db0:	8bae                	mv	s7,a1
    80003db2:	8a32                	mv	s4,a2
    80003db4:	84b6                	mv	s1,a3
    80003db6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003db8:	9f35                	addw	a4,a4,a3
    return 0;
    80003dba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dbc:	0ad76063          	bltu	a4,a3,80003e5c <readi+0xd2>
  if(off + n > ip->size)
    80003dc0:	00e7f463          	bgeu	a5,a4,80003dc8 <readi+0x3e>
    n = ip->size - off;
    80003dc4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dc8:	0a0a8963          	beqz	s5,80003e7a <readi+0xf0>
    80003dcc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dce:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dd2:	5c7d                	li	s8,-1
    80003dd4:	a82d                	j	80003e0e <readi+0x84>
    80003dd6:	020d1d93          	slli	s11,s10,0x20
    80003dda:	020ddd93          	srli	s11,s11,0x20
    80003dde:	05890613          	addi	a2,s2,88
    80003de2:	86ee                	mv	a3,s11
    80003de4:	963a                	add	a2,a2,a4
    80003de6:	85d2                	mv	a1,s4
    80003de8:	855e                	mv	a0,s7
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	940080e7          	jalr	-1728(ra) # 8000272a <either_copyout>
    80003df2:	05850d63          	beq	a0,s8,80003e4c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	5f6080e7          	jalr	1526(ra) # 800033ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e00:	013d09bb          	addw	s3,s10,s3
    80003e04:	009d04bb          	addw	s1,s10,s1
    80003e08:	9a6e                	add	s4,s4,s11
    80003e0a:	0559f763          	bgeu	s3,s5,80003e58 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e0e:	00a4d59b          	srliw	a1,s1,0xa
    80003e12:	855a                	mv	a0,s6
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	89e080e7          	jalr	-1890(ra) # 800036b2 <bmap>
    80003e1c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e20:	cd85                	beqz	a1,80003e58 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e22:	000b2503          	lw	a0,0(s6)
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	498080e7          	jalr	1176(ra) # 800032be <bread>
    80003e2e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e30:	3ff4f713          	andi	a4,s1,1023
    80003e34:	40ec87bb          	subw	a5,s9,a4
    80003e38:	413a86bb          	subw	a3,s5,s3
    80003e3c:	8d3e                	mv	s10,a5
    80003e3e:	2781                	sext.w	a5,a5
    80003e40:	0006861b          	sext.w	a2,a3
    80003e44:	f8f679e3          	bgeu	a2,a5,80003dd6 <readi+0x4c>
    80003e48:	8d36                	mv	s10,a3
    80003e4a:	b771                	j	80003dd6 <readi+0x4c>
      brelse(bp);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	5a0080e7          	jalr	1440(ra) # 800033ee <brelse>
      tot = -1;
    80003e56:	59fd                	li	s3,-1
  }
  return tot;
    80003e58:	0009851b          	sext.w	a0,s3
}
    80003e5c:	70a6                	ld	ra,104(sp)
    80003e5e:	7406                	ld	s0,96(sp)
    80003e60:	64e6                	ld	s1,88(sp)
    80003e62:	6946                	ld	s2,80(sp)
    80003e64:	69a6                	ld	s3,72(sp)
    80003e66:	6a06                	ld	s4,64(sp)
    80003e68:	7ae2                	ld	s5,56(sp)
    80003e6a:	7b42                	ld	s6,48(sp)
    80003e6c:	7ba2                	ld	s7,40(sp)
    80003e6e:	7c02                	ld	s8,32(sp)
    80003e70:	6ce2                	ld	s9,24(sp)
    80003e72:	6d42                	ld	s10,16(sp)
    80003e74:	6da2                	ld	s11,8(sp)
    80003e76:	6165                	addi	sp,sp,112
    80003e78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e7a:	89d6                	mv	s3,s5
    80003e7c:	bff1                	j	80003e58 <readi+0xce>
    return 0;
    80003e7e:	4501                	li	a0,0
}
    80003e80:	8082                	ret

0000000080003e82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e82:	457c                	lw	a5,76(a0)
    80003e84:	10d7e863          	bltu	a5,a3,80003f94 <writei+0x112>
{
    80003e88:	7159                	addi	sp,sp,-112
    80003e8a:	f486                	sd	ra,104(sp)
    80003e8c:	f0a2                	sd	s0,96(sp)
    80003e8e:	eca6                	sd	s1,88(sp)
    80003e90:	e8ca                	sd	s2,80(sp)
    80003e92:	e4ce                	sd	s3,72(sp)
    80003e94:	e0d2                	sd	s4,64(sp)
    80003e96:	fc56                	sd	s5,56(sp)
    80003e98:	f85a                	sd	s6,48(sp)
    80003e9a:	f45e                	sd	s7,40(sp)
    80003e9c:	f062                	sd	s8,32(sp)
    80003e9e:	ec66                	sd	s9,24(sp)
    80003ea0:	e86a                	sd	s10,16(sp)
    80003ea2:	e46e                	sd	s11,8(sp)
    80003ea4:	1880                	addi	s0,sp,112
    80003ea6:	8aaa                	mv	s5,a0
    80003ea8:	8bae                	mv	s7,a1
    80003eaa:	8a32                	mv	s4,a2
    80003eac:	8936                	mv	s2,a3
    80003eae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eb0:	00e687bb          	addw	a5,a3,a4
    80003eb4:	0ed7e263          	bltu	a5,a3,80003f98 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eb8:	00043737          	lui	a4,0x43
    80003ebc:	0ef76063          	bltu	a4,a5,80003f9c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ec0:	0c0b0863          	beqz	s6,80003f90 <writei+0x10e>
    80003ec4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eca:	5c7d                	li	s8,-1
    80003ecc:	a091                	j	80003f10 <writei+0x8e>
    80003ece:	020d1d93          	slli	s11,s10,0x20
    80003ed2:	020ddd93          	srli	s11,s11,0x20
    80003ed6:	05848513          	addi	a0,s1,88
    80003eda:	86ee                	mv	a3,s11
    80003edc:	8652                	mv	a2,s4
    80003ede:	85de                	mv	a1,s7
    80003ee0:	953a                	add	a0,a0,a4
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	89e080e7          	jalr	-1890(ra) # 80002780 <either_copyin>
    80003eea:	07850263          	beq	a0,s8,80003f4e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	788080e7          	jalr	1928(ra) # 80004678 <log_write>
    brelse(bp);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	4f4080e7          	jalr	1268(ra) # 800033ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f02:	013d09bb          	addw	s3,s10,s3
    80003f06:	012d093b          	addw	s2,s10,s2
    80003f0a:	9a6e                	add	s4,s4,s11
    80003f0c:	0569f663          	bgeu	s3,s6,80003f58 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f10:	00a9559b          	srliw	a1,s2,0xa
    80003f14:	8556                	mv	a0,s5
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	79c080e7          	jalr	1948(ra) # 800036b2 <bmap>
    80003f1e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f22:	c99d                	beqz	a1,80003f58 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f24:	000aa503          	lw	a0,0(s5)
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	396080e7          	jalr	918(ra) # 800032be <bread>
    80003f30:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f32:	3ff97713          	andi	a4,s2,1023
    80003f36:	40ec87bb          	subw	a5,s9,a4
    80003f3a:	413b06bb          	subw	a3,s6,s3
    80003f3e:	8d3e                	mv	s10,a5
    80003f40:	2781                	sext.w	a5,a5
    80003f42:	0006861b          	sext.w	a2,a3
    80003f46:	f8f674e3          	bgeu	a2,a5,80003ece <writei+0x4c>
    80003f4a:	8d36                	mv	s10,a3
    80003f4c:	b749                	j	80003ece <writei+0x4c>
      brelse(bp);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	49e080e7          	jalr	1182(ra) # 800033ee <brelse>
  }

  if(off > ip->size)
    80003f58:	04caa783          	lw	a5,76(s5)
    80003f5c:	0127f463          	bgeu	a5,s2,80003f64 <writei+0xe2>
    ip->size = off;
    80003f60:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f64:	8556                	mv	a0,s5
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	aa4080e7          	jalr	-1372(ra) # 80003a0a <iupdate>

  return tot;
    80003f6e:	0009851b          	sext.w	a0,s3
}
    80003f72:	70a6                	ld	ra,104(sp)
    80003f74:	7406                	ld	s0,96(sp)
    80003f76:	64e6                	ld	s1,88(sp)
    80003f78:	6946                	ld	s2,80(sp)
    80003f7a:	69a6                	ld	s3,72(sp)
    80003f7c:	6a06                	ld	s4,64(sp)
    80003f7e:	7ae2                	ld	s5,56(sp)
    80003f80:	7b42                	ld	s6,48(sp)
    80003f82:	7ba2                	ld	s7,40(sp)
    80003f84:	7c02                	ld	s8,32(sp)
    80003f86:	6ce2                	ld	s9,24(sp)
    80003f88:	6d42                	ld	s10,16(sp)
    80003f8a:	6da2                	ld	s11,8(sp)
    80003f8c:	6165                	addi	sp,sp,112
    80003f8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f90:	89da                	mv	s3,s6
    80003f92:	bfc9                	j	80003f64 <writei+0xe2>
    return -1;
    80003f94:	557d                	li	a0,-1
}
    80003f96:	8082                	ret
    return -1;
    80003f98:	557d                	li	a0,-1
    80003f9a:	bfe1                	j	80003f72 <writei+0xf0>
    return -1;
    80003f9c:	557d                	li	a0,-1
    80003f9e:	bfd1                	j	80003f72 <writei+0xf0>

0000000080003fa0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fa0:	1141                	addi	sp,sp,-16
    80003fa2:	e406                	sd	ra,8(sp)
    80003fa4:	e022                	sd	s0,0(sp)
    80003fa6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fa8:	4639                	li	a2,14
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	df8080e7          	jalr	-520(ra) # 80000da2 <strncmp>
}
    80003fb2:	60a2                	ld	ra,8(sp)
    80003fb4:	6402                	ld	s0,0(sp)
    80003fb6:	0141                	addi	sp,sp,16
    80003fb8:	8082                	ret

0000000080003fba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fba:	7139                	addi	sp,sp,-64
    80003fbc:	fc06                	sd	ra,56(sp)
    80003fbe:	f822                	sd	s0,48(sp)
    80003fc0:	f426                	sd	s1,40(sp)
    80003fc2:	f04a                	sd	s2,32(sp)
    80003fc4:	ec4e                	sd	s3,24(sp)
    80003fc6:	e852                	sd	s4,16(sp)
    80003fc8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fca:	04451703          	lh	a4,68(a0)
    80003fce:	4785                	li	a5,1
    80003fd0:	00f71a63          	bne	a4,a5,80003fe4 <dirlookup+0x2a>
    80003fd4:	892a                	mv	s2,a0
    80003fd6:	89ae                	mv	s3,a1
    80003fd8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fda:	457c                	lw	a5,76(a0)
    80003fdc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fde:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe0:	e79d                	bnez	a5,8000400e <dirlookup+0x54>
    80003fe2:	a8a5                	j	8000405a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fe4:	00004517          	auipc	a0,0x4
    80003fe8:	71450513          	addi	a0,a0,1812 # 800086f8 <syscalls+0x1b0>
    80003fec:	ffffc097          	auipc	ra,0xffffc
    80003ff0:	554080e7          	jalr	1364(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ff4:	00004517          	auipc	a0,0x4
    80003ff8:	71c50513          	addi	a0,a0,1820 # 80008710 <syscalls+0x1c8>
    80003ffc:	ffffc097          	auipc	ra,0xffffc
    80004000:	544080e7          	jalr	1348(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004004:	24c1                	addiw	s1,s1,16
    80004006:	04c92783          	lw	a5,76(s2)
    8000400a:	04f4f763          	bgeu	s1,a5,80004058 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400e:	4741                	li	a4,16
    80004010:	86a6                	mv	a3,s1
    80004012:	fc040613          	addi	a2,s0,-64
    80004016:	4581                	li	a1,0
    80004018:	854a                	mv	a0,s2
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	d70080e7          	jalr	-656(ra) # 80003d8a <readi>
    80004022:	47c1                	li	a5,16
    80004024:	fcf518e3          	bne	a0,a5,80003ff4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004028:	fc045783          	lhu	a5,-64(s0)
    8000402c:	dfe1                	beqz	a5,80004004 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000402e:	fc240593          	addi	a1,s0,-62
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	f6c080e7          	jalr	-148(ra) # 80003fa0 <namecmp>
    8000403c:	f561                	bnez	a0,80004004 <dirlookup+0x4a>
      if(poff)
    8000403e:	000a0463          	beqz	s4,80004046 <dirlookup+0x8c>
        *poff = off;
    80004042:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004046:	fc045583          	lhu	a1,-64(s0)
    8000404a:	00092503          	lw	a0,0(s2)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	74e080e7          	jalr	1870(ra) # 8000379c <iget>
    80004056:	a011                	j	8000405a <dirlookup+0xa0>
  return 0;
    80004058:	4501                	li	a0,0
}
    8000405a:	70e2                	ld	ra,56(sp)
    8000405c:	7442                	ld	s0,48(sp)
    8000405e:	74a2                	ld	s1,40(sp)
    80004060:	7902                	ld	s2,32(sp)
    80004062:	69e2                	ld	s3,24(sp)
    80004064:	6a42                	ld	s4,16(sp)
    80004066:	6121                	addi	sp,sp,64
    80004068:	8082                	ret

000000008000406a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000406a:	711d                	addi	sp,sp,-96
    8000406c:	ec86                	sd	ra,88(sp)
    8000406e:	e8a2                	sd	s0,80(sp)
    80004070:	e4a6                	sd	s1,72(sp)
    80004072:	e0ca                	sd	s2,64(sp)
    80004074:	fc4e                	sd	s3,56(sp)
    80004076:	f852                	sd	s4,48(sp)
    80004078:	f456                	sd	s5,40(sp)
    8000407a:	f05a                	sd	s6,32(sp)
    8000407c:	ec5e                	sd	s7,24(sp)
    8000407e:	e862                	sd	s8,16(sp)
    80004080:	e466                	sd	s9,8(sp)
    80004082:	e06a                	sd	s10,0(sp)
    80004084:	1080                	addi	s0,sp,96
    80004086:	84aa                	mv	s1,a0
    80004088:	8b2e                	mv	s6,a1
    8000408a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000408c:	00054703          	lbu	a4,0(a0)
    80004090:	02f00793          	li	a5,47
    80004094:	02f70363          	beq	a4,a5,800040ba <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004098:	ffffe097          	auipc	ra,0xffffe
    8000409c:	9b2080e7          	jalr	-1614(ra) # 80001a4a <myproc>
    800040a0:	15853503          	ld	a0,344(a0)
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	9f4080e7          	jalr	-1548(ra) # 80003a98 <idup>
    800040ac:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040ae:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040b2:	4cb5                	li	s9,13
  len = path - s;
    800040b4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040b6:	4c05                	li	s8,1
    800040b8:	a87d                	j	80004176 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040ba:	4585                	li	a1,1
    800040bc:	4505                	li	a0,1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	6de080e7          	jalr	1758(ra) # 8000379c <iget>
    800040c6:	8a2a                	mv	s4,a0
    800040c8:	b7dd                	j	800040ae <namex+0x44>
      iunlockput(ip);
    800040ca:	8552                	mv	a0,s4
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	c6c080e7          	jalr	-916(ra) # 80003d38 <iunlockput>
      return 0;
    800040d4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040d6:	8552                	mv	a0,s4
    800040d8:	60e6                	ld	ra,88(sp)
    800040da:	6446                	ld	s0,80(sp)
    800040dc:	64a6                	ld	s1,72(sp)
    800040de:	6906                	ld	s2,64(sp)
    800040e0:	79e2                	ld	s3,56(sp)
    800040e2:	7a42                	ld	s4,48(sp)
    800040e4:	7aa2                	ld	s5,40(sp)
    800040e6:	7b02                	ld	s6,32(sp)
    800040e8:	6be2                	ld	s7,24(sp)
    800040ea:	6c42                	ld	s8,16(sp)
    800040ec:	6ca2                	ld	s9,8(sp)
    800040ee:	6d02                	ld	s10,0(sp)
    800040f0:	6125                	addi	sp,sp,96
    800040f2:	8082                	ret
      iunlock(ip);
    800040f4:	8552                	mv	a0,s4
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	aa2080e7          	jalr	-1374(ra) # 80003b98 <iunlock>
      return ip;
    800040fe:	bfe1                	j	800040d6 <namex+0x6c>
      iunlockput(ip);
    80004100:	8552                	mv	a0,s4
    80004102:	00000097          	auipc	ra,0x0
    80004106:	c36080e7          	jalr	-970(ra) # 80003d38 <iunlockput>
      return 0;
    8000410a:	8a4e                	mv	s4,s3
    8000410c:	b7e9                	j	800040d6 <namex+0x6c>
  len = path - s;
    8000410e:	40998633          	sub	a2,s3,s1
    80004112:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004116:	09acd863          	bge	s9,s10,800041a6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000411a:	4639                	li	a2,14
    8000411c:	85a6                	mv	a1,s1
    8000411e:	8556                	mv	a0,s5
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	c0e080e7          	jalr	-1010(ra) # 80000d2e <memmove>
    80004128:	84ce                	mv	s1,s3
  while(*path == '/')
    8000412a:	0004c783          	lbu	a5,0(s1)
    8000412e:	01279763          	bne	a5,s2,8000413c <namex+0xd2>
    path++;
    80004132:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004134:	0004c783          	lbu	a5,0(s1)
    80004138:	ff278de3          	beq	a5,s2,80004132 <namex+0xc8>
    ilock(ip);
    8000413c:	8552                	mv	a0,s4
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	998080e7          	jalr	-1640(ra) # 80003ad6 <ilock>
    if(ip->type != T_DIR){
    80004146:	044a1783          	lh	a5,68(s4)
    8000414a:	f98790e3          	bne	a5,s8,800040ca <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000414e:	000b0563          	beqz	s6,80004158 <namex+0xee>
    80004152:	0004c783          	lbu	a5,0(s1)
    80004156:	dfd9                	beqz	a5,800040f4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004158:	865e                	mv	a2,s7
    8000415a:	85d6                	mv	a1,s5
    8000415c:	8552                	mv	a0,s4
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	e5c080e7          	jalr	-420(ra) # 80003fba <dirlookup>
    80004166:	89aa                	mv	s3,a0
    80004168:	dd41                	beqz	a0,80004100 <namex+0x96>
    iunlockput(ip);
    8000416a:	8552                	mv	a0,s4
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	bcc080e7          	jalr	-1076(ra) # 80003d38 <iunlockput>
    ip = next;
    80004174:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004176:	0004c783          	lbu	a5,0(s1)
    8000417a:	01279763          	bne	a5,s2,80004188 <namex+0x11e>
    path++;
    8000417e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004180:	0004c783          	lbu	a5,0(s1)
    80004184:	ff278de3          	beq	a5,s2,8000417e <namex+0x114>
  if(*path == 0)
    80004188:	cb9d                	beqz	a5,800041be <namex+0x154>
  while(*path != '/' && *path != 0)
    8000418a:	0004c783          	lbu	a5,0(s1)
    8000418e:	89a6                	mv	s3,s1
  len = path - s;
    80004190:	8d5e                	mv	s10,s7
    80004192:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004194:	01278963          	beq	a5,s2,800041a6 <namex+0x13c>
    80004198:	dbbd                	beqz	a5,8000410e <namex+0xa4>
    path++;
    8000419a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000419c:	0009c783          	lbu	a5,0(s3)
    800041a0:	ff279ce3          	bne	a5,s2,80004198 <namex+0x12e>
    800041a4:	b7ad                	j	8000410e <namex+0xa4>
    memmove(name, s, len);
    800041a6:	2601                	sext.w	a2,a2
    800041a8:	85a6                	mv	a1,s1
    800041aa:	8556                	mv	a0,s5
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	b82080e7          	jalr	-1150(ra) # 80000d2e <memmove>
    name[len] = 0;
    800041b4:	9d56                	add	s10,s10,s5
    800041b6:	000d0023          	sb	zero,0(s10)
    800041ba:	84ce                	mv	s1,s3
    800041bc:	b7bd                	j	8000412a <namex+0xc0>
  if(nameiparent){
    800041be:	f00b0ce3          	beqz	s6,800040d6 <namex+0x6c>
    iput(ip);
    800041c2:	8552                	mv	a0,s4
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	acc080e7          	jalr	-1332(ra) # 80003c90 <iput>
    return 0;
    800041cc:	4a01                	li	s4,0
    800041ce:	b721                	j	800040d6 <namex+0x6c>

00000000800041d0 <dirlink>:
{
    800041d0:	7139                	addi	sp,sp,-64
    800041d2:	fc06                	sd	ra,56(sp)
    800041d4:	f822                	sd	s0,48(sp)
    800041d6:	f426                	sd	s1,40(sp)
    800041d8:	f04a                	sd	s2,32(sp)
    800041da:	ec4e                	sd	s3,24(sp)
    800041dc:	e852                	sd	s4,16(sp)
    800041de:	0080                	addi	s0,sp,64
    800041e0:	892a                	mv	s2,a0
    800041e2:	8a2e                	mv	s4,a1
    800041e4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041e6:	4601                	li	a2,0
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	dd2080e7          	jalr	-558(ra) # 80003fba <dirlookup>
    800041f0:	e93d                	bnez	a0,80004266 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f2:	04c92483          	lw	s1,76(s2)
    800041f6:	c49d                	beqz	s1,80004224 <dirlink+0x54>
    800041f8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041fa:	4741                	li	a4,16
    800041fc:	86a6                	mv	a3,s1
    800041fe:	fc040613          	addi	a2,s0,-64
    80004202:	4581                	li	a1,0
    80004204:	854a                	mv	a0,s2
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	b84080e7          	jalr	-1148(ra) # 80003d8a <readi>
    8000420e:	47c1                	li	a5,16
    80004210:	06f51163          	bne	a0,a5,80004272 <dirlink+0xa2>
    if(de.inum == 0)
    80004214:	fc045783          	lhu	a5,-64(s0)
    80004218:	c791                	beqz	a5,80004224 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421a:	24c1                	addiw	s1,s1,16
    8000421c:	04c92783          	lw	a5,76(s2)
    80004220:	fcf4ede3          	bltu	s1,a5,800041fa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004224:	4639                	li	a2,14
    80004226:	85d2                	mv	a1,s4
    80004228:	fc240513          	addi	a0,s0,-62
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	bb2080e7          	jalr	-1102(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004234:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004238:	4741                	li	a4,16
    8000423a:	86a6                	mv	a3,s1
    8000423c:	fc040613          	addi	a2,s0,-64
    80004240:	4581                	li	a1,0
    80004242:	854a                	mv	a0,s2
    80004244:	00000097          	auipc	ra,0x0
    80004248:	c3e080e7          	jalr	-962(ra) # 80003e82 <writei>
    8000424c:	1541                	addi	a0,a0,-16
    8000424e:	00a03533          	snez	a0,a0
    80004252:	40a00533          	neg	a0,a0
}
    80004256:	70e2                	ld	ra,56(sp)
    80004258:	7442                	ld	s0,48(sp)
    8000425a:	74a2                	ld	s1,40(sp)
    8000425c:	7902                	ld	s2,32(sp)
    8000425e:	69e2                	ld	s3,24(sp)
    80004260:	6a42                	ld	s4,16(sp)
    80004262:	6121                	addi	sp,sp,64
    80004264:	8082                	ret
    iput(ip);
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	a2a080e7          	jalr	-1494(ra) # 80003c90 <iput>
    return -1;
    8000426e:	557d                	li	a0,-1
    80004270:	b7dd                	j	80004256 <dirlink+0x86>
      panic("dirlink read");
    80004272:	00004517          	auipc	a0,0x4
    80004276:	4ae50513          	addi	a0,a0,1198 # 80008720 <syscalls+0x1d8>
    8000427a:	ffffc097          	auipc	ra,0xffffc
    8000427e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>

0000000080004282 <namei>:

struct inode*
namei(char *path)
{
    80004282:	1101                	addi	sp,sp,-32
    80004284:	ec06                	sd	ra,24(sp)
    80004286:	e822                	sd	s0,16(sp)
    80004288:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000428a:	fe040613          	addi	a2,s0,-32
    8000428e:	4581                	li	a1,0
    80004290:	00000097          	auipc	ra,0x0
    80004294:	dda080e7          	jalr	-550(ra) # 8000406a <namex>
}
    80004298:	60e2                	ld	ra,24(sp)
    8000429a:	6442                	ld	s0,16(sp)
    8000429c:	6105                	addi	sp,sp,32
    8000429e:	8082                	ret

00000000800042a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042a0:	1141                	addi	sp,sp,-16
    800042a2:	e406                	sd	ra,8(sp)
    800042a4:	e022                	sd	s0,0(sp)
    800042a6:	0800                	addi	s0,sp,16
    800042a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042aa:	4585                	li	a1,1
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	dbe080e7          	jalr	-578(ra) # 8000406a <namex>
}
    800042b4:	60a2                	ld	ra,8(sp)
    800042b6:	6402                	ld	s0,0(sp)
    800042b8:	0141                	addi	sp,sp,16
    800042ba:	8082                	ret

00000000800042bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042bc:	1101                	addi	sp,sp,-32
    800042be:	ec06                	sd	ra,24(sp)
    800042c0:	e822                	sd	s0,16(sp)
    800042c2:	e426                	sd	s1,8(sp)
    800042c4:	e04a                	sd	s2,0(sp)
    800042c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042c8:	0001d917          	auipc	s2,0x1d
    800042cc:	2e890913          	addi	s2,s2,744 # 800215b0 <log>
    800042d0:	01892583          	lw	a1,24(s2)
    800042d4:	02892503          	lw	a0,40(s2)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	fe6080e7          	jalr	-26(ra) # 800032be <bread>
    800042e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042e2:	02c92683          	lw	a3,44(s2)
    800042e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042e8:	02d05863          	blez	a3,80004318 <write_head+0x5c>
    800042ec:	0001d797          	auipc	a5,0x1d
    800042f0:	2f478793          	addi	a5,a5,756 # 800215e0 <log+0x30>
    800042f4:	05c50713          	addi	a4,a0,92
    800042f8:	36fd                	addiw	a3,a3,-1
    800042fa:	02069613          	slli	a2,a3,0x20
    800042fe:	01e65693          	srli	a3,a2,0x1e
    80004302:	0001d617          	auipc	a2,0x1d
    80004306:	2e260613          	addi	a2,a2,738 # 800215e4 <log+0x34>
    8000430a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000430c:	4390                	lw	a2,0(a5)
    8000430e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004310:	0791                	addi	a5,a5,4
    80004312:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004314:	fed79ce3          	bne	a5,a3,8000430c <write_head+0x50>
  }
  bwrite(buf);
    80004318:	8526                	mv	a0,s1
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	096080e7          	jalr	150(ra) # 800033b0 <bwrite>
  brelse(buf);
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	0ca080e7          	jalr	202(ra) # 800033ee <brelse>
}
    8000432c:	60e2                	ld	ra,24(sp)
    8000432e:	6442                	ld	s0,16(sp)
    80004330:	64a2                	ld	s1,8(sp)
    80004332:	6902                	ld	s2,0(sp)
    80004334:	6105                	addi	sp,sp,32
    80004336:	8082                	ret

0000000080004338 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004338:	0001d797          	auipc	a5,0x1d
    8000433c:	2a47a783          	lw	a5,676(a5) # 800215dc <log+0x2c>
    80004340:	0af05d63          	blez	a5,800043fa <install_trans+0xc2>
{
    80004344:	7139                	addi	sp,sp,-64
    80004346:	fc06                	sd	ra,56(sp)
    80004348:	f822                	sd	s0,48(sp)
    8000434a:	f426                	sd	s1,40(sp)
    8000434c:	f04a                	sd	s2,32(sp)
    8000434e:	ec4e                	sd	s3,24(sp)
    80004350:	e852                	sd	s4,16(sp)
    80004352:	e456                	sd	s5,8(sp)
    80004354:	e05a                	sd	s6,0(sp)
    80004356:	0080                	addi	s0,sp,64
    80004358:	8b2a                	mv	s6,a0
    8000435a:	0001da97          	auipc	s5,0x1d
    8000435e:	286a8a93          	addi	s5,s5,646 # 800215e0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004362:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004364:	0001d997          	auipc	s3,0x1d
    80004368:	24c98993          	addi	s3,s3,588 # 800215b0 <log>
    8000436c:	a00d                	j	8000438e <install_trans+0x56>
    brelse(lbuf);
    8000436e:	854a                	mv	a0,s2
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	07e080e7          	jalr	126(ra) # 800033ee <brelse>
    brelse(dbuf);
    80004378:	8526                	mv	a0,s1
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	074080e7          	jalr	116(ra) # 800033ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004382:	2a05                	addiw	s4,s4,1
    80004384:	0a91                	addi	s5,s5,4
    80004386:	02c9a783          	lw	a5,44(s3)
    8000438a:	04fa5e63          	bge	s4,a5,800043e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438e:	0189a583          	lw	a1,24(s3)
    80004392:	014585bb          	addw	a1,a1,s4
    80004396:	2585                	addiw	a1,a1,1
    80004398:	0289a503          	lw	a0,40(s3)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	f22080e7          	jalr	-222(ra) # 800032be <bread>
    800043a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043a6:	000aa583          	lw	a1,0(s5)
    800043aa:	0289a503          	lw	a0,40(s3)
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	f10080e7          	jalr	-240(ra) # 800032be <bread>
    800043b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043b8:	40000613          	li	a2,1024
    800043bc:	05890593          	addi	a1,s2,88
    800043c0:	05850513          	addi	a0,a0,88
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	96a080e7          	jalr	-1686(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	fe2080e7          	jalr	-30(ra) # 800033b0 <bwrite>
    if(recovering == 0)
    800043d6:	f80b1ce3          	bnez	s6,8000436e <install_trans+0x36>
      bunpin(dbuf);
    800043da:	8526                	mv	a0,s1
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	0ec080e7          	jalr	236(ra) # 800034c8 <bunpin>
    800043e4:	b769                	j	8000436e <install_trans+0x36>
}
    800043e6:	70e2                	ld	ra,56(sp)
    800043e8:	7442                	ld	s0,48(sp)
    800043ea:	74a2                	ld	s1,40(sp)
    800043ec:	7902                	ld	s2,32(sp)
    800043ee:	69e2                	ld	s3,24(sp)
    800043f0:	6a42                	ld	s4,16(sp)
    800043f2:	6aa2                	ld	s5,8(sp)
    800043f4:	6b02                	ld	s6,0(sp)
    800043f6:	6121                	addi	sp,sp,64
    800043f8:	8082                	ret
    800043fa:	8082                	ret

00000000800043fc <initlog>:
{
    800043fc:	7179                	addi	sp,sp,-48
    800043fe:	f406                	sd	ra,40(sp)
    80004400:	f022                	sd	s0,32(sp)
    80004402:	ec26                	sd	s1,24(sp)
    80004404:	e84a                	sd	s2,16(sp)
    80004406:	e44e                	sd	s3,8(sp)
    80004408:	1800                	addi	s0,sp,48
    8000440a:	892a                	mv	s2,a0
    8000440c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000440e:	0001d497          	auipc	s1,0x1d
    80004412:	1a248493          	addi	s1,s1,418 # 800215b0 <log>
    80004416:	00004597          	auipc	a1,0x4
    8000441a:	31a58593          	addi	a1,a1,794 # 80008730 <syscalls+0x1e8>
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	726080e7          	jalr	1830(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004428:	0149a583          	lw	a1,20(s3)
    8000442c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000442e:	0109a783          	lw	a5,16(s3)
    80004432:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004434:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004438:	854a                	mv	a0,s2
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	e84080e7          	jalr	-380(ra) # 800032be <bread>
  log.lh.n = lh->n;
    80004442:	4d34                	lw	a3,88(a0)
    80004444:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004446:	02d05663          	blez	a3,80004472 <initlog+0x76>
    8000444a:	05c50793          	addi	a5,a0,92
    8000444e:	0001d717          	auipc	a4,0x1d
    80004452:	19270713          	addi	a4,a4,402 # 800215e0 <log+0x30>
    80004456:	36fd                	addiw	a3,a3,-1
    80004458:	02069613          	slli	a2,a3,0x20
    8000445c:	01e65693          	srli	a3,a2,0x1e
    80004460:	06050613          	addi	a2,a0,96
    80004464:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004466:	4390                	lw	a2,0(a5)
    80004468:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000446a:	0791                	addi	a5,a5,4
    8000446c:	0711                	addi	a4,a4,4
    8000446e:	fed79ce3          	bne	a5,a3,80004466 <initlog+0x6a>
  brelse(buf);
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	f7c080e7          	jalr	-132(ra) # 800033ee <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000447a:	4505                	li	a0,1
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	ebc080e7          	jalr	-324(ra) # 80004338 <install_trans>
  log.lh.n = 0;
    80004484:	0001d797          	auipc	a5,0x1d
    80004488:	1407ac23          	sw	zero,344(a5) # 800215dc <log+0x2c>
  write_head(); // clear the log
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	e30080e7          	jalr	-464(ra) # 800042bc <write_head>
}
    80004494:	70a2                	ld	ra,40(sp)
    80004496:	7402                	ld	s0,32(sp)
    80004498:	64e2                	ld	s1,24(sp)
    8000449a:	6942                	ld	s2,16(sp)
    8000449c:	69a2                	ld	s3,8(sp)
    8000449e:	6145                	addi	sp,sp,48
    800044a0:	8082                	ret

00000000800044a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	e04a                	sd	s2,0(sp)
    800044ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044ae:	0001d517          	auipc	a0,0x1d
    800044b2:	10250513          	addi	a0,a0,258 # 800215b0 <log>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	720080e7          	jalr	1824(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800044be:	0001d497          	auipc	s1,0x1d
    800044c2:	0f248493          	addi	s1,s1,242 # 800215b0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044c6:	4979                	li	s2,30
    800044c8:	a039                	j	800044d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ca:	85a6                	mv	a1,s1
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffe097          	auipc	ra,0xffffe
    800044d2:	e54080e7          	jalr	-428(ra) # 80002322 <sleep>
    if(log.committing){
    800044d6:	50dc                	lw	a5,36(s1)
    800044d8:	fbed                	bnez	a5,800044ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044da:	5098                	lw	a4,32(s1)
    800044dc:	2705                	addiw	a4,a4,1
    800044de:	0007069b          	sext.w	a3,a4
    800044e2:	0027179b          	slliw	a5,a4,0x2
    800044e6:	9fb9                	addw	a5,a5,a4
    800044e8:	0017979b          	slliw	a5,a5,0x1
    800044ec:	54d8                	lw	a4,44(s1)
    800044ee:	9fb9                	addw	a5,a5,a4
    800044f0:	00f95963          	bge	s2,a5,80004502 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044f4:	85a6                	mv	a1,s1
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	e2a080e7          	jalr	-470(ra) # 80002322 <sleep>
    80004500:	bfd9                	j	800044d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004502:	0001d517          	auipc	a0,0x1d
    80004506:	0ae50513          	addi	a0,a0,174 # 800215b0 <log>
    8000450a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	77e080e7          	jalr	1918(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004520:	7139                	addi	sp,sp,-64
    80004522:	fc06                	sd	ra,56(sp)
    80004524:	f822                	sd	s0,48(sp)
    80004526:	f426                	sd	s1,40(sp)
    80004528:	f04a                	sd	s2,32(sp)
    8000452a:	ec4e                	sd	s3,24(sp)
    8000452c:	e852                	sd	s4,16(sp)
    8000452e:	e456                	sd	s5,8(sp)
    80004530:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004532:	0001d497          	auipc	s1,0x1d
    80004536:	07e48493          	addi	s1,s1,126 # 800215b0 <log>
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	69a080e7          	jalr	1690(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004544:	509c                	lw	a5,32(s1)
    80004546:	37fd                	addiw	a5,a5,-1
    80004548:	0007891b          	sext.w	s2,a5
    8000454c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000454e:	50dc                	lw	a5,36(s1)
    80004550:	e7b9                	bnez	a5,8000459e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004552:	04091e63          	bnez	s2,800045ae <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004556:	0001d497          	auipc	s1,0x1d
    8000455a:	05a48493          	addi	s1,s1,90 # 800215b0 <log>
    8000455e:	4785                	li	a5,1
    80004560:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004562:	8526                	mv	a0,s1
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	726080e7          	jalr	1830(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000456c:	54dc                	lw	a5,44(s1)
    8000456e:	06f04763          	bgtz	a5,800045dc <end_op+0xbc>
    acquire(&log.lock);
    80004572:	0001d497          	auipc	s1,0x1d
    80004576:	03e48493          	addi	s1,s1,62 # 800215b0 <log>
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	65a080e7          	jalr	1626(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004584:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	dfc080e7          	jalr	-516(ra) # 80002386 <wakeup>
    release(&log.lock);
    80004592:	8526                	mv	a0,s1
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	6f6080e7          	jalr	1782(ra) # 80000c8a <release>
}
    8000459c:	a03d                	j	800045ca <end_op+0xaa>
    panic("log.committing");
    8000459e:	00004517          	auipc	a0,0x4
    800045a2:	19a50513          	addi	a0,a0,410 # 80008738 <syscalls+0x1f0>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	f9a080e7          	jalr	-102(ra) # 80000540 <panic>
    wakeup(&log);
    800045ae:	0001d497          	auipc	s1,0x1d
    800045b2:	00248493          	addi	s1,s1,2 # 800215b0 <log>
    800045b6:	8526                	mv	a0,s1
    800045b8:	ffffe097          	auipc	ra,0xffffe
    800045bc:	dce080e7          	jalr	-562(ra) # 80002386 <wakeup>
  release(&log.lock);
    800045c0:	8526                	mv	a0,s1
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	6c8080e7          	jalr	1736(ra) # 80000c8a <release>
}
    800045ca:	70e2                	ld	ra,56(sp)
    800045cc:	7442                	ld	s0,48(sp)
    800045ce:	74a2                	ld	s1,40(sp)
    800045d0:	7902                	ld	s2,32(sp)
    800045d2:	69e2                	ld	s3,24(sp)
    800045d4:	6a42                	ld	s4,16(sp)
    800045d6:	6aa2                	ld	s5,8(sp)
    800045d8:	6121                	addi	sp,sp,64
    800045da:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045dc:	0001da97          	auipc	s5,0x1d
    800045e0:	004a8a93          	addi	s5,s5,4 # 800215e0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045e4:	0001da17          	auipc	s4,0x1d
    800045e8:	fcca0a13          	addi	s4,s4,-52 # 800215b0 <log>
    800045ec:	018a2583          	lw	a1,24(s4)
    800045f0:	012585bb          	addw	a1,a1,s2
    800045f4:	2585                	addiw	a1,a1,1
    800045f6:	028a2503          	lw	a0,40(s4)
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	cc4080e7          	jalr	-828(ra) # 800032be <bread>
    80004602:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004604:	000aa583          	lw	a1,0(s5)
    80004608:	028a2503          	lw	a0,40(s4)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	cb2080e7          	jalr	-846(ra) # 800032be <bread>
    80004614:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004616:	40000613          	li	a2,1024
    8000461a:	05850593          	addi	a1,a0,88
    8000461e:	05848513          	addi	a0,s1,88
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	70c080e7          	jalr	1804(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000462a:	8526                	mv	a0,s1
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	d84080e7          	jalr	-636(ra) # 800033b0 <bwrite>
    brelse(from);
    80004634:	854e                	mv	a0,s3
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	db8080e7          	jalr	-584(ra) # 800033ee <brelse>
    brelse(to);
    8000463e:	8526                	mv	a0,s1
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	dae080e7          	jalr	-594(ra) # 800033ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004648:	2905                	addiw	s2,s2,1
    8000464a:	0a91                	addi	s5,s5,4
    8000464c:	02ca2783          	lw	a5,44(s4)
    80004650:	f8f94ee3          	blt	s2,a5,800045ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004654:	00000097          	auipc	ra,0x0
    80004658:	c68080e7          	jalr	-920(ra) # 800042bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000465c:	4501                	li	a0,0
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	cda080e7          	jalr	-806(ra) # 80004338 <install_trans>
    log.lh.n = 0;
    80004666:	0001d797          	auipc	a5,0x1d
    8000466a:	f607ab23          	sw	zero,-138(a5) # 800215dc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	c4e080e7          	jalr	-946(ra) # 800042bc <write_head>
    80004676:	bdf5                	j	80004572 <end_op+0x52>

0000000080004678 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	e04a                	sd	s2,0(sp)
    80004682:	1000                	addi	s0,sp,32
    80004684:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004686:	0001d917          	auipc	s2,0x1d
    8000468a:	f2a90913          	addi	s2,s2,-214 # 800215b0 <log>
    8000468e:	854a                	mv	a0,s2
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	546080e7          	jalr	1350(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004698:	02c92603          	lw	a2,44(s2)
    8000469c:	47f5                	li	a5,29
    8000469e:	06c7c563          	blt	a5,a2,80004708 <log_write+0x90>
    800046a2:	0001d797          	auipc	a5,0x1d
    800046a6:	f2a7a783          	lw	a5,-214(a5) # 800215cc <log+0x1c>
    800046aa:	37fd                	addiw	a5,a5,-1
    800046ac:	04f65e63          	bge	a2,a5,80004708 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046b0:	0001d797          	auipc	a5,0x1d
    800046b4:	f207a783          	lw	a5,-224(a5) # 800215d0 <log+0x20>
    800046b8:	06f05063          	blez	a5,80004718 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046bc:	4781                	li	a5,0
    800046be:	06c05563          	blez	a2,80004728 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046c2:	44cc                	lw	a1,12(s1)
    800046c4:	0001d717          	auipc	a4,0x1d
    800046c8:	f1c70713          	addi	a4,a4,-228 # 800215e0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ce:	4314                	lw	a3,0(a4)
    800046d0:	04b68c63          	beq	a3,a1,80004728 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046d4:	2785                	addiw	a5,a5,1
    800046d6:	0711                	addi	a4,a4,4
    800046d8:	fef61be3          	bne	a2,a5,800046ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046dc:	0621                	addi	a2,a2,8
    800046de:	060a                	slli	a2,a2,0x2
    800046e0:	0001d797          	auipc	a5,0x1d
    800046e4:	ed078793          	addi	a5,a5,-304 # 800215b0 <log>
    800046e8:	97b2                	add	a5,a5,a2
    800046ea:	44d8                	lw	a4,12(s1)
    800046ec:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	d9c080e7          	jalr	-612(ra) # 8000348c <bpin>
    log.lh.n++;
    800046f8:	0001d717          	auipc	a4,0x1d
    800046fc:	eb870713          	addi	a4,a4,-328 # 800215b0 <log>
    80004700:	575c                	lw	a5,44(a4)
    80004702:	2785                	addiw	a5,a5,1
    80004704:	d75c                	sw	a5,44(a4)
    80004706:	a82d                	j	80004740 <log_write+0xc8>
    panic("too big a transaction");
    80004708:	00004517          	auipc	a0,0x4
    8000470c:	04050513          	addi	a0,a0,64 # 80008748 <syscalls+0x200>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	e30080e7          	jalr	-464(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	04850513          	addi	a0,a0,72 # 80008760 <syscalls+0x218>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e20080e7          	jalr	-480(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004728:	00878693          	addi	a3,a5,8
    8000472c:	068a                	slli	a3,a3,0x2
    8000472e:	0001d717          	auipc	a4,0x1d
    80004732:	e8270713          	addi	a4,a4,-382 # 800215b0 <log>
    80004736:	9736                	add	a4,a4,a3
    80004738:	44d4                	lw	a3,12(s1)
    8000473a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000473c:	faf609e3          	beq	a2,a5,800046ee <log_write+0x76>
  }
  release(&log.lock);
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	e7050513          	addi	a0,a0,-400 # 800215b0 <log>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	542080e7          	jalr	1346(ra) # 80000c8a <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	e04a                	sd	s2,0(sp)
    80004766:	1000                	addi	s0,sp,32
    80004768:	84aa                	mv	s1,a0
    8000476a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000476c:	00004597          	auipc	a1,0x4
    80004770:	01458593          	addi	a1,a1,20 # 80008780 <syscalls+0x238>
    80004774:	0521                	addi	a0,a0,8
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	3d0080e7          	jalr	976(ra) # 80000b46 <initlock>
  lk->name = name;
    8000477e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004782:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004786:	0204a423          	sw	zero,40(s1)
}
    8000478a:	60e2                	ld	ra,24(sp)
    8000478c:	6442                	ld	s0,16(sp)
    8000478e:	64a2                	ld	s1,8(sp)
    80004790:	6902                	ld	s2,0(sp)
    80004792:	6105                	addi	sp,sp,32
    80004794:	8082                	ret

0000000080004796 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004796:	1101                	addi	sp,sp,-32
    80004798:	ec06                	sd	ra,24(sp)
    8000479a:	e822                	sd	s0,16(sp)
    8000479c:	e426                	sd	s1,8(sp)
    8000479e:	e04a                	sd	s2,0(sp)
    800047a0:	1000                	addi	s0,sp,32
    800047a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047a4:	00850913          	addi	s2,a0,8
    800047a8:	854a                	mv	a0,s2
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	42c080e7          	jalr	1068(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800047b2:	409c                	lw	a5,0(s1)
    800047b4:	cb89                	beqz	a5,800047c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047b6:	85ca                	mv	a1,s2
    800047b8:	8526                	mv	a0,s1
    800047ba:	ffffe097          	auipc	ra,0xffffe
    800047be:	b68080e7          	jalr	-1176(ra) # 80002322 <sleep>
  while (lk->locked) {
    800047c2:	409c                	lw	a5,0(s1)
    800047c4:	fbed                	bnez	a5,800047b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047c6:	4785                	li	a5,1
    800047c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047ca:	ffffd097          	auipc	ra,0xffffd
    800047ce:	280080e7          	jalr	640(ra) # 80001a4a <myproc>
    800047d2:	591c                	lw	a5,48(a0)
    800047d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047d6:	854a                	mv	a0,s2
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4b2080e7          	jalr	1202(ra) # 80000c8a <release>
}
    800047e0:	60e2                	ld	ra,24(sp)
    800047e2:	6442                	ld	s0,16(sp)
    800047e4:	64a2                	ld	s1,8(sp)
    800047e6:	6902                	ld	s2,0(sp)
    800047e8:	6105                	addi	sp,sp,32
    800047ea:	8082                	ret

00000000800047ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047ec:	1101                	addi	sp,sp,-32
    800047ee:	ec06                	sd	ra,24(sp)
    800047f0:	e822                	sd	s0,16(sp)
    800047f2:	e426                	sd	s1,8(sp)
    800047f4:	e04a                	sd	s2,0(sp)
    800047f6:	1000                	addi	s0,sp,32
    800047f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047fa:	00850913          	addi	s2,a0,8
    800047fe:	854a                	mv	a0,s2
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	3d6080e7          	jalr	982(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004808:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000480c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004810:	8526                	mv	a0,s1
    80004812:	ffffe097          	auipc	ra,0xffffe
    80004816:	b74080e7          	jalr	-1164(ra) # 80002386 <wakeup>
  release(&lk->lk);
    8000481a:	854a                	mv	a0,s2
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	46e080e7          	jalr	1134(ra) # 80000c8a <release>
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004830:	7179                	addi	sp,sp,-48
    80004832:	f406                	sd	ra,40(sp)
    80004834:	f022                	sd	s0,32(sp)
    80004836:	ec26                	sd	s1,24(sp)
    80004838:	e84a                	sd	s2,16(sp)
    8000483a:	e44e                	sd	s3,8(sp)
    8000483c:	1800                	addi	s0,sp,48
    8000483e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004840:	00850913          	addi	s2,a0,8
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	390080e7          	jalr	912(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000484e:	409c                	lw	a5,0(s1)
    80004850:	ef99                	bnez	a5,8000486e <holdingsleep+0x3e>
    80004852:	4481                	li	s1,0
  release(&lk->lk);
    80004854:	854a                	mv	a0,s2
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	434080e7          	jalr	1076(ra) # 80000c8a <release>
  return r;
}
    8000485e:	8526                	mv	a0,s1
    80004860:	70a2                	ld	ra,40(sp)
    80004862:	7402                	ld	s0,32(sp)
    80004864:	64e2                	ld	s1,24(sp)
    80004866:	6942                	ld	s2,16(sp)
    80004868:	69a2                	ld	s3,8(sp)
    8000486a:	6145                	addi	sp,sp,48
    8000486c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000486e:	0284a983          	lw	s3,40(s1)
    80004872:	ffffd097          	auipc	ra,0xffffd
    80004876:	1d8080e7          	jalr	472(ra) # 80001a4a <myproc>
    8000487a:	5904                	lw	s1,48(a0)
    8000487c:	413484b3          	sub	s1,s1,s3
    80004880:	0014b493          	seqz	s1,s1
    80004884:	bfc1                	j	80004854 <holdingsleep+0x24>

0000000080004886 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004886:	1141                	addi	sp,sp,-16
    80004888:	e406                	sd	ra,8(sp)
    8000488a:	e022                	sd	s0,0(sp)
    8000488c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000488e:	00004597          	auipc	a1,0x4
    80004892:	f0258593          	addi	a1,a1,-254 # 80008790 <syscalls+0x248>
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	e6250513          	addi	a0,a0,-414 # 800216f8 <ftable>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	2a8080e7          	jalr	680(ra) # 80000b46 <initlock>
}
    800048a6:	60a2                	ld	ra,8(sp)
    800048a8:	6402                	ld	s0,0(sp)
    800048aa:	0141                	addi	sp,sp,16
    800048ac:	8082                	ret

00000000800048ae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048ae:	1101                	addi	sp,sp,-32
    800048b0:	ec06                	sd	ra,24(sp)
    800048b2:	e822                	sd	s0,16(sp)
    800048b4:	e426                	sd	s1,8(sp)
    800048b6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	e4050513          	addi	a0,a0,-448 # 800216f8 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	316080e7          	jalr	790(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048c8:	0001d497          	auipc	s1,0x1d
    800048cc:	e4848493          	addi	s1,s1,-440 # 80021710 <ftable+0x18>
    800048d0:	0001e717          	auipc	a4,0x1e
    800048d4:	de070713          	addi	a4,a4,-544 # 800226b0 <disk>
    if(f->ref == 0){
    800048d8:	40dc                	lw	a5,4(s1)
    800048da:	cf99                	beqz	a5,800048f8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048dc:	02848493          	addi	s1,s1,40
    800048e0:	fee49ce3          	bne	s1,a4,800048d8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	e1450513          	addi	a0,a0,-492 # 800216f8 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	39e080e7          	jalr	926(ra) # 80000c8a <release>
  return 0;
    800048f4:	4481                	li	s1,0
    800048f6:	a819                	j	8000490c <filealloc+0x5e>
      f->ref = 1;
    800048f8:	4785                	li	a5,1
    800048fa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048fc:	0001d517          	auipc	a0,0x1d
    80004900:	dfc50513          	addi	a0,a0,-516 # 800216f8 <ftable>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	386080e7          	jalr	902(ra) # 80000c8a <release>
}
    8000490c:	8526                	mv	a0,s1
    8000490e:	60e2                	ld	ra,24(sp)
    80004910:	6442                	ld	s0,16(sp)
    80004912:	64a2                	ld	s1,8(sp)
    80004914:	6105                	addi	sp,sp,32
    80004916:	8082                	ret

0000000080004918 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004918:	1101                	addi	sp,sp,-32
    8000491a:	ec06                	sd	ra,24(sp)
    8000491c:	e822                	sd	s0,16(sp)
    8000491e:	e426                	sd	s1,8(sp)
    80004920:	1000                	addi	s0,sp,32
    80004922:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004924:	0001d517          	auipc	a0,0x1d
    80004928:	dd450513          	addi	a0,a0,-556 # 800216f8 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	2aa080e7          	jalr	682(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004934:	40dc                	lw	a5,4(s1)
    80004936:	02f05263          	blez	a5,8000495a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000493a:	2785                	addiw	a5,a5,1
    8000493c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000493e:	0001d517          	auipc	a0,0x1d
    80004942:	dba50513          	addi	a0,a0,-582 # 800216f8 <ftable>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	344080e7          	jalr	836(ra) # 80000c8a <release>
  return f;
}
    8000494e:	8526                	mv	a0,s1
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6105                	addi	sp,sp,32
    80004958:	8082                	ret
    panic("filedup");
    8000495a:	00004517          	auipc	a0,0x4
    8000495e:	e3e50513          	addi	a0,a0,-450 # 80008798 <syscalls+0x250>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	bde080e7          	jalr	-1058(ra) # 80000540 <panic>

000000008000496a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000496a:	7139                	addi	sp,sp,-64
    8000496c:	fc06                	sd	ra,56(sp)
    8000496e:	f822                	sd	s0,48(sp)
    80004970:	f426                	sd	s1,40(sp)
    80004972:	f04a                	sd	s2,32(sp)
    80004974:	ec4e                	sd	s3,24(sp)
    80004976:	e852                	sd	s4,16(sp)
    80004978:	e456                	sd	s5,8(sp)
    8000497a:	0080                	addi	s0,sp,64
    8000497c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000497e:	0001d517          	auipc	a0,0x1d
    80004982:	d7a50513          	addi	a0,a0,-646 # 800216f8 <ftable>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000498e:	40dc                	lw	a5,4(s1)
    80004990:	06f05163          	blez	a5,800049f2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004994:	37fd                	addiw	a5,a5,-1
    80004996:	0007871b          	sext.w	a4,a5
    8000499a:	c0dc                	sw	a5,4(s1)
    8000499c:	06e04363          	bgtz	a4,80004a02 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049a0:	0004a903          	lw	s2,0(s1)
    800049a4:	0094ca83          	lbu	s5,9(s1)
    800049a8:	0104ba03          	ld	s4,16(s1)
    800049ac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049b0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049b4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049b8:	0001d517          	auipc	a0,0x1d
    800049bc:	d4050513          	addi	a0,a0,-704 # 800216f8 <ftable>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	2ca080e7          	jalr	714(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049c8:	4785                	li	a5,1
    800049ca:	04f90d63          	beq	s2,a5,80004a24 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049ce:	3979                	addiw	s2,s2,-2
    800049d0:	4785                	li	a5,1
    800049d2:	0527e063          	bltu	a5,s2,80004a12 <fileclose+0xa8>
    begin_op();
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	acc080e7          	jalr	-1332(ra) # 800044a2 <begin_op>
    iput(ff.ip);
    800049de:	854e                	mv	a0,s3
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	2b0080e7          	jalr	688(ra) # 80003c90 <iput>
    end_op();
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	b38080e7          	jalr	-1224(ra) # 80004520 <end_op>
    800049f0:	a00d                	j	80004a12 <fileclose+0xa8>
    panic("fileclose");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	dae50513          	addi	a0,a0,-594 # 800087a0 <syscalls+0x258>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b46080e7          	jalr	-1210(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	cf650513          	addi	a0,a0,-778 # 800216f8 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
  }
}
    80004a12:	70e2                	ld	ra,56(sp)
    80004a14:	7442                	ld	s0,48(sp)
    80004a16:	74a2                	ld	s1,40(sp)
    80004a18:	7902                	ld	s2,32(sp)
    80004a1a:	69e2                	ld	s3,24(sp)
    80004a1c:	6a42                	ld	s4,16(sp)
    80004a1e:	6aa2                	ld	s5,8(sp)
    80004a20:	6121                	addi	sp,sp,64
    80004a22:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a24:	85d6                	mv	a1,s5
    80004a26:	8552                	mv	a0,s4
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	34c080e7          	jalr	844(ra) # 80004d74 <pipeclose>
    80004a30:	b7cd                	j	80004a12 <fileclose+0xa8>

0000000080004a32 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a32:	715d                	addi	sp,sp,-80
    80004a34:	e486                	sd	ra,72(sp)
    80004a36:	e0a2                	sd	s0,64(sp)
    80004a38:	fc26                	sd	s1,56(sp)
    80004a3a:	f84a                	sd	s2,48(sp)
    80004a3c:	f44e                	sd	s3,40(sp)
    80004a3e:	0880                	addi	s0,sp,80
    80004a40:	84aa                	mv	s1,a0
    80004a42:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	006080e7          	jalr	6(ra) # 80001a4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a4c:	409c                	lw	a5,0(s1)
    80004a4e:	37f9                	addiw	a5,a5,-2
    80004a50:	4705                	li	a4,1
    80004a52:	04f76763          	bltu	a4,a5,80004aa0 <filestat+0x6e>
    80004a56:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	07c080e7          	jalr	124(ra) # 80003ad6 <ilock>
    stati(f->ip, &st);
    80004a62:	fb840593          	addi	a1,s0,-72
    80004a66:	6c88                	ld	a0,24(s1)
    80004a68:	fffff097          	auipc	ra,0xfffff
    80004a6c:	2f8080e7          	jalr	760(ra) # 80003d60 <stati>
    iunlock(f->ip);
    80004a70:	6c88                	ld	a0,24(s1)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	126080e7          	jalr	294(ra) # 80003b98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a7a:	46e1                	li	a3,24
    80004a7c:	fb840613          	addi	a2,s0,-72
    80004a80:	85ce                	mv	a1,s3
    80004a82:	05893503          	ld	a0,88(s2)
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	be6080e7          	jalr	-1050(ra) # 8000166c <copyout>
    80004a8e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a92:	60a6                	ld	ra,72(sp)
    80004a94:	6406                	ld	s0,64(sp)
    80004a96:	74e2                	ld	s1,56(sp)
    80004a98:	7942                	ld	s2,48(sp)
    80004a9a:	79a2                	ld	s3,40(sp)
    80004a9c:	6161                	addi	sp,sp,80
    80004a9e:	8082                	ret
  return -1;
    80004aa0:	557d                	li	a0,-1
    80004aa2:	bfc5                	j	80004a92 <filestat+0x60>

0000000080004aa4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aa4:	7179                	addi	sp,sp,-48
    80004aa6:	f406                	sd	ra,40(sp)
    80004aa8:	f022                	sd	s0,32(sp)
    80004aaa:	ec26                	sd	s1,24(sp)
    80004aac:	e84a                	sd	s2,16(sp)
    80004aae:	e44e                	sd	s3,8(sp)
    80004ab0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ab2:	00854783          	lbu	a5,8(a0)
    80004ab6:	c3d5                	beqz	a5,80004b5a <fileread+0xb6>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	89ae                	mv	s3,a1
    80004abc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004abe:	411c                	lw	a5,0(a0)
    80004ac0:	4705                	li	a4,1
    80004ac2:	04e78963          	beq	a5,a4,80004b14 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ac6:	470d                	li	a4,3
    80004ac8:	04e78d63          	beq	a5,a4,80004b22 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004acc:	4709                	li	a4,2
    80004ace:	06e79e63          	bne	a5,a4,80004b4a <fileread+0xa6>
    ilock(f->ip);
    80004ad2:	6d08                	ld	a0,24(a0)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	002080e7          	jalr	2(ra) # 80003ad6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004adc:	874a                	mv	a4,s2
    80004ade:	5094                	lw	a3,32(s1)
    80004ae0:	864e                	mv	a2,s3
    80004ae2:	4585                	li	a1,1
    80004ae4:	6c88                	ld	a0,24(s1)
    80004ae6:	fffff097          	auipc	ra,0xfffff
    80004aea:	2a4080e7          	jalr	676(ra) # 80003d8a <readi>
    80004aee:	892a                	mv	s2,a0
    80004af0:	00a05563          	blez	a0,80004afa <fileread+0x56>
      f->off += r;
    80004af4:	509c                	lw	a5,32(s1)
    80004af6:	9fa9                	addw	a5,a5,a0
    80004af8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004afa:	6c88                	ld	a0,24(s1)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	09c080e7          	jalr	156(ra) # 80003b98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b04:	854a                	mv	a0,s2
    80004b06:	70a2                	ld	ra,40(sp)
    80004b08:	7402                	ld	s0,32(sp)
    80004b0a:	64e2                	ld	s1,24(sp)
    80004b0c:	6942                	ld	s2,16(sp)
    80004b0e:	69a2                	ld	s3,8(sp)
    80004b10:	6145                	addi	sp,sp,48
    80004b12:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b14:	6908                	ld	a0,16(a0)
    80004b16:	00000097          	auipc	ra,0x0
    80004b1a:	3c6080e7          	jalr	966(ra) # 80004edc <piperead>
    80004b1e:	892a                	mv	s2,a0
    80004b20:	b7d5                	j	80004b04 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b22:	02451783          	lh	a5,36(a0)
    80004b26:	03079693          	slli	a3,a5,0x30
    80004b2a:	92c1                	srli	a3,a3,0x30
    80004b2c:	4725                	li	a4,9
    80004b2e:	02d76863          	bltu	a4,a3,80004b5e <fileread+0xba>
    80004b32:	0792                	slli	a5,a5,0x4
    80004b34:	0001d717          	auipc	a4,0x1d
    80004b38:	b2470713          	addi	a4,a4,-1244 # 80021658 <devsw>
    80004b3c:	97ba                	add	a5,a5,a4
    80004b3e:	639c                	ld	a5,0(a5)
    80004b40:	c38d                	beqz	a5,80004b62 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b42:	4505                	li	a0,1
    80004b44:	9782                	jalr	a5
    80004b46:	892a                	mv	s2,a0
    80004b48:	bf75                	j	80004b04 <fileread+0x60>
    panic("fileread");
    80004b4a:	00004517          	auipc	a0,0x4
    80004b4e:	c6650513          	addi	a0,a0,-922 # 800087b0 <syscalls+0x268>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	9ee080e7          	jalr	-1554(ra) # 80000540 <panic>
    return -1;
    80004b5a:	597d                	li	s2,-1
    80004b5c:	b765                	j	80004b04 <fileread+0x60>
      return -1;
    80004b5e:	597d                	li	s2,-1
    80004b60:	b755                	j	80004b04 <fileread+0x60>
    80004b62:	597d                	li	s2,-1
    80004b64:	b745                	j	80004b04 <fileread+0x60>

0000000080004b66 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b66:	715d                	addi	sp,sp,-80
    80004b68:	e486                	sd	ra,72(sp)
    80004b6a:	e0a2                	sd	s0,64(sp)
    80004b6c:	fc26                	sd	s1,56(sp)
    80004b6e:	f84a                	sd	s2,48(sp)
    80004b70:	f44e                	sd	s3,40(sp)
    80004b72:	f052                	sd	s4,32(sp)
    80004b74:	ec56                	sd	s5,24(sp)
    80004b76:	e85a                	sd	s6,16(sp)
    80004b78:	e45e                	sd	s7,8(sp)
    80004b7a:	e062                	sd	s8,0(sp)
    80004b7c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b7e:	00954783          	lbu	a5,9(a0)
    80004b82:	10078663          	beqz	a5,80004c8e <filewrite+0x128>
    80004b86:	892a                	mv	s2,a0
    80004b88:	8b2e                	mv	s6,a1
    80004b8a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b8c:	411c                	lw	a5,0(a0)
    80004b8e:	4705                	li	a4,1
    80004b90:	02e78263          	beq	a5,a4,80004bb4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b94:	470d                	li	a4,3
    80004b96:	02e78663          	beq	a5,a4,80004bc2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b9a:	4709                	li	a4,2
    80004b9c:	0ee79163          	bne	a5,a4,80004c7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ba0:	0ac05d63          	blez	a2,80004c5a <filewrite+0xf4>
    int i = 0;
    80004ba4:	4981                	li	s3,0
    80004ba6:	6b85                	lui	s7,0x1
    80004ba8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bac:	6c05                	lui	s8,0x1
    80004bae:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bb2:	a861                	j	80004c4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bb4:	6908                	ld	a0,16(a0)
    80004bb6:	00000097          	auipc	ra,0x0
    80004bba:	22e080e7          	jalr	558(ra) # 80004de4 <pipewrite>
    80004bbe:	8a2a                	mv	s4,a0
    80004bc0:	a045                	j	80004c60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bc2:	02451783          	lh	a5,36(a0)
    80004bc6:	03079693          	slli	a3,a5,0x30
    80004bca:	92c1                	srli	a3,a3,0x30
    80004bcc:	4725                	li	a4,9
    80004bce:	0cd76263          	bltu	a4,a3,80004c92 <filewrite+0x12c>
    80004bd2:	0792                	slli	a5,a5,0x4
    80004bd4:	0001d717          	auipc	a4,0x1d
    80004bd8:	a8470713          	addi	a4,a4,-1404 # 80021658 <devsw>
    80004bdc:	97ba                	add	a5,a5,a4
    80004bde:	679c                	ld	a5,8(a5)
    80004be0:	cbdd                	beqz	a5,80004c96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004be2:	4505                	li	a0,1
    80004be4:	9782                	jalr	a5
    80004be6:	8a2a                	mv	s4,a0
    80004be8:	a8a5                	j	80004c60 <filewrite+0xfa>
    80004bea:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	8b4080e7          	jalr	-1868(ra) # 800044a2 <begin_op>
      ilock(f->ip);
    80004bf6:	01893503          	ld	a0,24(s2)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	edc080e7          	jalr	-292(ra) # 80003ad6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c02:	8756                	mv	a4,s5
    80004c04:	02092683          	lw	a3,32(s2)
    80004c08:	01698633          	add	a2,s3,s6
    80004c0c:	4585                	li	a1,1
    80004c0e:	01893503          	ld	a0,24(s2)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	270080e7          	jalr	624(ra) # 80003e82 <writei>
    80004c1a:	84aa                	mv	s1,a0
    80004c1c:	00a05763          	blez	a0,80004c2a <filewrite+0xc4>
        f->off += r;
    80004c20:	02092783          	lw	a5,32(s2)
    80004c24:	9fa9                	addw	a5,a5,a0
    80004c26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c2a:	01893503          	ld	a0,24(s2)
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	f6a080e7          	jalr	-150(ra) # 80003b98 <iunlock>
      end_op();
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	8ea080e7          	jalr	-1814(ra) # 80004520 <end_op>

      if(r != n1){
    80004c3e:	009a9f63          	bne	s5,s1,80004c5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c46:	0149db63          	bge	s3,s4,80004c5c <filewrite+0xf6>
      int n1 = n - i;
    80004c4a:	413a04bb          	subw	s1,s4,s3
    80004c4e:	0004879b          	sext.w	a5,s1
    80004c52:	f8fbdce3          	bge	s7,a5,80004bea <filewrite+0x84>
    80004c56:	84e2                	mv	s1,s8
    80004c58:	bf49                	j	80004bea <filewrite+0x84>
    int i = 0;
    80004c5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c5c:	013a1f63          	bne	s4,s3,80004c7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c60:	8552                	mv	a0,s4
    80004c62:	60a6                	ld	ra,72(sp)
    80004c64:	6406                	ld	s0,64(sp)
    80004c66:	74e2                	ld	s1,56(sp)
    80004c68:	7942                	ld	s2,48(sp)
    80004c6a:	79a2                	ld	s3,40(sp)
    80004c6c:	7a02                	ld	s4,32(sp)
    80004c6e:	6ae2                	ld	s5,24(sp)
    80004c70:	6b42                	ld	s6,16(sp)
    80004c72:	6ba2                	ld	s7,8(sp)
    80004c74:	6c02                	ld	s8,0(sp)
    80004c76:	6161                	addi	sp,sp,80
    80004c78:	8082                	ret
    ret = (i == n ? n : -1);
    80004c7a:	5a7d                	li	s4,-1
    80004c7c:	b7d5                	j	80004c60 <filewrite+0xfa>
    panic("filewrite");
    80004c7e:	00004517          	auipc	a0,0x4
    80004c82:	b4250513          	addi	a0,a0,-1214 # 800087c0 <syscalls+0x278>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	8ba080e7          	jalr	-1862(ra) # 80000540 <panic>
    return -1;
    80004c8e:	5a7d                	li	s4,-1
    80004c90:	bfc1                	j	80004c60 <filewrite+0xfa>
      return -1;
    80004c92:	5a7d                	li	s4,-1
    80004c94:	b7f1                	j	80004c60 <filewrite+0xfa>
    80004c96:	5a7d                	li	s4,-1
    80004c98:	b7e1                	j	80004c60 <filewrite+0xfa>

0000000080004c9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c9a:	7179                	addi	sp,sp,-48
    80004c9c:	f406                	sd	ra,40(sp)
    80004c9e:	f022                	sd	s0,32(sp)
    80004ca0:	ec26                	sd	s1,24(sp)
    80004ca2:	e84a                	sd	s2,16(sp)
    80004ca4:	e44e                	sd	s3,8(sp)
    80004ca6:	e052                	sd	s4,0(sp)
    80004ca8:	1800                	addi	s0,sp,48
    80004caa:	84aa                	mv	s1,a0
    80004cac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cae:	0005b023          	sd	zero,0(a1)
    80004cb2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cb6:	00000097          	auipc	ra,0x0
    80004cba:	bf8080e7          	jalr	-1032(ra) # 800048ae <filealloc>
    80004cbe:	e088                	sd	a0,0(s1)
    80004cc0:	c551                	beqz	a0,80004d4c <pipealloc+0xb2>
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	bec080e7          	jalr	-1044(ra) # 800048ae <filealloc>
    80004cca:	00aa3023          	sd	a0,0(s4)
    80004cce:	c92d                	beqz	a0,80004d40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	e16080e7          	jalr	-490(ra) # 80000ae6 <kalloc>
    80004cd8:	892a                	mv	s2,a0
    80004cda:	c125                	beqz	a0,80004d3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cdc:	4985                	li	s3,1
    80004cde:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ce2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ce6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cee:	00003597          	auipc	a1,0x3
    80004cf2:	7a258593          	addi	a1,a1,1954 # 80008490 <states.0+0x1c0>
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	e50080e7          	jalr	-432(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004cfe:	609c                	ld	a5,0(s1)
    80004d00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d04:	609c                	ld	a5,0(s1)
    80004d06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d0a:	609c                	ld	a5,0(s1)
    80004d0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d10:	609c                	ld	a5,0(s1)
    80004d12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d16:	000a3783          	ld	a5,0(s4)
    80004d1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d1e:	000a3783          	ld	a5,0(s4)
    80004d22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d26:	000a3783          	ld	a5,0(s4)
    80004d2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d2e:	000a3783          	ld	a5,0(s4)
    80004d32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d36:	4501                	li	a0,0
    80004d38:	a025                	j	80004d60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d3a:	6088                	ld	a0,0(s1)
    80004d3c:	e501                	bnez	a0,80004d44 <pipealloc+0xaa>
    80004d3e:	a039                	j	80004d4c <pipealloc+0xb2>
    80004d40:	6088                	ld	a0,0(s1)
    80004d42:	c51d                	beqz	a0,80004d70 <pipealloc+0xd6>
    fileclose(*f0);
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	c26080e7          	jalr	-986(ra) # 8000496a <fileclose>
  if(*f1)
    80004d4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d50:	557d                	li	a0,-1
  if(*f1)
    80004d52:	c799                	beqz	a5,80004d60 <pipealloc+0xc6>
    fileclose(*f1);
    80004d54:	853e                	mv	a0,a5
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	c14080e7          	jalr	-1004(ra) # 8000496a <fileclose>
  return -1;
    80004d5e:	557d                	li	a0,-1
}
    80004d60:	70a2                	ld	ra,40(sp)
    80004d62:	7402                	ld	s0,32(sp)
    80004d64:	64e2                	ld	s1,24(sp)
    80004d66:	6942                	ld	s2,16(sp)
    80004d68:	69a2                	ld	s3,8(sp)
    80004d6a:	6a02                	ld	s4,0(sp)
    80004d6c:	6145                	addi	sp,sp,48
    80004d6e:	8082                	ret
  return -1;
    80004d70:	557d                	li	a0,-1
    80004d72:	b7fd                	j	80004d60 <pipealloc+0xc6>

0000000080004d74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d74:	1101                	addi	sp,sp,-32
    80004d76:	ec06                	sd	ra,24(sp)
    80004d78:	e822                	sd	s0,16(sp)
    80004d7a:	e426                	sd	s1,8(sp)
    80004d7c:	e04a                	sd	s2,0(sp)
    80004d7e:	1000                	addi	s0,sp,32
    80004d80:	84aa                	mv	s1,a0
    80004d82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	e52080e7          	jalr	-430(ra) # 80000bd6 <acquire>
  if(writable){
    80004d8c:	02090d63          	beqz	s2,80004dc6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d94:	21848513          	addi	a0,s1,536
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	5ee080e7          	jalr	1518(ra) # 80002386 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004da0:	2204b783          	ld	a5,544(s1)
    80004da4:	eb95                	bnez	a5,80004dd8 <pipeclose+0x64>
    release(&pi->lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	ee2080e7          	jalr	-286(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	c36080e7          	jalr	-970(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004dba:	60e2                	ld	ra,24(sp)
    80004dbc:	6442                	ld	s0,16(sp)
    80004dbe:	64a2                	ld	s1,8(sp)
    80004dc0:	6902                	ld	s2,0(sp)
    80004dc2:	6105                	addi	sp,sp,32
    80004dc4:	8082                	ret
    pi->readopen = 0;
    80004dc6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dca:	21c48513          	addi	a0,s1,540
    80004dce:	ffffd097          	auipc	ra,0xffffd
    80004dd2:	5b8080e7          	jalr	1464(ra) # 80002386 <wakeup>
    80004dd6:	b7e9                	j	80004da0 <pipeclose+0x2c>
    release(&pi->lock);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	eb0080e7          	jalr	-336(ra) # 80000c8a <release>
}
    80004de2:	bfe1                	j	80004dba <pipeclose+0x46>

0000000080004de4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004de4:	711d                	addi	sp,sp,-96
    80004de6:	ec86                	sd	ra,88(sp)
    80004de8:	e8a2                	sd	s0,80(sp)
    80004dea:	e4a6                	sd	s1,72(sp)
    80004dec:	e0ca                	sd	s2,64(sp)
    80004dee:	fc4e                	sd	s3,56(sp)
    80004df0:	f852                	sd	s4,48(sp)
    80004df2:	f456                	sd	s5,40(sp)
    80004df4:	f05a                	sd	s6,32(sp)
    80004df6:	ec5e                	sd	s7,24(sp)
    80004df8:	e862                	sd	s8,16(sp)
    80004dfa:	1080                	addi	s0,sp,96
    80004dfc:	84aa                	mv	s1,a0
    80004dfe:	8aae                	mv	s5,a1
    80004e00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	c48080e7          	jalr	-952(ra) # 80001a4a <myproc>
    80004e0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	dc8080e7          	jalr	-568(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e16:	0b405663          	blez	s4,80004ec2 <pipewrite+0xde>
  int i = 0;
    80004e1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e1e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e22:	21c48b93          	addi	s7,s1,540
    80004e26:	a089                	j	80004e68 <pipewrite+0x84>
      release(&pi->lock);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	e60080e7          	jalr	-416(ra) # 80000c8a <release>
      return -1;
    80004e32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e34:	854a                	mv	a0,s2
    80004e36:	60e6                	ld	ra,88(sp)
    80004e38:	6446                	ld	s0,80(sp)
    80004e3a:	64a6                	ld	s1,72(sp)
    80004e3c:	6906                	ld	s2,64(sp)
    80004e3e:	79e2                	ld	s3,56(sp)
    80004e40:	7a42                	ld	s4,48(sp)
    80004e42:	7aa2                	ld	s5,40(sp)
    80004e44:	7b02                	ld	s6,32(sp)
    80004e46:	6be2                	ld	s7,24(sp)
    80004e48:	6c42                	ld	s8,16(sp)
    80004e4a:	6125                	addi	sp,sp,96
    80004e4c:	8082                	ret
      wakeup(&pi->nread);
    80004e4e:	8562                	mv	a0,s8
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	536080e7          	jalr	1334(ra) # 80002386 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e58:	85a6                	mv	a1,s1
    80004e5a:	855e                	mv	a0,s7
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	4c6080e7          	jalr	1222(ra) # 80002322 <sleep>
  while(i < n){
    80004e64:	07495063          	bge	s2,s4,80004ec4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e68:	2204a783          	lw	a5,544(s1)
    80004e6c:	dfd5                	beqz	a5,80004e28 <pipewrite+0x44>
    80004e6e:	854e                	mv	a0,s3
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	75a080e7          	jalr	1882(ra) # 800025ca <killed>
    80004e78:	f945                	bnez	a0,80004e28 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e7a:	2184a783          	lw	a5,536(s1)
    80004e7e:	21c4a703          	lw	a4,540(s1)
    80004e82:	2007879b          	addiw	a5,a5,512
    80004e86:	fcf704e3          	beq	a4,a5,80004e4e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8a:	4685                	li	a3,1
    80004e8c:	01590633          	add	a2,s2,s5
    80004e90:	faf40593          	addi	a1,s0,-81
    80004e94:	0589b503          	ld	a0,88(s3)
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	860080e7          	jalr	-1952(ra) # 800016f8 <copyin>
    80004ea0:	03650263          	beq	a0,s6,80004ec4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ea4:	21c4a783          	lw	a5,540(s1)
    80004ea8:	0017871b          	addiw	a4,a5,1
    80004eac:	20e4ae23          	sw	a4,540(s1)
    80004eb0:	1ff7f793          	andi	a5,a5,511
    80004eb4:	97a6                	add	a5,a5,s1
    80004eb6:	faf44703          	lbu	a4,-81(s0)
    80004eba:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ebe:	2905                	addiw	s2,s2,1
    80004ec0:	b755                	j	80004e64 <pipewrite+0x80>
  int i = 0;
    80004ec2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ec4:	21848513          	addi	a0,s1,536
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	4be080e7          	jalr	1214(ra) # 80002386 <wakeup>
  release(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	db8080e7          	jalr	-584(ra) # 80000c8a <release>
  return i;
    80004eda:	bfa9                	j	80004e34 <pipewrite+0x50>

0000000080004edc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004edc:	715d                	addi	sp,sp,-80
    80004ede:	e486                	sd	ra,72(sp)
    80004ee0:	e0a2                	sd	s0,64(sp)
    80004ee2:	fc26                	sd	s1,56(sp)
    80004ee4:	f84a                	sd	s2,48(sp)
    80004ee6:	f44e                	sd	s3,40(sp)
    80004ee8:	f052                	sd	s4,32(sp)
    80004eea:	ec56                	sd	s5,24(sp)
    80004eec:	e85a                	sd	s6,16(sp)
    80004eee:	0880                	addi	s0,sp,80
    80004ef0:	84aa                	mv	s1,a0
    80004ef2:	892e                	mv	s2,a1
    80004ef4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	b54080e7          	jalr	-1196(ra) # 80001a4a <myproc>
    80004efe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	cd4080e7          	jalr	-812(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f0a:	2184a703          	lw	a4,536(s1)
    80004f0e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f12:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f16:	02f71763          	bne	a4,a5,80004f44 <piperead+0x68>
    80004f1a:	2244a783          	lw	a5,548(s1)
    80004f1e:	c39d                	beqz	a5,80004f44 <piperead+0x68>
    if(killed(pr)){
    80004f20:	8552                	mv	a0,s4
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	6a8080e7          	jalr	1704(ra) # 800025ca <killed>
    80004f2a:	e949                	bnez	a0,80004fbc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f2c:	85a6                	mv	a1,s1
    80004f2e:	854e                	mv	a0,s3
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	3f2080e7          	jalr	1010(ra) # 80002322 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f38:	2184a703          	lw	a4,536(s1)
    80004f3c:	21c4a783          	lw	a5,540(s1)
    80004f40:	fcf70de3          	beq	a4,a5,80004f1a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f46:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f48:	05505463          	blez	s5,80004f90 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f4c:	2184a783          	lw	a5,536(s1)
    80004f50:	21c4a703          	lw	a4,540(s1)
    80004f54:	02f70e63          	beq	a4,a5,80004f90 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f58:	0017871b          	addiw	a4,a5,1
    80004f5c:	20e4ac23          	sw	a4,536(s1)
    80004f60:	1ff7f793          	andi	a5,a5,511
    80004f64:	97a6                	add	a5,a5,s1
    80004f66:	0187c783          	lbu	a5,24(a5)
    80004f6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f6e:	4685                	li	a3,1
    80004f70:	fbf40613          	addi	a2,s0,-65
    80004f74:	85ca                	mv	a1,s2
    80004f76:	058a3503          	ld	a0,88(s4)
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	6f2080e7          	jalr	1778(ra) # 8000166c <copyout>
    80004f82:	01650763          	beq	a0,s6,80004f90 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f86:	2985                	addiw	s3,s3,1
    80004f88:	0905                	addi	s2,s2,1
    80004f8a:	fd3a91e3          	bne	s5,s3,80004f4c <piperead+0x70>
    80004f8e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f90:	21c48513          	addi	a0,s1,540
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	3f2080e7          	jalr	1010(ra) # 80002386 <wakeup>
  release(&pi->lock);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	cec080e7          	jalr	-788(ra) # 80000c8a <release>
  return i;
}
    80004fa6:	854e                	mv	a0,s3
    80004fa8:	60a6                	ld	ra,72(sp)
    80004faa:	6406                	ld	s0,64(sp)
    80004fac:	74e2                	ld	s1,56(sp)
    80004fae:	7942                	ld	s2,48(sp)
    80004fb0:	79a2                	ld	s3,40(sp)
    80004fb2:	7a02                	ld	s4,32(sp)
    80004fb4:	6ae2                	ld	s5,24(sp)
    80004fb6:	6b42                	ld	s6,16(sp)
    80004fb8:	6161                	addi	sp,sp,80
    80004fba:	8082                	ret
      release(&pi->lock);
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	ccc080e7          	jalr	-820(ra) # 80000c8a <release>
      return -1;
    80004fc6:	59fd                	li	s3,-1
    80004fc8:	bff9                	j	80004fa6 <piperead+0xca>

0000000080004fca <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fca:	1141                	addi	sp,sp,-16
    80004fcc:	e422                	sd	s0,8(sp)
    80004fce:	0800                	addi	s0,sp,16
    80004fd0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004fd2:	8905                	andi	a0,a0,1
    80004fd4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004fd6:	8b89                	andi	a5,a5,2
    80004fd8:	c399                	beqz	a5,80004fde <flags2perm+0x14>
      perm |= PTE_W;
    80004fda:	00456513          	ori	a0,a0,4
    return perm;
}
    80004fde:	6422                	ld	s0,8(sp)
    80004fe0:	0141                	addi	sp,sp,16
    80004fe2:	8082                	ret

0000000080004fe4 <exec>:

int
exec(char *path, char **argv)
{
    80004fe4:	de010113          	addi	sp,sp,-544
    80004fe8:	20113c23          	sd	ra,536(sp)
    80004fec:	20813823          	sd	s0,528(sp)
    80004ff0:	20913423          	sd	s1,520(sp)
    80004ff4:	21213023          	sd	s2,512(sp)
    80004ff8:	ffce                	sd	s3,504(sp)
    80004ffa:	fbd2                	sd	s4,496(sp)
    80004ffc:	f7d6                	sd	s5,488(sp)
    80004ffe:	f3da                	sd	s6,480(sp)
    80005000:	efde                	sd	s7,472(sp)
    80005002:	ebe2                	sd	s8,464(sp)
    80005004:	e7e6                	sd	s9,456(sp)
    80005006:	e3ea                	sd	s10,448(sp)
    80005008:	ff6e                	sd	s11,440(sp)
    8000500a:	1400                	addi	s0,sp,544
    8000500c:	892a                	mv	s2,a0
    8000500e:	dea43423          	sd	a0,-536(s0)
    80005012:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	a34080e7          	jalr	-1484(ra) # 80001a4a <myproc>
    8000501e:	84aa                	mv	s1,a0

  begin_op();
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	482080e7          	jalr	1154(ra) # 800044a2 <begin_op>

  if((ip = namei(path)) == 0){
    80005028:	854a                	mv	a0,s2
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	258080e7          	jalr	600(ra) # 80004282 <namei>
    80005032:	c93d                	beqz	a0,800050a8 <exec+0xc4>
    80005034:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	aa0080e7          	jalr	-1376(ra) # 80003ad6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000503e:	04000713          	li	a4,64
    80005042:	4681                	li	a3,0
    80005044:	e5040613          	addi	a2,s0,-432
    80005048:	4581                	li	a1,0
    8000504a:	8556                	mv	a0,s5
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	d3e080e7          	jalr	-706(ra) # 80003d8a <readi>
    80005054:	04000793          	li	a5,64
    80005058:	00f51a63          	bne	a0,a5,8000506c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000505c:	e5042703          	lw	a4,-432(s0)
    80005060:	464c47b7          	lui	a5,0x464c4
    80005064:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005068:	04f70663          	beq	a4,a5,800050b4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000506c:	8556                	mv	a0,s5
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	cca080e7          	jalr	-822(ra) # 80003d38 <iunlockput>
    end_op();
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	4aa080e7          	jalr	1194(ra) # 80004520 <end_op>
  }
  return -1;
    8000507e:	557d                	li	a0,-1
}
    80005080:	21813083          	ld	ra,536(sp)
    80005084:	21013403          	ld	s0,528(sp)
    80005088:	20813483          	ld	s1,520(sp)
    8000508c:	20013903          	ld	s2,512(sp)
    80005090:	79fe                	ld	s3,504(sp)
    80005092:	7a5e                	ld	s4,496(sp)
    80005094:	7abe                	ld	s5,488(sp)
    80005096:	7b1e                	ld	s6,480(sp)
    80005098:	6bfe                	ld	s7,472(sp)
    8000509a:	6c5e                	ld	s8,464(sp)
    8000509c:	6cbe                	ld	s9,456(sp)
    8000509e:	6d1e                	ld	s10,448(sp)
    800050a0:	7dfa                	ld	s11,440(sp)
    800050a2:	22010113          	addi	sp,sp,544
    800050a6:	8082                	ret
    end_op();
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	478080e7          	jalr	1144(ra) # 80004520 <end_op>
    return -1;
    800050b0:	557d                	li	a0,-1
    800050b2:	b7f9                	j	80005080 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050b4:	8526                	mv	a0,s1
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	a58080e7          	jalr	-1448(ra) # 80001b0e <proc_pagetable>
    800050be:	8b2a                	mv	s6,a0
    800050c0:	d555                	beqz	a0,8000506c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c2:	e7042783          	lw	a5,-400(s0)
    800050c6:	e8845703          	lhu	a4,-376(s0)
    800050ca:	c735                	beqz	a4,80005136 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050cc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ce:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050d2:	6a05                	lui	s4,0x1
    800050d4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050d8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050dc:	6d85                	lui	s11,0x1
    800050de:	7d7d                	lui	s10,0xfffff
    800050e0:	ac3d                	j	8000531e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050e2:	00003517          	auipc	a0,0x3
    800050e6:	6ee50513          	addi	a0,a0,1774 # 800087d0 <syscalls+0x288>
    800050ea:	ffffb097          	auipc	ra,0xffffb
    800050ee:	456080e7          	jalr	1110(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050f2:	874a                	mv	a4,s2
    800050f4:	009c86bb          	addw	a3,s9,s1
    800050f8:	4581                	li	a1,0
    800050fa:	8556                	mv	a0,s5
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	c8e080e7          	jalr	-882(ra) # 80003d8a <readi>
    80005104:	2501                	sext.w	a0,a0
    80005106:	1aa91963          	bne	s2,a0,800052b8 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000510a:	009d84bb          	addw	s1,s11,s1
    8000510e:	013d09bb          	addw	s3,s10,s3
    80005112:	1f74f663          	bgeu	s1,s7,800052fe <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005116:	02049593          	slli	a1,s1,0x20
    8000511a:	9181                	srli	a1,a1,0x20
    8000511c:	95e2                	add	a1,a1,s8
    8000511e:	855a                	mv	a0,s6
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	f3c080e7          	jalr	-196(ra) # 8000105c <walkaddr>
    80005128:	862a                	mv	a2,a0
    if(pa == 0)
    8000512a:	dd45                	beqz	a0,800050e2 <exec+0xfe>
      n = PGSIZE;
    8000512c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000512e:	fd49f2e3          	bgeu	s3,s4,800050f2 <exec+0x10e>
      n = sz - i;
    80005132:	894e                	mv	s2,s3
    80005134:	bf7d                	j	800050f2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005136:	4901                	li	s2,0
  iunlockput(ip);
    80005138:	8556                	mv	a0,s5
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	bfe080e7          	jalr	-1026(ra) # 80003d38 <iunlockput>
  end_op();
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	3de080e7          	jalr	990(ra) # 80004520 <end_op>
  p = myproc();
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	900080e7          	jalr	-1792(ra) # 80001a4a <myproc>
    80005152:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005154:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005158:	6785                	lui	a5,0x1
    8000515a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000515c:	97ca                	add	a5,a5,s2
    8000515e:	777d                	lui	a4,0xfffff
    80005160:	8ff9                	and	a5,a5,a4
    80005162:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005166:	4691                	li	a3,4
    80005168:	6609                	lui	a2,0x2
    8000516a:	963e                	add	a2,a2,a5
    8000516c:	85be                	mv	a1,a5
    8000516e:	855a                	mv	a0,s6
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	2a0080e7          	jalr	672(ra) # 80001410 <uvmalloc>
    80005178:	8c2a                	mv	s8,a0
  ip = 0;
    8000517a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000517c:	12050e63          	beqz	a0,800052b8 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005180:	75f9                	lui	a1,0xffffe
    80005182:	95aa                	add	a1,a1,a0
    80005184:	855a                	mv	a0,s6
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	4b4080e7          	jalr	1204(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    8000518e:	7afd                	lui	s5,0xfffff
    80005190:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005192:	df043783          	ld	a5,-528(s0)
    80005196:	6388                	ld	a0,0(a5)
    80005198:	c925                	beqz	a0,80005208 <exec+0x224>
    8000519a:	e9040993          	addi	s3,s0,-368
    8000519e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051a2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051a4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051a6:	ffffc097          	auipc	ra,0xffffc
    800051aa:	ca8080e7          	jalr	-856(ra) # 80000e4e <strlen>
    800051ae:	0015079b          	addiw	a5,a0,1
    800051b2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051b6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051ba:	13596663          	bltu	s2,s5,800052e6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051be:	df043d83          	ld	s11,-528(s0)
    800051c2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051c6:	8552                	mv	a0,s4
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	c86080e7          	jalr	-890(ra) # 80000e4e <strlen>
    800051d0:	0015069b          	addiw	a3,a0,1
    800051d4:	8652                	mv	a2,s4
    800051d6:	85ca                	mv	a1,s2
    800051d8:	855a                	mv	a0,s6
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	492080e7          	jalr	1170(ra) # 8000166c <copyout>
    800051e2:	10054663          	bltz	a0,800052ee <exec+0x30a>
    ustack[argc] = sp;
    800051e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ea:	0485                	addi	s1,s1,1
    800051ec:	008d8793          	addi	a5,s11,8
    800051f0:	def43823          	sd	a5,-528(s0)
    800051f4:	008db503          	ld	a0,8(s11)
    800051f8:	c911                	beqz	a0,8000520c <exec+0x228>
    if(argc >= MAXARG)
    800051fa:	09a1                	addi	s3,s3,8
    800051fc:	fb3c95e3          	bne	s9,s3,800051a6 <exec+0x1c2>
  sz = sz1;
    80005200:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005204:	4a81                	li	s5,0
    80005206:	a84d                	j	800052b8 <exec+0x2d4>
  sp = sz;
    80005208:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000520a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000520c:	00349793          	slli	a5,s1,0x3
    80005210:	f9078793          	addi	a5,a5,-112
    80005214:	97a2                	add	a5,a5,s0
    80005216:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000521a:	00148693          	addi	a3,s1,1
    8000521e:	068e                	slli	a3,a3,0x3
    80005220:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005224:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005228:	01597663          	bgeu	s2,s5,80005234 <exec+0x250>
  sz = sz1;
    8000522c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005230:	4a81                	li	s5,0
    80005232:	a059                	j	800052b8 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005234:	e9040613          	addi	a2,s0,-368
    80005238:	85ca                	mv	a1,s2
    8000523a:	855a                	mv	a0,s6
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	430080e7          	jalr	1072(ra) # 8000166c <copyout>
    80005244:	0a054963          	bltz	a0,800052f6 <exec+0x312>
  p->trapframe->a1 = sp;
    80005248:	060bb783          	ld	a5,96(s7)
    8000524c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005250:	de843783          	ld	a5,-536(s0)
    80005254:	0007c703          	lbu	a4,0(a5)
    80005258:	cf11                	beqz	a4,80005274 <exec+0x290>
    8000525a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000525c:	02f00693          	li	a3,47
    80005260:	a039                	j	8000526e <exec+0x28a>
      last = s+1;
    80005262:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005266:	0785                	addi	a5,a5,1
    80005268:	fff7c703          	lbu	a4,-1(a5)
    8000526c:	c701                	beqz	a4,80005274 <exec+0x290>
    if(*s == '/')
    8000526e:	fed71ce3          	bne	a4,a3,80005266 <exec+0x282>
    80005272:	bfc5                	j	80005262 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005274:	4641                	li	a2,16
    80005276:	de843583          	ld	a1,-536(s0)
    8000527a:	160b8513          	addi	a0,s7,352
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	b9e080e7          	jalr	-1122(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005286:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    8000528a:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    8000528e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005292:	060bb783          	ld	a5,96(s7)
    80005296:	e6843703          	ld	a4,-408(s0)
    8000529a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000529c:	060bb783          	ld	a5,96(s7)
    800052a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052a4:	85ea                	mv	a1,s10
    800052a6:	ffffd097          	auipc	ra,0xffffd
    800052aa:	904080e7          	jalr	-1788(ra) # 80001baa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052ae:	0004851b          	sext.w	a0,s1
    800052b2:	b3f9                	j	80005080 <exec+0x9c>
    800052b4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052b8:	df843583          	ld	a1,-520(s0)
    800052bc:	855a                	mv	a0,s6
    800052be:	ffffd097          	auipc	ra,0xffffd
    800052c2:	8ec080e7          	jalr	-1812(ra) # 80001baa <proc_freepagetable>
  if(ip){
    800052c6:	da0a93e3          	bnez	s5,8000506c <exec+0x88>
  return -1;
    800052ca:	557d                	li	a0,-1
    800052cc:	bb55                	j	80005080 <exec+0x9c>
    800052ce:	df243c23          	sd	s2,-520(s0)
    800052d2:	b7dd                	j	800052b8 <exec+0x2d4>
    800052d4:	df243c23          	sd	s2,-520(s0)
    800052d8:	b7c5                	j	800052b8 <exec+0x2d4>
    800052da:	df243c23          	sd	s2,-520(s0)
    800052de:	bfe9                	j	800052b8 <exec+0x2d4>
    800052e0:	df243c23          	sd	s2,-520(s0)
    800052e4:	bfd1                	j	800052b8 <exec+0x2d4>
  sz = sz1;
    800052e6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ea:	4a81                	li	s5,0
    800052ec:	b7f1                	j	800052b8 <exec+0x2d4>
  sz = sz1;
    800052ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052f2:	4a81                	li	s5,0
    800052f4:	b7d1                	j	800052b8 <exec+0x2d4>
  sz = sz1;
    800052f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052fa:	4a81                	li	s5,0
    800052fc:	bf75                	j	800052b8 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052fe:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005302:	e0843783          	ld	a5,-504(s0)
    80005306:	0017869b          	addiw	a3,a5,1
    8000530a:	e0d43423          	sd	a3,-504(s0)
    8000530e:	e0043783          	ld	a5,-512(s0)
    80005312:	0387879b          	addiw	a5,a5,56
    80005316:	e8845703          	lhu	a4,-376(s0)
    8000531a:	e0e6dfe3          	bge	a3,a4,80005138 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000531e:	2781                	sext.w	a5,a5
    80005320:	e0f43023          	sd	a5,-512(s0)
    80005324:	03800713          	li	a4,56
    80005328:	86be                	mv	a3,a5
    8000532a:	e1840613          	addi	a2,s0,-488
    8000532e:	4581                	li	a1,0
    80005330:	8556                	mv	a0,s5
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	a58080e7          	jalr	-1448(ra) # 80003d8a <readi>
    8000533a:	03800793          	li	a5,56
    8000533e:	f6f51be3          	bne	a0,a5,800052b4 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005342:	e1842783          	lw	a5,-488(s0)
    80005346:	4705                	li	a4,1
    80005348:	fae79de3          	bne	a5,a4,80005302 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000534c:	e4043483          	ld	s1,-448(s0)
    80005350:	e3843783          	ld	a5,-456(s0)
    80005354:	f6f4ede3          	bltu	s1,a5,800052ce <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005358:	e2843783          	ld	a5,-472(s0)
    8000535c:	94be                	add	s1,s1,a5
    8000535e:	f6f4ebe3          	bltu	s1,a5,800052d4 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005362:	de043703          	ld	a4,-544(s0)
    80005366:	8ff9                	and	a5,a5,a4
    80005368:	fbad                	bnez	a5,800052da <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000536a:	e1c42503          	lw	a0,-484(s0)
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	c5c080e7          	jalr	-932(ra) # 80004fca <flags2perm>
    80005376:	86aa                	mv	a3,a0
    80005378:	8626                	mv	a2,s1
    8000537a:	85ca                	mv	a1,s2
    8000537c:	855a                	mv	a0,s6
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	092080e7          	jalr	146(ra) # 80001410 <uvmalloc>
    80005386:	dea43c23          	sd	a0,-520(s0)
    8000538a:	d939                	beqz	a0,800052e0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000538c:	e2843c03          	ld	s8,-472(s0)
    80005390:	e2042c83          	lw	s9,-480(s0)
    80005394:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005398:	f60b83e3          	beqz	s7,800052fe <exec+0x31a>
    8000539c:	89de                	mv	s3,s7
    8000539e:	4481                	li	s1,0
    800053a0:	bb9d                	j	80005116 <exec+0x132>

00000000800053a2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053a2:	7179                	addi	sp,sp,-48
    800053a4:	f406                	sd	ra,40(sp)
    800053a6:	f022                	sd	s0,32(sp)
    800053a8:	ec26                	sd	s1,24(sp)
    800053aa:	e84a                	sd	s2,16(sp)
    800053ac:	1800                	addi	s0,sp,48
    800053ae:	892e                	mv	s2,a1
    800053b0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053b2:	fdc40593          	addi	a1,s0,-36
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	a38080e7          	jalr	-1480(ra) # 80002dee <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053be:	fdc42703          	lw	a4,-36(s0)
    800053c2:	47bd                	li	a5,15
    800053c4:	02e7eb63          	bltu	a5,a4,800053fa <argfd+0x58>
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	682080e7          	jalr	1666(ra) # 80001a4a <myproc>
    800053d0:	fdc42703          	lw	a4,-36(s0)
    800053d4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc82a>
    800053d8:	078e                	slli	a5,a5,0x3
    800053da:	953e                	add	a0,a0,a5
    800053dc:	651c                	ld	a5,8(a0)
    800053de:	c385                	beqz	a5,800053fe <argfd+0x5c>
    return -1;
  if(pfd)
    800053e0:	00090463          	beqz	s2,800053e8 <argfd+0x46>
    *pfd = fd;
    800053e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053e8:	4501                	li	a0,0
  if(pf)
    800053ea:	c091                	beqz	s1,800053ee <argfd+0x4c>
    *pf = f;
    800053ec:	e09c                	sd	a5,0(s1)
}
    800053ee:	70a2                	ld	ra,40(sp)
    800053f0:	7402                	ld	s0,32(sp)
    800053f2:	64e2                	ld	s1,24(sp)
    800053f4:	6942                	ld	s2,16(sp)
    800053f6:	6145                	addi	sp,sp,48
    800053f8:	8082                	ret
    return -1;
    800053fa:	557d                	li	a0,-1
    800053fc:	bfcd                	j	800053ee <argfd+0x4c>
    800053fe:	557d                	li	a0,-1
    80005400:	b7fd                	j	800053ee <argfd+0x4c>

0000000080005402 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005402:	1101                	addi	sp,sp,-32
    80005404:	ec06                	sd	ra,24(sp)
    80005406:	e822                	sd	s0,16(sp)
    80005408:	e426                	sd	s1,8(sp)
    8000540a:	1000                	addi	s0,sp,32
    8000540c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	63c080e7          	jalr	1596(ra) # 80001a4a <myproc>
    80005416:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005418:	0d850793          	addi	a5,a0,216
    8000541c:	4501                	li	a0,0
    8000541e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005420:	6398                	ld	a4,0(a5)
    80005422:	cb19                	beqz	a4,80005438 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005424:	2505                	addiw	a0,a0,1
    80005426:	07a1                	addi	a5,a5,8
    80005428:	fed51ce3          	bne	a0,a3,80005420 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000542c:	557d                	li	a0,-1
}
    8000542e:	60e2                	ld	ra,24(sp)
    80005430:	6442                	ld	s0,16(sp)
    80005432:	64a2                	ld	s1,8(sp)
    80005434:	6105                	addi	sp,sp,32
    80005436:	8082                	ret
      p->ofile[fd] = f;
    80005438:	01a50793          	addi	a5,a0,26
    8000543c:	078e                	slli	a5,a5,0x3
    8000543e:	963e                	add	a2,a2,a5
    80005440:	e604                	sd	s1,8(a2)
      return fd;
    80005442:	b7f5                	j	8000542e <fdalloc+0x2c>

0000000080005444 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005444:	715d                	addi	sp,sp,-80
    80005446:	e486                	sd	ra,72(sp)
    80005448:	e0a2                	sd	s0,64(sp)
    8000544a:	fc26                	sd	s1,56(sp)
    8000544c:	f84a                	sd	s2,48(sp)
    8000544e:	f44e                	sd	s3,40(sp)
    80005450:	f052                	sd	s4,32(sp)
    80005452:	ec56                	sd	s5,24(sp)
    80005454:	e85a                	sd	s6,16(sp)
    80005456:	0880                	addi	s0,sp,80
    80005458:	8b2e                	mv	s6,a1
    8000545a:	89b2                	mv	s3,a2
    8000545c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000545e:	fb040593          	addi	a1,s0,-80
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	e3e080e7          	jalr	-450(ra) # 800042a0 <nameiparent>
    8000546a:	84aa                	mv	s1,a0
    8000546c:	14050f63          	beqz	a0,800055ca <create+0x186>
    return 0;

  ilock(dp);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	666080e7          	jalr	1638(ra) # 80003ad6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005478:	4601                	li	a2,0
    8000547a:	fb040593          	addi	a1,s0,-80
    8000547e:	8526                	mv	a0,s1
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	b3a080e7          	jalr	-1222(ra) # 80003fba <dirlookup>
    80005488:	8aaa                	mv	s5,a0
    8000548a:	c931                	beqz	a0,800054de <create+0x9a>
    iunlockput(dp);
    8000548c:	8526                	mv	a0,s1
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	8aa080e7          	jalr	-1878(ra) # 80003d38 <iunlockput>
    ilock(ip);
    80005496:	8556                	mv	a0,s5
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	63e080e7          	jalr	1598(ra) # 80003ad6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054a0:	000b059b          	sext.w	a1,s6
    800054a4:	4789                	li	a5,2
    800054a6:	02f59563          	bne	a1,a5,800054d0 <create+0x8c>
    800054aa:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc854>
    800054ae:	37f9                	addiw	a5,a5,-2
    800054b0:	17c2                	slli	a5,a5,0x30
    800054b2:	93c1                	srli	a5,a5,0x30
    800054b4:	4705                	li	a4,1
    800054b6:	00f76d63          	bltu	a4,a5,800054d0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054ba:	8556                	mv	a0,s5
    800054bc:	60a6                	ld	ra,72(sp)
    800054be:	6406                	ld	s0,64(sp)
    800054c0:	74e2                	ld	s1,56(sp)
    800054c2:	7942                	ld	s2,48(sp)
    800054c4:	79a2                	ld	s3,40(sp)
    800054c6:	7a02                	ld	s4,32(sp)
    800054c8:	6ae2                	ld	s5,24(sp)
    800054ca:	6b42                	ld	s6,16(sp)
    800054cc:	6161                	addi	sp,sp,80
    800054ce:	8082                	ret
    iunlockput(ip);
    800054d0:	8556                	mv	a0,s5
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	866080e7          	jalr	-1946(ra) # 80003d38 <iunlockput>
    return 0;
    800054da:	4a81                	li	s5,0
    800054dc:	bff9                	j	800054ba <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054de:	85da                	mv	a1,s6
    800054e0:	4088                	lw	a0,0(s1)
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	456080e7          	jalr	1110(ra) # 80003938 <ialloc>
    800054ea:	8a2a                	mv	s4,a0
    800054ec:	c539                	beqz	a0,8000553a <create+0xf6>
  ilock(ip);
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	5e8080e7          	jalr	1512(ra) # 80003ad6 <ilock>
  ip->major = major;
    800054f6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800054fa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800054fe:	4905                	li	s2,1
    80005500:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005504:	8552                	mv	a0,s4
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	504080e7          	jalr	1284(ra) # 80003a0a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000550e:	000b059b          	sext.w	a1,s6
    80005512:	03258b63          	beq	a1,s2,80005548 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005516:	004a2603          	lw	a2,4(s4)
    8000551a:	fb040593          	addi	a1,s0,-80
    8000551e:	8526                	mv	a0,s1
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	cb0080e7          	jalr	-848(ra) # 800041d0 <dirlink>
    80005528:	06054f63          	bltz	a0,800055a6 <create+0x162>
  iunlockput(dp);
    8000552c:	8526                	mv	a0,s1
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	80a080e7          	jalr	-2038(ra) # 80003d38 <iunlockput>
  return ip;
    80005536:	8ad2                	mv	s5,s4
    80005538:	b749                	j	800054ba <create+0x76>
    iunlockput(dp);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	7fc080e7          	jalr	2044(ra) # 80003d38 <iunlockput>
    return 0;
    80005544:	8ad2                	mv	s5,s4
    80005546:	bf95                	j	800054ba <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005548:	004a2603          	lw	a2,4(s4)
    8000554c:	00003597          	auipc	a1,0x3
    80005550:	2a458593          	addi	a1,a1,676 # 800087f0 <syscalls+0x2a8>
    80005554:	8552                	mv	a0,s4
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	c7a080e7          	jalr	-902(ra) # 800041d0 <dirlink>
    8000555e:	04054463          	bltz	a0,800055a6 <create+0x162>
    80005562:	40d0                	lw	a2,4(s1)
    80005564:	00003597          	auipc	a1,0x3
    80005568:	29458593          	addi	a1,a1,660 # 800087f8 <syscalls+0x2b0>
    8000556c:	8552                	mv	a0,s4
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c62080e7          	jalr	-926(ra) # 800041d0 <dirlink>
    80005576:	02054863          	bltz	a0,800055a6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000557a:	004a2603          	lw	a2,4(s4)
    8000557e:	fb040593          	addi	a1,s0,-80
    80005582:	8526                	mv	a0,s1
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	c4c080e7          	jalr	-948(ra) # 800041d0 <dirlink>
    8000558c:	00054d63          	bltz	a0,800055a6 <create+0x162>
    dp->nlink++;  // for ".."
    80005590:	04a4d783          	lhu	a5,74(s1)
    80005594:	2785                	addiw	a5,a5,1
    80005596:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	46e080e7          	jalr	1134(ra) # 80003a0a <iupdate>
    800055a4:	b761                	j	8000552c <create+0xe8>
  ip->nlink = 0;
    800055a6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055aa:	8552                	mv	a0,s4
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	45e080e7          	jalr	1118(ra) # 80003a0a <iupdate>
  iunlockput(ip);
    800055b4:	8552                	mv	a0,s4
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	782080e7          	jalr	1922(ra) # 80003d38 <iunlockput>
  iunlockput(dp);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	778080e7          	jalr	1912(ra) # 80003d38 <iunlockput>
  return 0;
    800055c8:	bdcd                	j	800054ba <create+0x76>
    return 0;
    800055ca:	8aaa                	mv	s5,a0
    800055cc:	b5fd                	j	800054ba <create+0x76>

00000000800055ce <sys_dup>:
{
    800055ce:	7179                	addi	sp,sp,-48
    800055d0:	f406                	sd	ra,40(sp)
    800055d2:	f022                	sd	s0,32(sp)
    800055d4:	ec26                	sd	s1,24(sp)
    800055d6:	e84a                	sd	s2,16(sp)
    800055d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055da:	fd840613          	addi	a2,s0,-40
    800055de:	4581                	li	a1,0
    800055e0:	4501                	li	a0,0
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	dc0080e7          	jalr	-576(ra) # 800053a2 <argfd>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055ec:	02054363          	bltz	a0,80005612 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800055f0:	fd843903          	ld	s2,-40(s0)
    800055f4:	854a                	mv	a0,s2
    800055f6:	00000097          	auipc	ra,0x0
    800055fa:	e0c080e7          	jalr	-500(ra) # 80005402 <fdalloc>
    800055fe:	84aa                	mv	s1,a0
    return -1;
    80005600:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005602:	00054863          	bltz	a0,80005612 <sys_dup+0x44>
  filedup(f);
    80005606:	854a                	mv	a0,s2
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	310080e7          	jalr	784(ra) # 80004918 <filedup>
  return fd;
    80005610:	87a6                	mv	a5,s1
}
    80005612:	853e                	mv	a0,a5
    80005614:	70a2                	ld	ra,40(sp)
    80005616:	7402                	ld	s0,32(sp)
    80005618:	64e2                	ld	s1,24(sp)
    8000561a:	6942                	ld	s2,16(sp)
    8000561c:	6145                	addi	sp,sp,48
    8000561e:	8082                	ret

0000000080005620 <sys_read>:
{
    80005620:	7179                	addi	sp,sp,-48
    80005622:	f406                	sd	ra,40(sp)
    80005624:	f022                	sd	s0,32(sp)
    80005626:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005628:	fd840593          	addi	a1,s0,-40
    8000562c:	4505                	li	a0,1
    8000562e:	ffffd097          	auipc	ra,0xffffd
    80005632:	7e0080e7          	jalr	2016(ra) # 80002e0e <argaddr>
  argint(2, &n);
    80005636:	fe440593          	addi	a1,s0,-28
    8000563a:	4509                	li	a0,2
    8000563c:	ffffd097          	auipc	ra,0xffffd
    80005640:	7b2080e7          	jalr	1970(ra) # 80002dee <argint>
  if(argfd(0, 0, &f) < 0)
    80005644:	fe840613          	addi	a2,s0,-24
    80005648:	4581                	li	a1,0
    8000564a:	4501                	li	a0,0
    8000564c:	00000097          	auipc	ra,0x0
    80005650:	d56080e7          	jalr	-682(ra) # 800053a2 <argfd>
    80005654:	87aa                	mv	a5,a0
    return -1;
    80005656:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005658:	0007cc63          	bltz	a5,80005670 <sys_read+0x50>
  return fileread(f, p, n);
    8000565c:	fe442603          	lw	a2,-28(s0)
    80005660:	fd843583          	ld	a1,-40(s0)
    80005664:	fe843503          	ld	a0,-24(s0)
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	43c080e7          	jalr	1084(ra) # 80004aa4 <fileread>
}
    80005670:	70a2                	ld	ra,40(sp)
    80005672:	7402                	ld	s0,32(sp)
    80005674:	6145                	addi	sp,sp,48
    80005676:	8082                	ret

0000000080005678 <sys_write>:
{
    80005678:	7179                	addi	sp,sp,-48
    8000567a:	f406                	sd	ra,40(sp)
    8000567c:	f022                	sd	s0,32(sp)
    8000567e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005680:	fd840593          	addi	a1,s0,-40
    80005684:	4505                	li	a0,1
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	788080e7          	jalr	1928(ra) # 80002e0e <argaddr>
  argint(2, &n);
    8000568e:	fe440593          	addi	a1,s0,-28
    80005692:	4509                	li	a0,2
    80005694:	ffffd097          	auipc	ra,0xffffd
    80005698:	75a080e7          	jalr	1882(ra) # 80002dee <argint>
  if(argfd(0, 0, &f) < 0)
    8000569c:	fe840613          	addi	a2,s0,-24
    800056a0:	4581                	li	a1,0
    800056a2:	4501                	li	a0,0
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	cfe080e7          	jalr	-770(ra) # 800053a2 <argfd>
    800056ac:	87aa                	mv	a5,a0
    return -1;
    800056ae:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056b0:	0007cc63          	bltz	a5,800056c8 <sys_write+0x50>
  return filewrite(f, p, n);
    800056b4:	fe442603          	lw	a2,-28(s0)
    800056b8:	fd843583          	ld	a1,-40(s0)
    800056bc:	fe843503          	ld	a0,-24(s0)
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	4a6080e7          	jalr	1190(ra) # 80004b66 <filewrite>
}
    800056c8:	70a2                	ld	ra,40(sp)
    800056ca:	7402                	ld	s0,32(sp)
    800056cc:	6145                	addi	sp,sp,48
    800056ce:	8082                	ret

00000000800056d0 <sys_close>:
{
    800056d0:	1101                	addi	sp,sp,-32
    800056d2:	ec06                	sd	ra,24(sp)
    800056d4:	e822                	sd	s0,16(sp)
    800056d6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056d8:	fe040613          	addi	a2,s0,-32
    800056dc:	fec40593          	addi	a1,s0,-20
    800056e0:	4501                	li	a0,0
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	cc0080e7          	jalr	-832(ra) # 800053a2 <argfd>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056ec:	02054463          	bltz	a0,80005714 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056f0:	ffffc097          	auipc	ra,0xffffc
    800056f4:	35a080e7          	jalr	858(ra) # 80001a4a <myproc>
    800056f8:	fec42783          	lw	a5,-20(s0)
    800056fc:	07e9                	addi	a5,a5,26
    800056fe:	078e                	slli	a5,a5,0x3
    80005700:	953e                	add	a0,a0,a5
    80005702:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005706:	fe043503          	ld	a0,-32(s0)
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	260080e7          	jalr	608(ra) # 8000496a <fileclose>
  return 0;
    80005712:	4781                	li	a5,0
}
    80005714:	853e                	mv	a0,a5
    80005716:	60e2                	ld	ra,24(sp)
    80005718:	6442                	ld	s0,16(sp)
    8000571a:	6105                	addi	sp,sp,32
    8000571c:	8082                	ret

000000008000571e <sys_fstat>:
{
    8000571e:	1101                	addi	sp,sp,-32
    80005720:	ec06                	sd	ra,24(sp)
    80005722:	e822                	sd	s0,16(sp)
    80005724:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005726:	fe040593          	addi	a1,s0,-32
    8000572a:	4505                	li	a0,1
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	6e2080e7          	jalr	1762(ra) # 80002e0e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005734:	fe840613          	addi	a2,s0,-24
    80005738:	4581                	li	a1,0
    8000573a:	4501                	li	a0,0
    8000573c:	00000097          	auipc	ra,0x0
    80005740:	c66080e7          	jalr	-922(ra) # 800053a2 <argfd>
    80005744:	87aa                	mv	a5,a0
    return -1;
    80005746:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005748:	0007ca63          	bltz	a5,8000575c <sys_fstat+0x3e>
  return filestat(f, st);
    8000574c:	fe043583          	ld	a1,-32(s0)
    80005750:	fe843503          	ld	a0,-24(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	2de080e7          	jalr	734(ra) # 80004a32 <filestat>
}
    8000575c:	60e2                	ld	ra,24(sp)
    8000575e:	6442                	ld	s0,16(sp)
    80005760:	6105                	addi	sp,sp,32
    80005762:	8082                	ret

0000000080005764 <sys_link>:
{
    80005764:	7169                	addi	sp,sp,-304
    80005766:	f606                	sd	ra,296(sp)
    80005768:	f222                	sd	s0,288(sp)
    8000576a:	ee26                	sd	s1,280(sp)
    8000576c:	ea4a                	sd	s2,272(sp)
    8000576e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005770:	08000613          	li	a2,128
    80005774:	ed040593          	addi	a1,s0,-304
    80005778:	4501                	li	a0,0
    8000577a:	ffffd097          	auipc	ra,0xffffd
    8000577e:	6b4080e7          	jalr	1716(ra) # 80002e2e <argstr>
    return -1;
    80005782:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005784:	10054e63          	bltz	a0,800058a0 <sys_link+0x13c>
    80005788:	08000613          	li	a2,128
    8000578c:	f5040593          	addi	a1,s0,-176
    80005790:	4505                	li	a0,1
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	69c080e7          	jalr	1692(ra) # 80002e2e <argstr>
    return -1;
    8000579a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579c:	10054263          	bltz	a0,800058a0 <sys_link+0x13c>
  begin_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	d02080e7          	jalr	-766(ra) # 800044a2 <begin_op>
  if((ip = namei(old)) == 0){
    800057a8:	ed040513          	addi	a0,s0,-304
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	ad6080e7          	jalr	-1322(ra) # 80004282 <namei>
    800057b4:	84aa                	mv	s1,a0
    800057b6:	c551                	beqz	a0,80005842 <sys_link+0xde>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	31e080e7          	jalr	798(ra) # 80003ad6 <ilock>
  if(ip->type == T_DIR){
    800057c0:	04449703          	lh	a4,68(s1)
    800057c4:	4785                	li	a5,1
    800057c6:	08f70463          	beq	a4,a5,8000584e <sys_link+0xea>
  ip->nlink++;
    800057ca:	04a4d783          	lhu	a5,74(s1)
    800057ce:	2785                	addiw	a5,a5,1
    800057d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	234080e7          	jalr	564(ra) # 80003a0a <iupdate>
  iunlock(ip);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	3b8080e7          	jalr	952(ra) # 80003b98 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057e8:	fd040593          	addi	a1,s0,-48
    800057ec:	f5040513          	addi	a0,s0,-176
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	ab0080e7          	jalr	-1360(ra) # 800042a0 <nameiparent>
    800057f8:	892a                	mv	s2,a0
    800057fa:	c935                	beqz	a0,8000586e <sys_link+0x10a>
  ilock(dp);
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	2da080e7          	jalr	730(ra) # 80003ad6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005804:	00092703          	lw	a4,0(s2)
    80005808:	409c                	lw	a5,0(s1)
    8000580a:	04f71d63          	bne	a4,a5,80005864 <sys_link+0x100>
    8000580e:	40d0                	lw	a2,4(s1)
    80005810:	fd040593          	addi	a1,s0,-48
    80005814:	854a                	mv	a0,s2
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	9ba080e7          	jalr	-1606(ra) # 800041d0 <dirlink>
    8000581e:	04054363          	bltz	a0,80005864 <sys_link+0x100>
  iunlockput(dp);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	514080e7          	jalr	1300(ra) # 80003d38 <iunlockput>
  iput(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	462080e7          	jalr	1122(ra) # 80003c90 <iput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	cea080e7          	jalr	-790(ra) # 80004520 <end_op>
  return 0;
    8000583e:	4781                	li	a5,0
    80005840:	a085                	j	800058a0 <sys_link+0x13c>
    end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	cde080e7          	jalr	-802(ra) # 80004520 <end_op>
    return -1;
    8000584a:	57fd                	li	a5,-1
    8000584c:	a891                	j	800058a0 <sys_link+0x13c>
    iunlockput(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	4e8080e7          	jalr	1256(ra) # 80003d38 <iunlockput>
    end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	cc8080e7          	jalr	-824(ra) # 80004520 <end_op>
    return -1;
    80005860:	57fd                	li	a5,-1
    80005862:	a83d                	j	800058a0 <sys_link+0x13c>
    iunlockput(dp);
    80005864:	854a                	mv	a0,s2
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	4d2080e7          	jalr	1234(ra) # 80003d38 <iunlockput>
  ilock(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	266080e7          	jalr	614(ra) # 80003ad6 <ilock>
  ip->nlink--;
    80005878:	04a4d783          	lhu	a5,74(s1)
    8000587c:	37fd                	addiw	a5,a5,-1
    8000587e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	186080e7          	jalr	390(ra) # 80003a0a <iupdate>
  iunlockput(ip);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	4aa080e7          	jalr	1194(ra) # 80003d38 <iunlockput>
  end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	c8a080e7          	jalr	-886(ra) # 80004520 <end_op>
  return -1;
    8000589e:	57fd                	li	a5,-1
}
    800058a0:	853e                	mv	a0,a5
    800058a2:	70b2                	ld	ra,296(sp)
    800058a4:	7412                	ld	s0,288(sp)
    800058a6:	64f2                	ld	s1,280(sp)
    800058a8:	6952                	ld	s2,272(sp)
    800058aa:	6155                	addi	sp,sp,304
    800058ac:	8082                	ret

00000000800058ae <sys_unlink>:
{
    800058ae:	7151                	addi	sp,sp,-240
    800058b0:	f586                	sd	ra,232(sp)
    800058b2:	f1a2                	sd	s0,224(sp)
    800058b4:	eda6                	sd	s1,216(sp)
    800058b6:	e9ca                	sd	s2,208(sp)
    800058b8:	e5ce                	sd	s3,200(sp)
    800058ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058bc:	08000613          	li	a2,128
    800058c0:	f3040593          	addi	a1,s0,-208
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	568080e7          	jalr	1384(ra) # 80002e2e <argstr>
    800058ce:	18054163          	bltz	a0,80005a50 <sys_unlink+0x1a2>
  begin_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	bd0080e7          	jalr	-1072(ra) # 800044a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058da:	fb040593          	addi	a1,s0,-80
    800058de:	f3040513          	addi	a0,s0,-208
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	9be080e7          	jalr	-1602(ra) # 800042a0 <nameiparent>
    800058ea:	84aa                	mv	s1,a0
    800058ec:	c979                	beqz	a0,800059c2 <sys_unlink+0x114>
  ilock(dp);
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	1e8080e7          	jalr	488(ra) # 80003ad6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058f6:	00003597          	auipc	a1,0x3
    800058fa:	efa58593          	addi	a1,a1,-262 # 800087f0 <syscalls+0x2a8>
    800058fe:	fb040513          	addi	a0,s0,-80
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	69e080e7          	jalr	1694(ra) # 80003fa0 <namecmp>
    8000590a:	14050a63          	beqz	a0,80005a5e <sys_unlink+0x1b0>
    8000590e:	00003597          	auipc	a1,0x3
    80005912:	eea58593          	addi	a1,a1,-278 # 800087f8 <syscalls+0x2b0>
    80005916:	fb040513          	addi	a0,s0,-80
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	686080e7          	jalr	1670(ra) # 80003fa0 <namecmp>
    80005922:	12050e63          	beqz	a0,80005a5e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005926:	f2c40613          	addi	a2,s0,-212
    8000592a:	fb040593          	addi	a1,s0,-80
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	68a080e7          	jalr	1674(ra) # 80003fba <dirlookup>
    80005938:	892a                	mv	s2,a0
    8000593a:	12050263          	beqz	a0,80005a5e <sys_unlink+0x1b0>
  ilock(ip);
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	198080e7          	jalr	408(ra) # 80003ad6 <ilock>
  if(ip->nlink < 1)
    80005946:	04a91783          	lh	a5,74(s2)
    8000594a:	08f05263          	blez	a5,800059ce <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000594e:	04491703          	lh	a4,68(s2)
    80005952:	4785                	li	a5,1
    80005954:	08f70563          	beq	a4,a5,800059de <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005958:	4641                	li	a2,16
    8000595a:	4581                	li	a1,0
    8000595c:	fc040513          	addi	a0,s0,-64
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	372080e7          	jalr	882(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005968:	4741                	li	a4,16
    8000596a:	f2c42683          	lw	a3,-212(s0)
    8000596e:	fc040613          	addi	a2,s0,-64
    80005972:	4581                	li	a1,0
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	50c080e7          	jalr	1292(ra) # 80003e82 <writei>
    8000597e:	47c1                	li	a5,16
    80005980:	0af51563          	bne	a0,a5,80005a2a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005984:	04491703          	lh	a4,68(s2)
    80005988:	4785                	li	a5,1
    8000598a:	0af70863          	beq	a4,a5,80005a3a <sys_unlink+0x18c>
  iunlockput(dp);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	3a8080e7          	jalr	936(ra) # 80003d38 <iunlockput>
  ip->nlink--;
    80005998:	04a95783          	lhu	a5,74(s2)
    8000599c:	37fd                	addiw	a5,a5,-1
    8000599e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	066080e7          	jalr	102(ra) # 80003a0a <iupdate>
  iunlockput(ip);
    800059ac:	854a                	mv	a0,s2
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	38a080e7          	jalr	906(ra) # 80003d38 <iunlockput>
  end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	b6a080e7          	jalr	-1174(ra) # 80004520 <end_op>
  return 0;
    800059be:	4501                	li	a0,0
    800059c0:	a84d                	j	80005a72 <sys_unlink+0x1c4>
    end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	b5e080e7          	jalr	-1186(ra) # 80004520 <end_op>
    return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	a05d                	j	80005a72 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ce:	00003517          	auipc	a0,0x3
    800059d2:	e3250513          	addi	a0,a0,-462 # 80008800 <syscalls+0x2b8>
    800059d6:	ffffb097          	auipc	ra,0xffffb
    800059da:	b6a080e7          	jalr	-1174(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059de:	04c92703          	lw	a4,76(s2)
    800059e2:	02000793          	li	a5,32
    800059e6:	f6e7f9e3          	bgeu	a5,a4,80005958 <sys_unlink+0xaa>
    800059ea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ee:	4741                	li	a4,16
    800059f0:	86ce                	mv	a3,s3
    800059f2:	f1840613          	addi	a2,s0,-232
    800059f6:	4581                	li	a1,0
    800059f8:	854a                	mv	a0,s2
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	390080e7          	jalr	912(ra) # 80003d8a <readi>
    80005a02:	47c1                	li	a5,16
    80005a04:	00f51b63          	bne	a0,a5,80005a1a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a08:	f1845783          	lhu	a5,-232(s0)
    80005a0c:	e7a1                	bnez	a5,80005a54 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a0e:	29c1                	addiw	s3,s3,16
    80005a10:	04c92783          	lw	a5,76(s2)
    80005a14:	fcf9ede3          	bltu	s3,a5,800059ee <sys_unlink+0x140>
    80005a18:	b781                	j	80005958 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a1a:	00003517          	auipc	a0,0x3
    80005a1e:	dfe50513          	addi	a0,a0,-514 # 80008818 <syscalls+0x2d0>
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	b1e080e7          	jalr	-1250(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a2a:	00003517          	auipc	a0,0x3
    80005a2e:	e0650513          	addi	a0,a0,-506 # 80008830 <syscalls+0x2e8>
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	b0e080e7          	jalr	-1266(ra) # 80000540 <panic>
    dp->nlink--;
    80005a3a:	04a4d783          	lhu	a5,74(s1)
    80005a3e:	37fd                	addiw	a5,a5,-1
    80005a40:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	fc4080e7          	jalr	-60(ra) # 80003a0a <iupdate>
    80005a4e:	b781                	j	8000598e <sys_unlink+0xe0>
    return -1;
    80005a50:	557d                	li	a0,-1
    80005a52:	a005                	j	80005a72 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	2e2080e7          	jalr	738(ra) # 80003d38 <iunlockput>
  iunlockput(dp);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	2d8080e7          	jalr	728(ra) # 80003d38 <iunlockput>
  end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	ab8080e7          	jalr	-1352(ra) # 80004520 <end_op>
  return -1;
    80005a70:	557d                	li	a0,-1
}
    80005a72:	70ae                	ld	ra,232(sp)
    80005a74:	740e                	ld	s0,224(sp)
    80005a76:	64ee                	ld	s1,216(sp)
    80005a78:	694e                	ld	s2,208(sp)
    80005a7a:	69ae                	ld	s3,200(sp)
    80005a7c:	616d                	addi	sp,sp,240
    80005a7e:	8082                	ret

0000000080005a80 <sys_open>:

uint64
sys_open(void)
{
    80005a80:	7131                	addi	sp,sp,-192
    80005a82:	fd06                	sd	ra,184(sp)
    80005a84:	f922                	sd	s0,176(sp)
    80005a86:	f526                	sd	s1,168(sp)
    80005a88:	f14a                	sd	s2,160(sp)
    80005a8a:	ed4e                	sd	s3,152(sp)
    80005a8c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a8e:	f4c40593          	addi	a1,s0,-180
    80005a92:	4505                	li	a0,1
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	35a080e7          	jalr	858(ra) # 80002dee <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a9c:	08000613          	li	a2,128
    80005aa0:	f5040593          	addi	a1,s0,-176
    80005aa4:	4501                	li	a0,0
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	388080e7          	jalr	904(ra) # 80002e2e <argstr>
    80005aae:	87aa                	mv	a5,a0
    return -1;
    80005ab0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ab2:	0a07c963          	bltz	a5,80005b64 <sys_open+0xe4>

  begin_op();
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	9ec080e7          	jalr	-1556(ra) # 800044a2 <begin_op>

  if(omode & O_CREATE){
    80005abe:	f4c42783          	lw	a5,-180(s0)
    80005ac2:	2007f793          	andi	a5,a5,512
    80005ac6:	cfc5                	beqz	a5,80005b7e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ac8:	4681                	li	a3,0
    80005aca:	4601                	li	a2,0
    80005acc:	4589                	li	a1,2
    80005ace:	f5040513          	addi	a0,s0,-176
    80005ad2:	00000097          	auipc	ra,0x0
    80005ad6:	972080e7          	jalr	-1678(ra) # 80005444 <create>
    80005ada:	84aa                	mv	s1,a0
    if(ip == 0){
    80005adc:	c959                	beqz	a0,80005b72 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ade:	04449703          	lh	a4,68(s1)
    80005ae2:	478d                	li	a5,3
    80005ae4:	00f71763          	bne	a4,a5,80005af2 <sys_open+0x72>
    80005ae8:	0464d703          	lhu	a4,70(s1)
    80005aec:	47a5                	li	a5,9
    80005aee:	0ce7ed63          	bltu	a5,a4,80005bc8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	dbc080e7          	jalr	-580(ra) # 800048ae <filealloc>
    80005afa:	89aa                	mv	s3,a0
    80005afc:	10050363          	beqz	a0,80005c02 <sys_open+0x182>
    80005b00:	00000097          	auipc	ra,0x0
    80005b04:	902080e7          	jalr	-1790(ra) # 80005402 <fdalloc>
    80005b08:	892a                	mv	s2,a0
    80005b0a:	0e054763          	bltz	a0,80005bf8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b0e:	04449703          	lh	a4,68(s1)
    80005b12:	478d                	li	a5,3
    80005b14:	0cf70563          	beq	a4,a5,80005bde <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b18:	4789                	li	a5,2
    80005b1a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b1e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b22:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b26:	f4c42783          	lw	a5,-180(s0)
    80005b2a:	0017c713          	xori	a4,a5,1
    80005b2e:	8b05                	andi	a4,a4,1
    80005b30:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b34:	0037f713          	andi	a4,a5,3
    80005b38:	00e03733          	snez	a4,a4
    80005b3c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b40:	4007f793          	andi	a5,a5,1024
    80005b44:	c791                	beqz	a5,80005b50 <sys_open+0xd0>
    80005b46:	04449703          	lh	a4,68(s1)
    80005b4a:	4789                	li	a5,2
    80005b4c:	0af70063          	beq	a4,a5,80005bec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	046080e7          	jalr	70(ra) # 80003b98 <iunlock>
  end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	9c6080e7          	jalr	-1594(ra) # 80004520 <end_op>

  return fd;
    80005b62:	854a                	mv	a0,s2
}
    80005b64:	70ea                	ld	ra,184(sp)
    80005b66:	744a                	ld	s0,176(sp)
    80005b68:	74aa                	ld	s1,168(sp)
    80005b6a:	790a                	ld	s2,160(sp)
    80005b6c:	69ea                	ld	s3,152(sp)
    80005b6e:	6129                	addi	sp,sp,192
    80005b70:	8082                	ret
      end_op();
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	9ae080e7          	jalr	-1618(ra) # 80004520 <end_op>
      return -1;
    80005b7a:	557d                	li	a0,-1
    80005b7c:	b7e5                	j	80005b64 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b7e:	f5040513          	addi	a0,s0,-176
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	700080e7          	jalr	1792(ra) # 80004282 <namei>
    80005b8a:	84aa                	mv	s1,a0
    80005b8c:	c905                	beqz	a0,80005bbc <sys_open+0x13c>
    ilock(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	f48080e7          	jalr	-184(ra) # 80003ad6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b96:	04449703          	lh	a4,68(s1)
    80005b9a:	4785                	li	a5,1
    80005b9c:	f4f711e3          	bne	a4,a5,80005ade <sys_open+0x5e>
    80005ba0:	f4c42783          	lw	a5,-180(s0)
    80005ba4:	d7b9                	beqz	a5,80005af2 <sys_open+0x72>
      iunlockput(ip);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	190080e7          	jalr	400(ra) # 80003d38 <iunlockput>
      end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	970080e7          	jalr	-1680(ra) # 80004520 <end_op>
      return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	b76d                	j	80005b64 <sys_open+0xe4>
      end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	964080e7          	jalr	-1692(ra) # 80004520 <end_op>
      return -1;
    80005bc4:	557d                	li	a0,-1
    80005bc6:	bf79                	j	80005b64 <sys_open+0xe4>
    iunlockput(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	16e080e7          	jalr	366(ra) # 80003d38 <iunlockput>
    end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	94e080e7          	jalr	-1714(ra) # 80004520 <end_op>
    return -1;
    80005bda:	557d                	li	a0,-1
    80005bdc:	b761                	j	80005b64 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bde:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005be2:	04649783          	lh	a5,70(s1)
    80005be6:	02f99223          	sh	a5,36(s3)
    80005bea:	bf25                	j	80005b22 <sys_open+0xa2>
    itrunc(ip);
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	ff6080e7          	jalr	-10(ra) # 80003be4 <itrunc>
    80005bf6:	bfa9                	j	80005b50 <sys_open+0xd0>
      fileclose(f);
    80005bf8:	854e                	mv	a0,s3
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	d70080e7          	jalr	-656(ra) # 8000496a <fileclose>
    iunlockput(ip);
    80005c02:	8526                	mv	a0,s1
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	134080e7          	jalr	308(ra) # 80003d38 <iunlockput>
    end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	914080e7          	jalr	-1772(ra) # 80004520 <end_op>
    return -1;
    80005c14:	557d                	li	a0,-1
    80005c16:	b7b9                	j	80005b64 <sys_open+0xe4>

0000000080005c18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c18:	7175                	addi	sp,sp,-144
    80005c1a:	e506                	sd	ra,136(sp)
    80005c1c:	e122                	sd	s0,128(sp)
    80005c1e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	882080e7          	jalr	-1918(ra) # 800044a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c28:	08000613          	li	a2,128
    80005c2c:	f7040593          	addi	a1,s0,-144
    80005c30:	4501                	li	a0,0
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	1fc080e7          	jalr	508(ra) # 80002e2e <argstr>
    80005c3a:	02054963          	bltz	a0,80005c6c <sys_mkdir+0x54>
    80005c3e:	4681                	li	a3,0
    80005c40:	4601                	li	a2,0
    80005c42:	4585                	li	a1,1
    80005c44:	f7040513          	addi	a0,s0,-144
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	7fc080e7          	jalr	2044(ra) # 80005444 <create>
    80005c50:	cd11                	beqz	a0,80005c6c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	0e6080e7          	jalr	230(ra) # 80003d38 <iunlockput>
  end_op();
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	8c6080e7          	jalr	-1850(ra) # 80004520 <end_op>
  return 0;
    80005c62:	4501                	li	a0,0
}
    80005c64:	60aa                	ld	ra,136(sp)
    80005c66:	640a                	ld	s0,128(sp)
    80005c68:	6149                	addi	sp,sp,144
    80005c6a:	8082                	ret
    end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	8b4080e7          	jalr	-1868(ra) # 80004520 <end_op>
    return -1;
    80005c74:	557d                	li	a0,-1
    80005c76:	b7fd                	j	80005c64 <sys_mkdir+0x4c>

0000000080005c78 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c78:	7135                	addi	sp,sp,-160
    80005c7a:	ed06                	sd	ra,152(sp)
    80005c7c:	e922                	sd	s0,144(sp)
    80005c7e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	822080e7          	jalr	-2014(ra) # 800044a2 <begin_op>
  argint(1, &major);
    80005c88:	f6c40593          	addi	a1,s0,-148
    80005c8c:	4505                	li	a0,1
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	160080e7          	jalr	352(ra) # 80002dee <argint>
  argint(2, &minor);
    80005c96:	f6840593          	addi	a1,s0,-152
    80005c9a:	4509                	li	a0,2
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	152080e7          	jalr	338(ra) # 80002dee <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ca4:	08000613          	li	a2,128
    80005ca8:	f7040593          	addi	a1,s0,-144
    80005cac:	4501                	li	a0,0
    80005cae:	ffffd097          	auipc	ra,0xffffd
    80005cb2:	180080e7          	jalr	384(ra) # 80002e2e <argstr>
    80005cb6:	02054b63          	bltz	a0,80005cec <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cba:	f6841683          	lh	a3,-152(s0)
    80005cbe:	f6c41603          	lh	a2,-148(s0)
    80005cc2:	458d                	li	a1,3
    80005cc4:	f7040513          	addi	a0,s0,-144
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	77c080e7          	jalr	1916(ra) # 80005444 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cd0:	cd11                	beqz	a0,80005cec <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	066080e7          	jalr	102(ra) # 80003d38 <iunlockput>
  end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	846080e7          	jalr	-1978(ra) # 80004520 <end_op>
  return 0;
    80005ce2:	4501                	li	a0,0
}
    80005ce4:	60ea                	ld	ra,152(sp)
    80005ce6:	644a                	ld	s0,144(sp)
    80005ce8:	610d                	addi	sp,sp,160
    80005cea:	8082                	ret
    end_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	834080e7          	jalr	-1996(ra) # 80004520 <end_op>
    return -1;
    80005cf4:	557d                	li	a0,-1
    80005cf6:	b7fd                	j	80005ce4 <sys_mknod+0x6c>

0000000080005cf8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cf8:	7135                	addi	sp,sp,-160
    80005cfa:	ed06                	sd	ra,152(sp)
    80005cfc:	e922                	sd	s0,144(sp)
    80005cfe:	e526                	sd	s1,136(sp)
    80005d00:	e14a                	sd	s2,128(sp)
    80005d02:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d04:	ffffc097          	auipc	ra,0xffffc
    80005d08:	d46080e7          	jalr	-698(ra) # 80001a4a <myproc>
    80005d0c:	892a                	mv	s2,a0
  
  begin_op();
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	794080e7          	jalr	1940(ra) # 800044a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d16:	08000613          	li	a2,128
    80005d1a:	f6040593          	addi	a1,s0,-160
    80005d1e:	4501                	li	a0,0
    80005d20:	ffffd097          	auipc	ra,0xffffd
    80005d24:	10e080e7          	jalr	270(ra) # 80002e2e <argstr>
    80005d28:	04054b63          	bltz	a0,80005d7e <sys_chdir+0x86>
    80005d2c:	f6040513          	addi	a0,s0,-160
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	552080e7          	jalr	1362(ra) # 80004282 <namei>
    80005d38:	84aa                	mv	s1,a0
    80005d3a:	c131                	beqz	a0,80005d7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	d9a080e7          	jalr	-614(ra) # 80003ad6 <ilock>
  if(ip->type != T_DIR){
    80005d44:	04449703          	lh	a4,68(s1)
    80005d48:	4785                	li	a5,1
    80005d4a:	04f71063          	bne	a4,a5,80005d8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d4e:	8526                	mv	a0,s1
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	e48080e7          	jalr	-440(ra) # 80003b98 <iunlock>
  iput(p->cwd);
    80005d58:	15893503          	ld	a0,344(s2)
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	f34080e7          	jalr	-204(ra) # 80003c90 <iput>
  end_op();
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	7bc080e7          	jalr	1980(ra) # 80004520 <end_op>
  p->cwd = ip;
    80005d6c:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d70:	4501                	li	a0,0
}
    80005d72:	60ea                	ld	ra,152(sp)
    80005d74:	644a                	ld	s0,144(sp)
    80005d76:	64aa                	ld	s1,136(sp)
    80005d78:	690a                	ld	s2,128(sp)
    80005d7a:	610d                	addi	sp,sp,160
    80005d7c:	8082                	ret
    end_op();
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	7a2080e7          	jalr	1954(ra) # 80004520 <end_op>
    return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	b7ed                	j	80005d72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d8a:	8526                	mv	a0,s1
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	fac080e7          	jalr	-84(ra) # 80003d38 <iunlockput>
    end_op();
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	78c080e7          	jalr	1932(ra) # 80004520 <end_op>
    return -1;
    80005d9c:	557d                	li	a0,-1
    80005d9e:	bfd1                	j	80005d72 <sys_chdir+0x7a>

0000000080005da0 <sys_exec>:

uint64
sys_exec(void)
{
    80005da0:	7145                	addi	sp,sp,-464
    80005da2:	e786                	sd	ra,456(sp)
    80005da4:	e3a2                	sd	s0,448(sp)
    80005da6:	ff26                	sd	s1,440(sp)
    80005da8:	fb4a                	sd	s2,432(sp)
    80005daa:	f74e                	sd	s3,424(sp)
    80005dac:	f352                	sd	s4,416(sp)
    80005dae:	ef56                	sd	s5,408(sp)
    80005db0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005db2:	e3840593          	addi	a1,s0,-456
    80005db6:	4505                	li	a0,1
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	056080e7          	jalr	86(ra) # 80002e0e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dc0:	08000613          	li	a2,128
    80005dc4:	f4040593          	addi	a1,s0,-192
    80005dc8:	4501                	li	a0,0
    80005dca:	ffffd097          	auipc	ra,0xffffd
    80005dce:	064080e7          	jalr	100(ra) # 80002e2e <argstr>
    80005dd2:	87aa                	mv	a5,a0
    return -1;
    80005dd4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005dd6:	0c07c363          	bltz	a5,80005e9c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005dda:	10000613          	li	a2,256
    80005dde:	4581                	li	a1,0
    80005de0:	e4040513          	addi	a0,s0,-448
    80005de4:	ffffb097          	auipc	ra,0xffffb
    80005de8:	eee080e7          	jalr	-274(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005df0:	89a6                	mv	s3,s1
    80005df2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005df4:	02000a13          	li	s4,32
    80005df8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dfc:	00391513          	slli	a0,s2,0x3
    80005e00:	e3040593          	addi	a1,s0,-464
    80005e04:	e3843783          	ld	a5,-456(s0)
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	ffffd097          	auipc	ra,0xffffd
    80005e0e:	f46080e7          	jalr	-186(ra) # 80002d50 <fetchaddr>
    80005e12:	02054a63          	bltz	a0,80005e46 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e16:	e3043783          	ld	a5,-464(s0)
    80005e1a:	c3b9                	beqz	a5,80005e60 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e1c:	ffffb097          	auipc	ra,0xffffb
    80005e20:	cca080e7          	jalr	-822(ra) # 80000ae6 <kalloc>
    80005e24:	85aa                	mv	a1,a0
    80005e26:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e2a:	cd11                	beqz	a0,80005e46 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e2c:	6605                	lui	a2,0x1
    80005e2e:	e3043503          	ld	a0,-464(s0)
    80005e32:	ffffd097          	auipc	ra,0xffffd
    80005e36:	f70080e7          	jalr	-144(ra) # 80002da2 <fetchstr>
    80005e3a:	00054663          	bltz	a0,80005e46 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e3e:	0905                	addi	s2,s2,1
    80005e40:	09a1                	addi	s3,s3,8
    80005e42:	fb491be3          	bne	s2,s4,80005df8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e46:	f4040913          	addi	s2,s0,-192
    80005e4a:	6088                	ld	a0,0(s1)
    80005e4c:	c539                	beqz	a0,80005e9a <sys_exec+0xfa>
    kfree(argv[i]);
    80005e4e:	ffffb097          	auipc	ra,0xffffb
    80005e52:	b9a080e7          	jalr	-1126(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e56:	04a1                	addi	s1,s1,8
    80005e58:	ff2499e3          	bne	s1,s2,80005e4a <sys_exec+0xaa>
  return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	a83d                	j	80005e9c <sys_exec+0xfc>
      argv[i] = 0;
    80005e60:	0a8e                	slli	s5,s5,0x3
    80005e62:	fc0a8793          	addi	a5,s5,-64
    80005e66:	00878ab3          	add	s5,a5,s0
    80005e6a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e6e:	e4040593          	addi	a1,s0,-448
    80005e72:	f4040513          	addi	a0,s0,-192
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	16e080e7          	jalr	366(ra) # 80004fe4 <exec>
    80005e7e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e80:	f4040993          	addi	s3,s0,-192
    80005e84:	6088                	ld	a0,0(s1)
    80005e86:	c901                	beqz	a0,80005e96 <sys_exec+0xf6>
    kfree(argv[i]);
    80005e88:	ffffb097          	auipc	ra,0xffffb
    80005e8c:	b60080e7          	jalr	-1184(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e90:	04a1                	addi	s1,s1,8
    80005e92:	ff3499e3          	bne	s1,s3,80005e84 <sys_exec+0xe4>
  return ret;
    80005e96:	854a                	mv	a0,s2
    80005e98:	a011                	j	80005e9c <sys_exec+0xfc>
  return -1;
    80005e9a:	557d                	li	a0,-1
}
    80005e9c:	60be                	ld	ra,456(sp)
    80005e9e:	641e                	ld	s0,448(sp)
    80005ea0:	74fa                	ld	s1,440(sp)
    80005ea2:	795a                	ld	s2,432(sp)
    80005ea4:	79ba                	ld	s3,424(sp)
    80005ea6:	7a1a                	ld	s4,416(sp)
    80005ea8:	6afa                	ld	s5,408(sp)
    80005eaa:	6179                	addi	sp,sp,464
    80005eac:	8082                	ret

0000000080005eae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eae:	7139                	addi	sp,sp,-64
    80005eb0:	fc06                	sd	ra,56(sp)
    80005eb2:	f822                	sd	s0,48(sp)
    80005eb4:	f426                	sd	s1,40(sp)
    80005eb6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	b92080e7          	jalr	-1134(ra) # 80001a4a <myproc>
    80005ec0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ec2:	fd840593          	addi	a1,s0,-40
    80005ec6:	4501                	li	a0,0
    80005ec8:	ffffd097          	auipc	ra,0xffffd
    80005ecc:	f46080e7          	jalr	-186(ra) # 80002e0e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ed0:	fc840593          	addi	a1,s0,-56
    80005ed4:	fd040513          	addi	a0,s0,-48
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	dc2080e7          	jalr	-574(ra) # 80004c9a <pipealloc>
    return -1;
    80005ee0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ee2:	0c054463          	bltz	a0,80005faa <sys_pipe+0xfc>
  fd0 = -1;
    80005ee6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eea:	fd043503          	ld	a0,-48(s0)
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	514080e7          	jalr	1300(ra) # 80005402 <fdalloc>
    80005ef6:	fca42223          	sw	a0,-60(s0)
    80005efa:	08054b63          	bltz	a0,80005f90 <sys_pipe+0xe2>
    80005efe:	fc843503          	ld	a0,-56(s0)
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	500080e7          	jalr	1280(ra) # 80005402 <fdalloc>
    80005f0a:	fca42023          	sw	a0,-64(s0)
    80005f0e:	06054863          	bltz	a0,80005f7e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f12:	4691                	li	a3,4
    80005f14:	fc440613          	addi	a2,s0,-60
    80005f18:	fd843583          	ld	a1,-40(s0)
    80005f1c:	6ca8                	ld	a0,88(s1)
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	74e080e7          	jalr	1870(ra) # 8000166c <copyout>
    80005f26:	02054063          	bltz	a0,80005f46 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f2a:	4691                	li	a3,4
    80005f2c:	fc040613          	addi	a2,s0,-64
    80005f30:	fd843583          	ld	a1,-40(s0)
    80005f34:	0591                	addi	a1,a1,4
    80005f36:	6ca8                	ld	a0,88(s1)
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	734080e7          	jalr	1844(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f40:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f42:	06055463          	bgez	a0,80005faa <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f46:	fc442783          	lw	a5,-60(s0)
    80005f4a:	07e9                	addi	a5,a5,26
    80005f4c:	078e                	slli	a5,a5,0x3
    80005f4e:	97a6                	add	a5,a5,s1
    80005f50:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f54:	fc042783          	lw	a5,-64(s0)
    80005f58:	07e9                	addi	a5,a5,26
    80005f5a:	078e                	slli	a5,a5,0x3
    80005f5c:	94be                	add	s1,s1,a5
    80005f5e:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005f62:	fd043503          	ld	a0,-48(s0)
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	a04080e7          	jalr	-1532(ra) # 8000496a <fileclose>
    fileclose(wf);
    80005f6e:	fc843503          	ld	a0,-56(s0)
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	9f8080e7          	jalr	-1544(ra) # 8000496a <fileclose>
    return -1;
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	a03d                	j	80005faa <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f7e:	fc442783          	lw	a5,-60(s0)
    80005f82:	0007c763          	bltz	a5,80005f90 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f86:	07e9                	addi	a5,a5,26
    80005f88:	078e                	slli	a5,a5,0x3
    80005f8a:	97a6                	add	a5,a5,s1
    80005f8c:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005f90:	fd043503          	ld	a0,-48(s0)
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	9d6080e7          	jalr	-1578(ra) # 8000496a <fileclose>
    fileclose(wf);
    80005f9c:	fc843503          	ld	a0,-56(s0)
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	9ca080e7          	jalr	-1590(ra) # 8000496a <fileclose>
    return -1;
    80005fa8:	57fd                	li	a5,-1
}
    80005faa:	853e                	mv	a0,a5
    80005fac:	70e2                	ld	ra,56(sp)
    80005fae:	7442                	ld	s0,48(sp)
    80005fb0:	74a2                	ld	s1,40(sp)
    80005fb2:	6121                	addi	sp,sp,64
    80005fb4:	8082                	ret
	...

0000000080005fc0 <kernelvec>:
    80005fc0:	7111                	addi	sp,sp,-256
    80005fc2:	e006                	sd	ra,0(sp)
    80005fc4:	e40a                	sd	sp,8(sp)
    80005fc6:	e80e                	sd	gp,16(sp)
    80005fc8:	ec12                	sd	tp,24(sp)
    80005fca:	f016                	sd	t0,32(sp)
    80005fcc:	f41a                	sd	t1,40(sp)
    80005fce:	f81e                	sd	t2,48(sp)
    80005fd0:	fc22                	sd	s0,56(sp)
    80005fd2:	e0a6                	sd	s1,64(sp)
    80005fd4:	e4aa                	sd	a0,72(sp)
    80005fd6:	e8ae                	sd	a1,80(sp)
    80005fd8:	ecb2                	sd	a2,88(sp)
    80005fda:	f0b6                	sd	a3,96(sp)
    80005fdc:	f4ba                	sd	a4,104(sp)
    80005fde:	f8be                	sd	a5,112(sp)
    80005fe0:	fcc2                	sd	a6,120(sp)
    80005fe2:	e146                	sd	a7,128(sp)
    80005fe4:	e54a                	sd	s2,136(sp)
    80005fe6:	e94e                	sd	s3,144(sp)
    80005fe8:	ed52                	sd	s4,152(sp)
    80005fea:	f156                	sd	s5,160(sp)
    80005fec:	f55a                	sd	s6,168(sp)
    80005fee:	f95e                	sd	s7,176(sp)
    80005ff0:	fd62                	sd	s8,184(sp)
    80005ff2:	e1e6                	sd	s9,192(sp)
    80005ff4:	e5ea                	sd	s10,200(sp)
    80005ff6:	e9ee                	sd	s11,208(sp)
    80005ff8:	edf2                	sd	t3,216(sp)
    80005ffa:	f1f6                	sd	t4,224(sp)
    80005ffc:	f5fa                	sd	t5,232(sp)
    80005ffe:	f9fe                	sd	t6,240(sp)
    80006000:	c1dfc0ef          	jal	ra,80002c1c <kerneltrap>
    80006004:	6082                	ld	ra,0(sp)
    80006006:	6122                	ld	sp,8(sp)
    80006008:	61c2                	ld	gp,16(sp)
    8000600a:	7282                	ld	t0,32(sp)
    8000600c:	7322                	ld	t1,40(sp)
    8000600e:	73c2                	ld	t2,48(sp)
    80006010:	7462                	ld	s0,56(sp)
    80006012:	6486                	ld	s1,64(sp)
    80006014:	6526                	ld	a0,72(sp)
    80006016:	65c6                	ld	a1,80(sp)
    80006018:	6666                	ld	a2,88(sp)
    8000601a:	7686                	ld	a3,96(sp)
    8000601c:	7726                	ld	a4,104(sp)
    8000601e:	77c6                	ld	a5,112(sp)
    80006020:	7866                	ld	a6,120(sp)
    80006022:	688a                	ld	a7,128(sp)
    80006024:	692a                	ld	s2,136(sp)
    80006026:	69ca                	ld	s3,144(sp)
    80006028:	6a6a                	ld	s4,152(sp)
    8000602a:	7a8a                	ld	s5,160(sp)
    8000602c:	7b2a                	ld	s6,168(sp)
    8000602e:	7bca                	ld	s7,176(sp)
    80006030:	7c6a                	ld	s8,184(sp)
    80006032:	6c8e                	ld	s9,192(sp)
    80006034:	6d2e                	ld	s10,200(sp)
    80006036:	6dce                	ld	s11,208(sp)
    80006038:	6e6e                	ld	t3,216(sp)
    8000603a:	7e8e                	ld	t4,224(sp)
    8000603c:	7f2e                	ld	t5,232(sp)
    8000603e:	7fce                	ld	t6,240(sp)
    80006040:	6111                	addi	sp,sp,256
    80006042:	10200073          	sret
    80006046:	00000013          	nop
    8000604a:	00000013          	nop
    8000604e:	0001                	nop

0000000080006050 <timervec>:
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	e10c                	sd	a1,0(a0)
    80006056:	e510                	sd	a2,8(a0)
    80006058:	e914                	sd	a3,16(a0)
    8000605a:	6d0c                	ld	a1,24(a0)
    8000605c:	7110                	ld	a2,32(a0)
    8000605e:	6194                	ld	a3,0(a1)
    80006060:	96b2                	add	a3,a3,a2
    80006062:	e194                	sd	a3,0(a1)
    80006064:	4589                	li	a1,2
    80006066:	14459073          	csrw	sip,a1
    8000606a:	6914                	ld	a3,16(a0)
    8000606c:	6510                	ld	a2,8(a0)
    8000606e:	610c                	ld	a1,0(a0)
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	30200073          	mret
	...

000000008000607a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000607a:	1141                	addi	sp,sp,-16
    8000607c:	e422                	sd	s0,8(sp)
    8000607e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006080:	0c0007b7          	lui	a5,0xc000
    80006084:	4705                	li	a4,1
    80006086:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006088:	c3d8                	sw	a4,4(a5)
}
    8000608a:	6422                	ld	s0,8(sp)
    8000608c:	0141                	addi	sp,sp,16
    8000608e:	8082                	ret

0000000080006090 <plicinithart>:

void
plicinithart(void)
{
    80006090:	1141                	addi	sp,sp,-16
    80006092:	e406                	sd	ra,8(sp)
    80006094:	e022                	sd	s0,0(sp)
    80006096:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	986080e7          	jalr	-1658(ra) # 80001a1e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060a0:	0085171b          	slliw	a4,a0,0x8
    800060a4:	0c0027b7          	lui	a5,0xc002
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	40200713          	li	a4,1026
    800060ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060b2:	00d5151b          	slliw	a0,a0,0xd
    800060b6:	0c2017b7          	lui	a5,0xc201
    800060ba:	97aa                	add	a5,a5,a0
    800060bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret

00000000800060c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060c8:	1141                	addi	sp,sp,-16
    800060ca:	e406                	sd	ra,8(sp)
    800060cc:	e022                	sd	s0,0(sp)
    800060ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	94e080e7          	jalr	-1714(ra) # 80001a1e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060d8:	00d5151b          	slliw	a0,a0,0xd
    800060dc:	0c2017b7          	lui	a5,0xc201
    800060e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060e2:	43c8                	lw	a0,4(a5)
    800060e4:	60a2                	ld	ra,8(sp)
    800060e6:	6402                	ld	s0,0(sp)
    800060e8:	0141                	addi	sp,sp,16
    800060ea:	8082                	ret

00000000800060ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	1000                	addi	s0,sp,32
    800060f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	926080e7          	jalr	-1754(ra) # 80001a1e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006100:	00d5151b          	slliw	a0,a0,0xd
    80006104:	0c2017b7          	lui	a5,0xc201
    80006108:	97aa                	add	a5,a5,a0
    8000610a:	c3c4                	sw	s1,4(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret

0000000080006116 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006116:	1141                	addi	sp,sp,-16
    80006118:	e406                	sd	ra,8(sp)
    8000611a:	e022                	sd	s0,0(sp)
    8000611c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000611e:	479d                	li	a5,7
    80006120:	04a7cc63          	blt	a5,a0,80006178 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006124:	0001c797          	auipc	a5,0x1c
    80006128:	58c78793          	addi	a5,a5,1420 # 800226b0 <disk>
    8000612c:	97aa                	add	a5,a5,a0
    8000612e:	0187c783          	lbu	a5,24(a5)
    80006132:	ebb9                	bnez	a5,80006188 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006134:	00451693          	slli	a3,a0,0x4
    80006138:	0001c797          	auipc	a5,0x1c
    8000613c:	57878793          	addi	a5,a5,1400 # 800226b0 <disk>
    80006140:	6398                	ld	a4,0(a5)
    80006142:	9736                	add	a4,a4,a3
    80006144:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006148:	6398                	ld	a4,0(a5)
    8000614a:	9736                	add	a4,a4,a3
    8000614c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006150:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006154:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006158:	97aa                	add	a5,a5,a0
    8000615a:	4705                	li	a4,1
    8000615c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006160:	0001c517          	auipc	a0,0x1c
    80006164:	56850513          	addi	a0,a0,1384 # 800226c8 <disk+0x18>
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	21e080e7          	jalr	542(ra) # 80002386 <wakeup>
}
    80006170:	60a2                	ld	ra,8(sp)
    80006172:	6402                	ld	s0,0(sp)
    80006174:	0141                	addi	sp,sp,16
    80006176:	8082                	ret
    panic("free_desc 1");
    80006178:	00002517          	auipc	a0,0x2
    8000617c:	6c850513          	addi	a0,a0,1736 # 80008840 <syscalls+0x2f8>
    80006180:	ffffa097          	auipc	ra,0xffffa
    80006184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006188:	00002517          	auipc	a0,0x2
    8000618c:	6c850513          	addi	a0,a0,1736 # 80008850 <syscalls+0x308>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3b0080e7          	jalr	944(ra) # 80000540 <panic>

0000000080006198 <virtio_disk_init>:
{
    80006198:	1101                	addi	sp,sp,-32
    8000619a:	ec06                	sd	ra,24(sp)
    8000619c:	e822                	sd	s0,16(sp)
    8000619e:	e426                	sd	s1,8(sp)
    800061a0:	e04a                	sd	s2,0(sp)
    800061a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061a4:	00002597          	auipc	a1,0x2
    800061a8:	6bc58593          	addi	a1,a1,1724 # 80008860 <syscalls+0x318>
    800061ac:	0001c517          	auipc	a0,0x1c
    800061b0:	62c50513          	addi	a0,a0,1580 # 800227d8 <disk+0x128>
    800061b4:	ffffb097          	auipc	ra,0xffffb
    800061b8:	992080e7          	jalr	-1646(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061bc:	100017b7          	lui	a5,0x10001
    800061c0:	4398                	lw	a4,0(a5)
    800061c2:	2701                	sext.w	a4,a4
    800061c4:	747277b7          	lui	a5,0x74727
    800061c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061cc:	14f71b63          	bne	a4,a5,80006322 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061d0:	100017b7          	lui	a5,0x10001
    800061d4:	43dc                	lw	a5,4(a5)
    800061d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061d8:	4709                	li	a4,2
    800061da:	14e79463          	bne	a5,a4,80006322 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061de:	100017b7          	lui	a5,0x10001
    800061e2:	479c                	lw	a5,8(a5)
    800061e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061e6:	12e79e63          	bne	a5,a4,80006322 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061ea:	100017b7          	lui	a5,0x10001
    800061ee:	47d8                	lw	a4,12(a5)
    800061f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061f2:	554d47b7          	lui	a5,0x554d4
    800061f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061fa:	12f71463          	bne	a4,a5,80006322 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061fe:	100017b7          	lui	a5,0x10001
    80006202:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006206:	4705                	li	a4,1
    80006208:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000620a:	470d                	li	a4,3
    8000620c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000620e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006210:	c7ffe6b7          	lui	a3,0xc7ffe
    80006214:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbf6f>
    80006218:	8f75                	and	a4,a4,a3
    8000621a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621c:	472d                	li	a4,11
    8000621e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006220:	5bbc                	lw	a5,112(a5)
    80006222:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006226:	8ba1                	andi	a5,a5,8
    80006228:	10078563          	beqz	a5,80006332 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006234:	43fc                	lw	a5,68(a5)
    80006236:	2781                	sext.w	a5,a5
    80006238:	10079563          	bnez	a5,80006342 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	5bdc                	lw	a5,52(a5)
    80006242:	2781                	sext.w	a5,a5
  if(max == 0)
    80006244:	10078763          	beqz	a5,80006352 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006248:	471d                	li	a4,7
    8000624a:	10f77c63          	bgeu	a4,a5,80006362 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000624e:	ffffb097          	auipc	ra,0xffffb
    80006252:	898080e7          	jalr	-1896(ra) # 80000ae6 <kalloc>
    80006256:	0001c497          	auipc	s1,0x1c
    8000625a:	45a48493          	addi	s1,s1,1114 # 800226b0 <disk>
    8000625e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	886080e7          	jalr	-1914(ra) # 80000ae6 <kalloc>
    80006268:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000626a:	ffffb097          	auipc	ra,0xffffb
    8000626e:	87c080e7          	jalr	-1924(ra) # 80000ae6 <kalloc>
    80006272:	87aa                	mv	a5,a0
    80006274:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006276:	6088                	ld	a0,0(s1)
    80006278:	cd6d                	beqz	a0,80006372 <virtio_disk_init+0x1da>
    8000627a:	0001c717          	auipc	a4,0x1c
    8000627e:	43e73703          	ld	a4,1086(a4) # 800226b8 <disk+0x8>
    80006282:	cb65                	beqz	a4,80006372 <virtio_disk_init+0x1da>
    80006284:	c7fd                	beqz	a5,80006372 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006286:	6605                	lui	a2,0x1
    80006288:	4581                	li	a1,0
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	a48080e7          	jalr	-1464(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006292:	0001c497          	auipc	s1,0x1c
    80006296:	41e48493          	addi	s1,s1,1054 # 800226b0 <disk>
    8000629a:	6605                	lui	a2,0x1
    8000629c:	4581                	li	a1,0
    8000629e:	6488                	ld	a0,8(s1)
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	a32080e7          	jalr	-1486(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800062a8:	6605                	lui	a2,0x1
    800062aa:	4581                	li	a1,0
    800062ac:	6888                	ld	a0,16(s1)
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	a24080e7          	jalr	-1500(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062b6:	100017b7          	lui	a5,0x10001
    800062ba:	4721                	li	a4,8
    800062bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062be:	4098                	lw	a4,0(s1)
    800062c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062c4:	40d8                	lw	a4,4(s1)
    800062c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ca:	6498                	ld	a4,8(s1)
    800062cc:	0007069b          	sext.w	a3,a4
    800062d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062d4:	9701                	srai	a4,a4,0x20
    800062d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062da:	6898                	ld	a4,16(s1)
    800062dc:	0007069b          	sext.w	a3,a4
    800062e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800062e4:	9701                	srai	a4,a4,0x20
    800062e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800062ea:	4705                	li	a4,1
    800062ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800062ee:	00e48c23          	sb	a4,24(s1)
    800062f2:	00e48ca3          	sb	a4,25(s1)
    800062f6:	00e48d23          	sb	a4,26(s1)
    800062fa:	00e48da3          	sb	a4,27(s1)
    800062fe:	00e48e23          	sb	a4,28(s1)
    80006302:	00e48ea3          	sb	a4,29(s1)
    80006306:	00e48f23          	sb	a4,30(s1)
    8000630a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000630e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006312:	0727a823          	sw	s2,112(a5)
}
    80006316:	60e2                	ld	ra,24(sp)
    80006318:	6442                	ld	s0,16(sp)
    8000631a:	64a2                	ld	s1,8(sp)
    8000631c:	6902                	ld	s2,0(sp)
    8000631e:	6105                	addi	sp,sp,32
    80006320:	8082                	ret
    panic("could not find virtio disk");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	54e50513          	addi	a0,a0,1358 # 80008870 <syscalls+0x328>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	216080e7          	jalr	534(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	55e50513          	addi	a0,a0,1374 # 80008890 <syscalls+0x348>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	206080e7          	jalr	518(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	56e50513          	addi	a0,a0,1390 # 800088b0 <syscalls+0x368>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	57e50513          	addi	a0,a0,1406 # 800088d0 <syscalls+0x388>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	58e50513          	addi	a0,a0,1422 # 800088f0 <syscalls+0x3a8>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	59e50513          	addi	a0,a0,1438 # 80008910 <syscalls+0x3c8>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>

0000000080006382 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006382:	7119                	addi	sp,sp,-128
    80006384:	fc86                	sd	ra,120(sp)
    80006386:	f8a2                	sd	s0,112(sp)
    80006388:	f4a6                	sd	s1,104(sp)
    8000638a:	f0ca                	sd	s2,96(sp)
    8000638c:	ecce                	sd	s3,88(sp)
    8000638e:	e8d2                	sd	s4,80(sp)
    80006390:	e4d6                	sd	s5,72(sp)
    80006392:	e0da                	sd	s6,64(sp)
    80006394:	fc5e                	sd	s7,56(sp)
    80006396:	f862                	sd	s8,48(sp)
    80006398:	f466                	sd	s9,40(sp)
    8000639a:	f06a                	sd	s10,32(sp)
    8000639c:	ec6e                	sd	s11,24(sp)
    8000639e:	0100                	addi	s0,sp,128
    800063a0:	8aaa                	mv	s5,a0
    800063a2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063a4:	00c52d03          	lw	s10,12(a0)
    800063a8:	001d1d1b          	slliw	s10,s10,0x1
    800063ac:	1d02                	slli	s10,s10,0x20
    800063ae:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063b2:	0001c517          	auipc	a0,0x1c
    800063b6:	42650513          	addi	a0,a0,1062 # 800227d8 <disk+0x128>
    800063ba:	ffffb097          	auipc	ra,0xffffb
    800063be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800063c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063c6:	0001cb97          	auipc	s7,0x1c
    800063ca:	2eab8b93          	addi	s7,s7,746 # 800226b0 <disk>
  for(int i = 0; i < 3; i++){
    800063ce:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063d0:	0001cc97          	auipc	s9,0x1c
    800063d4:	408c8c93          	addi	s9,s9,1032 # 800227d8 <disk+0x128>
    800063d8:	a08d                	j	8000643a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063da:	00fb8733          	add	a4,s7,a5
    800063de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063e4:	0207c563          	bltz	a5,8000640e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800063e8:	2905                	addiw	s2,s2,1
    800063ea:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800063ec:	05690c63          	beq	s2,s6,80006444 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800063f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063f2:	0001c717          	auipc	a4,0x1c
    800063f6:	2be70713          	addi	a4,a4,702 # 800226b0 <disk>
    800063fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063fc:	01874683          	lbu	a3,24(a4)
    80006400:	fee9                	bnez	a3,800063da <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006402:	2785                	addiw	a5,a5,1
    80006404:	0705                	addi	a4,a4,1
    80006406:	fe979be3          	bne	a5,s1,800063fc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000640a:	57fd                	li	a5,-1
    8000640c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000640e:	01205d63          	blez	s2,80006428 <virtio_disk_rw+0xa6>
    80006412:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006414:	000a2503          	lw	a0,0(s4)
    80006418:	00000097          	auipc	ra,0x0
    8000641c:	cfe080e7          	jalr	-770(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    80006420:	2d85                	addiw	s11,s11,1
    80006422:	0a11                	addi	s4,s4,4
    80006424:	ff2d98e3          	bne	s11,s2,80006414 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006428:	85e6                	mv	a1,s9
    8000642a:	0001c517          	auipc	a0,0x1c
    8000642e:	29e50513          	addi	a0,a0,670 # 800226c8 <disk+0x18>
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	ef0080e7          	jalr	-272(ra) # 80002322 <sleep>
  for(int i = 0; i < 3; i++){
    8000643a:	f8040a13          	addi	s4,s0,-128
{
    8000643e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006440:	894e                	mv	s2,s3
    80006442:	b77d                	j	800063f0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006444:	f8042503          	lw	a0,-128(s0)
    80006448:	00a50713          	addi	a4,a0,10
    8000644c:	0712                	slli	a4,a4,0x4

  if(write)
    8000644e:	0001c797          	auipc	a5,0x1c
    80006452:	26278793          	addi	a5,a5,610 # 800226b0 <disk>
    80006456:	00e786b3          	add	a3,a5,a4
    8000645a:	01803633          	snez	a2,s8
    8000645e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006460:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006464:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006468:	f6070613          	addi	a2,a4,-160
    8000646c:	6394                	ld	a3,0(a5)
    8000646e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006470:	00870593          	addi	a1,a4,8
    80006474:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006476:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006478:	0007b803          	ld	a6,0(a5)
    8000647c:	9642                	add	a2,a2,a6
    8000647e:	46c1                	li	a3,16
    80006480:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006482:	4585                	li	a1,1
    80006484:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006488:	f8442683          	lw	a3,-124(s0)
    8000648c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006490:	0692                	slli	a3,a3,0x4
    80006492:	9836                	add	a6,a6,a3
    80006494:	058a8613          	addi	a2,s5,88
    80006498:	00c83023          	sd	a2,0(a6) # fffffffffff00000 <end+0xffffffff7fedd810>
  disk.desc[idx[1]].len = BSIZE;
    8000649c:	0007b803          	ld	a6,0(a5)
    800064a0:	96c2                	add	a3,a3,a6
    800064a2:	40000613          	li	a2,1024
    800064a6:	c690                	sw	a2,8(a3)
  if(write)
    800064a8:	001c3613          	seqz	a2,s8
    800064ac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064b0:	00166613          	ori	a2,a2,1
    800064b4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064b8:	f8842603          	lw	a2,-120(s0)
    800064bc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064c0:	00250693          	addi	a3,a0,2
    800064c4:	0692                	slli	a3,a3,0x4
    800064c6:	96be                	add	a3,a3,a5
    800064c8:	58fd                	li	a7,-1
    800064ca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064ce:	0612                	slli	a2,a2,0x4
    800064d0:	9832                	add	a6,a6,a2
    800064d2:	f9070713          	addi	a4,a4,-112
    800064d6:	973e                	add	a4,a4,a5
    800064d8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800064dc:	6398                	ld	a4,0(a5)
    800064de:	9732                	add	a4,a4,a2
    800064e0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064e2:	4609                	li	a2,2
    800064e4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800064e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064ec:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800064f0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064f4:	6794                	ld	a3,8(a5)
    800064f6:	0026d703          	lhu	a4,2(a3)
    800064fa:	8b1d                	andi	a4,a4,7
    800064fc:	0706                	slli	a4,a4,0x1
    800064fe:	96ba                	add	a3,a3,a4
    80006500:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006504:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006508:	6798                	ld	a4,8(a5)
    8000650a:	00275783          	lhu	a5,2(a4)
    8000650e:	2785                	addiw	a5,a5,1
    80006510:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006514:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006518:	100017b7          	lui	a5,0x10001
    8000651c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006520:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006524:	0001c917          	auipc	s2,0x1c
    80006528:	2b490913          	addi	s2,s2,692 # 800227d8 <disk+0x128>
  while(b->disk == 1) {
    8000652c:	4485                	li	s1,1
    8000652e:	00b79c63          	bne	a5,a1,80006546 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006532:	85ca                	mv	a1,s2
    80006534:	8556                	mv	a0,s5
    80006536:	ffffc097          	auipc	ra,0xffffc
    8000653a:	dec080e7          	jalr	-532(ra) # 80002322 <sleep>
  while(b->disk == 1) {
    8000653e:	004aa783          	lw	a5,4(s5)
    80006542:	fe9788e3          	beq	a5,s1,80006532 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006546:	f8042903          	lw	s2,-128(s0)
    8000654a:	00290713          	addi	a4,s2,2
    8000654e:	0712                	slli	a4,a4,0x4
    80006550:	0001c797          	auipc	a5,0x1c
    80006554:	16078793          	addi	a5,a5,352 # 800226b0 <disk>
    80006558:	97ba                	add	a5,a5,a4
    8000655a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000655e:	0001c997          	auipc	s3,0x1c
    80006562:	15298993          	addi	s3,s3,338 # 800226b0 <disk>
    80006566:	00491713          	slli	a4,s2,0x4
    8000656a:	0009b783          	ld	a5,0(s3)
    8000656e:	97ba                	add	a5,a5,a4
    80006570:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006574:	854a                	mv	a0,s2
    80006576:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000657a:	00000097          	auipc	ra,0x0
    8000657e:	b9c080e7          	jalr	-1124(ra) # 80006116 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006582:	8885                	andi	s1,s1,1
    80006584:	f0ed                	bnez	s1,80006566 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006586:	0001c517          	auipc	a0,0x1c
    8000658a:	25250513          	addi	a0,a0,594 # 800227d8 <disk+0x128>
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	6fc080e7          	jalr	1788(ra) # 80000c8a <release>
}
    80006596:	70e6                	ld	ra,120(sp)
    80006598:	7446                	ld	s0,112(sp)
    8000659a:	74a6                	ld	s1,104(sp)
    8000659c:	7906                	ld	s2,96(sp)
    8000659e:	69e6                	ld	s3,88(sp)
    800065a0:	6a46                	ld	s4,80(sp)
    800065a2:	6aa6                	ld	s5,72(sp)
    800065a4:	6b06                	ld	s6,64(sp)
    800065a6:	7be2                	ld	s7,56(sp)
    800065a8:	7c42                	ld	s8,48(sp)
    800065aa:	7ca2                	ld	s9,40(sp)
    800065ac:	7d02                	ld	s10,32(sp)
    800065ae:	6de2                	ld	s11,24(sp)
    800065b0:	6109                	addi	sp,sp,128
    800065b2:	8082                	ret

00000000800065b4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065b4:	1101                	addi	sp,sp,-32
    800065b6:	ec06                	sd	ra,24(sp)
    800065b8:	e822                	sd	s0,16(sp)
    800065ba:	e426                	sd	s1,8(sp)
    800065bc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065be:	0001c497          	auipc	s1,0x1c
    800065c2:	0f248493          	addi	s1,s1,242 # 800226b0 <disk>
    800065c6:	0001c517          	auipc	a0,0x1c
    800065ca:	21250513          	addi	a0,a0,530 # 800227d8 <disk+0x128>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	608080e7          	jalr	1544(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065d6:	10001737          	lui	a4,0x10001
    800065da:	533c                	lw	a5,96(a4)
    800065dc:	8b8d                	andi	a5,a5,3
    800065de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065e4:	689c                	ld	a5,16(s1)
    800065e6:	0204d703          	lhu	a4,32(s1)
    800065ea:	0027d783          	lhu	a5,2(a5)
    800065ee:	04f70863          	beq	a4,a5,8000663e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800065f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065f6:	6898                	ld	a4,16(s1)
    800065f8:	0204d783          	lhu	a5,32(s1)
    800065fc:	8b9d                	andi	a5,a5,7
    800065fe:	078e                	slli	a5,a5,0x3
    80006600:	97ba                	add	a5,a5,a4
    80006602:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006604:	00278713          	addi	a4,a5,2
    80006608:	0712                	slli	a4,a4,0x4
    8000660a:	9726                	add	a4,a4,s1
    8000660c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006610:	e721                	bnez	a4,80006658 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006612:	0789                	addi	a5,a5,2
    80006614:	0792                	slli	a5,a5,0x4
    80006616:	97a6                	add	a5,a5,s1
    80006618:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000661a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000661e:	ffffc097          	auipc	ra,0xffffc
    80006622:	d68080e7          	jalr	-664(ra) # 80002386 <wakeup>

    disk.used_idx += 1;
    80006626:	0204d783          	lhu	a5,32(s1)
    8000662a:	2785                	addiw	a5,a5,1
    8000662c:	17c2                	slli	a5,a5,0x30
    8000662e:	93c1                	srli	a5,a5,0x30
    80006630:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006634:	6898                	ld	a4,16(s1)
    80006636:	00275703          	lhu	a4,2(a4)
    8000663a:	faf71ce3          	bne	a4,a5,800065f2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000663e:	0001c517          	auipc	a0,0x1c
    80006642:	19a50513          	addi	a0,a0,410 # 800227d8 <disk+0x128>
    80006646:	ffffa097          	auipc	ra,0xffffa
    8000664a:	644080e7          	jalr	1604(ra) # 80000c8a <release>
}
    8000664e:	60e2                	ld	ra,24(sp)
    80006650:	6442                	ld	s0,16(sp)
    80006652:	64a2                	ld	s1,8(sp)
    80006654:	6105                	addi	sp,sp,32
    80006656:	8082                	ret
      panic("virtio_disk_intr status");
    80006658:	00002517          	auipc	a0,0x2
    8000665c:	2d050513          	addi	a0,a0,720 # 80008928 <syscalls+0x3e0>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	ee0080e7          	jalr	-288(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
