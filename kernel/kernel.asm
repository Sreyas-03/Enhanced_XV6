
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8b070713          	addi	a4,a4,-1872 # 80008900 <timer_scratch>
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
    80000066:	b5e78793          	addi	a5,a5,-1186 # 80005bc0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc88f>
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
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
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
    8000018e:	8b650513          	addi	a0,a0,-1866 # 80010a40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8a648493          	addi	s1,s1,-1882 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	93690913          	addi	s2,s2,-1738 # 80010ad8 <cons+0x98>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
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
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
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
    8000022a:	81a50513          	addi	a0,a0,-2022 # 80010a40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	80450513          	addi	a0,a0,-2044 # 80010a40 <cons>
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
    80000276:	86f72323          	sw	a5,-1946(a4) # 80010ad8 <cons+0x98>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	77450513          	addi	a0,a0,1908 # 80010a40 <cons>
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
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	74650513          	addi	a0,a0,1862 # 80010a40 <cons>
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
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	72270713          	addi	a4,a4,1826 # 80010a40 <cons>
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
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6f878793          	addi	a5,a5,1784 # 80010a40 <cons>
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
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7627a783          	lw	a5,1890(a5) # 80010ad8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6b670713          	addi	a4,a4,1718 # 80010a40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6a648493          	addi	s1,s1,1702 # 80010a40 <cons>
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	66a70713          	addi	a4,a4,1642 # 80010a40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72a23          	sw	a5,1780(a4) # 80010ae0 <cons+0xa0>
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
    80000412:	00010797          	auipc	a5,0x10
    80000416:	62e78793          	addi	a5,a5,1582 # 80010a40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7a323          	sw	a2,1702(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	69a50513          	addi	a0,a0,1690 # 80010ad8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5e050513          	addi	a0,a0,1504 # 80010a40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	96078793          	addi	a5,a5,-1696 # 80020dd8 <devsw>
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
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5a07aa23          	sw	zero,1460(a5) # 80010b00 <pr+0x18>
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
    80000584:	34f72023          	sw	a5,832(a4) # 800088c0 <panicked>
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
    800005c0:	544dad83          	lw	s11,1348(s11) # 80010b00 <pr+0x18>
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
    800005fe:	4ee50513          	addi	a0,a0,1262 # 80010ae8 <pr>
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
    8000075c:	39050513          	addi	a0,a0,912 # 80010ae8 <pr>
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
    80000778:	37448493          	addi	s1,s1,884 # 80010ae8 <pr>
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
    800007d8:	33450513          	addi	a0,a0,820 # 80010b08 <uart_tx_lock>
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
    80000804:	0c07a783          	lw	a5,192(a5) # 800088c0 <panicked>
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
    8000083c:	0907b783          	ld	a5,144(a5) # 800088c8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	09073703          	ld	a4,144(a4) # 800088d0 <uart_tx_w>
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
    80000866:	2a6a0a13          	addi	s4,s4,678 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	05e48493          	addi	s1,s1,94 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	05e98993          	addi	s3,s3,94 # 800088d0 <uart_tx_w>
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
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
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
    800008d4:	23850513          	addi	a0,a0,568 # 80010b08 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	fe07a783          	lw	a5,-32(a5) # 800088c0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	fe673703          	ld	a4,-26(a4) # 800088d0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fd67b783          	ld	a5,-42(a5) # 800088c8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	20a98993          	addi	s3,s3,522 # 80010b08 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fc248493          	addi	s1,s1,-62 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fc290913          	addi	s2,s2,-62 # 800088d0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1d448493          	addi	s1,s1,468 # 80010b08 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7b423          	sd	a4,-120(a5) # 800088d0 <uart_tx_w>
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
    800009be:	14e48493          	addi	s1,s1,334 # 80010b08 <uart_tx_lock>
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
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	57478793          	addi	a5,a5,1396 # 80021f70 <end>
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
    80000a20:	12490913          	addi	s2,s2,292 # 80010b40 <kmem>
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
    80000abe:	08650513          	addi	a0,a0,134 # 80010b40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	4a250513          	addi	a0,a0,1186 # 80021f70 <end>
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
    80000af4:	05048493          	addi	s1,s1,80 # 80010b40 <kmem>
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
    80000b0c:	03850513          	addi	a0,a0,56 # 80010b40 <kmem>
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
    80000b38:	00c50513          	addi	a0,a0,12 # 80010b40 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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

static inline uint64
r_sstatus()
{
  uint64 x;
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus

// disable device interrupts
static inline void
intr_off()
{
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
// are device interrupts enabled?
static inline int
intr_get()
{
  uint64 x = r_sstatus();
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd091>
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
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a5070713          	addi	a4,a4,-1456 # 800088d8 <started>
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
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	78c080e7          	jalr	1932(ra) # 8000264a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d3a080e7          	jalr	-710(ra) # 80005c00 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
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
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	6ec080e7          	jalr	1772(ra) # 80002622 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	70c080e7          	jalr	1804(ra) # 8000264a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	ca4080e7          	jalr	-860(ra) # 80005bea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	cb2080e7          	jalr	-846(ra) # 80005c00 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	e50080e7          	jalr	-432(ra) # 80002da6 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	4f0080e7          	jalr	1264(ra) # 8000344e <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	496080e7          	jalr	1174(ra) # 800043fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	d9a080e7          	jalr	-614(ra) # 80005d08 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72a23          	sw	a5,-1708(a4) # 800088d8 <started>
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
    80000f9c:	9487b783          	ld	a5,-1720(a5) # 800088e0 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd087>
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
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
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
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7b623          	sd	a0,1676(a5) # 800088e0 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd090>
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

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	74448493          	addi	s1,s1,1860 # 80010f90 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	32aa0a13          	addi	s4,s4,810 # 80016b90 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	27850513          	addi	a0,a0,632 # 80010b60 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	27850513          	addi	a0,a0,632 # 80010b78 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	68048493          	addi	s1,s1,1664 # 80010f90 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	25e98993          	addi	s3,s3,606 # 80016b90 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
// this core's hartid (core number), the index into cpus[].
static inline uint64
r_tp()
{
  uint64 x;
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1f450513          	addi	a0,a0,500 # 80010b90 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	19c70713          	addi	a4,a4,412 # 80010b60 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e547a783          	lw	a5,-428(a5) # 80008850 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	c5c080e7          	jalr	-932(ra) # 80002662 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e207ad23          	sw	zero,-454(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	9ae080e7          	jalr	-1618(ra) # 800033ce <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	12a90913          	addi	s2,s2,298 # 80010b60 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e0c78793          	addi	a5,a5,-500 # 80008854 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	06093683          	ld	a3,96(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	7128                	ld	a0,96(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b7a:	6ca8                	ld	a0,88(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ce48493          	addi	s1,s1,974 # 80010f90 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	fc690913          	addi	s2,s2,-58 # 80016b90 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	f0a8                	sd	a0,96(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06848513          	addi	a0,s1,104
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f8bc                	sd	a5,112(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c4a7b823          	sd	a0,-944(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bbc58593          	addi	a1,a1,-1092 # 80008860 <initcode>
    80001cac:	6d28                	ld	a0,88(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	70b8                	ld	a4,96(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	70b8                	ld	a4,96(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	16048513          	addi	a0,s1,352
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	116080e7          	jalr	278(ra) # 80003df8 <namei>
    80001cea:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6d28                	ld	a0,88(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6d28                	ld	a0,88(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	6d2c                	ld	a1,88(a0)
    80001d92:	058ab503          	ld	a0,88(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	060ab683          	ld	a3,96(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	060a3703          	ld	a4,96(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	060a3783          	ld	a5,96(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d8a8493          	addi	s1,s5,216
    80001de4:	0d8a0913          	addi	s2,s4,216
    80001de8:	158a8993          	addi	s3,s5,344
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	67c080e7          	jalr	1660(ra) # 8000448e <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	158ab503          	ld	a0,344(s5)
    80001e24:	00001097          	auipc	ra,0x1
    80001e28:	7ea080e7          	jalr	2026(ra) # 8000360e <idup>
    80001e2c:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	160a8593          	addi	a1,s5,352
    80001e36:	160a0513          	addi	a0,s4,352
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d2848493          	addi	s1,s1,-728 # 80010b78 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	ca270713          	addi	a4,a4,-862 # 80010b60 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	ccc70713          	addi	a4,a4,-820 # 80010b98 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	c84a0a13          	addi	s4,s4,-892 # 80010b60 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	caa90913          	addi	s2,s2,-854 # 80016b90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	09648493          	addi	s1,s1,150 # 80010f90 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	17048493          	addi	s1,s1,368
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06848593          	addi	a1,s1,104
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	684080e7          	jalr	1668(ra) # 800025b8 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	bf670713          	addi	a4,a4,-1034 # 80010b60 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	bd090913          	addi	s2,s2,-1072 # 80010b60 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	bf058593          	addi	a1,a1,-1040 # 80010b98 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06848513          	addi	a0,s1,104
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	602080e7          	jalr	1538(ra) # 800025b8 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	ec448493          	addi	s1,s1,-316 # 80010f90 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	ab890913          	addi	s2,s2,-1352 # 80016b90 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	17048493          	addi	s1,s1,368
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e5048493          	addi	s1,s1,-432 # 80010f90 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7a0a0a13          	addi	s4,s4,1952 # 800088e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	a4098993          	addi	s3,s3,-1472 # 80016b90 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	17048493          	addi	s1,s1,368
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7447b783          	ld	a5,1860(a5) # 800088e8 <initproc>
    800021ac:	0d850493          	addi	s1,a0,216
    800021b0:	15850913          	addi	s2,a0,344
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	318080e7          	jalr	792(ra) # 800044e0 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	e38080e7          	jalr	-456(ra) # 80004018 <begin_op>
  iput(p->cwd);
    800021e8:	1589b503          	ld	a0,344(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	61a080e7          	jalr	1562(ra) # 80003806 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	ea2080e7          	jalr	-350(ra) # 80004096 <end_op>
  p->cwd = 0;
    800021fc:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	97848493          	addi	s1,s1,-1672 # 80010b78 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d2248493          	addi	s1,s1,-734 # 80010f90 <proc>
    80002276:	00015997          	auipc	s3,0x15
    8000227a:	91a98993          	addi	s3,s3,-1766 # 80016b90 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	17048493          	addi	s1,s1,368
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	82650513          	addi	a0,a0,-2010 # 80010b78 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00015997          	auipc	s3,0x15
    8000236c:	82898993          	addi	s3,s3,-2008 # 80016b90 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	808c0c13          	addi	s8,s8,-2040 # 80010b78 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c1648493          	addi	s1,s1,-1002 # 80010f90 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05893503          	ld	a0,88(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7c050513          	addi	a0,a0,1984 # 80010b78 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7a450513          	addi	a0,a0,1956 # 80010b78 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	17048493          	addi	s1,s1,368
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	75650513          	addi	a0,a0,1878 # 80010b78 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6d28                	ld	a0,88(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6d28                	ld	a0,88(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	bc248493          	addi	s1,s1,-1086 # 800110f0 <proc+0x160>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	7ba90913          	addi	s2,s2,1978 # 80016cf0 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d70b8b93          	addi	s7,s7,-656 # 800082c8 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed06a583          	lw	a1,-304(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	17048493          	addi	s1,s1,368
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	eb84a783          	lw	a5,-328(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <swtch>:
    800025b8:	00153023          	sd	ra,0(a0)
    800025bc:	00253423          	sd	sp,8(a0)
    800025c0:	e900                	sd	s0,16(a0)
    800025c2:	ed04                	sd	s1,24(a0)
    800025c4:	03253023          	sd	s2,32(a0)
    800025c8:	03353423          	sd	s3,40(a0)
    800025cc:	03453823          	sd	s4,48(a0)
    800025d0:	03553c23          	sd	s5,56(a0)
    800025d4:	05653023          	sd	s6,64(a0)
    800025d8:	05753423          	sd	s7,72(a0)
    800025dc:	05853823          	sd	s8,80(a0)
    800025e0:	05953c23          	sd	s9,88(a0)
    800025e4:	07a53023          	sd	s10,96(a0)
    800025e8:	07b53423          	sd	s11,104(a0)
    800025ec:	0005b083          	ld	ra,0(a1)
    800025f0:	0085b103          	ld	sp,8(a1)
    800025f4:	6980                	ld	s0,16(a1)
    800025f6:	6d84                	ld	s1,24(a1)
    800025f8:	0205b903          	ld	s2,32(a1)
    800025fc:	0285b983          	ld	s3,40(a1)
    80002600:	0305ba03          	ld	s4,48(a1)
    80002604:	0385ba83          	ld	s5,56(a1)
    80002608:	0405bb03          	ld	s6,64(a1)
    8000260c:	0485bb83          	ld	s7,72(a1)
    80002610:	0505bc03          	ld	s8,80(a1)
    80002614:	0585bc83          	ld	s9,88(a1)
    80002618:	0605bd03          	ld	s10,96(a1)
    8000261c:	0685bd83          	ld	s11,104(a1)
    80002620:	8082                	ret

0000000080002622 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002622:	1141                	addi	sp,sp,-16
    80002624:	e406                	sd	ra,8(sp)
    80002626:	e022                	sd	s0,0(sp)
    80002628:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000262a:	00006597          	auipc	a1,0x6
    8000262e:	cce58593          	addi	a1,a1,-818 # 800082f8 <states.0+0x30>
    80002632:	00014517          	auipc	a0,0x14
    80002636:	55e50513          	addi	a0,a0,1374 # 80016b90 <tickslock>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	50c080e7          	jalr	1292(ra) # 80000b46 <initlock>
}
    80002642:	60a2                	ld	ra,8(sp)
    80002644:	6402                	ld	s0,0(sp)
    80002646:	0141                	addi	sp,sp,16
    80002648:	8082                	ret

000000008000264a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000264a:	1141                	addi	sp,sp,-16
    8000264c:	e422                	sd	s0,8(sp)
    8000264e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002650:	00003797          	auipc	a5,0x3
    80002654:	4e078793          	addi	a5,a5,1248 # 80005b30 <kernelvec>
    80002658:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000265c:	6422                	ld	s0,8(sp)
    8000265e:	0141                	addi	sp,sp,16
    80002660:	8082                	ret

0000000080002662 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002662:	1141                	addi	sp,sp,-16
    80002664:	e406                	sd	ra,8(sp)
    80002666:	e022                	sd	s0,0(sp)
    80002668:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	342080e7          	jalr	834(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002672:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002676:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002678:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000267c:	00005697          	auipc	a3,0x5
    80002680:	98468693          	addi	a3,a3,-1660 # 80007000 <_trampoline>
    80002684:	00005717          	auipc	a4,0x5
    80002688:	97c70713          	addi	a4,a4,-1668 # 80007000 <_trampoline>
    8000268c:	8f15                	sub	a4,a4,a3
    8000268e:	040007b7          	lui	a5,0x4000
    80002692:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002694:	07b2                	slli	a5,a5,0xc
    80002696:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002698:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000269c:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000269e:	18002673          	csrr	a2,satp
    800026a2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026a4:	7130                	ld	a2,96(a0)
    800026a6:	6138                	ld	a4,64(a0)
    800026a8:	6585                	lui	a1,0x1
    800026aa:	972e                	add	a4,a4,a1
    800026ac:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ae:	7138                	ld	a4,96(a0)
    800026b0:	00000617          	auipc	a2,0x0
    800026b4:	13060613          	addi	a2,a2,304 # 800027e0 <usertrap>
    800026b8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ba:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026bc:	8612                	mv	a2,tp
    800026be:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026c4:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026cc:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026d0:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d2:	6f18                	ld	a4,24(a4)
    800026d4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d8:	6d28                	ld	a0,88(a0)
    800026da:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026dc:	00005717          	auipc	a4,0x5
    800026e0:	9c070713          	addi	a4,a4,-1600 # 8000709c <userret>
    800026e4:	8f15                	sub	a4,a4,a3
    800026e6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026e8:	577d                	li	a4,-1
    800026ea:	177e                	slli	a4,a4,0x3f
    800026ec:	8d59                	or	a0,a0,a4
    800026ee:	9782                	jalr	a5
}
    800026f0:	60a2                	ld	ra,8(sp)
    800026f2:	6402                	ld	s0,0(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f8:	1101                	addi	sp,sp,-32
    800026fa:	ec06                	sd	ra,24(sp)
    800026fc:	e822                	sd	s0,16(sp)
    800026fe:	e426                	sd	s1,8(sp)
    80002700:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002702:	00014497          	auipc	s1,0x14
    80002706:	48e48493          	addi	s1,s1,1166 # 80016b90 <tickslock>
    8000270a:	8526                	mv	a0,s1
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	4ca080e7          	jalr	1226(ra) # 80000bd6 <acquire>
  ticks++;
    80002714:	00006517          	auipc	a0,0x6
    80002718:	1dc50513          	addi	a0,a0,476 # 800088f0 <ticks>
    8000271c:	411c                	lw	a5,0(a0)
    8000271e:	2785                	addiw	a5,a5,1
    80002720:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002722:	00000097          	auipc	ra,0x0
    80002726:	996080e7          	jalr	-1642(ra) # 800020b8 <wakeup>
  release(&tickslock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	55e080e7          	jalr	1374(ra) # 80000c8a <release>
}
    80002734:	60e2                	ld	ra,24(sp)
    80002736:	6442                	ld	s0,16(sp)
    80002738:	64a2                	ld	s1,8(sp)
    8000273a:	6105                	addi	sp,sp,32
    8000273c:	8082                	ret

000000008000273e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273e:	1101                	addi	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002748:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274c:	00074d63          	bltz	a4,80002766 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002750:	57fd                	li	a5,-1
    80002752:	17fe                	slli	a5,a5,0x3f
    80002754:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002756:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002758:	06f70363          	beq	a4,a5,800027be <devintr+0x80>
  }
}
    8000275c:	60e2                	ld	ra,24(sp)
    8000275e:	6442                	ld	s0,16(sp)
    80002760:	64a2                	ld	s1,8(sp)
    80002762:	6105                	addi	sp,sp,32
    80002764:	8082                	ret
     (scause & 0xff) == 9){
    80002766:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000276a:	46a5                	li	a3,9
    8000276c:	fed792e3          	bne	a5,a3,80002750 <devintr+0x12>
    int irq = plic_claim();
    80002770:	00003097          	auipc	ra,0x3
    80002774:	4c8080e7          	jalr	1224(ra) # 80005c38 <plic_claim>
    80002778:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000277a:	47a9                	li	a5,10
    8000277c:	02f50763          	beq	a0,a5,800027aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002780:	4785                	li	a5,1
    80002782:	02f50963          	beq	a0,a5,800027b4 <devintr+0x76>
    return 1;
    80002786:	4505                	li	a0,1
    } else if(irq){
    80002788:	d8f1                	beqz	s1,8000275c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000278a:	85a6                	mv	a1,s1
    8000278c:	00006517          	auipc	a0,0x6
    80002790:	b7450513          	addi	a0,a0,-1164 # 80008300 <states.0+0x38>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	df6080e7          	jalr	-522(ra) # 8000058a <printf>
      plic_complete(irq);
    8000279c:	8526                	mv	a0,s1
    8000279e:	00003097          	auipc	ra,0x3
    800027a2:	4be080e7          	jalr	1214(ra) # 80005c5c <plic_complete>
    return 1;
    800027a6:	4505                	li	a0,1
    800027a8:	bf55                	j	8000275c <devintr+0x1e>
      uartintr();
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	1ee080e7          	jalr	494(ra) # 80000998 <uartintr>
    800027b2:	b7ed                	j	8000279c <devintr+0x5e>
      virtio_disk_intr();
    800027b4:	00004097          	auipc	ra,0x4
    800027b8:	970080e7          	jalr	-1680(ra) # 80006124 <virtio_disk_intr>
    800027bc:	b7c5                	j	8000279c <devintr+0x5e>
    if(cpuid() == 0){
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	1c2080e7          	jalr	450(ra) # 80001980 <cpuid>
    800027c6:	c901                	beqz	a0,800027d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ce:	14479073          	csrw	sip,a5
    return 2;
    800027d2:	4509                	li	a0,2
    800027d4:	b761                	j	8000275c <devintr+0x1e>
      clockintr();
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	f22080e7          	jalr	-222(ra) # 800026f8 <clockintr>
    800027de:	b7ed                	j	800027c8 <devintr+0x8a>

00000000800027e0 <usertrap>:
{
    800027e0:	1101                	addi	sp,sp,-32
    800027e2:	ec06                	sd	ra,24(sp)
    800027e4:	e822                	sd	s0,16(sp)
    800027e6:	e426                	sd	s1,8(sp)
    800027e8:	e04a                	sd	s2,0(sp)
    800027ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027f0:	1007f793          	andi	a5,a5,256
    800027f4:	e3b1                	bnez	a5,80002838 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f6:	00003797          	auipc	a5,0x3
    800027fa:	33a78793          	addi	a5,a5,826 # 80005b30 <kernelvec>
    800027fe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	1aa080e7          	jalr	426(ra) # 800019ac <myproc>
    8000280a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280e:	14102773          	csrr	a4,sepc
    80002812:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002814:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002818:	47a1                	li	a5,8
    8000281a:	02f70763          	beq	a4,a5,80002848 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	f20080e7          	jalr	-224(ra) # 8000273e <devintr>
    80002826:	892a                	mv	s2,a0
    80002828:	c151                	beqz	a0,800028ac <usertrap+0xcc>
  if(killed(p))
    8000282a:	8526                	mv	a0,s1
    8000282c:	00000097          	auipc	ra,0x0
    80002830:	ad0080e7          	jalr	-1328(ra) # 800022fc <killed>
    80002834:	c929                	beqz	a0,80002886 <usertrap+0xa6>
    80002836:	a099                	j	8000287c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002838:	00006517          	auipc	a0,0x6
    8000283c:	ae850513          	addi	a0,a0,-1304 # 80008320 <states.0+0x58>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	d00080e7          	jalr	-768(ra) # 80000540 <panic>
    if(killed(p))
    80002848:	00000097          	auipc	ra,0x0
    8000284c:	ab4080e7          	jalr	-1356(ra) # 800022fc <killed>
    80002850:	e921                	bnez	a0,800028a0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002852:	70b8                	ld	a4,96(s1)
    80002854:	6f1c                	ld	a5,24(a4)
    80002856:	0791                	addi	a5,a5,4
    80002858:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000285e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002862:	10079073          	csrw	sstatus,a5
    syscall();
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	2d4080e7          	jalr	724(ra) # 80002b3a <syscall>
  if(killed(p))
    8000286e:	8526                	mv	a0,s1
    80002870:	00000097          	auipc	ra,0x0
    80002874:	a8c080e7          	jalr	-1396(ra) # 800022fc <killed>
    80002878:	c911                	beqz	a0,8000288c <usertrap+0xac>
    8000287a:	4901                	li	s2,0
    exit(-1);
    8000287c:	557d                	li	a0,-1
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	90a080e7          	jalr	-1782(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002886:	4789                	li	a5,2
    80002888:	04f90f63          	beq	s2,a5,800028e6 <usertrap+0x106>
  usertrapret();
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	dd6080e7          	jalr	-554(ra) # 80002662 <usertrapret>
}
    80002894:	60e2                	ld	ra,24(sp)
    80002896:	6442                	ld	s0,16(sp)
    80002898:	64a2                	ld	s1,8(sp)
    8000289a:	6902                	ld	s2,0(sp)
    8000289c:	6105                	addi	sp,sp,32
    8000289e:	8082                	ret
      exit(-1);
    800028a0:	557d                	li	a0,-1
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	8e6080e7          	jalr	-1818(ra) # 80002188 <exit>
    800028aa:	b765                	j	80002852 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ac:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028b0:	5890                	lw	a2,48(s1)
    800028b2:	00006517          	auipc	a0,0x6
    800028b6:	a8e50513          	addi	a0,a0,-1394 # 80008340 <states.0+0x78>
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cd0080e7          	jalr	-816(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028c6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ca:	00006517          	auipc	a0,0x6
    800028ce:	aa650513          	addi	a0,a0,-1370 # 80008370 <states.0+0xa8>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	cb8080e7          	jalr	-840(ra) # 8000058a <printf>
    setkilled(p);
    800028da:	8526                	mv	a0,s1
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	9f4080e7          	jalr	-1548(ra) # 800022d0 <setkilled>
    800028e4:	b769                	j	8000286e <usertrap+0x8e>
    yield();
    800028e6:	fffff097          	auipc	ra,0xfffff
    800028ea:	732080e7          	jalr	1842(ra) # 80002018 <yield>
    800028ee:	bf79                	j	8000288c <usertrap+0xac>

00000000800028f0 <kerneltrap>:
{
    800028f0:	7179                	addi	sp,sp,-48
    800028f2:	f406                	sd	ra,40(sp)
    800028f4:	f022                	sd	s0,32(sp)
    800028f6:	ec26                	sd	s1,24(sp)
    800028f8:	e84a                	sd	s2,16(sp)
    800028fa:	e44e                	sd	s3,8(sp)
    800028fc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002902:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002906:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000290a:	1004f793          	andi	a5,s1,256
    8000290e:	cb85                	beqz	a5,8000293e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002910:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002914:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002916:	ef85                	bnez	a5,8000294e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	e26080e7          	jalr	-474(ra) # 8000273e <devintr>
    80002920:	cd1d                	beqz	a0,8000295e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002922:	4789                	li	a5,2
    80002924:	06f50a63          	beq	a0,a5,80002998 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002928:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292c:	10049073          	csrw	sstatus,s1
}
    80002930:	70a2                	ld	ra,40(sp)
    80002932:	7402                	ld	s0,32(sp)
    80002934:	64e2                	ld	s1,24(sp)
    80002936:	6942                	ld	s2,16(sp)
    80002938:	69a2                	ld	s3,8(sp)
    8000293a:	6145                	addi	sp,sp,48
    8000293c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	a5250513          	addi	a0,a0,-1454 # 80008390 <states.0+0xc8>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	bfa080e7          	jalr	-1030(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	a6a50513          	addi	a0,a0,-1430 # 800083b8 <states.0+0xf0>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	bea080e7          	jalr	-1046(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    8000295e:	85ce                	mv	a1,s3
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a7850513          	addi	a0,a0,-1416 # 800083d8 <states.0+0x110>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c22080e7          	jalr	-990(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002974:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a7050513          	addi	a0,a0,-1424 # 800083e8 <states.0+0x120>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c0a080e7          	jalr	-1014(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	a7850513          	addi	a0,a0,-1416 # 80008400 <states.0+0x138>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bb0080e7          	jalr	-1104(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	014080e7          	jalr	20(ra) # 800019ac <myproc>
    800029a0:	d541                	beqz	a0,80002928 <kerneltrap+0x38>
    800029a2:	fffff097          	auipc	ra,0xfffff
    800029a6:	00a080e7          	jalr	10(ra) # 800019ac <myproc>
    800029aa:	4d18                	lw	a4,24(a0)
    800029ac:	4791                	li	a5,4
    800029ae:	f6f71de3          	bne	a4,a5,80002928 <kerneltrap+0x38>
    yield();
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	666080e7          	jalr	1638(ra) # 80002018 <yield>
    800029ba:	b7bd                	j	80002928 <kerneltrap+0x38>

00000000800029bc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029bc:	1101                	addi	sp,sp,-32
    800029be:	ec06                	sd	ra,24(sp)
    800029c0:	e822                	sd	s0,16(sp)
    800029c2:	e426                	sd	s1,8(sp)
    800029c4:	1000                	addi	s0,sp,32
    800029c6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c8:	fffff097          	auipc	ra,0xfffff
    800029cc:	fe4080e7          	jalr	-28(ra) # 800019ac <myproc>
  switch (n) {
    800029d0:	4795                	li	a5,5
    800029d2:	0497e163          	bltu	a5,s1,80002a14 <argraw+0x58>
    800029d6:	048a                	slli	s1,s1,0x2
    800029d8:	00006717          	auipc	a4,0x6
    800029dc:	a6070713          	addi	a4,a4,-1440 # 80008438 <states.0+0x170>
    800029e0:	94ba                	add	s1,s1,a4
    800029e2:	409c                	lw	a5,0(s1)
    800029e4:	97ba                	add	a5,a5,a4
    800029e6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029e8:	713c                	ld	a5,96(a0)
    800029ea:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	64a2                	ld	s1,8(sp)
    800029f2:	6105                	addi	sp,sp,32
    800029f4:	8082                	ret
    return p->trapframe->a1;
    800029f6:	713c                	ld	a5,96(a0)
    800029f8:	7fa8                	ld	a0,120(a5)
    800029fa:	bfcd                	j	800029ec <argraw+0x30>
    return p->trapframe->a2;
    800029fc:	713c                	ld	a5,96(a0)
    800029fe:	63c8                	ld	a0,128(a5)
    80002a00:	b7f5                	j	800029ec <argraw+0x30>
    return p->trapframe->a3;
    80002a02:	713c                	ld	a5,96(a0)
    80002a04:	67c8                	ld	a0,136(a5)
    80002a06:	b7dd                	j	800029ec <argraw+0x30>
    return p->trapframe->a4;
    80002a08:	713c                	ld	a5,96(a0)
    80002a0a:	6bc8                	ld	a0,144(a5)
    80002a0c:	b7c5                	j	800029ec <argraw+0x30>
    return p->trapframe->a5;
    80002a0e:	713c                	ld	a5,96(a0)
    80002a10:	6fc8                	ld	a0,152(a5)
    80002a12:	bfe9                	j	800029ec <argraw+0x30>
  panic("argraw");
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	9fc50513          	addi	a0,a0,-1540 # 80008410 <states.0+0x148>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b24080e7          	jalr	-1244(ra) # 80000540 <panic>

0000000080002a24 <fetchaddr>:
{
    80002a24:	1101                	addi	sp,sp,-32
    80002a26:	ec06                	sd	ra,24(sp)
    80002a28:	e822                	sd	s0,16(sp)
    80002a2a:	e426                	sd	s1,8(sp)
    80002a2c:	e04a                	sd	s2,0(sp)
    80002a2e:	1000                	addi	s0,sp,32
    80002a30:	84aa                	mv	s1,a0
    80002a32:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	f78080e7          	jalr	-136(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a3c:	653c                	ld	a5,72(a0)
    80002a3e:	02f4f863          	bgeu	s1,a5,80002a6e <fetchaddr+0x4a>
    80002a42:	00848713          	addi	a4,s1,8
    80002a46:	02e7e663          	bltu	a5,a4,80002a72 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a4a:	46a1                	li	a3,8
    80002a4c:	8626                	mv	a2,s1
    80002a4e:	85ca                	mv	a1,s2
    80002a50:	6d28                	ld	a0,88(a0)
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	ca6080e7          	jalr	-858(ra) # 800016f8 <copyin>
    80002a5a:	00a03533          	snez	a0,a0
    80002a5e:	40a00533          	neg	a0,a0
}
    80002a62:	60e2                	ld	ra,24(sp)
    80002a64:	6442                	ld	s0,16(sp)
    80002a66:	64a2                	ld	s1,8(sp)
    80002a68:	6902                	ld	s2,0(sp)
    80002a6a:	6105                	addi	sp,sp,32
    80002a6c:	8082                	ret
    return -1;
    80002a6e:	557d                	li	a0,-1
    80002a70:	bfcd                	j	80002a62 <fetchaddr+0x3e>
    80002a72:	557d                	li	a0,-1
    80002a74:	b7fd                	j	80002a62 <fetchaddr+0x3e>

0000000080002a76 <fetchstr>:
{
    80002a76:	7179                	addi	sp,sp,-48
    80002a78:	f406                	sd	ra,40(sp)
    80002a7a:	f022                	sd	s0,32(sp)
    80002a7c:	ec26                	sd	s1,24(sp)
    80002a7e:	e84a                	sd	s2,16(sp)
    80002a80:	e44e                	sd	s3,8(sp)
    80002a82:	1800                	addi	s0,sp,48
    80002a84:	892a                	mv	s2,a0
    80002a86:	84ae                	mv	s1,a1
    80002a88:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f22080e7          	jalr	-222(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a92:	86ce                	mv	a3,s3
    80002a94:	864a                	mv	a2,s2
    80002a96:	85a6                	mv	a1,s1
    80002a98:	6d28                	ld	a0,88(a0)
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	cec080e7          	jalr	-788(ra) # 80001786 <copyinstr>
    80002aa2:	00054e63          	bltz	a0,80002abe <fetchstr+0x48>
  return strlen(buf);
    80002aa6:	8526                	mv	a0,s1
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	3a6080e7          	jalr	934(ra) # 80000e4e <strlen>
}
    80002ab0:	70a2                	ld	ra,40(sp)
    80002ab2:	7402                	ld	s0,32(sp)
    80002ab4:	64e2                	ld	s1,24(sp)
    80002ab6:	6942                	ld	s2,16(sp)
    80002ab8:	69a2                	ld	s3,8(sp)
    80002aba:	6145                	addi	sp,sp,48
    80002abc:	8082                	ret
    return -1;
    80002abe:	557d                	li	a0,-1
    80002ac0:	bfc5                	j	80002ab0 <fetchstr+0x3a>

0000000080002ac2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	1000                	addi	s0,sp,32
    80002acc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	eee080e7          	jalr	-274(ra) # 800029bc <argraw>
    80002ad6:	c088                	sw	a0,0(s1)
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret

0000000080002ae2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	ece080e7          	jalr	-306(ra) # 800029bc <argraw>
    80002af6:	e088                	sd	a0,0(s1)
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b02:	7179                	addi	sp,sp,-48
    80002b04:	f406                	sd	ra,40(sp)
    80002b06:	f022                	sd	s0,32(sp)
    80002b08:	ec26                	sd	s1,24(sp)
    80002b0a:	e84a                	sd	s2,16(sp)
    80002b0c:	1800                	addi	s0,sp,48
    80002b0e:	84ae                	mv	s1,a1
    80002b10:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b12:	fd840593          	addi	a1,s0,-40
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	fcc080e7          	jalr	-52(ra) # 80002ae2 <argaddr>
  return fetchstr(addr, buf, max);
    80002b1e:	864a                	mv	a2,s2
    80002b20:	85a6                	mv	a1,s1
    80002b22:	fd843503          	ld	a0,-40(s0)
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	f50080e7          	jalr	-176(ra) # 80002a76 <fetchstr>
}
    80002b2e:	70a2                	ld	ra,40(sp)
    80002b30:	7402                	ld	s0,32(sp)
    80002b32:	64e2                	ld	s1,24(sp)
    80002b34:	6942                	ld	s2,16(sp)
    80002b36:	6145                	addi	sp,sp,48
    80002b38:	8082                	ret

0000000080002b3a <syscall>:
[SYS_getyear] sys_getyear,
};

void
syscall(void)
{
    80002b3a:	1101                	addi	sp,sp,-32
    80002b3c:	ec06                	sd	ra,24(sp)
    80002b3e:	e822                	sd	s0,16(sp)
    80002b40:	e426                	sd	s1,8(sp)
    80002b42:	e04a                	sd	s2,0(sp)
    80002b44:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	e66080e7          	jalr	-410(ra) # 800019ac <myproc>
    80002b4e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b50:	06053903          	ld	s2,96(a0)
    80002b54:	0a893783          	ld	a5,168(s2)
    80002b58:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b5c:	37fd                	addiw	a5,a5,-1
    80002b5e:	4759                	li	a4,22
    80002b60:	00f76f63          	bltu	a4,a5,80002b7e <syscall+0x44>
    80002b64:	00369713          	slli	a4,a3,0x3
    80002b68:	00006797          	auipc	a5,0x6
    80002b6c:	8e878793          	addi	a5,a5,-1816 # 80008450 <syscalls>
    80002b70:	97ba                	add	a5,a5,a4
    80002b72:	639c                	ld	a5,0(a5)
    80002b74:	c789                	beqz	a5,80002b7e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b76:	9782                	jalr	a5
    80002b78:	06a93823          	sd	a0,112(s2)
    80002b7c:	a839                	j	80002b9a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b7e:	16048613          	addi	a2,s1,352
    80002b82:	588c                	lw	a1,48(s1)
    80002b84:	00006517          	auipc	a0,0x6
    80002b88:	89450513          	addi	a0,a0,-1900 # 80008418 <states.0+0x150>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	9fe080e7          	jalr	-1538(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b94:	70bc                	ld	a5,96(s1)
    80002b96:	577d                	li	a4,-1
    80002b98:	fbb8                	sd	a4,112(a5)
  }
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6902                	ld	s2,0(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bae:	fec40593          	addi	a1,s0,-20
    80002bb2:	4501                	li	a0,0
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	f0e080e7          	jalr	-242(ra) # 80002ac2 <argint>
  exit(n);
    80002bbc:	fec42503          	lw	a0,-20(s0)
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	5c8080e7          	jalr	1480(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002bc8:	4501                	li	a0,0
    80002bca:	60e2                	ld	ra,24(sp)
    80002bcc:	6442                	ld	s0,16(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bd2:	1141                	addi	sp,sp,-16
    80002bd4:	e406                	sd	ra,8(sp)
    80002bd6:	e022                	sd	s0,0(sp)
    80002bd8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	dd2080e7          	jalr	-558(ra) # 800019ac <myproc>
}
    80002be2:	5908                	lw	a0,48(a0)
    80002be4:	60a2                	ld	ra,8(sp)
    80002be6:	6402                	ld	s0,0(sp)
    80002be8:	0141                	addi	sp,sp,16
    80002bea:	8082                	ret

0000000080002bec <sys_fork>:

uint64
sys_fork(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
  return fork();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	16e080e7          	jalr	366(ra) # 80001d62 <fork>
}
    80002bfc:	60a2                	ld	ra,8(sp)
    80002bfe:	6402                	ld	s0,0(sp)
    80002c00:	0141                	addi	sp,sp,16
    80002c02:	8082                	ret

0000000080002c04 <sys_wait>:

uint64
sys_wait(void)
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c0c:	fe840593          	addi	a1,s0,-24
    80002c10:	4501                	li	a0,0
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	ed0080e7          	jalr	-304(ra) # 80002ae2 <argaddr>
  return wait(p);
    80002c1a:	fe843503          	ld	a0,-24(s0)
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	710080e7          	jalr	1808(ra) # 8000232e <wait>
}
    80002c26:	60e2                	ld	ra,24(sp)
    80002c28:	6442                	ld	s0,16(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c38:	fdc40593          	addi	a1,s0,-36
    80002c3c:	4501                	li	a0,0
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	e84080e7          	jalr	-380(ra) # 80002ac2 <argint>
  addr = myproc()->sz;
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	d66080e7          	jalr	-666(ra) # 800019ac <myproc>
    80002c4e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c50:	fdc42503          	lw	a0,-36(s0)
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	0b2080e7          	jalr	178(ra) # 80001d06 <growproc>
    80002c5c:	00054863          	bltz	a0,80002c6c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c60:	8526                	mv	a0,s1
    80002c62:	70a2                	ld	ra,40(sp)
    80002c64:	7402                	ld	s0,32(sp)
    80002c66:	64e2                	ld	s1,24(sp)
    80002c68:	6145                	addi	sp,sp,48
    80002c6a:	8082                	ret
    return -1;
    80002c6c:	54fd                	li	s1,-1
    80002c6e:	bfcd                	j	80002c60 <sys_sbrk+0x32>

0000000080002c70 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c70:	7139                	addi	sp,sp,-64
    80002c72:	fc06                	sd	ra,56(sp)
    80002c74:	f822                	sd	s0,48(sp)
    80002c76:	f426                	sd	s1,40(sp)
    80002c78:	f04a                	sd	s2,32(sp)
    80002c7a:	ec4e                	sd	s3,24(sp)
    80002c7c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c7e:	fcc40593          	addi	a1,s0,-52
    80002c82:	4501                	li	a0,0
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	e3e080e7          	jalr	-450(ra) # 80002ac2 <argint>
  acquire(&tickslock);
    80002c8c:	00014517          	auipc	a0,0x14
    80002c90:	f0450513          	addi	a0,a0,-252 # 80016b90 <tickslock>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	f42080e7          	jalr	-190(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002c9c:	00006917          	auipc	s2,0x6
    80002ca0:	c5492903          	lw	s2,-940(s2) # 800088f0 <ticks>
  while(ticks - ticks0 < n){
    80002ca4:	fcc42783          	lw	a5,-52(s0)
    80002ca8:	cf9d                	beqz	a5,80002ce6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002caa:	00014997          	auipc	s3,0x14
    80002cae:	ee698993          	addi	s3,s3,-282 # 80016b90 <tickslock>
    80002cb2:	00006497          	auipc	s1,0x6
    80002cb6:	c3e48493          	addi	s1,s1,-962 # 800088f0 <ticks>
    if(killed(myproc())){
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	cf2080e7          	jalr	-782(ra) # 800019ac <myproc>
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	63a080e7          	jalr	1594(ra) # 800022fc <killed>
    80002cca:	ed15                	bnez	a0,80002d06 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ccc:	85ce                	mv	a1,s3
    80002cce:	8526                	mv	a0,s1
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	384080e7          	jalr	900(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002cd8:	409c                	lw	a5,0(s1)
    80002cda:	412787bb          	subw	a5,a5,s2
    80002cde:	fcc42703          	lw	a4,-52(s0)
    80002ce2:	fce7ece3          	bltu	a5,a4,80002cba <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ce6:	00014517          	auipc	a0,0x14
    80002cea:	eaa50513          	addi	a0,a0,-342 # 80016b90 <tickslock>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	f9c080e7          	jalr	-100(ra) # 80000c8a <release>
  return 0;
    80002cf6:	4501                	li	a0,0
}
    80002cf8:	70e2                	ld	ra,56(sp)
    80002cfa:	7442                	ld	s0,48(sp)
    80002cfc:	74a2                	ld	s1,40(sp)
    80002cfe:	7902                	ld	s2,32(sp)
    80002d00:	69e2                	ld	s3,24(sp)
    80002d02:	6121                	addi	sp,sp,64
    80002d04:	8082                	ret
      release(&tickslock);
    80002d06:	00014517          	auipc	a0,0x14
    80002d0a:	e8a50513          	addi	a0,a0,-374 # 80016b90 <tickslock>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	f7c080e7          	jalr	-132(ra) # 80000c8a <release>
      return -1;
    80002d16:	557d                	li	a0,-1
    80002d18:	b7c5                	j	80002cf8 <sys_sleep+0x88>

0000000080002d1a <sys_kill>:

uint64
sys_kill(void)
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d22:	fec40593          	addi	a1,s0,-20
    80002d26:	4501                	li	a0,0
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	d9a080e7          	jalr	-614(ra) # 80002ac2 <argint>
  return kill(pid);
    80002d30:	fec42503          	lw	a0,-20(s0)
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	52a080e7          	jalr	1322(ra) # 8000225e <kill>
}
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret

0000000080002d44 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d4e:	00014517          	auipc	a0,0x14
    80002d52:	e4250513          	addi	a0,a0,-446 # 80016b90 <tickslock>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	e80080e7          	jalr	-384(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d5e:	00006497          	auipc	s1,0x6
    80002d62:	b924a483          	lw	s1,-1134(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002d66:	00014517          	auipc	a0,0x14
    80002d6a:	e2a50513          	addi	a0,a0,-470 # 80016b90 <tickslock>
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	f1c080e7          	jalr	-228(ra) # 80000c8a <release>
  return xticks;
}
    80002d76:	02049513          	slli	a0,s1,0x20
    80002d7a:	9101                	srli	a0,a0,0x20
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <sys_trace>:

uint64
sys_trace(void)
{
    80002d86:	1141                	addi	sp,sp,-16
    80002d88:	e422                	sd	s0,8(sp)
    80002d8a:	0800                	addi	s0,sp,16
  return 2003;
}
    80002d8c:	7d300513          	li	a0,2003
    80002d90:	6422                	ld	s0,8(sp)
    80002d92:	0141                	addi	sp,sp,16
    80002d94:	8082                	ret

0000000080002d96 <sys_getyear>:

uint64
sys_getyear(void) // this is for testing purpose only, can be removed
{
    80002d96:	1141                	addi	sp,sp,-16
    80002d98:	e422                	sd	s0,8(sp)
    80002d9a:	0800                	addi	s0,sp,16
  return 2003;
    80002d9c:	7d300513          	li	a0,2003
    80002da0:	6422                	ld	s0,8(sp)
    80002da2:	0141                	addi	sp,sp,16
    80002da4:	8082                	ret

0000000080002da6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002da6:	7179                	addi	sp,sp,-48
    80002da8:	f406                	sd	ra,40(sp)
    80002daa:	f022                	sd	s0,32(sp)
    80002dac:	ec26                	sd	s1,24(sp)
    80002dae:	e84a                	sd	s2,16(sp)
    80002db0:	e44e                	sd	s3,8(sp)
    80002db2:	e052                	sd	s4,0(sp)
    80002db4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002db6:	00005597          	auipc	a1,0x5
    80002dba:	75a58593          	addi	a1,a1,1882 # 80008510 <syscalls+0xc0>
    80002dbe:	00014517          	auipc	a0,0x14
    80002dc2:	dea50513          	addi	a0,a0,-534 # 80016ba8 <bcache>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	d80080e7          	jalr	-640(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dce:	0001c797          	auipc	a5,0x1c
    80002dd2:	dda78793          	addi	a5,a5,-550 # 8001eba8 <bcache+0x8000>
    80002dd6:	0001c717          	auipc	a4,0x1c
    80002dda:	03a70713          	addi	a4,a4,58 # 8001ee10 <bcache+0x8268>
    80002dde:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002de2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002de6:	00014497          	auipc	s1,0x14
    80002dea:	dda48493          	addi	s1,s1,-550 # 80016bc0 <bcache+0x18>
    b->next = bcache.head.next;
    80002dee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002df0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002df2:	00005a17          	auipc	s4,0x5
    80002df6:	726a0a13          	addi	s4,s4,1830 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002dfa:	2b893783          	ld	a5,696(s2)
    80002dfe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e00:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e04:	85d2                	mv	a1,s4
    80002e06:	01048513          	addi	a0,s1,16
    80002e0a:	00001097          	auipc	ra,0x1
    80002e0e:	4c8080e7          	jalr	1224(ra) # 800042d2 <initsleeplock>
    bcache.head.next->prev = b;
    80002e12:	2b893783          	ld	a5,696(s2)
    80002e16:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e18:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e1c:	45848493          	addi	s1,s1,1112
    80002e20:	fd349de3          	bne	s1,s3,80002dfa <binit+0x54>
  }
}
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6942                	ld	s2,16(sp)
    80002e2c:	69a2                	ld	s3,8(sp)
    80002e2e:	6a02                	ld	s4,0(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret

0000000080002e34 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e34:	7179                	addi	sp,sp,-48
    80002e36:	f406                	sd	ra,40(sp)
    80002e38:	f022                	sd	s0,32(sp)
    80002e3a:	ec26                	sd	s1,24(sp)
    80002e3c:	e84a                	sd	s2,16(sp)
    80002e3e:	e44e                	sd	s3,8(sp)
    80002e40:	1800                	addi	s0,sp,48
    80002e42:	892a                	mv	s2,a0
    80002e44:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e46:	00014517          	auipc	a0,0x14
    80002e4a:	d6250513          	addi	a0,a0,-670 # 80016ba8 <bcache>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	d88080e7          	jalr	-632(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e56:	0001c497          	auipc	s1,0x1c
    80002e5a:	00a4b483          	ld	s1,10(s1) # 8001ee60 <bcache+0x82b8>
    80002e5e:	0001c797          	auipc	a5,0x1c
    80002e62:	fb278793          	addi	a5,a5,-78 # 8001ee10 <bcache+0x8268>
    80002e66:	02f48f63          	beq	s1,a5,80002ea4 <bread+0x70>
    80002e6a:	873e                	mv	a4,a5
    80002e6c:	a021                	j	80002e74 <bread+0x40>
    80002e6e:	68a4                	ld	s1,80(s1)
    80002e70:	02e48a63          	beq	s1,a4,80002ea4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e74:	449c                	lw	a5,8(s1)
    80002e76:	ff279ce3          	bne	a5,s2,80002e6e <bread+0x3a>
    80002e7a:	44dc                	lw	a5,12(s1)
    80002e7c:	ff3799e3          	bne	a5,s3,80002e6e <bread+0x3a>
      b->refcnt++;
    80002e80:	40bc                	lw	a5,64(s1)
    80002e82:	2785                	addiw	a5,a5,1
    80002e84:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e86:	00014517          	auipc	a0,0x14
    80002e8a:	d2250513          	addi	a0,a0,-734 # 80016ba8 <bcache>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	dfc080e7          	jalr	-516(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e96:	01048513          	addi	a0,s1,16
    80002e9a:	00001097          	auipc	ra,0x1
    80002e9e:	472080e7          	jalr	1138(ra) # 8000430c <acquiresleep>
      return b;
    80002ea2:	a8b9                	j	80002f00 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ea4:	0001c497          	auipc	s1,0x1c
    80002ea8:	fb44b483          	ld	s1,-76(s1) # 8001ee58 <bcache+0x82b0>
    80002eac:	0001c797          	auipc	a5,0x1c
    80002eb0:	f6478793          	addi	a5,a5,-156 # 8001ee10 <bcache+0x8268>
    80002eb4:	00f48863          	beq	s1,a5,80002ec4 <bread+0x90>
    80002eb8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002eba:	40bc                	lw	a5,64(s1)
    80002ebc:	cf81                	beqz	a5,80002ed4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ebe:	64a4                	ld	s1,72(s1)
    80002ec0:	fee49de3          	bne	s1,a4,80002eba <bread+0x86>
  panic("bget: no buffers");
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	65c50513          	addi	a0,a0,1628 # 80008520 <syscalls+0xd0>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	674080e7          	jalr	1652(ra) # 80000540 <panic>
      b->dev = dev;
    80002ed4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ed8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002edc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ee0:	4785                	li	a5,1
    80002ee2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee4:	00014517          	auipc	a0,0x14
    80002ee8:	cc450513          	addi	a0,a0,-828 # 80016ba8 <bcache>
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	d9e080e7          	jalr	-610(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ef4:	01048513          	addi	a0,s1,16
    80002ef8:	00001097          	auipc	ra,0x1
    80002efc:	414080e7          	jalr	1044(ra) # 8000430c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f00:	409c                	lw	a5,0(s1)
    80002f02:	cb89                	beqz	a5,80002f14 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f04:	8526                	mv	a0,s1
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6942                	ld	s2,16(sp)
    80002f0e:	69a2                	ld	s3,8(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f14:	4581                	li	a1,0
    80002f16:	8526                	mv	a0,s1
    80002f18:	00003097          	auipc	ra,0x3
    80002f1c:	fda080e7          	jalr	-38(ra) # 80005ef2 <virtio_disk_rw>
    b->valid = 1;
    80002f20:	4785                	li	a5,1
    80002f22:	c09c                	sw	a5,0(s1)
  return b;
    80002f24:	b7c5                	j	80002f04 <bread+0xd0>

0000000080002f26 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	1000                	addi	s0,sp,32
    80002f30:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f32:	0541                	addi	a0,a0,16
    80002f34:	00001097          	auipc	ra,0x1
    80002f38:	472080e7          	jalr	1138(ra) # 800043a6 <holdingsleep>
    80002f3c:	cd01                	beqz	a0,80002f54 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f3e:	4585                	li	a1,1
    80002f40:	8526                	mv	a0,s1
    80002f42:	00003097          	auipc	ra,0x3
    80002f46:	fb0080e7          	jalr	-80(ra) # 80005ef2 <virtio_disk_rw>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	64a2                	ld	s1,8(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret
    panic("bwrite");
    80002f54:	00005517          	auipc	a0,0x5
    80002f58:	5e450513          	addi	a0,a0,1508 # 80008538 <syscalls+0xe8>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	5e4080e7          	jalr	1508(ra) # 80000540 <panic>

0000000080002f64 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	e426                	sd	s1,8(sp)
    80002f6c:	e04a                	sd	s2,0(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f72:	01050913          	addi	s2,a0,16
    80002f76:	854a                	mv	a0,s2
    80002f78:	00001097          	auipc	ra,0x1
    80002f7c:	42e080e7          	jalr	1070(ra) # 800043a6 <holdingsleep>
    80002f80:	c92d                	beqz	a0,80002ff2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f82:	854a                	mv	a0,s2
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	3de080e7          	jalr	990(ra) # 80004362 <releasesleep>

  acquire(&bcache.lock);
    80002f8c:	00014517          	auipc	a0,0x14
    80002f90:	c1c50513          	addi	a0,a0,-996 # 80016ba8 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	c42080e7          	jalr	-958(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f9c:	40bc                	lw	a5,64(s1)
    80002f9e:	37fd                	addiw	a5,a5,-1
    80002fa0:	0007871b          	sext.w	a4,a5
    80002fa4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fa6:	eb05                	bnez	a4,80002fd6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fa8:	68bc                	ld	a5,80(s1)
    80002faa:	64b8                	ld	a4,72(s1)
    80002fac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fae:	64bc                	ld	a5,72(s1)
    80002fb0:	68b8                	ld	a4,80(s1)
    80002fb2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fb4:	0001c797          	auipc	a5,0x1c
    80002fb8:	bf478793          	addi	a5,a5,-1036 # 8001eba8 <bcache+0x8000>
    80002fbc:	2b87b703          	ld	a4,696(a5)
    80002fc0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fc2:	0001c717          	auipc	a4,0x1c
    80002fc6:	e4e70713          	addi	a4,a4,-434 # 8001ee10 <bcache+0x8268>
    80002fca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fcc:	2b87b703          	ld	a4,696(a5)
    80002fd0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fd2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fd6:	00014517          	auipc	a0,0x14
    80002fda:	bd250513          	addi	a0,a0,-1070 # 80016ba8 <bcache>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cac080e7          	jalr	-852(ra) # 80000c8a <release>
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	64a2                	ld	s1,8(sp)
    80002fec:	6902                	ld	s2,0(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret
    panic("brelse");
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	54e50513          	addi	a0,a0,1358 # 80008540 <syscalls+0xf0>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>

0000000080003002 <bpin>:

void
bpin(struct buf *b) {
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	b9a50513          	addi	a0,a0,-1126 # 80016ba8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	bc0080e7          	jalr	-1088(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000301e:	40bc                	lw	a5,64(s1)
    80003020:	2785                	addiw	a5,a5,1
    80003022:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	b8450513          	addi	a0,a0,-1148 # 80016ba8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c5e080e7          	jalr	-930(ra) # 80000c8a <release>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <bunpin>:

void
bunpin(struct buf *b) {
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000304a:	00014517          	auipc	a0,0x14
    8000304e:	b5e50513          	addi	a0,a0,-1186 # 80016ba8 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	b84080e7          	jalr	-1148(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000305a:	40bc                	lw	a5,64(s1)
    8000305c:	37fd                	addiw	a5,a5,-1
    8000305e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003060:	00014517          	auipc	a0,0x14
    80003064:	b4850513          	addi	a0,a0,-1208 # 80016ba8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	c22080e7          	jalr	-990(ra) # 80000c8a <release>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	e04a                	sd	s2,0(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003088:	00d5d59b          	srliw	a1,a1,0xd
    8000308c:	0001c797          	auipc	a5,0x1c
    80003090:	1f87a783          	lw	a5,504(a5) # 8001f284 <sb+0x1c>
    80003094:	9dbd                	addw	a1,a1,a5
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	d9e080e7          	jalr	-610(ra) # 80002e34 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000309e:	0074f713          	andi	a4,s1,7
    800030a2:	4785                	li	a5,1
    800030a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030a8:	14ce                	slli	s1,s1,0x33
    800030aa:	90d9                	srli	s1,s1,0x36
    800030ac:	00950733          	add	a4,a0,s1
    800030b0:	05874703          	lbu	a4,88(a4)
    800030b4:	00e7f6b3          	and	a3,a5,a4
    800030b8:	c69d                	beqz	a3,800030e6 <bfree+0x6c>
    800030ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030bc:	94aa                	add	s1,s1,a0
    800030be:	fff7c793          	not	a5,a5
    800030c2:	8f7d                	and	a4,a4,a5
    800030c4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	126080e7          	jalr	294(ra) # 800041ee <log_write>
  brelse(bp);
    800030d0:	854a                	mv	a0,s2
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	e92080e7          	jalr	-366(ra) # 80002f64 <brelse>
}
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6902                	ld	s2,0(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret
    panic("freeing free block");
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	46250513          	addi	a0,a0,1122 # 80008548 <syscalls+0xf8>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	452080e7          	jalr	1106(ra) # 80000540 <panic>

00000000800030f6 <balloc>:
{
    800030f6:	711d                	addi	sp,sp,-96
    800030f8:	ec86                	sd	ra,88(sp)
    800030fa:	e8a2                	sd	s0,80(sp)
    800030fc:	e4a6                	sd	s1,72(sp)
    800030fe:	e0ca                	sd	s2,64(sp)
    80003100:	fc4e                	sd	s3,56(sp)
    80003102:	f852                	sd	s4,48(sp)
    80003104:	f456                	sd	s5,40(sp)
    80003106:	f05a                	sd	s6,32(sp)
    80003108:	ec5e                	sd	s7,24(sp)
    8000310a:	e862                	sd	s8,16(sp)
    8000310c:	e466                	sd	s9,8(sp)
    8000310e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003110:	0001c797          	auipc	a5,0x1c
    80003114:	15c7a783          	lw	a5,348(a5) # 8001f26c <sb+0x4>
    80003118:	cff5                	beqz	a5,80003214 <balloc+0x11e>
    8000311a:	8baa                	mv	s7,a0
    8000311c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000311e:	0001cb17          	auipc	s6,0x1c
    80003122:	14ab0b13          	addi	s6,s6,330 # 8001f268 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003126:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003128:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000312a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000312c:	6c89                	lui	s9,0x2
    8000312e:	a061                	j	800031b6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003130:	97ca                	add	a5,a5,s2
    80003132:	8e55                	or	a2,a2,a3
    80003134:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003138:	854a                	mv	a0,s2
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	0b4080e7          	jalr	180(ra) # 800041ee <log_write>
        brelse(bp);
    80003142:	854a                	mv	a0,s2
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e20080e7          	jalr	-480(ra) # 80002f64 <brelse>
  bp = bread(dev, bno);
    8000314c:	85a6                	mv	a1,s1
    8000314e:	855e                	mv	a0,s7
    80003150:	00000097          	auipc	ra,0x0
    80003154:	ce4080e7          	jalr	-796(ra) # 80002e34 <bread>
    80003158:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000315a:	40000613          	li	a2,1024
    8000315e:	4581                	li	a1,0
    80003160:	05850513          	addi	a0,a0,88
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b6e080e7          	jalr	-1170(ra) # 80000cd2 <memset>
  log_write(bp);
    8000316c:	854a                	mv	a0,s2
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	080080e7          	jalr	128(ra) # 800041ee <log_write>
  brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	dec080e7          	jalr	-532(ra) # 80002f64 <brelse>
}
    80003180:	8526                	mv	a0,s1
    80003182:	60e6                	ld	ra,88(sp)
    80003184:	6446                	ld	s0,80(sp)
    80003186:	64a6                	ld	s1,72(sp)
    80003188:	6906                	ld	s2,64(sp)
    8000318a:	79e2                	ld	s3,56(sp)
    8000318c:	7a42                	ld	s4,48(sp)
    8000318e:	7aa2                	ld	s5,40(sp)
    80003190:	7b02                	ld	s6,32(sp)
    80003192:	6be2                	ld	s7,24(sp)
    80003194:	6c42                	ld	s8,16(sp)
    80003196:	6ca2                	ld	s9,8(sp)
    80003198:	6125                	addi	sp,sp,96
    8000319a:	8082                	ret
    brelse(bp);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	dc6080e7          	jalr	-570(ra) # 80002f64 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031a6:	015c87bb          	addw	a5,s9,s5
    800031aa:	00078a9b          	sext.w	s5,a5
    800031ae:	004b2703          	lw	a4,4(s6)
    800031b2:	06eaf163          	bgeu	s5,a4,80003214 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800031b6:	41fad79b          	sraiw	a5,s5,0x1f
    800031ba:	0137d79b          	srliw	a5,a5,0x13
    800031be:	015787bb          	addw	a5,a5,s5
    800031c2:	40d7d79b          	sraiw	a5,a5,0xd
    800031c6:	01cb2583          	lw	a1,28(s6)
    800031ca:	9dbd                	addw	a1,a1,a5
    800031cc:	855e                	mv	a0,s7
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	c66080e7          	jalr	-922(ra) # 80002e34 <bread>
    800031d6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d8:	004b2503          	lw	a0,4(s6)
    800031dc:	000a849b          	sext.w	s1,s5
    800031e0:	8762                	mv	a4,s8
    800031e2:	faa4fde3          	bgeu	s1,a0,8000319c <balloc+0xa6>
      m = 1 << (bi % 8);
    800031e6:	00777693          	andi	a3,a4,7
    800031ea:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031ee:	41f7579b          	sraiw	a5,a4,0x1f
    800031f2:	01d7d79b          	srliw	a5,a5,0x1d
    800031f6:	9fb9                	addw	a5,a5,a4
    800031f8:	4037d79b          	sraiw	a5,a5,0x3
    800031fc:	00f90633          	add	a2,s2,a5
    80003200:	05864603          	lbu	a2,88(a2)
    80003204:	00c6f5b3          	and	a1,a3,a2
    80003208:	d585                	beqz	a1,80003130 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320a:	2705                	addiw	a4,a4,1
    8000320c:	2485                	addiw	s1,s1,1
    8000320e:	fd471ae3          	bne	a4,s4,800031e2 <balloc+0xec>
    80003212:	b769                	j	8000319c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003214:	00005517          	auipc	a0,0x5
    80003218:	34c50513          	addi	a0,a0,844 # 80008560 <syscalls+0x110>
    8000321c:	ffffd097          	auipc	ra,0xffffd
    80003220:	36e080e7          	jalr	878(ra) # 8000058a <printf>
  return 0;
    80003224:	4481                	li	s1,0
    80003226:	bfa9                	j	80003180 <balloc+0x8a>

0000000080003228 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003228:	7179                	addi	sp,sp,-48
    8000322a:	f406                	sd	ra,40(sp)
    8000322c:	f022                	sd	s0,32(sp)
    8000322e:	ec26                	sd	s1,24(sp)
    80003230:	e84a                	sd	s2,16(sp)
    80003232:	e44e                	sd	s3,8(sp)
    80003234:	e052                	sd	s4,0(sp)
    80003236:	1800                	addi	s0,sp,48
    80003238:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000323a:	47ad                	li	a5,11
    8000323c:	02b7e863          	bltu	a5,a1,8000326c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003240:	02059793          	slli	a5,a1,0x20
    80003244:	01e7d593          	srli	a1,a5,0x1e
    80003248:	00b504b3          	add	s1,a0,a1
    8000324c:	0504a903          	lw	s2,80(s1)
    80003250:	06091e63          	bnez	s2,800032cc <bmap+0xa4>
      addr = balloc(ip->dev);
    80003254:	4108                	lw	a0,0(a0)
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	ea0080e7          	jalr	-352(ra) # 800030f6 <balloc>
    8000325e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003262:	06090563          	beqz	s2,800032cc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003266:	0524a823          	sw	s2,80(s1)
    8000326a:	a08d                	j	800032cc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000326c:	ff45849b          	addiw	s1,a1,-12
    80003270:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003274:	0ff00793          	li	a5,255
    80003278:	08e7e563          	bltu	a5,a4,80003302 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000327c:	08052903          	lw	s2,128(a0)
    80003280:	00091d63          	bnez	s2,8000329a <bmap+0x72>
      addr = balloc(ip->dev);
    80003284:	4108                	lw	a0,0(a0)
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e70080e7          	jalr	-400(ra) # 800030f6 <balloc>
    8000328e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003292:	02090d63          	beqz	s2,800032cc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003296:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000329a:	85ca                	mv	a1,s2
    8000329c:	0009a503          	lw	a0,0(s3)
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	b94080e7          	jalr	-1132(ra) # 80002e34 <bread>
    800032a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ae:	02049713          	slli	a4,s1,0x20
    800032b2:	01e75593          	srli	a1,a4,0x1e
    800032b6:	00b784b3          	add	s1,a5,a1
    800032ba:	0004a903          	lw	s2,0(s1)
    800032be:	02090063          	beqz	s2,800032de <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032c2:	8552                	mv	a0,s4
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	ca0080e7          	jalr	-864(ra) # 80002f64 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032cc:	854a                	mv	a0,s2
    800032ce:	70a2                	ld	ra,40(sp)
    800032d0:	7402                	ld	s0,32(sp)
    800032d2:	64e2                	ld	s1,24(sp)
    800032d4:	6942                	ld	s2,16(sp)
    800032d6:	69a2                	ld	s3,8(sp)
    800032d8:	6a02                	ld	s4,0(sp)
    800032da:	6145                	addi	sp,sp,48
    800032dc:	8082                	ret
      addr = balloc(ip->dev);
    800032de:	0009a503          	lw	a0,0(s3)
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	e14080e7          	jalr	-492(ra) # 800030f6 <balloc>
    800032ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800032ee:	fc090ae3          	beqz	s2,800032c2 <bmap+0x9a>
        a[bn] = addr;
    800032f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032f6:	8552                	mv	a0,s4
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	ef6080e7          	jalr	-266(ra) # 800041ee <log_write>
    80003300:	b7c9                	j	800032c2 <bmap+0x9a>
  panic("bmap: out of range");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	27650513          	addi	a0,a0,630 # 80008578 <syscalls+0x128>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	236080e7          	jalr	566(ra) # 80000540 <panic>

0000000080003312 <iget>:
{
    80003312:	7179                	addi	sp,sp,-48
    80003314:	f406                	sd	ra,40(sp)
    80003316:	f022                	sd	s0,32(sp)
    80003318:	ec26                	sd	s1,24(sp)
    8000331a:	e84a                	sd	s2,16(sp)
    8000331c:	e44e                	sd	s3,8(sp)
    8000331e:	e052                	sd	s4,0(sp)
    80003320:	1800                	addi	s0,sp,48
    80003322:	89aa                	mv	s3,a0
    80003324:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003326:	0001c517          	auipc	a0,0x1c
    8000332a:	f6250513          	addi	a0,a0,-158 # 8001f288 <itable>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  empty = 0;
    80003336:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003338:	0001c497          	auipc	s1,0x1c
    8000333c:	f6848493          	addi	s1,s1,-152 # 8001f2a0 <itable+0x18>
    80003340:	0001e697          	auipc	a3,0x1e
    80003344:	9f068693          	addi	a3,a3,-1552 # 80020d30 <log>
    80003348:	a039                	j	80003356 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334a:	02090b63          	beqz	s2,80003380 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334e:	08848493          	addi	s1,s1,136
    80003352:	02d48a63          	beq	s1,a3,80003386 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003356:	449c                	lw	a5,8(s1)
    80003358:	fef059e3          	blez	a5,8000334a <iget+0x38>
    8000335c:	4098                	lw	a4,0(s1)
    8000335e:	ff3716e3          	bne	a4,s3,8000334a <iget+0x38>
    80003362:	40d8                	lw	a4,4(s1)
    80003364:	ff4713e3          	bne	a4,s4,8000334a <iget+0x38>
      ip->ref++;
    80003368:	2785                	addiw	a5,a5,1
    8000336a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000336c:	0001c517          	auipc	a0,0x1c
    80003370:	f1c50513          	addi	a0,a0,-228 # 8001f288 <itable>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
      return ip;
    8000337c:	8926                	mv	s2,s1
    8000337e:	a03d                	j	800033ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003380:	f7f9                	bnez	a5,8000334e <iget+0x3c>
    80003382:	8926                	mv	s2,s1
    80003384:	b7e9                	j	8000334e <iget+0x3c>
  if(empty == 0)
    80003386:	02090c63          	beqz	s2,800033be <iget+0xac>
  ip->dev = dev;
    8000338a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000338e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003392:	4785                	li	a5,1
    80003394:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003398:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000339c:	0001c517          	auipc	a0,0x1c
    800033a0:	eec50513          	addi	a0,a0,-276 # 8001f288 <itable>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8e6080e7          	jalr	-1818(ra) # 80000c8a <release>
}
    800033ac:	854a                	mv	a0,s2
    800033ae:	70a2                	ld	ra,40(sp)
    800033b0:	7402                	ld	s0,32(sp)
    800033b2:	64e2                	ld	s1,24(sp)
    800033b4:	6942                	ld	s2,16(sp)
    800033b6:	69a2                	ld	s3,8(sp)
    800033b8:	6a02                	ld	s4,0(sp)
    800033ba:	6145                	addi	sp,sp,48
    800033bc:	8082                	ret
    panic("iget: no inodes");
    800033be:	00005517          	auipc	a0,0x5
    800033c2:	1d250513          	addi	a0,a0,466 # 80008590 <syscalls+0x140>
    800033c6:	ffffd097          	auipc	ra,0xffffd
    800033ca:	17a080e7          	jalr	378(ra) # 80000540 <panic>

00000000800033ce <fsinit>:
fsinit(int dev) {
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	1800                	addi	s0,sp,48
    800033dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033de:	4585                	li	a1,1
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	a54080e7          	jalr	-1452(ra) # 80002e34 <bread>
    800033e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ea:	0001c997          	auipc	s3,0x1c
    800033ee:	e7e98993          	addi	s3,s3,-386 # 8001f268 <sb>
    800033f2:	02000613          	li	a2,32
    800033f6:	05850593          	addi	a1,a0,88
    800033fa:	854e                	mv	a0,s3
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	932080e7          	jalr	-1742(ra) # 80000d2e <memmove>
  brelse(bp);
    80003404:	8526                	mv	a0,s1
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	b5e080e7          	jalr	-1186(ra) # 80002f64 <brelse>
  if(sb.magic != FSMAGIC)
    8000340e:	0009a703          	lw	a4,0(s3)
    80003412:	102037b7          	lui	a5,0x10203
    80003416:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341a:	02f71263          	bne	a4,a5,8000343e <fsinit+0x70>
  initlog(dev, &sb);
    8000341e:	0001c597          	auipc	a1,0x1c
    80003422:	e4a58593          	addi	a1,a1,-438 # 8001f268 <sb>
    80003426:	854a                	mv	a0,s2
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	b4a080e7          	jalr	-1206(ra) # 80003f72 <initlog>
}
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6145                	addi	sp,sp,48
    8000343c:	8082                	ret
    panic("invalid file system");
    8000343e:	00005517          	auipc	a0,0x5
    80003442:	16250513          	addi	a0,a0,354 # 800085a0 <syscalls+0x150>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	0fa080e7          	jalr	250(ra) # 80000540 <panic>

000000008000344e <iinit>:
{
    8000344e:	7179                	addi	sp,sp,-48
    80003450:	f406                	sd	ra,40(sp)
    80003452:	f022                	sd	s0,32(sp)
    80003454:	ec26                	sd	s1,24(sp)
    80003456:	e84a                	sd	s2,16(sp)
    80003458:	e44e                	sd	s3,8(sp)
    8000345a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000345c:	00005597          	auipc	a1,0x5
    80003460:	15c58593          	addi	a1,a1,348 # 800085b8 <syscalls+0x168>
    80003464:	0001c517          	auipc	a0,0x1c
    80003468:	e2450513          	addi	a0,a0,-476 # 8001f288 <itable>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	6da080e7          	jalr	1754(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003474:	0001c497          	auipc	s1,0x1c
    80003478:	e3c48493          	addi	s1,s1,-452 # 8001f2b0 <itable+0x28>
    8000347c:	0001e997          	auipc	s3,0x1e
    80003480:	8c498993          	addi	s3,s3,-1852 # 80020d40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003484:	00005917          	auipc	s2,0x5
    80003488:	13c90913          	addi	s2,s2,316 # 800085c0 <syscalls+0x170>
    8000348c:	85ca                	mv	a1,s2
    8000348e:	8526                	mv	a0,s1
    80003490:	00001097          	auipc	ra,0x1
    80003494:	e42080e7          	jalr	-446(ra) # 800042d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003498:	08848493          	addi	s1,s1,136
    8000349c:	ff3498e3          	bne	s1,s3,8000348c <iinit+0x3e>
}
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret

00000000800034ae <ialloc>:
{
    800034ae:	715d                	addi	sp,sp,-80
    800034b0:	e486                	sd	ra,72(sp)
    800034b2:	e0a2                	sd	s0,64(sp)
    800034b4:	fc26                	sd	s1,56(sp)
    800034b6:	f84a                	sd	s2,48(sp)
    800034b8:	f44e                	sd	s3,40(sp)
    800034ba:	f052                	sd	s4,32(sp)
    800034bc:	ec56                	sd	s5,24(sp)
    800034be:	e85a                	sd	s6,16(sp)
    800034c0:	e45e                	sd	s7,8(sp)
    800034c2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c4:	0001c717          	auipc	a4,0x1c
    800034c8:	db072703          	lw	a4,-592(a4) # 8001f274 <sb+0xc>
    800034cc:	4785                	li	a5,1
    800034ce:	04e7fa63          	bgeu	a5,a4,80003522 <ialloc+0x74>
    800034d2:	8aaa                	mv	s5,a0
    800034d4:	8bae                	mv	s7,a1
    800034d6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034d8:	0001ca17          	auipc	s4,0x1c
    800034dc:	d90a0a13          	addi	s4,s4,-624 # 8001f268 <sb>
    800034e0:	00048b1b          	sext.w	s6,s1
    800034e4:	0044d593          	srli	a1,s1,0x4
    800034e8:	018a2783          	lw	a5,24(s4)
    800034ec:	9dbd                	addw	a1,a1,a5
    800034ee:	8556                	mv	a0,s5
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	944080e7          	jalr	-1724(ra) # 80002e34 <bread>
    800034f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fa:	05850993          	addi	s3,a0,88
    800034fe:	00f4f793          	andi	a5,s1,15
    80003502:	079a                	slli	a5,a5,0x6
    80003504:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003506:	00099783          	lh	a5,0(s3)
    8000350a:	c3a1                	beqz	a5,8000354a <ialloc+0x9c>
    brelse(bp);
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	a58080e7          	jalr	-1448(ra) # 80002f64 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003514:	0485                	addi	s1,s1,1
    80003516:	00ca2703          	lw	a4,12(s4)
    8000351a:	0004879b          	sext.w	a5,s1
    8000351e:	fce7e1e3          	bltu	a5,a4,800034e0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	0a650513          	addi	a0,a0,166 # 800085c8 <syscalls+0x178>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	060080e7          	jalr	96(ra) # 8000058a <printf>
  return 0;
    80003532:	4501                	li	a0,0
}
    80003534:	60a6                	ld	ra,72(sp)
    80003536:	6406                	ld	s0,64(sp)
    80003538:	74e2                	ld	s1,56(sp)
    8000353a:	7942                	ld	s2,48(sp)
    8000353c:	79a2                	ld	s3,40(sp)
    8000353e:	7a02                	ld	s4,32(sp)
    80003540:	6ae2                	ld	s5,24(sp)
    80003542:	6b42                	ld	s6,16(sp)
    80003544:	6ba2                	ld	s7,8(sp)
    80003546:	6161                	addi	sp,sp,80
    80003548:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000354a:	04000613          	li	a2,64
    8000354e:	4581                	li	a1,0
    80003550:	854e                	mv	a0,s3
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	780080e7          	jalr	1920(ra) # 80000cd2 <memset>
      dip->type = type;
    8000355a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000355e:	854a                	mv	a0,s2
    80003560:	00001097          	auipc	ra,0x1
    80003564:	c8e080e7          	jalr	-882(ra) # 800041ee <log_write>
      brelse(bp);
    80003568:	854a                	mv	a0,s2
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	9fa080e7          	jalr	-1542(ra) # 80002f64 <brelse>
      return iget(dev, inum);
    80003572:	85da                	mv	a1,s6
    80003574:	8556                	mv	a0,s5
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	d9c080e7          	jalr	-612(ra) # 80003312 <iget>
    8000357e:	bf5d                	j	80003534 <ialloc+0x86>

0000000080003580 <iupdate>:
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	e04a                	sd	s2,0(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000358e:	415c                	lw	a5,4(a0)
    80003590:	0047d79b          	srliw	a5,a5,0x4
    80003594:	0001c597          	auipc	a1,0x1c
    80003598:	cec5a583          	lw	a1,-788(a1) # 8001f280 <sb+0x18>
    8000359c:	9dbd                	addw	a1,a1,a5
    8000359e:	4108                	lw	a0,0(a0)
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	894080e7          	jalr	-1900(ra) # 80002e34 <bread>
    800035a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035aa:	05850793          	addi	a5,a0,88
    800035ae:	40d8                	lw	a4,4(s1)
    800035b0:	8b3d                	andi	a4,a4,15
    800035b2:	071a                	slli	a4,a4,0x6
    800035b4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035b6:	04449703          	lh	a4,68(s1)
    800035ba:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035be:	04649703          	lh	a4,70(s1)
    800035c2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035c6:	04849703          	lh	a4,72(s1)
    800035ca:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035ce:	04a49703          	lh	a4,74(s1)
    800035d2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035d6:	44f8                	lw	a4,76(s1)
    800035d8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035da:	03400613          	li	a2,52
    800035de:	05048593          	addi	a1,s1,80
    800035e2:	00c78513          	addi	a0,a5,12
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	748080e7          	jalr	1864(ra) # 80000d2e <memmove>
  log_write(bp);
    800035ee:	854a                	mv	a0,s2
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	bfe080e7          	jalr	-1026(ra) # 800041ee <log_write>
  brelse(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	96a080e7          	jalr	-1686(ra) # 80002f64 <brelse>
}
    80003602:	60e2                	ld	ra,24(sp)
    80003604:	6442                	ld	s0,16(sp)
    80003606:	64a2                	ld	s1,8(sp)
    80003608:	6902                	ld	s2,0(sp)
    8000360a:	6105                	addi	sp,sp,32
    8000360c:	8082                	ret

000000008000360e <idup>:
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	1000                	addi	s0,sp,32
    80003618:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000361a:	0001c517          	auipc	a0,0x1c
    8000361e:	c6e50513          	addi	a0,a0,-914 # 8001f288 <itable>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	5b4080e7          	jalr	1460(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000362a:	449c                	lw	a5,8(s1)
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	c5850513          	addi	a0,a0,-936 # 8001f288 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
}
    80003640:	8526                	mv	a0,s1
    80003642:	60e2                	ld	ra,24(sp)
    80003644:	6442                	ld	s0,16(sp)
    80003646:	64a2                	ld	s1,8(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret

000000008000364c <ilock>:
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	e04a                	sd	s2,0(sp)
    80003656:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003658:	c115                	beqz	a0,8000367c <ilock+0x30>
    8000365a:	84aa                	mv	s1,a0
    8000365c:	451c                	lw	a5,8(a0)
    8000365e:	00f05f63          	blez	a5,8000367c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003662:	0541                	addi	a0,a0,16
    80003664:	00001097          	auipc	ra,0x1
    80003668:	ca8080e7          	jalr	-856(ra) # 8000430c <acquiresleep>
  if(ip->valid == 0){
    8000366c:	40bc                	lw	a5,64(s1)
    8000366e:	cf99                	beqz	a5,8000368c <ilock+0x40>
}
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	64a2                	ld	s1,8(sp)
    80003676:	6902                	ld	s2,0(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret
    panic("ilock");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	f6450513          	addi	a0,a0,-156 # 800085e0 <syscalls+0x190>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368c:	40dc                	lw	a5,4(s1)
    8000368e:	0047d79b          	srliw	a5,a5,0x4
    80003692:	0001c597          	auipc	a1,0x1c
    80003696:	bee5a583          	lw	a1,-1042(a1) # 8001f280 <sb+0x18>
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	4088                	lw	a0,0(s1)
    8000369e:	fffff097          	auipc	ra,0xfffff
    800036a2:	796080e7          	jalr	1942(ra) # 80002e34 <bread>
    800036a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a8:	05850593          	addi	a1,a0,88
    800036ac:	40dc                	lw	a5,4(s1)
    800036ae:	8bbd                	andi	a5,a5,15
    800036b0:	079a                	slli	a5,a5,0x6
    800036b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b4:	00059783          	lh	a5,0(a1)
    800036b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036bc:	00259783          	lh	a5,2(a1)
    800036c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c4:	00459783          	lh	a5,4(a1)
    800036c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036cc:	00659783          	lh	a5,6(a1)
    800036d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d4:	459c                	lw	a5,8(a1)
    800036d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036d8:	03400613          	li	a2,52
    800036dc:	05b1                	addi	a1,a1,12
    800036de:	05048513          	addi	a0,s1,80
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	64c080e7          	jalr	1612(ra) # 80000d2e <memmove>
    brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	878080e7          	jalr	-1928(ra) # 80002f64 <brelse>
    ip->valid = 1;
    800036f4:	4785                	li	a5,1
    800036f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036f8:	04449783          	lh	a5,68(s1)
    800036fc:	fbb5                	bnez	a5,80003670 <ilock+0x24>
      panic("ilock: no type");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	eea50513          	addi	a0,a0,-278 # 800085e8 <syscalls+0x198>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e3a080e7          	jalr	-454(ra) # 80000540 <panic>

000000008000370e <iunlock>:
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	e04a                	sd	s2,0(sp)
    80003718:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000371a:	c905                	beqz	a0,8000374a <iunlock+0x3c>
    8000371c:	84aa                	mv	s1,a0
    8000371e:	01050913          	addi	s2,a0,16
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	c82080e7          	jalr	-894(ra) # 800043a6 <holdingsleep>
    8000372c:	cd19                	beqz	a0,8000374a <iunlock+0x3c>
    8000372e:	449c                	lw	a5,8(s1)
    80003730:	00f05d63          	blez	a5,8000374a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	c2c080e7          	jalr	-980(ra) # 80004362 <releasesleep>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6902                	ld	s2,0(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret
    panic("iunlock");
    8000374a:	00005517          	auipc	a0,0x5
    8000374e:	eae50513          	addi	a0,a0,-338 # 800085f8 <syscalls+0x1a8>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	dee080e7          	jalr	-530(ra) # 80000540 <panic>

000000008000375a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000375a:	7179                	addi	sp,sp,-48
    8000375c:	f406                	sd	ra,40(sp)
    8000375e:	f022                	sd	s0,32(sp)
    80003760:	ec26                	sd	s1,24(sp)
    80003762:	e84a                	sd	s2,16(sp)
    80003764:	e44e                	sd	s3,8(sp)
    80003766:	e052                	sd	s4,0(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376c:	05050493          	addi	s1,a0,80
    80003770:	08050913          	addi	s2,a0,128
    80003774:	a021                	j	8000377c <itrunc+0x22>
    80003776:	0491                	addi	s1,s1,4
    80003778:	01248d63          	beq	s1,s2,80003792 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377c:	408c                	lw	a1,0(s1)
    8000377e:	dde5                	beqz	a1,80003776 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003780:	0009a503          	lw	a0,0(s3)
    80003784:	00000097          	auipc	ra,0x0
    80003788:	8f6080e7          	jalr	-1802(ra) # 8000307a <bfree>
      ip->addrs[i] = 0;
    8000378c:	0004a023          	sw	zero,0(s1)
    80003790:	b7dd                	j	80003776 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003792:	0809a583          	lw	a1,128(s3)
    80003796:	e185                	bnez	a1,800037b6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003798:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379c:	854e                	mv	a0,s3
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	de2080e7          	jalr	-542(ra) # 80003580 <iupdate>
}
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6a02                	ld	s4,0(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b6:	0009a503          	lw	a0,0(s3)
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	67a080e7          	jalr	1658(ra) # 80002e34 <bread>
    800037c2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c4:	05850493          	addi	s1,a0,88
    800037c8:	45850913          	addi	s2,a0,1112
    800037cc:	a021                	j	800037d4 <itrunc+0x7a>
    800037ce:	0491                	addi	s1,s1,4
    800037d0:	01248b63          	beq	s1,s2,800037e6 <itrunc+0x8c>
      if(a[j])
    800037d4:	408c                	lw	a1,0(s1)
    800037d6:	dde5                	beqz	a1,800037ce <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037d8:	0009a503          	lw	a0,0(s3)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	89e080e7          	jalr	-1890(ra) # 8000307a <bfree>
    800037e4:	b7ed                	j	800037ce <itrunc+0x74>
    brelse(bp);
    800037e6:	8552                	mv	a0,s4
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	77c080e7          	jalr	1916(ra) # 80002f64 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037f0:	0809a583          	lw	a1,128(s3)
    800037f4:	0009a503          	lw	a0,0(s3)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	882080e7          	jalr	-1918(ra) # 8000307a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003800:	0809a023          	sw	zero,128(s3)
    80003804:	bf51                	j	80003798 <itrunc+0x3e>

0000000080003806 <iput>:
{
    80003806:	1101                	addi	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	a7450513          	addi	a0,a0,-1420 # 8001f288 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003824:	4498                	lw	a4,8(s1)
    80003826:	4785                	li	a5,1
    80003828:	02f70363          	beq	a4,a5,8000384e <iput+0x48>
  ip->ref--;
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	37fd                	addiw	a5,a5,-1
    80003830:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003832:	0001c517          	auipc	a0,0x1c
    80003836:	a5650513          	addi	a0,a0,-1450 # 8001f288 <itable>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	450080e7          	jalr	1104(ra) # 80000c8a <release>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6902                	ld	s2,0(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384e:	40bc                	lw	a5,64(s1)
    80003850:	dff1                	beqz	a5,8000382c <iput+0x26>
    80003852:	04a49783          	lh	a5,74(s1)
    80003856:	fbf9                	bnez	a5,8000382c <iput+0x26>
    acquiresleep(&ip->lock);
    80003858:	01048913          	addi	s2,s1,16
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	aae080e7          	jalr	-1362(ra) # 8000430c <acquiresleep>
    release(&itable.lock);
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	a2250513          	addi	a0,a0,-1502 # 8001f288 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	41c080e7          	jalr	1052(ra) # 80000c8a <release>
    itrunc(ip);
    80003876:	8526                	mv	a0,s1
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	ee2080e7          	jalr	-286(ra) # 8000375a <itrunc>
    ip->type = 0;
    80003880:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003884:	8526                	mv	a0,s1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	cfa080e7          	jalr	-774(ra) # 80003580 <iupdate>
    ip->valid = 0;
    8000388e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003892:	854a                	mv	a0,s2
    80003894:	00001097          	auipc	ra,0x1
    80003898:	ace080e7          	jalr	-1330(ra) # 80004362 <releasesleep>
    acquire(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	9ec50513          	addi	a0,a0,-1556 # 8001f288 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	332080e7          	jalr	818(ra) # 80000bd6 <acquire>
    800038ac:	b741                	j	8000382c <iput+0x26>

00000000800038ae <iunlockput>:
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e54080e7          	jalr	-428(ra) # 8000370e <iunlock>
  iput(ip);
    800038c2:	8526                	mv	a0,s1
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	f42080e7          	jalr	-190(ra) # 80003806 <iput>
}
    800038cc:	60e2                	ld	ra,24(sp)
    800038ce:	6442                	ld	s0,16(sp)
    800038d0:	64a2                	ld	s1,8(sp)
    800038d2:	6105                	addi	sp,sp,32
    800038d4:	8082                	ret

00000000800038d6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d6:	1141                	addi	sp,sp,-16
    800038d8:	e422                	sd	s0,8(sp)
    800038da:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038dc:	411c                	lw	a5,0(a0)
    800038de:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038e0:	415c                	lw	a5,4(a0)
    800038e2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038e4:	04451783          	lh	a5,68(a0)
    800038e8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ec:	04a51783          	lh	a5,74(a0)
    800038f0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038f4:	04c56783          	lwu	a5,76(a0)
    800038f8:	e99c                	sd	a5,16(a1)
}
    800038fa:	6422                	ld	s0,8(sp)
    800038fc:	0141                	addi	sp,sp,16
    800038fe:	8082                	ret

0000000080003900 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003900:	457c                	lw	a5,76(a0)
    80003902:	0ed7e963          	bltu	a5,a3,800039f4 <readi+0xf4>
{
    80003906:	7159                	addi	sp,sp,-112
    80003908:	f486                	sd	ra,104(sp)
    8000390a:	f0a2                	sd	s0,96(sp)
    8000390c:	eca6                	sd	s1,88(sp)
    8000390e:	e8ca                	sd	s2,80(sp)
    80003910:	e4ce                	sd	s3,72(sp)
    80003912:	e0d2                	sd	s4,64(sp)
    80003914:	fc56                	sd	s5,56(sp)
    80003916:	f85a                	sd	s6,48(sp)
    80003918:	f45e                	sd	s7,40(sp)
    8000391a:	f062                	sd	s8,32(sp)
    8000391c:	ec66                	sd	s9,24(sp)
    8000391e:	e86a                	sd	s10,16(sp)
    80003920:	e46e                	sd	s11,8(sp)
    80003922:	1880                	addi	s0,sp,112
    80003924:	8b2a                	mv	s6,a0
    80003926:	8bae                	mv	s7,a1
    80003928:	8a32                	mv	s4,a2
    8000392a:	84b6                	mv	s1,a3
    8000392c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000392e:	9f35                	addw	a4,a4,a3
    return 0;
    80003930:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003932:	0ad76063          	bltu	a4,a3,800039d2 <readi+0xd2>
  if(off + n > ip->size)
    80003936:	00e7f463          	bgeu	a5,a4,8000393e <readi+0x3e>
    n = ip->size - off;
    8000393a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393e:	0a0a8963          	beqz	s5,800039f0 <readi+0xf0>
    80003942:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003944:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003948:	5c7d                	li	s8,-1
    8000394a:	a82d                	j	80003984 <readi+0x84>
    8000394c:	020d1d93          	slli	s11,s10,0x20
    80003950:	020ddd93          	srli	s11,s11,0x20
    80003954:	05890613          	addi	a2,s2,88
    80003958:	86ee                	mv	a3,s11
    8000395a:	963a                	add	a2,a2,a4
    8000395c:	85d2                	mv	a1,s4
    8000395e:	855e                	mv	a0,s7
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	afc080e7          	jalr	-1284(ra) # 8000245c <either_copyout>
    80003968:	05850d63          	beq	a0,s8,800039c2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396c:	854a                	mv	a0,s2
    8000396e:	fffff097          	auipc	ra,0xfffff
    80003972:	5f6080e7          	jalr	1526(ra) # 80002f64 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003976:	013d09bb          	addw	s3,s10,s3
    8000397a:	009d04bb          	addw	s1,s10,s1
    8000397e:	9a6e                	add	s4,s4,s11
    80003980:	0559f763          	bgeu	s3,s5,800039ce <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003984:	00a4d59b          	srliw	a1,s1,0xa
    80003988:	855a                	mv	a0,s6
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	89e080e7          	jalr	-1890(ra) # 80003228 <bmap>
    80003992:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003996:	cd85                	beqz	a1,800039ce <readi+0xce>
    bp = bread(ip->dev, addr);
    80003998:	000b2503          	lw	a0,0(s6)
    8000399c:	fffff097          	auipc	ra,0xfffff
    800039a0:	498080e7          	jalr	1176(ra) # 80002e34 <bread>
    800039a4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a6:	3ff4f713          	andi	a4,s1,1023
    800039aa:	40ec87bb          	subw	a5,s9,a4
    800039ae:	413a86bb          	subw	a3,s5,s3
    800039b2:	8d3e                	mv	s10,a5
    800039b4:	2781                	sext.w	a5,a5
    800039b6:	0006861b          	sext.w	a2,a3
    800039ba:	f8f679e3          	bgeu	a2,a5,8000394c <readi+0x4c>
    800039be:	8d36                	mv	s10,a3
    800039c0:	b771                	j	8000394c <readi+0x4c>
      brelse(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	5a0080e7          	jalr	1440(ra) # 80002f64 <brelse>
      tot = -1;
    800039cc:	59fd                	li	s3,-1
  }
  return tot;
    800039ce:	0009851b          	sext.w	a0,s3
}
    800039d2:	70a6                	ld	ra,104(sp)
    800039d4:	7406                	ld	s0,96(sp)
    800039d6:	64e6                	ld	s1,88(sp)
    800039d8:	6946                	ld	s2,80(sp)
    800039da:	69a6                	ld	s3,72(sp)
    800039dc:	6a06                	ld	s4,64(sp)
    800039de:	7ae2                	ld	s5,56(sp)
    800039e0:	7b42                	ld	s6,48(sp)
    800039e2:	7ba2                	ld	s7,40(sp)
    800039e4:	7c02                	ld	s8,32(sp)
    800039e6:	6ce2                	ld	s9,24(sp)
    800039e8:	6d42                	ld	s10,16(sp)
    800039ea:	6da2                	ld	s11,8(sp)
    800039ec:	6165                	addi	sp,sp,112
    800039ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f0:	89d6                	mv	s3,s5
    800039f2:	bff1                	j	800039ce <readi+0xce>
    return 0;
    800039f4:	4501                	li	a0,0
}
    800039f6:	8082                	ret

00000000800039f8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f8:	457c                	lw	a5,76(a0)
    800039fa:	10d7e863          	bltu	a5,a3,80003b0a <writei+0x112>
{
    800039fe:	7159                	addi	sp,sp,-112
    80003a00:	f486                	sd	ra,104(sp)
    80003a02:	f0a2                	sd	s0,96(sp)
    80003a04:	eca6                	sd	s1,88(sp)
    80003a06:	e8ca                	sd	s2,80(sp)
    80003a08:	e4ce                	sd	s3,72(sp)
    80003a0a:	e0d2                	sd	s4,64(sp)
    80003a0c:	fc56                	sd	s5,56(sp)
    80003a0e:	f85a                	sd	s6,48(sp)
    80003a10:	f45e                	sd	s7,40(sp)
    80003a12:	f062                	sd	s8,32(sp)
    80003a14:	ec66                	sd	s9,24(sp)
    80003a16:	e86a                	sd	s10,16(sp)
    80003a18:	e46e                	sd	s11,8(sp)
    80003a1a:	1880                	addi	s0,sp,112
    80003a1c:	8aaa                	mv	s5,a0
    80003a1e:	8bae                	mv	s7,a1
    80003a20:	8a32                	mv	s4,a2
    80003a22:	8936                	mv	s2,a3
    80003a24:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a26:	00e687bb          	addw	a5,a3,a4
    80003a2a:	0ed7e263          	bltu	a5,a3,80003b0e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a2e:	00043737          	lui	a4,0x43
    80003a32:	0ef76063          	bltu	a4,a5,80003b12 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a36:	0c0b0863          	beqz	s6,80003b06 <writei+0x10e>
    80003a3a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a40:	5c7d                	li	s8,-1
    80003a42:	a091                	j	80003a86 <writei+0x8e>
    80003a44:	020d1d93          	slli	s11,s10,0x20
    80003a48:	020ddd93          	srli	s11,s11,0x20
    80003a4c:	05848513          	addi	a0,s1,88
    80003a50:	86ee                	mv	a3,s11
    80003a52:	8652                	mv	a2,s4
    80003a54:	85de                	mv	a1,s7
    80003a56:	953a                	add	a0,a0,a4
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	a5a080e7          	jalr	-1446(ra) # 800024b2 <either_copyin>
    80003a60:	07850263          	beq	a0,s8,80003ac4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a64:	8526                	mv	a0,s1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	788080e7          	jalr	1928(ra) # 800041ee <log_write>
    brelse(bp);
    80003a6e:	8526                	mv	a0,s1
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	4f4080e7          	jalr	1268(ra) # 80002f64 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a78:	013d09bb          	addw	s3,s10,s3
    80003a7c:	012d093b          	addw	s2,s10,s2
    80003a80:	9a6e                	add	s4,s4,s11
    80003a82:	0569f663          	bgeu	s3,s6,80003ace <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a86:	00a9559b          	srliw	a1,s2,0xa
    80003a8a:	8556                	mv	a0,s5
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	79c080e7          	jalr	1948(ra) # 80003228 <bmap>
    80003a94:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a98:	c99d                	beqz	a1,80003ace <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a9a:	000aa503          	lw	a0,0(s5)
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	396080e7          	jalr	918(ra) # 80002e34 <bread>
    80003aa6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa8:	3ff97713          	andi	a4,s2,1023
    80003aac:	40ec87bb          	subw	a5,s9,a4
    80003ab0:	413b06bb          	subw	a3,s6,s3
    80003ab4:	8d3e                	mv	s10,a5
    80003ab6:	2781                	sext.w	a5,a5
    80003ab8:	0006861b          	sext.w	a2,a3
    80003abc:	f8f674e3          	bgeu	a2,a5,80003a44 <writei+0x4c>
    80003ac0:	8d36                	mv	s10,a3
    80003ac2:	b749                	j	80003a44 <writei+0x4c>
      brelse(bp);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	49e080e7          	jalr	1182(ra) # 80002f64 <brelse>
  }

  if(off > ip->size)
    80003ace:	04caa783          	lw	a5,76(s5)
    80003ad2:	0127f463          	bgeu	a5,s2,80003ada <writei+0xe2>
    ip->size = off;
    80003ad6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ada:	8556                	mv	a0,s5
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	aa4080e7          	jalr	-1372(ra) # 80003580 <iupdate>

  return tot;
    80003ae4:	0009851b          	sext.w	a0,s3
}
    80003ae8:	70a6                	ld	ra,104(sp)
    80003aea:	7406                	ld	s0,96(sp)
    80003aec:	64e6                	ld	s1,88(sp)
    80003aee:	6946                	ld	s2,80(sp)
    80003af0:	69a6                	ld	s3,72(sp)
    80003af2:	6a06                	ld	s4,64(sp)
    80003af4:	7ae2                	ld	s5,56(sp)
    80003af6:	7b42                	ld	s6,48(sp)
    80003af8:	7ba2                	ld	s7,40(sp)
    80003afa:	7c02                	ld	s8,32(sp)
    80003afc:	6ce2                	ld	s9,24(sp)
    80003afe:	6d42                	ld	s10,16(sp)
    80003b00:	6da2                	ld	s11,8(sp)
    80003b02:	6165                	addi	sp,sp,112
    80003b04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b06:	89da                	mv	s3,s6
    80003b08:	bfc9                	j	80003ada <writei+0xe2>
    return -1;
    80003b0a:	557d                	li	a0,-1
}
    80003b0c:	8082                	ret
    return -1;
    80003b0e:	557d                	li	a0,-1
    80003b10:	bfe1                	j	80003ae8 <writei+0xf0>
    return -1;
    80003b12:	557d                	li	a0,-1
    80003b14:	bfd1                	j	80003ae8 <writei+0xf0>

0000000080003b16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b16:	1141                	addi	sp,sp,-16
    80003b18:	e406                	sd	ra,8(sp)
    80003b1a:	e022                	sd	s0,0(sp)
    80003b1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b1e:	4639                	li	a2,14
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	282080e7          	jalr	642(ra) # 80000da2 <strncmp>
}
    80003b28:	60a2                	ld	ra,8(sp)
    80003b2a:	6402                	ld	s0,0(sp)
    80003b2c:	0141                	addi	sp,sp,16
    80003b2e:	8082                	ret

0000000080003b30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b30:	7139                	addi	sp,sp,-64
    80003b32:	fc06                	sd	ra,56(sp)
    80003b34:	f822                	sd	s0,48(sp)
    80003b36:	f426                	sd	s1,40(sp)
    80003b38:	f04a                	sd	s2,32(sp)
    80003b3a:	ec4e                	sd	s3,24(sp)
    80003b3c:	e852                	sd	s4,16(sp)
    80003b3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b40:	04451703          	lh	a4,68(a0)
    80003b44:	4785                	li	a5,1
    80003b46:	00f71a63          	bne	a4,a5,80003b5a <dirlookup+0x2a>
    80003b4a:	892a                	mv	s2,a0
    80003b4c:	89ae                	mv	s3,a1
    80003b4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b50:	457c                	lw	a5,76(a0)
    80003b52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b56:	e79d                	bnez	a5,80003b84 <dirlookup+0x54>
    80003b58:	a8a5                	j	80003bd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b5a:	00005517          	auipc	a0,0x5
    80003b5e:	aa650513          	addi	a0,a0,-1370 # 80008600 <syscalls+0x1b0>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	9de080e7          	jalr	-1570(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	aae50513          	addi	a0,a0,-1362 # 80008618 <syscalls+0x1c8>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	9ce080e7          	jalr	-1586(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7a:	24c1                	addiw	s1,s1,16
    80003b7c:	04c92783          	lw	a5,76(s2)
    80003b80:	04f4f763          	bgeu	s1,a5,80003bce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b84:	4741                	li	a4,16
    80003b86:	86a6                	mv	a3,s1
    80003b88:	fc040613          	addi	a2,s0,-64
    80003b8c:	4581                	li	a1,0
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	d70080e7          	jalr	-656(ra) # 80003900 <readi>
    80003b98:	47c1                	li	a5,16
    80003b9a:	fcf518e3          	bne	a0,a5,80003b6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b9e:	fc045783          	lhu	a5,-64(s0)
    80003ba2:	dfe1                	beqz	a5,80003b7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba4:	fc240593          	addi	a1,s0,-62
    80003ba8:	854e                	mv	a0,s3
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	f6c080e7          	jalr	-148(ra) # 80003b16 <namecmp>
    80003bb2:	f561                	bnez	a0,80003b7a <dirlookup+0x4a>
      if(poff)
    80003bb4:	000a0463          	beqz	s4,80003bbc <dirlookup+0x8c>
        *poff = off;
    80003bb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bbc:	fc045583          	lhu	a1,-64(s0)
    80003bc0:	00092503          	lw	a0,0(s2)
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	74e080e7          	jalr	1870(ra) # 80003312 <iget>
    80003bcc:	a011                	j	80003bd0 <dirlookup+0xa0>
  return 0;
    80003bce:	4501                	li	a0,0
}
    80003bd0:	70e2                	ld	ra,56(sp)
    80003bd2:	7442                	ld	s0,48(sp)
    80003bd4:	74a2                	ld	s1,40(sp)
    80003bd6:	7902                	ld	s2,32(sp)
    80003bd8:	69e2                	ld	s3,24(sp)
    80003bda:	6a42                	ld	s4,16(sp)
    80003bdc:	6121                	addi	sp,sp,64
    80003bde:	8082                	ret

0000000080003be0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003be0:	711d                	addi	sp,sp,-96
    80003be2:	ec86                	sd	ra,88(sp)
    80003be4:	e8a2                	sd	s0,80(sp)
    80003be6:	e4a6                	sd	s1,72(sp)
    80003be8:	e0ca                	sd	s2,64(sp)
    80003bea:	fc4e                	sd	s3,56(sp)
    80003bec:	f852                	sd	s4,48(sp)
    80003bee:	f456                	sd	s5,40(sp)
    80003bf0:	f05a                	sd	s6,32(sp)
    80003bf2:	ec5e                	sd	s7,24(sp)
    80003bf4:	e862                	sd	s8,16(sp)
    80003bf6:	e466                	sd	s9,8(sp)
    80003bf8:	e06a                	sd	s10,0(sp)
    80003bfa:	1080                	addi	s0,sp,96
    80003bfc:	84aa                	mv	s1,a0
    80003bfe:	8b2e                	mv	s6,a1
    80003c00:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c02:	00054703          	lbu	a4,0(a0)
    80003c06:	02f00793          	li	a5,47
    80003c0a:	02f70363          	beq	a4,a5,80003c30 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c0e:	ffffe097          	auipc	ra,0xffffe
    80003c12:	d9e080e7          	jalr	-610(ra) # 800019ac <myproc>
    80003c16:	15853503          	ld	a0,344(a0)
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	9f4080e7          	jalr	-1548(ra) # 8000360e <idup>
    80003c22:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c24:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c28:	4cb5                	li	s9,13
  len = path - s;
    80003c2a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2c:	4c05                	li	s8,1
    80003c2e:	a87d                	j	80003cec <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c30:	4585                	li	a1,1
    80003c32:	4505                	li	a0,1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	6de080e7          	jalr	1758(ra) # 80003312 <iget>
    80003c3c:	8a2a                	mv	s4,a0
    80003c3e:	b7dd                	j	80003c24 <namex+0x44>
      iunlockput(ip);
    80003c40:	8552                	mv	a0,s4
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	c6c080e7          	jalr	-916(ra) # 800038ae <iunlockput>
      return 0;
    80003c4a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4c:	8552                	mv	a0,s4
    80003c4e:	60e6                	ld	ra,88(sp)
    80003c50:	6446                	ld	s0,80(sp)
    80003c52:	64a6                	ld	s1,72(sp)
    80003c54:	6906                	ld	s2,64(sp)
    80003c56:	79e2                	ld	s3,56(sp)
    80003c58:	7a42                	ld	s4,48(sp)
    80003c5a:	7aa2                	ld	s5,40(sp)
    80003c5c:	7b02                	ld	s6,32(sp)
    80003c5e:	6be2                	ld	s7,24(sp)
    80003c60:	6c42                	ld	s8,16(sp)
    80003c62:	6ca2                	ld	s9,8(sp)
    80003c64:	6d02                	ld	s10,0(sp)
    80003c66:	6125                	addi	sp,sp,96
    80003c68:	8082                	ret
      iunlock(ip);
    80003c6a:	8552                	mv	a0,s4
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	aa2080e7          	jalr	-1374(ra) # 8000370e <iunlock>
      return ip;
    80003c74:	bfe1                	j	80003c4c <namex+0x6c>
      iunlockput(ip);
    80003c76:	8552                	mv	a0,s4
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	c36080e7          	jalr	-970(ra) # 800038ae <iunlockput>
      return 0;
    80003c80:	8a4e                	mv	s4,s3
    80003c82:	b7e9                	j	80003c4c <namex+0x6c>
  len = path - s;
    80003c84:	40998633          	sub	a2,s3,s1
    80003c88:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c8c:	09acd863          	bge	s9,s10,80003d1c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c90:	4639                	li	a2,14
    80003c92:	85a6                	mv	a1,s1
    80003c94:	8556                	mv	a0,s5
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	098080e7          	jalr	152(ra) # 80000d2e <memmove>
    80003c9e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	01279763          	bne	a5,s2,80003cb2 <namex+0xd2>
    path++;
    80003ca8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003caa:	0004c783          	lbu	a5,0(s1)
    80003cae:	ff278de3          	beq	a5,s2,80003ca8 <namex+0xc8>
    ilock(ip);
    80003cb2:	8552                	mv	a0,s4
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	998080e7          	jalr	-1640(ra) # 8000364c <ilock>
    if(ip->type != T_DIR){
    80003cbc:	044a1783          	lh	a5,68(s4)
    80003cc0:	f98790e3          	bne	a5,s8,80003c40 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cc4:	000b0563          	beqz	s6,80003cce <namex+0xee>
    80003cc8:	0004c783          	lbu	a5,0(s1)
    80003ccc:	dfd9                	beqz	a5,80003c6a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cce:	865e                	mv	a2,s7
    80003cd0:	85d6                	mv	a1,s5
    80003cd2:	8552                	mv	a0,s4
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	e5c080e7          	jalr	-420(ra) # 80003b30 <dirlookup>
    80003cdc:	89aa                	mv	s3,a0
    80003cde:	dd41                	beqz	a0,80003c76 <namex+0x96>
    iunlockput(ip);
    80003ce0:	8552                	mv	a0,s4
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	bcc080e7          	jalr	-1076(ra) # 800038ae <iunlockput>
    ip = next;
    80003cea:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cec:	0004c783          	lbu	a5,0(s1)
    80003cf0:	01279763          	bne	a5,s2,80003cfe <namex+0x11e>
    path++;
    80003cf4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	ff278de3          	beq	a5,s2,80003cf4 <namex+0x114>
  if(*path == 0)
    80003cfe:	cb9d                	beqz	a5,80003d34 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d00:	0004c783          	lbu	a5,0(s1)
    80003d04:	89a6                	mv	s3,s1
  len = path - s;
    80003d06:	8d5e                	mv	s10,s7
    80003d08:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0a:	01278963          	beq	a5,s2,80003d1c <namex+0x13c>
    80003d0e:	dbbd                	beqz	a5,80003c84 <namex+0xa4>
    path++;
    80003d10:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d12:	0009c783          	lbu	a5,0(s3)
    80003d16:	ff279ce3          	bne	a5,s2,80003d0e <namex+0x12e>
    80003d1a:	b7ad                	j	80003c84 <namex+0xa4>
    memmove(name, s, len);
    80003d1c:	2601                	sext.w	a2,a2
    80003d1e:	85a6                	mv	a1,s1
    80003d20:	8556                	mv	a0,s5
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	00c080e7          	jalr	12(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d2a:	9d56                	add	s10,s10,s5
    80003d2c:	000d0023          	sb	zero,0(s10)
    80003d30:	84ce                	mv	s1,s3
    80003d32:	b7bd                	j	80003ca0 <namex+0xc0>
  if(nameiparent){
    80003d34:	f00b0ce3          	beqz	s6,80003c4c <namex+0x6c>
    iput(ip);
    80003d38:	8552                	mv	a0,s4
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	acc080e7          	jalr	-1332(ra) # 80003806 <iput>
    return 0;
    80003d42:	4a01                	li	s4,0
    80003d44:	b721                	j	80003c4c <namex+0x6c>

0000000080003d46 <dirlink>:
{
    80003d46:	7139                	addi	sp,sp,-64
    80003d48:	fc06                	sd	ra,56(sp)
    80003d4a:	f822                	sd	s0,48(sp)
    80003d4c:	f426                	sd	s1,40(sp)
    80003d4e:	f04a                	sd	s2,32(sp)
    80003d50:	ec4e                	sd	s3,24(sp)
    80003d52:	e852                	sd	s4,16(sp)
    80003d54:	0080                	addi	s0,sp,64
    80003d56:	892a                	mv	s2,a0
    80003d58:	8a2e                	mv	s4,a1
    80003d5a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d5c:	4601                	li	a2,0
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	dd2080e7          	jalr	-558(ra) # 80003b30 <dirlookup>
    80003d66:	e93d                	bnez	a0,80003ddc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	04c92483          	lw	s1,76(s2)
    80003d6c:	c49d                	beqz	s1,80003d9a <dirlink+0x54>
    80003d6e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d70:	4741                	li	a4,16
    80003d72:	86a6                	mv	a3,s1
    80003d74:	fc040613          	addi	a2,s0,-64
    80003d78:	4581                	li	a1,0
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	b84080e7          	jalr	-1148(ra) # 80003900 <readi>
    80003d84:	47c1                	li	a5,16
    80003d86:	06f51163          	bne	a0,a5,80003de8 <dirlink+0xa2>
    if(de.inum == 0)
    80003d8a:	fc045783          	lhu	a5,-64(s0)
    80003d8e:	c791                	beqz	a5,80003d9a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d90:	24c1                	addiw	s1,s1,16
    80003d92:	04c92783          	lw	a5,76(s2)
    80003d96:	fcf4ede3          	bltu	s1,a5,80003d70 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d9a:	4639                	li	a2,14
    80003d9c:	85d2                	mv	a1,s4
    80003d9e:	fc240513          	addi	a0,s0,-62
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	03c080e7          	jalr	60(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003daa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dae:	4741                	li	a4,16
    80003db0:	86a6                	mv	a3,s1
    80003db2:	fc040613          	addi	a2,s0,-64
    80003db6:	4581                	li	a1,0
    80003db8:	854a                	mv	a0,s2
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	c3e080e7          	jalr	-962(ra) # 800039f8 <writei>
    80003dc2:	1541                	addi	a0,a0,-16
    80003dc4:	00a03533          	snez	a0,a0
    80003dc8:	40a00533          	neg	a0,a0
}
    80003dcc:	70e2                	ld	ra,56(sp)
    80003dce:	7442                	ld	s0,48(sp)
    80003dd0:	74a2                	ld	s1,40(sp)
    80003dd2:	7902                	ld	s2,32(sp)
    80003dd4:	69e2                	ld	s3,24(sp)
    80003dd6:	6a42                	ld	s4,16(sp)
    80003dd8:	6121                	addi	sp,sp,64
    80003dda:	8082                	ret
    iput(ip);
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	a2a080e7          	jalr	-1494(ra) # 80003806 <iput>
    return -1;
    80003de4:	557d                	li	a0,-1
    80003de6:	b7dd                	j	80003dcc <dirlink+0x86>
      panic("dirlink read");
    80003de8:	00005517          	auipc	a0,0x5
    80003dec:	84050513          	addi	a0,a0,-1984 # 80008628 <syscalls+0x1d8>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>

0000000080003df8 <namei>:

struct inode*
namei(char *path)
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e00:	fe040613          	addi	a2,s0,-32
    80003e04:	4581                	li	a1,0
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	dda080e7          	jalr	-550(ra) # 80003be0 <namex>
}
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret

0000000080003e16 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e406                	sd	ra,8(sp)
    80003e1a:	e022                	sd	s0,0(sp)
    80003e1c:	0800                	addi	s0,sp,16
    80003e1e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e20:	4585                	li	a1,1
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	dbe080e7          	jalr	-578(ra) # 80003be0 <namex>
}
    80003e2a:	60a2                	ld	ra,8(sp)
    80003e2c:	6402                	ld	s0,0(sp)
    80003e2e:	0141                	addi	sp,sp,16
    80003e30:	8082                	ret

0000000080003e32 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e32:	1101                	addi	sp,sp,-32
    80003e34:	ec06                	sd	ra,24(sp)
    80003e36:	e822                	sd	s0,16(sp)
    80003e38:	e426                	sd	s1,8(sp)
    80003e3a:	e04a                	sd	s2,0(sp)
    80003e3c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e3e:	0001d917          	auipc	s2,0x1d
    80003e42:	ef290913          	addi	s2,s2,-270 # 80020d30 <log>
    80003e46:	01892583          	lw	a1,24(s2)
    80003e4a:	02892503          	lw	a0,40(s2)
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	fe6080e7          	jalr	-26(ra) # 80002e34 <bread>
    80003e56:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e58:	02c92683          	lw	a3,44(s2)
    80003e5c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e5e:	02d05863          	blez	a3,80003e8e <write_head+0x5c>
    80003e62:	0001d797          	auipc	a5,0x1d
    80003e66:	efe78793          	addi	a5,a5,-258 # 80020d60 <log+0x30>
    80003e6a:	05c50713          	addi	a4,a0,92
    80003e6e:	36fd                	addiw	a3,a3,-1
    80003e70:	02069613          	slli	a2,a3,0x20
    80003e74:	01e65693          	srli	a3,a2,0x1e
    80003e78:	0001d617          	auipc	a2,0x1d
    80003e7c:	eec60613          	addi	a2,a2,-276 # 80020d64 <log+0x34>
    80003e80:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e82:	4390                	lw	a2,0(a5)
    80003e84:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e86:	0791                	addi	a5,a5,4
    80003e88:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e8a:	fed79ce3          	bne	a5,a3,80003e82 <write_head+0x50>
  }
  bwrite(buf);
    80003e8e:	8526                	mv	a0,s1
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	096080e7          	jalr	150(ra) # 80002f26 <bwrite>
  brelse(buf);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	0ca080e7          	jalr	202(ra) # 80002f64 <brelse>
}
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6902                	ld	s2,0(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret

0000000080003eae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eae:	0001d797          	auipc	a5,0x1d
    80003eb2:	eae7a783          	lw	a5,-338(a5) # 80020d5c <log+0x2c>
    80003eb6:	0af05d63          	blez	a5,80003f70 <install_trans+0xc2>
{
    80003eba:	7139                	addi	sp,sp,-64
    80003ebc:	fc06                	sd	ra,56(sp)
    80003ebe:	f822                	sd	s0,48(sp)
    80003ec0:	f426                	sd	s1,40(sp)
    80003ec2:	f04a                	sd	s2,32(sp)
    80003ec4:	ec4e                	sd	s3,24(sp)
    80003ec6:	e852                	sd	s4,16(sp)
    80003ec8:	e456                	sd	s5,8(sp)
    80003eca:	e05a                	sd	s6,0(sp)
    80003ecc:	0080                	addi	s0,sp,64
    80003ece:	8b2a                	mv	s6,a0
    80003ed0:	0001da97          	auipc	s5,0x1d
    80003ed4:	e90a8a93          	addi	s5,s5,-368 # 80020d60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ed8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eda:	0001d997          	auipc	s3,0x1d
    80003ede:	e5698993          	addi	s3,s3,-426 # 80020d30 <log>
    80003ee2:	a00d                	j	80003f04 <install_trans+0x56>
    brelse(lbuf);
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	07e080e7          	jalr	126(ra) # 80002f64 <brelse>
    brelse(dbuf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	074080e7          	jalr	116(ra) # 80002f64 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ef8:	2a05                	addiw	s4,s4,1
    80003efa:	0a91                	addi	s5,s5,4
    80003efc:	02c9a783          	lw	a5,44(s3)
    80003f00:	04fa5e63          	bge	s4,a5,80003f5c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f04:	0189a583          	lw	a1,24(s3)
    80003f08:	014585bb          	addw	a1,a1,s4
    80003f0c:	2585                	addiw	a1,a1,1
    80003f0e:	0289a503          	lw	a0,40(s3)
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	f22080e7          	jalr	-222(ra) # 80002e34 <bread>
    80003f1a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f1c:	000aa583          	lw	a1,0(s5)
    80003f20:	0289a503          	lw	a0,40(s3)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	f10080e7          	jalr	-240(ra) # 80002e34 <bread>
    80003f2c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f2e:	40000613          	li	a2,1024
    80003f32:	05890593          	addi	a1,s2,88
    80003f36:	05850513          	addi	a0,a0,88
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	df4080e7          	jalr	-524(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f42:	8526                	mv	a0,s1
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	fe2080e7          	jalr	-30(ra) # 80002f26 <bwrite>
    if(recovering == 0)
    80003f4c:	f80b1ce3          	bnez	s6,80003ee4 <install_trans+0x36>
      bunpin(dbuf);
    80003f50:	8526                	mv	a0,s1
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	0ec080e7          	jalr	236(ra) # 8000303e <bunpin>
    80003f5a:	b769                	j	80003ee4 <install_trans+0x36>
}
    80003f5c:	70e2                	ld	ra,56(sp)
    80003f5e:	7442                	ld	s0,48(sp)
    80003f60:	74a2                	ld	s1,40(sp)
    80003f62:	7902                	ld	s2,32(sp)
    80003f64:	69e2                	ld	s3,24(sp)
    80003f66:	6a42                	ld	s4,16(sp)
    80003f68:	6aa2                	ld	s5,8(sp)
    80003f6a:	6b02                	ld	s6,0(sp)
    80003f6c:	6121                	addi	sp,sp,64
    80003f6e:	8082                	ret
    80003f70:	8082                	ret

0000000080003f72 <initlog>:
{
    80003f72:	7179                	addi	sp,sp,-48
    80003f74:	f406                	sd	ra,40(sp)
    80003f76:	f022                	sd	s0,32(sp)
    80003f78:	ec26                	sd	s1,24(sp)
    80003f7a:	e84a                	sd	s2,16(sp)
    80003f7c:	e44e                	sd	s3,8(sp)
    80003f7e:	1800                	addi	s0,sp,48
    80003f80:	892a                	mv	s2,a0
    80003f82:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f84:	0001d497          	auipc	s1,0x1d
    80003f88:	dac48493          	addi	s1,s1,-596 # 80020d30 <log>
    80003f8c:	00004597          	auipc	a1,0x4
    80003f90:	6ac58593          	addi	a1,a1,1708 # 80008638 <syscalls+0x1e8>
    80003f94:	8526                	mv	a0,s1
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	bb0080e7          	jalr	-1104(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003f9e:	0149a583          	lw	a1,20(s3)
    80003fa2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fa4:	0109a783          	lw	a5,16(s3)
    80003fa8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003faa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fae:	854a                	mv	a0,s2
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	e84080e7          	jalr	-380(ra) # 80002e34 <bread>
  log.lh.n = lh->n;
    80003fb8:	4d34                	lw	a3,88(a0)
    80003fba:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fbc:	02d05663          	blez	a3,80003fe8 <initlog+0x76>
    80003fc0:	05c50793          	addi	a5,a0,92
    80003fc4:	0001d717          	auipc	a4,0x1d
    80003fc8:	d9c70713          	addi	a4,a4,-612 # 80020d60 <log+0x30>
    80003fcc:	36fd                	addiw	a3,a3,-1
    80003fce:	02069613          	slli	a2,a3,0x20
    80003fd2:	01e65693          	srli	a3,a2,0x1e
    80003fd6:	06050613          	addi	a2,a0,96
    80003fda:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fdc:	4390                	lw	a2,0(a5)
    80003fde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe0:	0791                	addi	a5,a5,4
    80003fe2:	0711                	addi	a4,a4,4
    80003fe4:	fed79ce3          	bne	a5,a3,80003fdc <initlog+0x6a>
  brelse(buf);
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	f7c080e7          	jalr	-132(ra) # 80002f64 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff0:	4505                	li	a0,1
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	ebc080e7          	jalr	-324(ra) # 80003eae <install_trans>
  log.lh.n = 0;
    80003ffa:	0001d797          	auipc	a5,0x1d
    80003ffe:	d607a123          	sw	zero,-670(a5) # 80020d5c <log+0x2c>
  write_head(); // clear the log
    80004002:	00000097          	auipc	ra,0x0
    80004006:	e30080e7          	jalr	-464(ra) # 80003e32 <write_head>
}
    8000400a:	70a2                	ld	ra,40(sp)
    8000400c:	7402                	ld	s0,32(sp)
    8000400e:	64e2                	ld	s1,24(sp)
    80004010:	6942                	ld	s2,16(sp)
    80004012:	69a2                	ld	s3,8(sp)
    80004014:	6145                	addi	sp,sp,48
    80004016:	8082                	ret

0000000080004018 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	e04a                	sd	s2,0(sp)
    80004022:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004024:	0001d517          	auipc	a0,0x1d
    80004028:	d0c50513          	addi	a0,a0,-756 # 80020d30 <log>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004034:	0001d497          	auipc	s1,0x1d
    80004038:	cfc48493          	addi	s1,s1,-772 # 80020d30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000403c:	4979                	li	s2,30
    8000403e:	a039                	j	8000404c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004040:	85a6                	mv	a1,s1
    80004042:	8526                	mv	a0,s1
    80004044:	ffffe097          	auipc	ra,0xffffe
    80004048:	010080e7          	jalr	16(ra) # 80002054 <sleep>
    if(log.committing){
    8000404c:	50dc                	lw	a5,36(s1)
    8000404e:	fbed                	bnez	a5,80004040 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004050:	5098                	lw	a4,32(s1)
    80004052:	2705                	addiw	a4,a4,1
    80004054:	0007069b          	sext.w	a3,a4
    80004058:	0027179b          	slliw	a5,a4,0x2
    8000405c:	9fb9                	addw	a5,a5,a4
    8000405e:	0017979b          	slliw	a5,a5,0x1
    80004062:	54d8                	lw	a4,44(s1)
    80004064:	9fb9                	addw	a5,a5,a4
    80004066:	00f95963          	bge	s2,a5,80004078 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000406a:	85a6                	mv	a1,s1
    8000406c:	8526                	mv	a0,s1
    8000406e:	ffffe097          	auipc	ra,0xffffe
    80004072:	fe6080e7          	jalr	-26(ra) # 80002054 <sleep>
    80004076:	bfd9                	j	8000404c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004078:	0001d517          	auipc	a0,0x1d
    8000407c:	cb850513          	addi	a0,a0,-840 # 80020d30 <log>
    80004080:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004082:	ffffd097          	auipc	ra,0xffffd
    80004086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000408a:	60e2                	ld	ra,24(sp)
    8000408c:	6442                	ld	s0,16(sp)
    8000408e:	64a2                	ld	s1,8(sp)
    80004090:	6902                	ld	s2,0(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004096:	7139                	addi	sp,sp,-64
    80004098:	fc06                	sd	ra,56(sp)
    8000409a:	f822                	sd	s0,48(sp)
    8000409c:	f426                	sd	s1,40(sp)
    8000409e:	f04a                	sd	s2,32(sp)
    800040a0:	ec4e                	sd	s3,24(sp)
    800040a2:	e852                	sd	s4,16(sp)
    800040a4:	e456                	sd	s5,8(sp)
    800040a6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040a8:	0001d497          	auipc	s1,0x1d
    800040ac:	c8848493          	addi	s1,s1,-888 # 80020d30 <log>
    800040b0:	8526                	mv	a0,s1
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	b24080e7          	jalr	-1244(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800040ba:	509c                	lw	a5,32(s1)
    800040bc:	37fd                	addiw	a5,a5,-1
    800040be:	0007891b          	sext.w	s2,a5
    800040c2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040c4:	50dc                	lw	a5,36(s1)
    800040c6:	e7b9                	bnez	a5,80004114 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040c8:	04091e63          	bnez	s2,80004124 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040cc:	0001d497          	auipc	s1,0x1d
    800040d0:	c6448493          	addi	s1,s1,-924 # 80020d30 <log>
    800040d4:	4785                	li	a5,1
    800040d6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040d8:	8526                	mv	a0,s1
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	bb0080e7          	jalr	-1104(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040e2:	54dc                	lw	a5,44(s1)
    800040e4:	06f04763          	bgtz	a5,80004152 <end_op+0xbc>
    acquire(&log.lock);
    800040e8:	0001d497          	auipc	s1,0x1d
    800040ec:	c4848493          	addi	s1,s1,-952 # 80020d30 <log>
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	ae4080e7          	jalr	-1308(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800040fa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040fe:	8526                	mv	a0,s1
    80004100:	ffffe097          	auipc	ra,0xffffe
    80004104:	fb8080e7          	jalr	-72(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	b80080e7          	jalr	-1152(ra) # 80000c8a <release>
}
    80004112:	a03d                	j	80004140 <end_op+0xaa>
    panic("log.committing");
    80004114:	00004517          	auipc	a0,0x4
    80004118:	52c50513          	addi	a0,a0,1324 # 80008640 <syscalls+0x1f0>
    8000411c:	ffffc097          	auipc	ra,0xffffc
    80004120:	424080e7          	jalr	1060(ra) # 80000540 <panic>
    wakeup(&log);
    80004124:	0001d497          	auipc	s1,0x1d
    80004128:	c0c48493          	addi	s1,s1,-1012 # 80020d30 <log>
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffe097          	auipc	ra,0xffffe
    80004132:	f8a080e7          	jalr	-118(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004136:	8526                	mv	a0,s1
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
}
    80004140:	70e2                	ld	ra,56(sp)
    80004142:	7442                	ld	s0,48(sp)
    80004144:	74a2                	ld	s1,40(sp)
    80004146:	7902                	ld	s2,32(sp)
    80004148:	69e2                	ld	s3,24(sp)
    8000414a:	6a42                	ld	s4,16(sp)
    8000414c:	6aa2                	ld	s5,8(sp)
    8000414e:	6121                	addi	sp,sp,64
    80004150:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004152:	0001da97          	auipc	s5,0x1d
    80004156:	c0ea8a93          	addi	s5,s5,-1010 # 80020d60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000415a:	0001da17          	auipc	s4,0x1d
    8000415e:	bd6a0a13          	addi	s4,s4,-1066 # 80020d30 <log>
    80004162:	018a2583          	lw	a1,24(s4)
    80004166:	012585bb          	addw	a1,a1,s2
    8000416a:	2585                	addiw	a1,a1,1
    8000416c:	028a2503          	lw	a0,40(s4)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	cc4080e7          	jalr	-828(ra) # 80002e34 <bread>
    80004178:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000417a:	000aa583          	lw	a1,0(s5)
    8000417e:	028a2503          	lw	a0,40(s4)
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	cb2080e7          	jalr	-846(ra) # 80002e34 <bread>
    8000418a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000418c:	40000613          	li	a2,1024
    80004190:	05850593          	addi	a1,a0,88
    80004194:	05848513          	addi	a0,s1,88
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	b96080e7          	jalr	-1130(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	d84080e7          	jalr	-636(ra) # 80002f26 <bwrite>
    brelse(from);
    800041aa:	854e                	mv	a0,s3
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	db8080e7          	jalr	-584(ra) # 80002f64 <brelse>
    brelse(to);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	dae080e7          	jalr	-594(ra) # 80002f64 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	2905                	addiw	s2,s2,1
    800041c0:	0a91                	addi	s5,s5,4
    800041c2:	02ca2783          	lw	a5,44(s4)
    800041c6:	f8f94ee3          	blt	s2,a5,80004162 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	c68080e7          	jalr	-920(ra) # 80003e32 <write_head>
    install_trans(0); // Now install writes to home locations
    800041d2:	4501                	li	a0,0
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	cda080e7          	jalr	-806(ra) # 80003eae <install_trans>
    log.lh.n = 0;
    800041dc:	0001d797          	auipc	a5,0x1d
    800041e0:	b807a023          	sw	zero,-1152(a5) # 80020d5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	c4e080e7          	jalr	-946(ra) # 80003e32 <write_head>
    800041ec:	bdf5                	j	800040e8 <end_op+0x52>

00000000800041ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	e426                	sd	s1,8(sp)
    800041f6:	e04a                	sd	s2,0(sp)
    800041f8:	1000                	addi	s0,sp,32
    800041fa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041fc:	0001d917          	auipc	s2,0x1d
    80004200:	b3490913          	addi	s2,s2,-1228 # 80020d30 <log>
    80004204:	854a                	mv	a0,s2
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	9d0080e7          	jalr	-1584(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000420e:	02c92603          	lw	a2,44(s2)
    80004212:	47f5                	li	a5,29
    80004214:	06c7c563          	blt	a5,a2,8000427e <log_write+0x90>
    80004218:	0001d797          	auipc	a5,0x1d
    8000421c:	b347a783          	lw	a5,-1228(a5) # 80020d4c <log+0x1c>
    80004220:	37fd                	addiw	a5,a5,-1
    80004222:	04f65e63          	bge	a2,a5,8000427e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004226:	0001d797          	auipc	a5,0x1d
    8000422a:	b2a7a783          	lw	a5,-1238(a5) # 80020d50 <log+0x20>
    8000422e:	06f05063          	blez	a5,8000428e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004232:	4781                	li	a5,0
    80004234:	06c05563          	blez	a2,8000429e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004238:	44cc                	lw	a1,12(s1)
    8000423a:	0001d717          	auipc	a4,0x1d
    8000423e:	b2670713          	addi	a4,a4,-1242 # 80020d60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004242:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004244:	4314                	lw	a3,0(a4)
    80004246:	04b68c63          	beq	a3,a1,8000429e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000424a:	2785                	addiw	a5,a5,1
    8000424c:	0711                	addi	a4,a4,4
    8000424e:	fef61be3          	bne	a2,a5,80004244 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004252:	0621                	addi	a2,a2,8
    80004254:	060a                	slli	a2,a2,0x2
    80004256:	0001d797          	auipc	a5,0x1d
    8000425a:	ada78793          	addi	a5,a5,-1318 # 80020d30 <log>
    8000425e:	97b2                	add	a5,a5,a2
    80004260:	44d8                	lw	a4,12(s1)
    80004262:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	d9c080e7          	jalr	-612(ra) # 80003002 <bpin>
    log.lh.n++;
    8000426e:	0001d717          	auipc	a4,0x1d
    80004272:	ac270713          	addi	a4,a4,-1342 # 80020d30 <log>
    80004276:	575c                	lw	a5,44(a4)
    80004278:	2785                	addiw	a5,a5,1
    8000427a:	d75c                	sw	a5,44(a4)
    8000427c:	a82d                	j	800042b6 <log_write+0xc8>
    panic("too big a transaction");
    8000427e:	00004517          	auipc	a0,0x4
    80004282:	3d250513          	addi	a0,a0,978 # 80008650 <syscalls+0x200>
    80004286:	ffffc097          	auipc	ra,0xffffc
    8000428a:	2ba080e7          	jalr	698(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000428e:	00004517          	auipc	a0,0x4
    80004292:	3da50513          	addi	a0,a0,986 # 80008668 <syscalls+0x218>
    80004296:	ffffc097          	auipc	ra,0xffffc
    8000429a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000429e:	00878693          	addi	a3,a5,8
    800042a2:	068a                	slli	a3,a3,0x2
    800042a4:	0001d717          	auipc	a4,0x1d
    800042a8:	a8c70713          	addi	a4,a4,-1396 # 80020d30 <log>
    800042ac:	9736                	add	a4,a4,a3
    800042ae:	44d4                	lw	a3,12(s1)
    800042b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042b2:	faf609e3          	beq	a2,a5,80004264 <log_write+0x76>
  }
  release(&log.lock);
    800042b6:	0001d517          	auipc	a0,0x1d
    800042ba:	a7a50513          	addi	a0,a0,-1414 # 80020d30 <log>
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
}
    800042c6:	60e2                	ld	ra,24(sp)
    800042c8:	6442                	ld	s0,16(sp)
    800042ca:	64a2                	ld	s1,8(sp)
    800042cc:	6902                	ld	s2,0(sp)
    800042ce:	6105                	addi	sp,sp,32
    800042d0:	8082                	ret

00000000800042d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
    800042de:	84aa                	mv	s1,a0
    800042e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042e2:	00004597          	auipc	a1,0x4
    800042e6:	3a658593          	addi	a1,a1,934 # 80008688 <syscalls+0x238>
    800042ea:	0521                	addi	a0,a0,8
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	85a080e7          	jalr	-1958(ra) # 80000b46 <initlock>
  lk->name = name;
    800042f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042fc:	0204a423          	sw	zero,40(s1)
}
    80004300:	60e2                	ld	ra,24(sp)
    80004302:	6442                	ld	s0,16(sp)
    80004304:	64a2                	ld	s1,8(sp)
    80004306:	6902                	ld	s2,0(sp)
    80004308:	6105                	addi	sp,sp,32
    8000430a:	8082                	ret

000000008000430c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431a:	00850913          	addi	s2,a0,8
    8000431e:	854a                	mv	a0,s2
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	8b6080e7          	jalr	-1866(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004328:	409c                	lw	a5,0(s1)
    8000432a:	cb89                	beqz	a5,8000433c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000432c:	85ca                	mv	a1,s2
    8000432e:	8526                	mv	a0,s1
    80004330:	ffffe097          	auipc	ra,0xffffe
    80004334:	d24080e7          	jalr	-732(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004338:	409c                	lw	a5,0(s1)
    8000433a:	fbed                	bnez	a5,8000432c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000433c:	4785                	li	a5,1
    8000433e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	66c080e7          	jalr	1644(ra) # 800019ac <myproc>
    80004348:	591c                	lw	a5,48(a0)
    8000434a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
}
    80004356:	60e2                	ld	ra,24(sp)
    80004358:	6442                	ld	s0,16(sp)
    8000435a:	64a2                	ld	s1,8(sp)
    8000435c:	6902                	ld	s2,0(sp)
    8000435e:	6105                	addi	sp,sp,32
    80004360:	8082                	ret

0000000080004362 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004362:	1101                	addi	sp,sp,-32
    80004364:	ec06                	sd	ra,24(sp)
    80004366:	e822                	sd	s0,16(sp)
    80004368:	e426                	sd	s1,8(sp)
    8000436a:	e04a                	sd	s2,0(sp)
    8000436c:	1000                	addi	s0,sp,32
    8000436e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004370:	00850913          	addi	s2,a0,8
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	860080e7          	jalr	-1952(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000437e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004382:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	d30080e7          	jalr	-720(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    80004390:	854a                	mv	a0,s2
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	8f8080e7          	jalr	-1800(ra) # 80000c8a <release>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043a6:	7179                	addi	sp,sp,-48
    800043a8:	f406                	sd	ra,40(sp)
    800043aa:	f022                	sd	s0,32(sp)
    800043ac:	ec26                	sd	s1,24(sp)
    800043ae:	e84a                	sd	s2,16(sp)
    800043b0:	e44e                	sd	s3,8(sp)
    800043b2:	1800                	addi	s0,sp,48
    800043b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043b6:	00850913          	addi	s2,a0,8
    800043ba:	854a                	mv	a0,s2
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	81a080e7          	jalr	-2022(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043c4:	409c                	lw	a5,0(s1)
    800043c6:	ef99                	bnez	a5,800043e4 <holdingsleep+0x3e>
    800043c8:	4481                	li	s1,0
  release(&lk->lk);
    800043ca:	854a                	mv	a0,s2
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
  return r;
}
    800043d4:	8526                	mv	a0,s1
    800043d6:	70a2                	ld	ra,40(sp)
    800043d8:	7402                	ld	s0,32(sp)
    800043da:	64e2                	ld	s1,24(sp)
    800043dc:	6942                	ld	s2,16(sp)
    800043de:	69a2                	ld	s3,8(sp)
    800043e0:	6145                	addi	sp,sp,48
    800043e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e4:	0284a983          	lw	s3,40(s1)
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	5c4080e7          	jalr	1476(ra) # 800019ac <myproc>
    800043f0:	5904                	lw	s1,48(a0)
    800043f2:	413484b3          	sub	s1,s1,s3
    800043f6:	0014b493          	seqz	s1,s1
    800043fa:	bfc1                	j	800043ca <holdingsleep+0x24>

00000000800043fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043fc:	1141                	addi	sp,sp,-16
    800043fe:	e406                	sd	ra,8(sp)
    80004400:	e022                	sd	s0,0(sp)
    80004402:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004404:	00004597          	auipc	a1,0x4
    80004408:	29458593          	addi	a1,a1,660 # 80008698 <syscalls+0x248>
    8000440c:	0001d517          	auipc	a0,0x1d
    80004410:	a6c50513          	addi	a0,a0,-1428 # 80020e78 <ftable>
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	732080e7          	jalr	1842(ra) # 80000b46 <initlock>
}
    8000441c:	60a2                	ld	ra,8(sp)
    8000441e:	6402                	ld	s0,0(sp)
    80004420:	0141                	addi	sp,sp,16
    80004422:	8082                	ret

0000000080004424 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000442e:	0001d517          	auipc	a0,0x1d
    80004432:	a4a50513          	addi	a0,a0,-1462 # 80020e78 <ftable>
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000443e:	0001d497          	auipc	s1,0x1d
    80004442:	a5248493          	addi	s1,s1,-1454 # 80020e90 <ftable+0x18>
    80004446:	0001e717          	auipc	a4,0x1e
    8000444a:	9ea70713          	addi	a4,a4,-1558 # 80021e30 <disk>
    if(f->ref == 0){
    8000444e:	40dc                	lw	a5,4(s1)
    80004450:	cf99                	beqz	a5,8000446e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004452:	02848493          	addi	s1,s1,40
    80004456:	fee49ce3          	bne	s1,a4,8000444e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000445a:	0001d517          	auipc	a0,0x1d
    8000445e:	a1e50513          	addi	a0,a0,-1506 # 80020e78 <ftable>
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	828080e7          	jalr	-2008(ra) # 80000c8a <release>
  return 0;
    8000446a:	4481                	li	s1,0
    8000446c:	a819                	j	80004482 <filealloc+0x5e>
      f->ref = 1;
    8000446e:	4785                	li	a5,1
    80004470:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004472:	0001d517          	auipc	a0,0x1d
    80004476:	a0650513          	addi	a0,a0,-1530 # 80020e78 <ftable>
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
}
    80004482:	8526                	mv	a0,s1
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000448e:	1101                	addi	sp,sp,-32
    80004490:	ec06                	sd	ra,24(sp)
    80004492:	e822                	sd	s0,16(sp)
    80004494:	e426                	sd	s1,8(sp)
    80004496:	1000                	addi	s0,sp,32
    80004498:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000449a:	0001d517          	auipc	a0,0x1d
    8000449e:	9de50513          	addi	a0,a0,-1570 # 80020e78 <ftable>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	734080e7          	jalr	1844(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044aa:	40dc                	lw	a5,4(s1)
    800044ac:	02f05263          	blez	a5,800044d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044b0:	2785                	addiw	a5,a5,1
    800044b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044b4:	0001d517          	auipc	a0,0x1d
    800044b8:	9c450513          	addi	a0,a0,-1596 # 80020e78 <ftable>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7ce080e7          	jalr	1998(ra) # 80000c8a <release>
  return f;
}
    800044c4:	8526                	mv	a0,s1
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret
    panic("filedup");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	1d050513          	addi	a0,a0,464 # 800086a0 <syscalls+0x250>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	068080e7          	jalr	104(ra) # 80000540 <panic>

00000000800044e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044e0:	7139                	addi	sp,sp,-64
    800044e2:	fc06                	sd	ra,56(sp)
    800044e4:	f822                	sd	s0,48(sp)
    800044e6:	f426                	sd	s1,40(sp)
    800044e8:	f04a                	sd	s2,32(sp)
    800044ea:	ec4e                	sd	s3,24(sp)
    800044ec:	e852                	sd	s4,16(sp)
    800044ee:	e456                	sd	s5,8(sp)
    800044f0:	0080                	addi	s0,sp,64
    800044f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044f4:	0001d517          	auipc	a0,0x1d
    800044f8:	98450513          	addi	a0,a0,-1660 # 80020e78 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6da080e7          	jalr	1754(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004504:	40dc                	lw	a5,4(s1)
    80004506:	06f05163          	blez	a5,80004568 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000450a:	37fd                	addiw	a5,a5,-1
    8000450c:	0007871b          	sext.w	a4,a5
    80004510:	c0dc                	sw	a5,4(s1)
    80004512:	06e04363          	bgtz	a4,80004578 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004516:	0004a903          	lw	s2,0(s1)
    8000451a:	0094ca83          	lbu	s5,9(s1)
    8000451e:	0104ba03          	ld	s4,16(s1)
    80004522:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004526:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000452a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	94a50513          	addi	a0,a0,-1718 # 80020e78 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	754080e7          	jalr	1876(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000453e:	4785                	li	a5,1
    80004540:	04f90d63          	beq	s2,a5,8000459a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004544:	3979                	addiw	s2,s2,-2
    80004546:	4785                	li	a5,1
    80004548:	0527e063          	bltu	a5,s2,80004588 <fileclose+0xa8>
    begin_op();
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	acc080e7          	jalr	-1332(ra) # 80004018 <begin_op>
    iput(ff.ip);
    80004554:	854e                	mv	a0,s3
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	2b0080e7          	jalr	688(ra) # 80003806 <iput>
    end_op();
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	b38080e7          	jalr	-1224(ra) # 80004096 <end_op>
    80004566:	a00d                	j	80004588 <fileclose+0xa8>
    panic("fileclose");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	14050513          	addi	a0,a0,320 # 800086a8 <syscalls+0x258>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	fd0080e7          	jalr	-48(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004578:	0001d517          	auipc	a0,0x1d
    8000457c:	90050513          	addi	a0,a0,-1792 # 80020e78 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	70a080e7          	jalr	1802(ra) # 80000c8a <release>
  }
}
    80004588:	70e2                	ld	ra,56(sp)
    8000458a:	7442                	ld	s0,48(sp)
    8000458c:	74a2                	ld	s1,40(sp)
    8000458e:	7902                	ld	s2,32(sp)
    80004590:	69e2                	ld	s3,24(sp)
    80004592:	6a42                	ld	s4,16(sp)
    80004594:	6aa2                	ld	s5,8(sp)
    80004596:	6121                	addi	sp,sp,64
    80004598:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000459a:	85d6                	mv	a1,s5
    8000459c:	8552                	mv	a0,s4
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	34c080e7          	jalr	844(ra) # 800048ea <pipeclose>
    800045a6:	b7cd                	j	80004588 <fileclose+0xa8>

00000000800045a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045a8:	715d                	addi	sp,sp,-80
    800045aa:	e486                	sd	ra,72(sp)
    800045ac:	e0a2                	sd	s0,64(sp)
    800045ae:	fc26                	sd	s1,56(sp)
    800045b0:	f84a                	sd	s2,48(sp)
    800045b2:	f44e                	sd	s3,40(sp)
    800045b4:	0880                	addi	s0,sp,80
    800045b6:	84aa                	mv	s1,a0
    800045b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045ba:	ffffd097          	auipc	ra,0xffffd
    800045be:	3f2080e7          	jalr	1010(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	37f9                	addiw	a5,a5,-2
    800045c6:	4705                	li	a4,1
    800045c8:	04f76763          	bltu	a4,a5,80004616 <filestat+0x6e>
    800045cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800045ce:	6c88                	ld	a0,24(s1)
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	07c080e7          	jalr	124(ra) # 8000364c <ilock>
    stati(f->ip, &st);
    800045d8:	fb840593          	addi	a1,s0,-72
    800045dc:	6c88                	ld	a0,24(s1)
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	2f8080e7          	jalr	760(ra) # 800038d6 <stati>
    iunlock(f->ip);
    800045e6:	6c88                	ld	a0,24(s1)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	126080e7          	jalr	294(ra) # 8000370e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045f0:	46e1                	li	a3,24
    800045f2:	fb840613          	addi	a2,s0,-72
    800045f6:	85ce                	mv	a1,s3
    800045f8:	05893503          	ld	a0,88(s2)
    800045fc:	ffffd097          	auipc	ra,0xffffd
    80004600:	070080e7          	jalr	112(ra) # 8000166c <copyout>
    80004604:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004608:	60a6                	ld	ra,72(sp)
    8000460a:	6406                	ld	s0,64(sp)
    8000460c:	74e2                	ld	s1,56(sp)
    8000460e:	7942                	ld	s2,48(sp)
    80004610:	79a2                	ld	s3,40(sp)
    80004612:	6161                	addi	sp,sp,80
    80004614:	8082                	ret
  return -1;
    80004616:	557d                	li	a0,-1
    80004618:	bfc5                	j	80004608 <filestat+0x60>

000000008000461a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000461a:	7179                	addi	sp,sp,-48
    8000461c:	f406                	sd	ra,40(sp)
    8000461e:	f022                	sd	s0,32(sp)
    80004620:	ec26                	sd	s1,24(sp)
    80004622:	e84a                	sd	s2,16(sp)
    80004624:	e44e                	sd	s3,8(sp)
    80004626:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004628:	00854783          	lbu	a5,8(a0)
    8000462c:	c3d5                	beqz	a5,800046d0 <fileread+0xb6>
    8000462e:	84aa                	mv	s1,a0
    80004630:	89ae                	mv	s3,a1
    80004632:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004634:	411c                	lw	a5,0(a0)
    80004636:	4705                	li	a4,1
    80004638:	04e78963          	beq	a5,a4,8000468a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000463c:	470d                	li	a4,3
    8000463e:	04e78d63          	beq	a5,a4,80004698 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004642:	4709                	li	a4,2
    80004644:	06e79e63          	bne	a5,a4,800046c0 <fileread+0xa6>
    ilock(f->ip);
    80004648:	6d08                	ld	a0,24(a0)
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	002080e7          	jalr	2(ra) # 8000364c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004652:	874a                	mv	a4,s2
    80004654:	5094                	lw	a3,32(s1)
    80004656:	864e                	mv	a2,s3
    80004658:	4585                	li	a1,1
    8000465a:	6c88                	ld	a0,24(s1)
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	2a4080e7          	jalr	676(ra) # 80003900 <readi>
    80004664:	892a                	mv	s2,a0
    80004666:	00a05563          	blez	a0,80004670 <fileread+0x56>
      f->off += r;
    8000466a:	509c                	lw	a5,32(s1)
    8000466c:	9fa9                	addw	a5,a5,a0
    8000466e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004670:	6c88                	ld	a0,24(s1)
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	09c080e7          	jalr	156(ra) # 8000370e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000467a:	854a                	mv	a0,s2
    8000467c:	70a2                	ld	ra,40(sp)
    8000467e:	7402                	ld	s0,32(sp)
    80004680:	64e2                	ld	s1,24(sp)
    80004682:	6942                	ld	s2,16(sp)
    80004684:	69a2                	ld	s3,8(sp)
    80004686:	6145                	addi	sp,sp,48
    80004688:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000468a:	6908                	ld	a0,16(a0)
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	3c6080e7          	jalr	966(ra) # 80004a52 <piperead>
    80004694:	892a                	mv	s2,a0
    80004696:	b7d5                	j	8000467a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004698:	02451783          	lh	a5,36(a0)
    8000469c:	03079693          	slli	a3,a5,0x30
    800046a0:	92c1                	srli	a3,a3,0x30
    800046a2:	4725                	li	a4,9
    800046a4:	02d76863          	bltu	a4,a3,800046d4 <fileread+0xba>
    800046a8:	0792                	slli	a5,a5,0x4
    800046aa:	0001c717          	auipc	a4,0x1c
    800046ae:	72e70713          	addi	a4,a4,1838 # 80020dd8 <devsw>
    800046b2:	97ba                	add	a5,a5,a4
    800046b4:	639c                	ld	a5,0(a5)
    800046b6:	c38d                	beqz	a5,800046d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046b8:	4505                	li	a0,1
    800046ba:	9782                	jalr	a5
    800046bc:	892a                	mv	s2,a0
    800046be:	bf75                	j	8000467a <fileread+0x60>
    panic("fileread");
    800046c0:	00004517          	auipc	a0,0x4
    800046c4:	ff850513          	addi	a0,a0,-8 # 800086b8 <syscalls+0x268>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	e78080e7          	jalr	-392(ra) # 80000540 <panic>
    return -1;
    800046d0:	597d                	li	s2,-1
    800046d2:	b765                	j	8000467a <fileread+0x60>
      return -1;
    800046d4:	597d                	li	s2,-1
    800046d6:	b755                	j	8000467a <fileread+0x60>
    800046d8:	597d                	li	s2,-1
    800046da:	b745                	j	8000467a <fileread+0x60>

00000000800046dc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046dc:	715d                	addi	sp,sp,-80
    800046de:	e486                	sd	ra,72(sp)
    800046e0:	e0a2                	sd	s0,64(sp)
    800046e2:	fc26                	sd	s1,56(sp)
    800046e4:	f84a                	sd	s2,48(sp)
    800046e6:	f44e                	sd	s3,40(sp)
    800046e8:	f052                	sd	s4,32(sp)
    800046ea:	ec56                	sd	s5,24(sp)
    800046ec:	e85a                	sd	s6,16(sp)
    800046ee:	e45e                	sd	s7,8(sp)
    800046f0:	e062                	sd	s8,0(sp)
    800046f2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046f4:	00954783          	lbu	a5,9(a0)
    800046f8:	10078663          	beqz	a5,80004804 <filewrite+0x128>
    800046fc:	892a                	mv	s2,a0
    800046fe:	8b2e                	mv	s6,a1
    80004700:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004702:	411c                	lw	a5,0(a0)
    80004704:	4705                	li	a4,1
    80004706:	02e78263          	beq	a5,a4,8000472a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470a:	470d                	li	a4,3
    8000470c:	02e78663          	beq	a5,a4,80004738 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004710:	4709                	li	a4,2
    80004712:	0ee79163          	bne	a5,a4,800047f4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004716:	0ac05d63          	blez	a2,800047d0 <filewrite+0xf4>
    int i = 0;
    8000471a:	4981                	li	s3,0
    8000471c:	6b85                	lui	s7,0x1
    8000471e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004722:	6c05                	lui	s8,0x1
    80004724:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004728:	a861                	j	800047c0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000472a:	6908                	ld	a0,16(a0)
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	22e080e7          	jalr	558(ra) # 8000495a <pipewrite>
    80004734:	8a2a                	mv	s4,a0
    80004736:	a045                	j	800047d6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004738:	02451783          	lh	a5,36(a0)
    8000473c:	03079693          	slli	a3,a5,0x30
    80004740:	92c1                	srli	a3,a3,0x30
    80004742:	4725                	li	a4,9
    80004744:	0cd76263          	bltu	a4,a3,80004808 <filewrite+0x12c>
    80004748:	0792                	slli	a5,a5,0x4
    8000474a:	0001c717          	auipc	a4,0x1c
    8000474e:	68e70713          	addi	a4,a4,1678 # 80020dd8 <devsw>
    80004752:	97ba                	add	a5,a5,a4
    80004754:	679c                	ld	a5,8(a5)
    80004756:	cbdd                	beqz	a5,8000480c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004758:	4505                	li	a0,1
    8000475a:	9782                	jalr	a5
    8000475c:	8a2a                	mv	s4,a0
    8000475e:	a8a5                	j	800047d6 <filewrite+0xfa>
    80004760:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004764:	00000097          	auipc	ra,0x0
    80004768:	8b4080e7          	jalr	-1868(ra) # 80004018 <begin_op>
      ilock(f->ip);
    8000476c:	01893503          	ld	a0,24(s2)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	edc080e7          	jalr	-292(ra) # 8000364c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004778:	8756                	mv	a4,s5
    8000477a:	02092683          	lw	a3,32(s2)
    8000477e:	01698633          	add	a2,s3,s6
    80004782:	4585                	li	a1,1
    80004784:	01893503          	ld	a0,24(s2)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	270080e7          	jalr	624(ra) # 800039f8 <writei>
    80004790:	84aa                	mv	s1,a0
    80004792:	00a05763          	blez	a0,800047a0 <filewrite+0xc4>
        f->off += r;
    80004796:	02092783          	lw	a5,32(s2)
    8000479a:	9fa9                	addw	a5,a5,a0
    8000479c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047a0:	01893503          	ld	a0,24(s2)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	f6a080e7          	jalr	-150(ra) # 8000370e <iunlock>
      end_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	8ea080e7          	jalr	-1814(ra) # 80004096 <end_op>

      if(r != n1){
    800047b4:	009a9f63          	bne	s5,s1,800047d2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047b8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047bc:	0149db63          	bge	s3,s4,800047d2 <filewrite+0xf6>
      int n1 = n - i;
    800047c0:	413a04bb          	subw	s1,s4,s3
    800047c4:	0004879b          	sext.w	a5,s1
    800047c8:	f8fbdce3          	bge	s7,a5,80004760 <filewrite+0x84>
    800047cc:	84e2                	mv	s1,s8
    800047ce:	bf49                	j	80004760 <filewrite+0x84>
    int i = 0;
    800047d0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047d2:	013a1f63          	bne	s4,s3,800047f0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047d6:	8552                	mv	a0,s4
    800047d8:	60a6                	ld	ra,72(sp)
    800047da:	6406                	ld	s0,64(sp)
    800047dc:	74e2                	ld	s1,56(sp)
    800047de:	7942                	ld	s2,48(sp)
    800047e0:	79a2                	ld	s3,40(sp)
    800047e2:	7a02                	ld	s4,32(sp)
    800047e4:	6ae2                	ld	s5,24(sp)
    800047e6:	6b42                	ld	s6,16(sp)
    800047e8:	6ba2                	ld	s7,8(sp)
    800047ea:	6c02                	ld	s8,0(sp)
    800047ec:	6161                	addi	sp,sp,80
    800047ee:	8082                	ret
    ret = (i == n ? n : -1);
    800047f0:	5a7d                	li	s4,-1
    800047f2:	b7d5                	j	800047d6 <filewrite+0xfa>
    panic("filewrite");
    800047f4:	00004517          	auipc	a0,0x4
    800047f8:	ed450513          	addi	a0,a0,-300 # 800086c8 <syscalls+0x278>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	d44080e7          	jalr	-700(ra) # 80000540 <panic>
    return -1;
    80004804:	5a7d                	li	s4,-1
    80004806:	bfc1                	j	800047d6 <filewrite+0xfa>
      return -1;
    80004808:	5a7d                	li	s4,-1
    8000480a:	b7f1                	j	800047d6 <filewrite+0xfa>
    8000480c:	5a7d                	li	s4,-1
    8000480e:	b7e1                	j	800047d6 <filewrite+0xfa>

0000000080004810 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004810:	7179                	addi	sp,sp,-48
    80004812:	f406                	sd	ra,40(sp)
    80004814:	f022                	sd	s0,32(sp)
    80004816:	ec26                	sd	s1,24(sp)
    80004818:	e84a                	sd	s2,16(sp)
    8000481a:	e44e                	sd	s3,8(sp)
    8000481c:	e052                	sd	s4,0(sp)
    8000481e:	1800                	addi	s0,sp,48
    80004820:	84aa                	mv	s1,a0
    80004822:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004824:	0005b023          	sd	zero,0(a1)
    80004828:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	bf8080e7          	jalr	-1032(ra) # 80004424 <filealloc>
    80004834:	e088                	sd	a0,0(s1)
    80004836:	c551                	beqz	a0,800048c2 <pipealloc+0xb2>
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	bec080e7          	jalr	-1044(ra) # 80004424 <filealloc>
    80004840:	00aa3023          	sd	a0,0(s4)
    80004844:	c92d                	beqz	a0,800048b6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	2a0080e7          	jalr	672(ra) # 80000ae6 <kalloc>
    8000484e:	892a                	mv	s2,a0
    80004850:	c125                	beqz	a0,800048b0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004852:	4985                	li	s3,1
    80004854:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004858:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000485c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004860:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004864:	00004597          	auipc	a1,0x4
    80004868:	e7458593          	addi	a1,a1,-396 # 800086d8 <syscalls+0x288>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	2da080e7          	jalr	730(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004874:	609c                	ld	a5,0(s1)
    80004876:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000487a:	609c                	ld	a5,0(s1)
    8000487c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004880:	609c                	ld	a5,0(s1)
    80004882:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004886:	609c                	ld	a5,0(s1)
    80004888:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000488c:	000a3783          	ld	a5,0(s4)
    80004890:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004894:	000a3783          	ld	a5,0(s4)
    80004898:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000489c:	000a3783          	ld	a5,0(s4)
    800048a0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	0127b823          	sd	s2,16(a5)
  return 0;
    800048ac:	4501                	li	a0,0
    800048ae:	a025                	j	800048d6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048b0:	6088                	ld	a0,0(s1)
    800048b2:	e501                	bnez	a0,800048ba <pipealloc+0xaa>
    800048b4:	a039                	j	800048c2 <pipealloc+0xb2>
    800048b6:	6088                	ld	a0,0(s1)
    800048b8:	c51d                	beqz	a0,800048e6 <pipealloc+0xd6>
    fileclose(*f0);
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	c26080e7          	jalr	-986(ra) # 800044e0 <fileclose>
  if(*f1)
    800048c2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048c6:	557d                	li	a0,-1
  if(*f1)
    800048c8:	c799                	beqz	a5,800048d6 <pipealloc+0xc6>
    fileclose(*f1);
    800048ca:	853e                	mv	a0,a5
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	c14080e7          	jalr	-1004(ra) # 800044e0 <fileclose>
  return -1;
    800048d4:	557d                	li	a0,-1
}
    800048d6:	70a2                	ld	ra,40(sp)
    800048d8:	7402                	ld	s0,32(sp)
    800048da:	64e2                	ld	s1,24(sp)
    800048dc:	6942                	ld	s2,16(sp)
    800048de:	69a2                	ld	s3,8(sp)
    800048e0:	6a02                	ld	s4,0(sp)
    800048e2:	6145                	addi	sp,sp,48
    800048e4:	8082                	ret
  return -1;
    800048e6:	557d                	li	a0,-1
    800048e8:	b7fd                	j	800048d6 <pipealloc+0xc6>

00000000800048ea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048ea:	1101                	addi	sp,sp,-32
    800048ec:	ec06                	sd	ra,24(sp)
    800048ee:	e822                	sd	s0,16(sp)
    800048f0:	e426                	sd	s1,8(sp)
    800048f2:	e04a                	sd	s2,0(sp)
    800048f4:	1000                	addi	s0,sp,32
    800048f6:	84aa                	mv	s1,a0
    800048f8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	2dc080e7          	jalr	732(ra) # 80000bd6 <acquire>
  if(writable){
    80004902:	02090d63          	beqz	s2,8000493c <pipeclose+0x52>
    pi->writeopen = 0;
    80004906:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000490a:	21848513          	addi	a0,s1,536
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	7aa080e7          	jalr	1962(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004916:	2204b783          	ld	a5,544(s1)
    8000491a:	eb95                	bnez	a5,8000494e <pipeclose+0x64>
    release(&pi->lock);
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	36c080e7          	jalr	876(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004926:	8526                	mv	a0,s1
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	0c0080e7          	jalr	192(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6902                	ld	s2,0(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret
    pi->readopen = 0;
    8000493c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004940:	21c48513          	addi	a0,s1,540
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	774080e7          	jalr	1908(ra) # 800020b8 <wakeup>
    8000494c:	b7e9                	j	80004916 <pipeclose+0x2c>
    release(&pi->lock);
    8000494e:	8526                	mv	a0,s1
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	33a080e7          	jalr	826(ra) # 80000c8a <release>
}
    80004958:	bfe1                	j	80004930 <pipeclose+0x46>

000000008000495a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000495a:	711d                	addi	sp,sp,-96
    8000495c:	ec86                	sd	ra,88(sp)
    8000495e:	e8a2                	sd	s0,80(sp)
    80004960:	e4a6                	sd	s1,72(sp)
    80004962:	e0ca                	sd	s2,64(sp)
    80004964:	fc4e                	sd	s3,56(sp)
    80004966:	f852                	sd	s4,48(sp)
    80004968:	f456                	sd	s5,40(sp)
    8000496a:	f05a                	sd	s6,32(sp)
    8000496c:	ec5e                	sd	s7,24(sp)
    8000496e:	e862                	sd	s8,16(sp)
    80004970:	1080                	addi	s0,sp,96
    80004972:	84aa                	mv	s1,a0
    80004974:	8aae                	mv	s5,a1
    80004976:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004978:	ffffd097          	auipc	ra,0xffffd
    8000497c:	034080e7          	jalr	52(ra) # 800019ac <myproc>
    80004980:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	252080e7          	jalr	594(ra) # 80000bd6 <acquire>
  while(i < n){
    8000498c:	0b405663          	blez	s4,80004a38 <pipewrite+0xde>
  int i = 0;
    80004990:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004992:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004994:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004998:	21c48b93          	addi	s7,s1,540
    8000499c:	a089                	j	800049de <pipewrite+0x84>
      release(&pi->lock);
    8000499e:	8526                	mv	a0,s1
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2ea080e7          	jalr	746(ra) # 80000c8a <release>
      return -1;
    800049a8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049aa:	854a                	mv	a0,s2
    800049ac:	60e6                	ld	ra,88(sp)
    800049ae:	6446                	ld	s0,80(sp)
    800049b0:	64a6                	ld	s1,72(sp)
    800049b2:	6906                	ld	s2,64(sp)
    800049b4:	79e2                	ld	s3,56(sp)
    800049b6:	7a42                	ld	s4,48(sp)
    800049b8:	7aa2                	ld	s5,40(sp)
    800049ba:	7b02                	ld	s6,32(sp)
    800049bc:	6be2                	ld	s7,24(sp)
    800049be:	6c42                	ld	s8,16(sp)
    800049c0:	6125                	addi	sp,sp,96
    800049c2:	8082                	ret
      wakeup(&pi->nread);
    800049c4:	8562                	mv	a0,s8
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	6f2080e7          	jalr	1778(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049ce:	85a6                	mv	a1,s1
    800049d0:	855e                	mv	a0,s7
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	682080e7          	jalr	1666(ra) # 80002054 <sleep>
  while(i < n){
    800049da:	07495063          	bge	s2,s4,80004a3a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800049de:	2204a783          	lw	a5,544(s1)
    800049e2:	dfd5                	beqz	a5,8000499e <pipewrite+0x44>
    800049e4:	854e                	mv	a0,s3
    800049e6:	ffffe097          	auipc	ra,0xffffe
    800049ea:	916080e7          	jalr	-1770(ra) # 800022fc <killed>
    800049ee:	f945                	bnez	a0,8000499e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049f0:	2184a783          	lw	a5,536(s1)
    800049f4:	21c4a703          	lw	a4,540(s1)
    800049f8:	2007879b          	addiw	a5,a5,512
    800049fc:	fcf704e3          	beq	a4,a5,800049c4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a00:	4685                	li	a3,1
    80004a02:	01590633          	add	a2,s2,s5
    80004a06:	faf40593          	addi	a1,s0,-81
    80004a0a:	0589b503          	ld	a0,88(s3)
    80004a0e:	ffffd097          	auipc	ra,0xffffd
    80004a12:	cea080e7          	jalr	-790(ra) # 800016f8 <copyin>
    80004a16:	03650263          	beq	a0,s6,80004a3a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a1a:	21c4a783          	lw	a5,540(s1)
    80004a1e:	0017871b          	addiw	a4,a5,1
    80004a22:	20e4ae23          	sw	a4,540(s1)
    80004a26:	1ff7f793          	andi	a5,a5,511
    80004a2a:	97a6                	add	a5,a5,s1
    80004a2c:	faf44703          	lbu	a4,-81(s0)
    80004a30:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a34:	2905                	addiw	s2,s2,1
    80004a36:	b755                	j	800049da <pipewrite+0x80>
  int i = 0;
    80004a38:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a3a:	21848513          	addi	a0,s1,536
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	67a080e7          	jalr	1658(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	242080e7          	jalr	578(ra) # 80000c8a <release>
  return i;
    80004a50:	bfa9                	j	800049aa <pipewrite+0x50>

0000000080004a52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a52:	715d                	addi	sp,sp,-80
    80004a54:	e486                	sd	ra,72(sp)
    80004a56:	e0a2                	sd	s0,64(sp)
    80004a58:	fc26                	sd	s1,56(sp)
    80004a5a:	f84a                	sd	s2,48(sp)
    80004a5c:	f44e                	sd	s3,40(sp)
    80004a5e:	f052                	sd	s4,32(sp)
    80004a60:	ec56                	sd	s5,24(sp)
    80004a62:	e85a                	sd	s6,16(sp)
    80004a64:	0880                	addi	s0,sp,80
    80004a66:	84aa                	mv	s1,a0
    80004a68:	892e                	mv	s2,a1
    80004a6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	f40080e7          	jalr	-192(ra) # 800019ac <myproc>
    80004a74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	15e080e7          	jalr	350(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a80:	2184a703          	lw	a4,536(s1)
    80004a84:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a88:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8c:	02f71763          	bne	a4,a5,80004aba <piperead+0x68>
    80004a90:	2244a783          	lw	a5,548(s1)
    80004a94:	c39d                	beqz	a5,80004aba <piperead+0x68>
    if(killed(pr)){
    80004a96:	8552                	mv	a0,s4
    80004a98:	ffffe097          	auipc	ra,0xffffe
    80004a9c:	864080e7          	jalr	-1948(ra) # 800022fc <killed>
    80004aa0:	e949                	bnez	a0,80004b32 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa2:	85a6                	mv	a1,s1
    80004aa4:	854e                	mv	a0,s3
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	5ae080e7          	jalr	1454(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aae:	2184a703          	lw	a4,536(s1)
    80004ab2:	21c4a783          	lw	a5,540(s1)
    80004ab6:	fcf70de3          	beq	a4,a5,80004a90 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004abc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004abe:	05505463          	blez	s5,80004b06 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ac2:	2184a783          	lw	a5,536(s1)
    80004ac6:	21c4a703          	lw	a4,540(s1)
    80004aca:	02f70e63          	beq	a4,a5,80004b06 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ace:	0017871b          	addiw	a4,a5,1
    80004ad2:	20e4ac23          	sw	a4,536(s1)
    80004ad6:	1ff7f793          	andi	a5,a5,511
    80004ada:	97a6                	add	a5,a5,s1
    80004adc:	0187c783          	lbu	a5,24(a5)
    80004ae0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae4:	4685                	li	a3,1
    80004ae6:	fbf40613          	addi	a2,s0,-65
    80004aea:	85ca                	mv	a1,s2
    80004aec:	058a3503          	ld	a0,88(s4)
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	b7c080e7          	jalr	-1156(ra) # 8000166c <copyout>
    80004af8:	01650763          	beq	a0,s6,80004b06 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004afc:	2985                	addiw	s3,s3,1
    80004afe:	0905                	addi	s2,s2,1
    80004b00:	fd3a91e3          	bne	s5,s3,80004ac2 <piperead+0x70>
    80004b04:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b06:	21c48513          	addi	a0,s1,540
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	5ae080e7          	jalr	1454(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	176080e7          	jalr	374(ra) # 80000c8a <release>
  return i;
}
    80004b1c:	854e                	mv	a0,s3
    80004b1e:	60a6                	ld	ra,72(sp)
    80004b20:	6406                	ld	s0,64(sp)
    80004b22:	74e2                	ld	s1,56(sp)
    80004b24:	7942                	ld	s2,48(sp)
    80004b26:	79a2                	ld	s3,40(sp)
    80004b28:	7a02                	ld	s4,32(sp)
    80004b2a:	6ae2                	ld	s5,24(sp)
    80004b2c:	6b42                	ld	s6,16(sp)
    80004b2e:	6161                	addi	sp,sp,80
    80004b30:	8082                	ret
      release(&pi->lock);
    80004b32:	8526                	mv	a0,s1
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	156080e7          	jalr	342(ra) # 80000c8a <release>
      return -1;
    80004b3c:	59fd                	li	s3,-1
    80004b3e:	bff9                	j	80004b1c <piperead+0xca>

0000000080004b40 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b40:	1141                	addi	sp,sp,-16
    80004b42:	e422                	sd	s0,8(sp)
    80004b44:	0800                	addi	s0,sp,16
    80004b46:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b48:	8905                	andi	a0,a0,1
    80004b4a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b4c:	8b89                	andi	a5,a5,2
    80004b4e:	c399                	beqz	a5,80004b54 <flags2perm+0x14>
      perm |= PTE_W;
    80004b50:	00456513          	ori	a0,a0,4
    return perm;
}
    80004b54:	6422                	ld	s0,8(sp)
    80004b56:	0141                	addi	sp,sp,16
    80004b58:	8082                	ret

0000000080004b5a <exec>:

int
exec(char *path, char **argv)
{
    80004b5a:	de010113          	addi	sp,sp,-544
    80004b5e:	20113c23          	sd	ra,536(sp)
    80004b62:	20813823          	sd	s0,528(sp)
    80004b66:	20913423          	sd	s1,520(sp)
    80004b6a:	21213023          	sd	s2,512(sp)
    80004b6e:	ffce                	sd	s3,504(sp)
    80004b70:	fbd2                	sd	s4,496(sp)
    80004b72:	f7d6                	sd	s5,488(sp)
    80004b74:	f3da                	sd	s6,480(sp)
    80004b76:	efde                	sd	s7,472(sp)
    80004b78:	ebe2                	sd	s8,464(sp)
    80004b7a:	e7e6                	sd	s9,456(sp)
    80004b7c:	e3ea                	sd	s10,448(sp)
    80004b7e:	ff6e                	sd	s11,440(sp)
    80004b80:	1400                	addi	s0,sp,544
    80004b82:	892a                	mv	s2,a0
    80004b84:	dea43423          	sd	a0,-536(s0)
    80004b88:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	e20080e7          	jalr	-480(ra) # 800019ac <myproc>
    80004b94:	84aa                	mv	s1,a0

  begin_op();
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	482080e7          	jalr	1154(ra) # 80004018 <begin_op>

  if((ip = namei(path)) == 0){
    80004b9e:	854a                	mv	a0,s2
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	258080e7          	jalr	600(ra) # 80003df8 <namei>
    80004ba8:	c93d                	beqz	a0,80004c1e <exec+0xc4>
    80004baa:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	aa0080e7          	jalr	-1376(ra) # 8000364c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bb4:	04000713          	li	a4,64
    80004bb8:	4681                	li	a3,0
    80004bba:	e5040613          	addi	a2,s0,-432
    80004bbe:	4581                	li	a1,0
    80004bc0:	8556                	mv	a0,s5
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	d3e080e7          	jalr	-706(ra) # 80003900 <readi>
    80004bca:	04000793          	li	a5,64
    80004bce:	00f51a63          	bne	a0,a5,80004be2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004bd2:	e5042703          	lw	a4,-432(s0)
    80004bd6:	464c47b7          	lui	a5,0x464c4
    80004bda:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bde:	04f70663          	beq	a4,a5,80004c2a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004be2:	8556                	mv	a0,s5
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	cca080e7          	jalr	-822(ra) # 800038ae <iunlockput>
    end_op();
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	4aa080e7          	jalr	1194(ra) # 80004096 <end_op>
  }
  return -1;
    80004bf4:	557d                	li	a0,-1
}
    80004bf6:	21813083          	ld	ra,536(sp)
    80004bfa:	21013403          	ld	s0,528(sp)
    80004bfe:	20813483          	ld	s1,520(sp)
    80004c02:	20013903          	ld	s2,512(sp)
    80004c06:	79fe                	ld	s3,504(sp)
    80004c08:	7a5e                	ld	s4,496(sp)
    80004c0a:	7abe                	ld	s5,488(sp)
    80004c0c:	7b1e                	ld	s6,480(sp)
    80004c0e:	6bfe                	ld	s7,472(sp)
    80004c10:	6c5e                	ld	s8,464(sp)
    80004c12:	6cbe                	ld	s9,456(sp)
    80004c14:	6d1e                	ld	s10,448(sp)
    80004c16:	7dfa                	ld	s11,440(sp)
    80004c18:	22010113          	addi	sp,sp,544
    80004c1c:	8082                	ret
    end_op();
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	478080e7          	jalr	1144(ra) # 80004096 <end_op>
    return -1;
    80004c26:	557d                	li	a0,-1
    80004c28:	b7f9                	j	80004bf6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	e44080e7          	jalr	-444(ra) # 80001a70 <proc_pagetable>
    80004c34:	8b2a                	mv	s6,a0
    80004c36:	d555                	beqz	a0,80004be2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c38:	e7042783          	lw	a5,-400(s0)
    80004c3c:	e8845703          	lhu	a4,-376(s0)
    80004c40:	c735                	beqz	a4,80004cac <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c42:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c44:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c48:	6a05                	lui	s4,0x1
    80004c4a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c4e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004c52:	6d85                	lui	s11,0x1
    80004c54:	7d7d                	lui	s10,0xfffff
    80004c56:	ac3d                	j	80004e94 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c58:	00004517          	auipc	a0,0x4
    80004c5c:	a8850513          	addi	a0,a0,-1400 # 800086e0 <syscalls+0x290>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	8e0080e7          	jalr	-1824(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c68:	874a                	mv	a4,s2
    80004c6a:	009c86bb          	addw	a3,s9,s1
    80004c6e:	4581                	li	a1,0
    80004c70:	8556                	mv	a0,s5
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	c8e080e7          	jalr	-882(ra) # 80003900 <readi>
    80004c7a:	2501                	sext.w	a0,a0
    80004c7c:	1aa91963          	bne	s2,a0,80004e2e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004c80:	009d84bb          	addw	s1,s11,s1
    80004c84:	013d09bb          	addw	s3,s10,s3
    80004c88:	1f74f663          	bgeu	s1,s7,80004e74 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004c8c:	02049593          	slli	a1,s1,0x20
    80004c90:	9181                	srli	a1,a1,0x20
    80004c92:	95e2                	add	a1,a1,s8
    80004c94:	855a                	mv	a0,s6
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	3c6080e7          	jalr	966(ra) # 8000105c <walkaddr>
    80004c9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004ca0:	dd45                	beqz	a0,80004c58 <exec+0xfe>
      n = PGSIZE;
    80004ca2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ca4:	fd49f2e3          	bgeu	s3,s4,80004c68 <exec+0x10e>
      n = sz - i;
    80004ca8:	894e                	mv	s2,s3
    80004caa:	bf7d                	j	80004c68 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cac:	4901                	li	s2,0
  iunlockput(ip);
    80004cae:	8556                	mv	a0,s5
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	bfe080e7          	jalr	-1026(ra) # 800038ae <iunlockput>
  end_op();
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	3de080e7          	jalr	990(ra) # 80004096 <end_op>
  p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	cec080e7          	jalr	-788(ra) # 800019ac <myproc>
    80004cc8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cce:	6785                	lui	a5,0x1
    80004cd0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004cd2:	97ca                	add	a5,a5,s2
    80004cd4:	777d                	lui	a4,0xfffff
    80004cd6:	8ff9                	and	a5,a5,a4
    80004cd8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cdc:	4691                	li	a3,4
    80004cde:	6609                	lui	a2,0x2
    80004ce0:	963e                	add	a2,a2,a5
    80004ce2:	85be                	mv	a1,a5
    80004ce4:	855a                	mv	a0,s6
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	72a080e7          	jalr	1834(ra) # 80001410 <uvmalloc>
    80004cee:	8c2a                	mv	s8,a0
  ip = 0;
    80004cf0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cf2:	12050e63          	beqz	a0,80004e2e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cf6:	75f9                	lui	a1,0xffffe
    80004cf8:	95aa                	add	a1,a1,a0
    80004cfa:	855a                	mv	a0,s6
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	93e080e7          	jalr	-1730(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d04:	7afd                	lui	s5,0xfffff
    80004d06:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d08:	df043783          	ld	a5,-528(s0)
    80004d0c:	6388                	ld	a0,0(a5)
    80004d0e:	c925                	beqz	a0,80004d7e <exec+0x224>
    80004d10:	e9040993          	addi	s3,s0,-368
    80004d14:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d18:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d1a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	132080e7          	jalr	306(ra) # 80000e4e <strlen>
    80004d24:	0015079b          	addiw	a5,a0,1
    80004d28:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d2c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d30:	13596663          	bltu	s2,s5,80004e5c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d34:	df043d83          	ld	s11,-528(s0)
    80004d38:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d3c:	8552                	mv	a0,s4
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	110080e7          	jalr	272(ra) # 80000e4e <strlen>
    80004d46:	0015069b          	addiw	a3,a0,1
    80004d4a:	8652                	mv	a2,s4
    80004d4c:	85ca                	mv	a1,s2
    80004d4e:	855a                	mv	a0,s6
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	91c080e7          	jalr	-1764(ra) # 8000166c <copyout>
    80004d58:	10054663          	bltz	a0,80004e64 <exec+0x30a>
    ustack[argc] = sp;
    80004d5c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d60:	0485                	addi	s1,s1,1
    80004d62:	008d8793          	addi	a5,s11,8
    80004d66:	def43823          	sd	a5,-528(s0)
    80004d6a:	008db503          	ld	a0,8(s11)
    80004d6e:	c911                	beqz	a0,80004d82 <exec+0x228>
    if(argc >= MAXARG)
    80004d70:	09a1                	addi	s3,s3,8
    80004d72:	fb3c95e3          	bne	s9,s3,80004d1c <exec+0x1c2>
  sz = sz1;
    80004d76:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d7a:	4a81                	li	s5,0
    80004d7c:	a84d                	j	80004e2e <exec+0x2d4>
  sp = sz;
    80004d7e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d80:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d82:	00349793          	slli	a5,s1,0x3
    80004d86:	f9078793          	addi	a5,a5,-112
    80004d8a:	97a2                	add	a5,a5,s0
    80004d8c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d90:	00148693          	addi	a3,s1,1
    80004d94:	068e                	slli	a3,a3,0x3
    80004d96:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d9a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d9e:	01597663          	bgeu	s2,s5,80004daa <exec+0x250>
  sz = sz1;
    80004da2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004da6:	4a81                	li	s5,0
    80004da8:	a059                	j	80004e2e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004daa:	e9040613          	addi	a2,s0,-368
    80004dae:	85ca                	mv	a1,s2
    80004db0:	855a                	mv	a0,s6
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	8ba080e7          	jalr	-1862(ra) # 8000166c <copyout>
    80004dba:	0a054963          	bltz	a0,80004e6c <exec+0x312>
  p->trapframe->a1 = sp;
    80004dbe:	060bb783          	ld	a5,96(s7)
    80004dc2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dc6:	de843783          	ld	a5,-536(s0)
    80004dca:	0007c703          	lbu	a4,0(a5)
    80004dce:	cf11                	beqz	a4,80004dea <exec+0x290>
    80004dd0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dd2:	02f00693          	li	a3,47
    80004dd6:	a039                	j	80004de4 <exec+0x28a>
      last = s+1;
    80004dd8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ddc:	0785                	addi	a5,a5,1
    80004dde:	fff7c703          	lbu	a4,-1(a5)
    80004de2:	c701                	beqz	a4,80004dea <exec+0x290>
    if(*s == '/')
    80004de4:	fed71ce3          	bne	a4,a3,80004ddc <exec+0x282>
    80004de8:	bfc5                	j	80004dd8 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dea:	4641                	li	a2,16
    80004dec:	de843583          	ld	a1,-536(s0)
    80004df0:	160b8513          	addi	a0,s7,352
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	028080e7          	jalr	40(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004dfc:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80004e00:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80004e04:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e08:	060bb783          	ld	a5,96(s7)
    80004e0c:	e6843703          	ld	a4,-408(s0)
    80004e10:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e12:	060bb783          	ld	a5,96(s7)
    80004e16:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e1a:	85ea                	mv	a1,s10
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	cf0080e7          	jalr	-784(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e24:	0004851b          	sext.w	a0,s1
    80004e28:	b3f9                	j	80004bf6 <exec+0x9c>
    80004e2a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e2e:	df843583          	ld	a1,-520(s0)
    80004e32:	855a                	mv	a0,s6
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	cd8080e7          	jalr	-808(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004e3c:	da0a93e3          	bnez	s5,80004be2 <exec+0x88>
  return -1;
    80004e40:	557d                	li	a0,-1
    80004e42:	bb55                	j	80004bf6 <exec+0x9c>
    80004e44:	df243c23          	sd	s2,-520(s0)
    80004e48:	b7dd                	j	80004e2e <exec+0x2d4>
    80004e4a:	df243c23          	sd	s2,-520(s0)
    80004e4e:	b7c5                	j	80004e2e <exec+0x2d4>
    80004e50:	df243c23          	sd	s2,-520(s0)
    80004e54:	bfe9                	j	80004e2e <exec+0x2d4>
    80004e56:	df243c23          	sd	s2,-520(s0)
    80004e5a:	bfd1                	j	80004e2e <exec+0x2d4>
  sz = sz1;
    80004e5c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e60:	4a81                	li	s5,0
    80004e62:	b7f1                	j	80004e2e <exec+0x2d4>
  sz = sz1;
    80004e64:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e68:	4a81                	li	s5,0
    80004e6a:	b7d1                	j	80004e2e <exec+0x2d4>
  sz = sz1;
    80004e6c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e70:	4a81                	li	s5,0
    80004e72:	bf75                	j	80004e2e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e74:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e78:	e0843783          	ld	a5,-504(s0)
    80004e7c:	0017869b          	addiw	a3,a5,1
    80004e80:	e0d43423          	sd	a3,-504(s0)
    80004e84:	e0043783          	ld	a5,-512(s0)
    80004e88:	0387879b          	addiw	a5,a5,56
    80004e8c:	e8845703          	lhu	a4,-376(s0)
    80004e90:	e0e6dfe3          	bge	a3,a4,80004cae <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e94:	2781                	sext.w	a5,a5
    80004e96:	e0f43023          	sd	a5,-512(s0)
    80004e9a:	03800713          	li	a4,56
    80004e9e:	86be                	mv	a3,a5
    80004ea0:	e1840613          	addi	a2,s0,-488
    80004ea4:	4581                	li	a1,0
    80004ea6:	8556                	mv	a0,s5
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	a58080e7          	jalr	-1448(ra) # 80003900 <readi>
    80004eb0:	03800793          	li	a5,56
    80004eb4:	f6f51be3          	bne	a0,a5,80004e2a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004eb8:	e1842783          	lw	a5,-488(s0)
    80004ebc:	4705                	li	a4,1
    80004ebe:	fae79de3          	bne	a5,a4,80004e78 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004ec2:	e4043483          	ld	s1,-448(s0)
    80004ec6:	e3843783          	ld	a5,-456(s0)
    80004eca:	f6f4ede3          	bltu	s1,a5,80004e44 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ece:	e2843783          	ld	a5,-472(s0)
    80004ed2:	94be                	add	s1,s1,a5
    80004ed4:	f6f4ebe3          	bltu	s1,a5,80004e4a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004ed8:	de043703          	ld	a4,-544(s0)
    80004edc:	8ff9                	and	a5,a5,a4
    80004ede:	fbad                	bnez	a5,80004e50 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ee0:	e1c42503          	lw	a0,-484(s0)
    80004ee4:	00000097          	auipc	ra,0x0
    80004ee8:	c5c080e7          	jalr	-932(ra) # 80004b40 <flags2perm>
    80004eec:	86aa                	mv	a3,a0
    80004eee:	8626                	mv	a2,s1
    80004ef0:	85ca                	mv	a1,s2
    80004ef2:	855a                	mv	a0,s6
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	51c080e7          	jalr	1308(ra) # 80001410 <uvmalloc>
    80004efc:	dea43c23          	sd	a0,-520(s0)
    80004f00:	d939                	beqz	a0,80004e56 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f02:	e2843c03          	ld	s8,-472(s0)
    80004f06:	e2042c83          	lw	s9,-480(s0)
    80004f0a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f0e:	f60b83e3          	beqz	s7,80004e74 <exec+0x31a>
    80004f12:	89de                	mv	s3,s7
    80004f14:	4481                	li	s1,0
    80004f16:	bb9d                	j	80004c8c <exec+0x132>

0000000080004f18 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f18:	7179                	addi	sp,sp,-48
    80004f1a:	f406                	sd	ra,40(sp)
    80004f1c:	f022                	sd	s0,32(sp)
    80004f1e:	ec26                	sd	s1,24(sp)
    80004f20:	e84a                	sd	s2,16(sp)
    80004f22:	1800                	addi	s0,sp,48
    80004f24:	892e                	mv	s2,a1
    80004f26:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f28:	fdc40593          	addi	a1,s0,-36
    80004f2c:	ffffe097          	auipc	ra,0xffffe
    80004f30:	b96080e7          	jalr	-1130(ra) # 80002ac2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f34:	fdc42703          	lw	a4,-36(s0)
    80004f38:	47bd                	li	a5,15
    80004f3a:	02e7eb63          	bltu	a5,a4,80004f70 <argfd+0x58>
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	a6e080e7          	jalr	-1426(ra) # 800019ac <myproc>
    80004f46:	fdc42703          	lw	a4,-36(s0)
    80004f4a:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd0aa>
    80004f4e:	078e                	slli	a5,a5,0x3
    80004f50:	953e                	add	a0,a0,a5
    80004f52:	651c                	ld	a5,8(a0)
    80004f54:	c385                	beqz	a5,80004f74 <argfd+0x5c>
    return -1;
  if(pfd)
    80004f56:	00090463          	beqz	s2,80004f5e <argfd+0x46>
    *pfd = fd;
    80004f5a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f5e:	4501                	li	a0,0
  if(pf)
    80004f60:	c091                	beqz	s1,80004f64 <argfd+0x4c>
    *pf = f;
    80004f62:	e09c                	sd	a5,0(s1)
}
    80004f64:	70a2                	ld	ra,40(sp)
    80004f66:	7402                	ld	s0,32(sp)
    80004f68:	64e2                	ld	s1,24(sp)
    80004f6a:	6942                	ld	s2,16(sp)
    80004f6c:	6145                	addi	sp,sp,48
    80004f6e:	8082                	ret
    return -1;
    80004f70:	557d                	li	a0,-1
    80004f72:	bfcd                	j	80004f64 <argfd+0x4c>
    80004f74:	557d                	li	a0,-1
    80004f76:	b7fd                	j	80004f64 <argfd+0x4c>

0000000080004f78 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f78:	1101                	addi	sp,sp,-32
    80004f7a:	ec06                	sd	ra,24(sp)
    80004f7c:	e822                	sd	s0,16(sp)
    80004f7e:	e426                	sd	s1,8(sp)
    80004f80:	1000                	addi	s0,sp,32
    80004f82:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f84:	ffffd097          	auipc	ra,0xffffd
    80004f88:	a28080e7          	jalr	-1496(ra) # 800019ac <myproc>
    80004f8c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f8e:	0d850793          	addi	a5,a0,216
    80004f92:	4501                	li	a0,0
    80004f94:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f96:	6398                	ld	a4,0(a5)
    80004f98:	cb19                	beqz	a4,80004fae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f9a:	2505                	addiw	a0,a0,1
    80004f9c:	07a1                	addi	a5,a5,8
    80004f9e:	fed51ce3          	bne	a0,a3,80004f96 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fa2:	557d                	li	a0,-1
}
    80004fa4:	60e2                	ld	ra,24(sp)
    80004fa6:	6442                	ld	s0,16(sp)
    80004fa8:	64a2                	ld	s1,8(sp)
    80004faa:	6105                	addi	sp,sp,32
    80004fac:	8082                	ret
      p->ofile[fd] = f;
    80004fae:	01a50793          	addi	a5,a0,26
    80004fb2:	078e                	slli	a5,a5,0x3
    80004fb4:	963e                	add	a2,a2,a5
    80004fb6:	e604                	sd	s1,8(a2)
      return fd;
    80004fb8:	b7f5                	j	80004fa4 <fdalloc+0x2c>

0000000080004fba <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fba:	715d                	addi	sp,sp,-80
    80004fbc:	e486                	sd	ra,72(sp)
    80004fbe:	e0a2                	sd	s0,64(sp)
    80004fc0:	fc26                	sd	s1,56(sp)
    80004fc2:	f84a                	sd	s2,48(sp)
    80004fc4:	f44e                	sd	s3,40(sp)
    80004fc6:	f052                	sd	s4,32(sp)
    80004fc8:	ec56                	sd	s5,24(sp)
    80004fca:	e85a                	sd	s6,16(sp)
    80004fcc:	0880                	addi	s0,sp,80
    80004fce:	8b2e                	mv	s6,a1
    80004fd0:	89b2                	mv	s3,a2
    80004fd2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fd4:	fb040593          	addi	a1,s0,-80
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	e3e080e7          	jalr	-450(ra) # 80003e16 <nameiparent>
    80004fe0:	84aa                	mv	s1,a0
    80004fe2:	14050f63          	beqz	a0,80005140 <create+0x186>
    return 0;

  ilock(dp);
    80004fe6:	ffffe097          	auipc	ra,0xffffe
    80004fea:	666080e7          	jalr	1638(ra) # 8000364c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fee:	4601                	li	a2,0
    80004ff0:	fb040593          	addi	a1,s0,-80
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	b3a080e7          	jalr	-1222(ra) # 80003b30 <dirlookup>
    80004ffe:	8aaa                	mv	s5,a0
    80005000:	c931                	beqz	a0,80005054 <create+0x9a>
    iunlockput(dp);
    80005002:	8526                	mv	a0,s1
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	8aa080e7          	jalr	-1878(ra) # 800038ae <iunlockput>
    ilock(ip);
    8000500c:	8556                	mv	a0,s5
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	63e080e7          	jalr	1598(ra) # 8000364c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005016:	000b059b          	sext.w	a1,s6
    8000501a:	4789                	li	a5,2
    8000501c:	02f59563          	bne	a1,a5,80005046 <create+0x8c>
    80005020:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0d4>
    80005024:	37f9                	addiw	a5,a5,-2
    80005026:	17c2                	slli	a5,a5,0x30
    80005028:	93c1                	srli	a5,a5,0x30
    8000502a:	4705                	li	a4,1
    8000502c:	00f76d63          	bltu	a4,a5,80005046 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005030:	8556                	mv	a0,s5
    80005032:	60a6                	ld	ra,72(sp)
    80005034:	6406                	ld	s0,64(sp)
    80005036:	74e2                	ld	s1,56(sp)
    80005038:	7942                	ld	s2,48(sp)
    8000503a:	79a2                	ld	s3,40(sp)
    8000503c:	7a02                	ld	s4,32(sp)
    8000503e:	6ae2                	ld	s5,24(sp)
    80005040:	6b42                	ld	s6,16(sp)
    80005042:	6161                	addi	sp,sp,80
    80005044:	8082                	ret
    iunlockput(ip);
    80005046:	8556                	mv	a0,s5
    80005048:	fffff097          	auipc	ra,0xfffff
    8000504c:	866080e7          	jalr	-1946(ra) # 800038ae <iunlockput>
    return 0;
    80005050:	4a81                	li	s5,0
    80005052:	bff9                	j	80005030 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005054:	85da                	mv	a1,s6
    80005056:	4088                	lw	a0,0(s1)
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	456080e7          	jalr	1110(ra) # 800034ae <ialloc>
    80005060:	8a2a                	mv	s4,a0
    80005062:	c539                	beqz	a0,800050b0 <create+0xf6>
  ilock(ip);
    80005064:	ffffe097          	auipc	ra,0xffffe
    80005068:	5e8080e7          	jalr	1512(ra) # 8000364c <ilock>
  ip->major = major;
    8000506c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005070:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005074:	4905                	li	s2,1
    80005076:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000507a:	8552                	mv	a0,s4
    8000507c:	ffffe097          	auipc	ra,0xffffe
    80005080:	504080e7          	jalr	1284(ra) # 80003580 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005084:	000b059b          	sext.w	a1,s6
    80005088:	03258b63          	beq	a1,s2,800050be <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000508c:	004a2603          	lw	a2,4(s4)
    80005090:	fb040593          	addi	a1,s0,-80
    80005094:	8526                	mv	a0,s1
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	cb0080e7          	jalr	-848(ra) # 80003d46 <dirlink>
    8000509e:	06054f63          	bltz	a0,8000511c <create+0x162>
  iunlockput(dp);
    800050a2:	8526                	mv	a0,s1
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	80a080e7          	jalr	-2038(ra) # 800038ae <iunlockput>
  return ip;
    800050ac:	8ad2                	mv	s5,s4
    800050ae:	b749                	j	80005030 <create+0x76>
    iunlockput(dp);
    800050b0:	8526                	mv	a0,s1
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	7fc080e7          	jalr	2044(ra) # 800038ae <iunlockput>
    return 0;
    800050ba:	8ad2                	mv	s5,s4
    800050bc:	bf95                	j	80005030 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050be:	004a2603          	lw	a2,4(s4)
    800050c2:	00003597          	auipc	a1,0x3
    800050c6:	63e58593          	addi	a1,a1,1598 # 80008700 <syscalls+0x2b0>
    800050ca:	8552                	mv	a0,s4
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	c7a080e7          	jalr	-902(ra) # 80003d46 <dirlink>
    800050d4:	04054463          	bltz	a0,8000511c <create+0x162>
    800050d8:	40d0                	lw	a2,4(s1)
    800050da:	00003597          	auipc	a1,0x3
    800050de:	62e58593          	addi	a1,a1,1582 # 80008708 <syscalls+0x2b8>
    800050e2:	8552                	mv	a0,s4
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	c62080e7          	jalr	-926(ra) # 80003d46 <dirlink>
    800050ec:	02054863          	bltz	a0,8000511c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800050f0:	004a2603          	lw	a2,4(s4)
    800050f4:	fb040593          	addi	a1,s0,-80
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	c4c080e7          	jalr	-948(ra) # 80003d46 <dirlink>
    80005102:	00054d63          	bltz	a0,8000511c <create+0x162>
    dp->nlink++;  // for ".."
    80005106:	04a4d783          	lhu	a5,74(s1)
    8000510a:	2785                	addiw	a5,a5,1
    8000510c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffe097          	auipc	ra,0xffffe
    80005116:	46e080e7          	jalr	1134(ra) # 80003580 <iupdate>
    8000511a:	b761                	j	800050a2 <create+0xe8>
  ip->nlink = 0;
    8000511c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005120:	8552                	mv	a0,s4
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	45e080e7          	jalr	1118(ra) # 80003580 <iupdate>
  iunlockput(ip);
    8000512a:	8552                	mv	a0,s4
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	782080e7          	jalr	1922(ra) # 800038ae <iunlockput>
  iunlockput(dp);
    80005134:	8526                	mv	a0,s1
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	778080e7          	jalr	1912(ra) # 800038ae <iunlockput>
  return 0;
    8000513e:	bdcd                	j	80005030 <create+0x76>
    return 0;
    80005140:	8aaa                	mv	s5,a0
    80005142:	b5fd                	j	80005030 <create+0x76>

0000000080005144 <sys_dup>:
{
    80005144:	7179                	addi	sp,sp,-48
    80005146:	f406                	sd	ra,40(sp)
    80005148:	f022                	sd	s0,32(sp)
    8000514a:	ec26                	sd	s1,24(sp)
    8000514c:	e84a                	sd	s2,16(sp)
    8000514e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005150:	fd840613          	addi	a2,s0,-40
    80005154:	4581                	li	a1,0
    80005156:	4501                	li	a0,0
    80005158:	00000097          	auipc	ra,0x0
    8000515c:	dc0080e7          	jalr	-576(ra) # 80004f18 <argfd>
    return -1;
    80005160:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005162:	02054363          	bltz	a0,80005188 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005166:	fd843903          	ld	s2,-40(s0)
    8000516a:	854a                	mv	a0,s2
    8000516c:	00000097          	auipc	ra,0x0
    80005170:	e0c080e7          	jalr	-500(ra) # 80004f78 <fdalloc>
    80005174:	84aa                	mv	s1,a0
    return -1;
    80005176:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005178:	00054863          	bltz	a0,80005188 <sys_dup+0x44>
  filedup(f);
    8000517c:	854a                	mv	a0,s2
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	310080e7          	jalr	784(ra) # 8000448e <filedup>
  return fd;
    80005186:	87a6                	mv	a5,s1
}
    80005188:	853e                	mv	a0,a5
    8000518a:	70a2                	ld	ra,40(sp)
    8000518c:	7402                	ld	s0,32(sp)
    8000518e:	64e2                	ld	s1,24(sp)
    80005190:	6942                	ld	s2,16(sp)
    80005192:	6145                	addi	sp,sp,48
    80005194:	8082                	ret

0000000080005196 <sys_read>:
{
    80005196:	7179                	addi	sp,sp,-48
    80005198:	f406                	sd	ra,40(sp)
    8000519a:	f022                	sd	s0,32(sp)
    8000519c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000519e:	fd840593          	addi	a1,s0,-40
    800051a2:	4505                	li	a0,1
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	93e080e7          	jalr	-1730(ra) # 80002ae2 <argaddr>
  argint(2, &n);
    800051ac:	fe440593          	addi	a1,s0,-28
    800051b0:	4509                	li	a0,2
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	910080e7          	jalr	-1776(ra) # 80002ac2 <argint>
  if(argfd(0, 0, &f) < 0)
    800051ba:	fe840613          	addi	a2,s0,-24
    800051be:	4581                	li	a1,0
    800051c0:	4501                	li	a0,0
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	d56080e7          	jalr	-682(ra) # 80004f18 <argfd>
    800051ca:	87aa                	mv	a5,a0
    return -1;
    800051cc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051ce:	0007cc63          	bltz	a5,800051e6 <sys_read+0x50>
  return fileread(f, p, n);
    800051d2:	fe442603          	lw	a2,-28(s0)
    800051d6:	fd843583          	ld	a1,-40(s0)
    800051da:	fe843503          	ld	a0,-24(s0)
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	43c080e7          	jalr	1084(ra) # 8000461a <fileread>
}
    800051e6:	70a2                	ld	ra,40(sp)
    800051e8:	7402                	ld	s0,32(sp)
    800051ea:	6145                	addi	sp,sp,48
    800051ec:	8082                	ret

00000000800051ee <sys_write>:
{
    800051ee:	7179                	addi	sp,sp,-48
    800051f0:	f406                	sd	ra,40(sp)
    800051f2:	f022                	sd	s0,32(sp)
    800051f4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051f6:	fd840593          	addi	a1,s0,-40
    800051fa:	4505                	li	a0,1
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	8e6080e7          	jalr	-1818(ra) # 80002ae2 <argaddr>
  argint(2, &n);
    80005204:	fe440593          	addi	a1,s0,-28
    80005208:	4509                	li	a0,2
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	8b8080e7          	jalr	-1864(ra) # 80002ac2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005212:	fe840613          	addi	a2,s0,-24
    80005216:	4581                	li	a1,0
    80005218:	4501                	li	a0,0
    8000521a:	00000097          	auipc	ra,0x0
    8000521e:	cfe080e7          	jalr	-770(ra) # 80004f18 <argfd>
    80005222:	87aa                	mv	a5,a0
    return -1;
    80005224:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005226:	0007cc63          	bltz	a5,8000523e <sys_write+0x50>
  return filewrite(f, p, n);
    8000522a:	fe442603          	lw	a2,-28(s0)
    8000522e:	fd843583          	ld	a1,-40(s0)
    80005232:	fe843503          	ld	a0,-24(s0)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	4a6080e7          	jalr	1190(ra) # 800046dc <filewrite>
}
    8000523e:	70a2                	ld	ra,40(sp)
    80005240:	7402                	ld	s0,32(sp)
    80005242:	6145                	addi	sp,sp,48
    80005244:	8082                	ret

0000000080005246 <sys_close>:
{
    80005246:	1101                	addi	sp,sp,-32
    80005248:	ec06                	sd	ra,24(sp)
    8000524a:	e822                	sd	s0,16(sp)
    8000524c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000524e:	fe040613          	addi	a2,s0,-32
    80005252:	fec40593          	addi	a1,s0,-20
    80005256:	4501                	li	a0,0
    80005258:	00000097          	auipc	ra,0x0
    8000525c:	cc0080e7          	jalr	-832(ra) # 80004f18 <argfd>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005262:	02054463          	bltz	a0,8000528a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	746080e7          	jalr	1862(ra) # 800019ac <myproc>
    8000526e:	fec42783          	lw	a5,-20(s0)
    80005272:	07e9                	addi	a5,a5,26
    80005274:	078e                	slli	a5,a5,0x3
    80005276:	953e                	add	a0,a0,a5
    80005278:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000527c:	fe043503          	ld	a0,-32(s0)
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	260080e7          	jalr	608(ra) # 800044e0 <fileclose>
  return 0;
    80005288:	4781                	li	a5,0
}
    8000528a:	853e                	mv	a0,a5
    8000528c:	60e2                	ld	ra,24(sp)
    8000528e:	6442                	ld	s0,16(sp)
    80005290:	6105                	addi	sp,sp,32
    80005292:	8082                	ret

0000000080005294 <sys_fstat>:
{
    80005294:	1101                	addi	sp,sp,-32
    80005296:	ec06                	sd	ra,24(sp)
    80005298:	e822                	sd	s0,16(sp)
    8000529a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000529c:	fe040593          	addi	a1,s0,-32
    800052a0:	4505                	li	a0,1
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	840080e7          	jalr	-1984(ra) # 80002ae2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052aa:	fe840613          	addi	a2,s0,-24
    800052ae:	4581                	li	a1,0
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	c66080e7          	jalr	-922(ra) # 80004f18 <argfd>
    800052ba:	87aa                	mv	a5,a0
    return -1;
    800052bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052be:	0007ca63          	bltz	a5,800052d2 <sys_fstat+0x3e>
  return filestat(f, st);
    800052c2:	fe043583          	ld	a1,-32(s0)
    800052c6:	fe843503          	ld	a0,-24(s0)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	2de080e7          	jalr	734(ra) # 800045a8 <filestat>
}
    800052d2:	60e2                	ld	ra,24(sp)
    800052d4:	6442                	ld	s0,16(sp)
    800052d6:	6105                	addi	sp,sp,32
    800052d8:	8082                	ret

00000000800052da <sys_link>:
{
    800052da:	7169                	addi	sp,sp,-304
    800052dc:	f606                	sd	ra,296(sp)
    800052de:	f222                	sd	s0,288(sp)
    800052e0:	ee26                	sd	s1,280(sp)
    800052e2:	ea4a                	sd	s2,272(sp)
    800052e4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052e6:	08000613          	li	a2,128
    800052ea:	ed040593          	addi	a1,s0,-304
    800052ee:	4501                	li	a0,0
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	812080e7          	jalr	-2030(ra) # 80002b02 <argstr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052fa:	10054e63          	bltz	a0,80005416 <sys_link+0x13c>
    800052fe:	08000613          	li	a2,128
    80005302:	f5040593          	addi	a1,s0,-176
    80005306:	4505                	li	a0,1
    80005308:	ffffd097          	auipc	ra,0xffffd
    8000530c:	7fa080e7          	jalr	2042(ra) # 80002b02 <argstr>
    return -1;
    80005310:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005312:	10054263          	bltz	a0,80005416 <sys_link+0x13c>
  begin_op();
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	d02080e7          	jalr	-766(ra) # 80004018 <begin_op>
  if((ip = namei(old)) == 0){
    8000531e:	ed040513          	addi	a0,s0,-304
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	ad6080e7          	jalr	-1322(ra) # 80003df8 <namei>
    8000532a:	84aa                	mv	s1,a0
    8000532c:	c551                	beqz	a0,800053b8 <sys_link+0xde>
  ilock(ip);
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	31e080e7          	jalr	798(ra) # 8000364c <ilock>
  if(ip->type == T_DIR){
    80005336:	04449703          	lh	a4,68(s1)
    8000533a:	4785                	li	a5,1
    8000533c:	08f70463          	beq	a4,a5,800053c4 <sys_link+0xea>
  ip->nlink++;
    80005340:	04a4d783          	lhu	a5,74(s1)
    80005344:	2785                	addiw	a5,a5,1
    80005346:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	234080e7          	jalr	564(ra) # 80003580 <iupdate>
  iunlock(ip);
    80005354:	8526                	mv	a0,s1
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	3b8080e7          	jalr	952(ra) # 8000370e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000535e:	fd040593          	addi	a1,s0,-48
    80005362:	f5040513          	addi	a0,s0,-176
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	ab0080e7          	jalr	-1360(ra) # 80003e16 <nameiparent>
    8000536e:	892a                	mv	s2,a0
    80005370:	c935                	beqz	a0,800053e4 <sys_link+0x10a>
  ilock(dp);
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	2da080e7          	jalr	730(ra) # 8000364c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000537a:	00092703          	lw	a4,0(s2)
    8000537e:	409c                	lw	a5,0(s1)
    80005380:	04f71d63          	bne	a4,a5,800053da <sys_link+0x100>
    80005384:	40d0                	lw	a2,4(s1)
    80005386:	fd040593          	addi	a1,s0,-48
    8000538a:	854a                	mv	a0,s2
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	9ba080e7          	jalr	-1606(ra) # 80003d46 <dirlink>
    80005394:	04054363          	bltz	a0,800053da <sys_link+0x100>
  iunlockput(dp);
    80005398:	854a                	mv	a0,s2
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	514080e7          	jalr	1300(ra) # 800038ae <iunlockput>
  iput(ip);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	462080e7          	jalr	1122(ra) # 80003806 <iput>
  end_op();
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	cea080e7          	jalr	-790(ra) # 80004096 <end_op>
  return 0;
    800053b4:	4781                	li	a5,0
    800053b6:	a085                	j	80005416 <sys_link+0x13c>
    end_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cde080e7          	jalr	-802(ra) # 80004096 <end_op>
    return -1;
    800053c0:	57fd                	li	a5,-1
    800053c2:	a891                	j	80005416 <sys_link+0x13c>
    iunlockput(ip);
    800053c4:	8526                	mv	a0,s1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	4e8080e7          	jalr	1256(ra) # 800038ae <iunlockput>
    end_op();
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	cc8080e7          	jalr	-824(ra) # 80004096 <end_op>
    return -1;
    800053d6:	57fd                	li	a5,-1
    800053d8:	a83d                	j	80005416 <sys_link+0x13c>
    iunlockput(dp);
    800053da:	854a                	mv	a0,s2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	4d2080e7          	jalr	1234(ra) # 800038ae <iunlockput>
  ilock(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	266080e7          	jalr	614(ra) # 8000364c <ilock>
  ip->nlink--;
    800053ee:	04a4d783          	lhu	a5,74(s1)
    800053f2:	37fd                	addiw	a5,a5,-1
    800053f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053f8:	8526                	mv	a0,s1
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	186080e7          	jalr	390(ra) # 80003580 <iupdate>
  iunlockput(ip);
    80005402:	8526                	mv	a0,s1
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	4aa080e7          	jalr	1194(ra) # 800038ae <iunlockput>
  end_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c8a080e7          	jalr	-886(ra) # 80004096 <end_op>
  return -1;
    80005414:	57fd                	li	a5,-1
}
    80005416:	853e                	mv	a0,a5
    80005418:	70b2                	ld	ra,296(sp)
    8000541a:	7412                	ld	s0,288(sp)
    8000541c:	64f2                	ld	s1,280(sp)
    8000541e:	6952                	ld	s2,272(sp)
    80005420:	6155                	addi	sp,sp,304
    80005422:	8082                	ret

0000000080005424 <sys_unlink>:
{
    80005424:	7151                	addi	sp,sp,-240
    80005426:	f586                	sd	ra,232(sp)
    80005428:	f1a2                	sd	s0,224(sp)
    8000542a:	eda6                	sd	s1,216(sp)
    8000542c:	e9ca                	sd	s2,208(sp)
    8000542e:	e5ce                	sd	s3,200(sp)
    80005430:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005432:	08000613          	li	a2,128
    80005436:	f3040593          	addi	a1,s0,-208
    8000543a:	4501                	li	a0,0
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	6c6080e7          	jalr	1734(ra) # 80002b02 <argstr>
    80005444:	18054163          	bltz	a0,800055c6 <sys_unlink+0x1a2>
  begin_op();
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	bd0080e7          	jalr	-1072(ra) # 80004018 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005450:	fb040593          	addi	a1,s0,-80
    80005454:	f3040513          	addi	a0,s0,-208
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	9be080e7          	jalr	-1602(ra) # 80003e16 <nameiparent>
    80005460:	84aa                	mv	s1,a0
    80005462:	c979                	beqz	a0,80005538 <sys_unlink+0x114>
  ilock(dp);
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	1e8080e7          	jalr	488(ra) # 8000364c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000546c:	00003597          	auipc	a1,0x3
    80005470:	29458593          	addi	a1,a1,660 # 80008700 <syscalls+0x2b0>
    80005474:	fb040513          	addi	a0,s0,-80
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	69e080e7          	jalr	1694(ra) # 80003b16 <namecmp>
    80005480:	14050a63          	beqz	a0,800055d4 <sys_unlink+0x1b0>
    80005484:	00003597          	auipc	a1,0x3
    80005488:	28458593          	addi	a1,a1,644 # 80008708 <syscalls+0x2b8>
    8000548c:	fb040513          	addi	a0,s0,-80
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	686080e7          	jalr	1670(ra) # 80003b16 <namecmp>
    80005498:	12050e63          	beqz	a0,800055d4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000549c:	f2c40613          	addi	a2,s0,-212
    800054a0:	fb040593          	addi	a1,s0,-80
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	68a080e7          	jalr	1674(ra) # 80003b30 <dirlookup>
    800054ae:	892a                	mv	s2,a0
    800054b0:	12050263          	beqz	a0,800055d4 <sys_unlink+0x1b0>
  ilock(ip);
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	198080e7          	jalr	408(ra) # 8000364c <ilock>
  if(ip->nlink < 1)
    800054bc:	04a91783          	lh	a5,74(s2)
    800054c0:	08f05263          	blez	a5,80005544 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054c4:	04491703          	lh	a4,68(s2)
    800054c8:	4785                	li	a5,1
    800054ca:	08f70563          	beq	a4,a5,80005554 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054ce:	4641                	li	a2,16
    800054d0:	4581                	li	a1,0
    800054d2:	fc040513          	addi	a0,s0,-64
    800054d6:	ffffb097          	auipc	ra,0xffffb
    800054da:	7fc080e7          	jalr	2044(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054de:	4741                	li	a4,16
    800054e0:	f2c42683          	lw	a3,-212(s0)
    800054e4:	fc040613          	addi	a2,s0,-64
    800054e8:	4581                	li	a1,0
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	50c080e7          	jalr	1292(ra) # 800039f8 <writei>
    800054f4:	47c1                	li	a5,16
    800054f6:	0af51563          	bne	a0,a5,800055a0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054fa:	04491703          	lh	a4,68(s2)
    800054fe:	4785                	li	a5,1
    80005500:	0af70863          	beq	a4,a5,800055b0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	3a8080e7          	jalr	936(ra) # 800038ae <iunlockput>
  ip->nlink--;
    8000550e:	04a95783          	lhu	a5,74(s2)
    80005512:	37fd                	addiw	a5,a5,-1
    80005514:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005518:	854a                	mv	a0,s2
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	066080e7          	jalr	102(ra) # 80003580 <iupdate>
  iunlockput(ip);
    80005522:	854a                	mv	a0,s2
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	38a080e7          	jalr	906(ra) # 800038ae <iunlockput>
  end_op();
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	b6a080e7          	jalr	-1174(ra) # 80004096 <end_op>
  return 0;
    80005534:	4501                	li	a0,0
    80005536:	a84d                	j	800055e8 <sys_unlink+0x1c4>
    end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	b5e080e7          	jalr	-1186(ra) # 80004096 <end_op>
    return -1;
    80005540:	557d                	li	a0,-1
    80005542:	a05d                	j	800055e8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005544:	00003517          	auipc	a0,0x3
    80005548:	1cc50513          	addi	a0,a0,460 # 80008710 <syscalls+0x2c0>
    8000554c:	ffffb097          	auipc	ra,0xffffb
    80005550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005554:	04c92703          	lw	a4,76(s2)
    80005558:	02000793          	li	a5,32
    8000555c:	f6e7f9e3          	bgeu	a5,a4,800054ce <sys_unlink+0xaa>
    80005560:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005564:	4741                	li	a4,16
    80005566:	86ce                	mv	a3,s3
    80005568:	f1840613          	addi	a2,s0,-232
    8000556c:	4581                	li	a1,0
    8000556e:	854a                	mv	a0,s2
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	390080e7          	jalr	912(ra) # 80003900 <readi>
    80005578:	47c1                	li	a5,16
    8000557a:	00f51b63          	bne	a0,a5,80005590 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000557e:	f1845783          	lhu	a5,-232(s0)
    80005582:	e7a1                	bnez	a5,800055ca <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005584:	29c1                	addiw	s3,s3,16
    80005586:	04c92783          	lw	a5,76(s2)
    8000558a:	fcf9ede3          	bltu	s3,a5,80005564 <sys_unlink+0x140>
    8000558e:	b781                	j	800054ce <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005590:	00003517          	auipc	a0,0x3
    80005594:	19850513          	addi	a0,a0,408 # 80008728 <syscalls+0x2d8>
    80005598:	ffffb097          	auipc	ra,0xffffb
    8000559c:	fa8080e7          	jalr	-88(ra) # 80000540 <panic>
    panic("unlink: writei");
    800055a0:	00003517          	auipc	a0,0x3
    800055a4:	1a050513          	addi	a0,a0,416 # 80008740 <syscalls+0x2f0>
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	f98080e7          	jalr	-104(ra) # 80000540 <panic>
    dp->nlink--;
    800055b0:	04a4d783          	lhu	a5,74(s1)
    800055b4:	37fd                	addiw	a5,a5,-1
    800055b6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	fc4080e7          	jalr	-60(ra) # 80003580 <iupdate>
    800055c4:	b781                	j	80005504 <sys_unlink+0xe0>
    return -1;
    800055c6:	557d                	li	a0,-1
    800055c8:	a005                	j	800055e8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	2e2080e7          	jalr	738(ra) # 800038ae <iunlockput>
  iunlockput(dp);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	2d8080e7          	jalr	728(ra) # 800038ae <iunlockput>
  end_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	ab8080e7          	jalr	-1352(ra) # 80004096 <end_op>
  return -1;
    800055e6:	557d                	li	a0,-1
}
    800055e8:	70ae                	ld	ra,232(sp)
    800055ea:	740e                	ld	s0,224(sp)
    800055ec:	64ee                	ld	s1,216(sp)
    800055ee:	694e                	ld	s2,208(sp)
    800055f0:	69ae                	ld	s3,200(sp)
    800055f2:	616d                	addi	sp,sp,240
    800055f4:	8082                	ret

00000000800055f6 <sys_open>:

uint64
sys_open(void)
{
    800055f6:	7131                	addi	sp,sp,-192
    800055f8:	fd06                	sd	ra,184(sp)
    800055fa:	f922                	sd	s0,176(sp)
    800055fc:	f526                	sd	s1,168(sp)
    800055fe:	f14a                	sd	s2,160(sp)
    80005600:	ed4e                	sd	s3,152(sp)
    80005602:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005604:	f4c40593          	addi	a1,s0,-180
    80005608:	4505                	li	a0,1
    8000560a:	ffffd097          	auipc	ra,0xffffd
    8000560e:	4b8080e7          	jalr	1208(ra) # 80002ac2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005612:	08000613          	li	a2,128
    80005616:	f5040593          	addi	a1,s0,-176
    8000561a:	4501                	li	a0,0
    8000561c:	ffffd097          	auipc	ra,0xffffd
    80005620:	4e6080e7          	jalr	1254(ra) # 80002b02 <argstr>
    80005624:	87aa                	mv	a5,a0
    return -1;
    80005626:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005628:	0a07c963          	bltz	a5,800056da <sys_open+0xe4>

  begin_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	9ec080e7          	jalr	-1556(ra) # 80004018 <begin_op>

  if(omode & O_CREATE){
    80005634:	f4c42783          	lw	a5,-180(s0)
    80005638:	2007f793          	andi	a5,a5,512
    8000563c:	cfc5                	beqz	a5,800056f4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000563e:	4681                	li	a3,0
    80005640:	4601                	li	a2,0
    80005642:	4589                	li	a1,2
    80005644:	f5040513          	addi	a0,s0,-176
    80005648:	00000097          	auipc	ra,0x0
    8000564c:	972080e7          	jalr	-1678(ra) # 80004fba <create>
    80005650:	84aa                	mv	s1,a0
    if(ip == 0){
    80005652:	c959                	beqz	a0,800056e8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005654:	04449703          	lh	a4,68(s1)
    80005658:	478d                	li	a5,3
    8000565a:	00f71763          	bne	a4,a5,80005668 <sys_open+0x72>
    8000565e:	0464d703          	lhu	a4,70(s1)
    80005662:	47a5                	li	a5,9
    80005664:	0ce7ed63          	bltu	a5,a4,8000573e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	dbc080e7          	jalr	-580(ra) # 80004424 <filealloc>
    80005670:	89aa                	mv	s3,a0
    80005672:	10050363          	beqz	a0,80005778 <sys_open+0x182>
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	902080e7          	jalr	-1790(ra) # 80004f78 <fdalloc>
    8000567e:	892a                	mv	s2,a0
    80005680:	0e054763          	bltz	a0,8000576e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005684:	04449703          	lh	a4,68(s1)
    80005688:	478d                	li	a5,3
    8000568a:	0cf70563          	beq	a4,a5,80005754 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000568e:	4789                	li	a5,2
    80005690:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005694:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005698:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000569c:	f4c42783          	lw	a5,-180(s0)
    800056a0:	0017c713          	xori	a4,a5,1
    800056a4:	8b05                	andi	a4,a4,1
    800056a6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056aa:	0037f713          	andi	a4,a5,3
    800056ae:	00e03733          	snez	a4,a4
    800056b2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056b6:	4007f793          	andi	a5,a5,1024
    800056ba:	c791                	beqz	a5,800056c6 <sys_open+0xd0>
    800056bc:	04449703          	lh	a4,68(s1)
    800056c0:	4789                	li	a5,2
    800056c2:	0af70063          	beq	a4,a5,80005762 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	046080e7          	jalr	70(ra) # 8000370e <iunlock>
  end_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	9c6080e7          	jalr	-1594(ra) # 80004096 <end_op>

  return fd;
    800056d8:	854a                	mv	a0,s2
}
    800056da:	70ea                	ld	ra,184(sp)
    800056dc:	744a                	ld	s0,176(sp)
    800056de:	74aa                	ld	s1,168(sp)
    800056e0:	790a                	ld	s2,160(sp)
    800056e2:	69ea                	ld	s3,152(sp)
    800056e4:	6129                	addi	sp,sp,192
    800056e6:	8082                	ret
      end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	9ae080e7          	jalr	-1618(ra) # 80004096 <end_op>
      return -1;
    800056f0:	557d                	li	a0,-1
    800056f2:	b7e5                	j	800056da <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056f4:	f5040513          	addi	a0,s0,-176
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	700080e7          	jalr	1792(ra) # 80003df8 <namei>
    80005700:	84aa                	mv	s1,a0
    80005702:	c905                	beqz	a0,80005732 <sys_open+0x13c>
    ilock(ip);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	f48080e7          	jalr	-184(ra) # 8000364c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000570c:	04449703          	lh	a4,68(s1)
    80005710:	4785                	li	a5,1
    80005712:	f4f711e3          	bne	a4,a5,80005654 <sys_open+0x5e>
    80005716:	f4c42783          	lw	a5,-180(s0)
    8000571a:	d7b9                	beqz	a5,80005668 <sys_open+0x72>
      iunlockput(ip);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	190080e7          	jalr	400(ra) # 800038ae <iunlockput>
      end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	970080e7          	jalr	-1680(ra) # 80004096 <end_op>
      return -1;
    8000572e:	557d                	li	a0,-1
    80005730:	b76d                	j	800056da <sys_open+0xe4>
      end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	964080e7          	jalr	-1692(ra) # 80004096 <end_op>
      return -1;
    8000573a:	557d                	li	a0,-1
    8000573c:	bf79                	j	800056da <sys_open+0xe4>
    iunlockput(ip);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	16e080e7          	jalr	366(ra) # 800038ae <iunlockput>
    end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	94e080e7          	jalr	-1714(ra) # 80004096 <end_op>
    return -1;
    80005750:	557d                	li	a0,-1
    80005752:	b761                	j	800056da <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005754:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005758:	04649783          	lh	a5,70(s1)
    8000575c:	02f99223          	sh	a5,36(s3)
    80005760:	bf25                	j	80005698 <sys_open+0xa2>
    itrunc(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	ff6080e7          	jalr	-10(ra) # 8000375a <itrunc>
    8000576c:	bfa9                	j	800056c6 <sys_open+0xd0>
      fileclose(f);
    8000576e:	854e                	mv	a0,s3
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	d70080e7          	jalr	-656(ra) # 800044e0 <fileclose>
    iunlockput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	134080e7          	jalr	308(ra) # 800038ae <iunlockput>
    end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	914080e7          	jalr	-1772(ra) # 80004096 <end_op>
    return -1;
    8000578a:	557d                	li	a0,-1
    8000578c:	b7b9                	j	800056da <sys_open+0xe4>

000000008000578e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000578e:	7175                	addi	sp,sp,-144
    80005790:	e506                	sd	ra,136(sp)
    80005792:	e122                	sd	s0,128(sp)
    80005794:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	882080e7          	jalr	-1918(ra) # 80004018 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000579e:	08000613          	li	a2,128
    800057a2:	f7040593          	addi	a1,s0,-144
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	35a080e7          	jalr	858(ra) # 80002b02 <argstr>
    800057b0:	02054963          	bltz	a0,800057e2 <sys_mkdir+0x54>
    800057b4:	4681                	li	a3,0
    800057b6:	4601                	li	a2,0
    800057b8:	4585                	li	a1,1
    800057ba:	f7040513          	addi	a0,s0,-144
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	7fc080e7          	jalr	2044(ra) # 80004fba <create>
    800057c6:	cd11                	beqz	a0,800057e2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	0e6080e7          	jalr	230(ra) # 800038ae <iunlockput>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	8c6080e7          	jalr	-1850(ra) # 80004096 <end_op>
  return 0;
    800057d8:	4501                	li	a0,0
}
    800057da:	60aa                	ld	ra,136(sp)
    800057dc:	640a                	ld	s0,128(sp)
    800057de:	6149                	addi	sp,sp,144
    800057e0:	8082                	ret
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	8b4080e7          	jalr	-1868(ra) # 80004096 <end_op>
    return -1;
    800057ea:	557d                	li	a0,-1
    800057ec:	b7fd                	j	800057da <sys_mkdir+0x4c>

00000000800057ee <sys_mknod>:

uint64
sys_mknod(void)
{
    800057ee:	7135                	addi	sp,sp,-160
    800057f0:	ed06                	sd	ra,152(sp)
    800057f2:	e922                	sd	s0,144(sp)
    800057f4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	822080e7          	jalr	-2014(ra) # 80004018 <begin_op>
  argint(1, &major);
    800057fe:	f6c40593          	addi	a1,s0,-148
    80005802:	4505                	li	a0,1
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	2be080e7          	jalr	702(ra) # 80002ac2 <argint>
  argint(2, &minor);
    8000580c:	f6840593          	addi	a1,s0,-152
    80005810:	4509                	li	a0,2
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	2b0080e7          	jalr	688(ra) # 80002ac2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000581a:	08000613          	li	a2,128
    8000581e:	f7040593          	addi	a1,s0,-144
    80005822:	4501                	li	a0,0
    80005824:	ffffd097          	auipc	ra,0xffffd
    80005828:	2de080e7          	jalr	734(ra) # 80002b02 <argstr>
    8000582c:	02054b63          	bltz	a0,80005862 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005830:	f6841683          	lh	a3,-152(s0)
    80005834:	f6c41603          	lh	a2,-148(s0)
    80005838:	458d                	li	a1,3
    8000583a:	f7040513          	addi	a0,s0,-144
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	77c080e7          	jalr	1916(ra) # 80004fba <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005846:	cd11                	beqz	a0,80005862 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	066080e7          	jalr	102(ra) # 800038ae <iunlockput>
  end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	846080e7          	jalr	-1978(ra) # 80004096 <end_op>
  return 0;
    80005858:	4501                	li	a0,0
}
    8000585a:	60ea                	ld	ra,152(sp)
    8000585c:	644a                	ld	s0,144(sp)
    8000585e:	610d                	addi	sp,sp,160
    80005860:	8082                	ret
    end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	834080e7          	jalr	-1996(ra) # 80004096 <end_op>
    return -1;
    8000586a:	557d                	li	a0,-1
    8000586c:	b7fd                	j	8000585a <sys_mknod+0x6c>

000000008000586e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000586e:	7135                	addi	sp,sp,-160
    80005870:	ed06                	sd	ra,152(sp)
    80005872:	e922                	sd	s0,144(sp)
    80005874:	e526                	sd	s1,136(sp)
    80005876:	e14a                	sd	s2,128(sp)
    80005878:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000587a:	ffffc097          	auipc	ra,0xffffc
    8000587e:	132080e7          	jalr	306(ra) # 800019ac <myproc>
    80005882:	892a                	mv	s2,a0
  
  begin_op();
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	794080e7          	jalr	1940(ra) # 80004018 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000588c:	08000613          	li	a2,128
    80005890:	f6040593          	addi	a1,s0,-160
    80005894:	4501                	li	a0,0
    80005896:	ffffd097          	auipc	ra,0xffffd
    8000589a:	26c080e7          	jalr	620(ra) # 80002b02 <argstr>
    8000589e:	04054b63          	bltz	a0,800058f4 <sys_chdir+0x86>
    800058a2:	f6040513          	addi	a0,s0,-160
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	552080e7          	jalr	1362(ra) # 80003df8 <namei>
    800058ae:	84aa                	mv	s1,a0
    800058b0:	c131                	beqz	a0,800058f4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	d9a080e7          	jalr	-614(ra) # 8000364c <ilock>
  if(ip->type != T_DIR){
    800058ba:	04449703          	lh	a4,68(s1)
    800058be:	4785                	li	a5,1
    800058c0:	04f71063          	bne	a4,a5,80005900 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	e48080e7          	jalr	-440(ra) # 8000370e <iunlock>
  iput(p->cwd);
    800058ce:	15893503          	ld	a0,344(s2)
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	f34080e7          	jalr	-204(ra) # 80003806 <iput>
  end_op();
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	7bc080e7          	jalr	1980(ra) # 80004096 <end_op>
  p->cwd = ip;
    800058e2:	14993c23          	sd	s1,344(s2)
  return 0;
    800058e6:	4501                	li	a0,0
}
    800058e8:	60ea                	ld	ra,152(sp)
    800058ea:	644a                	ld	s0,144(sp)
    800058ec:	64aa                	ld	s1,136(sp)
    800058ee:	690a                	ld	s2,128(sp)
    800058f0:	610d                	addi	sp,sp,160
    800058f2:	8082                	ret
    end_op();
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	7a2080e7          	jalr	1954(ra) # 80004096 <end_op>
    return -1;
    800058fc:	557d                	li	a0,-1
    800058fe:	b7ed                	j	800058e8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005900:	8526                	mv	a0,s1
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	fac080e7          	jalr	-84(ra) # 800038ae <iunlockput>
    end_op();
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	78c080e7          	jalr	1932(ra) # 80004096 <end_op>
    return -1;
    80005912:	557d                	li	a0,-1
    80005914:	bfd1                	j	800058e8 <sys_chdir+0x7a>

0000000080005916 <sys_exec>:

uint64
sys_exec(void)
{
    80005916:	7145                	addi	sp,sp,-464
    80005918:	e786                	sd	ra,456(sp)
    8000591a:	e3a2                	sd	s0,448(sp)
    8000591c:	ff26                	sd	s1,440(sp)
    8000591e:	fb4a                	sd	s2,432(sp)
    80005920:	f74e                	sd	s3,424(sp)
    80005922:	f352                	sd	s4,416(sp)
    80005924:	ef56                	sd	s5,408(sp)
    80005926:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005928:	e3840593          	addi	a1,s0,-456
    8000592c:	4505                	li	a0,1
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	1b4080e7          	jalr	436(ra) # 80002ae2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005936:	08000613          	li	a2,128
    8000593a:	f4040593          	addi	a1,s0,-192
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	1c2080e7          	jalr	450(ra) # 80002b02 <argstr>
    80005948:	87aa                	mv	a5,a0
    return -1;
    8000594a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000594c:	0c07c363          	bltz	a5,80005a12 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005950:	10000613          	li	a2,256
    80005954:	4581                	li	a1,0
    80005956:	e4040513          	addi	a0,s0,-448
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	378080e7          	jalr	888(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005962:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005966:	89a6                	mv	s3,s1
    80005968:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000596a:	02000a13          	li	s4,32
    8000596e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005972:	00391513          	slli	a0,s2,0x3
    80005976:	e3040593          	addi	a1,s0,-464
    8000597a:	e3843783          	ld	a5,-456(s0)
    8000597e:	953e                	add	a0,a0,a5
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	0a4080e7          	jalr	164(ra) # 80002a24 <fetchaddr>
    80005988:	02054a63          	bltz	a0,800059bc <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000598c:	e3043783          	ld	a5,-464(s0)
    80005990:	c3b9                	beqz	a5,800059d6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005992:	ffffb097          	auipc	ra,0xffffb
    80005996:	154080e7          	jalr	340(ra) # 80000ae6 <kalloc>
    8000599a:	85aa                	mv	a1,a0
    8000599c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059a0:	cd11                	beqz	a0,800059bc <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059a2:	6605                	lui	a2,0x1
    800059a4:	e3043503          	ld	a0,-464(s0)
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	0ce080e7          	jalr	206(ra) # 80002a76 <fetchstr>
    800059b0:	00054663          	bltz	a0,800059bc <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800059b4:	0905                	addi	s2,s2,1
    800059b6:	09a1                	addi	s3,s3,8
    800059b8:	fb491be3          	bne	s2,s4,8000596e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059bc:	f4040913          	addi	s2,s0,-192
    800059c0:	6088                	ld	a0,0(s1)
    800059c2:	c539                	beqz	a0,80005a10 <sys_exec+0xfa>
    kfree(argv[i]);
    800059c4:	ffffb097          	auipc	ra,0xffffb
    800059c8:	024080e7          	jalr	36(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059cc:	04a1                	addi	s1,s1,8
    800059ce:	ff2499e3          	bne	s1,s2,800059c0 <sys_exec+0xaa>
  return -1;
    800059d2:	557d                	li	a0,-1
    800059d4:	a83d                	j	80005a12 <sys_exec+0xfc>
      argv[i] = 0;
    800059d6:	0a8e                	slli	s5,s5,0x3
    800059d8:	fc0a8793          	addi	a5,s5,-64
    800059dc:	00878ab3          	add	s5,a5,s0
    800059e0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059e4:	e4040593          	addi	a1,s0,-448
    800059e8:	f4040513          	addi	a0,s0,-192
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	16e080e7          	jalr	366(ra) # 80004b5a <exec>
    800059f4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059f6:	f4040993          	addi	s3,s0,-192
    800059fa:	6088                	ld	a0,0(s1)
    800059fc:	c901                	beqz	a0,80005a0c <sys_exec+0xf6>
    kfree(argv[i]);
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	fea080e7          	jalr	-22(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a06:	04a1                	addi	s1,s1,8
    80005a08:	ff3499e3          	bne	s1,s3,800059fa <sys_exec+0xe4>
  return ret;
    80005a0c:	854a                	mv	a0,s2
    80005a0e:	a011                	j	80005a12 <sys_exec+0xfc>
  return -1;
    80005a10:	557d                	li	a0,-1
}
    80005a12:	60be                	ld	ra,456(sp)
    80005a14:	641e                	ld	s0,448(sp)
    80005a16:	74fa                	ld	s1,440(sp)
    80005a18:	795a                	ld	s2,432(sp)
    80005a1a:	79ba                	ld	s3,424(sp)
    80005a1c:	7a1a                	ld	s4,416(sp)
    80005a1e:	6afa                	ld	s5,408(sp)
    80005a20:	6179                	addi	sp,sp,464
    80005a22:	8082                	ret

0000000080005a24 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a24:	7139                	addi	sp,sp,-64
    80005a26:	fc06                	sd	ra,56(sp)
    80005a28:	f822                	sd	s0,48(sp)
    80005a2a:	f426                	sd	s1,40(sp)
    80005a2c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a2e:	ffffc097          	auipc	ra,0xffffc
    80005a32:	f7e080e7          	jalr	-130(ra) # 800019ac <myproc>
    80005a36:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a38:	fd840593          	addi	a1,s0,-40
    80005a3c:	4501                	li	a0,0
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	0a4080e7          	jalr	164(ra) # 80002ae2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a46:	fc840593          	addi	a1,s0,-56
    80005a4a:	fd040513          	addi	a0,s0,-48
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	dc2080e7          	jalr	-574(ra) # 80004810 <pipealloc>
    return -1;
    80005a56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a58:	0c054463          	bltz	a0,80005b20 <sys_pipe+0xfc>
  fd0 = -1;
    80005a5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a60:	fd043503          	ld	a0,-48(s0)
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	514080e7          	jalr	1300(ra) # 80004f78 <fdalloc>
    80005a6c:	fca42223          	sw	a0,-60(s0)
    80005a70:	08054b63          	bltz	a0,80005b06 <sys_pipe+0xe2>
    80005a74:	fc843503          	ld	a0,-56(s0)
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	500080e7          	jalr	1280(ra) # 80004f78 <fdalloc>
    80005a80:	fca42023          	sw	a0,-64(s0)
    80005a84:	06054863          	bltz	a0,80005af4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a88:	4691                	li	a3,4
    80005a8a:	fc440613          	addi	a2,s0,-60
    80005a8e:	fd843583          	ld	a1,-40(s0)
    80005a92:	6ca8                	ld	a0,88(s1)
    80005a94:	ffffc097          	auipc	ra,0xffffc
    80005a98:	bd8080e7          	jalr	-1064(ra) # 8000166c <copyout>
    80005a9c:	02054063          	bltz	a0,80005abc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aa0:	4691                	li	a3,4
    80005aa2:	fc040613          	addi	a2,s0,-64
    80005aa6:	fd843583          	ld	a1,-40(s0)
    80005aaa:	0591                	addi	a1,a1,4
    80005aac:	6ca8                	ld	a0,88(s1)
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	bbe080e7          	jalr	-1090(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ab6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ab8:	06055463          	bgez	a0,80005b20 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005abc:	fc442783          	lw	a5,-60(s0)
    80005ac0:	07e9                	addi	a5,a5,26
    80005ac2:	078e                	slli	a5,a5,0x3
    80005ac4:	97a6                	add	a5,a5,s1
    80005ac6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005aca:	fc042783          	lw	a5,-64(s0)
    80005ace:	07e9                	addi	a5,a5,26
    80005ad0:	078e                	slli	a5,a5,0x3
    80005ad2:	94be                	add	s1,s1,a5
    80005ad4:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005ad8:	fd043503          	ld	a0,-48(s0)
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	a04080e7          	jalr	-1532(ra) # 800044e0 <fileclose>
    fileclose(wf);
    80005ae4:	fc843503          	ld	a0,-56(s0)
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	9f8080e7          	jalr	-1544(ra) # 800044e0 <fileclose>
    return -1;
    80005af0:	57fd                	li	a5,-1
    80005af2:	a03d                	j	80005b20 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005af4:	fc442783          	lw	a5,-60(s0)
    80005af8:	0007c763          	bltz	a5,80005b06 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005afc:	07e9                	addi	a5,a5,26
    80005afe:	078e                	slli	a5,a5,0x3
    80005b00:	97a6                	add	a5,a5,s1
    80005b02:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005b06:	fd043503          	ld	a0,-48(s0)
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	9d6080e7          	jalr	-1578(ra) # 800044e0 <fileclose>
    fileclose(wf);
    80005b12:	fc843503          	ld	a0,-56(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	9ca080e7          	jalr	-1590(ra) # 800044e0 <fileclose>
    return -1;
    80005b1e:	57fd                	li	a5,-1
}
    80005b20:	853e                	mv	a0,a5
    80005b22:	70e2                	ld	ra,56(sp)
    80005b24:	7442                	ld	s0,48(sp)
    80005b26:	74a2                	ld	s1,40(sp)
    80005b28:	6121                	addi	sp,sp,64
    80005b2a:	8082                	ret
    80005b2c:	0000                	unimp
	...

0000000080005b30 <kernelvec>:
    80005b30:	7111                	addi	sp,sp,-256
    80005b32:	e006                	sd	ra,0(sp)
    80005b34:	e40a                	sd	sp,8(sp)
    80005b36:	e80e                	sd	gp,16(sp)
    80005b38:	ec12                	sd	tp,24(sp)
    80005b3a:	f016                	sd	t0,32(sp)
    80005b3c:	f41a                	sd	t1,40(sp)
    80005b3e:	f81e                	sd	t2,48(sp)
    80005b40:	fc22                	sd	s0,56(sp)
    80005b42:	e0a6                	sd	s1,64(sp)
    80005b44:	e4aa                	sd	a0,72(sp)
    80005b46:	e8ae                	sd	a1,80(sp)
    80005b48:	ecb2                	sd	a2,88(sp)
    80005b4a:	f0b6                	sd	a3,96(sp)
    80005b4c:	f4ba                	sd	a4,104(sp)
    80005b4e:	f8be                	sd	a5,112(sp)
    80005b50:	fcc2                	sd	a6,120(sp)
    80005b52:	e146                	sd	a7,128(sp)
    80005b54:	e54a                	sd	s2,136(sp)
    80005b56:	e94e                	sd	s3,144(sp)
    80005b58:	ed52                	sd	s4,152(sp)
    80005b5a:	f156                	sd	s5,160(sp)
    80005b5c:	f55a                	sd	s6,168(sp)
    80005b5e:	f95e                	sd	s7,176(sp)
    80005b60:	fd62                	sd	s8,184(sp)
    80005b62:	e1e6                	sd	s9,192(sp)
    80005b64:	e5ea                	sd	s10,200(sp)
    80005b66:	e9ee                	sd	s11,208(sp)
    80005b68:	edf2                	sd	t3,216(sp)
    80005b6a:	f1f6                	sd	t4,224(sp)
    80005b6c:	f5fa                	sd	t5,232(sp)
    80005b6e:	f9fe                	sd	t6,240(sp)
    80005b70:	d81fc0ef          	jal	ra,800028f0 <kerneltrap>
    80005b74:	6082                	ld	ra,0(sp)
    80005b76:	6122                	ld	sp,8(sp)
    80005b78:	61c2                	ld	gp,16(sp)
    80005b7a:	7282                	ld	t0,32(sp)
    80005b7c:	7322                	ld	t1,40(sp)
    80005b7e:	73c2                	ld	t2,48(sp)
    80005b80:	7462                	ld	s0,56(sp)
    80005b82:	6486                	ld	s1,64(sp)
    80005b84:	6526                	ld	a0,72(sp)
    80005b86:	65c6                	ld	a1,80(sp)
    80005b88:	6666                	ld	a2,88(sp)
    80005b8a:	7686                	ld	a3,96(sp)
    80005b8c:	7726                	ld	a4,104(sp)
    80005b8e:	77c6                	ld	a5,112(sp)
    80005b90:	7866                	ld	a6,120(sp)
    80005b92:	688a                	ld	a7,128(sp)
    80005b94:	692a                	ld	s2,136(sp)
    80005b96:	69ca                	ld	s3,144(sp)
    80005b98:	6a6a                	ld	s4,152(sp)
    80005b9a:	7a8a                	ld	s5,160(sp)
    80005b9c:	7b2a                	ld	s6,168(sp)
    80005b9e:	7bca                	ld	s7,176(sp)
    80005ba0:	7c6a                	ld	s8,184(sp)
    80005ba2:	6c8e                	ld	s9,192(sp)
    80005ba4:	6d2e                	ld	s10,200(sp)
    80005ba6:	6dce                	ld	s11,208(sp)
    80005ba8:	6e6e                	ld	t3,216(sp)
    80005baa:	7e8e                	ld	t4,224(sp)
    80005bac:	7f2e                	ld	t5,232(sp)
    80005bae:	7fce                	ld	t6,240(sp)
    80005bb0:	6111                	addi	sp,sp,256
    80005bb2:	10200073          	sret
    80005bb6:	00000013          	nop
    80005bba:	00000013          	nop
    80005bbe:	0001                	nop

0000000080005bc0 <timervec>:
    80005bc0:	34051573          	csrrw	a0,mscratch,a0
    80005bc4:	e10c                	sd	a1,0(a0)
    80005bc6:	e510                	sd	a2,8(a0)
    80005bc8:	e914                	sd	a3,16(a0)
    80005bca:	6d0c                	ld	a1,24(a0)
    80005bcc:	7110                	ld	a2,32(a0)
    80005bce:	6194                	ld	a3,0(a1)
    80005bd0:	96b2                	add	a3,a3,a2
    80005bd2:	e194                	sd	a3,0(a1)
    80005bd4:	4589                	li	a1,2
    80005bd6:	14459073          	csrw	sip,a1
    80005bda:	6914                	ld	a3,16(a0)
    80005bdc:	6510                	ld	a2,8(a0)
    80005bde:	610c                	ld	a1,0(a0)
    80005be0:	34051573          	csrrw	a0,mscratch,a0
    80005be4:	30200073          	mret
	...

0000000080005bea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bea:	1141                	addi	sp,sp,-16
    80005bec:	e422                	sd	s0,8(sp)
    80005bee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bf0:	0c0007b7          	lui	a5,0xc000
    80005bf4:	4705                	li	a4,1
    80005bf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bf8:	c3d8                	sw	a4,4(a5)
}
    80005bfa:	6422                	ld	s0,8(sp)
    80005bfc:	0141                	addi	sp,sp,16
    80005bfe:	8082                	ret

0000000080005c00 <plicinithart>:

void
plicinithart(void)
{
    80005c00:	1141                	addi	sp,sp,-16
    80005c02:	e406                	sd	ra,8(sp)
    80005c04:	e022                	sd	s0,0(sp)
    80005c06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	d78080e7          	jalr	-648(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c10:	0085171b          	slliw	a4,a0,0x8
    80005c14:	0c0027b7          	lui	a5,0xc002
    80005c18:	97ba                	add	a5,a5,a4
    80005c1a:	40200713          	li	a4,1026
    80005c1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c22:	00d5151b          	slliw	a0,a0,0xd
    80005c26:	0c2017b7          	lui	a5,0xc201
    80005c2a:	97aa                	add	a5,a5,a0
    80005c2c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c30:	60a2                	ld	ra,8(sp)
    80005c32:	6402                	ld	s0,0(sp)
    80005c34:	0141                	addi	sp,sp,16
    80005c36:	8082                	ret

0000000080005c38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c38:	1141                	addi	sp,sp,-16
    80005c3a:	e406                	sd	ra,8(sp)
    80005c3c:	e022                	sd	s0,0(sp)
    80005c3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	d40080e7          	jalr	-704(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c48:	00d5151b          	slliw	a0,a0,0xd
    80005c4c:	0c2017b7          	lui	a5,0xc201
    80005c50:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c52:	43c8                	lw	a0,4(a5)
    80005c54:	60a2                	ld	ra,8(sp)
    80005c56:	6402                	ld	s0,0(sp)
    80005c58:	0141                	addi	sp,sp,16
    80005c5a:	8082                	ret

0000000080005c5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c5c:	1101                	addi	sp,sp,-32
    80005c5e:	ec06                	sd	ra,24(sp)
    80005c60:	e822                	sd	s0,16(sp)
    80005c62:	e426                	sd	s1,8(sp)
    80005c64:	1000                	addi	s0,sp,32
    80005c66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	d18080e7          	jalr	-744(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c70:	00d5151b          	slliw	a0,a0,0xd
    80005c74:	0c2017b7          	lui	a5,0xc201
    80005c78:	97aa                	add	a5,a5,a0
    80005c7a:	c3c4                	sw	s1,4(a5)
}
    80005c7c:	60e2                	ld	ra,24(sp)
    80005c7e:	6442                	ld	s0,16(sp)
    80005c80:	64a2                	ld	s1,8(sp)
    80005c82:	6105                	addi	sp,sp,32
    80005c84:	8082                	ret

0000000080005c86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c86:	1141                	addi	sp,sp,-16
    80005c88:	e406                	sd	ra,8(sp)
    80005c8a:	e022                	sd	s0,0(sp)
    80005c8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c8e:	479d                	li	a5,7
    80005c90:	04a7cc63          	blt	a5,a0,80005ce8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005c94:	0001c797          	auipc	a5,0x1c
    80005c98:	19c78793          	addi	a5,a5,412 # 80021e30 <disk>
    80005c9c:	97aa                	add	a5,a5,a0
    80005c9e:	0187c783          	lbu	a5,24(a5)
    80005ca2:	ebb9                	bnez	a5,80005cf8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ca4:	00451693          	slli	a3,a0,0x4
    80005ca8:	0001c797          	auipc	a5,0x1c
    80005cac:	18878793          	addi	a5,a5,392 # 80021e30 <disk>
    80005cb0:	6398                	ld	a4,0(a5)
    80005cb2:	9736                	add	a4,a4,a3
    80005cb4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005cb8:	6398                	ld	a4,0(a5)
    80005cba:	9736                	add	a4,a4,a3
    80005cbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005cc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005cc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	4705                	li	a4,1
    80005ccc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005cd0:	0001c517          	auipc	a0,0x1c
    80005cd4:	17850513          	addi	a0,a0,376 # 80021e48 <disk+0x18>
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	3e0080e7          	jalr	992(ra) # 800020b8 <wakeup>
}
    80005ce0:	60a2                	ld	ra,8(sp)
    80005ce2:	6402                	ld	s0,0(sp)
    80005ce4:	0141                	addi	sp,sp,16
    80005ce6:	8082                	ret
    panic("free_desc 1");
    80005ce8:	00003517          	auipc	a0,0x3
    80005cec:	a6850513          	addi	a0,a0,-1432 # 80008750 <syscalls+0x300>
    80005cf0:	ffffb097          	auipc	ra,0xffffb
    80005cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005cf8:	00003517          	auipc	a0,0x3
    80005cfc:	a6850513          	addi	a0,a0,-1432 # 80008760 <syscalls+0x310>
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	840080e7          	jalr	-1984(ra) # 80000540 <panic>

0000000080005d08 <virtio_disk_init>:
{
    80005d08:	1101                	addi	sp,sp,-32
    80005d0a:	ec06                	sd	ra,24(sp)
    80005d0c:	e822                	sd	s0,16(sp)
    80005d0e:	e426                	sd	s1,8(sp)
    80005d10:	e04a                	sd	s2,0(sp)
    80005d12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d14:	00003597          	auipc	a1,0x3
    80005d18:	a5c58593          	addi	a1,a1,-1444 # 80008770 <syscalls+0x320>
    80005d1c:	0001c517          	auipc	a0,0x1c
    80005d20:	23c50513          	addi	a0,a0,572 # 80021f58 <disk+0x128>
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	e22080e7          	jalr	-478(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d2c:	100017b7          	lui	a5,0x10001
    80005d30:	4398                	lw	a4,0(a5)
    80005d32:	2701                	sext.w	a4,a4
    80005d34:	747277b7          	lui	a5,0x74727
    80005d38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d3c:	14f71b63          	bne	a4,a5,80005e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d40:	100017b7          	lui	a5,0x10001
    80005d44:	43dc                	lw	a5,4(a5)
    80005d46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d48:	4709                	li	a4,2
    80005d4a:	14e79463          	bne	a5,a4,80005e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d4e:	100017b7          	lui	a5,0x10001
    80005d52:	479c                	lw	a5,8(a5)
    80005d54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d56:	12e79e63          	bne	a5,a4,80005e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d5a:	100017b7          	lui	a5,0x10001
    80005d5e:	47d8                	lw	a4,12(a5)
    80005d60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d62:	554d47b7          	lui	a5,0x554d4
    80005d66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d6a:	12f71463          	bne	a4,a5,80005e92 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d6e:	100017b7          	lui	a5,0x10001
    80005d72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d76:	4705                	li	a4,1
    80005d78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d7a:	470d                	li	a4,3
    80005d7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d7e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d80:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d84:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7ef>
    80005d88:	8f75                	and	a4,a4,a3
    80005d8a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d8c:	472d                	li	a4,11
    80005d8e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005d90:	5bbc                	lw	a5,112(a5)
    80005d92:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005d96:	8ba1                	andi	a5,a5,8
    80005d98:	10078563          	beqz	a5,80005ea2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d9c:	100017b7          	lui	a5,0x10001
    80005da0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005da4:	43fc                	lw	a5,68(a5)
    80005da6:	2781                	sext.w	a5,a5
    80005da8:	10079563          	bnez	a5,80005eb2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dac:	100017b7          	lui	a5,0x10001
    80005db0:	5bdc                	lw	a5,52(a5)
    80005db2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005db4:	10078763          	beqz	a5,80005ec2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005db8:	471d                	li	a4,7
    80005dba:	10f77c63          	bgeu	a4,a5,80005ed2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005dbe:	ffffb097          	auipc	ra,0xffffb
    80005dc2:	d28080e7          	jalr	-728(ra) # 80000ae6 <kalloc>
    80005dc6:	0001c497          	auipc	s1,0x1c
    80005dca:	06a48493          	addi	s1,s1,106 # 80021e30 <disk>
    80005dce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005dd0:	ffffb097          	auipc	ra,0xffffb
    80005dd4:	d16080e7          	jalr	-746(ra) # 80000ae6 <kalloc>
    80005dd8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005dda:	ffffb097          	auipc	ra,0xffffb
    80005dde:	d0c080e7          	jalr	-756(ra) # 80000ae6 <kalloc>
    80005de2:	87aa                	mv	a5,a0
    80005de4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005de6:	6088                	ld	a0,0(s1)
    80005de8:	cd6d                	beqz	a0,80005ee2 <virtio_disk_init+0x1da>
    80005dea:	0001c717          	auipc	a4,0x1c
    80005dee:	04e73703          	ld	a4,78(a4) # 80021e38 <disk+0x8>
    80005df2:	cb65                	beqz	a4,80005ee2 <virtio_disk_init+0x1da>
    80005df4:	c7fd                	beqz	a5,80005ee2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005df6:	6605                	lui	a2,0x1
    80005df8:	4581                	li	a1,0
    80005dfa:	ffffb097          	auipc	ra,0xffffb
    80005dfe:	ed8080e7          	jalr	-296(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e02:	0001c497          	auipc	s1,0x1c
    80005e06:	02e48493          	addi	s1,s1,46 # 80021e30 <disk>
    80005e0a:	6605                	lui	a2,0x1
    80005e0c:	4581                	li	a1,0
    80005e0e:	6488                	ld	a0,8(s1)
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	ec2080e7          	jalr	-318(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e18:	6605                	lui	a2,0x1
    80005e1a:	4581                	li	a1,0
    80005e1c:	6888                	ld	a0,16(s1)
    80005e1e:	ffffb097          	auipc	ra,0xffffb
    80005e22:	eb4080e7          	jalr	-332(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e26:	100017b7          	lui	a5,0x10001
    80005e2a:	4721                	li	a4,8
    80005e2c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e2e:	4098                	lw	a4,0(s1)
    80005e30:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e34:	40d8                	lw	a4,4(s1)
    80005e36:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e3a:	6498                	ld	a4,8(s1)
    80005e3c:	0007069b          	sext.w	a3,a4
    80005e40:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e44:	9701                	srai	a4,a4,0x20
    80005e46:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e4a:	6898                	ld	a4,16(s1)
    80005e4c:	0007069b          	sext.w	a3,a4
    80005e50:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005e54:	9701                	srai	a4,a4,0x20
    80005e56:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005e5a:	4705                	li	a4,1
    80005e5c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005e5e:	00e48c23          	sb	a4,24(s1)
    80005e62:	00e48ca3          	sb	a4,25(s1)
    80005e66:	00e48d23          	sb	a4,26(s1)
    80005e6a:	00e48da3          	sb	a4,27(s1)
    80005e6e:	00e48e23          	sb	a4,28(s1)
    80005e72:	00e48ea3          	sb	a4,29(s1)
    80005e76:	00e48f23          	sb	a4,30(s1)
    80005e7a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005e7e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e82:	0727a823          	sw	s2,112(a5)
}
    80005e86:	60e2                	ld	ra,24(sp)
    80005e88:	6442                	ld	s0,16(sp)
    80005e8a:	64a2                	ld	s1,8(sp)
    80005e8c:	6902                	ld	s2,0(sp)
    80005e8e:	6105                	addi	sp,sp,32
    80005e90:	8082                	ret
    panic("could not find virtio disk");
    80005e92:	00003517          	auipc	a0,0x3
    80005e96:	8ee50513          	addi	a0,a0,-1810 # 80008780 <syscalls+0x330>
    80005e9a:	ffffa097          	auipc	ra,0xffffa
    80005e9e:	6a6080e7          	jalr	1702(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ea2:	00003517          	auipc	a0,0x3
    80005ea6:	8fe50513          	addi	a0,a0,-1794 # 800087a0 <syscalls+0x350>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	90e50513          	addi	a0,a0,-1778 # 800087c0 <syscalls+0x370>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	91e50513          	addi	a0,a0,-1762 # 800087e0 <syscalls+0x390>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	92e50513          	addi	a0,a0,-1746 # 80008800 <syscalls+0x3b0>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	93e50513          	addi	a0,a0,-1730 # 80008820 <syscalls+0x3d0>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>

0000000080005ef2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ef2:	7119                	addi	sp,sp,-128
    80005ef4:	fc86                	sd	ra,120(sp)
    80005ef6:	f8a2                	sd	s0,112(sp)
    80005ef8:	f4a6                	sd	s1,104(sp)
    80005efa:	f0ca                	sd	s2,96(sp)
    80005efc:	ecce                	sd	s3,88(sp)
    80005efe:	e8d2                	sd	s4,80(sp)
    80005f00:	e4d6                	sd	s5,72(sp)
    80005f02:	e0da                	sd	s6,64(sp)
    80005f04:	fc5e                	sd	s7,56(sp)
    80005f06:	f862                	sd	s8,48(sp)
    80005f08:	f466                	sd	s9,40(sp)
    80005f0a:	f06a                	sd	s10,32(sp)
    80005f0c:	ec6e                	sd	s11,24(sp)
    80005f0e:	0100                	addi	s0,sp,128
    80005f10:	8aaa                	mv	s5,a0
    80005f12:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f14:	00c52d03          	lw	s10,12(a0)
    80005f18:	001d1d1b          	slliw	s10,s10,0x1
    80005f1c:	1d02                	slli	s10,s10,0x20
    80005f1e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f22:	0001c517          	auipc	a0,0x1c
    80005f26:	03650513          	addi	a0,a0,54 # 80021f58 <disk+0x128>
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	cac080e7          	jalr	-852(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f32:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f34:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f36:	0001cb97          	auipc	s7,0x1c
    80005f3a:	efab8b93          	addi	s7,s7,-262 # 80021e30 <disk>
  for(int i = 0; i < 3; i++){
    80005f3e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f40:	0001cc97          	auipc	s9,0x1c
    80005f44:	018c8c93          	addi	s9,s9,24 # 80021f58 <disk+0x128>
    80005f48:	a08d                	j	80005faa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005f4a:	00fb8733          	add	a4,s7,a5
    80005f4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f54:	0207c563          	bltz	a5,80005f7e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005f58:	2905                	addiw	s2,s2,1
    80005f5a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005f5c:	05690c63          	beq	s2,s6,80005fb4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005f60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f62:	0001c717          	auipc	a4,0x1c
    80005f66:	ece70713          	addi	a4,a4,-306 # 80021e30 <disk>
    80005f6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f6c:	01874683          	lbu	a3,24(a4)
    80005f70:	fee9                	bnez	a3,80005f4a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005f72:	2785                	addiw	a5,a5,1
    80005f74:	0705                	addi	a4,a4,1
    80005f76:	fe979be3          	bne	a5,s1,80005f6c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f7e:	01205d63          	blez	s2,80005f98 <virtio_disk_rw+0xa6>
    80005f82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f84:	000a2503          	lw	a0,0(s4)
    80005f88:	00000097          	auipc	ra,0x0
    80005f8c:	cfe080e7          	jalr	-770(ra) # 80005c86 <free_desc>
      for(int j = 0; j < i; j++)
    80005f90:	2d85                	addiw	s11,s11,1
    80005f92:	0a11                	addi	s4,s4,4
    80005f94:	ff2d98e3          	bne	s11,s2,80005f84 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f98:	85e6                	mv	a1,s9
    80005f9a:	0001c517          	auipc	a0,0x1c
    80005f9e:	eae50513          	addi	a0,a0,-338 # 80021e48 <disk+0x18>
    80005fa2:	ffffc097          	auipc	ra,0xffffc
    80005fa6:	0b2080e7          	jalr	178(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    80005faa:	f8040a13          	addi	s4,s0,-128
{
    80005fae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fb0:	894e                	mv	s2,s3
    80005fb2:	b77d                	j	80005f60 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fb4:	f8042503          	lw	a0,-128(s0)
    80005fb8:	00a50713          	addi	a4,a0,10
    80005fbc:	0712                	slli	a4,a4,0x4

  if(write)
    80005fbe:	0001c797          	auipc	a5,0x1c
    80005fc2:	e7278793          	addi	a5,a5,-398 # 80021e30 <disk>
    80005fc6:	00e786b3          	add	a3,a5,a4
    80005fca:	01803633          	snez	a2,s8
    80005fce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fd0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005fd4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fd8:	f6070613          	addi	a2,a4,-160
    80005fdc:	6394                	ld	a3,0(a5)
    80005fde:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fe0:	00870593          	addi	a1,a4,8
    80005fe4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fe6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fe8:	0007b803          	ld	a6,0(a5)
    80005fec:	9642                	add	a2,a2,a6
    80005fee:	46c1                	li	a3,16
    80005ff0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005ff2:	4585                	li	a1,1
    80005ff4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80005ff8:	f8442683          	lw	a3,-124(s0)
    80005ffc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006000:	0692                	slli	a3,a3,0x4
    80006002:	9836                	add	a6,a6,a3
    80006004:	058a8613          	addi	a2,s5,88
    80006008:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000600c:	0007b803          	ld	a6,0(a5)
    80006010:	96c2                	add	a3,a3,a6
    80006012:	40000613          	li	a2,1024
    80006016:	c690                	sw	a2,8(a3)
  if(write)
    80006018:	001c3613          	seqz	a2,s8
    8000601c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006020:	00166613          	ori	a2,a2,1
    80006024:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006028:	f8842603          	lw	a2,-120(s0)
    8000602c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006030:	00250693          	addi	a3,a0,2
    80006034:	0692                	slli	a3,a3,0x4
    80006036:	96be                	add	a3,a3,a5
    80006038:	58fd                	li	a7,-1
    8000603a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000603e:	0612                	slli	a2,a2,0x4
    80006040:	9832                	add	a6,a6,a2
    80006042:	f9070713          	addi	a4,a4,-112
    80006046:	973e                	add	a4,a4,a5
    80006048:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000604c:	6398                	ld	a4,0(a5)
    8000604e:	9732                	add	a4,a4,a2
    80006050:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006052:	4609                	li	a2,2
    80006054:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006058:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000605c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006060:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006064:	6794                	ld	a3,8(a5)
    80006066:	0026d703          	lhu	a4,2(a3)
    8000606a:	8b1d                	andi	a4,a4,7
    8000606c:	0706                	slli	a4,a4,0x1
    8000606e:	96ba                	add	a3,a3,a4
    80006070:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006074:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006078:	6798                	ld	a4,8(a5)
    8000607a:	00275783          	lhu	a5,2(a4)
    8000607e:	2785                	addiw	a5,a5,1
    80006080:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006084:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006090:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006094:	0001c917          	auipc	s2,0x1c
    80006098:	ec490913          	addi	s2,s2,-316 # 80021f58 <disk+0x128>
  while(b->disk == 1) {
    8000609c:	4485                	li	s1,1
    8000609e:	00b79c63          	bne	a5,a1,800060b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800060a2:	85ca                	mv	a1,s2
    800060a4:	8556                	mv	a0,s5
    800060a6:	ffffc097          	auipc	ra,0xffffc
    800060aa:	fae080e7          	jalr	-82(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800060ae:	004aa783          	lw	a5,4(s5)
    800060b2:	fe9788e3          	beq	a5,s1,800060a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800060b6:	f8042903          	lw	s2,-128(s0)
    800060ba:	00290713          	addi	a4,s2,2
    800060be:	0712                	slli	a4,a4,0x4
    800060c0:	0001c797          	auipc	a5,0x1c
    800060c4:	d7078793          	addi	a5,a5,-656 # 80021e30 <disk>
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800060ce:	0001c997          	auipc	s3,0x1c
    800060d2:	d6298993          	addi	s3,s3,-670 # 80021e30 <disk>
    800060d6:	00491713          	slli	a4,s2,0x4
    800060da:	0009b783          	ld	a5,0(s3)
    800060de:	97ba                	add	a5,a5,a4
    800060e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060e4:	854a                	mv	a0,s2
    800060e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	b9c080e7          	jalr	-1124(ra) # 80005c86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060f2:	8885                	andi	s1,s1,1
    800060f4:	f0ed                	bnez	s1,800060d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060f6:	0001c517          	auipc	a0,0x1c
    800060fa:	e6250513          	addi	a0,a0,-414 # 80021f58 <disk+0x128>
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	b8c080e7          	jalr	-1140(ra) # 80000c8a <release>
}
    80006106:	70e6                	ld	ra,120(sp)
    80006108:	7446                	ld	s0,112(sp)
    8000610a:	74a6                	ld	s1,104(sp)
    8000610c:	7906                	ld	s2,96(sp)
    8000610e:	69e6                	ld	s3,88(sp)
    80006110:	6a46                	ld	s4,80(sp)
    80006112:	6aa6                	ld	s5,72(sp)
    80006114:	6b06                	ld	s6,64(sp)
    80006116:	7be2                	ld	s7,56(sp)
    80006118:	7c42                	ld	s8,48(sp)
    8000611a:	7ca2                	ld	s9,40(sp)
    8000611c:	7d02                	ld	s10,32(sp)
    8000611e:	6de2                	ld	s11,24(sp)
    80006120:	6109                	addi	sp,sp,128
    80006122:	8082                	ret

0000000080006124 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006124:	1101                	addi	sp,sp,-32
    80006126:	ec06                	sd	ra,24(sp)
    80006128:	e822                	sd	s0,16(sp)
    8000612a:	e426                	sd	s1,8(sp)
    8000612c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000612e:	0001c497          	auipc	s1,0x1c
    80006132:	d0248493          	addi	s1,s1,-766 # 80021e30 <disk>
    80006136:	0001c517          	auipc	a0,0x1c
    8000613a:	e2250513          	addi	a0,a0,-478 # 80021f58 <disk+0x128>
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006146:	10001737          	lui	a4,0x10001
    8000614a:	533c                	lw	a5,96(a4)
    8000614c:	8b8d                	andi	a5,a5,3
    8000614e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006150:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006154:	689c                	ld	a5,16(s1)
    80006156:	0204d703          	lhu	a4,32(s1)
    8000615a:	0027d783          	lhu	a5,2(a5)
    8000615e:	04f70863          	beq	a4,a5,800061ae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006162:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006166:	6898                	ld	a4,16(s1)
    80006168:	0204d783          	lhu	a5,32(s1)
    8000616c:	8b9d                	andi	a5,a5,7
    8000616e:	078e                	slli	a5,a5,0x3
    80006170:	97ba                	add	a5,a5,a4
    80006172:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006174:	00278713          	addi	a4,a5,2
    80006178:	0712                	slli	a4,a4,0x4
    8000617a:	9726                	add	a4,a4,s1
    8000617c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006180:	e721                	bnez	a4,800061c8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006182:	0789                	addi	a5,a5,2
    80006184:	0792                	slli	a5,a5,0x4
    80006186:	97a6                	add	a5,a5,s1
    80006188:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000618a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000618e:	ffffc097          	auipc	ra,0xffffc
    80006192:	f2a080e7          	jalr	-214(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006196:	0204d783          	lhu	a5,32(s1)
    8000619a:	2785                	addiw	a5,a5,1
    8000619c:	17c2                	slli	a5,a5,0x30
    8000619e:	93c1                	srli	a5,a5,0x30
    800061a0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061a4:	6898                	ld	a4,16(s1)
    800061a6:	00275703          	lhu	a4,2(a4)
    800061aa:	faf71ce3          	bne	a4,a5,80006162 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800061ae:	0001c517          	auipc	a0,0x1c
    800061b2:	daa50513          	addi	a0,a0,-598 # 80021f58 <disk+0x128>
    800061b6:	ffffb097          	auipc	ra,0xffffb
    800061ba:	ad4080e7          	jalr	-1324(ra) # 80000c8a <release>
}
    800061be:	60e2                	ld	ra,24(sp)
    800061c0:	6442                	ld	s0,16(sp)
    800061c2:	64a2                	ld	s1,8(sp)
    800061c4:	6105                	addi	sp,sp,32
    800061c6:	8082                	ret
      panic("virtio_disk_intr status");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	67050513          	addi	a0,a0,1648 # 80008838 <syscalls+0x3e8>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	370080e7          	jalr	880(ra) # 80000540 <panic>
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
