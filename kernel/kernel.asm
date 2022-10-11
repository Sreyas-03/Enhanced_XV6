
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c3013103          	ld	sp,-976(sp) # 80008c30 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	c4070713          	addi	a4,a4,-960 # 80008c90 <timer_scratch>
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
    80000066:	44e78793          	addi	a5,a5,1102 # 800064b0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda0bf>
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
    8000012e:	6ea080e7          	jalr	1770(ra) # 80002814 <either_copyin>
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
    8000018e:	c4650513          	addi	a0,a0,-954 # 80010dd0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	c3648493          	addi	s1,s1,-970 # 80010dd0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	cc690913          	addi	s2,s2,-826 # 80010e68 <cons+0x98>
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
    800001c4:	886080e7          	jalr	-1914(ra) # 80001a46 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	496080e7          	jalr	1174(ra) # 8000265e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1ae080e7          	jalr	430(ra) # 80002384 <sleep>
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
    80000216:	5ac080e7          	jalr	1452(ra) # 800027be <either_copyout>
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
    8000022a:	baa50513          	addi	a0,a0,-1110 # 80010dd0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	b9450513          	addi	a0,a0,-1132 # 80010dd0 <cons>
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
    80000276:	bef72b23          	sw	a5,-1034(a4) # 80010e68 <cons+0x98>
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
    800002d0:	b0450513          	addi	a0,a0,-1276 # 80010dd0 <cons>
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
    800002f6:	578080e7          	jalr	1400(ra) # 8000286a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ad650513          	addi	a0,a0,-1322 # 80010dd0 <cons>
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
    80000322:	ab270713          	addi	a4,a4,-1358 # 80010dd0 <cons>
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
    8000034c:	a8878793          	addi	a5,a5,-1400 # 80010dd0 <cons>
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
    8000037a:	af27a783          	lw	a5,-1294(a5) # 80010e68 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	a4670713          	addi	a4,a4,-1466 # 80010dd0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	a3648493          	addi	s1,s1,-1482 # 80010dd0 <cons>
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
    800003da:	9fa70713          	addi	a4,a4,-1542 # 80010dd0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	a8f72223          	sw	a5,-1404(a4) # 80010e70 <cons+0xa0>
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
    80000416:	9be78793          	addi	a5,a5,-1602 # 80010dd0 <cons>
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
    8000043a:	a2c7ab23          	sw	a2,-1482(a5) # 80010e6c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	a2a50513          	addi	a0,a0,-1494 # 80010e68 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fb8080e7          	jalr	-72(ra) # 800023fe <wakeup>
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
    80000464:	97050513          	addi	a0,a0,-1680 # 80010dd0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	6f078793          	addi	a5,a5,1776 # 80022b68 <devsw>
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
    80000550:	9407a223          	sw	zero,-1724(a5) # 80010e90 <pr+0x18>
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
    80000584:	6cf72823          	sw	a5,1744(a4) # 80008c50 <panicked>
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
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	8d4dad83          	lw	s11,-1836(s11) # 80010e90 <pr+0x18>
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
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	87e50513          	addi	a0,a0,-1922 # 80010e78 <pr>
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
    8000075c:	72050513          	addi	a0,a0,1824 # 80010e78 <pr>
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
    80000778:	70448493          	addi	s1,s1,1796 # 80010e78 <pr>
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
    800007d8:	6c450513          	addi	a0,a0,1732 # 80010e98 <uart_tx_lock>
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
    80000804:	4507a783          	lw	a5,1104(a5) # 80008c50 <panicked>
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
    8000083c:	4207b783          	ld	a5,1056(a5) # 80008c58 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	42073703          	ld	a4,1056(a4) # 80008c60 <uart_tx_w>
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
    80000866:	636a0a13          	addi	s4,s4,1590 # 80010e98 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	3ee48493          	addi	s1,s1,1006 # 80008c58 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	3ee98993          	addi	s3,s3,1006 # 80008c60 <uart_tx_w>
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
    80000898:	b6a080e7          	jalr	-1174(ra) # 800023fe <wakeup>
    
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
    800008d4:	5c850513          	addi	a0,a0,1480 # 80010e98 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	3707a783          	lw	a5,880(a5) # 80008c50 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	37673703          	ld	a4,886(a4) # 80008c60 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	3667b783          	ld	a5,870(a5) # 80008c58 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	59a98993          	addi	s3,s3,1434 # 80010e98 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	35248493          	addi	s1,s1,850 # 80008c58 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	35290913          	addi	s2,s2,850 # 80008c60 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a66080e7          	jalr	-1434(ra) # 80002384 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	56448493          	addi	s1,s1,1380 # 80010e98 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	30e7bc23          	sd	a4,792(a5) # 80008c60 <uart_tx_w>
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
    800009be:	4de48493          	addi	s1,s1,1246 # 80010e98 <uart_tx_lock>
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
    800009fc:	00024797          	auipc	a5,0x24
    80000a00:	d4478793          	addi	a5,a5,-700 # 80024740 <end>
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
    80000a20:	4b490913          	addi	s2,s2,1204 # 80010ed0 <kmem>
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
    80000abe:	41650513          	addi	a0,a0,1046 # 80010ed0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	c7250513          	addi	a0,a0,-910 # 80024740 <end>
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
    80000af4:	3e048493          	addi	s1,s1,992 # 80010ed0 <kmem>
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
    80000b0c:	3c850513          	addi	a0,a0,968 # 80010ed0 <kmem>
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
    80000b38:	39c50513          	addi	a0,a0,924 # 80010ed0 <kmem>
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
    80000b74:	eba080e7          	jalr	-326(ra) # 80001a2a <mycpu>
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
    80000ba6:	e88080e7          	jalr	-376(ra) # 80001a2a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e7c080e7          	jalr	-388(ra) # 80001a2a <mycpu>
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
    80000bca:	e64080e7          	jalr	-412(ra) # 80001a2a <mycpu>
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
    80000c0a:	e24080e7          	jalr	-476(ra) # 80001a2a <mycpu>
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
    80000c36:	df8080e7          	jalr	-520(ra) # 80001a2a <mycpu>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda8c1>
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
    80000e84:	b9a080e7          	jalr	-1126(ra) # 80001a1a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	de070713          	addi	a4,a4,-544 # 80008c68 <started>
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
    80000ea0:	b7e080e7          	jalr	-1154(ra) # 80001a1a <cpuid>
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
    80000ec2:	d96080e7          	jalr	-618(ra) # 80002c54 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	62a080e7          	jalr	1578(ra) # 800064f0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	364080e7          	jalr	868(ra) # 80002232 <scheduler>
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
    80000f32:	a38080e7          	jalr	-1480(ra) # 80001966 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	cf6080e7          	jalr	-778(ra) # 80002c2c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	d16080e7          	jalr	-746(ra) # 80002c54 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	594080e7          	jalr	1428(ra) # 800064da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	5a2080e7          	jalr	1442(ra) # 800064f0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	73a080e7          	jalr	1850(ra) # 80003690 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	dda080e7          	jalr	-550(ra) # 80003d38 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	d80080e7          	jalr	-640(ra) # 80004ce6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	68a080e7          	jalr	1674(ra) # 800065f8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e2e080e7          	jalr	-466(ra) # 80001da4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	cef72223          	sw	a5,-796(a4) # 80008c68 <started>
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
    80000f9c:	cd87b783          	ld	a5,-808(a5) # 80008c70 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda8b7>
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
    80001232:	6a2080e7          	jalr	1698(ra) # 800018d0 <proc_mapstacks>
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
    80001258:	a0a7be23          	sd	a0,-1508(a5) # 80008c70 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda8c0>
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
  static uint64 z1 = 5234254; // assuming a random seed to generate random numbers
  static uint64 z2 = 1764237; // static to ensure same number is not generated all the time
  static uint64 z3 = 3986790;
  static uint64 z4 = 9823476;
  static uint64 b;
  b = ((z1 << 6) ^ z1) >> 5;
    8000183c:	00007697          	auipc	a3,0x7
    80001840:	1f468693          	addi	a3,a3,500 # 80008a30 <z1.6>
    80001844:	6298                	ld	a4,0(a3)
    80001846:	00671793          	slli	a5,a4,0x6
    8000184a:	8fb9                	xor	a5,a5,a4
    8000184c:	8395                	srli	a5,a5,0x5
  z1 = ((z1 & 75643U) << 13) ^ b;
    8000184e:	0736                	slli	a4,a4,0xd
    80001850:	24ef6637          	lui	a2,0x24ef6
    80001854:	8f71                	and	a4,a4,a2
    80001856:	8fb9                	xor	a5,a5,a4
    80001858:	e29c                	sd	a5,0(a3)
  b = ((z2 << 23) ^ z2) >> 12;
    8000185a:	00007597          	auipc	a1,0x7
    8000185e:	1ce58593          	addi	a1,a1,462 # 80008a28 <z2.4>
    80001862:	6198                	ld	a4,0(a1)
    80001864:	01771613          	slli	a2,a4,0x17
    80001868:	8e39                	xor	a2,a2,a4
    8000186a:	8231                	srli	a2,a2,0xc
  z2 = ((z2 & 873256U) << 17) ^ b;
    8000186c:	0746                	slli	a4,a4,0x11
    8000186e:	1aa656b7          	lui	a3,0x1aa65
    80001872:	06a2                	slli	a3,a3,0x8
    80001874:	8f75                	and	a4,a4,a3
    80001876:	8e39                	xor	a2,a2,a4
    80001878:	e190                	sd	a2,0(a1)
  b = ((z3 << 13) ^ z3) >> 19;
    8000187a:	00007517          	auipc	a0,0x7
    8000187e:	1a650513          	addi	a0,a0,422 # 80008a20 <z3.3>
    80001882:	6118                	ld	a4,0(a0)
    80001884:	00d71693          	slli	a3,a4,0xd
    80001888:	8eb9                	xor	a3,a3,a4
    8000188a:	82cd                	srli	a3,a3,0x13
  z3 = ((z3 & 71549U) << 7) ^ b;
    8000188c:	071e                	slli	a4,a4,0x7
    8000188e:	008bc5b7          	lui	a1,0x8bc
    80001892:	e8058593          	addi	a1,a1,-384 # 8bbe80 <_entry-0x7f744180>
    80001896:	8f6d                	and	a4,a4,a1
    80001898:	8eb9                	xor	a3,a3,a4
    8000189a:	e114                	sd	a3,0(a0)
  b = ((z4 << 3) ^ z4) >> 11;
    8000189c:	00007817          	auipc	a6,0x7
    800018a0:	17c80813          	addi	a6,a6,380 # 80008a18 <z4.2>
    800018a4:	00083583          	ld	a1,0(a6)
    800018a8:	00359713          	slli	a4,a1,0x3
    800018ac:	8f2d                	xor	a4,a4,a1
    800018ae:	832d                	srli	a4,a4,0xb
  z4 = ((z4 & 326565U) << 13) ^ b;
    800018b0:	05b6                	slli	a1,a1,0xd
    800018b2:	4fba5537          	lui	a0,0x4fba5
    800018b6:	0506                	slli	a0,a0,0x1
    800018b8:	8de9                	and	a1,a1,a0
    800018ba:	8f2d                	xor	a4,a4,a1
    800018bc:	00e83023          	sd	a4,0(a6)
  return (z1 ^ z2 ^ z3 ^ z4) / 2;
    800018c0:	00c7c533          	xor	a0,a5,a2
    800018c4:	8d35                	xor	a0,a0,a3
    800018c6:	8d39                	xor	a0,a0,a4
}
    800018c8:	8105                	srli	a0,a0,0x1
    800018ca:	6422                	ld	s0,8(sp)
    800018cc:	0141                	addi	sp,sp,16
    800018ce:	8082                	ret

00000000800018d0 <proc_mapstacks>:

void proc_mapstacks(pagetable_t kpgtbl)
{
    800018d0:	7139                	addi	sp,sp,-64
    800018d2:	fc06                	sd	ra,56(sp)
    800018d4:	f822                	sd	s0,48(sp)
    800018d6:	f426                	sd	s1,40(sp)
    800018d8:	f04a                	sd	s2,32(sp)
    800018da:	ec4e                	sd	s3,24(sp)
    800018dc:	e852                	sd	s4,16(sp)
    800018de:	e456                	sd	s5,8(sp)
    800018e0:	e05a                	sd	s6,0(sp)
    800018e2:	0080                	addi	s0,sp,64
    800018e4:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	a3a48493          	addi	s1,s1,-1478 # 80011320 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018ee:	8b26                	mv	s6,s1
    800018f0:	00006a97          	auipc	s5,0x6
    800018f4:	710a8a93          	addi	s5,s5,1808 # 80008000 <etext>
    800018f8:	04000937          	lui	s2,0x4000
    800018fc:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018fe:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001900:	00017a17          	auipc	s4,0x17
    80001904:	020a0a13          	addi	s4,s4,32 # 80018920 <tickslock>
    char *pa = kalloc();
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	1de080e7          	jalr	478(ra) # 80000ae6 <kalloc>
    80001910:	862a                	mv	a2,a0
    if (pa == 0)
    80001912:	c131                	beqz	a0,80001956 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001914:	416485b3          	sub	a1,s1,s6
    80001918:	858d                	srai	a1,a1,0x3
    8000191a:	000ab783          	ld	a5,0(s5)
    8000191e:	02f585b3          	mul	a1,a1,a5
    80001922:	2585                	addiw	a1,a1,1
    80001924:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001928:	4719                	li	a4,6
    8000192a:	6685                	lui	a3,0x1
    8000192c:	40b905b3          	sub	a1,s2,a1
    80001930:	854e                	mv	a0,s3
    80001932:	00000097          	auipc	ra,0x0
    80001936:	80c080e7          	jalr	-2036(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	1d848493          	addi	s1,s1,472
    8000193e:	fd4495e3          	bne	s1,s4,80001908 <proc_mapstacks+0x38>
  }
}
    80001942:	70e2                	ld	ra,56(sp)
    80001944:	7442                	ld	s0,48(sp)
    80001946:	74a2                	ld	s1,40(sp)
    80001948:	7902                	ld	s2,32(sp)
    8000194a:	69e2                	ld	s3,24(sp)
    8000194c:	6a42                	ld	s4,16(sp)
    8000194e:	6aa2                	ld	s5,8(sp)
    80001950:	6b02                	ld	s6,0(sp)
    80001952:	6121                	addi	sp,sp,64
    80001954:	8082                	ret
      panic("kalloc");
    80001956:	00007517          	auipc	a0,0x7
    8000195a:	88250513          	addi	a0,a0,-1918 # 800081d8 <digits+0x198>
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	be2080e7          	jalr	-1054(ra) # 80000540 <panic>

0000000080001966 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001966:	7139                	addi	sp,sp,-64
    80001968:	fc06                	sd	ra,56(sp)
    8000196a:	f822                	sd	s0,48(sp)
    8000196c:	f426                	sd	s1,40(sp)
    8000196e:	f04a                	sd	s2,32(sp)
    80001970:	ec4e                	sd	s3,24(sp)
    80001972:	e852                	sd	s4,16(sp)
    80001974:	e456                	sd	s5,8(sp)
    80001976:	e05a                	sd	s6,0(sp)
    80001978:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000197a:	00007597          	auipc	a1,0x7
    8000197e:	86658593          	addi	a1,a1,-1946 # 800081e0 <digits+0x1a0>
    80001982:	0000f517          	auipc	a0,0xf
    80001986:	56e50513          	addi	a0,a0,1390 # 80010ef0 <pid_lock>
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	1bc080e7          	jalr	444(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001992:	00007597          	auipc	a1,0x7
    80001996:	85658593          	addi	a1,a1,-1962 # 800081e8 <digits+0x1a8>
    8000199a:	0000f517          	auipc	a0,0xf
    8000199e:	56e50513          	addi	a0,a0,1390 # 80010f08 <wait_lock>
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	1a4080e7          	jalr	420(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019aa:	00010497          	auipc	s1,0x10
    800019ae:	97648493          	addi	s1,s1,-1674 # 80011320 <proc>
  {
    initlock(&p->lock, "proc");
    800019b2:	00007b17          	auipc	s6,0x7
    800019b6:	846b0b13          	addi	s6,s6,-1978 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019ba:	8aa6                	mv	s5,s1
    800019bc:	00006a17          	auipc	s4,0x6
    800019c0:	644a0a13          	addi	s4,s4,1604 # 80008000 <etext>
    800019c4:	04000937          	lui	s2,0x4000
    800019c8:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019ca:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019cc:	00017997          	auipc	s3,0x17
    800019d0:	f5498993          	addi	s3,s3,-172 # 80018920 <tickslock>
    initlock(&p->lock, "proc");
    800019d4:	85da                	mv	a1,s6
    800019d6:	8526                	mv	a0,s1
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	16e080e7          	jalr	366(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    800019e0:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019e4:	415487b3          	sub	a5,s1,s5
    800019e8:	878d                	srai	a5,a5,0x3
    800019ea:	000a3703          	ld	a4,0(s4)
    800019ee:	02e787b3          	mul	a5,a5,a4
    800019f2:	2785                	addiw	a5,a5,1
    800019f4:	00d7979b          	slliw	a5,a5,0xd
    800019f8:	40f907b3          	sub	a5,s2,a5
    800019fc:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019fe:	1d848493          	addi	s1,s1,472
    80001a02:	fd3499e3          	bne	s1,s3,800019d4 <procinit+0x6e>
  }
}
    80001a06:	70e2                	ld	ra,56(sp)
    80001a08:	7442                	ld	s0,48(sp)
    80001a0a:	74a2                	ld	s1,40(sp)
    80001a0c:	7902                	ld	s2,32(sp)
    80001a0e:	69e2                	ld	s3,24(sp)
    80001a10:	6a42                	ld	s4,16(sp)
    80001a12:	6aa2                	ld	s5,8(sp)
    80001a14:	6b02                	ld	s6,0(sp)
    80001a16:	6121                	addi	sp,sp,64
    80001a18:	8082                	ret

0000000080001a1a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e422                	sd	s0,8(sp)
    80001a1e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a20:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a22:	2501                	sext.w	a0,a0
    80001a24:	6422                	ld	s0,8(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret

0000000080001a2a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a2a:	1141                	addi	sp,sp,-16
    80001a2c:	e422                	sd	s0,8(sp)
    80001a2e:	0800                	addi	s0,sp,16
    80001a30:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a32:	2781                	sext.w	a5,a5
    80001a34:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a36:	0000f517          	auipc	a0,0xf
    80001a3a:	4ea50513          	addi	a0,a0,1258 # 80010f20 <cpus>
    80001a3e:	953e                	add	a0,a0,a5
    80001a40:	6422                	ld	s0,8(sp)
    80001a42:	0141                	addi	sp,sp,16
    80001a44:	8082                	ret

0000000080001a46 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	1000                	addi	s0,sp,32
  push_off();
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	13a080e7          	jalr	314(ra) # 80000b8a <push_off>
    80001a58:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a5a:	2781                	sext.w	a5,a5
    80001a5c:	079e                	slli	a5,a5,0x7
    80001a5e:	0000f717          	auipc	a4,0xf
    80001a62:	49270713          	addi	a4,a4,1170 # 80010ef0 <pid_lock>
    80001a66:	97ba                	add	a5,a5,a4
    80001a68:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	1c0080e7          	jalr	448(ra) # 80000c2a <pop_off>
  return p;
}
    80001a72:	8526                	mv	a0,s1
    80001a74:	60e2                	ld	ra,24(sp)
    80001a76:	6442                	ld	s0,16(sp)
    80001a78:	64a2                	ld	s1,8(sp)
    80001a7a:	6105                	addi	sp,sp,32
    80001a7c:	8082                	ret

0000000080001a7e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a7e:	1141                	addi	sp,sp,-16
    80001a80:	e406                	sd	ra,8(sp)
    80001a82:	e022                	sd	s0,0(sp)
    80001a84:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	fc0080e7          	jalr	-64(ra) # 80001a46 <myproc>
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	1fc080e7          	jalr	508(ra) # 80000c8a <release>

  if (first)
    80001a96:	00007797          	auipc	a5,0x7
    80001a9a:	f7a7a783          	lw	a5,-134(a5) # 80008a10 <first.1>
    80001a9e:	eb89                	bnez	a5,80001ab0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aa0:	00001097          	auipc	ra,0x1
    80001aa4:	1cc080e7          	jalr	460(ra) # 80002c6c <usertrapret>
}
    80001aa8:	60a2                	ld	ra,8(sp)
    80001aaa:	6402                	ld	s0,0(sp)
    80001aac:	0141                	addi	sp,sp,16
    80001aae:	8082                	ret
    first = 0;
    80001ab0:	00007797          	auipc	a5,0x7
    80001ab4:	f607a023          	sw	zero,-160(a5) # 80008a10 <first.1>
    fsinit(ROOTDEV);
    80001ab8:	4505                	li	a0,1
    80001aba:	00002097          	auipc	ra,0x2
    80001abe:	1fe080e7          	jalr	510(ra) # 80003cb8 <fsinit>
    80001ac2:	bff9                	j	80001aa0 <forkret+0x22>

0000000080001ac4 <allocpid>:
{
    80001ac4:	1101                	addi	sp,sp,-32
    80001ac6:	ec06                	sd	ra,24(sp)
    80001ac8:	e822                	sd	s0,16(sp)
    80001aca:	e426                	sd	s1,8(sp)
    80001acc:	e04a                	sd	s2,0(sp)
    80001ace:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad0:	0000f917          	auipc	s2,0xf
    80001ad4:	42090913          	addi	s2,s2,1056 # 80010ef0 <pid_lock>
    80001ad8:	854a                	mv	a0,s2
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	0fc080e7          	jalr	252(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001ae2:	00007797          	auipc	a5,0x7
    80001ae6:	f5678793          	addi	a5,a5,-170 # 80008a38 <nextpid>
    80001aea:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aec:	0014871b          	addiw	a4,s1,1
    80001af0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af2:	854a                	mv	a0,s2
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	196080e7          	jalr	406(ra) # 80000c8a <release>
}
    80001afc:	8526                	mv	a0,s1
    80001afe:	60e2                	ld	ra,24(sp)
    80001b00:	6442                	ld	s0,16(sp)
    80001b02:	64a2                	ld	s1,8(sp)
    80001b04:	6902                	ld	s2,0(sp)
    80001b06:	6105                	addi	sp,sp,32
    80001b08:	8082                	ret

0000000080001b0a <proc_pagetable>:
{
    80001b0a:	1101                	addi	sp,sp,-32
    80001b0c:	ec06                	sd	ra,24(sp)
    80001b0e:	e822                	sd	s0,16(sp)
    80001b10:	e426                	sd	s1,8(sp)
    80001b12:	e04a                	sd	s2,0(sp)
    80001b14:	1000                	addi	s0,sp,32
    80001b16:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b18:	00000097          	auipc	ra,0x0
    80001b1c:	810080e7          	jalr	-2032(ra) # 80001328 <uvmcreate>
    80001b20:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b22:	c121                	beqz	a0,80001b62 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b24:	4729                	li	a4,10
    80001b26:	00005697          	auipc	a3,0x5
    80001b2a:	4da68693          	addi	a3,a3,1242 # 80007000 <_trampoline>
    80001b2e:	6605                	lui	a2,0x1
    80001b30:	040005b7          	lui	a1,0x4000
    80001b34:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b36:	05b2                	slli	a1,a1,0xc
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	566080e7          	jalr	1382(ra) # 8000109e <mappages>
    80001b40:	02054863          	bltz	a0,80001b70 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b44:	4719                	li	a4,6
    80001b46:	06093683          	ld	a3,96(s2)
    80001b4a:	6605                	lui	a2,0x1
    80001b4c:	020005b7          	lui	a1,0x2000
    80001b50:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b52:	05b6                	slli	a1,a1,0xd
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	548080e7          	jalr	1352(ra) # 8000109e <mappages>
    80001b5e:	02054163          	bltz	a0,80001b80 <proc_pagetable+0x76>
}
    80001b62:	8526                	mv	a0,s1
    80001b64:	60e2                	ld	ra,24(sp)
    80001b66:	6442                	ld	s0,16(sp)
    80001b68:	64a2                	ld	s1,8(sp)
    80001b6a:	6902                	ld	s2,0(sp)
    80001b6c:	6105                	addi	sp,sp,32
    80001b6e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b70:	4581                	li	a1,0
    80001b72:	8526                	mv	a0,s1
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	9ba080e7          	jalr	-1606(ra) # 8000152e <uvmfree>
    return 0;
    80001b7c:	4481                	li	s1,0
    80001b7e:	b7d5                	j	80001b62 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b80:	4681                	li	a3,0
    80001b82:	4605                	li	a2,1
    80001b84:	040005b7          	lui	a1,0x4000
    80001b88:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b8a:	05b2                	slli	a1,a1,0xc
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	6d6080e7          	jalr	1750(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b96:	4581                	li	a1,0
    80001b98:	8526                	mv	a0,s1
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	994080e7          	jalr	-1644(ra) # 8000152e <uvmfree>
    return 0;
    80001ba2:	4481                	li	s1,0
    80001ba4:	bf7d                	j	80001b62 <proc_pagetable+0x58>

0000000080001ba6 <proc_freepagetable>:
{
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	e04a                	sd	s2,0(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	84aa                	mv	s1,a0
    80001bb4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb6:	4681                	li	a3,0
    80001bb8:	4605                	li	a2,1
    80001bba:	040005b7          	lui	a1,0x4000
    80001bbe:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bc0:	05b2                	slli	a1,a1,0xc
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	6a2080e7          	jalr	1698(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bca:	4681                	li	a3,0
    80001bcc:	4605                	li	a2,1
    80001bce:	020005b7          	lui	a1,0x2000
    80001bd2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd4:	05b6                	slli	a1,a1,0xd
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	68c080e7          	jalr	1676(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001be0:	85ca                	mv	a1,s2
    80001be2:	8526                	mv	a0,s1
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	94a080e7          	jalr	-1718(ra) # 8000152e <uvmfree>
}
    80001bec:	60e2                	ld	ra,24(sp)
    80001bee:	6442                	ld	s0,16(sp)
    80001bf0:	64a2                	ld	s1,8(sp)
    80001bf2:	6902                	ld	s2,0(sp)
    80001bf4:	6105                	addi	sp,sp,32
    80001bf6:	8082                	ret

0000000080001bf8 <freeproc>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	1000                	addi	s0,sp,32
    80001c02:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c04:	7128                	ld	a0,96(a0)
    80001c06:	c509                	beqz	a0,80001c10 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	de0080e7          	jalr	-544(ra) # 800009e8 <kfree>
  if(p->trapframe_copy)
    80001c10:	1d04b503          	ld	a0,464(s1)
    80001c14:	c509                	beqz	a0,80001c1e <freeproc+0x26>
    kfree((void*)p->trapframe_copy);
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	dd2080e7          	jalr	-558(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001c1e:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001c22:	6ca8                	ld	a0,88(s1)
    80001c24:	c511                	beqz	a0,80001c30 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001c26:	64ac                	ld	a1,72(s1)
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	f7e080e7          	jalr	-130(ra) # 80001ba6 <proc_freepagetable>
  p->pagetable = 0;
    80001c30:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c34:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c38:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c3c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c40:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c44:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c48:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c4c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c50:	0004ac23          	sw	zero,24(s1)
  p->strace_bit = 0;
    80001c54:	1604a823          	sw	zero,368(s1)
  p->birth_time = __INT_MAX__;
    80001c58:	800007b7          	lui	a5,0x80000
    80001c5c:	fff7c793          	not	a5,a5
    80001c60:	16f4bc23          	sd	a5,376(s1)
  p->num_tickets = 0;
    80001c64:	1804b023          	sd	zero,384(s1)
  p->static_priority = 0; // for PBS
    80001c68:	18049423          	sh	zero,392(s1)
  p->dynamic_priority = 0;
    80001c6c:	1a049423          	sh	zero,424(s1)
  p->sleep_start = 0;
    80001c70:	1804bc23          	sd	zero,408(s1)
  p->sleep_time = 0;
    80001c74:	1804b823          	sd	zero,400(s1)
  p->running_time = 0;
    80001c78:	1a04b023          	sd	zero,416(s1)
  p->proc_queue = 0;
    80001c7c:	1a049523          	sh	zero,426(s1)
}
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret

0000000080001c8a <allocproc>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	e04a                	sd	s2,0(sp)
    80001c94:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c96:	0000f497          	auipc	s1,0xf
    80001c9a:	68a48493          	addi	s1,s1,1674 # 80011320 <proc>
    80001c9e:	00017917          	auipc	s2,0x17
    80001ca2:	c8290913          	addi	s2,s2,-894 # 80018920 <tickslock>
    acquire(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	f2e080e7          	jalr	-210(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001cb0:	4c9c                	lw	a5,24(s1)
    80001cb2:	cf81                	beqz	a5,80001cca <allocproc+0x40>
      release(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cbe:	1d848493          	addi	s1,s1,472
    80001cc2:	ff2492e3          	bne	s1,s2,80001ca6 <allocproc+0x1c>
  return 0;
    80001cc6:	4481                	li	s1,0
    80001cc8:	a869                	j	80001d62 <allocproc+0xd8>
  p->pid = allocpid();
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	dfa080e7          	jalr	-518(ra) # 80001ac4 <allocpid>
    80001cd2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cd4:	4785                	li	a5,1
    80001cd6:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	e0e080e7          	jalr	-498(ra) # 80000ae6 <kalloc>
    80001ce0:	892a                	mv	s2,a0
    80001ce2:	f0a8                	sd	a0,96(s1)
    80001ce4:	c551                	beqz	a0,80001d70 <allocproc+0xe6>
  if((p->trapframe_copy = (struct trapframe *)kalloc()) == 0){
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	e00080e7          	jalr	-512(ra) # 80000ae6 <kalloc>
    80001cee:	1ca4b823          	sd	a0,464(s1)
    80001cf2:	c55d                	beqz	a0,80001da0 <allocproc+0x116>
  p->alarm_is_set=0;
    80001cf4:	1a049d23          	sh	zero,442(s1)
  p->num_ticks=0;
    80001cf8:	1c04a423          	sw	zero,456(s1)
  p->curr_ticks=0;
    80001cfc:	1a04ae23          	sw	zero,444(s1)
  p->sig_handler=0;
    80001d00:	1c04b023          	sd	zero,448(s1)
  p->pagetable = proc_pagetable(p);
    80001d04:	8526                	mv	a0,s1
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	e04080e7          	jalr	-508(ra) # 80001b0a <proc_pagetable>
    80001d0e:	892a                	mv	s2,a0
    80001d10:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001d12:	c93d                	beqz	a0,80001d88 <allocproc+0xfe>
  memset(&p->context, 0, sizeof(p->context));
    80001d14:	07000613          	li	a2,112
    80001d18:	4581                	li	a1,0
    80001d1a:	06848513          	addi	a0,s1,104
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fb4080e7          	jalr	-76(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d26:	00000797          	auipc	a5,0x0
    80001d2a:	d5878793          	addi	a5,a5,-680 # 80001a7e <forkret>
    80001d2e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d30:	60bc                	ld	a5,64(s1)
    80001d32:	6705                	lui	a4,0x1
    80001d34:	97ba                	add	a5,a5,a4
    80001d36:	f8bc                	sd	a5,112(s1)
  p->birth_time = sys_uptime(); // sys_uptime - gives number of ticks since start
    80001d38:	00001097          	auipc	ra,0x1
    80001d3c:	7d4080e7          	jalr	2004(ra) # 8000350c <sys_uptime>
    80001d40:	16a4bc23          	sd	a0,376(s1)
  p->num_tickets = 1;           // # tickets = 1 by default for every process
    80001d44:	4785                	li	a5,1
    80001d46:	18f4b023          	sd	a5,384(s1)
  p->static_priority = 60;      // priority = 60 by default
    80001d4a:	03c00793          	li	a5,60
    80001d4e:	18f49423          	sh	a5,392(s1)
  p->sleep_start = 0;
    80001d52:	1804bc23          	sd	zero,408(s1)
  p->sleep_time = 0;
    80001d56:	1804b823          	sd	zero,400(s1)
  p->running_time = 0;
    80001d5a:	1a04b023          	sd	zero,416(s1)
  p->proc_queue = 0;
    80001d5e:	1a049523          	sh	zero,426(s1)
}
    80001d62:	8526                	mv	a0,s1
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6902                	ld	s2,0(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret
    freeproc(p);
    80001d70:	8526                	mv	a0,s1
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	e86080e7          	jalr	-378(ra) # 80001bf8 <freeproc>
    release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f0e080e7          	jalr	-242(ra) # 80000c8a <release>
    return 0;
    80001d84:	84ca                	mv	s1,s2
    80001d86:	bff1                	j	80001d62 <allocproc+0xd8>
    freeproc(p);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	e6e080e7          	jalr	-402(ra) # 80001bf8 <freeproc>
    release(&p->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	ef6080e7          	jalr	-266(ra) # 80000c8a <release>
    return 0;
    80001d9c:	84ca                	mv	s1,s2
    80001d9e:	b7d1                	j	80001d62 <allocproc+0xd8>
    return 0;
    80001da0:	84aa                	mv	s1,a0
    80001da2:	b7c1                	j	80001d62 <allocproc+0xd8>

0000000080001da4 <userinit>:
{
    80001da4:	1101                	addi	sp,sp,-32
    80001da6:	ec06                	sd	ra,24(sp)
    80001da8:	e822                	sd	s0,16(sp)
    80001daa:	e426                	sd	s1,8(sp)
    80001dac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	edc080e7          	jalr	-292(ra) # 80001c8a <allocproc>
    80001db6:	84aa                	mv	s1,a0
  initproc = p;
    80001db8:	00007797          	auipc	a5,0x7
    80001dbc:	eca7b023          	sd	a0,-320(a5) # 80008c78 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dc0:	03400613          	li	a2,52
    80001dc4:	00007597          	auipc	a1,0x7
    80001dc8:	c7c58593          	addi	a1,a1,-900 # 80008a40 <initcode>
    80001dcc:	6d28                	ld	a0,88(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	588080e7          	jalr	1416(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001dd6:	6785                	lui	a5,0x1
    80001dd8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dda:	70b8                	ld	a4,96(s1)
    80001ddc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001de0:	70b8                	ld	a4,96(s1)
    80001de2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de4:	4641                	li	a2,16
    80001de6:	00006597          	auipc	a1,0x6
    80001dea:	41a58593          	addi	a1,a1,1050 # 80008200 <digits+0x1c0>
    80001dee:	16048513          	addi	a0,s1,352
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	02a080e7          	jalr	42(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001dfa:	00006517          	auipc	a0,0x6
    80001dfe:	41650513          	addi	a0,a0,1046 # 80008210 <digits+0x1d0>
    80001e02:	00003097          	auipc	ra,0x3
    80001e06:	8e0080e7          	jalr	-1824(ra) # 800046e2 <namei>
    80001e0a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e0e:	478d                	li	a5,3
    80001e10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e12:	8526                	mv	a0,s1
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	e76080e7          	jalr	-394(ra) # 80000c8a <release>
}
    80001e1c:	60e2                	ld	ra,24(sp)
    80001e1e:	6442                	ld	s0,16(sp)
    80001e20:	64a2                	ld	s1,8(sp)
    80001e22:	6105                	addi	sp,sp,32
    80001e24:	8082                	ret

0000000080001e26 <growproc>:
{
    80001e26:	1101                	addi	sp,sp,-32
    80001e28:	ec06                	sd	ra,24(sp)
    80001e2a:	e822                	sd	s0,16(sp)
    80001e2c:	e426                	sd	s1,8(sp)
    80001e2e:	e04a                	sd	s2,0(sp)
    80001e30:	1000                	addi	s0,sp,32
    80001e32:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	c12080e7          	jalr	-1006(ra) # 80001a46 <myproc>
    80001e3c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e3e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e40:	01204c63          	bgtz	s2,80001e58 <growproc+0x32>
  else if (n < 0)
    80001e44:	02094663          	bltz	s2,80001e70 <growproc+0x4a>
  p->sz = sz;
    80001e48:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e4a:	4501                	li	a0,0
}
    80001e4c:	60e2                	ld	ra,24(sp)
    80001e4e:	6442                	ld	s0,16(sp)
    80001e50:	64a2                	ld	s1,8(sp)
    80001e52:	6902                	ld	s2,0(sp)
    80001e54:	6105                	addi	sp,sp,32
    80001e56:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e58:	4691                	li	a3,4
    80001e5a:	00b90633          	add	a2,s2,a1
    80001e5e:	6d28                	ld	a0,88(a0)
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	5b0080e7          	jalr	1456(ra) # 80001410 <uvmalloc>
    80001e68:	85aa                	mv	a1,a0
    80001e6a:	fd79                	bnez	a0,80001e48 <growproc+0x22>
      return -1;
    80001e6c:	557d                	li	a0,-1
    80001e6e:	bff9                	j	80001e4c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e70:	00b90633          	add	a2,s2,a1
    80001e74:	6d28                	ld	a0,88(a0)
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	552080e7          	jalr	1362(ra) # 800013c8 <uvmdealloc>
    80001e7e:	85aa                	mv	a1,a0
    80001e80:	b7e1                	j	80001e48 <growproc+0x22>

0000000080001e82 <fork>:
{
    80001e82:	7139                	addi	sp,sp,-64
    80001e84:	fc06                	sd	ra,56(sp)
    80001e86:	f822                	sd	s0,48(sp)
    80001e88:	f426                	sd	s1,40(sp)
    80001e8a:	f04a                	sd	s2,32(sp)
    80001e8c:	ec4e                	sd	s3,24(sp)
    80001e8e:	e852                	sd	s4,16(sp)
    80001e90:	e456                	sd	s5,8(sp)
    80001e92:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	bb2080e7          	jalr	-1102(ra) # 80001a46 <myproc>
    80001e9c:	8a2a                	mv	s4,a0
  if ((np = allocproc()) == 0)
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	dec080e7          	jalr	-532(ra) # 80001c8a <allocproc>
    80001ea6:	14050463          	beqz	a0,80001fee <fork+0x16c>
    80001eaa:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001eac:	048a3603          	ld	a2,72(s4)
    80001eb0:	6d2c                	ld	a1,88(a0)
    80001eb2:	058a3503          	ld	a0,88(s4)
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	6b2080e7          	jalr	1714(ra) # 80001568 <uvmcopy>
    80001ebe:	04054863          	bltz	a0,80001f0e <fork+0x8c>
  np->sz = p->sz;
    80001ec2:	048a3783          	ld	a5,72(s4)
    80001ec6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001eca:	060a3683          	ld	a3,96(s4)
    80001ece:	87b6                	mv	a5,a3
    80001ed0:	0609b703          	ld	a4,96(s3)
    80001ed4:	12068693          	addi	a3,a3,288
    80001ed8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001edc:	6788                	ld	a0,8(a5)
    80001ede:	6b8c                	ld	a1,16(a5)
    80001ee0:	6f90                	ld	a2,24(a5)
    80001ee2:	01073023          	sd	a6,0(a4)
    80001ee6:	e708                	sd	a0,8(a4)
    80001ee8:	eb0c                	sd	a1,16(a4)
    80001eea:	ef10                	sd	a2,24(a4)
    80001eec:	02078793          	addi	a5,a5,32
    80001ef0:	02070713          	addi	a4,a4,32
    80001ef4:	fed792e3          	bne	a5,a3,80001ed8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ef8:	0609b783          	ld	a5,96(s3)
    80001efc:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f00:	0d8a0493          	addi	s1,s4,216
    80001f04:	0d898913          	addi	s2,s3,216
    80001f08:	158a0a93          	addi	s5,s4,344
    80001f0c:	a00d                	j	80001f2e <fork+0xac>
    freeproc(np);
    80001f0e:	854e                	mv	a0,s3
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	ce8080e7          	jalr	-792(ra) # 80001bf8 <freeproc>
    release(&np->lock);
    80001f18:	854e                	mv	a0,s3
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
    return -1;
    80001f22:	597d                	li	s2,-1
    80001f24:	a85d                	j	80001fda <fork+0x158>
  for (i = 0; i < NOFILE; i++)
    80001f26:	04a1                	addi	s1,s1,8
    80001f28:	0921                	addi	s2,s2,8
    80001f2a:	01548b63          	beq	s1,s5,80001f40 <fork+0xbe>
    if (p->ofile[i])
    80001f2e:	6088                	ld	a0,0(s1)
    80001f30:	d97d                	beqz	a0,80001f26 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f32:	00003097          	auipc	ra,0x3
    80001f36:	e46080e7          	jalr	-442(ra) # 80004d78 <filedup>
    80001f3a:	00a93023          	sd	a0,0(s2)
    80001f3e:	b7e5                	j	80001f26 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f40:	158a3503          	ld	a0,344(s4)
    80001f44:	00002097          	auipc	ra,0x2
    80001f48:	fb4080e7          	jalr	-76(ra) # 80003ef8 <idup>
    80001f4c:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f50:	4641                	li	a2,16
    80001f52:	160a0593          	addi	a1,s4,352
    80001f56:	16098513          	addi	a0,s3,352
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	ec2080e7          	jalr	-318(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f62:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f66:	854e                	mv	a0,s3
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d22080e7          	jalr	-734(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001f70:	0000f497          	auipc	s1,0xf
    80001f74:	f9848493          	addi	s1,s1,-104 # 80010f08 <wait_lock>
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	c5c080e7          	jalr	-932(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f82:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d02080e7          	jalr	-766(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f90:	854e                	mv	a0,s3
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	c44080e7          	jalr	-956(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f9a:	478d                	li	a5,3
    80001f9c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fa0:	854e                	mv	a0,s3
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	ce8080e7          	jalr	-792(ra) # 80000c8a <release>
  np->strace_bit = p->strace_bit;
    80001faa:	170a2783          	lw	a5,368(s4)
    80001fae:	16f9a823          	sw	a5,368(s3)
  np->birth_time = p->birth_time;           // check if this and equalities below this are required
    80001fb2:	178a3783          	ld	a5,376(s4)
    80001fb6:	16f9bc23          	sd	a5,376(s3)
  np->static_priority = p->static_priority; // check if this is required
    80001fba:	188a5783          	lhu	a5,392(s4)
    80001fbe:	18f99423          	sh	a5,392(s3)
  np->dynamic_priority = p->dynamic_priority;
    80001fc2:	1a8a5783          	lhu	a5,424(s4)
    80001fc6:	1af99423          	sh	a5,424(s3)
  np->sleep_time = p->sleep_time;
    80001fca:	190a3783          	ld	a5,400(s4)
    80001fce:	18f9b823          	sd	a5,400(s3)
  np->running_time = p->running_time;
    80001fd2:	1a0a3783          	ld	a5,416(s4)
    80001fd6:	1af9b023          	sd	a5,416(s3)
}
    80001fda:	854a                	mv	a0,s2
    80001fdc:	70e2                	ld	ra,56(sp)
    80001fde:	7442                	ld	s0,48(sp)
    80001fe0:	74a2                	ld	s1,40(sp)
    80001fe2:	7902                	ld	s2,32(sp)
    80001fe4:	69e2                	ld	s3,24(sp)
    80001fe6:	6a42                	ld	s4,16(sp)
    80001fe8:	6aa2                	ld	s5,8(sp)
    80001fea:	6121                	addi	sp,sp,64
    80001fec:	8082                	ret
    return -1;
    80001fee:	597d                	li	s2,-1
    80001ff0:	b7ed                	j	80001fda <fork+0x158>

0000000080001ff2 <roundRobin>:
{
    80001ff2:	7139                	addi	sp,sp,-64
    80001ff4:	fc06                	sd	ra,56(sp)
    80001ff6:	f822                	sd	s0,48(sp)
    80001ff8:	f426                	sd	s1,40(sp)
    80001ffa:	f04a                	sd	s2,32(sp)
    80001ffc:	ec4e                	sd	s3,24(sp)
    80001ffe:	e852                	sd	s4,16(sp)
    80002000:	e456                	sd	s5,8(sp)
    80002002:	e05a                	sd	s6,0(sp)
    80002004:	0080                	addi	s0,sp,64
    80002006:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    80002008:	0000f497          	auipc	s1,0xf
    8000200c:	31848493          	addi	s1,s1,792 # 80011320 <proc>
    if (p->state == RUNNABLE)
    80002010:	498d                	li	s3,3
      p->state = RUNNING;
    80002012:	4b11                	li	s6,4
      swtch(&c->context, &p->context);
    80002014:	00850a93          	addi	s5,a0,8
  for (p = proc; p < &proc[NPROC]; p++)
    80002018:	00017917          	auipc	s2,0x17
    8000201c:	90890913          	addi	s2,s2,-1784 # 80018920 <tickslock>
    80002020:	a811                	j	80002034 <roundRobin+0x42>
    release(&p->lock);
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c66080e7          	jalr	-922(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000202c:	1d848493          	addi	s1,s1,472
    80002030:	03248863          	beq	s1,s2,80002060 <roundRobin+0x6e>
    acquire(&p->lock);
    80002034:	8526                	mv	a0,s1
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	ba0080e7          	jalr	-1120(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE)
    8000203e:	4c9c                	lw	a5,24(s1)
    80002040:	ff3791e3          	bne	a5,s3,80002022 <roundRobin+0x30>
      p->state = RUNNING;
    80002044:	0164ac23          	sw	s6,24(s1)
      c->proc = p;
    80002048:	009a3023          	sd	s1,0(s4)
      swtch(&c->context, &p->context);
    8000204c:	06848593          	addi	a1,s1,104
    80002050:	8556                	mv	a0,s5
    80002052:	00001097          	auipc	ra,0x1
    80002056:	b70080e7          	jalr	-1168(ra) # 80002bc2 <swtch>
      c->proc = 0;
    8000205a:	000a3023          	sd	zero,0(s4)
    8000205e:	b7d1                	j	80002022 <roundRobin+0x30>
}
    80002060:	70e2                	ld	ra,56(sp)
    80002062:	7442                	ld	s0,48(sp)
    80002064:	74a2                	ld	s1,40(sp)
    80002066:	7902                	ld	s2,32(sp)
    80002068:	69e2                	ld	s3,24(sp)
    8000206a:	6a42                	ld	s4,16(sp)
    8000206c:	6aa2                	ld	s5,8(sp)
    8000206e:	6b02                	ld	s6,0(sp)
    80002070:	6121                	addi	sp,sp,64
    80002072:	8082                	ret

0000000080002074 <fcfs>:
{
    80002074:	7139                	addi	sp,sp,-64
    80002076:	fc06                	sd	ra,56(sp)
    80002078:	f822                	sd	s0,48(sp)
    8000207a:	f426                	sd	s1,40(sp)
    8000207c:	f04a                	sd	s2,32(sp)
    8000207e:	ec4e                	sd	s3,24(sp)
    80002080:	e852                	sd	s4,16(sp)
    80002082:	e456                	sd	s5,8(sp)
    80002084:	e05a                	sd	s6,0(sp)
    80002086:	0080                	addi	s0,sp,64
    80002088:	8b2a                	mv	s6,a0
  for (int i = 0; i < NPROC; i++)
    8000208a:	0000f497          	auipc	s1,0xf
    8000208e:	29648493          	addi	s1,s1,662 # 80011320 <proc>
    80002092:	00017a17          	auipc	s4,0x17
    80002096:	88ea0a13          	addi	s4,s4,-1906 # 80018920 <tickslock>
  struct proc *oldestproc = 0;
    8000209a:	4981                	li	s3,0
      if (p->state == RUNNABLE)
    8000209c:	4a8d                	li	s5,3
    8000209e:	a0ad                	j	80002108 <fcfs+0x94>
  if (!oldestproc) // change state of the newly selected process
    800020a0:	00098763          	beqz	s3,800020ae <fcfs+0x3a>
  if (oldestproc->state == RUNNABLE)
    800020a4:	0189a703          	lw	a4,24(s3)
    800020a8:	478d                	li	a5,3
    800020aa:	00f70c63          	beq	a4,a5,800020c2 <fcfs+0x4e>
}
    800020ae:	70e2                	ld	ra,56(sp)
    800020b0:	7442                	ld	s0,48(sp)
    800020b2:	74a2                	ld	s1,40(sp)
    800020b4:	7902                	ld	s2,32(sp)
    800020b6:	69e2                	ld	s3,24(sp)
    800020b8:	6a42                	ld	s4,16(sp)
    800020ba:	6aa2                	ld	s5,8(sp)
    800020bc:	6b02                	ld	s6,0(sp)
    800020be:	6121                	addi	sp,sp,64
    800020c0:	8082                	ret
    oldestproc->state = RUNNING;
    800020c2:	4791                	li	a5,4
    800020c4:	00f9ac23          	sw	a5,24(s3)
    c->proc = oldestproc;
    800020c8:	013b3023          	sd	s3,0(s6)
    swtch(&c->context, &oldestproc->context);
    800020cc:	06898593          	addi	a1,s3,104
    800020d0:	008b0513          	addi	a0,s6,8
    800020d4:	00001097          	auipc	ra,0x1
    800020d8:	aee080e7          	jalr	-1298(ra) # 80002bc2 <swtch>
    c->proc = 0;
    800020dc:	000b3023          	sd	zero,0(s6)
    release(&oldestproc->lock);
    800020e0:	854e                	mv	a0,s3
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ba8080e7          	jalr	-1112(ra) # 80000c8a <release>
    800020ea:	b7d1                	j	800020ae <fcfs+0x3a>
      if (p->state == RUNNABLE)
    800020ec:	4c9c                	lw	a5,24(s1)
    800020ee:	05578363          	beq	a5,s5,80002134 <fcfs+0xc0>
    if (oldestproc != p) // if the selected proc is not the last proc, release last proc
    800020f2:	01390763          	beq	s2,s3,80002100 <fcfs+0x8c>
      release(&p->lock);
    800020f6:	854a                	mv	a0,s2
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    80002100:	1d848493          	addi	s1,s1,472
    80002104:	f9448ee3          	beq	s1,s4,800020a0 <fcfs+0x2c>
    struct proc *p = &proc[i];
    80002108:	8926                	mv	s2,s1
    acquire(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	aca080e7          	jalr	-1334(ra) # 80000bd6 <acquire>
    if (oldestproc)
    80002114:	fc098ce3          	beqz	s3,800020ec <fcfs+0x78>
    if ((oldesttime > p->birth_time) || !oldestproc)
    80002118:	1784b703          	ld	a4,376(s1)
    8000211c:	1789b783          	ld	a5,376(s3)
    80002120:	fcf779e3          	bgeu	a4,a5,800020f2 <fcfs+0x7e>
      if (p->state == RUNNABLE)
    80002124:	4c9c                	lw	a5,24(s1)
    80002126:	fd5796e3          	bne	a5,s5,800020f2 <fcfs+0x7e>
          release(&oldestproc->lock); // release the prev selected proc, and lock newly selected proc
    8000212a:	854e                	mv	a0,s3
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b5e080e7          	jalr	-1186(ra) # 80000c8a <release>
  struct proc *oldestproc = 0;
    80002134:	89ca                	mv	s3,s2
    80002136:	b7e9                	j	80002100 <fcfs+0x8c>

0000000080002138 <lotteryBased>:
{
    80002138:	715d                	addi	sp,sp,-80
    8000213a:	e486                	sd	ra,72(sp)
    8000213c:	e0a2                	sd	s0,64(sp)
    8000213e:	fc26                	sd	s1,56(sp)
    80002140:	f84a                	sd	s2,48(sp)
    80002142:	f44e                	sd	s3,40(sp)
    80002144:	f052                	sd	s4,32(sp)
    80002146:	ec56                	sd	s5,24(sp)
    80002148:	e85a                	sd	s6,16(sp)
    8000214a:	e45e                	sd	s7,8(sp)
    8000214c:	e062                	sd	s8,0(sp)
    8000214e:	0880                	addi	s0,sp,80
    80002150:	8baa                	mv	s7,a0
  for (int i = 0; i < NPROC; i++)
    80002152:	0000f997          	auipc	s3,0xf
    80002156:	1ce98993          	addi	s3,s3,462 # 80011320 <proc>
    8000215a:	00016a17          	auipc	s4,0x16
    8000215e:	7c6a0a13          	addi	s4,s4,1990 # 80018920 <tickslock>
{
    80002162:	84ce                	mv	s1,s3
  uint64 totalNumTickets = 0, ticketCnt = 0;
    80002164:	4c01                	li	s8,0
    if (p->state == RUNNABLE)
    80002166:	4a8d                	li	s5,3
    80002168:	a811                	j	8000217c <lotteryBased+0x44>
    release(&p->lock);
    8000216a:	854a                	mv	a0,s2
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b1e080e7          	jalr	-1250(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    80002174:	1d848493          	addi	s1,s1,472
    80002178:	01448f63          	beq	s1,s4,80002196 <lotteryBased+0x5e>
    acquire(&p->lock);
    8000217c:	8926                	mv	s2,s1
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a56080e7          	jalr	-1450(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE)
    80002188:	4c9c                	lw	a5,24(s1)
    8000218a:	ff5790e3          	bne	a5,s5,8000216a <lotteryBased+0x32>
      totalNumTickets += p->num_tickets;
    8000218e:	1804b783          	ld	a5,384(s1)
    80002192:	9c3e                	add	s8,s8,a5
    80002194:	bfd9                	j	8000216a <lotteryBased+0x32>
  uint64 randNum = random() % totalNumTickets;
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	6a0080e7          	jalr	1696(ra) # 80001836 <random>
    8000219e:	03857c33          	remu	s8,a0,s8
  struct proc *chosenproc = 0;
    800021a2:	4a81                	li	s5,0
  uint64 totalNumTickets = 0, ticketCnt = 0;
    800021a4:	4901                	li	s2,0
    if (p->state != RUNNABLE)
    800021a6:	4b0d                	li	s6,3
    800021a8:	a00d                	j	800021ca <lotteryBased+0x92>
      release(&p->lock);
    800021aa:	854e                	mv	a0,s3
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	ade080e7          	jalr	-1314(ra) # 80000c8a <release>
      continue;
    800021b4:	a039                	j	800021c2 <lotteryBased+0x8a>
    ticketCnt += p->num_tickets;
    800021b6:	1804b783          	ld	a5,384(s1)
    800021ba:	993e                	add	s2,s2,a5
    if (ticketCnt >= randNum)
    800021bc:	03897c63          	bgeu	s2,s8,800021f4 <lotteryBased+0xbc>
    struct proc *p = &proc[i];
    800021c0:	8aa6                	mv	s5,s1
  for (int i = 0; i < NPROC; i++)
    800021c2:	1d898993          	addi	s3,s3,472
    800021c6:	03498463          	beq	s3,s4,800021ee <lotteryBased+0xb6>
    struct proc *p = &proc[i];
    800021ca:	84ce                	mv	s1,s3
    acquire(&p->lock);
    800021cc:	854e                	mv	a0,s3
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a08080e7          	jalr	-1528(ra) # 80000bd6 <acquire>
    if (p->state != RUNNABLE)
    800021d6:	0189a783          	lw	a5,24(s3)
    800021da:	fd6798e3          	bne	a5,s6,800021aa <lotteryBased+0x72>
    if (chosenproc)
    800021de:	fc0a8ce3          	beqz	s5,800021b6 <lotteryBased+0x7e>
      release(&chosenproc->lock);
    800021e2:	8556                	mv	a0,s5
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
    800021ec:	b7e9                	j	800021b6 <lotteryBased+0x7e>
  if (chosenproc)
    800021ee:	020a8663          	beqz	s5,8000221a <lotteryBased+0xe2>
    800021f2:	84d6                	mv	s1,s5
    chosenproc->state = RUNNING;
    800021f4:	4791                	li	a5,4
    800021f6:	cc9c                	sw	a5,24(s1)
    c->proc = chosenproc;
    800021f8:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffda8c0>
    swtch(&c->context, &chosenproc->context);
    800021fc:	06848593          	addi	a1,s1,104
    80002200:	008b8513          	addi	a0,s7,8
    80002204:	00001097          	auipc	ra,0x1
    80002208:	9be080e7          	jalr	-1602(ra) # 80002bc2 <swtch>
    c->proc = 0;
    8000220c:	000bb023          	sd	zero,0(s7)
    release(&chosenproc->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a78080e7          	jalr	-1416(ra) # 80000c8a <release>
}
    8000221a:	60a6                	ld	ra,72(sp)
    8000221c:	6406                	ld	s0,64(sp)
    8000221e:	74e2                	ld	s1,56(sp)
    80002220:	7942                	ld	s2,48(sp)
    80002222:	79a2                	ld	s3,40(sp)
    80002224:	7a02                	ld	s4,32(sp)
    80002226:	6ae2                	ld	s5,24(sp)
    80002228:	6b42                	ld	s6,16(sp)
    8000222a:	6ba2                	ld	s7,8(sp)
    8000222c:	6c02                	ld	s8,0(sp)
    8000222e:	6161                	addi	sp,sp,80
    80002230:	8082                	ret

0000000080002232 <scheduler>:
{
    80002232:	1101                	addi	sp,sp,-32
    80002234:	ec06                	sd	ra,24(sp)
    80002236:	e822                	sd	s0,16(sp)
    80002238:	e426                	sd	s1,8(sp)
    8000223a:	1000                	addi	s0,sp,32
    8000223c:	8792                	mv	a5,tp
  int id = r_tp();
    8000223e:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    80002240:	079e                	slli	a5,a5,0x7
    80002242:	0000f497          	auipc	s1,0xf
    80002246:	cde48493          	addi	s1,s1,-802 # 80010f20 <cpus>
    8000224a:	94be                	add	s1,s1,a5
  c->proc = 0;
    8000224c:	0000f717          	auipc	a4,0xf
    80002250:	ca470713          	addi	a4,a4,-860 # 80010ef0 <pid_lock>
    80002254:	97ba                	add	a5,a5,a4
    80002256:	0207b823          	sd	zero,48(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000225a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000225e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002262:	10079073          	csrw	sstatus,a5
    roundRobin(c);
    80002266:	8526                	mv	a0,s1
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	d8a080e7          	jalr	-630(ra) # 80001ff2 <roundRobin>
  for (;;)
    80002270:	b7ed                	j	8000225a <scheduler+0x28>

0000000080002272 <sched>:
{
    80002272:	7179                	addi	sp,sp,-48
    80002274:	f406                	sd	ra,40(sp)
    80002276:	f022                	sd	s0,32(sp)
    80002278:	ec26                	sd	s1,24(sp)
    8000227a:	e84a                	sd	s2,16(sp)
    8000227c:	e44e                	sd	s3,8(sp)
    8000227e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	7c6080e7          	jalr	1990(ra) # 80001a46 <myproc>
    80002288:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	8d2080e7          	jalr	-1838(ra) # 80000b5c <holding>
    80002292:	c93d                	beqz	a0,80002308 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002294:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002296:	2781                	sext.w	a5,a5
    80002298:	079e                	slli	a5,a5,0x7
    8000229a:	0000f717          	auipc	a4,0xf
    8000229e:	c5670713          	addi	a4,a4,-938 # 80010ef0 <pid_lock>
    800022a2:	97ba                	add	a5,a5,a4
    800022a4:	0a87a703          	lw	a4,168(a5)
    800022a8:	4785                	li	a5,1
    800022aa:	06f71763          	bne	a4,a5,80002318 <sched+0xa6>
  if (p->state == RUNNING)
    800022ae:	4c98                	lw	a4,24(s1)
    800022b0:	4791                	li	a5,4
    800022b2:	06f70b63          	beq	a4,a5,80002328 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ba:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022bc:	efb5                	bnez	a5,80002338 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022be:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022c0:	0000f917          	auipc	s2,0xf
    800022c4:	c3090913          	addi	s2,s2,-976 # 80010ef0 <pid_lock>
    800022c8:	2781                	sext.w	a5,a5
    800022ca:	079e                	slli	a5,a5,0x7
    800022cc:	97ca                	add	a5,a5,s2
    800022ce:	0ac7a983          	lw	s3,172(a5)
    800022d2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d4:	2781                	sext.w	a5,a5
    800022d6:	079e                	slli	a5,a5,0x7
    800022d8:	0000f597          	auipc	a1,0xf
    800022dc:	c5058593          	addi	a1,a1,-944 # 80010f28 <cpus+0x8>
    800022e0:	95be                	add	a1,a1,a5
    800022e2:	06848513          	addi	a0,s1,104
    800022e6:	00001097          	auipc	ra,0x1
    800022ea:	8dc080e7          	jalr	-1828(ra) # 80002bc2 <swtch>
    800022ee:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022f0:	2781                	sext.w	a5,a5
    800022f2:	079e                	slli	a5,a5,0x7
    800022f4:	993e                	add	s2,s2,a5
    800022f6:	0b392623          	sw	s3,172(s2)
}
    800022fa:	70a2                	ld	ra,40(sp)
    800022fc:	7402                	ld	s0,32(sp)
    800022fe:	64e2                	ld	s1,24(sp)
    80002300:	6942                	ld	s2,16(sp)
    80002302:	69a2                	ld	s3,8(sp)
    80002304:	6145                	addi	sp,sp,48
    80002306:	8082                	ret
    panic("sched p->lock");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f1050513          	addi	a0,a0,-240 # 80008218 <digits+0x1d8>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	230080e7          	jalr	560(ra) # 80000540 <panic>
    panic("sched locks");
    80002318:	00006517          	auipc	a0,0x6
    8000231c:	f1050513          	addi	a0,a0,-240 # 80008228 <digits+0x1e8>
    80002320:	ffffe097          	auipc	ra,0xffffe
    80002324:	220080e7          	jalr	544(ra) # 80000540 <panic>
    panic("sched running");
    80002328:	00006517          	auipc	a0,0x6
    8000232c:	f1050513          	addi	a0,a0,-240 # 80008238 <digits+0x1f8>
    80002330:	ffffe097          	auipc	ra,0xffffe
    80002334:	210080e7          	jalr	528(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002338:	00006517          	auipc	a0,0x6
    8000233c:	f1050513          	addi	a0,a0,-240 # 80008248 <digits+0x208>
    80002340:	ffffe097          	auipc	ra,0xffffe
    80002344:	200080e7          	jalr	512(ra) # 80000540 <panic>

0000000080002348 <yield>:
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	6f4080e7          	jalr	1780(ra) # 80001a46 <myproc>
    8000235a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	87a080e7          	jalr	-1926(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002364:	478d                	li	a5,3
    80002366:	cc9c                	sw	a5,24(s1)
  sched();
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	f0a080e7          	jalr	-246(ra) # 80002272 <sched>
  release(&p->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	918080e7          	jalr	-1768(ra) # 80000c8a <release>
}
    8000237a:	60e2                	ld	ra,24(sp)
    8000237c:	6442                	ld	s0,16(sp)
    8000237e:	64a2                	ld	s1,8(sp)
    80002380:	6105                	addi	sp,sp,32
    80002382:	8082                	ret

0000000080002384 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002384:	7179                	addi	sp,sp,-48
    80002386:	f406                	sd	ra,40(sp)
    80002388:	f022                	sd	s0,32(sp)
    8000238a:	ec26                	sd	s1,24(sp)
    8000238c:	e84a                	sd	s2,16(sp)
    8000238e:	e44e                	sd	s3,8(sp)
    80002390:	1800                	addi	s0,sp,48
    80002392:	89aa                	mv	s3,a0
    80002394:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	6b0080e7          	jalr	1712(ra) # 80001a46 <myproc>
    8000239e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	836080e7          	jalr	-1994(ra) # 80000bd6 <acquire>
  release(lk);
    800023a8:	854a                	mv	a0,s2
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8e0080e7          	jalr	-1824(ra) # 80000c8a <release>

  if (p->state != SLEEPING)        // added for PBS
    800023b2:	4c98                	lw	a4,24(s1)
    800023b4:	4789                	li	a5,2
    800023b6:	02f71d63          	bne	a4,a5,800023f0 <sleep+0x6c>
    p->sleep_start = sys_uptime(); // added for PBS

  // Go to sleep.
  p->chan = chan;
    800023ba:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023be:	4789                	li	a5,2
    800023c0:	cc9c                	sw	a5,24(s1)

  sched();
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	eb0080e7          	jalr	-336(ra) # 80002272 <sched>

  // Tidy up.
  p->chan = 0;
    800023ca:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
  acquire(lk);
    800023d8:	854a                	mv	a0,s2
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	7fc080e7          	jalr	2044(ra) # 80000bd6 <acquire>
}
    800023e2:	70a2                	ld	ra,40(sp)
    800023e4:	7402                	ld	s0,32(sp)
    800023e6:	64e2                	ld	s1,24(sp)
    800023e8:	6942                	ld	s2,16(sp)
    800023ea:	69a2                	ld	s3,8(sp)
    800023ec:	6145                	addi	sp,sp,48
    800023ee:	8082                	ret
    p->sleep_start = sys_uptime(); // added for PBS
    800023f0:	00001097          	auipc	ra,0x1
    800023f4:	11c080e7          	jalr	284(ra) # 8000350c <sys_uptime>
    800023f8:	18a4bc23          	sd	a0,408(s1)
    800023fc:	bf7d                	j	800023ba <sleep+0x36>

00000000800023fe <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023fe:	7139                	addi	sp,sp,-64
    80002400:	fc06                	sd	ra,56(sp)
    80002402:	f822                	sd	s0,48(sp)
    80002404:	f426                	sd	s1,40(sp)
    80002406:	f04a                	sd	s2,32(sp)
    80002408:	ec4e                	sd	s3,24(sp)
    8000240a:	e852                	sd	s4,16(sp)
    8000240c:	e456                	sd	s5,8(sp)
    8000240e:	0080                	addi	s0,sp,64
    80002410:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002412:	0000f497          	auipc	s1,0xf
    80002416:	f0e48493          	addi	s1,s1,-242 # 80011320 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000241a:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000241c:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000241e:	00016917          	auipc	s2,0x16
    80002422:	50290913          	addi	s2,s2,1282 # 80018920 <tickslock>
    80002426:	a821                	j	8000243e <wakeup+0x40>

        if (p->sleep_start != 0)                         // added for PBS
          p->sleep_time = sys_uptime() - p->sleep_start; // added for PBS
        p->sleep_start = 0;                              // added for PBS
    80002428:	1804bc23          	sd	zero,408(s1)
      }
      release(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002436:	1d848493          	addi	s1,s1,472
    8000243a:	05248263          	beq	s1,s2,8000247e <wakeup+0x80>
    if (p != myproc())
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	608080e7          	jalr	1544(ra) # 80001a46 <myproc>
    80002446:	fea488e3          	beq	s1,a0,80002436 <wakeup+0x38>
      acquire(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	78a080e7          	jalr	1930(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002454:	4c9c                	lw	a5,24(s1)
    80002456:	fd379be3          	bne	a5,s3,8000242c <wakeup+0x2e>
    8000245a:	709c                	ld	a5,32(s1)
    8000245c:	fd4798e3          	bne	a5,s4,8000242c <wakeup+0x2e>
        p->state = RUNNABLE;
    80002460:	0154ac23          	sw	s5,24(s1)
        if (p->sleep_start != 0)                         // added for PBS
    80002464:	1984b783          	ld	a5,408(s1)
    80002468:	d3e1                	beqz	a5,80002428 <wakeup+0x2a>
          p->sleep_time = sys_uptime() - p->sleep_start; // added for PBS
    8000246a:	00001097          	auipc	ra,0x1
    8000246e:	0a2080e7          	jalr	162(ra) # 8000350c <sys_uptime>
    80002472:	1984b783          	ld	a5,408(s1)
    80002476:	8d1d                	sub	a0,a0,a5
    80002478:	18a4b823          	sd	a0,400(s1)
    8000247c:	b775                	j	80002428 <wakeup+0x2a>
    }
  }
}
    8000247e:	70e2                	ld	ra,56(sp)
    80002480:	7442                	ld	s0,48(sp)
    80002482:	74a2                	ld	s1,40(sp)
    80002484:	7902                	ld	s2,32(sp)
    80002486:	69e2                	ld	s3,24(sp)
    80002488:	6a42                	ld	s4,16(sp)
    8000248a:	6aa2                	ld	s5,8(sp)
    8000248c:	6121                	addi	sp,sp,64
    8000248e:	8082                	ret

0000000080002490 <reparent>:
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024a2:	0000f497          	auipc	s1,0xf
    800024a6:	e7e48493          	addi	s1,s1,-386 # 80011320 <proc>
      pp->parent = initproc;
    800024aa:	00006a17          	auipc	s4,0x6
    800024ae:	7cea0a13          	addi	s4,s4,1998 # 80008c78 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b2:	00016997          	auipc	s3,0x16
    800024b6:	46e98993          	addi	s3,s3,1134 # 80018920 <tickslock>
    800024ba:	a029                	j	800024c4 <reparent+0x34>
    800024bc:	1d848493          	addi	s1,s1,472
    800024c0:	01348d63          	beq	s1,s3,800024da <reparent+0x4a>
    if (pp->parent == p)
    800024c4:	7c9c                	ld	a5,56(s1)
    800024c6:	ff279be3          	bne	a5,s2,800024bc <reparent+0x2c>
      pp->parent = initproc;
    800024ca:	000a3503          	ld	a0,0(s4)
    800024ce:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	f2e080e7          	jalr	-210(ra) # 800023fe <wakeup>
    800024d8:	b7d5                	j	800024bc <reparent+0x2c>
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret

00000000800024ea <exit>:
{
    800024ea:	7179                	addi	sp,sp,-48
    800024ec:	f406                	sd	ra,40(sp)
    800024ee:	f022                	sd	s0,32(sp)
    800024f0:	ec26                	sd	s1,24(sp)
    800024f2:	e84a                	sd	s2,16(sp)
    800024f4:	e44e                	sd	s3,8(sp)
    800024f6:	e052                	sd	s4,0(sp)
    800024f8:	1800                	addi	s0,sp,48
    800024fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	54a080e7          	jalr	1354(ra) # 80001a46 <myproc>
    80002504:	89aa                	mv	s3,a0
  if (p == initproc)
    80002506:	00006797          	auipc	a5,0x6
    8000250a:	7727b783          	ld	a5,1906(a5) # 80008c78 <initproc>
    8000250e:	0d850493          	addi	s1,a0,216
    80002512:	15850913          	addi	s2,a0,344
    80002516:	02a79363          	bne	a5,a0,8000253c <exit+0x52>
    panic("init exiting");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	d4650513          	addi	a0,a0,-698 # 80008260 <digits+0x220>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	01e080e7          	jalr	30(ra) # 80000540 <panic>
      fileclose(f);
    8000252a:	00003097          	auipc	ra,0x3
    8000252e:	8a0080e7          	jalr	-1888(ra) # 80004dca <fileclose>
      p->ofile[fd] = 0;
    80002532:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002536:	04a1                	addi	s1,s1,8
    80002538:	01248563          	beq	s1,s2,80002542 <exit+0x58>
    if (p->ofile[fd])
    8000253c:	6088                	ld	a0,0(s1)
    8000253e:	f575                	bnez	a0,8000252a <exit+0x40>
    80002540:	bfdd                	j	80002536 <exit+0x4c>
  begin_op();
    80002542:	00002097          	auipc	ra,0x2
    80002546:	3c0080e7          	jalr	960(ra) # 80004902 <begin_op>
  iput(p->cwd);
    8000254a:	1589b503          	ld	a0,344(s3)
    8000254e:	00002097          	auipc	ra,0x2
    80002552:	ba2080e7          	jalr	-1118(ra) # 800040f0 <iput>
  end_op();
    80002556:	00002097          	auipc	ra,0x2
    8000255a:	42a080e7          	jalr	1066(ra) # 80004980 <end_op>
  p->cwd = 0;
    8000255e:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	9a648493          	addi	s1,s1,-1626 # 80010f08 <wait_lock>
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	66a080e7          	jalr	1642(ra) # 80000bd6 <acquire>
  reparent(p);
    80002574:	854e                	mv	a0,s3
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	f1a080e7          	jalr	-230(ra) # 80002490 <reparent>
  wakeup(p->parent);
    8000257e:	0389b503          	ld	a0,56(s3)
    80002582:	00000097          	auipc	ra,0x0
    80002586:	e7c080e7          	jalr	-388(ra) # 800023fe <wakeup>
  acquire(&p->lock);
    8000258a:	854e                	mv	a0,s3
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	64a080e7          	jalr	1610(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002594:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002598:	4795                	li	a5,5
    8000259a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6ea080e7          	jalr	1770(ra) # 80000c8a <release>
  sched();
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	cca080e7          	jalr	-822(ra) # 80002272 <sched>
  panic("zombie exit");
    800025b0:	00006517          	auipc	a0,0x6
    800025b4:	cc050513          	addi	a0,a0,-832 # 80008270 <digits+0x230>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	f88080e7          	jalr	-120(ra) # 80000540 <panic>

00000000800025c0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025d0:	0000f497          	auipc	s1,0xf
    800025d4:	d5048493          	addi	s1,s1,-688 # 80011320 <proc>
    800025d8:	00016997          	auipc	s3,0x16
    800025dc:	34898993          	addi	s3,s3,840 # 80018920 <tickslock>
  {
    acquire(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	5f4080e7          	jalr	1524(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800025ea:	589c                	lw	a5,48(s1)
    800025ec:	01278d63          	beq	a5,s2,80002606 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	698080e7          	jalr	1688(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025fa:	1d848493          	addi	s1,s1,472
    800025fe:	ff3491e3          	bne	s1,s3,800025e0 <kill+0x20>
  }
  return -1;
    80002602:	557d                	li	a0,-1
    80002604:	a829                	j	8000261e <kill+0x5e>
      p->killed = 1;
    80002606:	4785                	li	a5,1
    80002608:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000260a:	4c98                	lw	a4,24(s1)
    8000260c:	4789                	li	a5,2
    8000260e:	00f70f63          	beq	a4,a5,8000262c <kill+0x6c>
      release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	676080e7          	jalr	1654(ra) # 80000c8a <release>
      return 0;
    8000261c:	4501                	li	a0,0
}
    8000261e:	70a2                	ld	ra,40(sp)
    80002620:	7402                	ld	s0,32(sp)
    80002622:	64e2                	ld	s1,24(sp)
    80002624:	6942                	ld	s2,16(sp)
    80002626:	69a2                	ld	s3,8(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret
        p->state = RUNNABLE;
    8000262c:	478d                	li	a5,3
    8000262e:	cc9c                	sw	a5,24(s1)
    80002630:	b7cd                	j	80002612 <kill+0x52>

0000000080002632 <setkilled>:

void setkilled(struct proc *p)
{
    80002632:	1101                	addi	sp,sp,-32
    80002634:	ec06                	sd	ra,24(sp)
    80002636:	e822                	sd	s0,16(sp)
    80002638:	e426                	sd	s1,8(sp)
    8000263a:	1000                	addi	s0,sp,32
    8000263c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	598080e7          	jalr	1432(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002646:	4785                	li	a5,1
    80002648:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	63e080e7          	jalr	1598(ra) # 80000c8a <release>
}
    80002654:	60e2                	ld	ra,24(sp)
    80002656:	6442                	ld	s0,16(sp)
    80002658:	64a2                	ld	s1,8(sp)
    8000265a:	6105                	addi	sp,sp,32
    8000265c:	8082                	ret

000000008000265e <killed>:

int killed(struct proc *p)
{
    8000265e:	1101                	addi	sp,sp,-32
    80002660:	ec06                	sd	ra,24(sp)
    80002662:	e822                	sd	s0,16(sp)
    80002664:	e426                	sd	s1,8(sp)
    80002666:	e04a                	sd	s2,0(sp)
    80002668:	1000                	addi	s0,sp,32
    8000266a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	56a080e7          	jalr	1386(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002674:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	610080e7          	jalr	1552(ra) # 80000c8a <release>
  return k;
}
    80002682:	854a                	mv	a0,s2
    80002684:	60e2                	ld	ra,24(sp)
    80002686:	6442                	ld	s0,16(sp)
    80002688:	64a2                	ld	s1,8(sp)
    8000268a:	6902                	ld	s2,0(sp)
    8000268c:	6105                	addi	sp,sp,32
    8000268e:	8082                	ret

0000000080002690 <wait>:
{
    80002690:	715d                	addi	sp,sp,-80
    80002692:	e486                	sd	ra,72(sp)
    80002694:	e0a2                	sd	s0,64(sp)
    80002696:	fc26                	sd	s1,56(sp)
    80002698:	f84a                	sd	s2,48(sp)
    8000269a:	f44e                	sd	s3,40(sp)
    8000269c:	f052                	sd	s4,32(sp)
    8000269e:	ec56                	sd	s5,24(sp)
    800026a0:	e85a                	sd	s6,16(sp)
    800026a2:	e45e                	sd	s7,8(sp)
    800026a4:	e062                	sd	s8,0(sp)
    800026a6:	0880                	addi	s0,sp,80
    800026a8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	39c080e7          	jalr	924(ra) # 80001a46 <myproc>
    800026b2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026b4:	0000f517          	auipc	a0,0xf
    800026b8:	85450513          	addi	a0,a0,-1964 # 80010f08 <wait_lock>
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	51a080e7          	jalr	1306(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026c4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026c6:	4a15                	li	s4,5
        havekids = 1;
    800026c8:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ca:	00016997          	auipc	s3,0x16
    800026ce:	25698993          	addi	s3,s3,598 # 80018920 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026d2:	0000fc17          	auipc	s8,0xf
    800026d6:	836c0c13          	addi	s8,s8,-1994 # 80010f08 <wait_lock>
    havekids = 0;
    800026da:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026dc:	0000f497          	auipc	s1,0xf
    800026e0:	c4448493          	addi	s1,s1,-956 # 80011320 <proc>
    800026e4:	a0bd                	j	80002752 <wait+0xc2>
          pid = pp->pid;
    800026e6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026ea:	000b0e63          	beqz	s6,80002706 <wait+0x76>
    800026ee:	4691                	li	a3,4
    800026f0:	02c48613          	addi	a2,s1,44
    800026f4:	85da                	mv	a1,s6
    800026f6:	05893503          	ld	a0,88(s2)
    800026fa:	fffff097          	auipc	ra,0xfffff
    800026fe:	f72080e7          	jalr	-142(ra) # 8000166c <copyout>
    80002702:	02054563          	bltz	a0,8000272c <wait+0x9c>
          freeproc(pp);
    80002706:	8526                	mv	a0,s1
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	4f0080e7          	jalr	1264(ra) # 80001bf8 <freeproc>
          release(&pp->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	578080e7          	jalr	1400(ra) # 80000c8a <release>
          release(&wait_lock);
    8000271a:	0000e517          	auipc	a0,0xe
    8000271e:	7ee50513          	addi	a0,a0,2030 # 80010f08 <wait_lock>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	568080e7          	jalr	1384(ra) # 80000c8a <release>
          return pid;
    8000272a:	a0b5                	j	80002796 <wait+0x106>
            release(&pp->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	55c080e7          	jalr	1372(ra) # 80000c8a <release>
            release(&wait_lock);
    80002736:	0000e517          	auipc	a0,0xe
    8000273a:	7d250513          	addi	a0,a0,2002 # 80010f08 <wait_lock>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
            return -1;
    80002746:	59fd                	li	s3,-1
    80002748:	a0b9                	j	80002796 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000274a:	1d848493          	addi	s1,s1,472
    8000274e:	03348463          	beq	s1,s3,80002776 <wait+0xe6>
      if (pp->parent == p)
    80002752:	7c9c                	ld	a5,56(s1)
    80002754:	ff279be3          	bne	a5,s2,8000274a <wait+0xba>
        acquire(&pp->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	47c080e7          	jalr	1148(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002762:	4c9c                	lw	a5,24(s1)
    80002764:	f94781e3          	beq	a5,s4,800026e6 <wait+0x56>
        release(&pp->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	520080e7          	jalr	1312(ra) # 80000c8a <release>
        havekids = 1;
    80002772:	8756                	mv	a4,s5
    80002774:	bfd9                	j	8000274a <wait+0xba>
    if (!havekids || killed(p))
    80002776:	c719                	beqz	a4,80002784 <wait+0xf4>
    80002778:	854a                	mv	a0,s2
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	ee4080e7          	jalr	-284(ra) # 8000265e <killed>
    80002782:	c51d                	beqz	a0,800027b0 <wait+0x120>
      release(&wait_lock);
    80002784:	0000e517          	auipc	a0,0xe
    80002788:	78450513          	addi	a0,a0,1924 # 80010f08 <wait_lock>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4fe080e7          	jalr	1278(ra) # 80000c8a <release>
      return -1;
    80002794:	59fd                	li	s3,-1
}
    80002796:	854e                	mv	a0,s3
    80002798:	60a6                	ld	ra,72(sp)
    8000279a:	6406                	ld	s0,64(sp)
    8000279c:	74e2                	ld	s1,56(sp)
    8000279e:	7942                	ld	s2,48(sp)
    800027a0:	79a2                	ld	s3,40(sp)
    800027a2:	7a02                	ld	s4,32(sp)
    800027a4:	6ae2                	ld	s5,24(sp)
    800027a6:	6b42                	ld	s6,16(sp)
    800027a8:	6ba2                	ld	s7,8(sp)
    800027aa:	6c02                	ld	s8,0(sp)
    800027ac:	6161                	addi	sp,sp,80
    800027ae:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027b0:	85e2                	mv	a1,s8
    800027b2:	854a                	mv	a0,s2
    800027b4:	00000097          	auipc	ra,0x0
    800027b8:	bd0080e7          	jalr	-1072(ra) # 80002384 <sleep>
    havekids = 0;
    800027bc:	bf39                	j	800026da <wait+0x4a>

00000000800027be <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027be:	7179                	addi	sp,sp,-48
    800027c0:	f406                	sd	ra,40(sp)
    800027c2:	f022                	sd	s0,32(sp)
    800027c4:	ec26                	sd	s1,24(sp)
    800027c6:	e84a                	sd	s2,16(sp)
    800027c8:	e44e                	sd	s3,8(sp)
    800027ca:	e052                	sd	s4,0(sp)
    800027cc:	1800                	addi	s0,sp,48
    800027ce:	84aa                	mv	s1,a0
    800027d0:	892e                	mv	s2,a1
    800027d2:	89b2                	mv	s3,a2
    800027d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	270080e7          	jalr	624(ra) # 80001a46 <myproc>
  if (user_dst)
    800027de:	c08d                	beqz	s1,80002800 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027e0:	86d2                	mv	a3,s4
    800027e2:	864e                	mv	a2,s3
    800027e4:	85ca                	mv	a1,s2
    800027e6:	6d28                	ld	a0,88(a0)
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	e84080e7          	jalr	-380(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027f0:	70a2                	ld	ra,40(sp)
    800027f2:	7402                	ld	s0,32(sp)
    800027f4:	64e2                	ld	s1,24(sp)
    800027f6:	6942                	ld	s2,16(sp)
    800027f8:	69a2                	ld	s3,8(sp)
    800027fa:	6a02                	ld	s4,0(sp)
    800027fc:	6145                	addi	sp,sp,48
    800027fe:	8082                	ret
    memmove((char *)dst, src, len);
    80002800:	000a061b          	sext.w	a2,s4
    80002804:	85ce                	mv	a1,s3
    80002806:	854a                	mv	a0,s2
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	526080e7          	jalr	1318(ra) # 80000d2e <memmove>
    return 0;
    80002810:	8526                	mv	a0,s1
    80002812:	bff9                	j	800027f0 <either_copyout+0x32>

0000000080002814 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002814:	7179                	addi	sp,sp,-48
    80002816:	f406                	sd	ra,40(sp)
    80002818:	f022                	sd	s0,32(sp)
    8000281a:	ec26                	sd	s1,24(sp)
    8000281c:	e84a                	sd	s2,16(sp)
    8000281e:	e44e                	sd	s3,8(sp)
    80002820:	e052                	sd	s4,0(sp)
    80002822:	1800                	addi	s0,sp,48
    80002824:	892a                	mv	s2,a0
    80002826:	84ae                	mv	s1,a1
    80002828:	89b2                	mv	s3,a2
    8000282a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	21a080e7          	jalr	538(ra) # 80001a46 <myproc>
  if (user_src)
    80002834:	c08d                	beqz	s1,80002856 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002836:	86d2                	mv	a3,s4
    80002838:	864e                	mv	a2,s3
    8000283a:	85ca                	mv	a1,s2
    8000283c:	6d28                	ld	a0,88(a0)
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	eba080e7          	jalr	-326(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002846:	70a2                	ld	ra,40(sp)
    80002848:	7402                	ld	s0,32(sp)
    8000284a:	64e2                	ld	s1,24(sp)
    8000284c:	6942                	ld	s2,16(sp)
    8000284e:	69a2                	ld	s3,8(sp)
    80002850:	6a02                	ld	s4,0(sp)
    80002852:	6145                	addi	sp,sp,48
    80002854:	8082                	ret
    memmove(dst, (char *)src, len);
    80002856:	000a061b          	sext.w	a2,s4
    8000285a:	85ce                	mv	a1,s3
    8000285c:	854a                	mv	a0,s2
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	4d0080e7          	jalr	1232(ra) # 80000d2e <memmove>
    return 0;
    80002866:	8526                	mv	a0,s1
    80002868:	bff9                	j	80002846 <either_copyin+0x32>

000000008000286a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000286a:	715d                	addi	sp,sp,-80
    8000286c:	e486                	sd	ra,72(sp)
    8000286e:	e0a2                	sd	s0,64(sp)
    80002870:	fc26                	sd	s1,56(sp)
    80002872:	f84a                	sd	s2,48(sp)
    80002874:	f44e                	sd	s3,40(sp)
    80002876:	f052                	sd	s4,32(sp)
    80002878:	ec56                	sd	s5,24(sp)
    8000287a:	e85a                	sd	s6,16(sp)
    8000287c:	e45e                	sd	s7,8(sp)
    8000287e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002880:	00006517          	auipc	a0,0x6
    80002884:	84850513          	addi	a0,a0,-1976 # 800080c8 <digits+0x88>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	d02080e7          	jalr	-766(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002890:	0000f497          	auipc	s1,0xf
    80002894:	bf048493          	addi	s1,s1,-1040 # 80011480 <proc+0x160>
    80002898:	00016917          	auipc	s2,0x16
    8000289c:	1e890913          	addi	s2,s2,488 # 80018a80 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028a2:	00006997          	auipc	s3,0x6
    800028a6:	9de98993          	addi	s3,s3,-1570 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800028aa:	00006a97          	auipc	s5,0x6
    800028ae:	9dea8a93          	addi	s5,s5,-1570 # 80008288 <digits+0x248>
    printf("\n");
    800028b2:	00006a17          	auipc	s4,0x6
    800028b6:	816a0a13          	addi	s4,s4,-2026 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ba:	00006b97          	auipc	s7,0x6
    800028be:	a2eb8b93          	addi	s7,s7,-1490 # 800082e8 <states.0>
    800028c2:	a00d                	j	800028e4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028c4:	ed06a583          	lw	a1,-304(a3)
    800028c8:	8556                	mv	a0,s5
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	cc0080e7          	jalr	-832(ra) # 8000058a <printf>
    printf("\n");
    800028d2:	8552                	mv	a0,s4
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	cb6080e7          	jalr	-842(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028dc:	1d848493          	addi	s1,s1,472
    800028e0:	03248263          	beq	s1,s2,80002904 <procdump+0x9a>
    if (p->state == UNUSED)
    800028e4:	86a6                	mv	a3,s1
    800028e6:	eb84a783          	lw	a5,-328(s1)
    800028ea:	dbed                	beqz	a5,800028dc <procdump+0x72>
      state = "???";
    800028ec:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ee:	fcfb6be3          	bltu	s6,a5,800028c4 <procdump+0x5a>
    800028f2:	02079713          	slli	a4,a5,0x20
    800028f6:	01d75793          	srli	a5,a4,0x1d
    800028fa:	97de                	add	a5,a5,s7
    800028fc:	6390                	ld	a2,0(a5)
    800028fe:	f279                	bnez	a2,800028c4 <procdump+0x5a>
      state = "???";
    80002900:	864e                	mv	a2,s3
    80002902:	b7c9                	j	800028c4 <procdump+0x5a>
  }
}
    80002904:	60a6                	ld	ra,72(sp)
    80002906:	6406                	ld	s0,64(sp)
    80002908:	74e2                	ld	s1,56(sp)
    8000290a:	7942                	ld	s2,48(sp)
    8000290c:	79a2                	ld	s3,40(sp)
    8000290e:	7a02                	ld	s4,32(sp)
    80002910:	6ae2                	ld	s5,24(sp)
    80002912:	6b42                	ld	s6,16(sp)
    80002914:	6ba2                	ld	s7,8(sp)
    80002916:	6161                	addi	sp,sp,80
    80002918:	8082                	ret

000000008000291a <strace>:

void strace(int strace_mask)
{
    8000291a:	1101                	addi	sp,sp,-32
    8000291c:	ec06                	sd	ra,24(sp)
    8000291e:	e822                	sd	s0,16(sp)
    80002920:	e426                	sd	s1,8(sp)
    80002922:	1000                	addi	s0,sp,32
    80002924:	84aa                	mv	s1,a0
  struct proc *p;
  p = myproc();
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	120080e7          	jalr	288(ra) # 80001a46 <myproc>
  if (!p)
    8000292e:	c519                	beqz	a0,8000293c <strace+0x22>
    return;

  myproc()->strace_bit = strace_mask;
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	116080e7          	jalr	278(ra) # 80001a46 <myproc>
    80002938:	16952823          	sw	s1,368(a0)
  return;
}
    8000293c:	60e2                	ld	ra,24(sp)
    8000293e:	6442                	ld	s0,16(sp)
    80002940:	64a2                	ld	s1,8(sp)
    80002942:	6105                	addi	sp,sp,32
    80002944:	8082                	ret

0000000080002946 <settickets>:

int settickets(int numTickets)
{
    80002946:	1101                	addi	sp,sp,-32
    80002948:	ec06                	sd	ra,24(sp)
    8000294a:	e822                	sd	s0,16(sp)
    8000294c:	e426                	sd	s1,8(sp)
    8000294e:	1000                	addi	s0,sp,32
    80002950:	84aa                	mv	s1,a0
  struct proc *p;
  p = myproc();
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	0f4080e7          	jalr	244(ra) # 80001a46 <myproc>
  if (!p)
    8000295a:	cd09                	beqz	a0,80002974 <settickets+0x2e>
    return -1;

  myproc()->num_tickets = numTickets;
    8000295c:	fffff097          	auipc	ra,0xfffff
    80002960:	0ea080e7          	jalr	234(ra) # 80001a46 <myproc>
    80002964:	18953023          	sd	s1,384(a0)
  return numTickets;
    80002968:	8526                	mv	a0,s1
}
    8000296a:	60e2                	ld	ra,24(sp)
    8000296c:	6442                	ld	s0,16(sp)
    8000296e:	64a2                	ld	s1,8(sp)
    80002970:	6105                	addi	sp,sp,32
    80002972:	8082                	ret
    return -1;
    80002974:	557d                	li	a0,-1
    80002976:	bfd5                	j	8000296a <settickets+0x24>

0000000080002978 <calcDP>:

int calcDP(struct proc *p)
{
    80002978:	1141                	addi	sp,sp,-16
    8000297a:	e422                	sd	s0,8(sp)
    8000297c:	0800                	addi	s0,sp,16
  int sleep_time = p->sleep_time;
    8000297e:	19052703          	lw	a4,400(a0)
  int running_time = p->running_time;
  int SP = p->static_priority;
    80002982:	18855783          	lhu	a5,392(a0)
  int running_time = p->running_time;
    80002986:	1a053683          	ld	a3,416(a0)

  if ((sleep_time + running_time) == 0)
    8000298a:	9eb9                	addw	a3,a3,a4
    8000298c:	0006861b          	sext.w	a2,a3
    return 5; // assume normal niceness
    80002990:	4515                	li	a0,5
  if ((sleep_time + running_time) == 0)
    80002992:	ca15                	beqz	a2,800029c6 <calcDP+0x4e>

  int niceness = 10 * ((int)sleep_time / (sleep_time + running_time));
    80002994:	02d7473b          	divw	a4,a4,a3
    80002998:	0027169b          	slliw	a3,a4,0x2
    8000299c:	9f35                	addw	a4,a4,a3
    8000299e:	0017171b          	slliw	a4,a4,0x1
  int DP = ((SP - niceness + 5) < 100) ? (SP - niceness + 5) : 100;
    800029a2:	40e7853b          	subw	a0,a5,a4
    800029a6:	0005071b          	sext.w	a4,a0
    800029aa:	05f00793          	li	a5,95
    800029ae:	00e7d463          	bge	a5,a4,800029b6 <calcDP+0x3e>
    800029b2:	05f00513          	li	a0,95
    800029b6:	2515                	addiw	a0,a0,5

  return (DP > 0) ? DP : 0;
    800029b8:	0005079b          	sext.w	a5,a0
    800029bc:	fff7c793          	not	a5,a5
    800029c0:	97fd                	srai	a5,a5,0x3f
    800029c2:	8d7d                	and	a0,a0,a5
    800029c4:	2501                	sext.w	a0,a0
}
    800029c6:	6422                	ld	s0,8(sp)
    800029c8:	0141                	addi	sp,sp,16
    800029ca:	8082                	ret

00000000800029cc <priority_based>:
{
    800029cc:	7139                	addi	sp,sp,-64
    800029ce:	fc06                	sd	ra,56(sp)
    800029d0:	f822                	sd	s0,48(sp)
    800029d2:	f426                	sd	s1,40(sp)
    800029d4:	f04a                	sd	s2,32(sp)
    800029d6:	ec4e                	sd	s3,24(sp)
    800029d8:	e852                	sd	s4,16(sp)
    800029da:	e456                	sd	s5,8(sp)
    800029dc:	e05a                	sd	s6,0(sp)
    800029de:	0080                	addi	s0,sp,64
    800029e0:	8b2a                	mv	s6,a0
  for (int i = 0; i < NPROC; i++)
    800029e2:	0000f497          	auipc	s1,0xf
    800029e6:	93e48493          	addi	s1,s1,-1730 # 80011320 <proc>
    800029ea:	00016a97          	auipc	s5,0x16
    800029ee:	f36a8a93          	addi	s5,s5,-202 # 80018920 <tickslock>
  struct proc *chosenproc = 0;
    800029f2:	4901                	li	s2,0
    if (p->state != RUNNABLE)
    800029f4:	4a0d                	li	s4,3
    800029f6:	a015                	j	80002a1a <priority_based+0x4e>
      release(&p->lock);
    800029f8:	8526                	mv	a0,s1
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	290080e7          	jalr	656(ra) # 80000c8a <release>
      continue;
    80002a02:	a801                	j	80002a12 <priority_based+0x46>
    if (p != chosenproc)
    80002a04:	01248763          	beq	s1,s2,80002a12 <priority_based+0x46>
      release(&p->lock);
    80002a08:	8526                	mv	a0,s1
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    80002a12:	1d848493          	addi	s1,s1,472
    80002a16:	05548163          	beq	s1,s5,80002a58 <priority_based+0x8c>
    struct proc *p = &proc[i];
    80002a1a:	89a6                	mv	s3,s1
    acquire(&p->lock);
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	1b8080e7          	jalr	440(ra) # 80000bd6 <acquire>
    if (p->state != RUNNABLE)
    80002a26:	4c9c                	lw	a5,24(s1)
    80002a28:	fd4798e3          	bne	a5,s4,800029f8 <priority_based+0x2c>
    p->dynamic_priority = calcDP(p);
    80002a2c:	8526                	mv	a0,s1
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	f4a080e7          	jalr	-182(ra) # 80002978 <calcDP>
    80002a36:	1542                	slli	a0,a0,0x30
    80002a38:	9141                	srli	a0,a0,0x30
    80002a3a:	1aa49423          	sh	a0,424(s1)
    if (!chosenproc || (p->dynamic_priority < chosenproc->dynamic_priority)) // this works because of short-circuiting
    80002a3e:	00090b63          	beqz	s2,80002a54 <priority_based+0x88>
    80002a42:	1a895783          	lhu	a5,424(s2)
    80002a46:	faf57fe3          	bgeu	a0,a5,80002a04 <priority_based+0x38>
        release(&chosenproc->lock);
    80002a4a:	854a                	mv	a0,s2
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	23e080e7          	jalr	574(ra) # 80000c8a <release>
  struct proc *chosenproc = 0;
    80002a54:	894e                	mv	s2,s3
    80002a56:	bf75                	j	80002a12 <priority_based+0x46>
  if (chosenproc)
    80002a58:	02090863          	beqz	s2,80002a88 <priority_based+0xbc>
    chosenproc->state = RUNNING;
    80002a5c:	4791                	li	a5,4
    80002a5e:	00f92c23          	sw	a5,24(s2)
    chosenproc->sleep_time = 0;
    80002a62:	18093823          	sd	zero,400(s2)
    c->proc = chosenproc;
    80002a66:	012b3023          	sd	s2,0(s6)
    swtch(&c->context, &chosenproc->context);
    80002a6a:	06890593          	addi	a1,s2,104
    80002a6e:	008b0513          	addi	a0,s6,8
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	150080e7          	jalr	336(ra) # 80002bc2 <swtch>
    c->proc = 0;
    80002a7a:	000b3023          	sd	zero,0(s6)
    release(&chosenproc->lock);
    80002a7e:	854a                	mv	a0,s2
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	20a080e7          	jalr	522(ra) # 80000c8a <release>
}
    80002a88:	70e2                	ld	ra,56(sp)
    80002a8a:	7442                	ld	s0,48(sp)
    80002a8c:	74a2                	ld	s1,40(sp)
    80002a8e:	7902                	ld	s2,32(sp)
    80002a90:	69e2                	ld	s3,24(sp)
    80002a92:	6a42                	ld	s4,16(sp)
    80002a94:	6aa2                	ld	s5,8(sp)
    80002a96:	6b02                	ld	s6,0(sp)
    80002a98:	6121                	addi	sp,sp,64
    80002a9a:	8082                	ret

0000000080002a9c <set_priority>:

int set_priority(int new_priority, int pid)
{
    80002a9c:	7139                	addi	sp,sp,-64
    80002a9e:	fc06                	sd	ra,56(sp)
    80002aa0:	f822                	sd	s0,48(sp)
    80002aa2:	f426                	sd	s1,40(sp)
    80002aa4:	f04a                	sd	s2,32(sp)
    80002aa6:	ec4e                	sd	s3,24(sp)
    80002aa8:	e852                	sd	s4,16(sp)
    80002aaa:	e456                	sd	s5,8(sp)
    80002aac:	e05a                	sd	s6,0(sp)
    80002aae:	0080                	addi	s0,sp,64
    80002ab0:	8b2a                	mv	s6,a0
    80002ab2:	89ae                	mv	s3,a1
  struct proc *chosen = 0;
  for (int i = 0; i < NPROC; i++)
    80002ab4:	0000f497          	auipc	s1,0xf
    80002ab8:	86c48493          	addi	s1,s1,-1940 # 80011320 <proc>
    80002abc:	4901                	li	s2,0
    80002abe:	04000a93          	li	s5,64
  {
    struct proc *p = &proc[i];
    80002ac2:	8a26                	mv	s4,s1
    acquire(&p->lock);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	110080e7          	jalr	272(ra) # 80000bd6 <acquire>
    if (pid == p->pid)
    80002ace:	589c                	lw	a5,48(s1)
    80002ad0:	03378663          	beq	a5,s3,80002afc <set_priority+0x60>
    {
      chosen = p;
      break;
    }
    release(&p->lock);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	1b4080e7          	jalr	436(ra) # 80000c8a <release>
  for (int i = 0; i < NPROC; i++)
    80002ade:	2905                	addiw	s2,s2,1
    80002ae0:	1d848493          	addi	s1,s1,472
    80002ae4:	fd591fe3          	bne	s2,s5,80002ac2 <set_priority+0x26>
    chosen->dynamic_priority = calcDP(chosen);
    release(&chosen->lock);
  }
  else
  {
    printf("Given pid does not exist\n");
    80002ae8:	00005517          	auipc	a0,0x5
    80002aec:	7b050513          	addi	a0,a0,1968 # 80008298 <digits+0x258>
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	a9a080e7          	jalr	-1382(ra) # 8000058a <printf>
  int prevSP = -1;
    80002af8:	597d                	li	s2,-1
    80002afa:	a815                	j	80002b2e <set_priority+0x92>
    prevSP = chosen->static_priority;
    80002afc:	1d800793          	li	a5,472
    80002b00:	02f90933          	mul	s2,s2,a5
    80002b04:	0000f497          	auipc	s1,0xf
    80002b08:	81c48493          	addi	s1,s1,-2020 # 80011320 <proc>
    80002b0c:	94ca                	add	s1,s1,s2
    80002b0e:	1884d903          	lhu	s2,392(s1)
    chosen->static_priority = new_priority;
    80002b12:	19649423          	sh	s6,392(s1)
    chosen->dynamic_priority = calcDP(chosen);
    80002b16:	8552                	mv	a0,s4
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	e60080e7          	jalr	-416(ra) # 80002978 <calcDP>
    80002b20:	1aa49423          	sh	a0,424(s1)
    release(&chosen->lock);
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	164080e7          	jalr	356(ra) # 80000c8a <release>
  }
  yield(); // reschedule once set_priority is done
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	81a080e7          	jalr	-2022(ra) # 80002348 <yield>
  return prevSP;
}
    80002b36:	854a                	mv	a0,s2
    80002b38:	70e2                	ld	ra,56(sp)
    80002b3a:	7442                	ld	s0,48(sp)
    80002b3c:	74a2                	ld	s1,40(sp)
    80002b3e:	7902                	ld	s2,32(sp)
    80002b40:	69e2                	ld	s3,24(sp)
    80002b42:	6a42                	ld	s4,16(sp)
    80002b44:	6aa2                	ld	s5,8(sp)
    80002b46:	6b02                	ld	s6,0(sp)
    80002b48:	6121                	addi	sp,sp,64
    80002b4a:	8082                	ret

0000000080002b4c <PBS_find_times>:

void PBS_find_times()
{
    80002b4c:	1141                	addi	sp,sp,-16
    80002b4e:	e422                	sd	s0,8(sp)
    80002b50:	0800                	addi	s0,sp,16
  // if (!p)
  //   return;

  // (myproc()->running_time)++;
  return;
}
    80002b52:	6422                	ld	s0,8(sp)
    80002b54:	0141                	addi	sp,sp,16
    80002b56:	8082                	ret

0000000080002b58 <sys_sigalarm>:

  ///////////////// IMPLEMENTED FOR SIGALARM /////////////////
uint64 sys_sigalarm(void)
{
    80002b58:	7179                	addi	sp,sp,-48
    80002b5a:	f406                	sd	ra,40(sp)
    80002b5c:	f022                	sd	s0,32(sp)
    80002b5e:	ec26                	sd	s1,24(sp)
    80002b60:	1800                	addi	s0,sp,48
  int this_ticks;
  argint(0, &this_ticks);
    80002b62:	fdc40593          	addi	a1,s0,-36
    80002b66:	4501                	li	a0,0
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	60a080e7          	jalr	1546(ra) # 80003172 <argint>
  uint64 handler;
  argaddr(1, &handler);
    80002b70:	fd040593          	addi	a1,s0,-48
    80002b74:	4505                	li	a0,1
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	61c080e7          	jalr	1564(ra) # 80003192 <argaddr>
  myproc()->sig_handler = 0;
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	ec8080e7          	jalr	-312(ra) # 80001a46 <myproc>
    80002b86:	1c053023          	sd	zero,448(a0)
  myproc()->num_ticks = this_ticks;
    80002b8a:	fdc42483          	lw	s1,-36(s0)
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	eb8080e7          	jalr	-328(ra) # 80001a46 <myproc>
    80002b96:	1c952423          	sw	s1,456(a0)
  myproc()->curr_ticks = 0;
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	eac080e7          	jalr	-340(ra) # 80001a46 <myproc>
    80002ba2:	1a052e23          	sw	zero,444(a0)
  myproc()->sig_handler = handler;
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	ea0080e7          	jalr	-352(ra) # 80001a46 <myproc>
    80002bae:	fd043783          	ld	a5,-48(s0)
    80002bb2:	1cf53023          	sd	a5,448(a0)
  return 0; 
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	70a2                	ld	ra,40(sp)
    80002bba:	7402                	ld	s0,32(sp)
    80002bbc:	64e2                	ld	s1,24(sp)
    80002bbe:	6145                	addi	sp,sp,48
    80002bc0:	8082                	ret

0000000080002bc2 <swtch>:
    80002bc2:	00153023          	sd	ra,0(a0)
    80002bc6:	00253423          	sd	sp,8(a0)
    80002bca:	e900                	sd	s0,16(a0)
    80002bcc:	ed04                	sd	s1,24(a0)
    80002bce:	03253023          	sd	s2,32(a0)
    80002bd2:	03353423          	sd	s3,40(a0)
    80002bd6:	03453823          	sd	s4,48(a0)
    80002bda:	03553c23          	sd	s5,56(a0)
    80002bde:	05653023          	sd	s6,64(a0)
    80002be2:	05753423          	sd	s7,72(a0)
    80002be6:	05853823          	sd	s8,80(a0)
    80002bea:	05953c23          	sd	s9,88(a0)
    80002bee:	07a53023          	sd	s10,96(a0)
    80002bf2:	07b53423          	sd	s11,104(a0)
    80002bf6:	0005b083          	ld	ra,0(a1)
    80002bfa:	0085b103          	ld	sp,8(a1)
    80002bfe:	6980                	ld	s0,16(a1)
    80002c00:	6d84                	ld	s1,24(a1)
    80002c02:	0205b903          	ld	s2,32(a1)
    80002c06:	0285b983          	ld	s3,40(a1)
    80002c0a:	0305ba03          	ld	s4,48(a1)
    80002c0e:	0385ba83          	ld	s5,56(a1)
    80002c12:	0405bb03          	ld	s6,64(a1)
    80002c16:	0485bb83          	ld	s7,72(a1)
    80002c1a:	0505bc03          	ld	s8,80(a1)
    80002c1e:	0585bc83          	ld	s9,88(a1)
    80002c22:	0605bd03          	ld	s10,96(a1)
    80002c26:	0685bd83          	ld	s11,104(a1)
    80002c2a:	8082                	ret

0000000080002c2c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c2c:	1141                	addi	sp,sp,-16
    80002c2e:	e406                	sd	ra,8(sp)
    80002c30:	e022                	sd	s0,0(sp)
    80002c32:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c34:	00005597          	auipc	a1,0x5
    80002c38:	6e458593          	addi	a1,a1,1764 # 80008318 <states.0+0x30>
    80002c3c:	00016517          	auipc	a0,0x16
    80002c40:	ce450513          	addi	a0,a0,-796 # 80018920 <tickslock>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	f02080e7          	jalr	-254(ra) # 80000b46 <initlock>
}
    80002c4c:	60a2                	ld	ra,8(sp)
    80002c4e:	6402                	ld	s0,0(sp)
    80002c50:	0141                	addi	sp,sp,16
    80002c52:	8082                	ret

0000000080002c54 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c54:	1141                	addi	sp,sp,-16
    80002c56:	e422                	sd	s0,8(sp)
    80002c58:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5a:	00003797          	auipc	a5,0x3
    80002c5e:	7c678793          	addi	a5,a5,1990 # 80006420 <kernelvec>
    80002c62:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c66:	6422                	ld	s0,8(sp)
    80002c68:	0141                	addi	sp,sp,16
    80002c6a:	8082                	ret

0000000080002c6c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c6c:	1141                	addi	sp,sp,-16
    80002c6e:	e406                	sd	ra,8(sp)
    80002c70:	e022                	sd	s0,0(sp)
    80002c72:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	dd2080e7          	jalr	-558(ra) # 80001a46 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c80:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c82:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c86:	00004697          	auipc	a3,0x4
    80002c8a:	37a68693          	addi	a3,a3,890 # 80007000 <_trampoline>
    80002c8e:	00004717          	auipc	a4,0x4
    80002c92:	37270713          	addi	a4,a4,882 # 80007000 <_trampoline>
    80002c96:	8f15                	sub	a4,a4,a3
    80002c98:	040007b7          	lui	a5,0x4000
    80002c9c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c9e:	07b2                	slli	a5,a5,0xc
    80002ca0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ca6:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ca8:	18002673          	csrr	a2,satp
    80002cac:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cae:	7130                	ld	a2,96(a0)
    80002cb0:	6138                	ld	a4,64(a0)
    80002cb2:	6585                	lui	a1,0x1
    80002cb4:	972e                	add	a4,a4,a1
    80002cb6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cb8:	7138                	ld	a4,96(a0)
    80002cba:	00000617          	auipc	a2,0x0
    80002cbe:	13e60613          	addi	a2,a2,318 # 80002df8 <usertrap>
    80002cc2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cc4:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cc6:	8612                	mv	a2,tp
    80002cc8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cca:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cce:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cd2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cda:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cdc:	6f18                	ld	a4,24(a4)
    80002cde:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ce2:	6d28                	ld	a0,88(a0)
    80002ce4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ce6:	00004717          	auipc	a4,0x4
    80002cea:	3b670713          	addi	a4,a4,950 # 8000709c <userret>
    80002cee:	8f15                	sub	a4,a4,a3
    80002cf0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cf2:	577d                	li	a4,-1
    80002cf4:	177e                	slli	a4,a4,0x3f
    80002cf6:	8d59                	or	a0,a0,a4
    80002cf8:	9782                	jalr	a5
}
    80002cfa:	60a2                	ld	ra,8(sp)
    80002cfc:	6402                	ld	s0,0(sp)
    80002cfe:	0141                	addi	sp,sp,16
    80002d00:	8082                	ret

0000000080002d02 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	e04a                	sd	s2,0(sp)
    80002d0c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d0e:	00016917          	auipc	s2,0x16
    80002d12:	c1290913          	addi	s2,s2,-1006 # 80018920 <tickslock>
    80002d16:	854a                	mv	a0,s2
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	ebe080e7          	jalr	-322(ra) # 80000bd6 <acquire>
  ticks++;
    80002d20:	00006497          	auipc	s1,0x6
    80002d24:	f6048493          	addi	s1,s1,-160 # 80008c80 <ticks>
    80002d28:	409c                	lw	a5,0(s1)
    80002d2a:	2785                	addiw	a5,a5,1
    80002d2c:	c09c                	sw	a5,0(s1)
  PBS_find_times(); // added for PBS  
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	e1e080e7          	jalr	-482(ra) # 80002b4c <PBS_find_times>
  wakeup(&ticks);
    80002d36:	8526                	mv	a0,s1
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	6c6080e7          	jalr	1734(ra) # 800023fe <wakeup>
  release(&tickslock);
    80002d40:	854a                	mv	a0,s2
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	f48080e7          	jalr	-184(ra) # 80000c8a <release>
}
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6902                	ld	s2,0(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret

0000000080002d56 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d60:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d64:	00074d63          	bltz	a4,80002d7e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d68:	57fd                	li	a5,-1
    80002d6a:	17fe                	slli	a5,a5,0x3f
    80002d6c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d6e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d70:	06f70363          	beq	a4,a5,80002dd6 <devintr+0x80>
  }
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret
     (scause & 0xff) == 9){
    80002d7e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002d82:	46a5                	li	a3,9
    80002d84:	fed792e3          	bne	a5,a3,80002d68 <devintr+0x12>
    int irq = plic_claim();
    80002d88:	00003097          	auipc	ra,0x3
    80002d8c:	7a0080e7          	jalr	1952(ra) # 80006528 <plic_claim>
    80002d90:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d92:	47a9                	li	a5,10
    80002d94:	02f50763          	beq	a0,a5,80002dc2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d98:	4785                	li	a5,1
    80002d9a:	02f50963          	beq	a0,a5,80002dcc <devintr+0x76>
    return 1;
    80002d9e:	4505                	li	a0,1
    } else if(irq){
    80002da0:	d8f1                	beqz	s1,80002d74 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002da2:	85a6                	mv	a1,s1
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	57c50513          	addi	a0,a0,1404 # 80008320 <states.0+0x38>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	7de080e7          	jalr	2014(ra) # 8000058a <printf>
      plic_complete(irq);
    80002db4:	8526                	mv	a0,s1
    80002db6:	00003097          	auipc	ra,0x3
    80002dba:	796080e7          	jalr	1942(ra) # 8000654c <plic_complete>
    return 1;
    80002dbe:	4505                	li	a0,1
    80002dc0:	bf55                	j	80002d74 <devintr+0x1e>
      uartintr();
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	bd6080e7          	jalr	-1066(ra) # 80000998 <uartintr>
    80002dca:	b7ed                	j	80002db4 <devintr+0x5e>
      virtio_disk_intr();
    80002dcc:	00004097          	auipc	ra,0x4
    80002dd0:	c48080e7          	jalr	-952(ra) # 80006a14 <virtio_disk_intr>
    80002dd4:	b7c5                	j	80002db4 <devintr+0x5e>
    if(cpuid() == 0){
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	c44080e7          	jalr	-956(ra) # 80001a1a <cpuid>
    80002dde:	c901                	beqz	a0,80002dee <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002de0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002de4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002de6:	14479073          	csrw	sip,a5
    return 2;
    80002dea:	4509                	li	a0,2
    80002dec:	b761                	j	80002d74 <devintr+0x1e>
      clockintr();
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	f14080e7          	jalr	-236(ra) # 80002d02 <clockintr>
    80002df6:	b7ed                	j	80002de0 <devintr+0x8a>

0000000080002df8 <usertrap>:
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	e426                	sd	s1,8(sp)
    80002e00:	e04a                	sd	s2,0(sp)
    80002e02:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e04:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e08:	1007f793          	andi	a5,a5,256
    80002e0c:	e3b1                	bnez	a5,80002e50 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e0e:	00003797          	auipc	a5,0x3
    80002e12:	61278793          	addi	a5,a5,1554 # 80006420 <kernelvec>
    80002e16:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	c2c080e7          	jalr	-980(ra) # 80001a46 <myproc>
    80002e22:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e24:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e26:	14102773          	csrr	a4,sepc
    80002e2a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e30:	47a1                	li	a5,8
    80002e32:	02f70763          	beq	a4,a5,80002e60 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	f20080e7          	jalr	-224(ra) # 80002d56 <devintr>
    80002e3e:	892a                	mv	s2,a0
    80002e40:	c92d                	beqz	a0,80002eb2 <usertrap+0xba>
  if(killed(p))
    80002e42:	8526                	mv	a0,s1
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	81a080e7          	jalr	-2022(ra) # 8000265e <killed>
    80002e4c:	c555                	beqz	a0,80002ef8 <usertrap+0x100>
    80002e4e:	a045                	j	80002eee <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	4f050513          	addi	a0,a0,1264 # 80008340 <states.0+0x58>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	6e8080e7          	jalr	1768(ra) # 80000540 <panic>
    if(killed(p))
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	7fe080e7          	jalr	2046(ra) # 8000265e <killed>
    80002e68:	ed1d                	bnez	a0,80002ea6 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002e6a:	70b8                	ld	a4,96(s1)
    80002e6c:	6f1c                	ld	a5,24(a4)
    80002e6e:	0791                	addi	a5,a5,4
    80002e70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	434080e7          	jalr	1076(ra) # 800032b2 <syscall>
  if(killed(p))
    80002e86:	8526                	mv	a0,s1
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	7d6080e7          	jalr	2006(ra) # 8000265e <killed>
    80002e90:	ed31                	bnez	a0,80002eec <usertrap+0xf4>
  usertrapret();
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	dda080e7          	jalr	-550(ra) # 80002c6c <usertrapret>
}
    80002e9a:	60e2                	ld	ra,24(sp)
    80002e9c:	6442                	ld	s0,16(sp)
    80002e9e:	64a2                	ld	s1,8(sp)
    80002ea0:	6902                	ld	s2,0(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret
      exit(-1);
    80002ea6:	557d                	li	a0,-1
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	642080e7          	jalr	1602(ra) # 800024ea <exit>
    80002eb0:	bf6d                	j	80002e6a <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002eb6:	5890                	lw	a2,48(s1)
    80002eb8:	00005517          	auipc	a0,0x5
    80002ebc:	4a850513          	addi	a0,a0,1192 # 80008360 <states.0+0x78>
    80002ec0:	ffffd097          	auipc	ra,0xffffd
    80002ec4:	6ca080e7          	jalr	1738(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ecc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	4c050513          	addi	a0,a0,1216 # 80008390 <states.0+0xa8>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	6b2080e7          	jalr	1714(ra) # 8000058a <printf>
    setkilled(p);
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	750080e7          	jalr	1872(ra) # 80002632 <setkilled>
    80002eea:	bf71                	j	80002e86 <usertrap+0x8e>
  if(killed(p))
    80002eec:	4901                	li	s2,0
    exit(-1);
    80002eee:	557d                	li	a0,-1
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	5fa080e7          	jalr	1530(ra) # 800024ea <exit>
  if(which_dev == 2)
    80002ef8:	4789                	li	a5,2
    80002efa:	f8f91ce3          	bne	s2,a5,80002e92 <usertrap+0x9a>
    p->curr_ticks+=1;
    80002efe:	1bc4a783          	lw	a5,444(s1)
    80002f02:	2785                	addiw	a5,a5,1
    80002f04:	0007871b          	sext.w	a4,a5
    80002f08:	1af4ae23          	sw	a5,444(s1)
    if(p->num_ticks>0&&p->curr_ticks>=p->num_ticks&&!p->alarm_is_set){
    80002f0c:	1c84a783          	lw	a5,456(s1)
    80002f10:	c7a9                	beqz	a5,80002f5a <usertrap+0x162>
    80002f12:	04f76463          	bltu	a4,a5,80002f5a <usertrap+0x162>
    80002f16:	1ba4d783          	lhu	a5,442(s1)
    80002f1a:	e3a1                	bnez	a5,80002f5a <usertrap+0x162>
      p->curr_ticks = 0;
    80002f1c:	1a04ae23          	sw	zero,444(s1)
      p->alarm_is_set=1;
    80002f20:	4785                	li	a5,1
    80002f22:	1af49d23          	sh	a5,442(s1)
      *(p->trapframe_copy)=*(p->trapframe);
    80002f26:	70b4                	ld	a3,96(s1)
    80002f28:	87b6                	mv	a5,a3
    80002f2a:	1d04b703          	ld	a4,464(s1)
    80002f2e:	12068693          	addi	a3,a3,288
    80002f32:	0007b803          	ld	a6,0(a5)
    80002f36:	6788                	ld	a0,8(a5)
    80002f38:	6b8c                	ld	a1,16(a5)
    80002f3a:	6f90                	ld	a2,24(a5)
    80002f3c:	01073023          	sd	a6,0(a4)
    80002f40:	e708                	sd	a0,8(a4)
    80002f42:	eb0c                	sd	a1,16(a4)
    80002f44:	ef10                	sd	a2,24(a4)
    80002f46:	02078793          	addi	a5,a5,32
    80002f4a:	02070713          	addi	a4,a4,32
    80002f4e:	fed792e3          	bne	a5,a3,80002f32 <usertrap+0x13a>
      p->trapframe->epc=p->sig_handler;
    80002f52:	70bc                	ld	a5,96(s1)
    80002f54:	1c04b703          	ld	a4,448(s1)
    80002f58:	ef98                	sd	a4,24(a5)
      yield();
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	3ee080e7          	jalr	1006(ra) # 80002348 <yield>
    80002f62:	bf05                	j	80002e92 <usertrap+0x9a>

0000000080002f64 <kerneltrap>:
{
    80002f64:	7179                	addi	sp,sp,-48
    80002f66:	f406                	sd	ra,40(sp)
    80002f68:	f022                	sd	s0,32(sp)
    80002f6a:	ec26                	sd	s1,24(sp)
    80002f6c:	e84a                	sd	s2,16(sp)
    80002f6e:	e44e                	sd	s3,8(sp)
    80002f70:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f72:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f76:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f7e:	1004f793          	andi	a5,s1,256
    80002f82:	cb85                	beqz	a5,80002fb2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f88:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f8a:	ef85                	bnez	a5,80002fc2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	dca080e7          	jalr	-566(ra) # 80002d56 <devintr>
    80002f94:	cd1d                	beqz	a0,80002fd2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f96:	4789                	li	a5,2
    80002f98:	06f50a63          	beq	a0,a5,8000300c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f9c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa0:	10049073          	csrw	sstatus,s1
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fb2:	00005517          	auipc	a0,0x5
    80002fb6:	3fe50513          	addi	a0,a0,1022 # 800083b0 <states.0+0xc8>
    80002fba:	ffffd097          	auipc	ra,0xffffd
    80002fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002fc2:	00005517          	auipc	a0,0x5
    80002fc6:	41650513          	addi	a0,a0,1046 # 800083d8 <states.0+0xf0>
    80002fca:	ffffd097          	auipc	ra,0xffffd
    80002fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002fd2:	85ce                	mv	a1,s3
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	42450513          	addi	a0,a0,1060 # 800083f8 <states.0+0x110>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5ae080e7          	jalr	1454(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fe4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fe8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fec:	00005517          	auipc	a0,0x5
    80002ff0:	41c50513          	addi	a0,a0,1052 # 80008408 <states.0+0x120>
    80002ff4:	ffffd097          	auipc	ra,0xffffd
    80002ff8:	596080e7          	jalr	1430(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	42450513          	addi	a0,a0,1060 # 80008420 <states.0+0x138>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	a3a080e7          	jalr	-1478(ra) # 80001a46 <myproc>
    80003014:	d541                	beqz	a0,80002f9c <kerneltrap+0x38>
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	a30080e7          	jalr	-1488(ra) # 80001a46 <myproc>
    8000301e:	4d18                	lw	a4,24(a0)
    80003020:	4791                	li	a5,4
    80003022:	f6f71de3          	bne	a4,a5,80002f9c <kerneltrap+0x38>
      yield();
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	322080e7          	jalr	802(ra) # 80002348 <yield>
      if (myproc()->proc_queue < 4)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	a18080e7          	jalr	-1512(ra) # 80001a46 <myproc>
    80003036:	1aa55703          	lhu	a4,426(a0)
    8000303a:	478d                	li	a5,3
    8000303c:	00e7fe63          	bgeu	a5,a4,80003058 <kerneltrap+0xf4>
      myproc()->birth_time = sys_uptime();
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	a06080e7          	jalr	-1530(ra) # 80001a46 <myproc>
    80003048:	89aa                	mv	s3,a0
    8000304a:	00000097          	auipc	ra,0x0
    8000304e:	4c2080e7          	jalr	1218(ra) # 8000350c <sys_uptime>
    80003052:	16a9bc23          	sd	a0,376(s3)
    80003056:	b799                	j	80002f9c <kerneltrap+0x38>
        (myproc()->proc_queue)++;
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	9ee080e7          	jalr	-1554(ra) # 80001a46 <myproc>
    80003060:	1aa55783          	lhu	a5,426(a0)
    80003064:	2785                	addiw	a5,a5,1
    80003066:	1af51523          	sh	a5,426(a0)
    8000306a:	bfd9                	j	80003040 <kerneltrap+0xdc>

000000008000306c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	9ce080e7          	jalr	-1586(ra) # 80001a46 <myproc>
  switch (n)
    80003080:	4795                	li	a5,5
    80003082:	0497e163          	bltu	a5,s1,800030c4 <argraw+0x58>
    80003086:	048a                	slli	s1,s1,0x2
    80003088:	00005717          	auipc	a4,0x5
    8000308c:	4f070713          	addi	a4,a4,1264 # 80008578 <states.0+0x290>
    80003090:	94ba                	add	s1,s1,a4
    80003092:	409c                	lw	a5,0(s1)
    80003094:	97ba                	add	a5,a5,a4
    80003096:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80003098:	713c                	ld	a5,96(a0)
    8000309a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret
    return p->trapframe->a1;
    800030a6:	713c                	ld	a5,96(a0)
    800030a8:	7fa8                	ld	a0,120(a5)
    800030aa:	bfcd                	j	8000309c <argraw+0x30>
    return p->trapframe->a2;
    800030ac:	713c                	ld	a5,96(a0)
    800030ae:	63c8                	ld	a0,128(a5)
    800030b0:	b7f5                	j	8000309c <argraw+0x30>
    return p->trapframe->a3;
    800030b2:	713c                	ld	a5,96(a0)
    800030b4:	67c8                	ld	a0,136(a5)
    800030b6:	b7dd                	j	8000309c <argraw+0x30>
    return p->trapframe->a4;
    800030b8:	713c                	ld	a5,96(a0)
    800030ba:	6bc8                	ld	a0,144(a5)
    800030bc:	b7c5                	j	8000309c <argraw+0x30>
    return p->trapframe->a5;
    800030be:	713c                	ld	a5,96(a0)
    800030c0:	6fc8                	ld	a0,152(a5)
    800030c2:	bfe9                	j	8000309c <argraw+0x30>
  panic("argraw");
    800030c4:	00005517          	auipc	a0,0x5
    800030c8:	36c50513          	addi	a0,a0,876 # 80008430 <states.0+0x148>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	474080e7          	jalr	1140(ra) # 80000540 <panic>

00000000800030d4 <fetchaddr>:
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	e04a                	sd	s2,0(sp)
    800030de:	1000                	addi	s0,sp,32
    800030e0:	84aa                	mv	s1,a0
    800030e2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	962080e7          	jalr	-1694(ra) # 80001a46 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030ec:	653c                	ld	a5,72(a0)
    800030ee:	02f4f863          	bgeu	s1,a5,8000311e <fetchaddr+0x4a>
    800030f2:	00848713          	addi	a4,s1,8
    800030f6:	02e7e663          	bltu	a5,a4,80003122 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030fa:	46a1                	li	a3,8
    800030fc:	8626                	mv	a2,s1
    800030fe:	85ca                	mv	a1,s2
    80003100:	6d28                	ld	a0,88(a0)
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	5f6080e7          	jalr	1526(ra) # 800016f8 <copyin>
    8000310a:	00a03533          	snez	a0,a0
    8000310e:	40a00533          	neg	a0,a0
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	64a2                	ld	s1,8(sp)
    80003118:	6902                	ld	s2,0(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret
    return -1;
    8000311e:	557d                	li	a0,-1
    80003120:	bfcd                	j	80003112 <fetchaddr+0x3e>
    80003122:	557d                	li	a0,-1
    80003124:	b7fd                	j	80003112 <fetchaddr+0x3e>

0000000080003126 <fetchstr>:
{
    80003126:	7179                	addi	sp,sp,-48
    80003128:	f406                	sd	ra,40(sp)
    8000312a:	f022                	sd	s0,32(sp)
    8000312c:	ec26                	sd	s1,24(sp)
    8000312e:	e84a                	sd	s2,16(sp)
    80003130:	e44e                	sd	s3,8(sp)
    80003132:	1800                	addi	s0,sp,48
    80003134:	892a                	mv	s2,a0
    80003136:	84ae                	mv	s1,a1
    80003138:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	90c080e7          	jalr	-1780(ra) # 80001a46 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003142:	86ce                	mv	a3,s3
    80003144:	864a                	mv	a2,s2
    80003146:	85a6                	mv	a1,s1
    80003148:	6d28                	ld	a0,88(a0)
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	63c080e7          	jalr	1596(ra) # 80001786 <copyinstr>
    80003152:	00054e63          	bltz	a0,8000316e <fetchstr+0x48>
  return strlen(buf);
    80003156:	8526                	mv	a0,s1
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	cf6080e7          	jalr	-778(ra) # 80000e4e <strlen>
}
    80003160:	70a2                	ld	ra,40(sp)
    80003162:	7402                	ld	s0,32(sp)
    80003164:	64e2                	ld	s1,24(sp)
    80003166:	6942                	ld	s2,16(sp)
    80003168:	69a2                	ld	s3,8(sp)
    8000316a:	6145                	addi	sp,sp,48
    8000316c:	8082                	ret
    return -1;
    8000316e:	557d                	li	a0,-1
    80003170:	bfc5                	j	80003160 <fetchstr+0x3a>

0000000080003172 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003172:	1101                	addi	sp,sp,-32
    80003174:	ec06                	sd	ra,24(sp)
    80003176:	e822                	sd	s0,16(sp)
    80003178:	e426                	sd	s1,8(sp)
    8000317a:	1000                	addi	s0,sp,32
    8000317c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	eee080e7          	jalr	-274(ra) # 8000306c <argraw>
    80003186:	c088                	sw	a0,0(s1)
}
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	64a2                	ld	s1,8(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	ece080e7          	jalr	-306(ra) # 8000306c <argraw>
    800031a6:	e088                	sd	a0,0(s1)
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret

00000000800031b2 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800031b2:	7179                	addi	sp,sp,-48
    800031b4:	f406                	sd	ra,40(sp)
    800031b6:	f022                	sd	s0,32(sp)
    800031b8:	ec26                	sd	s1,24(sp)
    800031ba:	e84a                	sd	s2,16(sp)
    800031bc:	1800                	addi	s0,sp,48
    800031be:	84ae                	mv	s1,a1
    800031c0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031c2:	fd840593          	addi	a1,s0,-40
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	fcc080e7          	jalr	-52(ra) # 80003192 <argaddr>
  return fetchstr(addr, buf, max);
    800031ce:	864a                	mv	a2,s2
    800031d0:	85a6                	mv	a1,s1
    800031d2:	fd843503          	ld	a0,-40(s0)
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	f50080e7          	jalr	-176(ra) # 80003126 <fetchstr>
}
    800031de:	70a2                	ld	ra,40(sp)
    800031e0:	7402                	ld	s0,32(sp)
    800031e2:	64e2                	ld	s1,24(sp)
    800031e4:	6942                	ld	s2,16(sp)
    800031e6:	6145                	addi	sp,sp,48
    800031e8:	8082                	ret

00000000800031ea <prompt_strace>:
    ///////////////////////////////////////////////////////////
    
};

void prompt_strace(struct proc *p, int num)
{
    800031ea:	715d                	addi	sp,sp,-80
    800031ec:	e486                	sd	ra,72(sp)
    800031ee:	e0a2                	sd	s0,64(sp)
    800031f0:	fc26                	sd	s1,56(sp)
    800031f2:	f84a                	sd	s2,48(sp)
    800031f4:	f44e                	sd	s3,40(sp)
    800031f6:	f052                	sd	s4,32(sp)
    800031f8:	ec56                	sd	s5,24(sp)
    800031fa:	0880                	addi	s0,sp,80
    800031fc:	8a2a                	mv	s4,a0
    800031fe:	892e                	mv	s2,a1
  printf("%d: syscall %s (", p->pid, syscall_info[num].name);
    80003200:	00459793          	slli	a5,a1,0x4
    80003204:	00006497          	auipc	s1,0x6
    80003208:	87448493          	addi	s1,s1,-1932 # 80008a78 <syscall_info>
    8000320c:	94be                	add	s1,s1,a5
    8000320e:	6090                	ld	a2,0(s1)
    80003210:	590c                	lw	a1,48(a0)
    80003212:	00005517          	auipc	a0,0x5
    80003216:	22650513          	addi	a0,a0,550 # 80008438 <states.0+0x150>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	370080e7          	jalr	880(ra) # 8000058a <printf>
  int arg;
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80003222:	449c                	lw	a5,8(s1)
    80003224:	06f05363          	blez	a5,8000328a <prompt_strace+0xa0>
    80003228:	4481                	li	s1,0
  {
    argint(i, &arg);
    if (i == syscall_info[num].numArgs - 1)
    8000322a:	00491593          	slli	a1,s2,0x4
    8000322e:	00006917          	auipc	s2,0x6
    80003232:	84a90913          	addi	s2,s2,-1974 # 80008a78 <syscall_info>
    80003236:	992e                	add	s2,s2,a1
      printf("%d", arg);
    else
      printf("%d ", arg);
    80003238:	00005997          	auipc	s3,0x5
    8000323c:	22098993          	addi	s3,s3,544 # 80008458 <states.0+0x170>
      printf("%d", arg);
    80003240:	00005a97          	auipc	s5,0x5
    80003244:	210a8a93          	addi	s5,s5,528 # 80008450 <states.0+0x168>
    80003248:	a829                	j	80003262 <prompt_strace+0x78>
    8000324a:	fbc42583          	lw	a1,-68(s0)
    8000324e:	8556                	mv	a0,s5
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	33a080e7          	jalr	826(ra) # 8000058a <printf>
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80003258:	2485                	addiw	s1,s1,1
    8000325a:	00892783          	lw	a5,8(s2)
    8000325e:	02f4d663          	bge	s1,a5,8000328a <prompt_strace+0xa0>
    argint(i, &arg);
    80003262:	fbc40593          	addi	a1,s0,-68
    80003266:	8526                	mv	a0,s1
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	f0a080e7          	jalr	-246(ra) # 80003172 <argint>
    if (i == syscall_info[num].numArgs - 1)
    80003270:	00892783          	lw	a5,8(s2)
    80003274:	37fd                	addiw	a5,a5,-1
    80003276:	fc978ae3          	beq	a5,s1,8000324a <prompt_strace+0x60>
      printf("%d ", arg);
    8000327a:	fbc42583          	lw	a1,-68(s0)
    8000327e:	854e                	mv	a0,s3
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	30a080e7          	jalr	778(ra) # 8000058a <printf>
    80003288:	bfc1                	j	80003258 <prompt_strace+0x6e>
  }
  printf(") -> %d\n", p->trapframe->a0);
    8000328a:	060a3783          	ld	a5,96(s4)
    8000328e:	7bac                	ld	a1,112(a5)
    80003290:	00005517          	auipc	a0,0x5
    80003294:	1d050513          	addi	a0,a0,464 # 80008460 <states.0+0x178>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2f2080e7          	jalr	754(ra) # 8000058a <printf>
  return;
}
    800032a0:	60a6                	ld	ra,72(sp)
    800032a2:	6406                	ld	s0,64(sp)
    800032a4:	74e2                	ld	s1,56(sp)
    800032a6:	7942                	ld	s2,48(sp)
    800032a8:	79a2                	ld	s3,40(sp)
    800032aa:	7a02                	ld	s4,32(sp)
    800032ac:	6ae2                	ld	s5,24(sp)
    800032ae:	6161                	addi	sp,sp,80
    800032b0:	8082                	ret

00000000800032b2 <syscall>:

void syscall(void)
{
    800032b2:	7179                	addi	sp,sp,-48
    800032b4:	f406                	sd	ra,40(sp)
    800032b6:	f022                	sd	s0,32(sp)
    800032b8:	ec26                	sd	s1,24(sp)
    800032ba:	e84a                	sd	s2,16(sp)
    800032bc:	e44e                	sd	s3,8(sp)
    800032be:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	786080e7          	jalr	1926(ra) # 80001a46 <myproc>
    800032c8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032ca:	06053983          	ld	s3,96(a0)
    800032ce:	0a89b783          	ld	a5,168(s3)
    800032d2:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800032d6:	37fd                	addiw	a5,a5,-1
    800032d8:	4765                	li	a4,25
    800032da:	02f76b63          	bltu	a4,a5,80003310 <syscall+0x5e>
    800032de:	00391713          	slli	a4,s2,0x3
    800032e2:	00005797          	auipc	a5,0x5
    800032e6:	2ae78793          	addi	a5,a5,686 # 80008590 <syscalls>
    800032ea:	97ba                	add	a5,a5,a4
    800032ec:	639c                	ld	a5,0(a5)
    800032ee:	c7b9                	beqz	a5,8000333c <syscall+0x8a>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800032f0:	9782                	jalr	a5
    800032f2:	06a9b823          	sd	a0,112(s3)
  {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }

  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && ((p->strace_bit>>num) & 1))
    800032f6:	1704a783          	lw	a5,368(s1)
    800032fa:	0127d7bb          	srlw	a5,a5,s2
    800032fe:	8b85                	andi	a5,a5,1
    80003300:	c79d                	beqz	a5,8000332e <syscall+0x7c>
  {
    prompt_strace(p, num);
    80003302:	85ca                	mv	a1,s2
    80003304:	8526                	mv	a0,s1
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	ee4080e7          	jalr	-284(ra) # 800031ea <prompt_strace>
  }
  return;
    8000330e:	a005                	j	8000332e <syscall+0x7c>
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80003310:	86ca                	mv	a3,s2
    80003312:	16050613          	addi	a2,a0,352
    80003316:	590c                	lw	a1,48(a0)
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	15850513          	addi	a0,a0,344 # 80008470 <states.0+0x188>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	26a080e7          	jalr	618(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80003328:	70bc                	ld	a5,96(s1)
    8000332a:	577d                	li	a4,-1
    8000332c:	fbb8                	sd	a4,112(a5)
}
    8000332e:	70a2                	ld	ra,40(sp)
    80003330:	7402                	ld	s0,32(sp)
    80003332:	64e2                	ld	s1,24(sp)
    80003334:	6942                	ld	s2,16(sp)
    80003336:	69a2                	ld	s3,8(sp)
    80003338:	6145                	addi	sp,sp,48
    8000333a:	8082                	ret
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    8000333c:	86ca                	mv	a3,s2
    8000333e:	16050613          	addi	a2,a0,352
    80003342:	590c                	lw	a1,48(a0)
    80003344:	00005517          	auipc	a0,0x5
    80003348:	12c50513          	addi	a0,a0,300 # 80008470 <states.0+0x188>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	23e080e7          	jalr	574(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80003354:	70bc                	ld	a5,96(s1)
    80003356:	577d                	li	a4,-1
    80003358:	fbb8                	sd	a4,112(a5)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && ((p->strace_bit>>num) & 1))
    8000335a:	00391713          	slli	a4,s2,0x3
    8000335e:	00005797          	auipc	a5,0x5
    80003362:	23278793          	addi	a5,a5,562 # 80008590 <syscalls>
    80003366:	97ba                	add	a5,a5,a4
    80003368:	639c                	ld	a5,0(a5)
    8000336a:	d3f1                	beqz	a5,8000332e <syscall+0x7c>
    8000336c:	b769                	j	800032f6 <syscall+0x44>

000000008000336e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000336e:	1101                	addi	sp,sp,-32
    80003370:	ec06                	sd	ra,24(sp)
    80003372:	e822                	sd	s0,16(sp)
    80003374:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003376:	fec40593          	addi	a1,s0,-20
    8000337a:	4501                	li	a0,0
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	df6080e7          	jalr	-522(ra) # 80003172 <argint>
  exit(n);
    80003384:	fec42503          	lw	a0,-20(s0)
    80003388:	fffff097          	auipc	ra,0xfffff
    8000338c:	162080e7          	jalr	354(ra) # 800024ea <exit>
  return 0;  // not reached
}
    80003390:	4501                	li	a0,0
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	6105                	addi	sp,sp,32
    80003398:	8082                	ret

000000008000339a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000339a:	1141                	addi	sp,sp,-16
    8000339c:	e406                	sd	ra,8(sp)
    8000339e:	e022                	sd	s0,0(sp)
    800033a0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	6a4080e7          	jalr	1700(ra) # 80001a46 <myproc>
}
    800033aa:	5908                	lw	a0,48(a0)
    800033ac:	60a2                	ld	ra,8(sp)
    800033ae:	6402                	ld	s0,0(sp)
    800033b0:	0141                	addi	sp,sp,16
    800033b2:	8082                	ret

00000000800033b4 <sys_fork>:

uint64
sys_fork(void)
{
    800033b4:	1141                	addi	sp,sp,-16
    800033b6:	e406                	sd	ra,8(sp)
    800033b8:	e022                	sd	s0,0(sp)
    800033ba:	0800                	addi	s0,sp,16
  return fork();
    800033bc:	fffff097          	auipc	ra,0xfffff
    800033c0:	ac6080e7          	jalr	-1338(ra) # 80001e82 <fork>
}
    800033c4:	60a2                	ld	ra,8(sp)
    800033c6:	6402                	ld	s0,0(sp)
    800033c8:	0141                	addi	sp,sp,16
    800033ca:	8082                	ret

00000000800033cc <sys_wait>:

uint64
sys_wait(void)
{
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800033d4:	fe840593          	addi	a1,s0,-24
    800033d8:	4501                	li	a0,0
    800033da:	00000097          	auipc	ra,0x0
    800033de:	db8080e7          	jalr	-584(ra) # 80003192 <argaddr>
  return wait(p);
    800033e2:	fe843503          	ld	a0,-24(s0)
    800033e6:	fffff097          	auipc	ra,0xfffff
    800033ea:	2aa080e7          	jalr	682(ra) # 80002690 <wait>
}
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	6105                	addi	sp,sp,32
    800033f4:	8082                	ret

00000000800033f6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033f6:	7179                	addi	sp,sp,-48
    800033f8:	f406                	sd	ra,40(sp)
    800033fa:	f022                	sd	s0,32(sp)
    800033fc:	ec26                	sd	s1,24(sp)
    800033fe:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003400:	fdc40593          	addi	a1,s0,-36
    80003404:	4501                	li	a0,0
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	d6c080e7          	jalr	-660(ra) # 80003172 <argint>
  addr = myproc()->sz;
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	638080e7          	jalr	1592(ra) # 80001a46 <myproc>
    80003416:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003418:	fdc42503          	lw	a0,-36(s0)
    8000341c:	fffff097          	auipc	ra,0xfffff
    80003420:	a0a080e7          	jalr	-1526(ra) # 80001e26 <growproc>
    80003424:	00054863          	bltz	a0,80003434 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003428:	8526                	mv	a0,s1
    8000342a:	70a2                	ld	ra,40(sp)
    8000342c:	7402                	ld	s0,32(sp)
    8000342e:	64e2                	ld	s1,24(sp)
    80003430:	6145                	addi	sp,sp,48
    80003432:	8082                	ret
    return -1;
    80003434:	54fd                	li	s1,-1
    80003436:	bfcd                	j	80003428 <sys_sbrk+0x32>

0000000080003438 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003438:	7139                	addi	sp,sp,-64
    8000343a:	fc06                	sd	ra,56(sp)
    8000343c:	f822                	sd	s0,48(sp)
    8000343e:	f426                	sd	s1,40(sp)
    80003440:	f04a                	sd	s2,32(sp)
    80003442:	ec4e                	sd	s3,24(sp)
    80003444:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003446:	fcc40593          	addi	a1,s0,-52
    8000344a:	4501                	li	a0,0
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	d26080e7          	jalr	-730(ra) # 80003172 <argint>
  acquire(&tickslock);
    80003454:	00015517          	auipc	a0,0x15
    80003458:	4cc50513          	addi	a0,a0,1228 # 80018920 <tickslock>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	77a080e7          	jalr	1914(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003464:	00006917          	auipc	s2,0x6
    80003468:	81c92903          	lw	s2,-2020(s2) # 80008c80 <ticks>
  while(ticks - ticks0 < n){
    8000346c:	fcc42783          	lw	a5,-52(s0)
    80003470:	cf9d                	beqz	a5,800034ae <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003472:	00015997          	auipc	s3,0x15
    80003476:	4ae98993          	addi	s3,s3,1198 # 80018920 <tickslock>
    8000347a:	00006497          	auipc	s1,0x6
    8000347e:	80648493          	addi	s1,s1,-2042 # 80008c80 <ticks>
    if(killed(myproc())){
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	5c4080e7          	jalr	1476(ra) # 80001a46 <myproc>
    8000348a:	fffff097          	auipc	ra,0xfffff
    8000348e:	1d4080e7          	jalr	468(ra) # 8000265e <killed>
    80003492:	ed15                	bnez	a0,800034ce <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003494:	85ce                	mv	a1,s3
    80003496:	8526                	mv	a0,s1
    80003498:	fffff097          	auipc	ra,0xfffff
    8000349c:	eec080e7          	jalr	-276(ra) # 80002384 <sleep>
  while(ticks - ticks0 < n){
    800034a0:	409c                	lw	a5,0(s1)
    800034a2:	412787bb          	subw	a5,a5,s2
    800034a6:	fcc42703          	lw	a4,-52(s0)
    800034aa:	fce7ece3          	bltu	a5,a4,80003482 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800034ae:	00015517          	auipc	a0,0x15
    800034b2:	47250513          	addi	a0,a0,1138 # 80018920 <tickslock>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
  return 0;
    800034be:	4501                	li	a0,0
}
    800034c0:	70e2                	ld	ra,56(sp)
    800034c2:	7442                	ld	s0,48(sp)
    800034c4:	74a2                	ld	s1,40(sp)
    800034c6:	7902                	ld	s2,32(sp)
    800034c8:	69e2                	ld	s3,24(sp)
    800034ca:	6121                	addi	sp,sp,64
    800034cc:	8082                	ret
      release(&tickslock);
    800034ce:	00015517          	auipc	a0,0x15
    800034d2:	45250513          	addi	a0,a0,1106 # 80018920 <tickslock>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
      return -1;
    800034de:	557d                	li	a0,-1
    800034e0:	b7c5                	j	800034c0 <sys_sleep+0x88>

00000000800034e2 <sys_kill>:

uint64
sys_kill(void)
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800034ea:	fec40593          	addi	a1,s0,-20
    800034ee:	4501                	li	a0,0
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	c82080e7          	jalr	-894(ra) # 80003172 <argint>
  return kill(pid);
    800034f8:	fec42503          	lw	a0,-20(s0)
    800034fc:	fffff097          	auipc	ra,0xfffff
    80003500:	0c4080e7          	jalr	196(ra) # 800025c0 <kill>
}
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret

000000008000350c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	e426                	sd	s1,8(sp)
    80003514:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003516:	00015517          	auipc	a0,0x15
    8000351a:	40a50513          	addi	a0,a0,1034 # 80018920 <tickslock>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	6b8080e7          	jalr	1720(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003526:	00005497          	auipc	s1,0x5
    8000352a:	75a4a483          	lw	s1,1882(s1) # 80008c80 <ticks>
  release(&tickslock);
    8000352e:	00015517          	auipc	a0,0x15
    80003532:	3f250513          	addi	a0,a0,1010 # 80018920 <tickslock>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	754080e7          	jalr	1876(ra) # 80000c8a <release>
  return xticks;
}
    8000353e:	02049513          	slli	a0,s1,0x20
    80003542:	9101                	srli	a0,a0,0x20
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	64a2                	ld	s1,8(sp)
    8000354a:	6105                	addi	sp,sp,32
    8000354c:	8082                	ret

000000008000354e <sys_strace>:

uint64
sys_strace(void)
{
    8000354e:	1101                	addi	sp,sp,-32
    80003550:	ec06                	sd	ra,24(sp)
    80003552:	e822                	sd	s0,16(sp)
    80003554:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003556:	fec40593          	addi	a1,s0,-20
    8000355a:	4501                	li	a0,0
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	c16080e7          	jalr	-1002(ra) # 80003172 <argint>
  strace(n);
    80003564:	fec42503          	lw	a0,-20(s0)
    80003568:	fffff097          	auipc	ra,0xfffff
    8000356c:	3b2080e7          	jalr	946(ra) # 8000291a <strace>
  return 0;
}
    80003570:	4501                	li	a0,0
    80003572:	60e2                	ld	ra,24(sp)
    80003574:	6442                	ld	s0,16(sp)
    80003576:	6105                	addi	sp,sp,32
    80003578:	8082                	ret

000000008000357a <sys_settickets>:

uint64
sys_settickets(void)
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003582:	fec40593          	addi	a1,s0,-20
    80003586:	4501                	li	a0,0
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	bea080e7          	jalr	-1046(ra) # 80003172 <argint>
  int m = settickets(n);
    80003590:	fec42503          	lw	a0,-20(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	3b2080e7          	jalr	946(ra) # 80002946 <settickets>

  if(m == n)  // correct number of tickets set
    8000359c:	fec42783          	lw	a5,-20(s0)
    800035a0:	40a78533          	sub	a0,a5,a0
    800035a4:	00a03533          	snez	a0,a0
    return 0;
  return -1;
}
    800035a8:	40a00533          	neg	a0,a0
    800035ac:	60e2                	ld	ra,24(sp)
    800035ae:	6442                	ld	s0,16(sp)
    800035b0:	6105                	addi	sp,sp,32
    800035b2:	8082                	ret

00000000800035b4 <sys_set_priority>:


uint64
sys_set_priority(void)
{
    800035b4:	1101                	addi	sp,sp,-32
    800035b6:	ec06                	sd	ra,24(sp)
    800035b8:	e822                	sd	s0,16(sp)
    800035ba:	1000                	addi	s0,sp,32
  int n, pid;
  argint(0, &n);
    800035bc:	fec40593          	addi	a1,s0,-20
    800035c0:	4501                	li	a0,0
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	bb0080e7          	jalr	-1104(ra) # 80003172 <argint>
  argint(1, &pid);
    800035ca:	fe840593          	addi	a1,s0,-24
    800035ce:	4505                	li	a0,1
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	ba2080e7          	jalr	-1118(ra) # 80003172 <argint>

  int prev_SP = set_priority(n, pid);
    800035d8:	fe842583          	lw	a1,-24(s0)
    800035dc:	fec42503          	lw	a0,-20(s0)
    800035e0:	fffff097          	auipc	ra,0xfffff
    800035e4:	4bc080e7          	jalr	1212(ra) # 80002a9c <set_priority>
  if (prev_SP > 100 || prev_SP < 0)
    800035e8:	2501                	sext.w	a0,a0
    800035ea:	06400793          	li	a5,100
    800035ee:	00a7b533          	sltu	a0,a5,a0
    return -1;
  return 0;
}
    800035f2:	40a00533          	neg	a0,a0
    800035f6:	60e2                	ld	ra,24(sp)
    800035f8:	6442                	ld	s0,16(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret

00000000800035fe <restore>:

/////////////////// IMPLEMENTED FOR SIGALARM ///////////////
void restore(){
    800035fe:	1141                	addi	sp,sp,-16
    80003600:	e406                	sd	ra,8(sp)
    80003602:	e022                	sd	s0,0(sp)
    80003604:	0800                	addi	s0,sp,16
  struct proc*p=myproc();
    80003606:	ffffe097          	auipc	ra,0xffffe
    8000360a:	440080e7          	jalr	1088(ra) # 80001a46 <myproc>

  p->trapframe_copy->kernel_satp = p->trapframe->kernel_satp;
    8000360e:	1d053783          	ld	a5,464(a0)
    80003612:	7138                	ld	a4,96(a0)
    80003614:	6318                	ld	a4,0(a4)
    80003616:	e398                	sd	a4,0(a5)
  p->trapframe_copy->kernel_sp = p->trapframe->kernel_sp;
    80003618:	1d053783          	ld	a5,464(a0)
    8000361c:	7138                	ld	a4,96(a0)
    8000361e:	6718                	ld	a4,8(a4)
    80003620:	e798                	sd	a4,8(a5)
  p->trapframe_copy->kernel_trap = p->trapframe->kernel_trap;
    80003622:	1d053783          	ld	a5,464(a0)
    80003626:	7138                	ld	a4,96(a0)
    80003628:	6b18                	ld	a4,16(a4)
    8000362a:	eb98                	sd	a4,16(a5)
  p->trapframe_copy->kernel_hartid = p->trapframe->kernel_hartid;
    8000362c:	1d053783          	ld	a5,464(a0)
    80003630:	7138                	ld	a4,96(a0)
    80003632:	7318                	ld	a4,32(a4)
    80003634:	f398                	sd	a4,32(a5)
  *(p->trapframe) = *(p->trapframe_copy);
    80003636:	1d053683          	ld	a3,464(a0)
    8000363a:	87b6                	mv	a5,a3
    8000363c:	7138                	ld	a4,96(a0)
    8000363e:	12068693          	addi	a3,a3,288
    80003642:	0007b803          	ld	a6,0(a5)
    80003646:	6788                	ld	a0,8(a5)
    80003648:	6b8c                	ld	a1,16(a5)
    8000364a:	6f90                	ld	a2,24(a5)
    8000364c:	01073023          	sd	a6,0(a4)
    80003650:	e708                	sd	a0,8(a4)
    80003652:	eb0c                	sd	a1,16(a4)
    80003654:	ef10                	sd	a2,24(a4)
    80003656:	02078793          	addi	a5,a5,32
    8000365a:	02070713          	addi	a4,a4,32
    8000365e:	fed792e3          	bne	a5,a3,80003642 <restore+0x44>
}
    80003662:	60a2                	ld	ra,8(sp)
    80003664:	6402                	ld	s0,0(sp)
    80003666:	0141                	addi	sp,sp,16
    80003668:	8082                	ret

000000008000366a <sys_sigreturn>:

uint64 sys_sigreturn(void){
    8000366a:	1141                	addi	sp,sp,-16
    8000366c:	e406                	sd	ra,8(sp)
    8000366e:	e022                	sd	s0,0(sp)
    80003670:	0800                	addi	s0,sp,16
  restore();
    80003672:	00000097          	auipc	ra,0x0
    80003676:	f8c080e7          	jalr	-116(ra) # 800035fe <restore>
  myproc()->alarm_is_set = 0;
    8000367a:	ffffe097          	auipc	ra,0xffffe
    8000367e:	3cc080e7          	jalr	972(ra) # 80001a46 <myproc>
    80003682:	1a051d23          	sh	zero,442(a0)
  return 0;
}
    80003686:	4501                	li	a0,0
    80003688:	60a2                	ld	ra,8(sp)
    8000368a:	6402                	ld	s0,0(sp)
    8000368c:	0141                	addi	sp,sp,16
    8000368e:	8082                	ret

0000000080003690 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003690:	7179                	addi	sp,sp,-48
    80003692:	f406                	sd	ra,40(sp)
    80003694:	f022                	sd	s0,32(sp)
    80003696:	ec26                	sd	s1,24(sp)
    80003698:	e84a                	sd	s2,16(sp)
    8000369a:	e44e                	sd	s3,8(sp)
    8000369c:	e052                	sd	s4,0(sp)
    8000369e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800036a0:	00005597          	auipc	a1,0x5
    800036a4:	fc858593          	addi	a1,a1,-56 # 80008668 <syscalls+0xd8>
    800036a8:	00015517          	auipc	a0,0x15
    800036ac:	29050513          	addi	a0,a0,656 # 80018938 <bcache>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	496080e7          	jalr	1174(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036b8:	0001d797          	auipc	a5,0x1d
    800036bc:	28078793          	addi	a5,a5,640 # 80020938 <bcache+0x8000>
    800036c0:	0001d717          	auipc	a4,0x1d
    800036c4:	4e070713          	addi	a4,a4,1248 # 80020ba0 <bcache+0x8268>
    800036c8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036cc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036d0:	00015497          	auipc	s1,0x15
    800036d4:	28048493          	addi	s1,s1,640 # 80018950 <bcache+0x18>
    b->next = bcache.head.next;
    800036d8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036da:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036dc:	00005a17          	auipc	s4,0x5
    800036e0:	f94a0a13          	addi	s4,s4,-108 # 80008670 <syscalls+0xe0>
    b->next = bcache.head.next;
    800036e4:	2b893783          	ld	a5,696(s2)
    800036e8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036ea:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036ee:	85d2                	mv	a1,s4
    800036f0:	01048513          	addi	a0,s1,16
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	4c8080e7          	jalr	1224(ra) # 80004bbc <initsleeplock>
    bcache.head.next->prev = b;
    800036fc:	2b893783          	ld	a5,696(s2)
    80003700:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003702:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003706:	45848493          	addi	s1,s1,1112
    8000370a:	fd349de3          	bne	s1,s3,800036e4 <binit+0x54>
  }
}
    8000370e:	70a2                	ld	ra,40(sp)
    80003710:	7402                	ld	s0,32(sp)
    80003712:	64e2                	ld	s1,24(sp)
    80003714:	6942                	ld	s2,16(sp)
    80003716:	69a2                	ld	s3,8(sp)
    80003718:	6a02                	ld	s4,0(sp)
    8000371a:	6145                	addi	sp,sp,48
    8000371c:	8082                	ret

000000008000371e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000371e:	7179                	addi	sp,sp,-48
    80003720:	f406                	sd	ra,40(sp)
    80003722:	f022                	sd	s0,32(sp)
    80003724:	ec26                	sd	s1,24(sp)
    80003726:	e84a                	sd	s2,16(sp)
    80003728:	e44e                	sd	s3,8(sp)
    8000372a:	1800                	addi	s0,sp,48
    8000372c:	892a                	mv	s2,a0
    8000372e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003730:	00015517          	auipc	a0,0x15
    80003734:	20850513          	addi	a0,a0,520 # 80018938 <bcache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	49e080e7          	jalr	1182(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003740:	0001d497          	auipc	s1,0x1d
    80003744:	4b04b483          	ld	s1,1200(s1) # 80020bf0 <bcache+0x82b8>
    80003748:	0001d797          	auipc	a5,0x1d
    8000374c:	45878793          	addi	a5,a5,1112 # 80020ba0 <bcache+0x8268>
    80003750:	02f48f63          	beq	s1,a5,8000378e <bread+0x70>
    80003754:	873e                	mv	a4,a5
    80003756:	a021                	j	8000375e <bread+0x40>
    80003758:	68a4                	ld	s1,80(s1)
    8000375a:	02e48a63          	beq	s1,a4,8000378e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000375e:	449c                	lw	a5,8(s1)
    80003760:	ff279ce3          	bne	a5,s2,80003758 <bread+0x3a>
    80003764:	44dc                	lw	a5,12(s1)
    80003766:	ff3799e3          	bne	a5,s3,80003758 <bread+0x3a>
      b->refcnt++;
    8000376a:	40bc                	lw	a5,64(s1)
    8000376c:	2785                	addiw	a5,a5,1
    8000376e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003770:	00015517          	auipc	a0,0x15
    80003774:	1c850513          	addi	a0,a0,456 # 80018938 <bcache>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	512080e7          	jalr	1298(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003780:	01048513          	addi	a0,s1,16
    80003784:	00001097          	auipc	ra,0x1
    80003788:	472080e7          	jalr	1138(ra) # 80004bf6 <acquiresleep>
      return b;
    8000378c:	a8b9                	j	800037ea <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000378e:	0001d497          	auipc	s1,0x1d
    80003792:	45a4b483          	ld	s1,1114(s1) # 80020be8 <bcache+0x82b0>
    80003796:	0001d797          	auipc	a5,0x1d
    8000379a:	40a78793          	addi	a5,a5,1034 # 80020ba0 <bcache+0x8268>
    8000379e:	00f48863          	beq	s1,a5,800037ae <bread+0x90>
    800037a2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800037a4:	40bc                	lw	a5,64(s1)
    800037a6:	cf81                	beqz	a5,800037be <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037a8:	64a4                	ld	s1,72(s1)
    800037aa:	fee49de3          	bne	s1,a4,800037a4 <bread+0x86>
  panic("bget: no buffers");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	eca50513          	addi	a0,a0,-310 # 80008678 <syscalls+0xe8>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d8a080e7          	jalr	-630(ra) # 80000540 <panic>
      b->dev = dev;
    800037be:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800037c2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800037c6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037ca:	4785                	li	a5,1
    800037cc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037ce:	00015517          	auipc	a0,0x15
    800037d2:	16a50513          	addi	a0,a0,362 # 80018938 <bcache>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	4b4080e7          	jalr	1204(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800037de:	01048513          	addi	a0,s1,16
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	414080e7          	jalr	1044(ra) # 80004bf6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037ea:	409c                	lw	a5,0(s1)
    800037ec:	cb89                	beqz	a5,800037fe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037ee:	8526                	mv	a0,s1
    800037f0:	70a2                	ld	ra,40(sp)
    800037f2:	7402                	ld	s0,32(sp)
    800037f4:	64e2                	ld	s1,24(sp)
    800037f6:	6942                	ld	s2,16(sp)
    800037f8:	69a2                	ld	s3,8(sp)
    800037fa:	6145                	addi	sp,sp,48
    800037fc:	8082                	ret
    virtio_disk_rw(b, 0);
    800037fe:	4581                	li	a1,0
    80003800:	8526                	mv	a0,s1
    80003802:	00003097          	auipc	ra,0x3
    80003806:	fe0080e7          	jalr	-32(ra) # 800067e2 <virtio_disk_rw>
    b->valid = 1;
    8000380a:	4785                	li	a5,1
    8000380c:	c09c                	sw	a5,0(s1)
  return b;
    8000380e:	b7c5                	j	800037ee <bread+0xd0>

0000000080003810 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	1000                	addi	s0,sp,32
    8000381a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000381c:	0541                	addi	a0,a0,16
    8000381e:	00001097          	auipc	ra,0x1
    80003822:	472080e7          	jalr	1138(ra) # 80004c90 <holdingsleep>
    80003826:	cd01                	beqz	a0,8000383e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003828:	4585                	li	a1,1
    8000382a:	8526                	mv	a0,s1
    8000382c:	00003097          	auipc	ra,0x3
    80003830:	fb6080e7          	jalr	-74(ra) # 800067e2 <virtio_disk_rw>
}
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret
    panic("bwrite");
    8000383e:	00005517          	auipc	a0,0x5
    80003842:	e5250513          	addi	a0,a0,-430 # 80008690 <syscalls+0x100>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	cfa080e7          	jalr	-774(ra) # 80000540 <panic>

000000008000384e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	e04a                	sd	s2,0(sp)
    80003858:	1000                	addi	s0,sp,32
    8000385a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000385c:	01050913          	addi	s2,a0,16
    80003860:	854a                	mv	a0,s2
    80003862:	00001097          	auipc	ra,0x1
    80003866:	42e080e7          	jalr	1070(ra) # 80004c90 <holdingsleep>
    8000386a:	c92d                	beqz	a0,800038dc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	3de080e7          	jalr	990(ra) # 80004c4c <releasesleep>

  acquire(&bcache.lock);
    80003876:	00015517          	auipc	a0,0x15
    8000387a:	0c250513          	addi	a0,a0,194 # 80018938 <bcache>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	358080e7          	jalr	856(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003886:	40bc                	lw	a5,64(s1)
    80003888:	37fd                	addiw	a5,a5,-1
    8000388a:	0007871b          	sext.w	a4,a5
    8000388e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003890:	eb05                	bnez	a4,800038c0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003892:	68bc                	ld	a5,80(s1)
    80003894:	64b8                	ld	a4,72(s1)
    80003896:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003898:	64bc                	ld	a5,72(s1)
    8000389a:	68b8                	ld	a4,80(s1)
    8000389c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000389e:	0001d797          	auipc	a5,0x1d
    800038a2:	09a78793          	addi	a5,a5,154 # 80020938 <bcache+0x8000>
    800038a6:	2b87b703          	ld	a4,696(a5)
    800038aa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038ac:	0001d717          	auipc	a4,0x1d
    800038b0:	2f470713          	addi	a4,a4,756 # 80020ba0 <bcache+0x8268>
    800038b4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038b6:	2b87b703          	ld	a4,696(a5)
    800038ba:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038bc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038c0:	00015517          	auipc	a0,0x15
    800038c4:	07850513          	addi	a0,a0,120 # 80018938 <bcache>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	3c2080e7          	jalr	962(ra) # 80000c8a <release>
}
    800038d0:	60e2                	ld	ra,24(sp)
    800038d2:	6442                	ld	s0,16(sp)
    800038d4:	64a2                	ld	s1,8(sp)
    800038d6:	6902                	ld	s2,0(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret
    panic("brelse");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	dbc50513          	addi	a0,a0,-580 # 80008698 <syscalls+0x108>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c5c080e7          	jalr	-932(ra) # 80000540 <panic>

00000000800038ec <bpin>:

void
bpin(struct buf *b) {
    800038ec:	1101                	addi	sp,sp,-32
    800038ee:	ec06                	sd	ra,24(sp)
    800038f0:	e822                	sd	s0,16(sp)
    800038f2:	e426                	sd	s1,8(sp)
    800038f4:	1000                	addi	s0,sp,32
    800038f6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038f8:	00015517          	auipc	a0,0x15
    800038fc:	04050513          	addi	a0,a0,64 # 80018938 <bcache>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	2d6080e7          	jalr	726(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003908:	40bc                	lw	a5,64(s1)
    8000390a:	2785                	addiw	a5,a5,1
    8000390c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000390e:	00015517          	auipc	a0,0x15
    80003912:	02a50513          	addi	a0,a0,42 # 80018938 <bcache>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	374080e7          	jalr	884(ra) # 80000c8a <release>
}
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	64a2                	ld	s1,8(sp)
    80003924:	6105                	addi	sp,sp,32
    80003926:	8082                	ret

0000000080003928 <bunpin>:

void
bunpin(struct buf *b) {
    80003928:	1101                	addi	sp,sp,-32
    8000392a:	ec06                	sd	ra,24(sp)
    8000392c:	e822                	sd	s0,16(sp)
    8000392e:	e426                	sd	s1,8(sp)
    80003930:	1000                	addi	s0,sp,32
    80003932:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003934:	00015517          	auipc	a0,0x15
    80003938:	00450513          	addi	a0,a0,4 # 80018938 <bcache>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	29a080e7          	jalr	666(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003944:	40bc                	lw	a5,64(s1)
    80003946:	37fd                	addiw	a5,a5,-1
    80003948:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000394a:	00015517          	auipc	a0,0x15
    8000394e:	fee50513          	addi	a0,a0,-18 # 80018938 <bcache>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	338080e7          	jalr	824(ra) # 80000c8a <release>
}
    8000395a:	60e2                	ld	ra,24(sp)
    8000395c:	6442                	ld	s0,16(sp)
    8000395e:	64a2                	ld	s1,8(sp)
    80003960:	6105                	addi	sp,sp,32
    80003962:	8082                	ret

0000000080003964 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003964:	1101                	addi	sp,sp,-32
    80003966:	ec06                	sd	ra,24(sp)
    80003968:	e822                	sd	s0,16(sp)
    8000396a:	e426                	sd	s1,8(sp)
    8000396c:	e04a                	sd	s2,0(sp)
    8000396e:	1000                	addi	s0,sp,32
    80003970:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003972:	00d5d59b          	srliw	a1,a1,0xd
    80003976:	0001d797          	auipc	a5,0x1d
    8000397a:	69e7a783          	lw	a5,1694(a5) # 80021014 <sb+0x1c>
    8000397e:	9dbd                	addw	a1,a1,a5
    80003980:	00000097          	auipc	ra,0x0
    80003984:	d9e080e7          	jalr	-610(ra) # 8000371e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003988:	0074f713          	andi	a4,s1,7
    8000398c:	4785                	li	a5,1
    8000398e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003992:	14ce                	slli	s1,s1,0x33
    80003994:	90d9                	srli	s1,s1,0x36
    80003996:	00950733          	add	a4,a0,s1
    8000399a:	05874703          	lbu	a4,88(a4)
    8000399e:	00e7f6b3          	and	a3,a5,a4
    800039a2:	c69d                	beqz	a3,800039d0 <bfree+0x6c>
    800039a4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800039a6:	94aa                	add	s1,s1,a0
    800039a8:	fff7c793          	not	a5,a5
    800039ac:	8f7d                	and	a4,a4,a5
    800039ae:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	126080e7          	jalr	294(ra) # 80004ad8 <log_write>
  brelse(bp);
    800039ba:	854a                	mv	a0,s2
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	e92080e7          	jalr	-366(ra) # 8000384e <brelse>
}
    800039c4:	60e2                	ld	ra,24(sp)
    800039c6:	6442                	ld	s0,16(sp)
    800039c8:	64a2                	ld	s1,8(sp)
    800039ca:	6902                	ld	s2,0(sp)
    800039cc:	6105                	addi	sp,sp,32
    800039ce:	8082                	ret
    panic("freeing free block");
    800039d0:	00005517          	auipc	a0,0x5
    800039d4:	cd050513          	addi	a0,a0,-816 # 800086a0 <syscalls+0x110>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	b68080e7          	jalr	-1176(ra) # 80000540 <panic>

00000000800039e0 <balloc>:
{
    800039e0:	711d                	addi	sp,sp,-96
    800039e2:	ec86                	sd	ra,88(sp)
    800039e4:	e8a2                	sd	s0,80(sp)
    800039e6:	e4a6                	sd	s1,72(sp)
    800039e8:	e0ca                	sd	s2,64(sp)
    800039ea:	fc4e                	sd	s3,56(sp)
    800039ec:	f852                	sd	s4,48(sp)
    800039ee:	f456                	sd	s5,40(sp)
    800039f0:	f05a                	sd	s6,32(sp)
    800039f2:	ec5e                	sd	s7,24(sp)
    800039f4:	e862                	sd	s8,16(sp)
    800039f6:	e466                	sd	s9,8(sp)
    800039f8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039fa:	0001d797          	auipc	a5,0x1d
    800039fe:	6027a783          	lw	a5,1538(a5) # 80020ffc <sb+0x4>
    80003a02:	cff5                	beqz	a5,80003afe <balloc+0x11e>
    80003a04:	8baa                	mv	s7,a0
    80003a06:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a08:	0001db17          	auipc	s6,0x1d
    80003a0c:	5f0b0b13          	addi	s6,s6,1520 # 80020ff8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a10:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a12:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a14:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a16:	6c89                	lui	s9,0x2
    80003a18:	a061                	j	80003aa0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a1a:	97ca                	add	a5,a5,s2
    80003a1c:	8e55                	or	a2,a2,a3
    80003a1e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	0b4080e7          	jalr	180(ra) # 80004ad8 <log_write>
        brelse(bp);
    80003a2c:	854a                	mv	a0,s2
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	e20080e7          	jalr	-480(ra) # 8000384e <brelse>
  bp = bread(dev, bno);
    80003a36:	85a6                	mv	a1,s1
    80003a38:	855e                	mv	a0,s7
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	ce4080e7          	jalr	-796(ra) # 8000371e <bread>
    80003a42:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a44:	40000613          	li	a2,1024
    80003a48:	4581                	li	a1,0
    80003a4a:	05850513          	addi	a0,a0,88
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	284080e7          	jalr	644(ra) # 80000cd2 <memset>
  log_write(bp);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	080080e7          	jalr	128(ra) # 80004ad8 <log_write>
  brelse(bp);
    80003a60:	854a                	mv	a0,s2
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	dec080e7          	jalr	-532(ra) # 8000384e <brelse>
}
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	60e6                	ld	ra,88(sp)
    80003a6e:	6446                	ld	s0,80(sp)
    80003a70:	64a6                	ld	s1,72(sp)
    80003a72:	6906                	ld	s2,64(sp)
    80003a74:	79e2                	ld	s3,56(sp)
    80003a76:	7a42                	ld	s4,48(sp)
    80003a78:	7aa2                	ld	s5,40(sp)
    80003a7a:	7b02                	ld	s6,32(sp)
    80003a7c:	6be2                	ld	s7,24(sp)
    80003a7e:	6c42                	ld	s8,16(sp)
    80003a80:	6ca2                	ld	s9,8(sp)
    80003a82:	6125                	addi	sp,sp,96
    80003a84:	8082                	ret
    brelse(bp);
    80003a86:	854a                	mv	a0,s2
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	dc6080e7          	jalr	-570(ra) # 8000384e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a90:	015c87bb          	addw	a5,s9,s5
    80003a94:	00078a9b          	sext.w	s5,a5
    80003a98:	004b2703          	lw	a4,4(s6)
    80003a9c:	06eaf163          	bgeu	s5,a4,80003afe <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003aa0:	41fad79b          	sraiw	a5,s5,0x1f
    80003aa4:	0137d79b          	srliw	a5,a5,0x13
    80003aa8:	015787bb          	addw	a5,a5,s5
    80003aac:	40d7d79b          	sraiw	a5,a5,0xd
    80003ab0:	01cb2583          	lw	a1,28(s6)
    80003ab4:	9dbd                	addw	a1,a1,a5
    80003ab6:	855e                	mv	a0,s7
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	c66080e7          	jalr	-922(ra) # 8000371e <bread>
    80003ac0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ac2:	004b2503          	lw	a0,4(s6)
    80003ac6:	000a849b          	sext.w	s1,s5
    80003aca:	8762                	mv	a4,s8
    80003acc:	faa4fde3          	bgeu	s1,a0,80003a86 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003ad0:	00777693          	andi	a3,a4,7
    80003ad4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ad8:	41f7579b          	sraiw	a5,a4,0x1f
    80003adc:	01d7d79b          	srliw	a5,a5,0x1d
    80003ae0:	9fb9                	addw	a5,a5,a4
    80003ae2:	4037d79b          	sraiw	a5,a5,0x3
    80003ae6:	00f90633          	add	a2,s2,a5
    80003aea:	05864603          	lbu	a2,88(a2)
    80003aee:	00c6f5b3          	and	a1,a3,a2
    80003af2:	d585                	beqz	a1,80003a1a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003af4:	2705                	addiw	a4,a4,1
    80003af6:	2485                	addiw	s1,s1,1
    80003af8:	fd471ae3          	bne	a4,s4,80003acc <balloc+0xec>
    80003afc:	b769                	j	80003a86 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	bba50513          	addi	a0,a0,-1094 # 800086b8 <syscalls+0x128>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a84080e7          	jalr	-1404(ra) # 8000058a <printf>
  return 0;
    80003b0e:	4481                	li	s1,0
    80003b10:	bfa9                	j	80003a6a <balloc+0x8a>

0000000080003b12 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b12:	7179                	addi	sp,sp,-48
    80003b14:	f406                	sd	ra,40(sp)
    80003b16:	f022                	sd	s0,32(sp)
    80003b18:	ec26                	sd	s1,24(sp)
    80003b1a:	e84a                	sd	s2,16(sp)
    80003b1c:	e44e                	sd	s3,8(sp)
    80003b1e:	e052                	sd	s4,0(sp)
    80003b20:	1800                	addi	s0,sp,48
    80003b22:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b24:	47ad                	li	a5,11
    80003b26:	02b7e863          	bltu	a5,a1,80003b56 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003b2a:	02059793          	slli	a5,a1,0x20
    80003b2e:	01e7d593          	srli	a1,a5,0x1e
    80003b32:	00b504b3          	add	s1,a0,a1
    80003b36:	0504a903          	lw	s2,80(s1)
    80003b3a:	06091e63          	bnez	s2,80003bb6 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003b3e:	4108                	lw	a0,0(a0)
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	ea0080e7          	jalr	-352(ra) # 800039e0 <balloc>
    80003b48:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b4c:	06090563          	beqz	s2,80003bb6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003b50:	0524a823          	sw	s2,80(s1)
    80003b54:	a08d                	j	80003bb6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b56:	ff45849b          	addiw	s1,a1,-12
    80003b5a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b5e:	0ff00793          	li	a5,255
    80003b62:	08e7e563          	bltu	a5,a4,80003bec <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b66:	08052903          	lw	s2,128(a0)
    80003b6a:	00091d63          	bnez	s2,80003b84 <bmap+0x72>
      addr = balloc(ip->dev);
    80003b6e:	4108                	lw	a0,0(a0)
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	e70080e7          	jalr	-400(ra) # 800039e0 <balloc>
    80003b78:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b7c:	02090d63          	beqz	s2,80003bb6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b80:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b84:	85ca                	mv	a1,s2
    80003b86:	0009a503          	lw	a0,0(s3)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	b94080e7          	jalr	-1132(ra) # 8000371e <bread>
    80003b92:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b94:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b98:	02049713          	slli	a4,s1,0x20
    80003b9c:	01e75593          	srli	a1,a4,0x1e
    80003ba0:	00b784b3          	add	s1,a5,a1
    80003ba4:	0004a903          	lw	s2,0(s1)
    80003ba8:	02090063          	beqz	s2,80003bc8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003bac:	8552                	mv	a0,s4
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	ca0080e7          	jalr	-864(ra) # 8000384e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	70a2                	ld	ra,40(sp)
    80003bba:	7402                	ld	s0,32(sp)
    80003bbc:	64e2                	ld	s1,24(sp)
    80003bbe:	6942                	ld	s2,16(sp)
    80003bc0:	69a2                	ld	s3,8(sp)
    80003bc2:	6a02                	ld	s4,0(sp)
    80003bc4:	6145                	addi	sp,sp,48
    80003bc6:	8082                	ret
      addr = balloc(ip->dev);
    80003bc8:	0009a503          	lw	a0,0(s3)
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	e14080e7          	jalr	-492(ra) # 800039e0 <balloc>
    80003bd4:	0005091b          	sext.w	s2,a0
      if(addr){
    80003bd8:	fc090ae3          	beqz	s2,80003bac <bmap+0x9a>
        a[bn] = addr;
    80003bdc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003be0:	8552                	mv	a0,s4
    80003be2:	00001097          	auipc	ra,0x1
    80003be6:	ef6080e7          	jalr	-266(ra) # 80004ad8 <log_write>
    80003bea:	b7c9                	j	80003bac <bmap+0x9a>
  panic("bmap: out of range");
    80003bec:	00005517          	auipc	a0,0x5
    80003bf0:	ae450513          	addi	a0,a0,-1308 # 800086d0 <syscalls+0x140>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	94c080e7          	jalr	-1716(ra) # 80000540 <panic>

0000000080003bfc <iget>:
{
    80003bfc:	7179                	addi	sp,sp,-48
    80003bfe:	f406                	sd	ra,40(sp)
    80003c00:	f022                	sd	s0,32(sp)
    80003c02:	ec26                	sd	s1,24(sp)
    80003c04:	e84a                	sd	s2,16(sp)
    80003c06:	e44e                	sd	s3,8(sp)
    80003c08:	e052                	sd	s4,0(sp)
    80003c0a:	1800                	addi	s0,sp,48
    80003c0c:	89aa                	mv	s3,a0
    80003c0e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c10:	0001d517          	auipc	a0,0x1d
    80003c14:	40850513          	addi	a0,a0,1032 # 80021018 <itable>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	fbe080e7          	jalr	-66(ra) # 80000bd6 <acquire>
  empty = 0;
    80003c20:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c22:	0001d497          	auipc	s1,0x1d
    80003c26:	40e48493          	addi	s1,s1,1038 # 80021030 <itable+0x18>
    80003c2a:	0001f697          	auipc	a3,0x1f
    80003c2e:	e9668693          	addi	a3,a3,-362 # 80022ac0 <log>
    80003c32:	a039                	j	80003c40 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c34:	02090b63          	beqz	s2,80003c6a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c38:	08848493          	addi	s1,s1,136
    80003c3c:	02d48a63          	beq	s1,a3,80003c70 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c40:	449c                	lw	a5,8(s1)
    80003c42:	fef059e3          	blez	a5,80003c34 <iget+0x38>
    80003c46:	4098                	lw	a4,0(s1)
    80003c48:	ff3716e3          	bne	a4,s3,80003c34 <iget+0x38>
    80003c4c:	40d8                	lw	a4,4(s1)
    80003c4e:	ff4713e3          	bne	a4,s4,80003c34 <iget+0x38>
      ip->ref++;
    80003c52:	2785                	addiw	a5,a5,1
    80003c54:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c56:	0001d517          	auipc	a0,0x1d
    80003c5a:	3c250513          	addi	a0,a0,962 # 80021018 <itable>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	02c080e7          	jalr	44(ra) # 80000c8a <release>
      return ip;
    80003c66:	8926                	mv	s2,s1
    80003c68:	a03d                	j	80003c96 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c6a:	f7f9                	bnez	a5,80003c38 <iget+0x3c>
    80003c6c:	8926                	mv	s2,s1
    80003c6e:	b7e9                	j	80003c38 <iget+0x3c>
  if(empty == 0)
    80003c70:	02090c63          	beqz	s2,80003ca8 <iget+0xac>
  ip->dev = dev;
    80003c74:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c78:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c7c:	4785                	li	a5,1
    80003c7e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c82:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c86:	0001d517          	auipc	a0,0x1d
    80003c8a:	39250513          	addi	a0,a0,914 # 80021018 <itable>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	ffc080e7          	jalr	-4(ra) # 80000c8a <release>
}
    80003c96:	854a                	mv	a0,s2
    80003c98:	70a2                	ld	ra,40(sp)
    80003c9a:	7402                	ld	s0,32(sp)
    80003c9c:	64e2                	ld	s1,24(sp)
    80003c9e:	6942                	ld	s2,16(sp)
    80003ca0:	69a2                	ld	s3,8(sp)
    80003ca2:	6a02                	ld	s4,0(sp)
    80003ca4:	6145                	addi	sp,sp,48
    80003ca6:	8082                	ret
    panic("iget: no inodes");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	a4050513          	addi	a0,a0,-1472 # 800086e8 <syscalls+0x158>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	890080e7          	jalr	-1904(ra) # 80000540 <panic>

0000000080003cb8 <fsinit>:
fsinit(int dev) {
    80003cb8:	7179                	addi	sp,sp,-48
    80003cba:	f406                	sd	ra,40(sp)
    80003cbc:	f022                	sd	s0,32(sp)
    80003cbe:	ec26                	sd	s1,24(sp)
    80003cc0:	e84a                	sd	s2,16(sp)
    80003cc2:	e44e                	sd	s3,8(sp)
    80003cc4:	1800                	addi	s0,sp,48
    80003cc6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cc8:	4585                	li	a1,1
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	a54080e7          	jalr	-1452(ra) # 8000371e <bread>
    80003cd2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003cd4:	0001d997          	auipc	s3,0x1d
    80003cd8:	32498993          	addi	s3,s3,804 # 80020ff8 <sb>
    80003cdc:	02000613          	li	a2,32
    80003ce0:	05850593          	addi	a1,a0,88
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	048080e7          	jalr	72(ra) # 80000d2e <memmove>
  brelse(bp);
    80003cee:	8526                	mv	a0,s1
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	b5e080e7          	jalr	-1186(ra) # 8000384e <brelse>
  if(sb.magic != FSMAGIC)
    80003cf8:	0009a703          	lw	a4,0(s3)
    80003cfc:	102037b7          	lui	a5,0x10203
    80003d00:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d04:	02f71263          	bne	a4,a5,80003d28 <fsinit+0x70>
  initlog(dev, &sb);
    80003d08:	0001d597          	auipc	a1,0x1d
    80003d0c:	2f058593          	addi	a1,a1,752 # 80020ff8 <sb>
    80003d10:	854a                	mv	a0,s2
    80003d12:	00001097          	auipc	ra,0x1
    80003d16:	b4a080e7          	jalr	-1206(ra) # 8000485c <initlog>
}
    80003d1a:	70a2                	ld	ra,40(sp)
    80003d1c:	7402                	ld	s0,32(sp)
    80003d1e:	64e2                	ld	s1,24(sp)
    80003d20:	6942                	ld	s2,16(sp)
    80003d22:	69a2                	ld	s3,8(sp)
    80003d24:	6145                	addi	sp,sp,48
    80003d26:	8082                	ret
    panic("invalid file system");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	9d050513          	addi	a0,a0,-1584 # 800086f8 <syscalls+0x168>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	810080e7          	jalr	-2032(ra) # 80000540 <panic>

0000000080003d38 <iinit>:
{
    80003d38:	7179                	addi	sp,sp,-48
    80003d3a:	f406                	sd	ra,40(sp)
    80003d3c:	f022                	sd	s0,32(sp)
    80003d3e:	ec26                	sd	s1,24(sp)
    80003d40:	e84a                	sd	s2,16(sp)
    80003d42:	e44e                	sd	s3,8(sp)
    80003d44:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d46:	00005597          	auipc	a1,0x5
    80003d4a:	9ca58593          	addi	a1,a1,-1590 # 80008710 <syscalls+0x180>
    80003d4e:	0001d517          	auipc	a0,0x1d
    80003d52:	2ca50513          	addi	a0,a0,714 # 80021018 <itable>
    80003d56:	ffffd097          	auipc	ra,0xffffd
    80003d5a:	df0080e7          	jalr	-528(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d5e:	0001d497          	auipc	s1,0x1d
    80003d62:	2e248493          	addi	s1,s1,738 # 80021040 <itable+0x28>
    80003d66:	0001f997          	auipc	s3,0x1f
    80003d6a:	d6a98993          	addi	s3,s3,-662 # 80022ad0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d6e:	00005917          	auipc	s2,0x5
    80003d72:	9aa90913          	addi	s2,s2,-1622 # 80008718 <syscalls+0x188>
    80003d76:	85ca                	mv	a1,s2
    80003d78:	8526                	mv	a0,s1
    80003d7a:	00001097          	auipc	ra,0x1
    80003d7e:	e42080e7          	jalr	-446(ra) # 80004bbc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d82:	08848493          	addi	s1,s1,136
    80003d86:	ff3498e3          	bne	s1,s3,80003d76 <iinit+0x3e>
}
    80003d8a:	70a2                	ld	ra,40(sp)
    80003d8c:	7402                	ld	s0,32(sp)
    80003d8e:	64e2                	ld	s1,24(sp)
    80003d90:	6942                	ld	s2,16(sp)
    80003d92:	69a2                	ld	s3,8(sp)
    80003d94:	6145                	addi	sp,sp,48
    80003d96:	8082                	ret

0000000080003d98 <ialloc>:
{
    80003d98:	715d                	addi	sp,sp,-80
    80003d9a:	e486                	sd	ra,72(sp)
    80003d9c:	e0a2                	sd	s0,64(sp)
    80003d9e:	fc26                	sd	s1,56(sp)
    80003da0:	f84a                	sd	s2,48(sp)
    80003da2:	f44e                	sd	s3,40(sp)
    80003da4:	f052                	sd	s4,32(sp)
    80003da6:	ec56                	sd	s5,24(sp)
    80003da8:	e85a                	sd	s6,16(sp)
    80003daa:	e45e                	sd	s7,8(sp)
    80003dac:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dae:	0001d717          	auipc	a4,0x1d
    80003db2:	25672703          	lw	a4,598(a4) # 80021004 <sb+0xc>
    80003db6:	4785                	li	a5,1
    80003db8:	04e7fa63          	bgeu	a5,a4,80003e0c <ialloc+0x74>
    80003dbc:	8aaa                	mv	s5,a0
    80003dbe:	8bae                	mv	s7,a1
    80003dc0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003dc2:	0001da17          	auipc	s4,0x1d
    80003dc6:	236a0a13          	addi	s4,s4,566 # 80020ff8 <sb>
    80003dca:	00048b1b          	sext.w	s6,s1
    80003dce:	0044d593          	srli	a1,s1,0x4
    80003dd2:	018a2783          	lw	a5,24(s4)
    80003dd6:	9dbd                	addw	a1,a1,a5
    80003dd8:	8556                	mv	a0,s5
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	944080e7          	jalr	-1724(ra) # 8000371e <bread>
    80003de2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003de4:	05850993          	addi	s3,a0,88
    80003de8:	00f4f793          	andi	a5,s1,15
    80003dec:	079a                	slli	a5,a5,0x6
    80003dee:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003df0:	00099783          	lh	a5,0(s3)
    80003df4:	c3a1                	beqz	a5,80003e34 <ialloc+0x9c>
    brelse(bp);
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	a58080e7          	jalr	-1448(ra) # 8000384e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dfe:	0485                	addi	s1,s1,1
    80003e00:	00ca2703          	lw	a4,12(s4)
    80003e04:	0004879b          	sext.w	a5,s1
    80003e08:	fce7e1e3          	bltu	a5,a4,80003dca <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003e0c:	00005517          	auipc	a0,0x5
    80003e10:	91450513          	addi	a0,a0,-1772 # 80008720 <syscalls+0x190>
    80003e14:	ffffc097          	auipc	ra,0xffffc
    80003e18:	776080e7          	jalr	1910(ra) # 8000058a <printf>
  return 0;
    80003e1c:	4501                	li	a0,0
}
    80003e1e:	60a6                	ld	ra,72(sp)
    80003e20:	6406                	ld	s0,64(sp)
    80003e22:	74e2                	ld	s1,56(sp)
    80003e24:	7942                	ld	s2,48(sp)
    80003e26:	79a2                	ld	s3,40(sp)
    80003e28:	7a02                	ld	s4,32(sp)
    80003e2a:	6ae2                	ld	s5,24(sp)
    80003e2c:	6b42                	ld	s6,16(sp)
    80003e2e:	6ba2                	ld	s7,8(sp)
    80003e30:	6161                	addi	sp,sp,80
    80003e32:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003e34:	04000613          	li	a2,64
    80003e38:	4581                	li	a1,0
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	e96080e7          	jalr	-362(ra) # 80000cd2 <memset>
      dip->type = type;
    80003e44:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e48:	854a                	mv	a0,s2
    80003e4a:	00001097          	auipc	ra,0x1
    80003e4e:	c8e080e7          	jalr	-882(ra) # 80004ad8 <log_write>
      brelse(bp);
    80003e52:	854a                	mv	a0,s2
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	9fa080e7          	jalr	-1542(ra) # 8000384e <brelse>
      return iget(dev, inum);
    80003e5c:	85da                	mv	a1,s6
    80003e5e:	8556                	mv	a0,s5
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	d9c080e7          	jalr	-612(ra) # 80003bfc <iget>
    80003e68:	bf5d                	j	80003e1e <ialloc+0x86>

0000000080003e6a <iupdate>:
{
    80003e6a:	1101                	addi	sp,sp,-32
    80003e6c:	ec06                	sd	ra,24(sp)
    80003e6e:	e822                	sd	s0,16(sp)
    80003e70:	e426                	sd	s1,8(sp)
    80003e72:	e04a                	sd	s2,0(sp)
    80003e74:	1000                	addi	s0,sp,32
    80003e76:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e78:	415c                	lw	a5,4(a0)
    80003e7a:	0047d79b          	srliw	a5,a5,0x4
    80003e7e:	0001d597          	auipc	a1,0x1d
    80003e82:	1925a583          	lw	a1,402(a1) # 80021010 <sb+0x18>
    80003e86:	9dbd                	addw	a1,a1,a5
    80003e88:	4108                	lw	a0,0(a0)
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	894080e7          	jalr	-1900(ra) # 8000371e <bread>
    80003e92:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e94:	05850793          	addi	a5,a0,88
    80003e98:	40d8                	lw	a4,4(s1)
    80003e9a:	8b3d                	andi	a4,a4,15
    80003e9c:	071a                	slli	a4,a4,0x6
    80003e9e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003ea0:	04449703          	lh	a4,68(s1)
    80003ea4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ea8:	04649703          	lh	a4,70(s1)
    80003eac:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003eb0:	04849703          	lh	a4,72(s1)
    80003eb4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003eb8:	04a49703          	lh	a4,74(s1)
    80003ebc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ec0:	44f8                	lw	a4,76(s1)
    80003ec2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ec4:	03400613          	li	a2,52
    80003ec8:	05048593          	addi	a1,s1,80
    80003ecc:	00c78513          	addi	a0,a5,12
    80003ed0:	ffffd097          	auipc	ra,0xffffd
    80003ed4:	e5e080e7          	jalr	-418(ra) # 80000d2e <memmove>
  log_write(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00001097          	auipc	ra,0x1
    80003ede:	bfe080e7          	jalr	-1026(ra) # 80004ad8 <log_write>
  brelse(bp);
    80003ee2:	854a                	mv	a0,s2
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	96a080e7          	jalr	-1686(ra) # 8000384e <brelse>
}
    80003eec:	60e2                	ld	ra,24(sp)
    80003eee:	6442                	ld	s0,16(sp)
    80003ef0:	64a2                	ld	s1,8(sp)
    80003ef2:	6902                	ld	s2,0(sp)
    80003ef4:	6105                	addi	sp,sp,32
    80003ef6:	8082                	ret

0000000080003ef8 <idup>:
{
    80003ef8:	1101                	addi	sp,sp,-32
    80003efa:	ec06                	sd	ra,24(sp)
    80003efc:	e822                	sd	s0,16(sp)
    80003efe:	e426                	sd	s1,8(sp)
    80003f00:	1000                	addi	s0,sp,32
    80003f02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f04:	0001d517          	auipc	a0,0x1d
    80003f08:	11450513          	addi	a0,a0,276 # 80021018 <itable>
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	cca080e7          	jalr	-822(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003f14:	449c                	lw	a5,8(s1)
    80003f16:	2785                	addiw	a5,a5,1
    80003f18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f1a:	0001d517          	auipc	a0,0x1d
    80003f1e:	0fe50513          	addi	a0,a0,254 # 80021018 <itable>
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	d68080e7          	jalr	-664(ra) # 80000c8a <release>
}
    80003f2a:	8526                	mv	a0,s1
    80003f2c:	60e2                	ld	ra,24(sp)
    80003f2e:	6442                	ld	s0,16(sp)
    80003f30:	64a2                	ld	s1,8(sp)
    80003f32:	6105                	addi	sp,sp,32
    80003f34:	8082                	ret

0000000080003f36 <ilock>:
{
    80003f36:	1101                	addi	sp,sp,-32
    80003f38:	ec06                	sd	ra,24(sp)
    80003f3a:	e822                	sd	s0,16(sp)
    80003f3c:	e426                	sd	s1,8(sp)
    80003f3e:	e04a                	sd	s2,0(sp)
    80003f40:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f42:	c115                	beqz	a0,80003f66 <ilock+0x30>
    80003f44:	84aa                	mv	s1,a0
    80003f46:	451c                	lw	a5,8(a0)
    80003f48:	00f05f63          	blez	a5,80003f66 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f4c:	0541                	addi	a0,a0,16
    80003f4e:	00001097          	auipc	ra,0x1
    80003f52:	ca8080e7          	jalr	-856(ra) # 80004bf6 <acquiresleep>
  if(ip->valid == 0){
    80003f56:	40bc                	lw	a5,64(s1)
    80003f58:	cf99                	beqz	a5,80003f76 <ilock+0x40>
}
    80003f5a:	60e2                	ld	ra,24(sp)
    80003f5c:	6442                	ld	s0,16(sp)
    80003f5e:	64a2                	ld	s1,8(sp)
    80003f60:	6902                	ld	s2,0(sp)
    80003f62:	6105                	addi	sp,sp,32
    80003f64:	8082                	ret
    panic("ilock");
    80003f66:	00004517          	auipc	a0,0x4
    80003f6a:	7d250513          	addi	a0,a0,2002 # 80008738 <syscalls+0x1a8>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5d2080e7          	jalr	1490(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f76:	40dc                	lw	a5,4(s1)
    80003f78:	0047d79b          	srliw	a5,a5,0x4
    80003f7c:	0001d597          	auipc	a1,0x1d
    80003f80:	0945a583          	lw	a1,148(a1) # 80021010 <sb+0x18>
    80003f84:	9dbd                	addw	a1,a1,a5
    80003f86:	4088                	lw	a0,0(s1)
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	796080e7          	jalr	1942(ra) # 8000371e <bread>
    80003f90:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f92:	05850593          	addi	a1,a0,88
    80003f96:	40dc                	lw	a5,4(s1)
    80003f98:	8bbd                	andi	a5,a5,15
    80003f9a:	079a                	slli	a5,a5,0x6
    80003f9c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f9e:	00059783          	lh	a5,0(a1)
    80003fa2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003fa6:	00259783          	lh	a5,2(a1)
    80003faa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003fae:	00459783          	lh	a5,4(a1)
    80003fb2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fb6:	00659783          	lh	a5,6(a1)
    80003fba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fbe:	459c                	lw	a5,8(a1)
    80003fc0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fc2:	03400613          	li	a2,52
    80003fc6:	05b1                	addi	a1,a1,12
    80003fc8:	05048513          	addi	a0,s1,80
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	d62080e7          	jalr	-670(ra) # 80000d2e <memmove>
    brelse(bp);
    80003fd4:	854a                	mv	a0,s2
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	878080e7          	jalr	-1928(ra) # 8000384e <brelse>
    ip->valid = 1;
    80003fde:	4785                	li	a5,1
    80003fe0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fe2:	04449783          	lh	a5,68(s1)
    80003fe6:	fbb5                	bnez	a5,80003f5a <ilock+0x24>
      panic("ilock: no type");
    80003fe8:	00004517          	auipc	a0,0x4
    80003fec:	75850513          	addi	a0,a0,1880 # 80008740 <syscalls+0x1b0>
    80003ff0:	ffffc097          	auipc	ra,0xffffc
    80003ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080003ff8 <iunlock>:
{
    80003ff8:	1101                	addi	sp,sp,-32
    80003ffa:	ec06                	sd	ra,24(sp)
    80003ffc:	e822                	sd	s0,16(sp)
    80003ffe:	e426                	sd	s1,8(sp)
    80004000:	e04a                	sd	s2,0(sp)
    80004002:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004004:	c905                	beqz	a0,80004034 <iunlock+0x3c>
    80004006:	84aa                	mv	s1,a0
    80004008:	01050913          	addi	s2,a0,16
    8000400c:	854a                	mv	a0,s2
    8000400e:	00001097          	auipc	ra,0x1
    80004012:	c82080e7          	jalr	-894(ra) # 80004c90 <holdingsleep>
    80004016:	cd19                	beqz	a0,80004034 <iunlock+0x3c>
    80004018:	449c                	lw	a5,8(s1)
    8000401a:	00f05d63          	blez	a5,80004034 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000401e:	854a                	mv	a0,s2
    80004020:	00001097          	auipc	ra,0x1
    80004024:	c2c080e7          	jalr	-980(ra) # 80004c4c <releasesleep>
}
    80004028:	60e2                	ld	ra,24(sp)
    8000402a:	6442                	ld	s0,16(sp)
    8000402c:	64a2                	ld	s1,8(sp)
    8000402e:	6902                	ld	s2,0(sp)
    80004030:	6105                	addi	sp,sp,32
    80004032:	8082                	ret
    panic("iunlock");
    80004034:	00004517          	auipc	a0,0x4
    80004038:	71c50513          	addi	a0,a0,1820 # 80008750 <syscalls+0x1c0>
    8000403c:	ffffc097          	auipc	ra,0xffffc
    80004040:	504080e7          	jalr	1284(ra) # 80000540 <panic>

0000000080004044 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004044:	7179                	addi	sp,sp,-48
    80004046:	f406                	sd	ra,40(sp)
    80004048:	f022                	sd	s0,32(sp)
    8000404a:	ec26                	sd	s1,24(sp)
    8000404c:	e84a                	sd	s2,16(sp)
    8000404e:	e44e                	sd	s3,8(sp)
    80004050:	e052                	sd	s4,0(sp)
    80004052:	1800                	addi	s0,sp,48
    80004054:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004056:	05050493          	addi	s1,a0,80
    8000405a:	08050913          	addi	s2,a0,128
    8000405e:	a021                	j	80004066 <itrunc+0x22>
    80004060:	0491                	addi	s1,s1,4
    80004062:	01248d63          	beq	s1,s2,8000407c <itrunc+0x38>
    if(ip->addrs[i]){
    80004066:	408c                	lw	a1,0(s1)
    80004068:	dde5                	beqz	a1,80004060 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000406a:	0009a503          	lw	a0,0(s3)
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	8f6080e7          	jalr	-1802(ra) # 80003964 <bfree>
      ip->addrs[i] = 0;
    80004076:	0004a023          	sw	zero,0(s1)
    8000407a:	b7dd                	j	80004060 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000407c:	0809a583          	lw	a1,128(s3)
    80004080:	e185                	bnez	a1,800040a0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004082:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004086:	854e                	mv	a0,s3
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	de2080e7          	jalr	-542(ra) # 80003e6a <iupdate>
}
    80004090:	70a2                	ld	ra,40(sp)
    80004092:	7402                	ld	s0,32(sp)
    80004094:	64e2                	ld	s1,24(sp)
    80004096:	6942                	ld	s2,16(sp)
    80004098:	69a2                	ld	s3,8(sp)
    8000409a:	6a02                	ld	s4,0(sp)
    8000409c:	6145                	addi	sp,sp,48
    8000409e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800040a0:	0009a503          	lw	a0,0(s3)
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	67a080e7          	jalr	1658(ra) # 8000371e <bread>
    800040ac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800040ae:	05850493          	addi	s1,a0,88
    800040b2:	45850913          	addi	s2,a0,1112
    800040b6:	a021                	j	800040be <itrunc+0x7a>
    800040b8:	0491                	addi	s1,s1,4
    800040ba:	01248b63          	beq	s1,s2,800040d0 <itrunc+0x8c>
      if(a[j])
    800040be:	408c                	lw	a1,0(s1)
    800040c0:	dde5                	beqz	a1,800040b8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800040c2:	0009a503          	lw	a0,0(s3)
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	89e080e7          	jalr	-1890(ra) # 80003964 <bfree>
    800040ce:	b7ed                	j	800040b8 <itrunc+0x74>
    brelse(bp);
    800040d0:	8552                	mv	a0,s4
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	77c080e7          	jalr	1916(ra) # 8000384e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040da:	0809a583          	lw	a1,128(s3)
    800040de:	0009a503          	lw	a0,0(s3)
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	882080e7          	jalr	-1918(ra) # 80003964 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040ea:	0809a023          	sw	zero,128(s3)
    800040ee:	bf51                	j	80004082 <itrunc+0x3e>

00000000800040f0 <iput>:
{
    800040f0:	1101                	addi	sp,sp,-32
    800040f2:	ec06                	sd	ra,24(sp)
    800040f4:	e822                	sd	s0,16(sp)
    800040f6:	e426                	sd	s1,8(sp)
    800040f8:	e04a                	sd	s2,0(sp)
    800040fa:	1000                	addi	s0,sp,32
    800040fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040fe:	0001d517          	auipc	a0,0x1d
    80004102:	f1a50513          	addi	a0,a0,-230 # 80021018 <itable>
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000410e:	4498                	lw	a4,8(s1)
    80004110:	4785                	li	a5,1
    80004112:	02f70363          	beq	a4,a5,80004138 <iput+0x48>
  ip->ref--;
    80004116:	449c                	lw	a5,8(s1)
    80004118:	37fd                	addiw	a5,a5,-1
    8000411a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000411c:	0001d517          	auipc	a0,0x1d
    80004120:	efc50513          	addi	a0,a0,-260 # 80021018 <itable>
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	b66080e7          	jalr	-1178(ra) # 80000c8a <release>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6902                	ld	s2,0(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004138:	40bc                	lw	a5,64(s1)
    8000413a:	dff1                	beqz	a5,80004116 <iput+0x26>
    8000413c:	04a49783          	lh	a5,74(s1)
    80004140:	fbf9                	bnez	a5,80004116 <iput+0x26>
    acquiresleep(&ip->lock);
    80004142:	01048913          	addi	s2,s1,16
    80004146:	854a                	mv	a0,s2
    80004148:	00001097          	auipc	ra,0x1
    8000414c:	aae080e7          	jalr	-1362(ra) # 80004bf6 <acquiresleep>
    release(&itable.lock);
    80004150:	0001d517          	auipc	a0,0x1d
    80004154:	ec850513          	addi	a0,a0,-312 # 80021018 <itable>
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	b32080e7          	jalr	-1230(ra) # 80000c8a <release>
    itrunc(ip);
    80004160:	8526                	mv	a0,s1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	ee2080e7          	jalr	-286(ra) # 80004044 <itrunc>
    ip->type = 0;
    8000416a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000416e:	8526                	mv	a0,s1
    80004170:	00000097          	auipc	ra,0x0
    80004174:	cfa080e7          	jalr	-774(ra) # 80003e6a <iupdate>
    ip->valid = 0;
    80004178:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000417c:	854a                	mv	a0,s2
    8000417e:	00001097          	auipc	ra,0x1
    80004182:	ace080e7          	jalr	-1330(ra) # 80004c4c <releasesleep>
    acquire(&itable.lock);
    80004186:	0001d517          	auipc	a0,0x1d
    8000418a:	e9250513          	addi	a0,a0,-366 # 80021018 <itable>
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	a48080e7          	jalr	-1464(ra) # 80000bd6 <acquire>
    80004196:	b741                	j	80004116 <iput+0x26>

0000000080004198 <iunlockput>:
{
    80004198:	1101                	addi	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	1000                	addi	s0,sp,32
    800041a2:	84aa                	mv	s1,a0
  iunlock(ip);
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	e54080e7          	jalr	-428(ra) # 80003ff8 <iunlock>
  iput(ip);
    800041ac:	8526                	mv	a0,s1
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	f42080e7          	jalr	-190(ra) # 800040f0 <iput>
}
    800041b6:	60e2                	ld	ra,24(sp)
    800041b8:	6442                	ld	s0,16(sp)
    800041ba:	64a2                	ld	s1,8(sp)
    800041bc:	6105                	addi	sp,sp,32
    800041be:	8082                	ret

00000000800041c0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041c0:	1141                	addi	sp,sp,-16
    800041c2:	e422                	sd	s0,8(sp)
    800041c4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041c6:	411c                	lw	a5,0(a0)
    800041c8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041ca:	415c                	lw	a5,4(a0)
    800041cc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041ce:	04451783          	lh	a5,68(a0)
    800041d2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041d6:	04a51783          	lh	a5,74(a0)
    800041da:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041de:	04c56783          	lwu	a5,76(a0)
    800041e2:	e99c                	sd	a5,16(a1)
}
    800041e4:	6422                	ld	s0,8(sp)
    800041e6:	0141                	addi	sp,sp,16
    800041e8:	8082                	ret

00000000800041ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041ea:	457c                	lw	a5,76(a0)
    800041ec:	0ed7e963          	bltu	a5,a3,800042de <readi+0xf4>
{
    800041f0:	7159                	addi	sp,sp,-112
    800041f2:	f486                	sd	ra,104(sp)
    800041f4:	f0a2                	sd	s0,96(sp)
    800041f6:	eca6                	sd	s1,88(sp)
    800041f8:	e8ca                	sd	s2,80(sp)
    800041fa:	e4ce                	sd	s3,72(sp)
    800041fc:	e0d2                	sd	s4,64(sp)
    800041fe:	fc56                	sd	s5,56(sp)
    80004200:	f85a                	sd	s6,48(sp)
    80004202:	f45e                	sd	s7,40(sp)
    80004204:	f062                	sd	s8,32(sp)
    80004206:	ec66                	sd	s9,24(sp)
    80004208:	e86a                	sd	s10,16(sp)
    8000420a:	e46e                	sd	s11,8(sp)
    8000420c:	1880                	addi	s0,sp,112
    8000420e:	8b2a                	mv	s6,a0
    80004210:	8bae                	mv	s7,a1
    80004212:	8a32                	mv	s4,a2
    80004214:	84b6                	mv	s1,a3
    80004216:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004218:	9f35                	addw	a4,a4,a3
    return 0;
    8000421a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000421c:	0ad76063          	bltu	a4,a3,800042bc <readi+0xd2>
  if(off + n > ip->size)
    80004220:	00e7f463          	bgeu	a5,a4,80004228 <readi+0x3e>
    n = ip->size - off;
    80004224:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004228:	0a0a8963          	beqz	s5,800042da <readi+0xf0>
    8000422c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000422e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004232:	5c7d                	li	s8,-1
    80004234:	a82d                	j	8000426e <readi+0x84>
    80004236:	020d1d93          	slli	s11,s10,0x20
    8000423a:	020ddd93          	srli	s11,s11,0x20
    8000423e:	05890613          	addi	a2,s2,88
    80004242:	86ee                	mv	a3,s11
    80004244:	963a                	add	a2,a2,a4
    80004246:	85d2                	mv	a1,s4
    80004248:	855e                	mv	a0,s7
    8000424a:	ffffe097          	auipc	ra,0xffffe
    8000424e:	574080e7          	jalr	1396(ra) # 800027be <either_copyout>
    80004252:	05850d63          	beq	a0,s8,800042ac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004256:	854a                	mv	a0,s2
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	5f6080e7          	jalr	1526(ra) # 8000384e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004260:	013d09bb          	addw	s3,s10,s3
    80004264:	009d04bb          	addw	s1,s10,s1
    80004268:	9a6e                	add	s4,s4,s11
    8000426a:	0559f763          	bgeu	s3,s5,800042b8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000426e:	00a4d59b          	srliw	a1,s1,0xa
    80004272:	855a                	mv	a0,s6
    80004274:	00000097          	auipc	ra,0x0
    80004278:	89e080e7          	jalr	-1890(ra) # 80003b12 <bmap>
    8000427c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004280:	cd85                	beqz	a1,800042b8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004282:	000b2503          	lw	a0,0(s6)
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	498080e7          	jalr	1176(ra) # 8000371e <bread>
    8000428e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004290:	3ff4f713          	andi	a4,s1,1023
    80004294:	40ec87bb          	subw	a5,s9,a4
    80004298:	413a86bb          	subw	a3,s5,s3
    8000429c:	8d3e                	mv	s10,a5
    8000429e:	2781                	sext.w	a5,a5
    800042a0:	0006861b          	sext.w	a2,a3
    800042a4:	f8f679e3          	bgeu	a2,a5,80004236 <readi+0x4c>
    800042a8:	8d36                	mv	s10,a3
    800042aa:	b771                	j	80004236 <readi+0x4c>
      brelse(bp);
    800042ac:	854a                	mv	a0,s2
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	5a0080e7          	jalr	1440(ra) # 8000384e <brelse>
      tot = -1;
    800042b6:	59fd                	li	s3,-1
  }
  return tot;
    800042b8:	0009851b          	sext.w	a0,s3
}
    800042bc:	70a6                	ld	ra,104(sp)
    800042be:	7406                	ld	s0,96(sp)
    800042c0:	64e6                	ld	s1,88(sp)
    800042c2:	6946                	ld	s2,80(sp)
    800042c4:	69a6                	ld	s3,72(sp)
    800042c6:	6a06                	ld	s4,64(sp)
    800042c8:	7ae2                	ld	s5,56(sp)
    800042ca:	7b42                	ld	s6,48(sp)
    800042cc:	7ba2                	ld	s7,40(sp)
    800042ce:	7c02                	ld	s8,32(sp)
    800042d0:	6ce2                	ld	s9,24(sp)
    800042d2:	6d42                	ld	s10,16(sp)
    800042d4:	6da2                	ld	s11,8(sp)
    800042d6:	6165                	addi	sp,sp,112
    800042d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042da:	89d6                	mv	s3,s5
    800042dc:	bff1                	j	800042b8 <readi+0xce>
    return 0;
    800042de:	4501                	li	a0,0
}
    800042e0:	8082                	ret

00000000800042e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042e2:	457c                	lw	a5,76(a0)
    800042e4:	10d7e863          	bltu	a5,a3,800043f4 <writei+0x112>
{
    800042e8:	7159                	addi	sp,sp,-112
    800042ea:	f486                	sd	ra,104(sp)
    800042ec:	f0a2                	sd	s0,96(sp)
    800042ee:	eca6                	sd	s1,88(sp)
    800042f0:	e8ca                	sd	s2,80(sp)
    800042f2:	e4ce                	sd	s3,72(sp)
    800042f4:	e0d2                	sd	s4,64(sp)
    800042f6:	fc56                	sd	s5,56(sp)
    800042f8:	f85a                	sd	s6,48(sp)
    800042fa:	f45e                	sd	s7,40(sp)
    800042fc:	f062                	sd	s8,32(sp)
    800042fe:	ec66                	sd	s9,24(sp)
    80004300:	e86a                	sd	s10,16(sp)
    80004302:	e46e                	sd	s11,8(sp)
    80004304:	1880                	addi	s0,sp,112
    80004306:	8aaa                	mv	s5,a0
    80004308:	8bae                	mv	s7,a1
    8000430a:	8a32                	mv	s4,a2
    8000430c:	8936                	mv	s2,a3
    8000430e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004310:	00e687bb          	addw	a5,a3,a4
    80004314:	0ed7e263          	bltu	a5,a3,800043f8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004318:	00043737          	lui	a4,0x43
    8000431c:	0ef76063          	bltu	a4,a5,800043fc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004320:	0c0b0863          	beqz	s6,800043f0 <writei+0x10e>
    80004324:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004326:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000432a:	5c7d                	li	s8,-1
    8000432c:	a091                	j	80004370 <writei+0x8e>
    8000432e:	020d1d93          	slli	s11,s10,0x20
    80004332:	020ddd93          	srli	s11,s11,0x20
    80004336:	05848513          	addi	a0,s1,88
    8000433a:	86ee                	mv	a3,s11
    8000433c:	8652                	mv	a2,s4
    8000433e:	85de                	mv	a1,s7
    80004340:	953a                	add	a0,a0,a4
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	4d2080e7          	jalr	1234(ra) # 80002814 <either_copyin>
    8000434a:	07850263          	beq	a0,s8,800043ae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000434e:	8526                	mv	a0,s1
    80004350:	00000097          	auipc	ra,0x0
    80004354:	788080e7          	jalr	1928(ra) # 80004ad8 <log_write>
    brelse(bp);
    80004358:	8526                	mv	a0,s1
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	4f4080e7          	jalr	1268(ra) # 8000384e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004362:	013d09bb          	addw	s3,s10,s3
    80004366:	012d093b          	addw	s2,s10,s2
    8000436a:	9a6e                	add	s4,s4,s11
    8000436c:	0569f663          	bgeu	s3,s6,800043b8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004370:	00a9559b          	srliw	a1,s2,0xa
    80004374:	8556                	mv	a0,s5
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	79c080e7          	jalr	1948(ra) # 80003b12 <bmap>
    8000437e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004382:	c99d                	beqz	a1,800043b8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004384:	000aa503          	lw	a0,0(s5)
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	396080e7          	jalr	918(ra) # 8000371e <bread>
    80004390:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004392:	3ff97713          	andi	a4,s2,1023
    80004396:	40ec87bb          	subw	a5,s9,a4
    8000439a:	413b06bb          	subw	a3,s6,s3
    8000439e:	8d3e                	mv	s10,a5
    800043a0:	2781                	sext.w	a5,a5
    800043a2:	0006861b          	sext.w	a2,a3
    800043a6:	f8f674e3          	bgeu	a2,a5,8000432e <writei+0x4c>
    800043aa:	8d36                	mv	s10,a3
    800043ac:	b749                	j	8000432e <writei+0x4c>
      brelse(bp);
    800043ae:	8526                	mv	a0,s1
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	49e080e7          	jalr	1182(ra) # 8000384e <brelse>
  }

  if(off > ip->size)
    800043b8:	04caa783          	lw	a5,76(s5)
    800043bc:	0127f463          	bgeu	a5,s2,800043c4 <writei+0xe2>
    ip->size = off;
    800043c0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043c4:	8556                	mv	a0,s5
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	aa4080e7          	jalr	-1372(ra) # 80003e6a <iupdate>

  return tot;
    800043ce:	0009851b          	sext.w	a0,s3
}
    800043d2:	70a6                	ld	ra,104(sp)
    800043d4:	7406                	ld	s0,96(sp)
    800043d6:	64e6                	ld	s1,88(sp)
    800043d8:	6946                	ld	s2,80(sp)
    800043da:	69a6                	ld	s3,72(sp)
    800043dc:	6a06                	ld	s4,64(sp)
    800043de:	7ae2                	ld	s5,56(sp)
    800043e0:	7b42                	ld	s6,48(sp)
    800043e2:	7ba2                	ld	s7,40(sp)
    800043e4:	7c02                	ld	s8,32(sp)
    800043e6:	6ce2                	ld	s9,24(sp)
    800043e8:	6d42                	ld	s10,16(sp)
    800043ea:	6da2                	ld	s11,8(sp)
    800043ec:	6165                	addi	sp,sp,112
    800043ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043f0:	89da                	mv	s3,s6
    800043f2:	bfc9                	j	800043c4 <writei+0xe2>
    return -1;
    800043f4:	557d                	li	a0,-1
}
    800043f6:	8082                	ret
    return -1;
    800043f8:	557d                	li	a0,-1
    800043fa:	bfe1                	j	800043d2 <writei+0xf0>
    return -1;
    800043fc:	557d                	li	a0,-1
    800043fe:	bfd1                	j	800043d2 <writei+0xf0>

0000000080004400 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004400:	1141                	addi	sp,sp,-16
    80004402:	e406                	sd	ra,8(sp)
    80004404:	e022                	sd	s0,0(sp)
    80004406:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004408:	4639                	li	a2,14
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	998080e7          	jalr	-1640(ra) # 80000da2 <strncmp>
}
    80004412:	60a2                	ld	ra,8(sp)
    80004414:	6402                	ld	s0,0(sp)
    80004416:	0141                	addi	sp,sp,16
    80004418:	8082                	ret

000000008000441a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000441a:	7139                	addi	sp,sp,-64
    8000441c:	fc06                	sd	ra,56(sp)
    8000441e:	f822                	sd	s0,48(sp)
    80004420:	f426                	sd	s1,40(sp)
    80004422:	f04a                	sd	s2,32(sp)
    80004424:	ec4e                	sd	s3,24(sp)
    80004426:	e852                	sd	s4,16(sp)
    80004428:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000442a:	04451703          	lh	a4,68(a0)
    8000442e:	4785                	li	a5,1
    80004430:	00f71a63          	bne	a4,a5,80004444 <dirlookup+0x2a>
    80004434:	892a                	mv	s2,a0
    80004436:	89ae                	mv	s3,a1
    80004438:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000443a:	457c                	lw	a5,76(a0)
    8000443c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000443e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004440:	e79d                	bnez	a5,8000446e <dirlookup+0x54>
    80004442:	a8a5                	j	800044ba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004444:	00004517          	auipc	a0,0x4
    80004448:	31450513          	addi	a0,a0,788 # 80008758 <syscalls+0x1c8>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	0f4080e7          	jalr	244(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004454:	00004517          	auipc	a0,0x4
    80004458:	31c50513          	addi	a0,a0,796 # 80008770 <syscalls+0x1e0>
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	0e4080e7          	jalr	228(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004464:	24c1                	addiw	s1,s1,16
    80004466:	04c92783          	lw	a5,76(s2)
    8000446a:	04f4f763          	bgeu	s1,a5,800044b8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000446e:	4741                	li	a4,16
    80004470:	86a6                	mv	a3,s1
    80004472:	fc040613          	addi	a2,s0,-64
    80004476:	4581                	li	a1,0
    80004478:	854a                	mv	a0,s2
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	d70080e7          	jalr	-656(ra) # 800041ea <readi>
    80004482:	47c1                	li	a5,16
    80004484:	fcf518e3          	bne	a0,a5,80004454 <dirlookup+0x3a>
    if(de.inum == 0)
    80004488:	fc045783          	lhu	a5,-64(s0)
    8000448c:	dfe1                	beqz	a5,80004464 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000448e:	fc240593          	addi	a1,s0,-62
    80004492:	854e                	mv	a0,s3
    80004494:	00000097          	auipc	ra,0x0
    80004498:	f6c080e7          	jalr	-148(ra) # 80004400 <namecmp>
    8000449c:	f561                	bnez	a0,80004464 <dirlookup+0x4a>
      if(poff)
    8000449e:	000a0463          	beqz	s4,800044a6 <dirlookup+0x8c>
        *poff = off;
    800044a2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800044a6:	fc045583          	lhu	a1,-64(s0)
    800044aa:	00092503          	lw	a0,0(s2)
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	74e080e7          	jalr	1870(ra) # 80003bfc <iget>
    800044b6:	a011                	j	800044ba <dirlookup+0xa0>
  return 0;
    800044b8:	4501                	li	a0,0
}
    800044ba:	70e2                	ld	ra,56(sp)
    800044bc:	7442                	ld	s0,48(sp)
    800044be:	74a2                	ld	s1,40(sp)
    800044c0:	7902                	ld	s2,32(sp)
    800044c2:	69e2                	ld	s3,24(sp)
    800044c4:	6a42                	ld	s4,16(sp)
    800044c6:	6121                	addi	sp,sp,64
    800044c8:	8082                	ret

00000000800044ca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044ca:	711d                	addi	sp,sp,-96
    800044cc:	ec86                	sd	ra,88(sp)
    800044ce:	e8a2                	sd	s0,80(sp)
    800044d0:	e4a6                	sd	s1,72(sp)
    800044d2:	e0ca                	sd	s2,64(sp)
    800044d4:	fc4e                	sd	s3,56(sp)
    800044d6:	f852                	sd	s4,48(sp)
    800044d8:	f456                	sd	s5,40(sp)
    800044da:	f05a                	sd	s6,32(sp)
    800044dc:	ec5e                	sd	s7,24(sp)
    800044de:	e862                	sd	s8,16(sp)
    800044e0:	e466                	sd	s9,8(sp)
    800044e2:	e06a                	sd	s10,0(sp)
    800044e4:	1080                	addi	s0,sp,96
    800044e6:	84aa                	mv	s1,a0
    800044e8:	8b2e                	mv	s6,a1
    800044ea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044ec:	00054703          	lbu	a4,0(a0)
    800044f0:	02f00793          	li	a5,47
    800044f4:	02f70363          	beq	a4,a5,8000451a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044f8:	ffffd097          	auipc	ra,0xffffd
    800044fc:	54e080e7          	jalr	1358(ra) # 80001a46 <myproc>
    80004500:	15853503          	ld	a0,344(a0)
    80004504:	00000097          	auipc	ra,0x0
    80004508:	9f4080e7          	jalr	-1548(ra) # 80003ef8 <idup>
    8000450c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000450e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004512:	4cb5                	li	s9,13
  len = path - s;
    80004514:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004516:	4c05                	li	s8,1
    80004518:	a87d                	j	800045d6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000451a:	4585                	li	a1,1
    8000451c:	4505                	li	a0,1
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	6de080e7          	jalr	1758(ra) # 80003bfc <iget>
    80004526:	8a2a                	mv	s4,a0
    80004528:	b7dd                	j	8000450e <namex+0x44>
      iunlockput(ip);
    8000452a:	8552                	mv	a0,s4
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	c6c080e7          	jalr	-916(ra) # 80004198 <iunlockput>
      return 0;
    80004534:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004536:	8552                	mv	a0,s4
    80004538:	60e6                	ld	ra,88(sp)
    8000453a:	6446                	ld	s0,80(sp)
    8000453c:	64a6                	ld	s1,72(sp)
    8000453e:	6906                	ld	s2,64(sp)
    80004540:	79e2                	ld	s3,56(sp)
    80004542:	7a42                	ld	s4,48(sp)
    80004544:	7aa2                	ld	s5,40(sp)
    80004546:	7b02                	ld	s6,32(sp)
    80004548:	6be2                	ld	s7,24(sp)
    8000454a:	6c42                	ld	s8,16(sp)
    8000454c:	6ca2                	ld	s9,8(sp)
    8000454e:	6d02                	ld	s10,0(sp)
    80004550:	6125                	addi	sp,sp,96
    80004552:	8082                	ret
      iunlock(ip);
    80004554:	8552                	mv	a0,s4
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	aa2080e7          	jalr	-1374(ra) # 80003ff8 <iunlock>
      return ip;
    8000455e:	bfe1                	j	80004536 <namex+0x6c>
      iunlockput(ip);
    80004560:	8552                	mv	a0,s4
    80004562:	00000097          	auipc	ra,0x0
    80004566:	c36080e7          	jalr	-970(ra) # 80004198 <iunlockput>
      return 0;
    8000456a:	8a4e                	mv	s4,s3
    8000456c:	b7e9                	j	80004536 <namex+0x6c>
  len = path - s;
    8000456e:	40998633          	sub	a2,s3,s1
    80004572:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004576:	09acd863          	bge	s9,s10,80004606 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000457a:	4639                	li	a2,14
    8000457c:	85a6                	mv	a1,s1
    8000457e:	8556                	mv	a0,s5
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	7ae080e7          	jalr	1966(ra) # 80000d2e <memmove>
    80004588:	84ce                	mv	s1,s3
  while(*path == '/')
    8000458a:	0004c783          	lbu	a5,0(s1)
    8000458e:	01279763          	bne	a5,s2,8000459c <namex+0xd2>
    path++;
    80004592:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004594:	0004c783          	lbu	a5,0(s1)
    80004598:	ff278de3          	beq	a5,s2,80004592 <namex+0xc8>
    ilock(ip);
    8000459c:	8552                	mv	a0,s4
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	998080e7          	jalr	-1640(ra) # 80003f36 <ilock>
    if(ip->type != T_DIR){
    800045a6:	044a1783          	lh	a5,68(s4)
    800045aa:	f98790e3          	bne	a5,s8,8000452a <namex+0x60>
    if(nameiparent && *path == '\0'){
    800045ae:	000b0563          	beqz	s6,800045b8 <namex+0xee>
    800045b2:	0004c783          	lbu	a5,0(s1)
    800045b6:	dfd9                	beqz	a5,80004554 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045b8:	865e                	mv	a2,s7
    800045ba:	85d6                	mv	a1,s5
    800045bc:	8552                	mv	a0,s4
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	e5c080e7          	jalr	-420(ra) # 8000441a <dirlookup>
    800045c6:	89aa                	mv	s3,a0
    800045c8:	dd41                	beqz	a0,80004560 <namex+0x96>
    iunlockput(ip);
    800045ca:	8552                	mv	a0,s4
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	bcc080e7          	jalr	-1076(ra) # 80004198 <iunlockput>
    ip = next;
    800045d4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800045d6:	0004c783          	lbu	a5,0(s1)
    800045da:	01279763          	bne	a5,s2,800045e8 <namex+0x11e>
    path++;
    800045de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045e0:	0004c783          	lbu	a5,0(s1)
    800045e4:	ff278de3          	beq	a5,s2,800045de <namex+0x114>
  if(*path == 0)
    800045e8:	cb9d                	beqz	a5,8000461e <namex+0x154>
  while(*path != '/' && *path != 0)
    800045ea:	0004c783          	lbu	a5,0(s1)
    800045ee:	89a6                	mv	s3,s1
  len = path - s;
    800045f0:	8d5e                	mv	s10,s7
    800045f2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800045f4:	01278963          	beq	a5,s2,80004606 <namex+0x13c>
    800045f8:	dbbd                	beqz	a5,8000456e <namex+0xa4>
    path++;
    800045fa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800045fc:	0009c783          	lbu	a5,0(s3)
    80004600:	ff279ce3          	bne	a5,s2,800045f8 <namex+0x12e>
    80004604:	b7ad                	j	8000456e <namex+0xa4>
    memmove(name, s, len);
    80004606:	2601                	sext.w	a2,a2
    80004608:	85a6                	mv	a1,s1
    8000460a:	8556                	mv	a0,s5
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	722080e7          	jalr	1826(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004614:	9d56                	add	s10,s10,s5
    80004616:	000d0023          	sb	zero,0(s10)
    8000461a:	84ce                	mv	s1,s3
    8000461c:	b7bd                	j	8000458a <namex+0xc0>
  if(nameiparent){
    8000461e:	f00b0ce3          	beqz	s6,80004536 <namex+0x6c>
    iput(ip);
    80004622:	8552                	mv	a0,s4
    80004624:	00000097          	auipc	ra,0x0
    80004628:	acc080e7          	jalr	-1332(ra) # 800040f0 <iput>
    return 0;
    8000462c:	4a01                	li	s4,0
    8000462e:	b721                	j	80004536 <namex+0x6c>

0000000080004630 <dirlink>:
{
    80004630:	7139                	addi	sp,sp,-64
    80004632:	fc06                	sd	ra,56(sp)
    80004634:	f822                	sd	s0,48(sp)
    80004636:	f426                	sd	s1,40(sp)
    80004638:	f04a                	sd	s2,32(sp)
    8000463a:	ec4e                	sd	s3,24(sp)
    8000463c:	e852                	sd	s4,16(sp)
    8000463e:	0080                	addi	s0,sp,64
    80004640:	892a                	mv	s2,a0
    80004642:	8a2e                	mv	s4,a1
    80004644:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004646:	4601                	li	a2,0
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	dd2080e7          	jalr	-558(ra) # 8000441a <dirlookup>
    80004650:	e93d                	bnez	a0,800046c6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004652:	04c92483          	lw	s1,76(s2)
    80004656:	c49d                	beqz	s1,80004684 <dirlink+0x54>
    80004658:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000465a:	4741                	li	a4,16
    8000465c:	86a6                	mv	a3,s1
    8000465e:	fc040613          	addi	a2,s0,-64
    80004662:	4581                	li	a1,0
    80004664:	854a                	mv	a0,s2
    80004666:	00000097          	auipc	ra,0x0
    8000466a:	b84080e7          	jalr	-1148(ra) # 800041ea <readi>
    8000466e:	47c1                	li	a5,16
    80004670:	06f51163          	bne	a0,a5,800046d2 <dirlink+0xa2>
    if(de.inum == 0)
    80004674:	fc045783          	lhu	a5,-64(s0)
    80004678:	c791                	beqz	a5,80004684 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000467a:	24c1                	addiw	s1,s1,16
    8000467c:	04c92783          	lw	a5,76(s2)
    80004680:	fcf4ede3          	bltu	s1,a5,8000465a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004684:	4639                	li	a2,14
    80004686:	85d2                	mv	a1,s4
    80004688:	fc240513          	addi	a0,s0,-62
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	752080e7          	jalr	1874(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004694:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004698:	4741                	li	a4,16
    8000469a:	86a6                	mv	a3,s1
    8000469c:	fc040613          	addi	a2,s0,-64
    800046a0:	4581                	li	a1,0
    800046a2:	854a                	mv	a0,s2
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	c3e080e7          	jalr	-962(ra) # 800042e2 <writei>
    800046ac:	1541                	addi	a0,a0,-16
    800046ae:	00a03533          	snez	a0,a0
    800046b2:	40a00533          	neg	a0,a0
}
    800046b6:	70e2                	ld	ra,56(sp)
    800046b8:	7442                	ld	s0,48(sp)
    800046ba:	74a2                	ld	s1,40(sp)
    800046bc:	7902                	ld	s2,32(sp)
    800046be:	69e2                	ld	s3,24(sp)
    800046c0:	6a42                	ld	s4,16(sp)
    800046c2:	6121                	addi	sp,sp,64
    800046c4:	8082                	ret
    iput(ip);
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	a2a080e7          	jalr	-1494(ra) # 800040f0 <iput>
    return -1;
    800046ce:	557d                	li	a0,-1
    800046d0:	b7dd                	j	800046b6 <dirlink+0x86>
      panic("dirlink read");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	0ae50513          	addi	a0,a0,174 # 80008780 <syscalls+0x1f0>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e66080e7          	jalr	-410(ra) # 80000540 <panic>

00000000800046e2 <namei>:

struct inode*
namei(char *path)
{
    800046e2:	1101                	addi	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046ea:	fe040613          	addi	a2,s0,-32
    800046ee:	4581                	li	a1,0
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	dda080e7          	jalr	-550(ra) # 800044ca <namex>
}
    800046f8:	60e2                	ld	ra,24(sp)
    800046fa:	6442                	ld	s0,16(sp)
    800046fc:	6105                	addi	sp,sp,32
    800046fe:	8082                	ret

0000000080004700 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004700:	1141                	addi	sp,sp,-16
    80004702:	e406                	sd	ra,8(sp)
    80004704:	e022                	sd	s0,0(sp)
    80004706:	0800                	addi	s0,sp,16
    80004708:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000470a:	4585                	li	a1,1
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	dbe080e7          	jalr	-578(ra) # 800044ca <namex>
}
    80004714:	60a2                	ld	ra,8(sp)
    80004716:	6402                	ld	s0,0(sp)
    80004718:	0141                	addi	sp,sp,16
    8000471a:	8082                	ret

000000008000471c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000471c:	1101                	addi	sp,sp,-32
    8000471e:	ec06                	sd	ra,24(sp)
    80004720:	e822                	sd	s0,16(sp)
    80004722:	e426                	sd	s1,8(sp)
    80004724:	e04a                	sd	s2,0(sp)
    80004726:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004728:	0001e917          	auipc	s2,0x1e
    8000472c:	39890913          	addi	s2,s2,920 # 80022ac0 <log>
    80004730:	01892583          	lw	a1,24(s2)
    80004734:	02892503          	lw	a0,40(s2)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	fe6080e7          	jalr	-26(ra) # 8000371e <bread>
    80004740:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004742:	02c92683          	lw	a3,44(s2)
    80004746:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004748:	02d05863          	blez	a3,80004778 <write_head+0x5c>
    8000474c:	0001e797          	auipc	a5,0x1e
    80004750:	3a478793          	addi	a5,a5,932 # 80022af0 <log+0x30>
    80004754:	05c50713          	addi	a4,a0,92
    80004758:	36fd                	addiw	a3,a3,-1
    8000475a:	02069613          	slli	a2,a3,0x20
    8000475e:	01e65693          	srli	a3,a2,0x1e
    80004762:	0001e617          	auipc	a2,0x1e
    80004766:	39260613          	addi	a2,a2,914 # 80022af4 <log+0x34>
    8000476a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000476c:	4390                	lw	a2,0(a5)
    8000476e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004770:	0791                	addi	a5,a5,4
    80004772:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004774:	fed79ce3          	bne	a5,a3,8000476c <write_head+0x50>
  }
  bwrite(buf);
    80004778:	8526                	mv	a0,s1
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	096080e7          	jalr	150(ra) # 80003810 <bwrite>
  brelse(buf);
    80004782:	8526                	mv	a0,s1
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	0ca080e7          	jalr	202(ra) # 8000384e <brelse>
}
    8000478c:	60e2                	ld	ra,24(sp)
    8000478e:	6442                	ld	s0,16(sp)
    80004790:	64a2                	ld	s1,8(sp)
    80004792:	6902                	ld	s2,0(sp)
    80004794:	6105                	addi	sp,sp,32
    80004796:	8082                	ret

0000000080004798 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004798:	0001e797          	auipc	a5,0x1e
    8000479c:	3547a783          	lw	a5,852(a5) # 80022aec <log+0x2c>
    800047a0:	0af05d63          	blez	a5,8000485a <install_trans+0xc2>
{
    800047a4:	7139                	addi	sp,sp,-64
    800047a6:	fc06                	sd	ra,56(sp)
    800047a8:	f822                	sd	s0,48(sp)
    800047aa:	f426                	sd	s1,40(sp)
    800047ac:	f04a                	sd	s2,32(sp)
    800047ae:	ec4e                	sd	s3,24(sp)
    800047b0:	e852                	sd	s4,16(sp)
    800047b2:	e456                	sd	s5,8(sp)
    800047b4:	e05a                	sd	s6,0(sp)
    800047b6:	0080                	addi	s0,sp,64
    800047b8:	8b2a                	mv	s6,a0
    800047ba:	0001ea97          	auipc	s5,0x1e
    800047be:	336a8a93          	addi	s5,s5,822 # 80022af0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047c2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047c4:	0001e997          	auipc	s3,0x1e
    800047c8:	2fc98993          	addi	s3,s3,764 # 80022ac0 <log>
    800047cc:	a00d                	j	800047ee <install_trans+0x56>
    brelse(lbuf);
    800047ce:	854a                	mv	a0,s2
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	07e080e7          	jalr	126(ra) # 8000384e <brelse>
    brelse(dbuf);
    800047d8:	8526                	mv	a0,s1
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	074080e7          	jalr	116(ra) # 8000384e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e2:	2a05                	addiw	s4,s4,1
    800047e4:	0a91                	addi	s5,s5,4
    800047e6:	02c9a783          	lw	a5,44(s3)
    800047ea:	04fa5e63          	bge	s4,a5,80004846 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047ee:	0189a583          	lw	a1,24(s3)
    800047f2:	014585bb          	addw	a1,a1,s4
    800047f6:	2585                	addiw	a1,a1,1
    800047f8:	0289a503          	lw	a0,40(s3)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	f22080e7          	jalr	-222(ra) # 8000371e <bread>
    80004804:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004806:	000aa583          	lw	a1,0(s5)
    8000480a:	0289a503          	lw	a0,40(s3)
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	f10080e7          	jalr	-240(ra) # 8000371e <bread>
    80004816:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004818:	40000613          	li	a2,1024
    8000481c:	05890593          	addi	a1,s2,88
    80004820:	05850513          	addi	a0,a0,88
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	50a080e7          	jalr	1290(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000482c:	8526                	mv	a0,s1
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	fe2080e7          	jalr	-30(ra) # 80003810 <bwrite>
    if(recovering == 0)
    80004836:	f80b1ce3          	bnez	s6,800047ce <install_trans+0x36>
      bunpin(dbuf);
    8000483a:	8526                	mv	a0,s1
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	0ec080e7          	jalr	236(ra) # 80003928 <bunpin>
    80004844:	b769                	j	800047ce <install_trans+0x36>
}
    80004846:	70e2                	ld	ra,56(sp)
    80004848:	7442                	ld	s0,48(sp)
    8000484a:	74a2                	ld	s1,40(sp)
    8000484c:	7902                	ld	s2,32(sp)
    8000484e:	69e2                	ld	s3,24(sp)
    80004850:	6a42                	ld	s4,16(sp)
    80004852:	6aa2                	ld	s5,8(sp)
    80004854:	6b02                	ld	s6,0(sp)
    80004856:	6121                	addi	sp,sp,64
    80004858:	8082                	ret
    8000485a:	8082                	ret

000000008000485c <initlog>:
{
    8000485c:	7179                	addi	sp,sp,-48
    8000485e:	f406                	sd	ra,40(sp)
    80004860:	f022                	sd	s0,32(sp)
    80004862:	ec26                	sd	s1,24(sp)
    80004864:	e84a                	sd	s2,16(sp)
    80004866:	e44e                	sd	s3,8(sp)
    80004868:	1800                	addi	s0,sp,48
    8000486a:	892a                	mv	s2,a0
    8000486c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000486e:	0001e497          	auipc	s1,0x1e
    80004872:	25248493          	addi	s1,s1,594 # 80022ac0 <log>
    80004876:	00004597          	auipc	a1,0x4
    8000487a:	f1a58593          	addi	a1,a1,-230 # 80008790 <syscalls+0x200>
    8000487e:	8526                	mv	a0,s1
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	2c6080e7          	jalr	710(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004888:	0149a583          	lw	a1,20(s3)
    8000488c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000488e:	0109a783          	lw	a5,16(s3)
    80004892:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004894:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004898:	854a                	mv	a0,s2
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	e84080e7          	jalr	-380(ra) # 8000371e <bread>
  log.lh.n = lh->n;
    800048a2:	4d34                	lw	a3,88(a0)
    800048a4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048a6:	02d05663          	blez	a3,800048d2 <initlog+0x76>
    800048aa:	05c50793          	addi	a5,a0,92
    800048ae:	0001e717          	auipc	a4,0x1e
    800048b2:	24270713          	addi	a4,a4,578 # 80022af0 <log+0x30>
    800048b6:	36fd                	addiw	a3,a3,-1
    800048b8:	02069613          	slli	a2,a3,0x20
    800048bc:	01e65693          	srli	a3,a2,0x1e
    800048c0:	06050613          	addi	a2,a0,96
    800048c4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800048c6:	4390                	lw	a2,0(a5)
    800048c8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800048ca:	0791                	addi	a5,a5,4
    800048cc:	0711                	addi	a4,a4,4
    800048ce:	fed79ce3          	bne	a5,a3,800048c6 <initlog+0x6a>
  brelse(buf);
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	f7c080e7          	jalr	-132(ra) # 8000384e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048da:	4505                	li	a0,1
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	ebc080e7          	jalr	-324(ra) # 80004798 <install_trans>
  log.lh.n = 0;
    800048e4:	0001e797          	auipc	a5,0x1e
    800048e8:	2007a423          	sw	zero,520(a5) # 80022aec <log+0x2c>
  write_head(); // clear the log
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	e30080e7          	jalr	-464(ra) # 8000471c <write_head>
}
    800048f4:	70a2                	ld	ra,40(sp)
    800048f6:	7402                	ld	s0,32(sp)
    800048f8:	64e2                	ld	s1,24(sp)
    800048fa:	6942                	ld	s2,16(sp)
    800048fc:	69a2                	ld	s3,8(sp)
    800048fe:	6145                	addi	sp,sp,48
    80004900:	8082                	ret

0000000080004902 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004902:	1101                	addi	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	e04a                	sd	s2,0(sp)
    8000490c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000490e:	0001e517          	auipc	a0,0x1e
    80004912:	1b250513          	addi	a0,a0,434 # 80022ac0 <log>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2c0080e7          	jalr	704(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000491e:	0001e497          	auipc	s1,0x1e
    80004922:	1a248493          	addi	s1,s1,418 # 80022ac0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004926:	4979                	li	s2,30
    80004928:	a039                	j	80004936 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000492a:	85a6                	mv	a1,s1
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffe097          	auipc	ra,0xffffe
    80004932:	a56080e7          	jalr	-1450(ra) # 80002384 <sleep>
    if(log.committing){
    80004936:	50dc                	lw	a5,36(s1)
    80004938:	fbed                	bnez	a5,8000492a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000493a:	5098                	lw	a4,32(s1)
    8000493c:	2705                	addiw	a4,a4,1
    8000493e:	0007069b          	sext.w	a3,a4
    80004942:	0027179b          	slliw	a5,a4,0x2
    80004946:	9fb9                	addw	a5,a5,a4
    80004948:	0017979b          	slliw	a5,a5,0x1
    8000494c:	54d8                	lw	a4,44(s1)
    8000494e:	9fb9                	addw	a5,a5,a4
    80004950:	00f95963          	bge	s2,a5,80004962 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004954:	85a6                	mv	a1,s1
    80004956:	8526                	mv	a0,s1
    80004958:	ffffe097          	auipc	ra,0xffffe
    8000495c:	a2c080e7          	jalr	-1492(ra) # 80002384 <sleep>
    80004960:	bfd9                	j	80004936 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004962:	0001e517          	auipc	a0,0x1e
    80004966:	15e50513          	addi	a0,a0,350 # 80022ac0 <log>
    8000496a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	31e080e7          	jalr	798(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004974:	60e2                	ld	ra,24(sp)
    80004976:	6442                	ld	s0,16(sp)
    80004978:	64a2                	ld	s1,8(sp)
    8000497a:	6902                	ld	s2,0(sp)
    8000497c:	6105                	addi	sp,sp,32
    8000497e:	8082                	ret

0000000080004980 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004980:	7139                	addi	sp,sp,-64
    80004982:	fc06                	sd	ra,56(sp)
    80004984:	f822                	sd	s0,48(sp)
    80004986:	f426                	sd	s1,40(sp)
    80004988:	f04a                	sd	s2,32(sp)
    8000498a:	ec4e                	sd	s3,24(sp)
    8000498c:	e852                	sd	s4,16(sp)
    8000498e:	e456                	sd	s5,8(sp)
    80004990:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004992:	0001e497          	auipc	s1,0x1e
    80004996:	12e48493          	addi	s1,s1,302 # 80022ac0 <log>
    8000499a:	8526                	mv	a0,s1
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	23a080e7          	jalr	570(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800049a4:	509c                	lw	a5,32(s1)
    800049a6:	37fd                	addiw	a5,a5,-1
    800049a8:	0007891b          	sext.w	s2,a5
    800049ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049ae:	50dc                	lw	a5,36(s1)
    800049b0:	e7b9                	bnez	a5,800049fe <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049b2:	04091e63          	bnez	s2,80004a0e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800049b6:	0001e497          	auipc	s1,0x1e
    800049ba:	10a48493          	addi	s1,s1,266 # 80022ac0 <log>
    800049be:	4785                	li	a5,1
    800049c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	2c6080e7          	jalr	710(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049cc:	54dc                	lw	a5,44(s1)
    800049ce:	06f04763          	bgtz	a5,80004a3c <end_op+0xbc>
    acquire(&log.lock);
    800049d2:	0001e497          	auipc	s1,0x1e
    800049d6:	0ee48493          	addi	s1,s1,238 # 80022ac0 <log>
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	1fa080e7          	jalr	506(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800049e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffe097          	auipc	ra,0xffffe
    800049ee:	a14080e7          	jalr	-1516(ra) # 800023fe <wakeup>
    release(&log.lock);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	296080e7          	jalr	662(ra) # 80000c8a <release>
}
    800049fc:	a03d                	j	80004a2a <end_op+0xaa>
    panic("log.committing");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	d9a50513          	addi	a0,a0,-614 # 80008798 <syscalls+0x208>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	b3a080e7          	jalr	-1222(ra) # 80000540 <panic>
    wakeup(&log);
    80004a0e:	0001e497          	auipc	s1,0x1e
    80004a12:	0b248493          	addi	s1,s1,178 # 80022ac0 <log>
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffe097          	auipc	ra,0xffffe
    80004a1c:	9e6080e7          	jalr	-1562(ra) # 800023fe <wakeup>
  release(&log.lock);
    80004a20:	8526                	mv	a0,s1
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	268080e7          	jalr	616(ra) # 80000c8a <release>
}
    80004a2a:	70e2                	ld	ra,56(sp)
    80004a2c:	7442                	ld	s0,48(sp)
    80004a2e:	74a2                	ld	s1,40(sp)
    80004a30:	7902                	ld	s2,32(sp)
    80004a32:	69e2                	ld	s3,24(sp)
    80004a34:	6a42                	ld	s4,16(sp)
    80004a36:	6aa2                	ld	s5,8(sp)
    80004a38:	6121                	addi	sp,sp,64
    80004a3a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a3c:	0001ea97          	auipc	s5,0x1e
    80004a40:	0b4a8a93          	addi	s5,s5,180 # 80022af0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a44:	0001ea17          	auipc	s4,0x1e
    80004a48:	07ca0a13          	addi	s4,s4,124 # 80022ac0 <log>
    80004a4c:	018a2583          	lw	a1,24(s4)
    80004a50:	012585bb          	addw	a1,a1,s2
    80004a54:	2585                	addiw	a1,a1,1
    80004a56:	028a2503          	lw	a0,40(s4)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	cc4080e7          	jalr	-828(ra) # 8000371e <bread>
    80004a62:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a64:	000aa583          	lw	a1,0(s5)
    80004a68:	028a2503          	lw	a0,40(s4)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	cb2080e7          	jalr	-846(ra) # 8000371e <bread>
    80004a74:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a76:	40000613          	li	a2,1024
    80004a7a:	05850593          	addi	a1,a0,88
    80004a7e:	05848513          	addi	a0,s1,88
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	2ac080e7          	jalr	684(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	fffff097          	auipc	ra,0xfffff
    80004a90:	d84080e7          	jalr	-636(ra) # 80003810 <bwrite>
    brelse(from);
    80004a94:	854e                	mv	a0,s3
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	db8080e7          	jalr	-584(ra) # 8000384e <brelse>
    brelse(to);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	dae080e7          	jalr	-594(ra) # 8000384e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aa8:	2905                	addiw	s2,s2,1
    80004aaa:	0a91                	addi	s5,s5,4
    80004aac:	02ca2783          	lw	a5,44(s4)
    80004ab0:	f8f94ee3          	blt	s2,a5,80004a4c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	c68080e7          	jalr	-920(ra) # 8000471c <write_head>
    install_trans(0); // Now install writes to home locations
    80004abc:	4501                	li	a0,0
    80004abe:	00000097          	auipc	ra,0x0
    80004ac2:	cda080e7          	jalr	-806(ra) # 80004798 <install_trans>
    log.lh.n = 0;
    80004ac6:	0001e797          	auipc	a5,0x1e
    80004aca:	0207a323          	sw	zero,38(a5) # 80022aec <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ace:	00000097          	auipc	ra,0x0
    80004ad2:	c4e080e7          	jalr	-946(ra) # 8000471c <write_head>
    80004ad6:	bdf5                	j	800049d2 <end_op+0x52>

0000000080004ad8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ad8:	1101                	addi	sp,sp,-32
    80004ada:	ec06                	sd	ra,24(sp)
    80004adc:	e822                	sd	s0,16(sp)
    80004ade:	e426                	sd	s1,8(sp)
    80004ae0:	e04a                	sd	s2,0(sp)
    80004ae2:	1000                	addi	s0,sp,32
    80004ae4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ae6:	0001e917          	auipc	s2,0x1e
    80004aea:	fda90913          	addi	s2,s2,-38 # 80022ac0 <log>
    80004aee:	854a                	mv	a0,s2
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	0e6080e7          	jalr	230(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004af8:	02c92603          	lw	a2,44(s2)
    80004afc:	47f5                	li	a5,29
    80004afe:	06c7c563          	blt	a5,a2,80004b68 <log_write+0x90>
    80004b02:	0001e797          	auipc	a5,0x1e
    80004b06:	fda7a783          	lw	a5,-38(a5) # 80022adc <log+0x1c>
    80004b0a:	37fd                	addiw	a5,a5,-1
    80004b0c:	04f65e63          	bge	a2,a5,80004b68 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b10:	0001e797          	auipc	a5,0x1e
    80004b14:	fd07a783          	lw	a5,-48(a5) # 80022ae0 <log+0x20>
    80004b18:	06f05063          	blez	a5,80004b78 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b1c:	4781                	li	a5,0
    80004b1e:	06c05563          	blez	a2,80004b88 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b22:	44cc                	lw	a1,12(s1)
    80004b24:	0001e717          	auipc	a4,0x1e
    80004b28:	fcc70713          	addi	a4,a4,-52 # 80022af0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b2c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b2e:	4314                	lw	a3,0(a4)
    80004b30:	04b68c63          	beq	a3,a1,80004b88 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b34:	2785                	addiw	a5,a5,1
    80004b36:	0711                	addi	a4,a4,4
    80004b38:	fef61be3          	bne	a2,a5,80004b2e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b3c:	0621                	addi	a2,a2,8
    80004b3e:	060a                	slli	a2,a2,0x2
    80004b40:	0001e797          	auipc	a5,0x1e
    80004b44:	f8078793          	addi	a5,a5,-128 # 80022ac0 <log>
    80004b48:	97b2                	add	a5,a5,a2
    80004b4a:	44d8                	lw	a4,12(s1)
    80004b4c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b4e:	8526                	mv	a0,s1
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	d9c080e7          	jalr	-612(ra) # 800038ec <bpin>
    log.lh.n++;
    80004b58:	0001e717          	auipc	a4,0x1e
    80004b5c:	f6870713          	addi	a4,a4,-152 # 80022ac0 <log>
    80004b60:	575c                	lw	a5,44(a4)
    80004b62:	2785                	addiw	a5,a5,1
    80004b64:	d75c                	sw	a5,44(a4)
    80004b66:	a82d                	j	80004ba0 <log_write+0xc8>
    panic("too big a transaction");
    80004b68:	00004517          	auipc	a0,0x4
    80004b6c:	c4050513          	addi	a0,a0,-960 # 800087a8 <syscalls+0x218>
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	9d0080e7          	jalr	-1584(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004b78:	00004517          	auipc	a0,0x4
    80004b7c:	c4850513          	addi	a0,a0,-952 # 800087c0 <syscalls+0x230>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	9c0080e7          	jalr	-1600(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004b88:	00878693          	addi	a3,a5,8
    80004b8c:	068a                	slli	a3,a3,0x2
    80004b8e:	0001e717          	auipc	a4,0x1e
    80004b92:	f3270713          	addi	a4,a4,-206 # 80022ac0 <log>
    80004b96:	9736                	add	a4,a4,a3
    80004b98:	44d4                	lw	a3,12(s1)
    80004b9a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b9c:	faf609e3          	beq	a2,a5,80004b4e <log_write+0x76>
  }
  release(&log.lock);
    80004ba0:	0001e517          	auipc	a0,0x1e
    80004ba4:	f2050513          	addi	a0,a0,-224 # 80022ac0 <log>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	0e2080e7          	jalr	226(ra) # 80000c8a <release>
}
    80004bb0:	60e2                	ld	ra,24(sp)
    80004bb2:	6442                	ld	s0,16(sp)
    80004bb4:	64a2                	ld	s1,8(sp)
    80004bb6:	6902                	ld	s2,0(sp)
    80004bb8:	6105                	addi	sp,sp,32
    80004bba:	8082                	ret

0000000080004bbc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bbc:	1101                	addi	sp,sp,-32
    80004bbe:	ec06                	sd	ra,24(sp)
    80004bc0:	e822                	sd	s0,16(sp)
    80004bc2:	e426                	sd	s1,8(sp)
    80004bc4:	e04a                	sd	s2,0(sp)
    80004bc6:	1000                	addi	s0,sp,32
    80004bc8:	84aa                	mv	s1,a0
    80004bca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bcc:	00004597          	auipc	a1,0x4
    80004bd0:	c1458593          	addi	a1,a1,-1004 # 800087e0 <syscalls+0x250>
    80004bd4:	0521                	addi	a0,a0,8
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	f70080e7          	jalr	-144(ra) # 80000b46 <initlock>
  lk->name = name;
    80004bde:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004be2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004be6:	0204a423          	sw	zero,40(s1)
}
    80004bea:	60e2                	ld	ra,24(sp)
    80004bec:	6442                	ld	s0,16(sp)
    80004bee:	64a2                	ld	s1,8(sp)
    80004bf0:	6902                	ld	s2,0(sp)
    80004bf2:	6105                	addi	sp,sp,32
    80004bf4:	8082                	ret

0000000080004bf6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bf6:	1101                	addi	sp,sp,-32
    80004bf8:	ec06                	sd	ra,24(sp)
    80004bfa:	e822                	sd	s0,16(sp)
    80004bfc:	e426                	sd	s1,8(sp)
    80004bfe:	e04a                	sd	s2,0(sp)
    80004c00:	1000                	addi	s0,sp,32
    80004c02:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c04:	00850913          	addi	s2,a0,8
    80004c08:	854a                	mv	a0,s2
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	fcc080e7          	jalr	-52(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004c12:	409c                	lw	a5,0(s1)
    80004c14:	cb89                	beqz	a5,80004c26 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c16:	85ca                	mv	a1,s2
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	76a080e7          	jalr	1898(ra) # 80002384 <sleep>
  while (lk->locked) {
    80004c22:	409c                	lw	a5,0(s1)
    80004c24:	fbed                	bnez	a5,80004c16 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c26:	4785                	li	a5,1
    80004c28:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	e1c080e7          	jalr	-484(ra) # 80001a46 <myproc>
    80004c32:	591c                	lw	a5,48(a0)
    80004c34:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c36:	854a                	mv	a0,s2
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	052080e7          	jalr	82(ra) # 80000c8a <release>
}
    80004c40:	60e2                	ld	ra,24(sp)
    80004c42:	6442                	ld	s0,16(sp)
    80004c44:	64a2                	ld	s1,8(sp)
    80004c46:	6902                	ld	s2,0(sp)
    80004c48:	6105                	addi	sp,sp,32
    80004c4a:	8082                	ret

0000000080004c4c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c4c:	1101                	addi	sp,sp,-32
    80004c4e:	ec06                	sd	ra,24(sp)
    80004c50:	e822                	sd	s0,16(sp)
    80004c52:	e426                	sd	s1,8(sp)
    80004c54:	e04a                	sd	s2,0(sp)
    80004c56:	1000                	addi	s0,sp,32
    80004c58:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c5a:	00850913          	addi	s2,a0,8
    80004c5e:	854a                	mv	a0,s2
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	f76080e7          	jalr	-138(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004c68:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c6c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c70:	8526                	mv	a0,s1
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	78c080e7          	jalr	1932(ra) # 800023fe <wakeup>
  release(&lk->lk);
    80004c7a:	854a                	mv	a0,s2
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	00e080e7          	jalr	14(ra) # 80000c8a <release>
}
    80004c84:	60e2                	ld	ra,24(sp)
    80004c86:	6442                	ld	s0,16(sp)
    80004c88:	64a2                	ld	s1,8(sp)
    80004c8a:	6902                	ld	s2,0(sp)
    80004c8c:	6105                	addi	sp,sp,32
    80004c8e:	8082                	ret

0000000080004c90 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c90:	7179                	addi	sp,sp,-48
    80004c92:	f406                	sd	ra,40(sp)
    80004c94:	f022                	sd	s0,32(sp)
    80004c96:	ec26                	sd	s1,24(sp)
    80004c98:	e84a                	sd	s2,16(sp)
    80004c9a:	e44e                	sd	s3,8(sp)
    80004c9c:	1800                	addi	s0,sp,48
    80004c9e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ca0:	00850913          	addi	s2,a0,8
    80004ca4:	854a                	mv	a0,s2
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	f30080e7          	jalr	-208(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cae:	409c                	lw	a5,0(s1)
    80004cb0:	ef99                	bnez	a5,80004cce <holdingsleep+0x3e>
    80004cb2:	4481                	li	s1,0
  release(&lk->lk);
    80004cb4:	854a                	mv	a0,s2
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
  return r;
}
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	70a2                	ld	ra,40(sp)
    80004cc2:	7402                	ld	s0,32(sp)
    80004cc4:	64e2                	ld	s1,24(sp)
    80004cc6:	6942                	ld	s2,16(sp)
    80004cc8:	69a2                	ld	s3,8(sp)
    80004cca:	6145                	addi	sp,sp,48
    80004ccc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cce:	0284a983          	lw	s3,40(s1)
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	d74080e7          	jalr	-652(ra) # 80001a46 <myproc>
    80004cda:	5904                	lw	s1,48(a0)
    80004cdc:	413484b3          	sub	s1,s1,s3
    80004ce0:	0014b493          	seqz	s1,s1
    80004ce4:	bfc1                	j	80004cb4 <holdingsleep+0x24>

0000000080004ce6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ce6:	1141                	addi	sp,sp,-16
    80004ce8:	e406                	sd	ra,8(sp)
    80004cea:	e022                	sd	s0,0(sp)
    80004cec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cee:	00004597          	auipc	a1,0x4
    80004cf2:	b0258593          	addi	a1,a1,-1278 # 800087f0 <syscalls+0x260>
    80004cf6:	0001e517          	auipc	a0,0x1e
    80004cfa:	f1250513          	addi	a0,a0,-238 # 80022c08 <ftable>
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	e48080e7          	jalr	-440(ra) # 80000b46 <initlock>
}
    80004d06:	60a2                	ld	ra,8(sp)
    80004d08:	6402                	ld	s0,0(sp)
    80004d0a:	0141                	addi	sp,sp,16
    80004d0c:	8082                	ret

0000000080004d0e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d0e:	1101                	addi	sp,sp,-32
    80004d10:	ec06                	sd	ra,24(sp)
    80004d12:	e822                	sd	s0,16(sp)
    80004d14:	e426                	sd	s1,8(sp)
    80004d16:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d18:	0001e517          	auipc	a0,0x1e
    80004d1c:	ef050513          	addi	a0,a0,-272 # 80022c08 <ftable>
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	eb6080e7          	jalr	-330(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d28:	0001e497          	auipc	s1,0x1e
    80004d2c:	ef848493          	addi	s1,s1,-264 # 80022c20 <ftable+0x18>
    80004d30:	0001f717          	auipc	a4,0x1f
    80004d34:	e9070713          	addi	a4,a4,-368 # 80023bc0 <disk>
    if(f->ref == 0){
    80004d38:	40dc                	lw	a5,4(s1)
    80004d3a:	cf99                	beqz	a5,80004d58 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d3c:	02848493          	addi	s1,s1,40
    80004d40:	fee49ce3          	bne	s1,a4,80004d38 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d44:	0001e517          	auipc	a0,0x1e
    80004d48:	ec450513          	addi	a0,a0,-316 # 80022c08 <ftable>
    80004d4c:	ffffc097          	auipc	ra,0xffffc
    80004d50:	f3e080e7          	jalr	-194(ra) # 80000c8a <release>
  return 0;
    80004d54:	4481                	li	s1,0
    80004d56:	a819                	j	80004d6c <filealloc+0x5e>
      f->ref = 1;
    80004d58:	4785                	li	a5,1
    80004d5a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d5c:	0001e517          	auipc	a0,0x1e
    80004d60:	eac50513          	addi	a0,a0,-340 # 80022c08 <ftable>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f26080e7          	jalr	-218(ra) # 80000c8a <release>
}
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	60e2                	ld	ra,24(sp)
    80004d70:	6442                	ld	s0,16(sp)
    80004d72:	64a2                	ld	s1,8(sp)
    80004d74:	6105                	addi	sp,sp,32
    80004d76:	8082                	ret

0000000080004d78 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d78:	1101                	addi	sp,sp,-32
    80004d7a:	ec06                	sd	ra,24(sp)
    80004d7c:	e822                	sd	s0,16(sp)
    80004d7e:	e426                	sd	s1,8(sp)
    80004d80:	1000                	addi	s0,sp,32
    80004d82:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d84:	0001e517          	auipc	a0,0x1e
    80004d88:	e8450513          	addi	a0,a0,-380 # 80022c08 <ftable>
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	e4a080e7          	jalr	-438(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d94:	40dc                	lw	a5,4(s1)
    80004d96:	02f05263          	blez	a5,80004dba <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d9a:	2785                	addiw	a5,a5,1
    80004d9c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d9e:	0001e517          	auipc	a0,0x1e
    80004da2:	e6a50513          	addi	a0,a0,-406 # 80022c08 <ftable>
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	ee4080e7          	jalr	-284(ra) # 80000c8a <release>
  return f;
}
    80004dae:	8526                	mv	a0,s1
    80004db0:	60e2                	ld	ra,24(sp)
    80004db2:	6442                	ld	s0,16(sp)
    80004db4:	64a2                	ld	s1,8(sp)
    80004db6:	6105                	addi	sp,sp,32
    80004db8:	8082                	ret
    panic("filedup");
    80004dba:	00004517          	auipc	a0,0x4
    80004dbe:	a3e50513          	addi	a0,a0,-1474 # 800087f8 <syscalls+0x268>
    80004dc2:	ffffb097          	auipc	ra,0xffffb
    80004dc6:	77e080e7          	jalr	1918(ra) # 80000540 <panic>

0000000080004dca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004dca:	7139                	addi	sp,sp,-64
    80004dcc:	fc06                	sd	ra,56(sp)
    80004dce:	f822                	sd	s0,48(sp)
    80004dd0:	f426                	sd	s1,40(sp)
    80004dd2:	f04a                	sd	s2,32(sp)
    80004dd4:	ec4e                	sd	s3,24(sp)
    80004dd6:	e852                	sd	s4,16(sp)
    80004dd8:	e456                	sd	s5,8(sp)
    80004dda:	0080                	addi	s0,sp,64
    80004ddc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004dde:	0001e517          	auipc	a0,0x1e
    80004de2:	e2a50513          	addi	a0,a0,-470 # 80022c08 <ftable>
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	df0080e7          	jalr	-528(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004dee:	40dc                	lw	a5,4(s1)
    80004df0:	06f05163          	blez	a5,80004e52 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004df4:	37fd                	addiw	a5,a5,-1
    80004df6:	0007871b          	sext.w	a4,a5
    80004dfa:	c0dc                	sw	a5,4(s1)
    80004dfc:	06e04363          	bgtz	a4,80004e62 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e00:	0004a903          	lw	s2,0(s1)
    80004e04:	0094ca83          	lbu	s5,9(s1)
    80004e08:	0104ba03          	ld	s4,16(s1)
    80004e0c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e10:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e14:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e18:	0001e517          	auipc	a0,0x1e
    80004e1c:	df050513          	addi	a0,a0,-528 # 80022c08 <ftable>
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	e6a080e7          	jalr	-406(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004e28:	4785                	li	a5,1
    80004e2a:	04f90d63          	beq	s2,a5,80004e84 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e2e:	3979                	addiw	s2,s2,-2
    80004e30:	4785                	li	a5,1
    80004e32:	0527e063          	bltu	a5,s2,80004e72 <fileclose+0xa8>
    begin_op();
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	acc080e7          	jalr	-1332(ra) # 80004902 <begin_op>
    iput(ff.ip);
    80004e3e:	854e                	mv	a0,s3
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	2b0080e7          	jalr	688(ra) # 800040f0 <iput>
    end_op();
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	b38080e7          	jalr	-1224(ra) # 80004980 <end_op>
    80004e50:	a00d                	j	80004e72 <fileclose+0xa8>
    panic("fileclose");
    80004e52:	00004517          	auipc	a0,0x4
    80004e56:	9ae50513          	addi	a0,a0,-1618 # 80008800 <syscalls+0x270>
    80004e5a:	ffffb097          	auipc	ra,0xffffb
    80004e5e:	6e6080e7          	jalr	1766(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004e62:	0001e517          	auipc	a0,0x1e
    80004e66:	da650513          	addi	a0,a0,-602 # 80022c08 <ftable>
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	e20080e7          	jalr	-480(ra) # 80000c8a <release>
  }
}
    80004e72:	70e2                	ld	ra,56(sp)
    80004e74:	7442                	ld	s0,48(sp)
    80004e76:	74a2                	ld	s1,40(sp)
    80004e78:	7902                	ld	s2,32(sp)
    80004e7a:	69e2                	ld	s3,24(sp)
    80004e7c:	6a42                	ld	s4,16(sp)
    80004e7e:	6aa2                	ld	s5,8(sp)
    80004e80:	6121                	addi	sp,sp,64
    80004e82:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e84:	85d6                	mv	a1,s5
    80004e86:	8552                	mv	a0,s4
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	34c080e7          	jalr	844(ra) # 800051d4 <pipeclose>
    80004e90:	b7cd                	j	80004e72 <fileclose+0xa8>

0000000080004e92 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e92:	715d                	addi	sp,sp,-80
    80004e94:	e486                	sd	ra,72(sp)
    80004e96:	e0a2                	sd	s0,64(sp)
    80004e98:	fc26                	sd	s1,56(sp)
    80004e9a:	f84a                	sd	s2,48(sp)
    80004e9c:	f44e                	sd	s3,40(sp)
    80004e9e:	0880                	addi	s0,sp,80
    80004ea0:	84aa                	mv	s1,a0
    80004ea2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	ba2080e7          	jalr	-1118(ra) # 80001a46 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004eac:	409c                	lw	a5,0(s1)
    80004eae:	37f9                	addiw	a5,a5,-2
    80004eb0:	4705                	li	a4,1
    80004eb2:	04f76763          	bltu	a4,a5,80004f00 <filestat+0x6e>
    80004eb6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004eb8:	6c88                	ld	a0,24(s1)
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	07c080e7          	jalr	124(ra) # 80003f36 <ilock>
    stati(f->ip, &st);
    80004ec2:	fb840593          	addi	a1,s0,-72
    80004ec6:	6c88                	ld	a0,24(s1)
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	2f8080e7          	jalr	760(ra) # 800041c0 <stati>
    iunlock(f->ip);
    80004ed0:	6c88                	ld	a0,24(s1)
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	126080e7          	jalr	294(ra) # 80003ff8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004eda:	46e1                	li	a3,24
    80004edc:	fb840613          	addi	a2,s0,-72
    80004ee0:	85ce                	mv	a1,s3
    80004ee2:	05893503          	ld	a0,88(s2)
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	786080e7          	jalr	1926(ra) # 8000166c <copyout>
    80004eee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ef2:	60a6                	ld	ra,72(sp)
    80004ef4:	6406                	ld	s0,64(sp)
    80004ef6:	74e2                	ld	s1,56(sp)
    80004ef8:	7942                	ld	s2,48(sp)
    80004efa:	79a2                	ld	s3,40(sp)
    80004efc:	6161                	addi	sp,sp,80
    80004efe:	8082                	ret
  return -1;
    80004f00:	557d                	li	a0,-1
    80004f02:	bfc5                	j	80004ef2 <filestat+0x60>

0000000080004f04 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f04:	7179                	addi	sp,sp,-48
    80004f06:	f406                	sd	ra,40(sp)
    80004f08:	f022                	sd	s0,32(sp)
    80004f0a:	ec26                	sd	s1,24(sp)
    80004f0c:	e84a                	sd	s2,16(sp)
    80004f0e:	e44e                	sd	s3,8(sp)
    80004f10:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f12:	00854783          	lbu	a5,8(a0)
    80004f16:	c3d5                	beqz	a5,80004fba <fileread+0xb6>
    80004f18:	84aa                	mv	s1,a0
    80004f1a:	89ae                	mv	s3,a1
    80004f1c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f1e:	411c                	lw	a5,0(a0)
    80004f20:	4705                	li	a4,1
    80004f22:	04e78963          	beq	a5,a4,80004f74 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f26:	470d                	li	a4,3
    80004f28:	04e78d63          	beq	a5,a4,80004f82 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f2c:	4709                	li	a4,2
    80004f2e:	06e79e63          	bne	a5,a4,80004faa <fileread+0xa6>
    ilock(f->ip);
    80004f32:	6d08                	ld	a0,24(a0)
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	002080e7          	jalr	2(ra) # 80003f36 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f3c:	874a                	mv	a4,s2
    80004f3e:	5094                	lw	a3,32(s1)
    80004f40:	864e                	mv	a2,s3
    80004f42:	4585                	li	a1,1
    80004f44:	6c88                	ld	a0,24(s1)
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	2a4080e7          	jalr	676(ra) # 800041ea <readi>
    80004f4e:	892a                	mv	s2,a0
    80004f50:	00a05563          	blez	a0,80004f5a <fileread+0x56>
      f->off += r;
    80004f54:	509c                	lw	a5,32(s1)
    80004f56:	9fa9                	addw	a5,a5,a0
    80004f58:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f5a:	6c88                	ld	a0,24(s1)
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	09c080e7          	jalr	156(ra) # 80003ff8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f64:	854a                	mv	a0,s2
    80004f66:	70a2                	ld	ra,40(sp)
    80004f68:	7402                	ld	s0,32(sp)
    80004f6a:	64e2                	ld	s1,24(sp)
    80004f6c:	6942                	ld	s2,16(sp)
    80004f6e:	69a2                	ld	s3,8(sp)
    80004f70:	6145                	addi	sp,sp,48
    80004f72:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f74:	6908                	ld	a0,16(a0)
    80004f76:	00000097          	auipc	ra,0x0
    80004f7a:	3c6080e7          	jalr	966(ra) # 8000533c <piperead>
    80004f7e:	892a                	mv	s2,a0
    80004f80:	b7d5                	j	80004f64 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f82:	02451783          	lh	a5,36(a0)
    80004f86:	03079693          	slli	a3,a5,0x30
    80004f8a:	92c1                	srli	a3,a3,0x30
    80004f8c:	4725                	li	a4,9
    80004f8e:	02d76863          	bltu	a4,a3,80004fbe <fileread+0xba>
    80004f92:	0792                	slli	a5,a5,0x4
    80004f94:	0001e717          	auipc	a4,0x1e
    80004f98:	bd470713          	addi	a4,a4,-1068 # 80022b68 <devsw>
    80004f9c:	97ba                	add	a5,a5,a4
    80004f9e:	639c                	ld	a5,0(a5)
    80004fa0:	c38d                	beqz	a5,80004fc2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fa2:	4505                	li	a0,1
    80004fa4:	9782                	jalr	a5
    80004fa6:	892a                	mv	s2,a0
    80004fa8:	bf75                	j	80004f64 <fileread+0x60>
    panic("fileread");
    80004faa:	00004517          	auipc	a0,0x4
    80004fae:	86650513          	addi	a0,a0,-1946 # 80008810 <syscalls+0x280>
    80004fb2:	ffffb097          	auipc	ra,0xffffb
    80004fb6:	58e080e7          	jalr	1422(ra) # 80000540 <panic>
    return -1;
    80004fba:	597d                	li	s2,-1
    80004fbc:	b765                	j	80004f64 <fileread+0x60>
      return -1;
    80004fbe:	597d                	li	s2,-1
    80004fc0:	b755                	j	80004f64 <fileread+0x60>
    80004fc2:	597d                	li	s2,-1
    80004fc4:	b745                	j	80004f64 <fileread+0x60>

0000000080004fc6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004fc6:	715d                	addi	sp,sp,-80
    80004fc8:	e486                	sd	ra,72(sp)
    80004fca:	e0a2                	sd	s0,64(sp)
    80004fcc:	fc26                	sd	s1,56(sp)
    80004fce:	f84a                	sd	s2,48(sp)
    80004fd0:	f44e                	sd	s3,40(sp)
    80004fd2:	f052                	sd	s4,32(sp)
    80004fd4:	ec56                	sd	s5,24(sp)
    80004fd6:	e85a                	sd	s6,16(sp)
    80004fd8:	e45e                	sd	s7,8(sp)
    80004fda:	e062                	sd	s8,0(sp)
    80004fdc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004fde:	00954783          	lbu	a5,9(a0)
    80004fe2:	10078663          	beqz	a5,800050ee <filewrite+0x128>
    80004fe6:	892a                	mv	s2,a0
    80004fe8:	8b2e                	mv	s6,a1
    80004fea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fec:	411c                	lw	a5,0(a0)
    80004fee:	4705                	li	a4,1
    80004ff0:	02e78263          	beq	a5,a4,80005014 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ff4:	470d                	li	a4,3
    80004ff6:	02e78663          	beq	a5,a4,80005022 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ffa:	4709                	li	a4,2
    80004ffc:	0ee79163          	bne	a5,a4,800050de <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005000:	0ac05d63          	blez	a2,800050ba <filewrite+0xf4>
    int i = 0;
    80005004:	4981                	li	s3,0
    80005006:	6b85                	lui	s7,0x1
    80005008:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000500c:	6c05                	lui	s8,0x1
    8000500e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005012:	a861                	j	800050aa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005014:	6908                	ld	a0,16(a0)
    80005016:	00000097          	auipc	ra,0x0
    8000501a:	22e080e7          	jalr	558(ra) # 80005244 <pipewrite>
    8000501e:	8a2a                	mv	s4,a0
    80005020:	a045                	j	800050c0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005022:	02451783          	lh	a5,36(a0)
    80005026:	03079693          	slli	a3,a5,0x30
    8000502a:	92c1                	srli	a3,a3,0x30
    8000502c:	4725                	li	a4,9
    8000502e:	0cd76263          	bltu	a4,a3,800050f2 <filewrite+0x12c>
    80005032:	0792                	slli	a5,a5,0x4
    80005034:	0001e717          	auipc	a4,0x1e
    80005038:	b3470713          	addi	a4,a4,-1228 # 80022b68 <devsw>
    8000503c:	97ba                	add	a5,a5,a4
    8000503e:	679c                	ld	a5,8(a5)
    80005040:	cbdd                	beqz	a5,800050f6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005042:	4505                	li	a0,1
    80005044:	9782                	jalr	a5
    80005046:	8a2a                	mv	s4,a0
    80005048:	a8a5                	j	800050c0 <filewrite+0xfa>
    8000504a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000504e:	00000097          	auipc	ra,0x0
    80005052:	8b4080e7          	jalr	-1868(ra) # 80004902 <begin_op>
      ilock(f->ip);
    80005056:	01893503          	ld	a0,24(s2)
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	edc080e7          	jalr	-292(ra) # 80003f36 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005062:	8756                	mv	a4,s5
    80005064:	02092683          	lw	a3,32(s2)
    80005068:	01698633          	add	a2,s3,s6
    8000506c:	4585                	li	a1,1
    8000506e:	01893503          	ld	a0,24(s2)
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	270080e7          	jalr	624(ra) # 800042e2 <writei>
    8000507a:	84aa                	mv	s1,a0
    8000507c:	00a05763          	blez	a0,8000508a <filewrite+0xc4>
        f->off += r;
    80005080:	02092783          	lw	a5,32(s2)
    80005084:	9fa9                	addw	a5,a5,a0
    80005086:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000508a:	01893503          	ld	a0,24(s2)
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	f6a080e7          	jalr	-150(ra) # 80003ff8 <iunlock>
      end_op();
    80005096:	00000097          	auipc	ra,0x0
    8000509a:	8ea080e7          	jalr	-1814(ra) # 80004980 <end_op>

      if(r != n1){
    8000509e:	009a9f63          	bne	s5,s1,800050bc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050a2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050a6:	0149db63          	bge	s3,s4,800050bc <filewrite+0xf6>
      int n1 = n - i;
    800050aa:	413a04bb          	subw	s1,s4,s3
    800050ae:	0004879b          	sext.w	a5,s1
    800050b2:	f8fbdce3          	bge	s7,a5,8000504a <filewrite+0x84>
    800050b6:	84e2                	mv	s1,s8
    800050b8:	bf49                	j	8000504a <filewrite+0x84>
    int i = 0;
    800050ba:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050bc:	013a1f63          	bne	s4,s3,800050da <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050c0:	8552                	mv	a0,s4
    800050c2:	60a6                	ld	ra,72(sp)
    800050c4:	6406                	ld	s0,64(sp)
    800050c6:	74e2                	ld	s1,56(sp)
    800050c8:	7942                	ld	s2,48(sp)
    800050ca:	79a2                	ld	s3,40(sp)
    800050cc:	7a02                	ld	s4,32(sp)
    800050ce:	6ae2                	ld	s5,24(sp)
    800050d0:	6b42                	ld	s6,16(sp)
    800050d2:	6ba2                	ld	s7,8(sp)
    800050d4:	6c02                	ld	s8,0(sp)
    800050d6:	6161                	addi	sp,sp,80
    800050d8:	8082                	ret
    ret = (i == n ? n : -1);
    800050da:	5a7d                	li	s4,-1
    800050dc:	b7d5                	j	800050c0 <filewrite+0xfa>
    panic("filewrite");
    800050de:	00003517          	auipc	a0,0x3
    800050e2:	74250513          	addi	a0,a0,1858 # 80008820 <syscalls+0x290>
    800050e6:	ffffb097          	auipc	ra,0xffffb
    800050ea:	45a080e7          	jalr	1114(ra) # 80000540 <panic>
    return -1;
    800050ee:	5a7d                	li	s4,-1
    800050f0:	bfc1                	j	800050c0 <filewrite+0xfa>
      return -1;
    800050f2:	5a7d                	li	s4,-1
    800050f4:	b7f1                	j	800050c0 <filewrite+0xfa>
    800050f6:	5a7d                	li	s4,-1
    800050f8:	b7e1                	j	800050c0 <filewrite+0xfa>

00000000800050fa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050fa:	7179                	addi	sp,sp,-48
    800050fc:	f406                	sd	ra,40(sp)
    800050fe:	f022                	sd	s0,32(sp)
    80005100:	ec26                	sd	s1,24(sp)
    80005102:	e84a                	sd	s2,16(sp)
    80005104:	e44e                	sd	s3,8(sp)
    80005106:	e052                	sd	s4,0(sp)
    80005108:	1800                	addi	s0,sp,48
    8000510a:	84aa                	mv	s1,a0
    8000510c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000510e:	0005b023          	sd	zero,0(a1)
    80005112:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005116:	00000097          	auipc	ra,0x0
    8000511a:	bf8080e7          	jalr	-1032(ra) # 80004d0e <filealloc>
    8000511e:	e088                	sd	a0,0(s1)
    80005120:	c551                	beqz	a0,800051ac <pipealloc+0xb2>
    80005122:	00000097          	auipc	ra,0x0
    80005126:	bec080e7          	jalr	-1044(ra) # 80004d0e <filealloc>
    8000512a:	00aa3023          	sd	a0,0(s4)
    8000512e:	c92d                	beqz	a0,800051a0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	9b6080e7          	jalr	-1610(ra) # 80000ae6 <kalloc>
    80005138:	892a                	mv	s2,a0
    8000513a:	c125                	beqz	a0,8000519a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000513c:	4985                	li	s3,1
    8000513e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005142:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005146:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000514a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000514e:	00003597          	auipc	a1,0x3
    80005152:	35a58593          	addi	a1,a1,858 # 800084a8 <states.0+0x1c0>
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	9f0080e7          	jalr	-1552(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000515e:	609c                	ld	a5,0(s1)
    80005160:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005164:	609c                	ld	a5,0(s1)
    80005166:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000516a:	609c                	ld	a5,0(s1)
    8000516c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005170:	609c                	ld	a5,0(s1)
    80005172:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005176:	000a3783          	ld	a5,0(s4)
    8000517a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000517e:	000a3783          	ld	a5,0(s4)
    80005182:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005186:	000a3783          	ld	a5,0(s4)
    8000518a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000518e:	000a3783          	ld	a5,0(s4)
    80005192:	0127b823          	sd	s2,16(a5)
  return 0;
    80005196:	4501                	li	a0,0
    80005198:	a025                	j	800051c0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000519a:	6088                	ld	a0,0(s1)
    8000519c:	e501                	bnez	a0,800051a4 <pipealloc+0xaa>
    8000519e:	a039                	j	800051ac <pipealloc+0xb2>
    800051a0:	6088                	ld	a0,0(s1)
    800051a2:	c51d                	beqz	a0,800051d0 <pipealloc+0xd6>
    fileclose(*f0);
    800051a4:	00000097          	auipc	ra,0x0
    800051a8:	c26080e7          	jalr	-986(ra) # 80004dca <fileclose>
  if(*f1)
    800051ac:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051b0:	557d                	li	a0,-1
  if(*f1)
    800051b2:	c799                	beqz	a5,800051c0 <pipealloc+0xc6>
    fileclose(*f1);
    800051b4:	853e                	mv	a0,a5
    800051b6:	00000097          	auipc	ra,0x0
    800051ba:	c14080e7          	jalr	-1004(ra) # 80004dca <fileclose>
  return -1;
    800051be:	557d                	li	a0,-1
}
    800051c0:	70a2                	ld	ra,40(sp)
    800051c2:	7402                	ld	s0,32(sp)
    800051c4:	64e2                	ld	s1,24(sp)
    800051c6:	6942                	ld	s2,16(sp)
    800051c8:	69a2                	ld	s3,8(sp)
    800051ca:	6a02                	ld	s4,0(sp)
    800051cc:	6145                	addi	sp,sp,48
    800051ce:	8082                	ret
  return -1;
    800051d0:	557d                	li	a0,-1
    800051d2:	b7fd                	j	800051c0 <pipealloc+0xc6>

00000000800051d4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051d4:	1101                	addi	sp,sp,-32
    800051d6:	ec06                	sd	ra,24(sp)
    800051d8:	e822                	sd	s0,16(sp)
    800051da:	e426                	sd	s1,8(sp)
    800051dc:	e04a                	sd	s2,0(sp)
    800051de:	1000                	addi	s0,sp,32
    800051e0:	84aa                	mv	s1,a0
    800051e2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	9f2080e7          	jalr	-1550(ra) # 80000bd6 <acquire>
  if(writable){
    800051ec:	02090d63          	beqz	s2,80005226 <pipeclose+0x52>
    pi->writeopen = 0;
    800051f0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051f4:	21848513          	addi	a0,s1,536
    800051f8:	ffffd097          	auipc	ra,0xffffd
    800051fc:	206080e7          	jalr	518(ra) # 800023fe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005200:	2204b783          	ld	a5,544(s1)
    80005204:	eb95                	bnez	a5,80005238 <pipeclose+0x64>
    release(&pi->lock);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	a82080e7          	jalr	-1406(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffb097          	auipc	ra,0xffffb
    80005216:	7d6080e7          	jalr	2006(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000521a:	60e2                	ld	ra,24(sp)
    8000521c:	6442                	ld	s0,16(sp)
    8000521e:	64a2                	ld	s1,8(sp)
    80005220:	6902                	ld	s2,0(sp)
    80005222:	6105                	addi	sp,sp,32
    80005224:	8082                	ret
    pi->readopen = 0;
    80005226:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000522a:	21c48513          	addi	a0,s1,540
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	1d0080e7          	jalr	464(ra) # 800023fe <wakeup>
    80005236:	b7e9                	j	80005200 <pipeclose+0x2c>
    release(&pi->lock);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	a50080e7          	jalr	-1456(ra) # 80000c8a <release>
}
    80005242:	bfe1                	j	8000521a <pipeclose+0x46>

0000000080005244 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005244:	711d                	addi	sp,sp,-96
    80005246:	ec86                	sd	ra,88(sp)
    80005248:	e8a2                	sd	s0,80(sp)
    8000524a:	e4a6                	sd	s1,72(sp)
    8000524c:	e0ca                	sd	s2,64(sp)
    8000524e:	fc4e                	sd	s3,56(sp)
    80005250:	f852                	sd	s4,48(sp)
    80005252:	f456                	sd	s5,40(sp)
    80005254:	f05a                	sd	s6,32(sp)
    80005256:	ec5e                	sd	s7,24(sp)
    80005258:	e862                	sd	s8,16(sp)
    8000525a:	1080                	addi	s0,sp,96
    8000525c:	84aa                	mv	s1,a0
    8000525e:	8aae                	mv	s5,a1
    80005260:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	7e4080e7          	jalr	2020(ra) # 80001a46 <myproc>
    8000526a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000526c:	8526                	mv	a0,s1
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
  while(i < n){
    80005276:	0b405663          	blez	s4,80005322 <pipewrite+0xde>
  int i = 0;
    8000527a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000527c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000527e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005282:	21c48b93          	addi	s7,s1,540
    80005286:	a089                	j	800052c8 <pipewrite+0x84>
      release(&pi->lock);
    80005288:	8526                	mv	a0,s1
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	a00080e7          	jalr	-1536(ra) # 80000c8a <release>
      return -1;
    80005292:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005294:	854a                	mv	a0,s2
    80005296:	60e6                	ld	ra,88(sp)
    80005298:	6446                	ld	s0,80(sp)
    8000529a:	64a6                	ld	s1,72(sp)
    8000529c:	6906                	ld	s2,64(sp)
    8000529e:	79e2                	ld	s3,56(sp)
    800052a0:	7a42                	ld	s4,48(sp)
    800052a2:	7aa2                	ld	s5,40(sp)
    800052a4:	7b02                	ld	s6,32(sp)
    800052a6:	6be2                	ld	s7,24(sp)
    800052a8:	6c42                	ld	s8,16(sp)
    800052aa:	6125                	addi	sp,sp,96
    800052ac:	8082                	ret
      wakeup(&pi->nread);
    800052ae:	8562                	mv	a0,s8
    800052b0:	ffffd097          	auipc	ra,0xffffd
    800052b4:	14e080e7          	jalr	334(ra) # 800023fe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052b8:	85a6                	mv	a1,s1
    800052ba:	855e                	mv	a0,s7
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	0c8080e7          	jalr	200(ra) # 80002384 <sleep>
  while(i < n){
    800052c4:	07495063          	bge	s2,s4,80005324 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800052c8:	2204a783          	lw	a5,544(s1)
    800052cc:	dfd5                	beqz	a5,80005288 <pipewrite+0x44>
    800052ce:	854e                	mv	a0,s3
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	38e080e7          	jalr	910(ra) # 8000265e <killed>
    800052d8:	f945                	bnez	a0,80005288 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052da:	2184a783          	lw	a5,536(s1)
    800052de:	21c4a703          	lw	a4,540(s1)
    800052e2:	2007879b          	addiw	a5,a5,512
    800052e6:	fcf704e3          	beq	a4,a5,800052ae <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052ea:	4685                	li	a3,1
    800052ec:	01590633          	add	a2,s2,s5
    800052f0:	faf40593          	addi	a1,s0,-81
    800052f4:	0589b503          	ld	a0,88(s3)
    800052f8:	ffffc097          	auipc	ra,0xffffc
    800052fc:	400080e7          	jalr	1024(ra) # 800016f8 <copyin>
    80005300:	03650263          	beq	a0,s6,80005324 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005304:	21c4a783          	lw	a5,540(s1)
    80005308:	0017871b          	addiw	a4,a5,1
    8000530c:	20e4ae23          	sw	a4,540(s1)
    80005310:	1ff7f793          	andi	a5,a5,511
    80005314:	97a6                	add	a5,a5,s1
    80005316:	faf44703          	lbu	a4,-81(s0)
    8000531a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000531e:	2905                	addiw	s2,s2,1
    80005320:	b755                	j	800052c4 <pipewrite+0x80>
  int i = 0;
    80005322:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005324:	21848513          	addi	a0,s1,536
    80005328:	ffffd097          	auipc	ra,0xffffd
    8000532c:	0d6080e7          	jalr	214(ra) # 800023fe <wakeup>
  release(&pi->lock);
    80005330:	8526                	mv	a0,s1
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	958080e7          	jalr	-1704(ra) # 80000c8a <release>
  return i;
    8000533a:	bfa9                	j	80005294 <pipewrite+0x50>

000000008000533c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000533c:	715d                	addi	sp,sp,-80
    8000533e:	e486                	sd	ra,72(sp)
    80005340:	e0a2                	sd	s0,64(sp)
    80005342:	fc26                	sd	s1,56(sp)
    80005344:	f84a                	sd	s2,48(sp)
    80005346:	f44e                	sd	s3,40(sp)
    80005348:	f052                	sd	s4,32(sp)
    8000534a:	ec56                	sd	s5,24(sp)
    8000534c:	e85a                	sd	s6,16(sp)
    8000534e:	0880                	addi	s0,sp,80
    80005350:	84aa                	mv	s1,a0
    80005352:	892e                	mv	s2,a1
    80005354:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	6f0080e7          	jalr	1776(ra) # 80001a46 <myproc>
    8000535e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000536a:	2184a703          	lw	a4,536(s1)
    8000536e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005372:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005376:	02f71763          	bne	a4,a5,800053a4 <piperead+0x68>
    8000537a:	2244a783          	lw	a5,548(s1)
    8000537e:	c39d                	beqz	a5,800053a4 <piperead+0x68>
    if(killed(pr)){
    80005380:	8552                	mv	a0,s4
    80005382:	ffffd097          	auipc	ra,0xffffd
    80005386:	2dc080e7          	jalr	732(ra) # 8000265e <killed>
    8000538a:	e949                	bnez	a0,8000541c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000538c:	85a6                	mv	a1,s1
    8000538e:	854e                	mv	a0,s3
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	ff4080e7          	jalr	-12(ra) # 80002384 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005398:	2184a703          	lw	a4,536(s1)
    8000539c:	21c4a783          	lw	a5,540(s1)
    800053a0:	fcf70de3          	beq	a4,a5,8000537a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053a4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053a6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053a8:	05505463          	blez	s5,800053f0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800053ac:	2184a783          	lw	a5,536(s1)
    800053b0:	21c4a703          	lw	a4,540(s1)
    800053b4:	02f70e63          	beq	a4,a5,800053f0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053b8:	0017871b          	addiw	a4,a5,1
    800053bc:	20e4ac23          	sw	a4,536(s1)
    800053c0:	1ff7f793          	andi	a5,a5,511
    800053c4:	97a6                	add	a5,a5,s1
    800053c6:	0187c783          	lbu	a5,24(a5)
    800053ca:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053ce:	4685                	li	a3,1
    800053d0:	fbf40613          	addi	a2,s0,-65
    800053d4:	85ca                	mv	a1,s2
    800053d6:	058a3503          	ld	a0,88(s4)
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	292080e7          	jalr	658(ra) # 8000166c <copyout>
    800053e2:	01650763          	beq	a0,s6,800053f0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053e6:	2985                	addiw	s3,s3,1
    800053e8:	0905                	addi	s2,s2,1
    800053ea:	fd3a91e3          	bne	s5,s3,800053ac <piperead+0x70>
    800053ee:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053f0:	21c48513          	addi	a0,s1,540
    800053f4:	ffffd097          	auipc	ra,0xffffd
    800053f8:	00a080e7          	jalr	10(ra) # 800023fe <wakeup>
  release(&pi->lock);
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffc097          	auipc	ra,0xffffc
    80005402:	88c080e7          	jalr	-1908(ra) # 80000c8a <release>
  return i;
}
    80005406:	854e                	mv	a0,s3
    80005408:	60a6                	ld	ra,72(sp)
    8000540a:	6406                	ld	s0,64(sp)
    8000540c:	74e2                	ld	s1,56(sp)
    8000540e:	7942                	ld	s2,48(sp)
    80005410:	79a2                	ld	s3,40(sp)
    80005412:	7a02                	ld	s4,32(sp)
    80005414:	6ae2                	ld	s5,24(sp)
    80005416:	6b42                	ld	s6,16(sp)
    80005418:	6161                	addi	sp,sp,80
    8000541a:	8082                	ret
      release(&pi->lock);
    8000541c:	8526                	mv	a0,s1
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
      return -1;
    80005426:	59fd                	li	s3,-1
    80005428:	bff9                	j	80005406 <piperead+0xca>

000000008000542a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000542a:	1141                	addi	sp,sp,-16
    8000542c:	e422                	sd	s0,8(sp)
    8000542e:	0800                	addi	s0,sp,16
    80005430:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005432:	8905                	andi	a0,a0,1
    80005434:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005436:	8b89                	andi	a5,a5,2
    80005438:	c399                	beqz	a5,8000543e <flags2perm+0x14>
      perm |= PTE_W;
    8000543a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000543e:	6422                	ld	s0,8(sp)
    80005440:	0141                	addi	sp,sp,16
    80005442:	8082                	ret

0000000080005444 <exec>:

int
exec(char *path, char **argv)
{
    80005444:	de010113          	addi	sp,sp,-544
    80005448:	20113c23          	sd	ra,536(sp)
    8000544c:	20813823          	sd	s0,528(sp)
    80005450:	20913423          	sd	s1,520(sp)
    80005454:	21213023          	sd	s2,512(sp)
    80005458:	ffce                	sd	s3,504(sp)
    8000545a:	fbd2                	sd	s4,496(sp)
    8000545c:	f7d6                	sd	s5,488(sp)
    8000545e:	f3da                	sd	s6,480(sp)
    80005460:	efde                	sd	s7,472(sp)
    80005462:	ebe2                	sd	s8,464(sp)
    80005464:	e7e6                	sd	s9,456(sp)
    80005466:	e3ea                	sd	s10,448(sp)
    80005468:	ff6e                	sd	s11,440(sp)
    8000546a:	1400                	addi	s0,sp,544
    8000546c:	892a                	mv	s2,a0
    8000546e:	dea43423          	sd	a0,-536(s0)
    80005472:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	5d0080e7          	jalr	1488(ra) # 80001a46 <myproc>
    8000547e:	84aa                	mv	s1,a0

  begin_op();
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	482080e7          	jalr	1154(ra) # 80004902 <begin_op>

  if((ip = namei(path)) == 0){
    80005488:	854a                	mv	a0,s2
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	258080e7          	jalr	600(ra) # 800046e2 <namei>
    80005492:	c93d                	beqz	a0,80005508 <exec+0xc4>
    80005494:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	aa0080e7          	jalr	-1376(ra) # 80003f36 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000549e:	04000713          	li	a4,64
    800054a2:	4681                	li	a3,0
    800054a4:	e5040613          	addi	a2,s0,-432
    800054a8:	4581                	li	a1,0
    800054aa:	8556                	mv	a0,s5
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	d3e080e7          	jalr	-706(ra) # 800041ea <readi>
    800054b4:	04000793          	li	a5,64
    800054b8:	00f51a63          	bne	a0,a5,800054cc <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800054bc:	e5042703          	lw	a4,-432(s0)
    800054c0:	464c47b7          	lui	a5,0x464c4
    800054c4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054c8:	04f70663          	beq	a4,a5,80005514 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054cc:	8556                	mv	a0,s5
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	cca080e7          	jalr	-822(ra) # 80004198 <iunlockput>
    end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	4aa080e7          	jalr	1194(ra) # 80004980 <end_op>
  }
  return -1;
    800054de:	557d                	li	a0,-1
}
    800054e0:	21813083          	ld	ra,536(sp)
    800054e4:	21013403          	ld	s0,528(sp)
    800054e8:	20813483          	ld	s1,520(sp)
    800054ec:	20013903          	ld	s2,512(sp)
    800054f0:	79fe                	ld	s3,504(sp)
    800054f2:	7a5e                	ld	s4,496(sp)
    800054f4:	7abe                	ld	s5,488(sp)
    800054f6:	7b1e                	ld	s6,480(sp)
    800054f8:	6bfe                	ld	s7,472(sp)
    800054fa:	6c5e                	ld	s8,464(sp)
    800054fc:	6cbe                	ld	s9,456(sp)
    800054fe:	6d1e                	ld	s10,448(sp)
    80005500:	7dfa                	ld	s11,440(sp)
    80005502:	22010113          	addi	sp,sp,544
    80005506:	8082                	ret
    end_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	478080e7          	jalr	1144(ra) # 80004980 <end_op>
    return -1;
    80005510:	557d                	li	a0,-1
    80005512:	b7f9                	j	800054e0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005514:	8526                	mv	a0,s1
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	5f4080e7          	jalr	1524(ra) # 80001b0a <proc_pagetable>
    8000551e:	8b2a                	mv	s6,a0
    80005520:	d555                	beqz	a0,800054cc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005522:	e7042783          	lw	a5,-400(s0)
    80005526:	e8845703          	lhu	a4,-376(s0)
    8000552a:	c735                	beqz	a4,80005596 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000552c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000552e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005532:	6a05                	lui	s4,0x1
    80005534:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005538:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000553c:	6d85                	lui	s11,0x1
    8000553e:	7d7d                	lui	s10,0xfffff
    80005540:	ac3d                	j	8000577e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005542:	00003517          	auipc	a0,0x3
    80005546:	2ee50513          	addi	a0,a0,750 # 80008830 <syscalls+0x2a0>
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	ff6080e7          	jalr	-10(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005552:	874a                	mv	a4,s2
    80005554:	009c86bb          	addw	a3,s9,s1
    80005558:	4581                	li	a1,0
    8000555a:	8556                	mv	a0,s5
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	c8e080e7          	jalr	-882(ra) # 800041ea <readi>
    80005564:	2501                	sext.w	a0,a0
    80005566:	1aa91963          	bne	s2,a0,80005718 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000556a:	009d84bb          	addw	s1,s11,s1
    8000556e:	013d09bb          	addw	s3,s10,s3
    80005572:	1f74f663          	bgeu	s1,s7,8000575e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005576:	02049593          	slli	a1,s1,0x20
    8000557a:	9181                	srli	a1,a1,0x20
    8000557c:	95e2                	add	a1,a1,s8
    8000557e:	855a                	mv	a0,s6
    80005580:	ffffc097          	auipc	ra,0xffffc
    80005584:	adc080e7          	jalr	-1316(ra) # 8000105c <walkaddr>
    80005588:	862a                	mv	a2,a0
    if(pa == 0)
    8000558a:	dd45                	beqz	a0,80005542 <exec+0xfe>
      n = PGSIZE;
    8000558c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000558e:	fd49f2e3          	bgeu	s3,s4,80005552 <exec+0x10e>
      n = sz - i;
    80005592:	894e                	mv	s2,s3
    80005594:	bf7d                	j	80005552 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005596:	4901                	li	s2,0
  iunlockput(ip);
    80005598:	8556                	mv	a0,s5
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	bfe080e7          	jalr	-1026(ra) # 80004198 <iunlockput>
  end_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	3de080e7          	jalr	990(ra) # 80004980 <end_op>
  p = myproc();
    800055aa:	ffffc097          	auipc	ra,0xffffc
    800055ae:	49c080e7          	jalr	1180(ra) # 80001a46 <myproc>
    800055b2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800055b4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800055b8:	6785                	lui	a5,0x1
    800055ba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800055bc:	97ca                	add	a5,a5,s2
    800055be:	777d                	lui	a4,0xfffff
    800055c0:	8ff9                	and	a5,a5,a4
    800055c2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800055c6:	4691                	li	a3,4
    800055c8:	6609                	lui	a2,0x2
    800055ca:	963e                	add	a2,a2,a5
    800055cc:	85be                	mv	a1,a5
    800055ce:	855a                	mv	a0,s6
    800055d0:	ffffc097          	auipc	ra,0xffffc
    800055d4:	e40080e7          	jalr	-448(ra) # 80001410 <uvmalloc>
    800055d8:	8c2a                	mv	s8,a0
  ip = 0;
    800055da:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800055dc:	12050e63          	beqz	a0,80005718 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055e0:	75f9                	lui	a1,0xffffe
    800055e2:	95aa                	add	a1,a1,a0
    800055e4:	855a                	mv	a0,s6
    800055e6:	ffffc097          	auipc	ra,0xffffc
    800055ea:	054080e7          	jalr	84(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800055ee:	7afd                	lui	s5,0xfffff
    800055f0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800055f2:	df043783          	ld	a5,-528(s0)
    800055f6:	6388                	ld	a0,0(a5)
    800055f8:	c925                	beqz	a0,80005668 <exec+0x224>
    800055fa:	e9040993          	addi	s3,s0,-368
    800055fe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005602:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005604:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	848080e7          	jalr	-1976(ra) # 80000e4e <strlen>
    8000560e:	0015079b          	addiw	a5,a0,1
    80005612:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005616:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000561a:	13596663          	bltu	s2,s5,80005746 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000561e:	df043d83          	ld	s11,-528(s0)
    80005622:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005626:	8552                	mv	a0,s4
    80005628:	ffffc097          	auipc	ra,0xffffc
    8000562c:	826080e7          	jalr	-2010(ra) # 80000e4e <strlen>
    80005630:	0015069b          	addiw	a3,a0,1
    80005634:	8652                	mv	a2,s4
    80005636:	85ca                	mv	a1,s2
    80005638:	855a                	mv	a0,s6
    8000563a:	ffffc097          	auipc	ra,0xffffc
    8000563e:	032080e7          	jalr	50(ra) # 8000166c <copyout>
    80005642:	10054663          	bltz	a0,8000574e <exec+0x30a>
    ustack[argc] = sp;
    80005646:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000564a:	0485                	addi	s1,s1,1
    8000564c:	008d8793          	addi	a5,s11,8
    80005650:	def43823          	sd	a5,-528(s0)
    80005654:	008db503          	ld	a0,8(s11)
    80005658:	c911                	beqz	a0,8000566c <exec+0x228>
    if(argc >= MAXARG)
    8000565a:	09a1                	addi	s3,s3,8
    8000565c:	fb3c95e3          	bne	s9,s3,80005606 <exec+0x1c2>
  sz = sz1;
    80005660:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005664:	4a81                	li	s5,0
    80005666:	a84d                	j	80005718 <exec+0x2d4>
  sp = sz;
    80005668:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000566a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000566c:	00349793          	slli	a5,s1,0x3
    80005670:	f9078793          	addi	a5,a5,-112
    80005674:	97a2                	add	a5,a5,s0
    80005676:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000567a:	00148693          	addi	a3,s1,1
    8000567e:	068e                	slli	a3,a3,0x3
    80005680:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005684:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005688:	01597663          	bgeu	s2,s5,80005694 <exec+0x250>
  sz = sz1;
    8000568c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005690:	4a81                	li	s5,0
    80005692:	a059                	j	80005718 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005694:	e9040613          	addi	a2,s0,-368
    80005698:	85ca                	mv	a1,s2
    8000569a:	855a                	mv	a0,s6
    8000569c:	ffffc097          	auipc	ra,0xffffc
    800056a0:	fd0080e7          	jalr	-48(ra) # 8000166c <copyout>
    800056a4:	0a054963          	bltz	a0,80005756 <exec+0x312>
  p->trapframe->a1 = sp;
    800056a8:	060bb783          	ld	a5,96(s7)
    800056ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800056b0:	de843783          	ld	a5,-536(s0)
    800056b4:	0007c703          	lbu	a4,0(a5)
    800056b8:	cf11                	beqz	a4,800056d4 <exec+0x290>
    800056ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800056bc:	02f00693          	li	a3,47
    800056c0:	a039                	j	800056ce <exec+0x28a>
      last = s+1;
    800056c2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800056c6:	0785                	addi	a5,a5,1
    800056c8:	fff7c703          	lbu	a4,-1(a5)
    800056cc:	c701                	beqz	a4,800056d4 <exec+0x290>
    if(*s == '/')
    800056ce:	fed71ce3          	bne	a4,a3,800056c6 <exec+0x282>
    800056d2:	bfc5                	j	800056c2 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800056d4:	4641                	li	a2,16
    800056d6:	de843583          	ld	a1,-536(s0)
    800056da:	160b8513          	addi	a0,s7,352
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	73e080e7          	jalr	1854(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800056e6:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800056ea:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800056ee:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056f2:	060bb783          	ld	a5,96(s7)
    800056f6:	e6843703          	ld	a4,-408(s0)
    800056fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056fc:	060bb783          	ld	a5,96(s7)
    80005700:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005704:	85ea                	mv	a1,s10
    80005706:	ffffc097          	auipc	ra,0xffffc
    8000570a:	4a0080e7          	jalr	1184(ra) # 80001ba6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000570e:	0004851b          	sext.w	a0,s1
    80005712:	b3f9                	j	800054e0 <exec+0x9c>
    80005714:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005718:	df843583          	ld	a1,-520(s0)
    8000571c:	855a                	mv	a0,s6
    8000571e:	ffffc097          	auipc	ra,0xffffc
    80005722:	488080e7          	jalr	1160(ra) # 80001ba6 <proc_freepagetable>
  if(ip){
    80005726:	da0a93e3          	bnez	s5,800054cc <exec+0x88>
  return -1;
    8000572a:	557d                	li	a0,-1
    8000572c:	bb55                	j	800054e0 <exec+0x9c>
    8000572e:	df243c23          	sd	s2,-520(s0)
    80005732:	b7dd                	j	80005718 <exec+0x2d4>
    80005734:	df243c23          	sd	s2,-520(s0)
    80005738:	b7c5                	j	80005718 <exec+0x2d4>
    8000573a:	df243c23          	sd	s2,-520(s0)
    8000573e:	bfe9                	j	80005718 <exec+0x2d4>
    80005740:	df243c23          	sd	s2,-520(s0)
    80005744:	bfd1                	j	80005718 <exec+0x2d4>
  sz = sz1;
    80005746:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000574a:	4a81                	li	s5,0
    8000574c:	b7f1                	j	80005718 <exec+0x2d4>
  sz = sz1;
    8000574e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005752:	4a81                	li	s5,0
    80005754:	b7d1                	j	80005718 <exec+0x2d4>
  sz = sz1;
    80005756:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000575a:	4a81                	li	s5,0
    8000575c:	bf75                	j	80005718 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000575e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005762:	e0843783          	ld	a5,-504(s0)
    80005766:	0017869b          	addiw	a3,a5,1
    8000576a:	e0d43423          	sd	a3,-504(s0)
    8000576e:	e0043783          	ld	a5,-512(s0)
    80005772:	0387879b          	addiw	a5,a5,56
    80005776:	e8845703          	lhu	a4,-376(s0)
    8000577a:	e0e6dfe3          	bge	a3,a4,80005598 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000577e:	2781                	sext.w	a5,a5
    80005780:	e0f43023          	sd	a5,-512(s0)
    80005784:	03800713          	li	a4,56
    80005788:	86be                	mv	a3,a5
    8000578a:	e1840613          	addi	a2,s0,-488
    8000578e:	4581                	li	a1,0
    80005790:	8556                	mv	a0,s5
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	a58080e7          	jalr	-1448(ra) # 800041ea <readi>
    8000579a:	03800793          	li	a5,56
    8000579e:	f6f51be3          	bne	a0,a5,80005714 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800057a2:	e1842783          	lw	a5,-488(s0)
    800057a6:	4705                	li	a4,1
    800057a8:	fae79de3          	bne	a5,a4,80005762 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800057ac:	e4043483          	ld	s1,-448(s0)
    800057b0:	e3843783          	ld	a5,-456(s0)
    800057b4:	f6f4ede3          	bltu	s1,a5,8000572e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800057b8:	e2843783          	ld	a5,-472(s0)
    800057bc:	94be                	add	s1,s1,a5
    800057be:	f6f4ebe3          	bltu	s1,a5,80005734 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800057c2:	de043703          	ld	a4,-544(s0)
    800057c6:	8ff9                	and	a5,a5,a4
    800057c8:	fbad                	bnez	a5,8000573a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057ca:	e1c42503          	lw	a0,-484(s0)
    800057ce:	00000097          	auipc	ra,0x0
    800057d2:	c5c080e7          	jalr	-932(ra) # 8000542a <flags2perm>
    800057d6:	86aa                	mv	a3,a0
    800057d8:	8626                	mv	a2,s1
    800057da:	85ca                	mv	a1,s2
    800057dc:	855a                	mv	a0,s6
    800057de:	ffffc097          	auipc	ra,0xffffc
    800057e2:	c32080e7          	jalr	-974(ra) # 80001410 <uvmalloc>
    800057e6:	dea43c23          	sd	a0,-520(s0)
    800057ea:	d939                	beqz	a0,80005740 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057ec:	e2843c03          	ld	s8,-472(s0)
    800057f0:	e2042c83          	lw	s9,-480(s0)
    800057f4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057f8:	f60b83e3          	beqz	s7,8000575e <exec+0x31a>
    800057fc:	89de                	mv	s3,s7
    800057fe:	4481                	li	s1,0
    80005800:	bb9d                	j	80005576 <exec+0x132>

0000000080005802 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005802:	7179                	addi	sp,sp,-48
    80005804:	f406                	sd	ra,40(sp)
    80005806:	f022                	sd	s0,32(sp)
    80005808:	ec26                	sd	s1,24(sp)
    8000580a:	e84a                	sd	s2,16(sp)
    8000580c:	1800                	addi	s0,sp,48
    8000580e:	892e                	mv	s2,a1
    80005810:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005812:	fdc40593          	addi	a1,s0,-36
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	95c080e7          	jalr	-1700(ra) # 80003172 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000581e:	fdc42703          	lw	a4,-36(s0)
    80005822:	47bd                	li	a5,15
    80005824:	02e7eb63          	bltu	a5,a4,8000585a <argfd+0x58>
    80005828:	ffffc097          	auipc	ra,0xffffc
    8000582c:	21e080e7          	jalr	542(ra) # 80001a46 <myproc>
    80005830:	fdc42703          	lw	a4,-36(s0)
    80005834:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffda8da>
    80005838:	078e                	slli	a5,a5,0x3
    8000583a:	953e                	add	a0,a0,a5
    8000583c:	651c                	ld	a5,8(a0)
    8000583e:	c385                	beqz	a5,8000585e <argfd+0x5c>
    return -1;
  if(pfd)
    80005840:	00090463          	beqz	s2,80005848 <argfd+0x46>
    *pfd = fd;
    80005844:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005848:	4501                	li	a0,0
  if(pf)
    8000584a:	c091                	beqz	s1,8000584e <argfd+0x4c>
    *pf = f;
    8000584c:	e09c                	sd	a5,0(s1)
}
    8000584e:	70a2                	ld	ra,40(sp)
    80005850:	7402                	ld	s0,32(sp)
    80005852:	64e2                	ld	s1,24(sp)
    80005854:	6942                	ld	s2,16(sp)
    80005856:	6145                	addi	sp,sp,48
    80005858:	8082                	ret
    return -1;
    8000585a:	557d                	li	a0,-1
    8000585c:	bfcd                	j	8000584e <argfd+0x4c>
    8000585e:	557d                	li	a0,-1
    80005860:	b7fd                	j	8000584e <argfd+0x4c>

0000000080005862 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005862:	1101                	addi	sp,sp,-32
    80005864:	ec06                	sd	ra,24(sp)
    80005866:	e822                	sd	s0,16(sp)
    80005868:	e426                	sd	s1,8(sp)
    8000586a:	1000                	addi	s0,sp,32
    8000586c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000586e:	ffffc097          	auipc	ra,0xffffc
    80005872:	1d8080e7          	jalr	472(ra) # 80001a46 <myproc>
    80005876:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005878:	0d850793          	addi	a5,a0,216
    8000587c:	4501                	li	a0,0
    8000587e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005880:	6398                	ld	a4,0(a5)
    80005882:	cb19                	beqz	a4,80005898 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005884:	2505                	addiw	a0,a0,1
    80005886:	07a1                	addi	a5,a5,8
    80005888:	fed51ce3          	bne	a0,a3,80005880 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000588c:	557d                	li	a0,-1
}
    8000588e:	60e2                	ld	ra,24(sp)
    80005890:	6442                	ld	s0,16(sp)
    80005892:	64a2                	ld	s1,8(sp)
    80005894:	6105                	addi	sp,sp,32
    80005896:	8082                	ret
      p->ofile[fd] = f;
    80005898:	01a50793          	addi	a5,a0,26
    8000589c:	078e                	slli	a5,a5,0x3
    8000589e:	963e                	add	a2,a2,a5
    800058a0:	e604                	sd	s1,8(a2)
      return fd;
    800058a2:	b7f5                	j	8000588e <fdalloc+0x2c>

00000000800058a4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058a4:	715d                	addi	sp,sp,-80
    800058a6:	e486                	sd	ra,72(sp)
    800058a8:	e0a2                	sd	s0,64(sp)
    800058aa:	fc26                	sd	s1,56(sp)
    800058ac:	f84a                	sd	s2,48(sp)
    800058ae:	f44e                	sd	s3,40(sp)
    800058b0:	f052                	sd	s4,32(sp)
    800058b2:	ec56                	sd	s5,24(sp)
    800058b4:	e85a                	sd	s6,16(sp)
    800058b6:	0880                	addi	s0,sp,80
    800058b8:	8b2e                	mv	s6,a1
    800058ba:	89b2                	mv	s3,a2
    800058bc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800058be:	fb040593          	addi	a1,s0,-80
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	e3e080e7          	jalr	-450(ra) # 80004700 <nameiparent>
    800058ca:	84aa                	mv	s1,a0
    800058cc:	14050f63          	beqz	a0,80005a2a <create+0x186>
    return 0;

  ilock(dp);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	666080e7          	jalr	1638(ra) # 80003f36 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800058d8:	4601                	li	a2,0
    800058da:	fb040593          	addi	a1,s0,-80
    800058de:	8526                	mv	a0,s1
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	b3a080e7          	jalr	-1222(ra) # 8000441a <dirlookup>
    800058e8:	8aaa                	mv	s5,a0
    800058ea:	c931                	beqz	a0,8000593e <create+0x9a>
    iunlockput(dp);
    800058ec:	8526                	mv	a0,s1
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	8aa080e7          	jalr	-1878(ra) # 80004198 <iunlockput>
    ilock(ip);
    800058f6:	8556                	mv	a0,s5
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	63e080e7          	jalr	1598(ra) # 80003f36 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005900:	000b059b          	sext.w	a1,s6
    80005904:	4789                	li	a5,2
    80005906:	02f59563          	bne	a1,a5,80005930 <create+0x8c>
    8000590a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffda904>
    8000590e:	37f9                	addiw	a5,a5,-2
    80005910:	17c2                	slli	a5,a5,0x30
    80005912:	93c1                	srli	a5,a5,0x30
    80005914:	4705                	li	a4,1
    80005916:	00f76d63          	bltu	a4,a5,80005930 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000591a:	8556                	mv	a0,s5
    8000591c:	60a6                	ld	ra,72(sp)
    8000591e:	6406                	ld	s0,64(sp)
    80005920:	74e2                	ld	s1,56(sp)
    80005922:	7942                	ld	s2,48(sp)
    80005924:	79a2                	ld	s3,40(sp)
    80005926:	7a02                	ld	s4,32(sp)
    80005928:	6ae2                	ld	s5,24(sp)
    8000592a:	6b42                	ld	s6,16(sp)
    8000592c:	6161                	addi	sp,sp,80
    8000592e:	8082                	ret
    iunlockput(ip);
    80005930:	8556                	mv	a0,s5
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	866080e7          	jalr	-1946(ra) # 80004198 <iunlockput>
    return 0;
    8000593a:	4a81                	li	s5,0
    8000593c:	bff9                	j	8000591a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000593e:	85da                	mv	a1,s6
    80005940:	4088                	lw	a0,0(s1)
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	456080e7          	jalr	1110(ra) # 80003d98 <ialloc>
    8000594a:	8a2a                	mv	s4,a0
    8000594c:	c539                	beqz	a0,8000599a <create+0xf6>
  ilock(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	5e8080e7          	jalr	1512(ra) # 80003f36 <ilock>
  ip->major = major;
    80005956:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000595a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000595e:	4905                	li	s2,1
    80005960:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005964:	8552                	mv	a0,s4
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	504080e7          	jalr	1284(ra) # 80003e6a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000596e:	000b059b          	sext.w	a1,s6
    80005972:	03258b63          	beq	a1,s2,800059a8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005976:	004a2603          	lw	a2,4(s4)
    8000597a:	fb040593          	addi	a1,s0,-80
    8000597e:	8526                	mv	a0,s1
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	cb0080e7          	jalr	-848(ra) # 80004630 <dirlink>
    80005988:	06054f63          	bltz	a0,80005a06 <create+0x162>
  iunlockput(dp);
    8000598c:	8526                	mv	a0,s1
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	80a080e7          	jalr	-2038(ra) # 80004198 <iunlockput>
  return ip;
    80005996:	8ad2                	mv	s5,s4
    80005998:	b749                	j	8000591a <create+0x76>
    iunlockput(dp);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	7fc080e7          	jalr	2044(ra) # 80004198 <iunlockput>
    return 0;
    800059a4:	8ad2                	mv	s5,s4
    800059a6:	bf95                	j	8000591a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059a8:	004a2603          	lw	a2,4(s4)
    800059ac:	00003597          	auipc	a1,0x3
    800059b0:	ea458593          	addi	a1,a1,-348 # 80008850 <syscalls+0x2c0>
    800059b4:	8552                	mv	a0,s4
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	c7a080e7          	jalr	-902(ra) # 80004630 <dirlink>
    800059be:	04054463          	bltz	a0,80005a06 <create+0x162>
    800059c2:	40d0                	lw	a2,4(s1)
    800059c4:	00003597          	auipc	a1,0x3
    800059c8:	e9458593          	addi	a1,a1,-364 # 80008858 <syscalls+0x2c8>
    800059cc:	8552                	mv	a0,s4
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	c62080e7          	jalr	-926(ra) # 80004630 <dirlink>
    800059d6:	02054863          	bltz	a0,80005a06 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800059da:	004a2603          	lw	a2,4(s4)
    800059de:	fb040593          	addi	a1,s0,-80
    800059e2:	8526                	mv	a0,s1
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	c4c080e7          	jalr	-948(ra) # 80004630 <dirlink>
    800059ec:	00054d63          	bltz	a0,80005a06 <create+0x162>
    dp->nlink++;  // for ".."
    800059f0:	04a4d783          	lhu	a5,74(s1)
    800059f4:	2785                	addiw	a5,a5,1
    800059f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	46e080e7          	jalr	1134(ra) # 80003e6a <iupdate>
    80005a04:	b761                	j	8000598c <create+0xe8>
  ip->nlink = 0;
    80005a06:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005a0a:	8552                	mv	a0,s4
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	45e080e7          	jalr	1118(ra) # 80003e6a <iupdate>
  iunlockput(ip);
    80005a14:	8552                	mv	a0,s4
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	782080e7          	jalr	1922(ra) # 80004198 <iunlockput>
  iunlockput(dp);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	778080e7          	jalr	1912(ra) # 80004198 <iunlockput>
  return 0;
    80005a28:	bdcd                	j	8000591a <create+0x76>
    return 0;
    80005a2a:	8aaa                	mv	s5,a0
    80005a2c:	b5fd                	j	8000591a <create+0x76>

0000000080005a2e <sys_dup>:
{
    80005a2e:	7179                	addi	sp,sp,-48
    80005a30:	f406                	sd	ra,40(sp)
    80005a32:	f022                	sd	s0,32(sp)
    80005a34:	ec26                	sd	s1,24(sp)
    80005a36:	e84a                	sd	s2,16(sp)
    80005a38:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a3a:	fd840613          	addi	a2,s0,-40
    80005a3e:	4581                	li	a1,0
    80005a40:	4501                	li	a0,0
    80005a42:	00000097          	auipc	ra,0x0
    80005a46:	dc0080e7          	jalr	-576(ra) # 80005802 <argfd>
    return -1;
    80005a4a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a4c:	02054363          	bltz	a0,80005a72 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005a50:	fd843903          	ld	s2,-40(s0)
    80005a54:	854a                	mv	a0,s2
    80005a56:	00000097          	auipc	ra,0x0
    80005a5a:	e0c080e7          	jalr	-500(ra) # 80005862 <fdalloc>
    80005a5e:	84aa                	mv	s1,a0
    return -1;
    80005a60:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a62:	00054863          	bltz	a0,80005a72 <sys_dup+0x44>
  filedup(f);
    80005a66:	854a                	mv	a0,s2
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	310080e7          	jalr	784(ra) # 80004d78 <filedup>
  return fd;
    80005a70:	87a6                	mv	a5,s1
}
    80005a72:	853e                	mv	a0,a5
    80005a74:	70a2                	ld	ra,40(sp)
    80005a76:	7402                	ld	s0,32(sp)
    80005a78:	64e2                	ld	s1,24(sp)
    80005a7a:	6942                	ld	s2,16(sp)
    80005a7c:	6145                	addi	sp,sp,48
    80005a7e:	8082                	ret

0000000080005a80 <sys_read>:
{
    80005a80:	7179                	addi	sp,sp,-48
    80005a82:	f406                	sd	ra,40(sp)
    80005a84:	f022                	sd	s0,32(sp)
    80005a86:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a88:	fd840593          	addi	a1,s0,-40
    80005a8c:	4505                	li	a0,1
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	704080e7          	jalr	1796(ra) # 80003192 <argaddr>
  argint(2, &n);
    80005a96:	fe440593          	addi	a1,s0,-28
    80005a9a:	4509                	li	a0,2
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	6d6080e7          	jalr	1750(ra) # 80003172 <argint>
  if(argfd(0, 0, &f) < 0)
    80005aa4:	fe840613          	addi	a2,s0,-24
    80005aa8:	4581                	li	a1,0
    80005aaa:	4501                	li	a0,0
    80005aac:	00000097          	auipc	ra,0x0
    80005ab0:	d56080e7          	jalr	-682(ra) # 80005802 <argfd>
    80005ab4:	87aa                	mv	a5,a0
    return -1;
    80005ab6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ab8:	0007cc63          	bltz	a5,80005ad0 <sys_read+0x50>
  return fileread(f, p, n);
    80005abc:	fe442603          	lw	a2,-28(s0)
    80005ac0:	fd843583          	ld	a1,-40(s0)
    80005ac4:	fe843503          	ld	a0,-24(s0)
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	43c080e7          	jalr	1084(ra) # 80004f04 <fileread>
}
    80005ad0:	70a2                	ld	ra,40(sp)
    80005ad2:	7402                	ld	s0,32(sp)
    80005ad4:	6145                	addi	sp,sp,48
    80005ad6:	8082                	ret

0000000080005ad8 <sys_write>:
{
    80005ad8:	7179                	addi	sp,sp,-48
    80005ada:	f406                	sd	ra,40(sp)
    80005adc:	f022                	sd	s0,32(sp)
    80005ade:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ae0:	fd840593          	addi	a1,s0,-40
    80005ae4:	4505                	li	a0,1
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	6ac080e7          	jalr	1708(ra) # 80003192 <argaddr>
  argint(2, &n);
    80005aee:	fe440593          	addi	a1,s0,-28
    80005af2:	4509                	li	a0,2
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	67e080e7          	jalr	1662(ra) # 80003172 <argint>
  if(argfd(0, 0, &f) < 0)
    80005afc:	fe840613          	addi	a2,s0,-24
    80005b00:	4581                	li	a1,0
    80005b02:	4501                	li	a0,0
    80005b04:	00000097          	auipc	ra,0x0
    80005b08:	cfe080e7          	jalr	-770(ra) # 80005802 <argfd>
    80005b0c:	87aa                	mv	a5,a0
    return -1;
    80005b0e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b10:	0007cc63          	bltz	a5,80005b28 <sys_write+0x50>
  return filewrite(f, p, n);
    80005b14:	fe442603          	lw	a2,-28(s0)
    80005b18:	fd843583          	ld	a1,-40(s0)
    80005b1c:	fe843503          	ld	a0,-24(s0)
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	4a6080e7          	jalr	1190(ra) # 80004fc6 <filewrite>
}
    80005b28:	70a2                	ld	ra,40(sp)
    80005b2a:	7402                	ld	s0,32(sp)
    80005b2c:	6145                	addi	sp,sp,48
    80005b2e:	8082                	ret

0000000080005b30 <sys_close>:
{
    80005b30:	1101                	addi	sp,sp,-32
    80005b32:	ec06                	sd	ra,24(sp)
    80005b34:	e822                	sd	s0,16(sp)
    80005b36:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b38:	fe040613          	addi	a2,s0,-32
    80005b3c:	fec40593          	addi	a1,s0,-20
    80005b40:	4501                	li	a0,0
    80005b42:	00000097          	auipc	ra,0x0
    80005b46:	cc0080e7          	jalr	-832(ra) # 80005802 <argfd>
    return -1;
    80005b4a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b4c:	02054463          	bltz	a0,80005b74 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b50:	ffffc097          	auipc	ra,0xffffc
    80005b54:	ef6080e7          	jalr	-266(ra) # 80001a46 <myproc>
    80005b58:	fec42783          	lw	a5,-20(s0)
    80005b5c:	07e9                	addi	a5,a5,26
    80005b5e:	078e                	slli	a5,a5,0x3
    80005b60:	953e                	add	a0,a0,a5
    80005b62:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005b66:	fe043503          	ld	a0,-32(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	260080e7          	jalr	608(ra) # 80004dca <fileclose>
  return 0;
    80005b72:	4781                	li	a5,0
}
    80005b74:	853e                	mv	a0,a5
    80005b76:	60e2                	ld	ra,24(sp)
    80005b78:	6442                	ld	s0,16(sp)
    80005b7a:	6105                	addi	sp,sp,32
    80005b7c:	8082                	ret

0000000080005b7e <sys_fstat>:
{
    80005b7e:	1101                	addi	sp,sp,-32
    80005b80:	ec06                	sd	ra,24(sp)
    80005b82:	e822                	sd	s0,16(sp)
    80005b84:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b86:	fe040593          	addi	a1,s0,-32
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	606080e7          	jalr	1542(ra) # 80003192 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b94:	fe840613          	addi	a2,s0,-24
    80005b98:	4581                	li	a1,0
    80005b9a:	4501                	li	a0,0
    80005b9c:	00000097          	auipc	ra,0x0
    80005ba0:	c66080e7          	jalr	-922(ra) # 80005802 <argfd>
    80005ba4:	87aa                	mv	a5,a0
    return -1;
    80005ba6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ba8:	0007ca63          	bltz	a5,80005bbc <sys_fstat+0x3e>
  return filestat(f, st);
    80005bac:	fe043583          	ld	a1,-32(s0)
    80005bb0:	fe843503          	ld	a0,-24(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	2de080e7          	jalr	734(ra) # 80004e92 <filestat>
}
    80005bbc:	60e2                	ld	ra,24(sp)
    80005bbe:	6442                	ld	s0,16(sp)
    80005bc0:	6105                	addi	sp,sp,32
    80005bc2:	8082                	ret

0000000080005bc4 <sys_link>:
{
    80005bc4:	7169                	addi	sp,sp,-304
    80005bc6:	f606                	sd	ra,296(sp)
    80005bc8:	f222                	sd	s0,288(sp)
    80005bca:	ee26                	sd	s1,280(sp)
    80005bcc:	ea4a                	sd	s2,272(sp)
    80005bce:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bd0:	08000613          	li	a2,128
    80005bd4:	ed040593          	addi	a1,s0,-304
    80005bd8:	4501                	li	a0,0
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	5d8080e7          	jalr	1496(ra) # 800031b2 <argstr>
    return -1;
    80005be2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005be4:	10054e63          	bltz	a0,80005d00 <sys_link+0x13c>
    80005be8:	08000613          	li	a2,128
    80005bec:	f5040593          	addi	a1,s0,-176
    80005bf0:	4505                	li	a0,1
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	5c0080e7          	jalr	1472(ra) # 800031b2 <argstr>
    return -1;
    80005bfa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bfc:	10054263          	bltz	a0,80005d00 <sys_link+0x13c>
  begin_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	d02080e7          	jalr	-766(ra) # 80004902 <begin_op>
  if((ip = namei(old)) == 0){
    80005c08:	ed040513          	addi	a0,s0,-304
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	ad6080e7          	jalr	-1322(ra) # 800046e2 <namei>
    80005c14:	84aa                	mv	s1,a0
    80005c16:	c551                	beqz	a0,80005ca2 <sys_link+0xde>
  ilock(ip);
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	31e080e7          	jalr	798(ra) # 80003f36 <ilock>
  if(ip->type == T_DIR){
    80005c20:	04449703          	lh	a4,68(s1)
    80005c24:	4785                	li	a5,1
    80005c26:	08f70463          	beq	a4,a5,80005cae <sys_link+0xea>
  ip->nlink++;
    80005c2a:	04a4d783          	lhu	a5,74(s1)
    80005c2e:	2785                	addiw	a5,a5,1
    80005c30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c34:	8526                	mv	a0,s1
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	234080e7          	jalr	564(ra) # 80003e6a <iupdate>
  iunlock(ip);
    80005c3e:	8526                	mv	a0,s1
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	3b8080e7          	jalr	952(ra) # 80003ff8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c48:	fd040593          	addi	a1,s0,-48
    80005c4c:	f5040513          	addi	a0,s0,-176
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	ab0080e7          	jalr	-1360(ra) # 80004700 <nameiparent>
    80005c58:	892a                	mv	s2,a0
    80005c5a:	c935                	beqz	a0,80005cce <sys_link+0x10a>
  ilock(dp);
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	2da080e7          	jalr	730(ra) # 80003f36 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c64:	00092703          	lw	a4,0(s2)
    80005c68:	409c                	lw	a5,0(s1)
    80005c6a:	04f71d63          	bne	a4,a5,80005cc4 <sys_link+0x100>
    80005c6e:	40d0                	lw	a2,4(s1)
    80005c70:	fd040593          	addi	a1,s0,-48
    80005c74:	854a                	mv	a0,s2
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	9ba080e7          	jalr	-1606(ra) # 80004630 <dirlink>
    80005c7e:	04054363          	bltz	a0,80005cc4 <sys_link+0x100>
  iunlockput(dp);
    80005c82:	854a                	mv	a0,s2
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	514080e7          	jalr	1300(ra) # 80004198 <iunlockput>
  iput(ip);
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	462080e7          	jalr	1122(ra) # 800040f0 <iput>
  end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	cea080e7          	jalr	-790(ra) # 80004980 <end_op>
  return 0;
    80005c9e:	4781                	li	a5,0
    80005ca0:	a085                	j	80005d00 <sys_link+0x13c>
    end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	cde080e7          	jalr	-802(ra) # 80004980 <end_op>
    return -1;
    80005caa:	57fd                	li	a5,-1
    80005cac:	a891                	j	80005d00 <sys_link+0x13c>
    iunlockput(ip);
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	4e8080e7          	jalr	1256(ra) # 80004198 <iunlockput>
    end_op();
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	cc8080e7          	jalr	-824(ra) # 80004980 <end_op>
    return -1;
    80005cc0:	57fd                	li	a5,-1
    80005cc2:	a83d                	j	80005d00 <sys_link+0x13c>
    iunlockput(dp);
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	4d2080e7          	jalr	1234(ra) # 80004198 <iunlockput>
  ilock(ip);
    80005cce:	8526                	mv	a0,s1
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	266080e7          	jalr	614(ra) # 80003f36 <ilock>
  ip->nlink--;
    80005cd8:	04a4d783          	lhu	a5,74(s1)
    80005cdc:	37fd                	addiw	a5,a5,-1
    80005cde:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ce2:	8526                	mv	a0,s1
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	186080e7          	jalr	390(ra) # 80003e6a <iupdate>
  iunlockput(ip);
    80005cec:	8526                	mv	a0,s1
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	4aa080e7          	jalr	1194(ra) # 80004198 <iunlockput>
  end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	c8a080e7          	jalr	-886(ra) # 80004980 <end_op>
  return -1;
    80005cfe:	57fd                	li	a5,-1
}
    80005d00:	853e                	mv	a0,a5
    80005d02:	70b2                	ld	ra,296(sp)
    80005d04:	7412                	ld	s0,288(sp)
    80005d06:	64f2                	ld	s1,280(sp)
    80005d08:	6952                	ld	s2,272(sp)
    80005d0a:	6155                	addi	sp,sp,304
    80005d0c:	8082                	ret

0000000080005d0e <sys_unlink>:
{
    80005d0e:	7151                	addi	sp,sp,-240
    80005d10:	f586                	sd	ra,232(sp)
    80005d12:	f1a2                	sd	s0,224(sp)
    80005d14:	eda6                	sd	s1,216(sp)
    80005d16:	e9ca                	sd	s2,208(sp)
    80005d18:	e5ce                	sd	s3,200(sp)
    80005d1a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d1c:	08000613          	li	a2,128
    80005d20:	f3040593          	addi	a1,s0,-208
    80005d24:	4501                	li	a0,0
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	48c080e7          	jalr	1164(ra) # 800031b2 <argstr>
    80005d2e:	18054163          	bltz	a0,80005eb0 <sys_unlink+0x1a2>
  begin_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	bd0080e7          	jalr	-1072(ra) # 80004902 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d3a:	fb040593          	addi	a1,s0,-80
    80005d3e:	f3040513          	addi	a0,s0,-208
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	9be080e7          	jalr	-1602(ra) # 80004700 <nameiparent>
    80005d4a:	84aa                	mv	s1,a0
    80005d4c:	c979                	beqz	a0,80005e22 <sys_unlink+0x114>
  ilock(dp);
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	1e8080e7          	jalr	488(ra) # 80003f36 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d56:	00003597          	auipc	a1,0x3
    80005d5a:	afa58593          	addi	a1,a1,-1286 # 80008850 <syscalls+0x2c0>
    80005d5e:	fb040513          	addi	a0,s0,-80
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	69e080e7          	jalr	1694(ra) # 80004400 <namecmp>
    80005d6a:	14050a63          	beqz	a0,80005ebe <sys_unlink+0x1b0>
    80005d6e:	00003597          	auipc	a1,0x3
    80005d72:	aea58593          	addi	a1,a1,-1302 # 80008858 <syscalls+0x2c8>
    80005d76:	fb040513          	addi	a0,s0,-80
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	686080e7          	jalr	1670(ra) # 80004400 <namecmp>
    80005d82:	12050e63          	beqz	a0,80005ebe <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d86:	f2c40613          	addi	a2,s0,-212
    80005d8a:	fb040593          	addi	a1,s0,-80
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	68a080e7          	jalr	1674(ra) # 8000441a <dirlookup>
    80005d98:	892a                	mv	s2,a0
    80005d9a:	12050263          	beqz	a0,80005ebe <sys_unlink+0x1b0>
  ilock(ip);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	198080e7          	jalr	408(ra) # 80003f36 <ilock>
  if(ip->nlink < 1)
    80005da6:	04a91783          	lh	a5,74(s2)
    80005daa:	08f05263          	blez	a5,80005e2e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005dae:	04491703          	lh	a4,68(s2)
    80005db2:	4785                	li	a5,1
    80005db4:	08f70563          	beq	a4,a5,80005e3e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005db8:	4641                	li	a2,16
    80005dba:	4581                	li	a1,0
    80005dbc:	fc040513          	addi	a0,s0,-64
    80005dc0:	ffffb097          	auipc	ra,0xffffb
    80005dc4:	f12080e7          	jalr	-238(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dc8:	4741                	li	a4,16
    80005dca:	f2c42683          	lw	a3,-212(s0)
    80005dce:	fc040613          	addi	a2,s0,-64
    80005dd2:	4581                	li	a1,0
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	50c080e7          	jalr	1292(ra) # 800042e2 <writei>
    80005dde:	47c1                	li	a5,16
    80005de0:	0af51563          	bne	a0,a5,80005e8a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005de4:	04491703          	lh	a4,68(s2)
    80005de8:	4785                	li	a5,1
    80005dea:	0af70863          	beq	a4,a5,80005e9a <sys_unlink+0x18c>
  iunlockput(dp);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	3a8080e7          	jalr	936(ra) # 80004198 <iunlockput>
  ip->nlink--;
    80005df8:	04a95783          	lhu	a5,74(s2)
    80005dfc:	37fd                	addiw	a5,a5,-1
    80005dfe:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e02:	854a                	mv	a0,s2
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	066080e7          	jalr	102(ra) # 80003e6a <iupdate>
  iunlockput(ip);
    80005e0c:	854a                	mv	a0,s2
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	38a080e7          	jalr	906(ra) # 80004198 <iunlockput>
  end_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	b6a080e7          	jalr	-1174(ra) # 80004980 <end_op>
  return 0;
    80005e1e:	4501                	li	a0,0
    80005e20:	a84d                	j	80005ed2 <sys_unlink+0x1c4>
    end_op();
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	b5e080e7          	jalr	-1186(ra) # 80004980 <end_op>
    return -1;
    80005e2a:	557d                	li	a0,-1
    80005e2c:	a05d                	j	80005ed2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e2e:	00003517          	auipc	a0,0x3
    80005e32:	a3250513          	addi	a0,a0,-1486 # 80008860 <syscalls+0x2d0>
    80005e36:	ffffa097          	auipc	ra,0xffffa
    80005e3a:	70a080e7          	jalr	1802(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e3e:	04c92703          	lw	a4,76(s2)
    80005e42:	02000793          	li	a5,32
    80005e46:	f6e7f9e3          	bgeu	a5,a4,80005db8 <sys_unlink+0xaa>
    80005e4a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e4e:	4741                	li	a4,16
    80005e50:	86ce                	mv	a3,s3
    80005e52:	f1840613          	addi	a2,s0,-232
    80005e56:	4581                	li	a1,0
    80005e58:	854a                	mv	a0,s2
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	390080e7          	jalr	912(ra) # 800041ea <readi>
    80005e62:	47c1                	li	a5,16
    80005e64:	00f51b63          	bne	a0,a5,80005e7a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e68:	f1845783          	lhu	a5,-232(s0)
    80005e6c:	e7a1                	bnez	a5,80005eb4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e6e:	29c1                	addiw	s3,s3,16
    80005e70:	04c92783          	lw	a5,76(s2)
    80005e74:	fcf9ede3          	bltu	s3,a5,80005e4e <sys_unlink+0x140>
    80005e78:	b781                	j	80005db8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e7a:	00003517          	auipc	a0,0x3
    80005e7e:	9fe50513          	addi	a0,a0,-1538 # 80008878 <syscalls+0x2e8>
    80005e82:	ffffa097          	auipc	ra,0xffffa
    80005e86:	6be080e7          	jalr	1726(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005e8a:	00003517          	auipc	a0,0x3
    80005e8e:	a0650513          	addi	a0,a0,-1530 # 80008890 <syscalls+0x300>
    80005e92:	ffffa097          	auipc	ra,0xffffa
    80005e96:	6ae080e7          	jalr	1710(ra) # 80000540 <panic>
    dp->nlink--;
    80005e9a:	04a4d783          	lhu	a5,74(s1)
    80005e9e:	37fd                	addiw	a5,a5,-1
    80005ea0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ea4:	8526                	mv	a0,s1
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	fc4080e7          	jalr	-60(ra) # 80003e6a <iupdate>
    80005eae:	b781                	j	80005dee <sys_unlink+0xe0>
    return -1;
    80005eb0:	557d                	li	a0,-1
    80005eb2:	a005                	j	80005ed2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005eb4:	854a                	mv	a0,s2
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	2e2080e7          	jalr	738(ra) # 80004198 <iunlockput>
  iunlockput(dp);
    80005ebe:	8526                	mv	a0,s1
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	2d8080e7          	jalr	728(ra) # 80004198 <iunlockput>
  end_op();
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	ab8080e7          	jalr	-1352(ra) # 80004980 <end_op>
  return -1;
    80005ed0:	557d                	li	a0,-1
}
    80005ed2:	70ae                	ld	ra,232(sp)
    80005ed4:	740e                	ld	s0,224(sp)
    80005ed6:	64ee                	ld	s1,216(sp)
    80005ed8:	694e                	ld	s2,208(sp)
    80005eda:	69ae                	ld	s3,200(sp)
    80005edc:	616d                	addi	sp,sp,240
    80005ede:	8082                	ret

0000000080005ee0 <sys_open>:

uint64
sys_open(void)
{
    80005ee0:	7131                	addi	sp,sp,-192
    80005ee2:	fd06                	sd	ra,184(sp)
    80005ee4:	f922                	sd	s0,176(sp)
    80005ee6:	f526                	sd	s1,168(sp)
    80005ee8:	f14a                	sd	s2,160(sp)
    80005eea:	ed4e                	sd	s3,152(sp)
    80005eec:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005eee:	f4c40593          	addi	a1,s0,-180
    80005ef2:	4505                	li	a0,1
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	27e080e7          	jalr	638(ra) # 80003172 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005efc:	08000613          	li	a2,128
    80005f00:	f5040593          	addi	a1,s0,-176
    80005f04:	4501                	li	a0,0
    80005f06:	ffffd097          	auipc	ra,0xffffd
    80005f0a:	2ac080e7          	jalr	684(ra) # 800031b2 <argstr>
    80005f0e:	87aa                	mv	a5,a0
    return -1;
    80005f10:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f12:	0a07c963          	bltz	a5,80005fc4 <sys_open+0xe4>

  begin_op();
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	9ec080e7          	jalr	-1556(ra) # 80004902 <begin_op>

  if(omode & O_CREATE){
    80005f1e:	f4c42783          	lw	a5,-180(s0)
    80005f22:	2007f793          	andi	a5,a5,512
    80005f26:	cfc5                	beqz	a5,80005fde <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f28:	4681                	li	a3,0
    80005f2a:	4601                	li	a2,0
    80005f2c:	4589                	li	a1,2
    80005f2e:	f5040513          	addi	a0,s0,-176
    80005f32:	00000097          	auipc	ra,0x0
    80005f36:	972080e7          	jalr	-1678(ra) # 800058a4 <create>
    80005f3a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f3c:	c959                	beqz	a0,80005fd2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f3e:	04449703          	lh	a4,68(s1)
    80005f42:	478d                	li	a5,3
    80005f44:	00f71763          	bne	a4,a5,80005f52 <sys_open+0x72>
    80005f48:	0464d703          	lhu	a4,70(s1)
    80005f4c:	47a5                	li	a5,9
    80005f4e:	0ce7ed63          	bltu	a5,a4,80006028 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	dbc080e7          	jalr	-580(ra) # 80004d0e <filealloc>
    80005f5a:	89aa                	mv	s3,a0
    80005f5c:	10050363          	beqz	a0,80006062 <sys_open+0x182>
    80005f60:	00000097          	auipc	ra,0x0
    80005f64:	902080e7          	jalr	-1790(ra) # 80005862 <fdalloc>
    80005f68:	892a                	mv	s2,a0
    80005f6a:	0e054763          	bltz	a0,80006058 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f6e:	04449703          	lh	a4,68(s1)
    80005f72:	478d                	li	a5,3
    80005f74:	0cf70563          	beq	a4,a5,8000603e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f78:	4789                	li	a5,2
    80005f7a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f7e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f82:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f86:	f4c42783          	lw	a5,-180(s0)
    80005f8a:	0017c713          	xori	a4,a5,1
    80005f8e:	8b05                	andi	a4,a4,1
    80005f90:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f94:	0037f713          	andi	a4,a5,3
    80005f98:	00e03733          	snez	a4,a4
    80005f9c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005fa0:	4007f793          	andi	a5,a5,1024
    80005fa4:	c791                	beqz	a5,80005fb0 <sys_open+0xd0>
    80005fa6:	04449703          	lh	a4,68(s1)
    80005faa:	4789                	li	a5,2
    80005fac:	0af70063          	beq	a4,a5,8000604c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005fb0:	8526                	mv	a0,s1
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	046080e7          	jalr	70(ra) # 80003ff8 <iunlock>
  end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	9c6080e7          	jalr	-1594(ra) # 80004980 <end_op>

  return fd;
    80005fc2:	854a                	mv	a0,s2
}
    80005fc4:	70ea                	ld	ra,184(sp)
    80005fc6:	744a                	ld	s0,176(sp)
    80005fc8:	74aa                	ld	s1,168(sp)
    80005fca:	790a                	ld	s2,160(sp)
    80005fcc:	69ea                	ld	s3,152(sp)
    80005fce:	6129                	addi	sp,sp,192
    80005fd0:	8082                	ret
      end_op();
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	9ae080e7          	jalr	-1618(ra) # 80004980 <end_op>
      return -1;
    80005fda:	557d                	li	a0,-1
    80005fdc:	b7e5                	j	80005fc4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fde:	f5040513          	addi	a0,s0,-176
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	700080e7          	jalr	1792(ra) # 800046e2 <namei>
    80005fea:	84aa                	mv	s1,a0
    80005fec:	c905                	beqz	a0,8000601c <sys_open+0x13c>
    ilock(ip);
    80005fee:	ffffe097          	auipc	ra,0xffffe
    80005ff2:	f48080e7          	jalr	-184(ra) # 80003f36 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ff6:	04449703          	lh	a4,68(s1)
    80005ffa:	4785                	li	a5,1
    80005ffc:	f4f711e3          	bne	a4,a5,80005f3e <sys_open+0x5e>
    80006000:	f4c42783          	lw	a5,-180(s0)
    80006004:	d7b9                	beqz	a5,80005f52 <sys_open+0x72>
      iunlockput(ip);
    80006006:	8526                	mv	a0,s1
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	190080e7          	jalr	400(ra) # 80004198 <iunlockput>
      end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	970080e7          	jalr	-1680(ra) # 80004980 <end_op>
      return -1;
    80006018:	557d                	li	a0,-1
    8000601a:	b76d                	j	80005fc4 <sys_open+0xe4>
      end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	964080e7          	jalr	-1692(ra) # 80004980 <end_op>
      return -1;
    80006024:	557d                	li	a0,-1
    80006026:	bf79                	j	80005fc4 <sys_open+0xe4>
    iunlockput(ip);
    80006028:	8526                	mv	a0,s1
    8000602a:	ffffe097          	auipc	ra,0xffffe
    8000602e:	16e080e7          	jalr	366(ra) # 80004198 <iunlockput>
    end_op();
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	94e080e7          	jalr	-1714(ra) # 80004980 <end_op>
    return -1;
    8000603a:	557d                	li	a0,-1
    8000603c:	b761                	j	80005fc4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000603e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006042:	04649783          	lh	a5,70(s1)
    80006046:	02f99223          	sh	a5,36(s3)
    8000604a:	bf25                	j	80005f82 <sys_open+0xa2>
    itrunc(ip);
    8000604c:	8526                	mv	a0,s1
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	ff6080e7          	jalr	-10(ra) # 80004044 <itrunc>
    80006056:	bfa9                	j	80005fb0 <sys_open+0xd0>
      fileclose(f);
    80006058:	854e                	mv	a0,s3
    8000605a:	fffff097          	auipc	ra,0xfffff
    8000605e:	d70080e7          	jalr	-656(ra) # 80004dca <fileclose>
    iunlockput(ip);
    80006062:	8526                	mv	a0,s1
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	134080e7          	jalr	308(ra) # 80004198 <iunlockput>
    end_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	914080e7          	jalr	-1772(ra) # 80004980 <end_op>
    return -1;
    80006074:	557d                	li	a0,-1
    80006076:	b7b9                	j	80005fc4 <sys_open+0xe4>

0000000080006078 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006078:	7175                	addi	sp,sp,-144
    8000607a:	e506                	sd	ra,136(sp)
    8000607c:	e122                	sd	s0,128(sp)
    8000607e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	882080e7          	jalr	-1918(ra) # 80004902 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006088:	08000613          	li	a2,128
    8000608c:	f7040593          	addi	a1,s0,-144
    80006090:	4501                	li	a0,0
    80006092:	ffffd097          	auipc	ra,0xffffd
    80006096:	120080e7          	jalr	288(ra) # 800031b2 <argstr>
    8000609a:	02054963          	bltz	a0,800060cc <sys_mkdir+0x54>
    8000609e:	4681                	li	a3,0
    800060a0:	4601                	li	a2,0
    800060a2:	4585                	li	a1,1
    800060a4:	f7040513          	addi	a0,s0,-144
    800060a8:	fffff097          	auipc	ra,0xfffff
    800060ac:	7fc080e7          	jalr	2044(ra) # 800058a4 <create>
    800060b0:	cd11                	beqz	a0,800060cc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	0e6080e7          	jalr	230(ra) # 80004198 <iunlockput>
  end_op();
    800060ba:	fffff097          	auipc	ra,0xfffff
    800060be:	8c6080e7          	jalr	-1850(ra) # 80004980 <end_op>
  return 0;
    800060c2:	4501                	li	a0,0
}
    800060c4:	60aa                	ld	ra,136(sp)
    800060c6:	640a                	ld	s0,128(sp)
    800060c8:	6149                	addi	sp,sp,144
    800060ca:	8082                	ret
    end_op();
    800060cc:	fffff097          	auipc	ra,0xfffff
    800060d0:	8b4080e7          	jalr	-1868(ra) # 80004980 <end_op>
    return -1;
    800060d4:	557d                	li	a0,-1
    800060d6:	b7fd                	j	800060c4 <sys_mkdir+0x4c>

00000000800060d8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060d8:	7135                	addi	sp,sp,-160
    800060da:	ed06                	sd	ra,152(sp)
    800060dc:	e922                	sd	s0,144(sp)
    800060de:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	822080e7          	jalr	-2014(ra) # 80004902 <begin_op>
  argint(1, &major);
    800060e8:	f6c40593          	addi	a1,s0,-148
    800060ec:	4505                	li	a0,1
    800060ee:	ffffd097          	auipc	ra,0xffffd
    800060f2:	084080e7          	jalr	132(ra) # 80003172 <argint>
  argint(2, &minor);
    800060f6:	f6840593          	addi	a1,s0,-152
    800060fa:	4509                	li	a0,2
    800060fc:	ffffd097          	auipc	ra,0xffffd
    80006100:	076080e7          	jalr	118(ra) # 80003172 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006104:	08000613          	li	a2,128
    80006108:	f7040593          	addi	a1,s0,-144
    8000610c:	4501                	li	a0,0
    8000610e:	ffffd097          	auipc	ra,0xffffd
    80006112:	0a4080e7          	jalr	164(ra) # 800031b2 <argstr>
    80006116:	02054b63          	bltz	a0,8000614c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000611a:	f6841683          	lh	a3,-152(s0)
    8000611e:	f6c41603          	lh	a2,-148(s0)
    80006122:	458d                	li	a1,3
    80006124:	f7040513          	addi	a0,s0,-144
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	77c080e7          	jalr	1916(ra) # 800058a4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006130:	cd11                	beqz	a0,8000614c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	066080e7          	jalr	102(ra) # 80004198 <iunlockput>
  end_op();
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	846080e7          	jalr	-1978(ra) # 80004980 <end_op>
  return 0;
    80006142:	4501                	li	a0,0
}
    80006144:	60ea                	ld	ra,152(sp)
    80006146:	644a                	ld	s0,144(sp)
    80006148:	610d                	addi	sp,sp,160
    8000614a:	8082                	ret
    end_op();
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	834080e7          	jalr	-1996(ra) # 80004980 <end_op>
    return -1;
    80006154:	557d                	li	a0,-1
    80006156:	b7fd                	j	80006144 <sys_mknod+0x6c>

0000000080006158 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006158:	7135                	addi	sp,sp,-160
    8000615a:	ed06                	sd	ra,152(sp)
    8000615c:	e922                	sd	s0,144(sp)
    8000615e:	e526                	sd	s1,136(sp)
    80006160:	e14a                	sd	s2,128(sp)
    80006162:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006164:	ffffc097          	auipc	ra,0xffffc
    80006168:	8e2080e7          	jalr	-1822(ra) # 80001a46 <myproc>
    8000616c:	892a                	mv	s2,a0
  
  begin_op();
    8000616e:	ffffe097          	auipc	ra,0xffffe
    80006172:	794080e7          	jalr	1940(ra) # 80004902 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006176:	08000613          	li	a2,128
    8000617a:	f6040593          	addi	a1,s0,-160
    8000617e:	4501                	li	a0,0
    80006180:	ffffd097          	auipc	ra,0xffffd
    80006184:	032080e7          	jalr	50(ra) # 800031b2 <argstr>
    80006188:	04054b63          	bltz	a0,800061de <sys_chdir+0x86>
    8000618c:	f6040513          	addi	a0,s0,-160
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	552080e7          	jalr	1362(ra) # 800046e2 <namei>
    80006198:	84aa                	mv	s1,a0
    8000619a:	c131                	beqz	a0,800061de <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	d9a080e7          	jalr	-614(ra) # 80003f36 <ilock>
  if(ip->type != T_DIR){
    800061a4:	04449703          	lh	a4,68(s1)
    800061a8:	4785                	li	a5,1
    800061aa:	04f71063          	bne	a4,a5,800061ea <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800061ae:	8526                	mv	a0,s1
    800061b0:	ffffe097          	auipc	ra,0xffffe
    800061b4:	e48080e7          	jalr	-440(ra) # 80003ff8 <iunlock>
  iput(p->cwd);
    800061b8:	15893503          	ld	a0,344(s2)
    800061bc:	ffffe097          	auipc	ra,0xffffe
    800061c0:	f34080e7          	jalr	-204(ra) # 800040f0 <iput>
  end_op();
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	7bc080e7          	jalr	1980(ra) # 80004980 <end_op>
  p->cwd = ip;
    800061cc:	14993c23          	sd	s1,344(s2)
  return 0;
    800061d0:	4501                	li	a0,0
}
    800061d2:	60ea                	ld	ra,152(sp)
    800061d4:	644a                	ld	s0,144(sp)
    800061d6:	64aa                	ld	s1,136(sp)
    800061d8:	690a                	ld	s2,128(sp)
    800061da:	610d                	addi	sp,sp,160
    800061dc:	8082                	ret
    end_op();
    800061de:	ffffe097          	auipc	ra,0xffffe
    800061e2:	7a2080e7          	jalr	1954(ra) # 80004980 <end_op>
    return -1;
    800061e6:	557d                	li	a0,-1
    800061e8:	b7ed                	j	800061d2 <sys_chdir+0x7a>
    iunlockput(ip);
    800061ea:	8526                	mv	a0,s1
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	fac080e7          	jalr	-84(ra) # 80004198 <iunlockput>
    end_op();
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	78c080e7          	jalr	1932(ra) # 80004980 <end_op>
    return -1;
    800061fc:	557d                	li	a0,-1
    800061fe:	bfd1                	j	800061d2 <sys_chdir+0x7a>

0000000080006200 <sys_exec>:

uint64
sys_exec(void)
{
    80006200:	7145                	addi	sp,sp,-464
    80006202:	e786                	sd	ra,456(sp)
    80006204:	e3a2                	sd	s0,448(sp)
    80006206:	ff26                	sd	s1,440(sp)
    80006208:	fb4a                	sd	s2,432(sp)
    8000620a:	f74e                	sd	s3,424(sp)
    8000620c:	f352                	sd	s4,416(sp)
    8000620e:	ef56                	sd	s5,408(sp)
    80006210:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006212:	e3840593          	addi	a1,s0,-456
    80006216:	4505                	li	a0,1
    80006218:	ffffd097          	auipc	ra,0xffffd
    8000621c:	f7a080e7          	jalr	-134(ra) # 80003192 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006220:	08000613          	li	a2,128
    80006224:	f4040593          	addi	a1,s0,-192
    80006228:	4501                	li	a0,0
    8000622a:	ffffd097          	auipc	ra,0xffffd
    8000622e:	f88080e7          	jalr	-120(ra) # 800031b2 <argstr>
    80006232:	87aa                	mv	a5,a0
    return -1;
    80006234:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006236:	0c07c363          	bltz	a5,800062fc <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000623a:	10000613          	li	a2,256
    8000623e:	4581                	li	a1,0
    80006240:	e4040513          	addi	a0,s0,-448
    80006244:	ffffb097          	auipc	ra,0xffffb
    80006248:	a8e080e7          	jalr	-1394(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000624c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006250:	89a6                	mv	s3,s1
    80006252:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006254:	02000a13          	li	s4,32
    80006258:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000625c:	00391513          	slli	a0,s2,0x3
    80006260:	e3040593          	addi	a1,s0,-464
    80006264:	e3843783          	ld	a5,-456(s0)
    80006268:	953e                	add	a0,a0,a5
    8000626a:	ffffd097          	auipc	ra,0xffffd
    8000626e:	e6a080e7          	jalr	-406(ra) # 800030d4 <fetchaddr>
    80006272:	02054a63          	bltz	a0,800062a6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006276:	e3043783          	ld	a5,-464(s0)
    8000627a:	c3b9                	beqz	a5,800062c0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	86a080e7          	jalr	-1942(ra) # 80000ae6 <kalloc>
    80006284:	85aa                	mv	a1,a0
    80006286:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000628a:	cd11                	beqz	a0,800062a6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000628c:	6605                	lui	a2,0x1
    8000628e:	e3043503          	ld	a0,-464(s0)
    80006292:	ffffd097          	auipc	ra,0xffffd
    80006296:	e94080e7          	jalr	-364(ra) # 80003126 <fetchstr>
    8000629a:	00054663          	bltz	a0,800062a6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000629e:	0905                	addi	s2,s2,1
    800062a0:	09a1                	addi	s3,s3,8
    800062a2:	fb491be3          	bne	s2,s4,80006258 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a6:	f4040913          	addi	s2,s0,-192
    800062aa:	6088                	ld	a0,0(s1)
    800062ac:	c539                	beqz	a0,800062fa <sys_exec+0xfa>
    kfree(argv[i]);
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	73a080e7          	jalr	1850(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062b6:	04a1                	addi	s1,s1,8
    800062b8:	ff2499e3          	bne	s1,s2,800062aa <sys_exec+0xaa>
  return -1;
    800062bc:	557d                	li	a0,-1
    800062be:	a83d                	j	800062fc <sys_exec+0xfc>
      argv[i] = 0;
    800062c0:	0a8e                	slli	s5,s5,0x3
    800062c2:	fc0a8793          	addi	a5,s5,-64
    800062c6:	00878ab3          	add	s5,a5,s0
    800062ca:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062ce:	e4040593          	addi	a1,s0,-448
    800062d2:	f4040513          	addi	a0,s0,-192
    800062d6:	fffff097          	auipc	ra,0xfffff
    800062da:	16e080e7          	jalr	366(ra) # 80005444 <exec>
    800062de:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062e0:	f4040993          	addi	s3,s0,-192
    800062e4:	6088                	ld	a0,0(s1)
    800062e6:	c901                	beqz	a0,800062f6 <sys_exec+0xf6>
    kfree(argv[i]);
    800062e8:	ffffa097          	auipc	ra,0xffffa
    800062ec:	700080e7          	jalr	1792(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062f0:	04a1                	addi	s1,s1,8
    800062f2:	ff3499e3          	bne	s1,s3,800062e4 <sys_exec+0xe4>
  return ret;
    800062f6:	854a                	mv	a0,s2
    800062f8:	a011                	j	800062fc <sys_exec+0xfc>
  return -1;
    800062fa:	557d                	li	a0,-1
}
    800062fc:	60be                	ld	ra,456(sp)
    800062fe:	641e                	ld	s0,448(sp)
    80006300:	74fa                	ld	s1,440(sp)
    80006302:	795a                	ld	s2,432(sp)
    80006304:	79ba                	ld	s3,424(sp)
    80006306:	7a1a                	ld	s4,416(sp)
    80006308:	6afa                	ld	s5,408(sp)
    8000630a:	6179                	addi	sp,sp,464
    8000630c:	8082                	ret

000000008000630e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000630e:	7139                	addi	sp,sp,-64
    80006310:	fc06                	sd	ra,56(sp)
    80006312:	f822                	sd	s0,48(sp)
    80006314:	f426                	sd	s1,40(sp)
    80006316:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006318:	ffffb097          	auipc	ra,0xffffb
    8000631c:	72e080e7          	jalr	1838(ra) # 80001a46 <myproc>
    80006320:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006322:	fd840593          	addi	a1,s0,-40
    80006326:	4501                	li	a0,0
    80006328:	ffffd097          	auipc	ra,0xffffd
    8000632c:	e6a080e7          	jalr	-406(ra) # 80003192 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006330:	fc840593          	addi	a1,s0,-56
    80006334:	fd040513          	addi	a0,s0,-48
    80006338:	fffff097          	auipc	ra,0xfffff
    8000633c:	dc2080e7          	jalr	-574(ra) # 800050fa <pipealloc>
    return -1;
    80006340:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006342:	0c054463          	bltz	a0,8000640a <sys_pipe+0xfc>
  fd0 = -1;
    80006346:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000634a:	fd043503          	ld	a0,-48(s0)
    8000634e:	fffff097          	auipc	ra,0xfffff
    80006352:	514080e7          	jalr	1300(ra) # 80005862 <fdalloc>
    80006356:	fca42223          	sw	a0,-60(s0)
    8000635a:	08054b63          	bltz	a0,800063f0 <sys_pipe+0xe2>
    8000635e:	fc843503          	ld	a0,-56(s0)
    80006362:	fffff097          	auipc	ra,0xfffff
    80006366:	500080e7          	jalr	1280(ra) # 80005862 <fdalloc>
    8000636a:	fca42023          	sw	a0,-64(s0)
    8000636e:	06054863          	bltz	a0,800063de <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006372:	4691                	li	a3,4
    80006374:	fc440613          	addi	a2,s0,-60
    80006378:	fd843583          	ld	a1,-40(s0)
    8000637c:	6ca8                	ld	a0,88(s1)
    8000637e:	ffffb097          	auipc	ra,0xffffb
    80006382:	2ee080e7          	jalr	750(ra) # 8000166c <copyout>
    80006386:	02054063          	bltz	a0,800063a6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000638a:	4691                	li	a3,4
    8000638c:	fc040613          	addi	a2,s0,-64
    80006390:	fd843583          	ld	a1,-40(s0)
    80006394:	0591                	addi	a1,a1,4
    80006396:	6ca8                	ld	a0,88(s1)
    80006398:	ffffb097          	auipc	ra,0xffffb
    8000639c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800063a0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063a2:	06055463          	bgez	a0,8000640a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800063a6:	fc442783          	lw	a5,-60(s0)
    800063aa:	07e9                	addi	a5,a5,26
    800063ac:	078e                	slli	a5,a5,0x3
    800063ae:	97a6                	add	a5,a5,s1
    800063b0:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800063b4:	fc042783          	lw	a5,-64(s0)
    800063b8:	07e9                	addi	a5,a5,26
    800063ba:	078e                	slli	a5,a5,0x3
    800063bc:	94be                	add	s1,s1,a5
    800063be:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800063c2:	fd043503          	ld	a0,-48(s0)
    800063c6:	fffff097          	auipc	ra,0xfffff
    800063ca:	a04080e7          	jalr	-1532(ra) # 80004dca <fileclose>
    fileclose(wf);
    800063ce:	fc843503          	ld	a0,-56(s0)
    800063d2:	fffff097          	auipc	ra,0xfffff
    800063d6:	9f8080e7          	jalr	-1544(ra) # 80004dca <fileclose>
    return -1;
    800063da:	57fd                	li	a5,-1
    800063dc:	a03d                	j	8000640a <sys_pipe+0xfc>
    if(fd0 >= 0)
    800063de:	fc442783          	lw	a5,-60(s0)
    800063e2:	0007c763          	bltz	a5,800063f0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800063e6:	07e9                	addi	a5,a5,26
    800063e8:	078e                	slli	a5,a5,0x3
    800063ea:	97a6                	add	a5,a5,s1
    800063ec:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    800063f0:	fd043503          	ld	a0,-48(s0)
    800063f4:	fffff097          	auipc	ra,0xfffff
    800063f8:	9d6080e7          	jalr	-1578(ra) # 80004dca <fileclose>
    fileclose(wf);
    800063fc:	fc843503          	ld	a0,-56(s0)
    80006400:	fffff097          	auipc	ra,0xfffff
    80006404:	9ca080e7          	jalr	-1590(ra) # 80004dca <fileclose>
    return -1;
    80006408:	57fd                	li	a5,-1
}
    8000640a:	853e                	mv	a0,a5
    8000640c:	70e2                	ld	ra,56(sp)
    8000640e:	7442                	ld	s0,48(sp)
    80006410:	74a2                	ld	s1,40(sp)
    80006412:	6121                	addi	sp,sp,64
    80006414:	8082                	ret
	...

0000000080006420 <kernelvec>:
    80006420:	7111                	addi	sp,sp,-256
    80006422:	e006                	sd	ra,0(sp)
    80006424:	e40a                	sd	sp,8(sp)
    80006426:	e80e                	sd	gp,16(sp)
    80006428:	ec12                	sd	tp,24(sp)
    8000642a:	f016                	sd	t0,32(sp)
    8000642c:	f41a                	sd	t1,40(sp)
    8000642e:	f81e                	sd	t2,48(sp)
    80006430:	fc22                	sd	s0,56(sp)
    80006432:	e0a6                	sd	s1,64(sp)
    80006434:	e4aa                	sd	a0,72(sp)
    80006436:	e8ae                	sd	a1,80(sp)
    80006438:	ecb2                	sd	a2,88(sp)
    8000643a:	f0b6                	sd	a3,96(sp)
    8000643c:	f4ba                	sd	a4,104(sp)
    8000643e:	f8be                	sd	a5,112(sp)
    80006440:	fcc2                	sd	a6,120(sp)
    80006442:	e146                	sd	a7,128(sp)
    80006444:	e54a                	sd	s2,136(sp)
    80006446:	e94e                	sd	s3,144(sp)
    80006448:	ed52                	sd	s4,152(sp)
    8000644a:	f156                	sd	s5,160(sp)
    8000644c:	f55a                	sd	s6,168(sp)
    8000644e:	f95e                	sd	s7,176(sp)
    80006450:	fd62                	sd	s8,184(sp)
    80006452:	e1e6                	sd	s9,192(sp)
    80006454:	e5ea                	sd	s10,200(sp)
    80006456:	e9ee                	sd	s11,208(sp)
    80006458:	edf2                	sd	t3,216(sp)
    8000645a:	f1f6                	sd	t4,224(sp)
    8000645c:	f5fa                	sd	t5,232(sp)
    8000645e:	f9fe                	sd	t6,240(sp)
    80006460:	b05fc0ef          	jal	ra,80002f64 <kerneltrap>
    80006464:	6082                	ld	ra,0(sp)
    80006466:	6122                	ld	sp,8(sp)
    80006468:	61c2                	ld	gp,16(sp)
    8000646a:	7282                	ld	t0,32(sp)
    8000646c:	7322                	ld	t1,40(sp)
    8000646e:	73c2                	ld	t2,48(sp)
    80006470:	7462                	ld	s0,56(sp)
    80006472:	6486                	ld	s1,64(sp)
    80006474:	6526                	ld	a0,72(sp)
    80006476:	65c6                	ld	a1,80(sp)
    80006478:	6666                	ld	a2,88(sp)
    8000647a:	7686                	ld	a3,96(sp)
    8000647c:	7726                	ld	a4,104(sp)
    8000647e:	77c6                	ld	a5,112(sp)
    80006480:	7866                	ld	a6,120(sp)
    80006482:	688a                	ld	a7,128(sp)
    80006484:	692a                	ld	s2,136(sp)
    80006486:	69ca                	ld	s3,144(sp)
    80006488:	6a6a                	ld	s4,152(sp)
    8000648a:	7a8a                	ld	s5,160(sp)
    8000648c:	7b2a                	ld	s6,168(sp)
    8000648e:	7bca                	ld	s7,176(sp)
    80006490:	7c6a                	ld	s8,184(sp)
    80006492:	6c8e                	ld	s9,192(sp)
    80006494:	6d2e                	ld	s10,200(sp)
    80006496:	6dce                	ld	s11,208(sp)
    80006498:	6e6e                	ld	t3,216(sp)
    8000649a:	7e8e                	ld	t4,224(sp)
    8000649c:	7f2e                	ld	t5,232(sp)
    8000649e:	7fce                	ld	t6,240(sp)
    800064a0:	6111                	addi	sp,sp,256
    800064a2:	10200073          	sret
    800064a6:	00000013          	nop
    800064aa:	00000013          	nop
    800064ae:	0001                	nop

00000000800064b0 <timervec>:
    800064b0:	34051573          	csrrw	a0,mscratch,a0
    800064b4:	e10c                	sd	a1,0(a0)
    800064b6:	e510                	sd	a2,8(a0)
    800064b8:	e914                	sd	a3,16(a0)
    800064ba:	6d0c                	ld	a1,24(a0)
    800064bc:	7110                	ld	a2,32(a0)
    800064be:	6194                	ld	a3,0(a1)
    800064c0:	96b2                	add	a3,a3,a2
    800064c2:	e194                	sd	a3,0(a1)
    800064c4:	4589                	li	a1,2
    800064c6:	14459073          	csrw	sip,a1
    800064ca:	6914                	ld	a3,16(a0)
    800064cc:	6510                	ld	a2,8(a0)
    800064ce:	610c                	ld	a1,0(a0)
    800064d0:	34051573          	csrrw	a0,mscratch,a0
    800064d4:	30200073          	mret
	...

00000000800064da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064da:	1141                	addi	sp,sp,-16
    800064dc:	e422                	sd	s0,8(sp)
    800064de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064e0:	0c0007b7          	lui	a5,0xc000
    800064e4:	4705                	li	a4,1
    800064e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064e8:	c3d8                	sw	a4,4(a5)
}
    800064ea:	6422                	ld	s0,8(sp)
    800064ec:	0141                	addi	sp,sp,16
    800064ee:	8082                	ret

00000000800064f0 <plicinithart>:

void
plicinithart(void)
{
    800064f0:	1141                	addi	sp,sp,-16
    800064f2:	e406                	sd	ra,8(sp)
    800064f4:	e022                	sd	s0,0(sp)
    800064f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064f8:	ffffb097          	auipc	ra,0xffffb
    800064fc:	522080e7          	jalr	1314(ra) # 80001a1a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006500:	0085171b          	slliw	a4,a0,0x8
    80006504:	0c0027b7          	lui	a5,0xc002
    80006508:	97ba                	add	a5,a5,a4
    8000650a:	40200713          	li	a4,1026
    8000650e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006512:	00d5151b          	slliw	a0,a0,0xd
    80006516:	0c2017b7          	lui	a5,0xc201
    8000651a:	97aa                	add	a5,a5,a0
    8000651c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006520:	60a2                	ld	ra,8(sp)
    80006522:	6402                	ld	s0,0(sp)
    80006524:	0141                	addi	sp,sp,16
    80006526:	8082                	ret

0000000080006528 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006528:	1141                	addi	sp,sp,-16
    8000652a:	e406                	sd	ra,8(sp)
    8000652c:	e022                	sd	s0,0(sp)
    8000652e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006530:	ffffb097          	auipc	ra,0xffffb
    80006534:	4ea080e7          	jalr	1258(ra) # 80001a1a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006538:	00d5151b          	slliw	a0,a0,0xd
    8000653c:	0c2017b7          	lui	a5,0xc201
    80006540:	97aa                	add	a5,a5,a0
  return irq;
}
    80006542:	43c8                	lw	a0,4(a5)
    80006544:	60a2                	ld	ra,8(sp)
    80006546:	6402                	ld	s0,0(sp)
    80006548:	0141                	addi	sp,sp,16
    8000654a:	8082                	ret

000000008000654c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000654c:	1101                	addi	sp,sp,-32
    8000654e:	ec06                	sd	ra,24(sp)
    80006550:	e822                	sd	s0,16(sp)
    80006552:	e426                	sd	s1,8(sp)
    80006554:	1000                	addi	s0,sp,32
    80006556:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006558:	ffffb097          	auipc	ra,0xffffb
    8000655c:	4c2080e7          	jalr	1218(ra) # 80001a1a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006560:	00d5151b          	slliw	a0,a0,0xd
    80006564:	0c2017b7          	lui	a5,0xc201
    80006568:	97aa                	add	a5,a5,a0
    8000656a:	c3c4                	sw	s1,4(a5)
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	addi	sp,sp,32
    80006574:	8082                	ret

0000000080006576 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006576:	1141                	addi	sp,sp,-16
    80006578:	e406                	sd	ra,8(sp)
    8000657a:	e022                	sd	s0,0(sp)
    8000657c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000657e:	479d                	li	a5,7
    80006580:	04a7cc63          	blt	a5,a0,800065d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006584:	0001d797          	auipc	a5,0x1d
    80006588:	63c78793          	addi	a5,a5,1596 # 80023bc0 <disk>
    8000658c:	97aa                	add	a5,a5,a0
    8000658e:	0187c783          	lbu	a5,24(a5)
    80006592:	ebb9                	bnez	a5,800065e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006594:	00451693          	slli	a3,a0,0x4
    80006598:	0001d797          	auipc	a5,0x1d
    8000659c:	62878793          	addi	a5,a5,1576 # 80023bc0 <disk>
    800065a0:	6398                	ld	a4,0(a5)
    800065a2:	9736                	add	a4,a4,a3
    800065a4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800065a8:	6398                	ld	a4,0(a5)
    800065aa:	9736                	add	a4,a4,a3
    800065ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800065b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800065b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800065b8:	97aa                	add	a5,a5,a0
    800065ba:	4705                	li	a4,1
    800065bc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800065c0:	0001d517          	auipc	a0,0x1d
    800065c4:	61850513          	addi	a0,a0,1560 # 80023bd8 <disk+0x18>
    800065c8:	ffffc097          	auipc	ra,0xffffc
    800065cc:	e36080e7          	jalr	-458(ra) # 800023fe <wakeup>
}
    800065d0:	60a2                	ld	ra,8(sp)
    800065d2:	6402                	ld	s0,0(sp)
    800065d4:	0141                	addi	sp,sp,16
    800065d6:	8082                	ret
    panic("free_desc 1");
    800065d8:	00002517          	auipc	a0,0x2
    800065dc:	2c850513          	addi	a0,a0,712 # 800088a0 <syscalls+0x310>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	f60080e7          	jalr	-160(ra) # 80000540 <panic>
    panic("free_desc 2");
    800065e8:	00002517          	auipc	a0,0x2
    800065ec:	2c850513          	addi	a0,a0,712 # 800088b0 <syscalls+0x320>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	f50080e7          	jalr	-176(ra) # 80000540 <panic>

00000000800065f8 <virtio_disk_init>:
{
    800065f8:	1101                	addi	sp,sp,-32
    800065fa:	ec06                	sd	ra,24(sp)
    800065fc:	e822                	sd	s0,16(sp)
    800065fe:	e426                	sd	s1,8(sp)
    80006600:	e04a                	sd	s2,0(sp)
    80006602:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006604:	00002597          	auipc	a1,0x2
    80006608:	2bc58593          	addi	a1,a1,700 # 800088c0 <syscalls+0x330>
    8000660c:	0001d517          	auipc	a0,0x1d
    80006610:	6dc50513          	addi	a0,a0,1756 # 80023ce8 <disk+0x128>
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	532080e7          	jalr	1330(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000661c:	100017b7          	lui	a5,0x10001
    80006620:	4398                	lw	a4,0(a5)
    80006622:	2701                	sext.w	a4,a4
    80006624:	747277b7          	lui	a5,0x74727
    80006628:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000662c:	14f71b63          	bne	a4,a5,80006782 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006630:	100017b7          	lui	a5,0x10001
    80006634:	43dc                	lw	a5,4(a5)
    80006636:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006638:	4709                	li	a4,2
    8000663a:	14e79463          	bne	a5,a4,80006782 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000663e:	100017b7          	lui	a5,0x10001
    80006642:	479c                	lw	a5,8(a5)
    80006644:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006646:	12e79e63          	bne	a5,a4,80006782 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000664a:	100017b7          	lui	a5,0x10001
    8000664e:	47d8                	lw	a4,12(a5)
    80006650:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006652:	554d47b7          	lui	a5,0x554d4
    80006656:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000665a:	12f71463          	bne	a4,a5,80006782 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000665e:	100017b7          	lui	a5,0x10001
    80006662:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006666:	4705                	li	a4,1
    80006668:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000666a:	470d                	li	a4,3
    8000666c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000666e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006670:	c7ffe6b7          	lui	a3,0xc7ffe
    80006674:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fda01f>
    80006678:	8f75                	and	a4,a4,a3
    8000667a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000667c:	472d                	li	a4,11
    8000667e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006680:	5bbc                	lw	a5,112(a5)
    80006682:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006686:	8ba1                	andi	a5,a5,8
    80006688:	10078563          	beqz	a5,80006792 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000668c:	100017b7          	lui	a5,0x10001
    80006690:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006694:	43fc                	lw	a5,68(a5)
    80006696:	2781                	sext.w	a5,a5
    80006698:	10079563          	bnez	a5,800067a2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000669c:	100017b7          	lui	a5,0x10001
    800066a0:	5bdc                	lw	a5,52(a5)
    800066a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800066a4:	10078763          	beqz	a5,800067b2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800066a8:	471d                	li	a4,7
    800066aa:	10f77c63          	bgeu	a4,a5,800067c2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	438080e7          	jalr	1080(ra) # 80000ae6 <kalloc>
    800066b6:	0001d497          	auipc	s1,0x1d
    800066ba:	50a48493          	addi	s1,s1,1290 # 80023bc0 <disk>
    800066be:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	426080e7          	jalr	1062(ra) # 80000ae6 <kalloc>
    800066c8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	41c080e7          	jalr	1052(ra) # 80000ae6 <kalloc>
    800066d2:	87aa                	mv	a5,a0
    800066d4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800066d6:	6088                	ld	a0,0(s1)
    800066d8:	cd6d                	beqz	a0,800067d2 <virtio_disk_init+0x1da>
    800066da:	0001d717          	auipc	a4,0x1d
    800066de:	4ee73703          	ld	a4,1262(a4) # 80023bc8 <disk+0x8>
    800066e2:	cb65                	beqz	a4,800067d2 <virtio_disk_init+0x1da>
    800066e4:	c7fd                	beqz	a5,800067d2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800066e6:	6605                	lui	a2,0x1
    800066e8:	4581                	li	a1,0
    800066ea:	ffffa097          	auipc	ra,0xffffa
    800066ee:	5e8080e7          	jalr	1512(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800066f2:	0001d497          	auipc	s1,0x1d
    800066f6:	4ce48493          	addi	s1,s1,1230 # 80023bc0 <disk>
    800066fa:	6605                	lui	a2,0x1
    800066fc:	4581                	li	a1,0
    800066fe:	6488                	ld	a0,8(s1)
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	5d2080e7          	jalr	1490(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006708:	6605                	lui	a2,0x1
    8000670a:	4581                	li	a1,0
    8000670c:	6888                	ld	a0,16(s1)
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	5c4080e7          	jalr	1476(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006716:	100017b7          	lui	a5,0x10001
    8000671a:	4721                	li	a4,8
    8000671c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000671e:	4098                	lw	a4,0(s1)
    80006720:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006724:	40d8                	lw	a4,4(s1)
    80006726:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000672a:	6498                	ld	a4,8(s1)
    8000672c:	0007069b          	sext.w	a3,a4
    80006730:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006734:	9701                	srai	a4,a4,0x20
    80006736:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000673a:	6898                	ld	a4,16(s1)
    8000673c:	0007069b          	sext.w	a3,a4
    80006740:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006744:	9701                	srai	a4,a4,0x20
    80006746:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000674a:	4705                	li	a4,1
    8000674c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000674e:	00e48c23          	sb	a4,24(s1)
    80006752:	00e48ca3          	sb	a4,25(s1)
    80006756:	00e48d23          	sb	a4,26(s1)
    8000675a:	00e48da3          	sb	a4,27(s1)
    8000675e:	00e48e23          	sb	a4,28(s1)
    80006762:	00e48ea3          	sb	a4,29(s1)
    80006766:	00e48f23          	sb	a4,30(s1)
    8000676a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000676e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006772:	0727a823          	sw	s2,112(a5)
}
    80006776:	60e2                	ld	ra,24(sp)
    80006778:	6442                	ld	s0,16(sp)
    8000677a:	64a2                	ld	s1,8(sp)
    8000677c:	6902                	ld	s2,0(sp)
    8000677e:	6105                	addi	sp,sp,32
    80006780:	8082                	ret
    panic("could not find virtio disk");
    80006782:	00002517          	auipc	a0,0x2
    80006786:	14e50513          	addi	a0,a0,334 # 800088d0 <syscalls+0x340>
    8000678a:	ffffa097          	auipc	ra,0xffffa
    8000678e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006792:	00002517          	auipc	a0,0x2
    80006796:	15e50513          	addi	a0,a0,350 # 800088f0 <syscalls+0x360>
    8000679a:	ffffa097          	auipc	ra,0xffffa
    8000679e:	da6080e7          	jalr	-602(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800067a2:	00002517          	auipc	a0,0x2
    800067a6:	16e50513          	addi	a0,a0,366 # 80008910 <syscalls+0x380>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	d96080e7          	jalr	-618(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800067b2:	00002517          	auipc	a0,0x2
    800067b6:	17e50513          	addi	a0,a0,382 # 80008930 <syscalls+0x3a0>
    800067ba:	ffffa097          	auipc	ra,0xffffa
    800067be:	d86080e7          	jalr	-634(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800067c2:	00002517          	auipc	a0,0x2
    800067c6:	18e50513          	addi	a0,a0,398 # 80008950 <syscalls+0x3c0>
    800067ca:	ffffa097          	auipc	ra,0xffffa
    800067ce:	d76080e7          	jalr	-650(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800067d2:	00002517          	auipc	a0,0x2
    800067d6:	19e50513          	addi	a0,a0,414 # 80008970 <syscalls+0x3e0>
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	d66080e7          	jalr	-666(ra) # 80000540 <panic>

00000000800067e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067e2:	7119                	addi	sp,sp,-128
    800067e4:	fc86                	sd	ra,120(sp)
    800067e6:	f8a2                	sd	s0,112(sp)
    800067e8:	f4a6                	sd	s1,104(sp)
    800067ea:	f0ca                	sd	s2,96(sp)
    800067ec:	ecce                	sd	s3,88(sp)
    800067ee:	e8d2                	sd	s4,80(sp)
    800067f0:	e4d6                	sd	s5,72(sp)
    800067f2:	e0da                	sd	s6,64(sp)
    800067f4:	fc5e                	sd	s7,56(sp)
    800067f6:	f862                	sd	s8,48(sp)
    800067f8:	f466                	sd	s9,40(sp)
    800067fa:	f06a                	sd	s10,32(sp)
    800067fc:	ec6e                	sd	s11,24(sp)
    800067fe:	0100                	addi	s0,sp,128
    80006800:	8aaa                	mv	s5,a0
    80006802:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006804:	00c52d03          	lw	s10,12(a0)
    80006808:	001d1d1b          	slliw	s10,s10,0x1
    8000680c:	1d02                	slli	s10,s10,0x20
    8000680e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006812:	0001d517          	auipc	a0,0x1d
    80006816:	4d650513          	addi	a0,a0,1238 # 80023ce8 <disk+0x128>
    8000681a:	ffffa097          	auipc	ra,0xffffa
    8000681e:	3bc080e7          	jalr	956(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006822:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006824:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006826:	0001db97          	auipc	s7,0x1d
    8000682a:	39ab8b93          	addi	s7,s7,922 # 80023bc0 <disk>
  for(int i = 0; i < 3; i++){
    8000682e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006830:	0001dc97          	auipc	s9,0x1d
    80006834:	4b8c8c93          	addi	s9,s9,1208 # 80023ce8 <disk+0x128>
    80006838:	a08d                	j	8000689a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000683a:	00fb8733          	add	a4,s7,a5
    8000683e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006842:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006844:	0207c563          	bltz	a5,8000686e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006848:	2905                	addiw	s2,s2,1
    8000684a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000684c:	05690c63          	beq	s2,s6,800068a4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006850:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006852:	0001d717          	auipc	a4,0x1d
    80006856:	36e70713          	addi	a4,a4,878 # 80023bc0 <disk>
    8000685a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000685c:	01874683          	lbu	a3,24(a4)
    80006860:	fee9                	bnez	a3,8000683a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006862:	2785                	addiw	a5,a5,1
    80006864:	0705                	addi	a4,a4,1
    80006866:	fe979be3          	bne	a5,s1,8000685c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000686a:	57fd                	li	a5,-1
    8000686c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000686e:	01205d63          	blez	s2,80006888 <virtio_disk_rw+0xa6>
    80006872:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006874:	000a2503          	lw	a0,0(s4)
    80006878:	00000097          	auipc	ra,0x0
    8000687c:	cfe080e7          	jalr	-770(ra) # 80006576 <free_desc>
      for(int j = 0; j < i; j++)
    80006880:	2d85                	addiw	s11,s11,1
    80006882:	0a11                	addi	s4,s4,4
    80006884:	ff2d98e3          	bne	s11,s2,80006874 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006888:	85e6                	mv	a1,s9
    8000688a:	0001d517          	auipc	a0,0x1d
    8000688e:	34e50513          	addi	a0,a0,846 # 80023bd8 <disk+0x18>
    80006892:	ffffc097          	auipc	ra,0xffffc
    80006896:	af2080e7          	jalr	-1294(ra) # 80002384 <sleep>
  for(int i = 0; i < 3; i++){
    8000689a:	f8040a13          	addi	s4,s0,-128
{
    8000689e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800068a0:	894e                	mv	s2,s3
    800068a2:	b77d                	j	80006850 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068a4:	f8042503          	lw	a0,-128(s0)
    800068a8:	00a50713          	addi	a4,a0,10
    800068ac:	0712                	slli	a4,a4,0x4

  if(write)
    800068ae:	0001d797          	auipc	a5,0x1d
    800068b2:	31278793          	addi	a5,a5,786 # 80023bc0 <disk>
    800068b6:	00e786b3          	add	a3,a5,a4
    800068ba:	01803633          	snez	a2,s8
    800068be:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068c0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800068c4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c8:	f6070613          	addi	a2,a4,-160
    800068cc:	6394                	ld	a3,0(a5)
    800068ce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068d0:	00870593          	addi	a1,a4,8
    800068d4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800068d6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068d8:	0007b803          	ld	a6,0(a5)
    800068dc:	9642                	add	a2,a2,a6
    800068de:	46c1                	li	a3,16
    800068e0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068e2:	4585                	li	a1,1
    800068e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800068e8:	f8442683          	lw	a3,-124(s0)
    800068ec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068f0:	0692                	slli	a3,a3,0x4
    800068f2:	9836                	add	a6,a6,a3
    800068f4:	058a8613          	addi	a2,s5,88
    800068f8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800068fc:	0007b803          	ld	a6,0(a5)
    80006900:	96c2                	add	a3,a3,a6
    80006902:	40000613          	li	a2,1024
    80006906:	c690                	sw	a2,8(a3)
  if(write)
    80006908:	001c3613          	seqz	a2,s8
    8000690c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006910:	00166613          	ori	a2,a2,1
    80006914:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006918:	f8842603          	lw	a2,-120(s0)
    8000691c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006920:	00250693          	addi	a3,a0,2
    80006924:	0692                	slli	a3,a3,0x4
    80006926:	96be                	add	a3,a3,a5
    80006928:	58fd                	li	a7,-1
    8000692a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000692e:	0612                	slli	a2,a2,0x4
    80006930:	9832                	add	a6,a6,a2
    80006932:	f9070713          	addi	a4,a4,-112
    80006936:	973e                	add	a4,a4,a5
    80006938:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000693c:	6398                	ld	a4,0(a5)
    8000693e:	9732                	add	a4,a4,a2
    80006940:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006942:	4609                	li	a2,2
    80006944:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006948:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000694c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006950:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006954:	6794                	ld	a3,8(a5)
    80006956:	0026d703          	lhu	a4,2(a3)
    8000695a:	8b1d                	andi	a4,a4,7
    8000695c:	0706                	slli	a4,a4,0x1
    8000695e:	96ba                	add	a3,a3,a4
    80006960:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006964:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006968:	6798                	ld	a4,8(a5)
    8000696a:	00275783          	lhu	a5,2(a4)
    8000696e:	2785                	addiw	a5,a5,1
    80006970:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006974:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006978:	100017b7          	lui	a5,0x10001
    8000697c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006980:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006984:	0001d917          	auipc	s2,0x1d
    80006988:	36490913          	addi	s2,s2,868 # 80023ce8 <disk+0x128>
  while(b->disk == 1) {
    8000698c:	4485                	li	s1,1
    8000698e:	00b79c63          	bne	a5,a1,800069a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006992:	85ca                	mv	a1,s2
    80006994:	8556                	mv	a0,s5
    80006996:	ffffc097          	auipc	ra,0xffffc
    8000699a:	9ee080e7          	jalr	-1554(ra) # 80002384 <sleep>
  while(b->disk == 1) {
    8000699e:	004aa783          	lw	a5,4(s5)
    800069a2:	fe9788e3          	beq	a5,s1,80006992 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800069a6:	f8042903          	lw	s2,-128(s0)
    800069aa:	00290713          	addi	a4,s2,2
    800069ae:	0712                	slli	a4,a4,0x4
    800069b0:	0001d797          	auipc	a5,0x1d
    800069b4:	21078793          	addi	a5,a5,528 # 80023bc0 <disk>
    800069b8:	97ba                	add	a5,a5,a4
    800069ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800069be:	0001d997          	auipc	s3,0x1d
    800069c2:	20298993          	addi	s3,s3,514 # 80023bc0 <disk>
    800069c6:	00491713          	slli	a4,s2,0x4
    800069ca:	0009b783          	ld	a5,0(s3)
    800069ce:	97ba                	add	a5,a5,a4
    800069d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800069d4:	854a                	mv	a0,s2
    800069d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800069da:	00000097          	auipc	ra,0x0
    800069de:	b9c080e7          	jalr	-1124(ra) # 80006576 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069e2:	8885                	andi	s1,s1,1
    800069e4:	f0ed                	bnez	s1,800069c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069e6:	0001d517          	auipc	a0,0x1d
    800069ea:	30250513          	addi	a0,a0,770 # 80023ce8 <disk+0x128>
    800069ee:	ffffa097          	auipc	ra,0xffffa
    800069f2:	29c080e7          	jalr	668(ra) # 80000c8a <release>
}
    800069f6:	70e6                	ld	ra,120(sp)
    800069f8:	7446                	ld	s0,112(sp)
    800069fa:	74a6                	ld	s1,104(sp)
    800069fc:	7906                	ld	s2,96(sp)
    800069fe:	69e6                	ld	s3,88(sp)
    80006a00:	6a46                	ld	s4,80(sp)
    80006a02:	6aa6                	ld	s5,72(sp)
    80006a04:	6b06                	ld	s6,64(sp)
    80006a06:	7be2                	ld	s7,56(sp)
    80006a08:	7c42                	ld	s8,48(sp)
    80006a0a:	7ca2                	ld	s9,40(sp)
    80006a0c:	7d02                	ld	s10,32(sp)
    80006a0e:	6de2                	ld	s11,24(sp)
    80006a10:	6109                	addi	sp,sp,128
    80006a12:	8082                	ret

0000000080006a14 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a14:	1101                	addi	sp,sp,-32
    80006a16:	ec06                	sd	ra,24(sp)
    80006a18:	e822                	sd	s0,16(sp)
    80006a1a:	e426                	sd	s1,8(sp)
    80006a1c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a1e:	0001d497          	auipc	s1,0x1d
    80006a22:	1a248493          	addi	s1,s1,418 # 80023bc0 <disk>
    80006a26:	0001d517          	auipc	a0,0x1d
    80006a2a:	2c250513          	addi	a0,a0,706 # 80023ce8 <disk+0x128>
    80006a2e:	ffffa097          	auipc	ra,0xffffa
    80006a32:	1a8080e7          	jalr	424(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a36:	10001737          	lui	a4,0x10001
    80006a3a:	533c                	lw	a5,96(a4)
    80006a3c:	8b8d                	andi	a5,a5,3
    80006a3e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a40:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a44:	689c                	ld	a5,16(s1)
    80006a46:	0204d703          	lhu	a4,32(s1)
    80006a4a:	0027d783          	lhu	a5,2(a5)
    80006a4e:	04f70863          	beq	a4,a5,80006a9e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a52:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a56:	6898                	ld	a4,16(s1)
    80006a58:	0204d783          	lhu	a5,32(s1)
    80006a5c:	8b9d                	andi	a5,a5,7
    80006a5e:	078e                	slli	a5,a5,0x3
    80006a60:	97ba                	add	a5,a5,a4
    80006a62:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a64:	00278713          	addi	a4,a5,2
    80006a68:	0712                	slli	a4,a4,0x4
    80006a6a:	9726                	add	a4,a4,s1
    80006a6c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a70:	e721                	bnez	a4,80006ab8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a72:	0789                	addi	a5,a5,2
    80006a74:	0792                	slli	a5,a5,0x4
    80006a76:	97a6                	add	a5,a5,s1
    80006a78:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a7a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a7e:	ffffc097          	auipc	ra,0xffffc
    80006a82:	980080e7          	jalr	-1664(ra) # 800023fe <wakeup>

    disk.used_idx += 1;
    80006a86:	0204d783          	lhu	a5,32(s1)
    80006a8a:	2785                	addiw	a5,a5,1
    80006a8c:	17c2                	slli	a5,a5,0x30
    80006a8e:	93c1                	srli	a5,a5,0x30
    80006a90:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a94:	6898                	ld	a4,16(s1)
    80006a96:	00275703          	lhu	a4,2(a4)
    80006a9a:	faf71ce3          	bne	a4,a5,80006a52 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a9e:	0001d517          	auipc	a0,0x1d
    80006aa2:	24a50513          	addi	a0,a0,586 # 80023ce8 <disk+0x128>
    80006aa6:	ffffa097          	auipc	ra,0xffffa
    80006aaa:	1e4080e7          	jalr	484(ra) # 80000c8a <release>
}
    80006aae:	60e2                	ld	ra,24(sp)
    80006ab0:	6442                	ld	s0,16(sp)
    80006ab2:	64a2                	ld	s1,8(sp)
    80006ab4:	6105                	addi	sp,sp,32
    80006ab6:	8082                	ret
      panic("virtio_disk_intr status");
    80006ab8:	00002517          	auipc	a0,0x2
    80006abc:	ed050513          	addi	a0,a0,-304 # 80008988 <syscalls+0x3f8>
    80006ac0:	ffffa097          	auipc	ra,0xffffa
    80006ac4:	a80080e7          	jalr	-1408(ra) # 80000540 <panic>

0000000080006ac8 <queue_init>:

struct queue_info queue_info;
struct proc *sched_queue[NQUEUE][NPROC];

void queue_init()
{
    80006ac8:	1141                	addi	sp,sp,-16
    80006aca:	e422                	sd	s0,8(sp)
    80006acc:	0800                	addi	s0,sp,16
    for (int i = 0; i < NQUEUE; i++)
    80006ace:	0001d797          	auipc	a5,0x1d
    80006ad2:	23278793          	addi	a5,a5,562 # 80023d00 <queue_info>
    80006ad6:	4701                	li	a4,0
    {
        queue_info.max_ticks[i] = 1 << i;
    80006ad8:	4585                	li	a1,1
    for (int i = 0; i < NQUEUE; i++)
    80006ada:	4615                	li	a2,5
        queue_info.max_ticks[i] = 1 << i;
    80006adc:	00e596bb          	sllw	a3,a1,a4
    80006ae0:	cbd4                	sw	a3,20(a5)
        queue_info.num_procs[i] = 0;
    80006ae2:	0007a023          	sw	zero,0(a5)
        queue_info.last[i] = 0;
    80006ae6:	0207a423          	sw	zero,40(a5)
    for (int i = 0; i < NQUEUE; i++)
    80006aea:	2705                	addiw	a4,a4,1
    80006aec:	0791                	addi	a5,a5,4
    80006aee:	fec717e3          	bne	a4,a2,80006adc <queue_init+0x14>
    }
}
    80006af2:	6422                	ld	s0,8(sp)
    80006af4:	0141                	addi	sp,sp,16
    80006af6:	8082                	ret

0000000080006af8 <queue_insert>:

void queue_insert(struct proc *p, int queue_no)
{
    80006af8:	1101                	addi	sp,sp,-32
    80006afa:	ec06                	sd	ra,24(sp)
    80006afc:	e822                	sd	s0,16(sp)
    80006afe:	e426                	sd	s1,8(sp)
    80006b00:	e04a                	sd	s2,0(sp)
    80006b02:	1000                	addi	s0,sp,32
    queue_no += NQUEUE * 10000; // to handle negative queue numbers
    80006b04:	64b1                	lui	s1,0xc
    80006b06:	3504849b          	addiw	s1,s1,848 # c350 <_entry-0x7fff3cb0>
    80006b0a:	9cad                	addw	s1,s1,a1
    queue_no %= NQUEUE;         // to handle queue numbers > 5
    80006b0c:	4795                	li	a5,5
    80006b0e:	02f4e4bb          	remw	s1,s1,a5
    if (queue_info.last[queue_no] > NPROC)
    80006b12:	00848713          	addi	a4,s1,8
    80006b16:	070a                	slli	a4,a4,0x2
    80006b18:	0001d797          	auipc	a5,0x1d
    80006b1c:	1e878793          	addi	a5,a5,488 # 80023d00 <queue_info>
    80006b20:	97ba                	add	a5,a5,a4
    80006b22:	479c                	lw	a5,8(a5)
    80006b24:	04000713          	li	a4,64
    80006b28:	06f74263          	blt	a4,a5,80006b8c <queue_insert+0x94>
    80006b2c:	892a                	mv	s2,a0
    {
        panic("MLFQ: Number of processes in current queue exceeds limit");
        return;
    }
    sched_queue[queue_no][queue_info.last[queue_no]] = p;
    80006b2e:	00649713          	slli	a4,s1,0x6
    80006b32:	973e                	add	a4,a4,a5
    80006b34:	070e                	slli	a4,a4,0x3
    80006b36:	0001d697          	auipc	a3,0x1d
    80006b3a:	20a68693          	addi	a3,a3,522 # 80023d40 <sched_queue>
    80006b3e:	9736                	add	a4,a4,a3
    80006b40:	e308                	sd	a0,0(a4)
    queue_info.last[queue_no]++;
    80006b42:	0001d717          	auipc	a4,0x1d
    80006b46:	1be70713          	addi	a4,a4,446 # 80023d00 <queue_info>
    80006b4a:	00848693          	addi	a3,s1,8
    80006b4e:	068a                	slli	a3,a3,0x2
    80006b50:	96ba                	add	a3,a3,a4
    80006b52:	2785                	addiw	a5,a5,1
    80006b54:	c69c                	sw	a5,8(a3)
    queue_info.num_procs[queue_no]++;
    80006b56:	00249793          	slli	a5,s1,0x2
    80006b5a:	97ba                	add	a5,a5,a4
    80006b5c:	4398                	lw	a4,0(a5)
    80006b5e:	2705                	addiw	a4,a4,1
    80006b60:	c398                	sw	a4,0(a5)
    p->birth_time = sys_uptime(); // birth time also represents the time when it was inducted into the queue
    80006b62:	ffffd097          	auipc	ra,0xffffd
    80006b66:	9aa080e7          	jalr	-1622(ra) # 8000350c <sys_uptime>
    80006b6a:	16a93c23          	sd	a0,376(s2)
    p->proc_queue = queue_no;
    80006b6e:	1a991523          	sh	s1,426(s2)
    p->in_queue = 1;        // flag telling whether its a part of a queue
    80006b72:	4785                	li	a5,1
    80006b74:	1af91c23          	sh	a5,440(s2)
    p->queue_wait_time = 0; // wait time in the queue
    80006b78:	1a093823          	sd	zero,432(s2)
    p->running_time = 0;    // doubles up as the time for which the process is run
    80006b7c:	1a093023          	sd	zero,416(s2)
    return;
}
    80006b80:	60e2                	ld	ra,24(sp)
    80006b82:	6442                	ld	s0,16(sp)
    80006b84:	64a2                	ld	s1,8(sp)
    80006b86:	6902                	ld	s2,0(sp)
    80006b88:	6105                	addi	sp,sp,32
    80006b8a:	8082                	ret
        panic("MLFQ: Number of processes in current queue exceeds limit");
    80006b8c:	00002517          	auipc	a0,0x2
    80006b90:	e1450513          	addi	a0,a0,-492 # 800089a0 <syscalls+0x410>
    80006b94:	ffffa097          	auipc	ra,0xffffa
    80006b98:	9ac080e7          	jalr	-1620(ra) # 80000540 <panic>

0000000080006b9c <queue_pop>:
    return;
}

struct proc* queue_pop(int queue_no)
{
    queue_no += NQUEUE * 10000; // to handle negative queue numbers
    80006b9c:	67b1                	lui	a5,0xc
    80006b9e:	3507879b          	addiw	a5,a5,848 # c350 <_entry-0x7fff3cb0>
    80006ba2:	9fa9                	addw	a5,a5,a0
    queue_no %= NQUEUE;         // to handle queue numbers > 5
    80006ba4:	4715                	li	a4,5
    80006ba6:	02e7e73b          	remw	a4,a5,a4
    if (queue_info.num_procs[queue_no] <= 0)
    80006baa:	00271693          	slli	a3,a4,0x2
    80006bae:	0001d797          	auipc	a5,0x1d
    80006bb2:	15278793          	addi	a5,a5,338 # 80023d00 <queue_info>
    80006bb6:	97b6                	add	a5,a5,a3
    80006bb8:	4390                	lw	a2,0(a5)
    80006bba:	04c05963          	blez	a2,80006c0c <queue_pop+0x70>
    {
        panic("MLFQ: Attempt to pop empty queue");
        return 0;
    }
    struct proc *retval = sched_queue[queue_no][0];
    80006bbe:	00971813          	slli	a6,a4,0x9
    80006bc2:	0001d797          	auipc	a5,0x1d
    80006bc6:	17e78793          	addi	a5,a5,382 # 80023d40 <sched_queue>
    80006bca:	97c2                	add	a5,a5,a6
    80006bcc:	6388                	ld	a0,0(a5)
    retval->in_queue = 0;
    80006bce:	1a051c23          	sh	zero,440(a0)
    queue_info.num_procs[queue_no]--;
    80006bd2:	0001d697          	auipc	a3,0x1d
    80006bd6:	12e68693          	addi	a3,a3,302 # 80023d00 <queue_info>
    80006bda:	00271593          	slli	a1,a4,0x2
    80006bde:	95b6                	add	a1,a1,a3
    80006be0:	367d                	addiw	a2,a2,-1
    80006be2:	c190                	sw	a2,0(a1)
    sched_queue[queue_no][0] = 0;
    80006be4:	0007b023          	sd	zero,0(a5)
    queue_info.last[queue_no]--;
    80006be8:	0721                	addi	a4,a4,8
    80006bea:	070a                	slli	a4,a4,0x2
    80006bec:	9736                	add	a4,a4,a3
    80006bee:	4714                	lw	a3,8(a4)
    80006bf0:	36fd                	addiw	a3,a3,-1
    80006bf2:	c714                	sw	a3,8(a4)
        for (int i = 0; i < NPROC - 1; i++)
    80006bf4:	0001d697          	auipc	a3,0x1d
    80006bf8:	34468693          	addi	a3,a3,836 # 80023f38 <sched_queue+0x1f8>
    80006bfc:	96c2                	add	a3,a3,a6
            sched_queue[queue_no][i] = sched_queue[queue_no][i + 1];
    80006bfe:	6798                	ld	a4,8(a5)
    80006c00:	e398                	sd	a4,0(a5)
            if (!sched_queue[queue_no][i + 1])
    80006c02:	c701                	beqz	a4,80006c0a <queue_pop+0x6e>
        for (int i = 0; i < NPROC - 1; i++)
    80006c04:	07a1                	addi	a5,a5,8
    80006c06:	fed79ce3          	bne	a5,a3,80006bfe <queue_pop+0x62>
    rotate_sched_queue(queue_no, 1);
    return retval;
    80006c0a:	8082                	ret
{
    80006c0c:	1141                	addi	sp,sp,-16
    80006c0e:	e406                	sd	ra,8(sp)
    80006c10:	e022                	sd	s0,0(sp)
    80006c12:	0800                	addi	s0,sp,16
        panic("MLFQ: Attempt to pop empty queue");
    80006c14:	00002517          	auipc	a0,0x2
    80006c18:	dcc50513          	addi	a0,a0,-564 # 800089e0 <syscalls+0x450>
    80006c1c:	ffffa097          	auipc	ra,0xffffa
    80006c20:	924080e7          	jalr	-1756(ra) # 80000540 <panic>
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
