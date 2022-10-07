
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae013103          	ld	sp,-1312(sp) # 80008ae0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	af070713          	addi	a4,a4,-1296 # 80008b40 <timer_scratch>
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
    80000066:	cae78793          	addi	a5,a5,-850 # 80005d10 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc44f>
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
    8000012e:	394080e7          	jalr	916(ra) # 800024be <either_copyin>
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
    8000018e:	af650513          	addi	a0,a0,-1290 # 80010c80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	ae648493          	addi	s1,s1,-1306 # 80010c80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b7690913          	addi	s2,s2,-1162 # 80010d18 <cons+0x98>
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
    800001cc:	140080e7          	jalr	320(ra) # 80002308 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e8a080e7          	jalr	-374(ra) # 80002060 <sleep>
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
    80000216:	256080e7          	jalr	598(ra) # 80002468 <either_copyout>
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
    8000022a:	a5a50513          	addi	a0,a0,-1446 # 80010c80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a4450513          	addi	a0,a0,-1468 # 80010c80 <cons>
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
    80000276:	aaf72323          	sw	a5,-1370(a4) # 80010d18 <cons+0x98>
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
    800002d0:	9b450513          	addi	a0,a0,-1612 # 80010c80 <cons>
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
    800002f6:	222080e7          	jalr	546(ra) # 80002514 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	98650513          	addi	a0,a0,-1658 # 80010c80 <cons>
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
    80000322:	96270713          	addi	a4,a4,-1694 # 80010c80 <cons>
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
    8000034c:	93878793          	addi	a5,a5,-1736 # 80010c80 <cons>
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
    8000037a:	9a27a783          	lw	a5,-1630(a5) # 80010d18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	8f670713          	addi	a4,a4,-1802 # 80010c80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	8e648493          	addi	s1,s1,-1818 # 80010c80 <cons>
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
    800003da:	8aa70713          	addi	a4,a4,-1878 # 80010c80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	92f72a23          	sw	a5,-1740(a4) # 80010d20 <cons+0xa0>
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
    80000416:	86e78793          	addi	a5,a5,-1938 # 80010c80 <cons>
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
    8000043a:	8ec7a323          	sw	a2,-1818(a5) # 80010d1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	8da50513          	addi	a0,a0,-1830 # 80010d18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c7e080e7          	jalr	-898(ra) # 800020c4 <wakeup>
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
    80000464:	82050513          	addi	a0,a0,-2016 # 80010c80 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	da078793          	addi	a5,a5,-608 # 80021218 <devsw>
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
    80000550:	7e07aa23          	sw	zero,2036(a5) # 80010d40 <pr+0x18>
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
    80000584:	58f72023          	sw	a5,1408(a4) # 80008b00 <panicked>
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
    800005c0:	784dad83          	lw	s11,1924(s11) # 80010d40 <pr+0x18>
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
    800005fe:	72e50513          	addi	a0,a0,1838 # 80010d28 <pr>
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
    8000075c:	5d050513          	addi	a0,a0,1488 # 80010d28 <pr>
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
    80000778:	5b448493          	addi	s1,s1,1460 # 80010d28 <pr>
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
    800007d8:	57450513          	addi	a0,a0,1396 # 80010d48 <uart_tx_lock>
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
    80000804:	3007a783          	lw	a5,768(a5) # 80008b00 <panicked>
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
    8000083c:	2d07b783          	ld	a5,720(a5) # 80008b08 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	2d073703          	ld	a4,720(a4) # 80008b10 <uart_tx_w>
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
    80000866:	4e6a0a13          	addi	s4,s4,1254 # 80010d48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	29e48493          	addi	s1,s1,670 # 80008b08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	29e98993          	addi	s3,s3,670 # 80008b10 <uart_tx_w>
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
    80000898:	830080e7          	jalr	-2000(ra) # 800020c4 <wakeup>
    
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
    800008d4:	47850513          	addi	a0,a0,1144 # 80010d48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2207a783          	lw	a5,544(a5) # 80008b00 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	22673703          	ld	a4,550(a4) # 80008b10 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2167b783          	ld	a5,534(a5) # 80008b08 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	44a98993          	addi	s3,s3,1098 # 80010d48 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	20248493          	addi	s1,s1,514 # 80008b08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	20290913          	addi	s2,s2,514 # 80008b10 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	742080e7          	jalr	1858(ra) # 80002060 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	41448493          	addi	s1,s1,1044 # 80010d48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	1ce7b423          	sd	a4,456(a5) # 80008b10 <uart_tx_w>
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
    800009be:	38e48493          	addi	s1,s1,910 # 80010d48 <uart_tx_lock>
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
    80000a00:	9b478793          	addi	a5,a5,-1612 # 800223b0 <end>
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
    80000a20:	36490913          	addi	s2,s2,868 # 80010d80 <kmem>
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
    80000abe:	2c650513          	addi	a0,a0,710 # 80010d80 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	8e250513          	addi	a0,a0,-1822 # 800223b0 <end>
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
    80000af4:	29048493          	addi	s1,s1,656 # 80010d80 <kmem>
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
    80000b0c:	27850513          	addi	a0,a0,632 # 80010d80 <kmem>
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
    80000b38:	24c50513          	addi	a0,a0,588 # 80010d80 <kmem>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcc51>
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
    80000e8c:	c9070713          	addi	a4,a4,-880 # 80008b18 <started>
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
    80000ec2:	7ba080e7          	jalr	1978(ra) # 80002678 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e8a080e7          	jalr	-374(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe0080e7          	jalr	-32(ra) # 80001eae <scheduler>
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
    80000f3a:	71a080e7          	jalr	1818(ra) # 80002650 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	73a080e7          	jalr	1850(ra) # 80002678 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	df4080e7          	jalr	-524(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e02080e7          	jalr	-510(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f96080e7          	jalr	-106(ra) # 80002eec <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	636080e7          	jalr	1590(ra) # 80003594 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5dc080e7          	jalr	1500(ra) # 80004542 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	eea080e7          	jalr	-278(ra) # 80005e58 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d12080e7          	jalr	-750(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	b8f72a23          	sw	a5,-1132(a4) # 80008b18 <started>
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
    80000f9c:	b887b783          	ld	a5,-1144(a5) # 80008b20 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcc47>
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
    80001254:	00008797          	auipc	a5,0x8
    80001258:	8ca7b623          	sd	a0,-1844(a5) # 80008b20 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcc50>
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
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	98448493          	addi	s1,s1,-1660 # 800111d0 <proc>
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
    8000186a:	76aa0a13          	addi	s4,s4,1898 # 80016fd0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
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
    800018a0:	17848493          	addi	s1,s1,376
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
    800018ec:	4b850513          	addi	a0,a0,1208 # 80010da0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	4b850513          	addi	a0,a0,1208 # 80010db8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	8c048493          	addi	s1,s1,-1856 # 800111d0 <proc>
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
    80001936:	69e98993          	addi	s3,s3,1694 # 80016fd0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17848493          	addi	s1,s1,376
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
    800019a0:	43450513          	addi	a0,a0,1076 # 80010dd0 <cpus>
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
    800019c8:	3dc70713          	addi	a4,a4,988 # 80010da0 <pid_lock>
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
    80001a00:	f247a783          	lw	a5,-220(a5) # 80008920 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	c8a080e7          	jalr	-886(ra) # 80002690 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f007a523          	sw	zero,-246(a5) # 80008920 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	af4080e7          	jalr	-1292(ra) # 80003514 <fsinit>
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
    80001a3a:	36a90913          	addi	s2,s2,874 # 80010da0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	edc78793          	addi	a5,a5,-292 # 80008924 <nextpid>
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
  p->strace_bit = 0;
    80001bac:	1604a823          	sw	zero,368(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	0000f497          	auipc	s1,0xf
    80001bca:	60a48493          	addi	s1,s1,1546 # 800111d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	40290913          	addi	s2,s2,1026 # 80016fd0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	ffe080e7          	jalr	-2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0a4080e7          	jalr	164(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17848493          	addi	s1,s1,376
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e30080e7          	jalr	-464(ra) # 80001a2a <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	ede080e7          	jalr	-290(ra) # 80000ae6 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	f0a8                	sd	a0,96(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e58080e7          	jalr	-424(ra) # 80001a70 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06848513          	addi	a0,s1,104
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0a2080e7          	jalr	162(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	dac78793          	addi	a5,a5,-596 # 800019e4 <forkret>
    80001c40:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f8bc                	sd	a5,112(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f04080e7          	jalr	-252(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	026080e7          	jalr	38(ra) # 80000c8a <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	eec080e7          	jalr	-276(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	00e080e7          	jalr	14(ra) # 80000c8a <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	e8a7b623          	sd	a0,-372(a5) # 80008b28 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	c8858593          	addi	a1,a1,-888 # 80008930 <initcode>
    80001cb0:	6d28                	ld	a0,88(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6a4080e7          	jalr	1700(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	70b8                	ld	a4,96(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	70b8                	ld	a4,96(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	16048513          	addi	a0,s1,352
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	146080e7          	jalr	326(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	258080e7          	jalr	600(ra) # 80003f3e <namei>
    80001cee:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	f92080e7          	jalr	-110(ra) # 80000c8a <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c94080e7          	jalr	-876(ra) # 800019ac <myproc>
    80001d20:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d24:	01204c63          	bgtz	s2,80001d3c <growproc+0x32>
  } else if(n < 0){
    80001d28:	02094663          	bltz	s2,80001d54 <growproc+0x4a>
  p->sz = sz;
    80001d2c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2e:	4501                	li	a0,0
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d3c:	4691                	li	a3,4
    80001d3e:	00b90633          	add	a2,s2,a1
    80001d42:	6d28                	ld	a0,88(a0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	6cc080e7          	jalr	1740(ra) # 80001410 <uvmalloc>
    80001d4c:	85aa                	mv	a1,a0
    80001d4e:	fd79                	bnez	a0,80001d2c <growproc+0x22>
      return -1;
    80001d50:	557d                	li	a0,-1
    80001d52:	bff9                	j	80001d30 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6d28                	ld	a0,88(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	66e080e7          	jalr	1646(ra) # 800013c8 <uvmdealloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	b7e1                	j	80001d2c <growproc+0x22>

0000000080001d66 <fork>:
{
    80001d66:	7139                	addi	sp,sp,-64
    80001d68:	fc06                	sd	ra,56(sp)
    80001d6a:	f822                	sd	s0,48(sp)
    80001d6c:	f426                	sd	s1,40(sp)
    80001d6e:	f04a                	sd	s2,32(sp)
    80001d70:	ec4e                	sd	s3,24(sp)
    80001d72:	e852                	sd	s4,16(sp)
    80001d74:	e456                	sd	s5,8(sp)
    80001d76:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	c34080e7          	jalr	-972(ra) # 800019ac <myproc>
    80001d80:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	e38080e7          	jalr	-456(ra) # 80001bba <allocproc>
    80001d8a:	12050063          	beqz	a0,80001eaa <fork+0x144>
    80001d8e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d90:	048ab603          	ld	a2,72(s5)
    80001d94:	6d2c                	ld	a1,88(a0)
    80001d96:	058ab503          	ld	a0,88(s5)
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	7ce080e7          	jalr	1998(ra) # 80001568 <uvmcopy>
    80001da2:	04054863          	bltz	a0,80001df2 <fork+0x8c>
  np->sz = p->sz;
    80001da6:	048ab783          	ld	a5,72(s5)
    80001daa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dae:	060ab683          	ld	a3,96(s5)
    80001db2:	87b6                	mv	a5,a3
    80001db4:	0609b703          	ld	a4,96(s3)
    80001db8:	12068693          	addi	a3,a3,288
    80001dbc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc0:	6788                	ld	a0,8(a5)
    80001dc2:	6b8c                	ld	a1,16(a5)
    80001dc4:	6f90                	ld	a2,24(a5)
    80001dc6:	01073023          	sd	a6,0(a4)
    80001dca:	e708                	sd	a0,8(a4)
    80001dcc:	eb0c                	sd	a1,16(a4)
    80001dce:	ef10                	sd	a2,24(a4)
    80001dd0:	02078793          	addi	a5,a5,32
    80001dd4:	02070713          	addi	a4,a4,32
    80001dd8:	fed792e3          	bne	a5,a3,80001dbc <fork+0x56>
  np->trapframe->a0 = 0;
    80001ddc:	0609b783          	ld	a5,96(s3)
    80001de0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de4:	0d8a8493          	addi	s1,s5,216
    80001de8:	0d898913          	addi	s2,s3,216
    80001dec:	158a8a13          	addi	s4,s5,344
    80001df0:	a00d                	j	80001e12 <fork+0xac>
    freeproc(np);
    80001df2:	854e                	mv	a0,s3
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	d6a080e7          	jalr	-662(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001dfc:	854e                	mv	a0,s3
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	e8c080e7          	jalr	-372(ra) # 80000c8a <release>
    return -1;
    80001e06:	597d                	li	s2,-1
    80001e08:	a079                	j	80001e96 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e0a:	04a1                	addi	s1,s1,8
    80001e0c:	0921                	addi	s2,s2,8
    80001e0e:	01448b63          	beq	s1,s4,80001e24 <fork+0xbe>
    if(p->ofile[i])
    80001e12:	6088                	ld	a0,0(s1)
    80001e14:	d97d                	beqz	a0,80001e0a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	7be080e7          	jalr	1982(ra) # 800045d4 <filedup>
    80001e1e:	00a93023          	sd	a0,0(s2)
    80001e22:	b7e5                	j	80001e0a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e24:	158ab503          	ld	a0,344(s5)
    80001e28:	00002097          	auipc	ra,0x2
    80001e2c:	92c080e7          	jalr	-1748(ra) # 80003754 <idup>
    80001e30:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e34:	4641                	li	a2,16
    80001e36:	160a8593          	addi	a1,s5,352
    80001e3a:	16098513          	addi	a0,s3,352
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	fde080e7          	jalr	-34(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e46:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e4a:	854e                	mv	a0,s3
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e54:	0000f497          	auipc	s1,0xf
    80001e58:	f6448493          	addi	s1,s1,-156 # 80010db8 <wait_lock>
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	d78080e7          	jalr	-648(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e66:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	d60080e7          	jalr	-672(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7e:	478d                	li	a5,3
    80001e80:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e84:	854e                	mv	a0,s3
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
  np->strace_bit = p->strace_bit;
    80001e8e:	170aa783          	lw	a5,368(s5)
    80001e92:	16f9a823          	sw	a5,368(s3)
}
    80001e96:	854a                	mv	a0,s2
    80001e98:	70e2                	ld	ra,56(sp)
    80001e9a:	7442                	ld	s0,48(sp)
    80001e9c:	74a2                	ld	s1,40(sp)
    80001e9e:	7902                	ld	s2,32(sp)
    80001ea0:	69e2                	ld	s3,24(sp)
    80001ea2:	6a42                	ld	s4,16(sp)
    80001ea4:	6aa2                	ld	s5,8(sp)
    80001ea6:	6121                	addi	sp,sp,64
    80001ea8:	8082                	ret
    return -1;
    80001eaa:	597d                	li	s2,-1
    80001eac:	b7ed                	j	80001e96 <fork+0x130>

0000000080001eae <scheduler>:
{
    80001eae:	7139                	addi	sp,sp,-64
    80001eb0:	fc06                	sd	ra,56(sp)
    80001eb2:	f822                	sd	s0,48(sp)
    80001eb4:	f426                	sd	s1,40(sp)
    80001eb6:	f04a                	sd	s2,32(sp)
    80001eb8:	ec4e                	sd	s3,24(sp)
    80001eba:	e852                	sd	s4,16(sp)
    80001ebc:	e456                	sd	s5,8(sp)
    80001ebe:	e05a                	sd	s6,0(sp)
    80001ec0:	0080                	addi	s0,sp,64
    80001ec2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec6:	00779a93          	slli	s5,a5,0x7
    80001eca:	0000f717          	auipc	a4,0xf
    80001ece:	ed670713          	addi	a4,a4,-298 # 80010da0 <pid_lock>
    80001ed2:	9756                	add	a4,a4,s5
    80001ed4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed8:	0000f717          	auipc	a4,0xf
    80001edc:	f0070713          	addi	a4,a4,-256 # 80010dd8 <cpus+0x8>
    80001ee0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee2:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee4:	4b11                	li	s6,4
        c->proc = p;
    80001ee6:	079e                	slli	a5,a5,0x7
    80001ee8:	0000fa17          	auipc	s4,0xf
    80001eec:	eb8a0a13          	addi	s4,s4,-328 # 80010da0 <pid_lock>
    80001ef0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef2:	00015917          	auipc	s2,0x15
    80001ef6:	0de90913          	addi	s2,s2,222 # 80016fd0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001efa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f02:	10079073          	csrw	sstatus,a5
    80001f06:	0000f497          	auipc	s1,0xf
    80001f0a:	2ca48493          	addi	s1,s1,714 # 800111d0 <proc>
    80001f0e:	a811                	j	80001f22 <scheduler+0x74>
      release(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d78080e7          	jalr	-648(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f1a:	17848493          	addi	s1,s1,376
    80001f1e:	fd248ee3          	beq	s1,s2,80001efa <scheduler+0x4c>
      acquire(&p->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	cb2080e7          	jalr	-846(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f2c:	4c9c                	lw	a5,24(s1)
    80001f2e:	ff3791e3          	bne	a5,s3,80001f10 <scheduler+0x62>
        p->state = RUNNING;
    80001f32:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f36:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f3a:	06848593          	addi	a1,s1,104
    80001f3e:	8556                	mv	a0,s5
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	6a6080e7          	jalr	1702(ra) # 800025e6 <swtch>
        c->proc = 0;
    80001f48:	020a3823          	sd	zero,48(s4)
    80001f4c:	b7d1                	j	80001f10 <scheduler+0x62>

0000000080001f4e <sched>:
{
    80001f4e:	7179                	addi	sp,sp,-48
    80001f50:	f406                	sd	ra,40(sp)
    80001f52:	f022                	sd	s0,32(sp)
    80001f54:	ec26                	sd	s1,24(sp)
    80001f56:	e84a                	sd	s2,16(sp)
    80001f58:	e44e                	sd	s3,8(sp)
    80001f5a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	a50080e7          	jalr	-1456(ra) # 800019ac <myproc>
    80001f64:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	bf6080e7          	jalr	-1034(ra) # 80000b5c <holding>
    80001f6e:	c93d                	beqz	a0,80001fe4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f70:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f72:	2781                	sext.w	a5,a5
    80001f74:	079e                	slli	a5,a5,0x7
    80001f76:	0000f717          	auipc	a4,0xf
    80001f7a:	e2a70713          	addi	a4,a4,-470 # 80010da0 <pid_lock>
    80001f7e:	97ba                	add	a5,a5,a4
    80001f80:	0a87a703          	lw	a4,168(a5)
    80001f84:	4785                	li	a5,1
    80001f86:	06f71763          	bne	a4,a5,80001ff4 <sched+0xa6>
  if(p->state == RUNNING)
    80001f8a:	4c98                	lw	a4,24(s1)
    80001f8c:	4791                	li	a5,4
    80001f8e:	06f70b63          	beq	a4,a5,80002004 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f98:	efb5                	bnez	a5,80002014 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9c:	0000f917          	auipc	s2,0xf
    80001fa0:	e0490913          	addi	s2,s2,-508 # 80010da0 <pid_lock>
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	97ca                	add	a5,a5,s2
    80001faa:	0ac7a983          	lw	s3,172(a5)
    80001fae:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb0:	2781                	sext.w	a5,a5
    80001fb2:	079e                	slli	a5,a5,0x7
    80001fb4:	0000f597          	auipc	a1,0xf
    80001fb8:	e2458593          	addi	a1,a1,-476 # 80010dd8 <cpus+0x8>
    80001fbc:	95be                	add	a1,a1,a5
    80001fbe:	06848513          	addi	a0,s1,104
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	624080e7          	jalr	1572(ra) # 800025e6 <swtch>
    80001fca:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fcc:	2781                	sext.w	a5,a5
    80001fce:	079e                	slli	a5,a5,0x7
    80001fd0:	993e                	add	s2,s2,a5
    80001fd2:	0b392623          	sw	s3,172(s2)
}
    80001fd6:	70a2                	ld	ra,40(sp)
    80001fd8:	7402                	ld	s0,32(sp)
    80001fda:	64e2                	ld	s1,24(sp)
    80001fdc:	6942                	ld	s2,16(sp)
    80001fde:	69a2                	ld	s3,8(sp)
    80001fe0:	6145                	addi	sp,sp,48
    80001fe2:	8082                	ret
    panic("sched p->lock");
    80001fe4:	00006517          	auipc	a0,0x6
    80001fe8:	23450513          	addi	a0,a0,564 # 80008218 <digits+0x1d8>
    80001fec:	ffffe097          	auipc	ra,0xffffe
    80001ff0:	554080e7          	jalr	1364(ra) # 80000540 <panic>
    panic("sched locks");
    80001ff4:	00006517          	auipc	a0,0x6
    80001ff8:	23450513          	addi	a0,a0,564 # 80008228 <digits+0x1e8>
    80001ffc:	ffffe097          	auipc	ra,0xffffe
    80002000:	544080e7          	jalr	1348(ra) # 80000540 <panic>
    panic("sched running");
    80002004:	00006517          	auipc	a0,0x6
    80002008:	23450513          	addi	a0,a0,564 # 80008238 <digits+0x1f8>
    8000200c:	ffffe097          	auipc	ra,0xffffe
    80002010:	534080e7          	jalr	1332(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002014:	00006517          	auipc	a0,0x6
    80002018:	23450513          	addi	a0,a0,564 # 80008248 <digits+0x208>
    8000201c:	ffffe097          	auipc	ra,0xffffe
    80002020:	524080e7          	jalr	1316(ra) # 80000540 <panic>

0000000080002024 <yield>:
{
    80002024:	1101                	addi	sp,sp,-32
    80002026:	ec06                	sd	ra,24(sp)
    80002028:	e822                	sd	s0,16(sp)
    8000202a:	e426                	sd	s1,8(sp)
    8000202c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	97e080e7          	jalr	-1666(ra) # 800019ac <myproc>
    80002036:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	b9e080e7          	jalr	-1122(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002040:	478d                	li	a5,3
    80002042:	cc9c                	sw	a5,24(s1)
  sched();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	f0a080e7          	jalr	-246(ra) # 80001f4e <sched>
  release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
}
    80002056:	60e2                	ld	ra,24(sp)
    80002058:	6442                	ld	s0,16(sp)
    8000205a:	64a2                	ld	s1,8(sp)
    8000205c:	6105                	addi	sp,sp,32
    8000205e:	8082                	ret

0000000080002060 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002060:	7179                	addi	sp,sp,-48
    80002062:	f406                	sd	ra,40(sp)
    80002064:	f022                	sd	s0,32(sp)
    80002066:	ec26                	sd	s1,24(sp)
    80002068:	e84a                	sd	s2,16(sp)
    8000206a:	e44e                	sd	s3,8(sp)
    8000206c:	1800                	addi	s0,sp,48
    8000206e:	89aa                	mv	s3,a0
    80002070:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	93a080e7          	jalr	-1734(ra) # 800019ac <myproc>
    8000207a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b5a080e7          	jalr	-1190(ra) # 80000bd6 <acquire>
  release(lk);
    80002084:	854a                	mv	a0,s2
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000208e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002092:	4789                	li	a5,2
    80002094:	cc9c                	sw	a5,24(s1)

  sched();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	eb8080e7          	jalr	-328(ra) # 80001f4e <sched>

  // Tidy up.
  p->chan = 0;
    8000209e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	be6080e7          	jalr	-1050(ra) # 80000c8a <release>
  acquire(lk);
    800020ac:	854a                	mv	a0,s2
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b28080e7          	jalr	-1240(ra) # 80000bd6 <acquire>
}
    800020b6:	70a2                	ld	ra,40(sp)
    800020b8:	7402                	ld	s0,32(sp)
    800020ba:	64e2                	ld	s1,24(sp)
    800020bc:	6942                	ld	s2,16(sp)
    800020be:	69a2                	ld	s3,8(sp)
    800020c0:	6145                	addi	sp,sp,48
    800020c2:	8082                	ret

00000000800020c4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020c4:	7139                	addi	sp,sp,-64
    800020c6:	fc06                	sd	ra,56(sp)
    800020c8:	f822                	sd	s0,48(sp)
    800020ca:	f426                	sd	s1,40(sp)
    800020cc:	f04a                	sd	s2,32(sp)
    800020ce:	ec4e                	sd	s3,24(sp)
    800020d0:	e852                	sd	s4,16(sp)
    800020d2:	e456                	sd	s5,8(sp)
    800020d4:	0080                	addi	s0,sp,64
    800020d6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	0000f497          	auipc	s1,0xf
    800020dc:	0f848493          	addi	s1,s1,248 # 800111d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020e0:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020e2:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e4:	00015917          	auipc	s2,0x15
    800020e8:	eec90913          	addi	s2,s2,-276 # 80016fd0 <tickslock>
    800020ec:	a811                	j	80002100 <wakeup+0x3c>
      }
      release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b9a080e7          	jalr	-1126(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f8:	17848493          	addi	s1,s1,376
    800020fc:	03248663          	beq	s1,s2,80002128 <wakeup+0x64>
    if(p != myproc()){
    80002100:	00000097          	auipc	ra,0x0
    80002104:	8ac080e7          	jalr	-1876(ra) # 800019ac <myproc>
    80002108:	fea488e3          	beq	s1,a0,800020f8 <wakeup+0x34>
      acquire(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002116:	4c9c                	lw	a5,24(s1)
    80002118:	fd379be3          	bne	a5,s3,800020ee <wakeup+0x2a>
    8000211c:	709c                	ld	a5,32(s1)
    8000211e:	fd4798e3          	bne	a5,s4,800020ee <wakeup+0x2a>
        p->state = RUNNABLE;
    80002122:	0154ac23          	sw	s5,24(s1)
    80002126:	b7e1                	j	800020ee <wakeup+0x2a>
    }
  }
}
    80002128:	70e2                	ld	ra,56(sp)
    8000212a:	7442                	ld	s0,48(sp)
    8000212c:	74a2                	ld	s1,40(sp)
    8000212e:	7902                	ld	s2,32(sp)
    80002130:	69e2                	ld	s3,24(sp)
    80002132:	6a42                	ld	s4,16(sp)
    80002134:	6aa2                	ld	s5,8(sp)
    80002136:	6121                	addi	sp,sp,64
    80002138:	8082                	ret

000000008000213a <reparent>:
{
    8000213a:	7179                	addi	sp,sp,-48
    8000213c:	f406                	sd	ra,40(sp)
    8000213e:	f022                	sd	s0,32(sp)
    80002140:	ec26                	sd	s1,24(sp)
    80002142:	e84a                	sd	s2,16(sp)
    80002144:	e44e                	sd	s3,8(sp)
    80002146:	e052                	sd	s4,0(sp)
    80002148:	1800                	addi	s0,sp,48
    8000214a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214c:	0000f497          	auipc	s1,0xf
    80002150:	08448493          	addi	s1,s1,132 # 800111d0 <proc>
      pp->parent = initproc;
    80002154:	00007a17          	auipc	s4,0x7
    80002158:	9d4a0a13          	addi	s4,s4,-1580 # 80008b28 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000215c:	00015997          	auipc	s3,0x15
    80002160:	e7498993          	addi	s3,s3,-396 # 80016fd0 <tickslock>
    80002164:	a029                	j	8000216e <reparent+0x34>
    80002166:	17848493          	addi	s1,s1,376
    8000216a:	01348d63          	beq	s1,s3,80002184 <reparent+0x4a>
    if(pp->parent == p){
    8000216e:	7c9c                	ld	a5,56(s1)
    80002170:	ff279be3          	bne	a5,s2,80002166 <reparent+0x2c>
      pp->parent = initproc;
    80002174:	000a3503          	ld	a0,0(s4)
    80002178:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	f4a080e7          	jalr	-182(ra) # 800020c4 <wakeup>
    80002182:	b7d5                	j	80002166 <reparent+0x2c>
}
    80002184:	70a2                	ld	ra,40(sp)
    80002186:	7402                	ld	s0,32(sp)
    80002188:	64e2                	ld	s1,24(sp)
    8000218a:	6942                	ld	s2,16(sp)
    8000218c:	69a2                	ld	s3,8(sp)
    8000218e:	6a02                	ld	s4,0(sp)
    80002190:	6145                	addi	sp,sp,48
    80002192:	8082                	ret

0000000080002194 <exit>:
{
    80002194:	7179                	addi	sp,sp,-48
    80002196:	f406                	sd	ra,40(sp)
    80002198:	f022                	sd	s0,32(sp)
    8000219a:	ec26                	sd	s1,24(sp)
    8000219c:	e84a                	sd	s2,16(sp)
    8000219e:	e44e                	sd	s3,8(sp)
    800021a0:	e052                	sd	s4,0(sp)
    800021a2:	1800                	addi	s0,sp,48
    800021a4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	806080e7          	jalr	-2042(ra) # 800019ac <myproc>
    800021ae:	89aa                	mv	s3,a0
  if(p == initproc)
    800021b0:	00007797          	auipc	a5,0x7
    800021b4:	9787b783          	ld	a5,-1672(a5) # 80008b28 <initproc>
    800021b8:	0d850493          	addi	s1,a0,216
    800021bc:	15850913          	addi	s2,a0,344
    800021c0:	02a79363          	bne	a5,a0,800021e6 <exit+0x52>
    panic("init exiting");
    800021c4:	00006517          	auipc	a0,0x6
    800021c8:	09c50513          	addi	a0,a0,156 # 80008260 <digits+0x220>
    800021cc:	ffffe097          	auipc	ra,0xffffe
    800021d0:	374080e7          	jalr	884(ra) # 80000540 <panic>
      fileclose(f);
    800021d4:	00002097          	auipc	ra,0x2
    800021d8:	452080e7          	jalr	1106(ra) # 80004626 <fileclose>
      p->ofile[fd] = 0;
    800021dc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021e0:	04a1                	addi	s1,s1,8
    800021e2:	01248563          	beq	s1,s2,800021ec <exit+0x58>
    if(p->ofile[fd]){
    800021e6:	6088                	ld	a0,0(s1)
    800021e8:	f575                	bnez	a0,800021d4 <exit+0x40>
    800021ea:	bfdd                	j	800021e0 <exit+0x4c>
  begin_op();
    800021ec:	00002097          	auipc	ra,0x2
    800021f0:	f72080e7          	jalr	-142(ra) # 8000415e <begin_op>
  iput(p->cwd);
    800021f4:	1589b503          	ld	a0,344(s3)
    800021f8:	00001097          	auipc	ra,0x1
    800021fc:	754080e7          	jalr	1876(ra) # 8000394c <iput>
  end_op();
    80002200:	00002097          	auipc	ra,0x2
    80002204:	fdc080e7          	jalr	-36(ra) # 800041dc <end_op>
  p->cwd = 0;
    80002208:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000220c:	0000f497          	auipc	s1,0xf
    80002210:	bac48493          	addi	s1,s1,-1108 # 80010db8 <wait_lock>
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9c0080e7          	jalr	-1600(ra) # 80000bd6 <acquire>
  reparent(p);
    8000221e:	854e                	mv	a0,s3
    80002220:	00000097          	auipc	ra,0x0
    80002224:	f1a080e7          	jalr	-230(ra) # 8000213a <reparent>
  wakeup(p->parent);
    80002228:	0389b503          	ld	a0,56(s3)
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	e98080e7          	jalr	-360(ra) # 800020c4 <wakeup>
  acquire(&p->lock);
    80002234:	854e                	mv	a0,s3
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	9a0080e7          	jalr	-1632(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000223e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002242:	4795                	li	a5,5
    80002244:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a40080e7          	jalr	-1472(ra) # 80000c8a <release>
  sched();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	cfc080e7          	jalr	-772(ra) # 80001f4e <sched>
  panic("zombie exit");
    8000225a:	00006517          	auipc	a0,0x6
    8000225e:	01650513          	addi	a0,a0,22 # 80008270 <digits+0x230>
    80002262:	ffffe097          	auipc	ra,0xffffe
    80002266:	2de080e7          	jalr	734(ra) # 80000540 <panic>

000000008000226a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000226a:	7179                	addi	sp,sp,-48
    8000226c:	f406                	sd	ra,40(sp)
    8000226e:	f022                	sd	s0,32(sp)
    80002270:	ec26                	sd	s1,24(sp)
    80002272:	e84a                	sd	s2,16(sp)
    80002274:	e44e                	sd	s3,8(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000227a:	0000f497          	auipc	s1,0xf
    8000227e:	f5648493          	addi	s1,s1,-170 # 800111d0 <proc>
    80002282:	00015997          	auipc	s3,0x15
    80002286:	d4e98993          	addi	s3,s3,-690 # 80016fd0 <tickslock>
    acquire(&p->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	94a080e7          	jalr	-1718(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002294:	589c                	lw	a5,48(s1)
    80002296:	01278d63          	beq	a5,s2,800022b0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	9ee080e7          	jalr	-1554(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022a4:	17848493          	addi	s1,s1,376
    800022a8:	ff3491e3          	bne	s1,s3,8000228a <kill+0x20>
  }
  return -1;
    800022ac:	557d                	li	a0,-1
    800022ae:	a829                	j	800022c8 <kill+0x5e>
      p->killed = 1;
    800022b0:	4785                	li	a5,1
    800022b2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022b4:	4c98                	lw	a4,24(s1)
    800022b6:	4789                	li	a5,2
    800022b8:	00f70f63          	beq	a4,a5,800022d6 <kill+0x6c>
      release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
      return 0;
    800022c6:	4501                	li	a0,0
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret
        p->state = RUNNABLE;
    800022d6:	478d                	li	a5,3
    800022d8:	cc9c                	sw	a5,24(s1)
    800022da:	b7cd                	j	800022bc <kill+0x52>

00000000800022dc <setkilled>:

void
setkilled(struct proc *p)
{
    800022dc:	1101                	addi	sp,sp,-32
    800022de:	ec06                	sd	ra,24(sp)
    800022e0:	e822                	sd	s0,16(sp)
    800022e2:	e426                	sd	s1,8(sp)
    800022e4:	1000                	addi	s0,sp,32
    800022e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	8ee080e7          	jalr	-1810(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022f0:	4785                	li	a5,1
    800022f2:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	994080e7          	jalr	-1644(ra) # 80000c8a <release>
}
    800022fe:	60e2                	ld	ra,24(sp)
    80002300:	6442                	ld	s0,16(sp)
    80002302:	64a2                	ld	s1,8(sp)
    80002304:	6105                	addi	sp,sp,32
    80002306:	8082                	ret

0000000080002308 <killed>:

int
killed(struct proc *p)
{
    80002308:	1101                	addi	sp,sp,-32
    8000230a:	ec06                	sd	ra,24(sp)
    8000230c:	e822                	sd	s0,16(sp)
    8000230e:	e426                	sd	s1,8(sp)
    80002310:	e04a                	sd	s2,0(sp)
    80002312:	1000                	addi	s0,sp,32
    80002314:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8c0080e7          	jalr	-1856(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000231e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	966080e7          	jalr	-1690(ra) # 80000c8a <release>
  return k;
}
    8000232c:	854a                	mv	a0,s2
    8000232e:	60e2                	ld	ra,24(sp)
    80002330:	6442                	ld	s0,16(sp)
    80002332:	64a2                	ld	s1,8(sp)
    80002334:	6902                	ld	s2,0(sp)
    80002336:	6105                	addi	sp,sp,32
    80002338:	8082                	ret

000000008000233a <wait>:
{
    8000233a:	715d                	addi	sp,sp,-80
    8000233c:	e486                	sd	ra,72(sp)
    8000233e:	e0a2                	sd	s0,64(sp)
    80002340:	fc26                	sd	s1,56(sp)
    80002342:	f84a                	sd	s2,48(sp)
    80002344:	f44e                	sd	s3,40(sp)
    80002346:	f052                	sd	s4,32(sp)
    80002348:	ec56                	sd	s5,24(sp)
    8000234a:	e85a                	sd	s6,16(sp)
    8000234c:	e45e                	sd	s7,8(sp)
    8000234e:	e062                	sd	s8,0(sp)
    80002350:	0880                	addi	s0,sp,80
    80002352:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	658080e7          	jalr	1624(ra) # 800019ac <myproc>
    8000235c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000235e:	0000f517          	auipc	a0,0xf
    80002362:	a5a50513          	addi	a0,a0,-1446 # 80010db8 <wait_lock>
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	870080e7          	jalr	-1936(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000236e:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002370:	4a15                	li	s4,5
        havekids = 1;
    80002372:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002374:	00015997          	auipc	s3,0x15
    80002378:	c5c98993          	addi	s3,s3,-932 # 80016fd0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237c:	0000fc17          	auipc	s8,0xf
    80002380:	a3cc0c13          	addi	s8,s8,-1476 # 80010db8 <wait_lock>
    havekids = 0;
    80002384:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002386:	0000f497          	auipc	s1,0xf
    8000238a:	e4a48493          	addi	s1,s1,-438 # 800111d0 <proc>
    8000238e:	a0bd                	j	800023fc <wait+0xc2>
          pid = pp->pid;
    80002390:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002394:	000b0e63          	beqz	s6,800023b0 <wait+0x76>
    80002398:	4691                	li	a3,4
    8000239a:	02c48613          	addi	a2,s1,44
    8000239e:	85da                	mv	a1,s6
    800023a0:	05893503          	ld	a0,88(s2)
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	2c8080e7          	jalr	712(ra) # 8000166c <copyout>
    800023ac:	02054563          	bltz	a0,800023d6 <wait+0x9c>
          freeproc(pp);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	7ac080e7          	jalr	1964(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8ce080e7          	jalr	-1842(ra) # 80000c8a <release>
          release(&wait_lock);
    800023c4:	0000f517          	auipc	a0,0xf
    800023c8:	9f450513          	addi	a0,a0,-1548 # 80010db8 <wait_lock>
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
          return pid;
    800023d4:	a0b5                	j	80002440 <wait+0x106>
            release(&pp->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8b2080e7          	jalr	-1870(ra) # 80000c8a <release>
            release(&wait_lock);
    800023e0:	0000f517          	auipc	a0,0xf
    800023e4:	9d850513          	addi	a0,a0,-1576 # 80010db8 <wait_lock>
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8a2080e7          	jalr	-1886(ra) # 80000c8a <release>
            return -1;
    800023f0:	59fd                	li	s3,-1
    800023f2:	a0b9                	j	80002440 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f4:	17848493          	addi	s1,s1,376
    800023f8:	03348463          	beq	s1,s3,80002420 <wait+0xe6>
      if(pp->parent == p){
    800023fc:	7c9c                	ld	a5,56(s1)
    800023fe:	ff279be3          	bne	a5,s2,800023f4 <wait+0xba>
        acquire(&pp->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	7d2080e7          	jalr	2002(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000240c:	4c9c                	lw	a5,24(s1)
    8000240e:	f94781e3          	beq	a5,s4,80002390 <wait+0x56>
        release(&pp->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
        havekids = 1;
    8000241c:	8756                	mv	a4,s5
    8000241e:	bfd9                	j	800023f4 <wait+0xba>
    if(!havekids || killed(p)){
    80002420:	c719                	beqz	a4,8000242e <wait+0xf4>
    80002422:	854a                	mv	a0,s2
    80002424:	00000097          	auipc	ra,0x0
    80002428:	ee4080e7          	jalr	-284(ra) # 80002308 <killed>
    8000242c:	c51d                	beqz	a0,8000245a <wait+0x120>
      release(&wait_lock);
    8000242e:	0000f517          	auipc	a0,0xf
    80002432:	98a50513          	addi	a0,a0,-1654 # 80010db8 <wait_lock>
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	854080e7          	jalr	-1964(ra) # 80000c8a <release>
      return -1;
    8000243e:	59fd                	li	s3,-1
}
    80002440:	854e                	mv	a0,s3
    80002442:	60a6                	ld	ra,72(sp)
    80002444:	6406                	ld	s0,64(sp)
    80002446:	74e2                	ld	s1,56(sp)
    80002448:	7942                	ld	s2,48(sp)
    8000244a:	79a2                	ld	s3,40(sp)
    8000244c:	7a02                	ld	s4,32(sp)
    8000244e:	6ae2                	ld	s5,24(sp)
    80002450:	6b42                	ld	s6,16(sp)
    80002452:	6ba2                	ld	s7,8(sp)
    80002454:	6c02                	ld	s8,0(sp)
    80002456:	6161                	addi	sp,sp,80
    80002458:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000245a:	85e2                	mv	a1,s8
    8000245c:	854a                	mv	a0,s2
    8000245e:	00000097          	auipc	ra,0x0
    80002462:	c02080e7          	jalr	-1022(ra) # 80002060 <sleep>
    havekids = 0;
    80002466:	bf39                	j	80002384 <wait+0x4a>

0000000080002468 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002468:	7179                	addi	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	e052                	sd	s4,0(sp)
    80002476:	1800                	addi	s0,sp,48
    80002478:	84aa                	mv	s1,a0
    8000247a:	892e                	mv	s2,a1
    8000247c:	89b2                	mv	s3,a2
    8000247e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	52c080e7          	jalr	1324(ra) # 800019ac <myproc>
  if(user_dst){
    80002488:	c08d                	beqz	s1,800024aa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000248a:	86d2                	mv	a3,s4
    8000248c:	864e                	mv	a2,s3
    8000248e:	85ca                	mv	a1,s2
    80002490:	6d28                	ld	a0,88(a0)
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	1da080e7          	jalr	474(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6a02                	ld	s4,0(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret
    memmove((char *)dst, src, len);
    800024aa:	000a061b          	sext.w	a2,s4
    800024ae:	85ce                	mv	a1,s3
    800024b0:	854a                	mv	a0,s2
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	87c080e7          	jalr	-1924(ra) # 80000d2e <memmove>
    return 0;
    800024ba:	8526                	mv	a0,s1
    800024bc:	bff9                	j	8000249a <either_copyout+0x32>

00000000800024be <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
    800024d0:	84ae                	mv	s1,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	4d6080e7          	jalr	1238(ra) # 800019ac <myproc>
  if(user_src){
    800024de:	c08d                	beqz	s1,80002500 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6d28                	ld	a0,88(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	210080e7          	jalr	528(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	826080e7          	jalr	-2010(ra) # 80000d2e <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyin+0x32>

0000000080002514 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002514:	715d                	addi	sp,sp,-80
    80002516:	e486                	sd	ra,72(sp)
    80002518:	e0a2                	sd	s0,64(sp)
    8000251a:	fc26                	sd	s1,56(sp)
    8000251c:	f84a                	sd	s2,48(sp)
    8000251e:	f44e                	sd	s3,40(sp)
    80002520:	f052                	sd	s4,32(sp)
    80002522:	ec56                	sd	s5,24(sp)
    80002524:	e85a                	sd	s6,16(sp)
    80002526:	e45e                	sd	s7,8(sp)
    80002528:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000252a:	00006517          	auipc	a0,0x6
    8000252e:	b9e50513          	addi	a0,a0,-1122 # 800080c8 <digits+0x88>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	058080e7          	jalr	88(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253a:	0000f497          	auipc	s1,0xf
    8000253e:	df648493          	addi	s1,s1,-522 # 80011330 <proc+0x160>
    80002542:	00015917          	auipc	s2,0x15
    80002546:	bee90913          	addi	s2,s2,-1042 # 80017130 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000254c:	00006997          	auipc	s3,0x6
    80002550:	d3498993          	addi	s3,s3,-716 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002554:	00006a97          	auipc	s5,0x6
    80002558:	d34a8a93          	addi	s5,s5,-716 # 80008288 <digits+0x248>
    printf("\n");
    8000255c:	00006a17          	auipc	s4,0x6
    80002560:	b6ca0a13          	addi	s4,s4,-1172 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002564:	00006b97          	auipc	s7,0x6
    80002568:	d64b8b93          	addi	s7,s7,-668 # 800082c8 <states.0>
    8000256c:	a00d                	j	8000258e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256e:	ed06a583          	lw	a1,-304(a3)
    80002572:	8556                	mv	a0,s5
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	016080e7          	jalr	22(ra) # 8000058a <printf>
    printf("\n");
    8000257c:	8552                	mv	a0,s4
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	00c080e7          	jalr	12(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002586:	17848493          	addi	s1,s1,376
    8000258a:	03248263          	beq	s1,s2,800025ae <procdump+0x9a>
    if(p->state == UNUSED)
    8000258e:	86a6                	mv	a3,s1
    80002590:	eb84a783          	lw	a5,-328(s1)
    80002594:	dbed                	beqz	a5,80002586 <procdump+0x72>
      state = "???";
    80002596:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	fcfb6be3          	bltu	s6,a5,8000256e <procdump+0x5a>
    8000259c:	02079713          	slli	a4,a5,0x20
    800025a0:	01d75793          	srli	a5,a4,0x1d
    800025a4:	97de                	add	a5,a5,s7
    800025a6:	6390                	ld	a2,0(a5)
    800025a8:	f279                	bnez	a2,8000256e <procdump+0x5a>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    800025ac:	b7c9                	j	8000256e <procdump+0x5a>
  }
}
    800025ae:	60a6                	ld	ra,72(sp)
    800025b0:	6406                	ld	s0,64(sp)
    800025b2:	74e2                	ld	s1,56(sp)
    800025b4:	7942                	ld	s2,48(sp)
    800025b6:	79a2                	ld	s3,40(sp)
    800025b8:	7a02                	ld	s4,32(sp)
    800025ba:	6ae2                	ld	s5,24(sp)
    800025bc:	6b42                	ld	s6,16(sp)
    800025be:	6ba2                	ld	s7,8(sp)
    800025c0:	6161                	addi	sp,sp,80
    800025c2:	8082                	ret

00000000800025c4 <strace>:

void
strace(int strace_mask)
{
    800025c4:	1101                	addi	sp,sp,-32
    800025c6:	ec06                	sd	ra,24(sp)
    800025c8:	e822                	sd	s0,16(sp)
    800025ca:	e426                	sd	s1,8(sp)
    800025cc:	1000                	addi	s0,sp,32
    800025ce:	84aa                	mv	s1,a0
  myproc()->strace_bit = strace_mask;
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	3dc080e7          	jalr	988(ra) # 800019ac <myproc>
    800025d8:	16952823          	sw	s1,368(a0)
  return;
    800025dc:	60e2                	ld	ra,24(sp)
    800025de:	6442                	ld	s0,16(sp)
    800025e0:	64a2                	ld	s1,8(sp)
    800025e2:	6105                	addi	sp,sp,32
    800025e4:	8082                	ret

00000000800025e6 <swtch>:
    800025e6:	00153023          	sd	ra,0(a0)
    800025ea:	00253423          	sd	sp,8(a0)
    800025ee:	e900                	sd	s0,16(a0)
    800025f0:	ed04                	sd	s1,24(a0)
    800025f2:	03253023          	sd	s2,32(a0)
    800025f6:	03353423          	sd	s3,40(a0)
    800025fa:	03453823          	sd	s4,48(a0)
    800025fe:	03553c23          	sd	s5,56(a0)
    80002602:	05653023          	sd	s6,64(a0)
    80002606:	05753423          	sd	s7,72(a0)
    8000260a:	05853823          	sd	s8,80(a0)
    8000260e:	05953c23          	sd	s9,88(a0)
    80002612:	07a53023          	sd	s10,96(a0)
    80002616:	07b53423          	sd	s11,104(a0)
    8000261a:	0005b083          	ld	ra,0(a1)
    8000261e:	0085b103          	ld	sp,8(a1)
    80002622:	6980                	ld	s0,16(a1)
    80002624:	6d84                	ld	s1,24(a1)
    80002626:	0205b903          	ld	s2,32(a1)
    8000262a:	0285b983          	ld	s3,40(a1)
    8000262e:	0305ba03          	ld	s4,48(a1)
    80002632:	0385ba83          	ld	s5,56(a1)
    80002636:	0405bb03          	ld	s6,64(a1)
    8000263a:	0485bb83          	ld	s7,72(a1)
    8000263e:	0505bc03          	ld	s8,80(a1)
    80002642:	0585bc83          	ld	s9,88(a1)
    80002646:	0605bd03          	ld	s10,96(a1)
    8000264a:	0685bd83          	ld	s11,104(a1)
    8000264e:	8082                	ret

0000000080002650 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002650:	1141                	addi	sp,sp,-16
    80002652:	e406                	sd	ra,8(sp)
    80002654:	e022                	sd	s0,0(sp)
    80002656:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002658:	00006597          	auipc	a1,0x6
    8000265c:	ca058593          	addi	a1,a1,-864 # 800082f8 <states.0+0x30>
    80002660:	00015517          	auipc	a0,0x15
    80002664:	97050513          	addi	a0,a0,-1680 # 80016fd0 <tickslock>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	4de080e7          	jalr	1246(ra) # 80000b46 <initlock>
}
    80002670:	60a2                	ld	ra,8(sp)
    80002672:	6402                	ld	s0,0(sp)
    80002674:	0141                	addi	sp,sp,16
    80002676:	8082                	ret

0000000080002678 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002678:	1141                	addi	sp,sp,-16
    8000267a:	e422                	sd	s0,8(sp)
    8000267c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000267e:	00003797          	auipc	a5,0x3
    80002682:	60278793          	addi	a5,a5,1538 # 80005c80 <kernelvec>
    80002686:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000268a:	6422                	ld	s0,8(sp)
    8000268c:	0141                	addi	sp,sp,16
    8000268e:	8082                	ret

0000000080002690 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002690:	1141                	addi	sp,sp,-16
    80002692:	e406                	sd	ra,8(sp)
    80002694:	e022                	sd	s0,0(sp)
    80002696:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	314080e7          	jalr	788(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026a4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026aa:	00005697          	auipc	a3,0x5
    800026ae:	95668693          	addi	a3,a3,-1706 # 80007000 <_trampoline>
    800026b2:	00005717          	auipc	a4,0x5
    800026b6:	94e70713          	addi	a4,a4,-1714 # 80007000 <_trampoline>
    800026ba:	8f15                	sub	a4,a4,a3
    800026bc:	040007b7          	lui	a5,0x4000
    800026c0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026c2:	07b2                	slli	a5,a5,0xc
    800026c4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026c6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ca:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026cc:	18002673          	csrr	a2,satp
    800026d0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026d2:	7130                	ld	a2,96(a0)
    800026d4:	6138                	ld	a4,64(a0)
    800026d6:	6585                	lui	a1,0x1
    800026d8:	972e                	add	a4,a4,a1
    800026da:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026dc:	7138                	ld	a4,96(a0)
    800026de:	00000617          	auipc	a2,0x0
    800026e2:	13060613          	addi	a2,a2,304 # 8000280e <usertrap>
    800026e6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026e8:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ea:	8612                	mv	a2,tp
    800026ec:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ee:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026f2:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026f6:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026fa:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026fe:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002700:	6f18                	ld	a4,24(a4)
    80002702:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002706:	6d28                	ld	a0,88(a0)
    80002708:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000270a:	00005717          	auipc	a4,0x5
    8000270e:	99270713          	addi	a4,a4,-1646 # 8000709c <userret>
    80002712:	8f15                	sub	a4,a4,a3
    80002714:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002716:	577d                	li	a4,-1
    80002718:	177e                	slli	a4,a4,0x3f
    8000271a:	8d59                	or	a0,a0,a4
    8000271c:	9782                	jalr	a5
}
    8000271e:	60a2                	ld	ra,8(sp)
    80002720:	6402                	ld	s0,0(sp)
    80002722:	0141                	addi	sp,sp,16
    80002724:	8082                	ret

0000000080002726 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002726:	1101                	addi	sp,sp,-32
    80002728:	ec06                	sd	ra,24(sp)
    8000272a:	e822                	sd	s0,16(sp)
    8000272c:	e426                	sd	s1,8(sp)
    8000272e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002730:	00015497          	auipc	s1,0x15
    80002734:	8a048493          	addi	s1,s1,-1888 # 80016fd0 <tickslock>
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	49c080e7          	jalr	1180(ra) # 80000bd6 <acquire>
  ticks++;
    80002742:	00006517          	auipc	a0,0x6
    80002746:	3ee50513          	addi	a0,a0,1006 # 80008b30 <ticks>
    8000274a:	411c                	lw	a5,0(a0)
    8000274c:	2785                	addiw	a5,a5,1
    8000274e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002750:	00000097          	auipc	ra,0x0
    80002754:	974080e7          	jalr	-1676(ra) # 800020c4 <wakeup>
  release(&tickslock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
}
    80002762:	60e2                	ld	ra,24(sp)
    80002764:	6442                	ld	s0,16(sp)
    80002766:	64a2                	ld	s1,8(sp)
    80002768:	6105                	addi	sp,sp,32
    8000276a:	8082                	ret

000000008000276c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000276c:	1101                	addi	sp,sp,-32
    8000276e:	ec06                	sd	ra,24(sp)
    80002770:	e822                	sd	s0,16(sp)
    80002772:	e426                	sd	s1,8(sp)
    80002774:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002776:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000277a:	00074d63          	bltz	a4,80002794 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000277e:	57fd                	li	a5,-1
    80002780:	17fe                	slli	a5,a5,0x3f
    80002782:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002784:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002786:	06f70363          	beq	a4,a5,800027ec <devintr+0x80>
  }
}
    8000278a:	60e2                	ld	ra,24(sp)
    8000278c:	6442                	ld	s0,16(sp)
    8000278e:	64a2                	ld	s1,8(sp)
    80002790:	6105                	addi	sp,sp,32
    80002792:	8082                	ret
     (scause & 0xff) == 9){
    80002794:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002798:	46a5                	li	a3,9
    8000279a:	fed792e3          	bne	a5,a3,8000277e <devintr+0x12>
    int irq = plic_claim();
    8000279e:	00003097          	auipc	ra,0x3
    800027a2:	5ea080e7          	jalr	1514(ra) # 80005d88 <plic_claim>
    800027a6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027a8:	47a9                	li	a5,10
    800027aa:	02f50763          	beq	a0,a5,800027d8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ae:	4785                	li	a5,1
    800027b0:	02f50963          	beq	a0,a5,800027e2 <devintr+0x76>
    return 1;
    800027b4:	4505                	li	a0,1
    } else if(irq){
    800027b6:	d8f1                	beqz	s1,8000278a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027b8:	85a6                	mv	a1,s1
    800027ba:	00006517          	auipc	a0,0x6
    800027be:	b4650513          	addi	a0,a0,-1210 # 80008300 <states.0+0x38>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	dc8080e7          	jalr	-568(ra) # 8000058a <printf>
      plic_complete(irq);
    800027ca:	8526                	mv	a0,s1
    800027cc:	00003097          	auipc	ra,0x3
    800027d0:	5e0080e7          	jalr	1504(ra) # 80005dac <plic_complete>
    return 1;
    800027d4:	4505                	li	a0,1
    800027d6:	bf55                	j	8000278a <devintr+0x1e>
      uartintr();
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	1c0080e7          	jalr	448(ra) # 80000998 <uartintr>
    800027e0:	b7ed                	j	800027ca <devintr+0x5e>
      virtio_disk_intr();
    800027e2:	00004097          	auipc	ra,0x4
    800027e6:	a92080e7          	jalr	-1390(ra) # 80006274 <virtio_disk_intr>
    800027ea:	b7c5                	j	800027ca <devintr+0x5e>
    if(cpuid() == 0){
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	194080e7          	jalr	404(ra) # 80001980 <cpuid>
    800027f4:	c901                	beqz	a0,80002804 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027f6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027fa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027fc:	14479073          	csrw	sip,a5
    return 2;
    80002800:	4509                	li	a0,2
    80002802:	b761                	j	8000278a <devintr+0x1e>
      clockintr();
    80002804:	00000097          	auipc	ra,0x0
    80002808:	f22080e7          	jalr	-222(ra) # 80002726 <clockintr>
    8000280c:	b7ed                	j	800027f6 <devintr+0x8a>

000000008000280e <usertrap>:
{
    8000280e:	1101                	addi	sp,sp,-32
    80002810:	ec06                	sd	ra,24(sp)
    80002812:	e822                	sd	s0,16(sp)
    80002814:	e426                	sd	s1,8(sp)
    80002816:	e04a                	sd	s2,0(sp)
    80002818:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000281e:	1007f793          	andi	a5,a5,256
    80002822:	e3b1                	bnez	a5,80002866 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002824:	00003797          	auipc	a5,0x3
    80002828:	45c78793          	addi	a5,a5,1116 # 80005c80 <kernelvec>
    8000282c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	17c080e7          	jalr	380(ra) # 800019ac <myproc>
    80002838:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000283a:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000283c:	14102773          	csrr	a4,sepc
    80002840:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002842:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002846:	47a1                	li	a5,8
    80002848:	02f70763          	beq	a4,a5,80002876 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	f20080e7          	jalr	-224(ra) # 8000276c <devintr>
    80002854:	892a                	mv	s2,a0
    80002856:	c151                	beqz	a0,800028da <usertrap+0xcc>
  if(killed(p))
    80002858:	8526                	mv	a0,s1
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	aae080e7          	jalr	-1362(ra) # 80002308 <killed>
    80002862:	c929                	beqz	a0,800028b4 <usertrap+0xa6>
    80002864:	a099                	j	800028aa <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	aba50513          	addi	a0,a0,-1350 # 80008320 <states.0+0x58>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	cd2080e7          	jalr	-814(ra) # 80000540 <panic>
    if(killed(p))
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	a92080e7          	jalr	-1390(ra) # 80002308 <killed>
    8000287e:	e921                	bnez	a0,800028ce <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002880:	70b8                	ld	a4,96(s1)
    80002882:	6f1c                	ld	a5,24(a4)
    80002884:	0791                	addi	a5,a5,4
    80002886:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000288c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10079073          	csrw	sstatus,a5
    syscall();
    80002894:	00000097          	auipc	ra,0x0
    80002898:	390080e7          	jalr	912(ra) # 80002c24 <syscall>
  if(killed(p))
    8000289c:	8526                	mv	a0,s1
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	a6a080e7          	jalr	-1430(ra) # 80002308 <killed>
    800028a6:	c911                	beqz	a0,800028ba <usertrap+0xac>
    800028a8:	4901                	li	s2,0
    exit(-1);
    800028aa:	557d                	li	a0,-1
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	8e8080e7          	jalr	-1816(ra) # 80002194 <exit>
  if(which_dev == 2)
    800028b4:	4789                	li	a5,2
    800028b6:	04f90f63          	beq	s2,a5,80002914 <usertrap+0x106>
  usertrapret();
    800028ba:	00000097          	auipc	ra,0x0
    800028be:	dd6080e7          	jalr	-554(ra) # 80002690 <usertrapret>
}
    800028c2:	60e2                	ld	ra,24(sp)
    800028c4:	6442                	ld	s0,16(sp)
    800028c6:	64a2                	ld	s1,8(sp)
    800028c8:	6902                	ld	s2,0(sp)
    800028ca:	6105                	addi	sp,sp,32
    800028cc:	8082                	ret
      exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	8c4080e7          	jalr	-1852(ra) # 80002194 <exit>
    800028d8:	b765                	j	80002880 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028da:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028de:	5890                	lw	a2,48(s1)
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	a6050513          	addi	a0,a0,-1440 # 80008340 <states.0+0x78>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	ca2080e7          	jalr	-862(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a7850513          	addi	a0,a0,-1416 # 80008370 <states.0+0xa8>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c8a080e7          	jalr	-886(ra) # 8000058a <printf>
    setkilled(p);
    80002908:	8526                	mv	a0,s1
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	9d2080e7          	jalr	-1582(ra) # 800022dc <setkilled>
    80002912:	b769                	j	8000289c <usertrap+0x8e>
    yield();
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	710080e7          	jalr	1808(ra) # 80002024 <yield>
    8000291c:	bf79                	j	800028ba <usertrap+0xac>

000000008000291e <kerneltrap>:
{
    8000291e:	7179                	addi	sp,sp,-48
    80002920:	f406                	sd	ra,40(sp)
    80002922:	f022                	sd	s0,32(sp)
    80002924:	ec26                	sd	s1,24(sp)
    80002926:	e84a                	sd	s2,16(sp)
    80002928:	e44e                	sd	s3,8(sp)
    8000292a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002930:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002934:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002938:	1004f793          	andi	a5,s1,256
    8000293c:	cb85                	beqz	a5,8000296c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002942:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002944:	ef85                	bnez	a5,8000297c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	e26080e7          	jalr	-474(ra) # 8000276c <devintr>
    8000294e:	cd1d                	beqz	a0,8000298c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002950:	4789                	li	a5,2
    80002952:	06f50a63          	beq	a0,a5,800029c6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002956:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295a:	10049073          	csrw	sstatus,s1
}
    8000295e:	70a2                	ld	ra,40(sp)
    80002960:	7402                	ld	s0,32(sp)
    80002962:	64e2                	ld	s1,24(sp)
    80002964:	6942                	ld	s2,16(sp)
    80002966:	69a2                	ld	s3,8(sp)
    80002968:	6145                	addi	sp,sp,48
    8000296a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	a2450513          	addi	a0,a0,-1500 # 80008390 <states.0+0xc8>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	bcc080e7          	jalr	-1076(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	a3c50513          	addi	a0,a0,-1476 # 800083b8 <states.0+0xf0>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	bbc080e7          	jalr	-1092(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    8000298c:	85ce                	mv	a1,s3
    8000298e:	00006517          	auipc	a0,0x6
    80002992:	a4a50513          	addi	a0,a0,-1462 # 800083d8 <states.0+0x110>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	bf4080e7          	jalr	-1036(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029a2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	a4250513          	addi	a0,a0,-1470 # 800083e8 <states.0+0x120>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	bdc080e7          	jalr	-1060(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	a4a50513          	addi	a0,a0,-1462 # 80008400 <states.0+0x138>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	b82080e7          	jalr	-1150(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	fe6080e7          	jalr	-26(ra) # 800019ac <myproc>
    800029ce:	d541                	beqz	a0,80002956 <kerneltrap+0x38>
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	fdc080e7          	jalr	-36(ra) # 800019ac <myproc>
    800029d8:	4d18                	lw	a4,24(a0)
    800029da:	4791                	li	a5,4
    800029dc:	f6f71de3          	bne	a4,a5,80002956 <kerneltrap+0x38>
    yield();
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	644080e7          	jalr	1604(ra) # 80002024 <yield>
    800029e8:	b7bd                	j	80002956 <kerneltrap+0x38>

00000000800029ea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029ea:	1101                	addi	sp,sp,-32
    800029ec:	ec06                	sd	ra,24(sp)
    800029ee:	e822                	sd	s0,16(sp)
    800029f0:	e426                	sd	s1,8(sp)
    800029f2:	1000                	addi	s0,sp,32
    800029f4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	fb6080e7          	jalr	-74(ra) # 800019ac <myproc>
  switch (n)
    800029fe:	4795                	li	a5,5
    80002a00:	0497e163          	bltu	a5,s1,80002a42 <argraw+0x58>
    80002a04:	048a                	slli	s1,s1,0x2
    80002a06:	00006717          	auipc	a4,0x6
    80002a0a:	b1270713          	addi	a4,a4,-1262 # 80008518 <states.0+0x250>
    80002a0e:	94ba                	add	s1,s1,a4
    80002a10:	409c                	lw	a5,0(s1)
    80002a12:	97ba                	add	a5,a5,a4
    80002a14:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a16:	713c                	ld	a5,96(a0)
    80002a18:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6105                	addi	sp,sp,32
    80002a22:	8082                	ret
    return p->trapframe->a1;
    80002a24:	713c                	ld	a5,96(a0)
    80002a26:	7fa8                	ld	a0,120(a5)
    80002a28:	bfcd                	j	80002a1a <argraw+0x30>
    return p->trapframe->a2;
    80002a2a:	713c                	ld	a5,96(a0)
    80002a2c:	63c8                	ld	a0,128(a5)
    80002a2e:	b7f5                	j	80002a1a <argraw+0x30>
    return p->trapframe->a3;
    80002a30:	713c                	ld	a5,96(a0)
    80002a32:	67c8                	ld	a0,136(a5)
    80002a34:	b7dd                	j	80002a1a <argraw+0x30>
    return p->trapframe->a4;
    80002a36:	713c                	ld	a5,96(a0)
    80002a38:	6bc8                	ld	a0,144(a5)
    80002a3a:	b7c5                	j	80002a1a <argraw+0x30>
    return p->trapframe->a5;
    80002a3c:	713c                	ld	a5,96(a0)
    80002a3e:	6fc8                	ld	a0,152(a5)
    80002a40:	bfe9                	j	80002a1a <argraw+0x30>
  panic("argraw");
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	9ce50513          	addi	a0,a0,-1586 # 80008410 <states.0+0x148>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	af6080e7          	jalr	-1290(ra) # 80000540 <panic>

0000000080002a52 <fetchaddr>:
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	e04a                	sd	s2,0(sp)
    80002a5c:	1000                	addi	s0,sp,32
    80002a5e:	84aa                	mv	s1,a0
    80002a60:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	f4a080e7          	jalr	-182(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a6a:	653c                	ld	a5,72(a0)
    80002a6c:	02f4f863          	bgeu	s1,a5,80002a9c <fetchaddr+0x4a>
    80002a70:	00848713          	addi	a4,s1,8
    80002a74:	02e7e663          	bltu	a5,a4,80002aa0 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a78:	46a1                	li	a3,8
    80002a7a:	8626                	mv	a2,s1
    80002a7c:	85ca                	mv	a1,s2
    80002a7e:	6d28                	ld	a0,88(a0)
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	c78080e7          	jalr	-904(ra) # 800016f8 <copyin>
    80002a88:	00a03533          	snez	a0,a0
    80002a8c:	40a00533          	neg	a0,a0
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6902                	ld	s2,0(sp)
    80002a98:	6105                	addi	sp,sp,32
    80002a9a:	8082                	ret
    return -1;
    80002a9c:	557d                	li	a0,-1
    80002a9e:	bfcd                	j	80002a90 <fetchaddr+0x3e>
    80002aa0:	557d                	li	a0,-1
    80002aa2:	b7fd                	j	80002a90 <fetchaddr+0x3e>

0000000080002aa4 <fetchstr>:
{
    80002aa4:	7179                	addi	sp,sp,-48
    80002aa6:	f406                	sd	ra,40(sp)
    80002aa8:	f022                	sd	s0,32(sp)
    80002aaa:	ec26                	sd	s1,24(sp)
    80002aac:	e84a                	sd	s2,16(sp)
    80002aae:	e44e                	sd	s3,8(sp)
    80002ab0:	1800                	addi	s0,sp,48
    80002ab2:	892a                	mv	s2,a0
    80002ab4:	84ae                	mv	s1,a1
    80002ab6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ab8:	fffff097          	auipc	ra,0xfffff
    80002abc:	ef4080e7          	jalr	-268(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ac0:	86ce                	mv	a3,s3
    80002ac2:	864a                	mv	a2,s2
    80002ac4:	85a6                	mv	a1,s1
    80002ac6:	6d28                	ld	a0,88(a0)
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	cbe080e7          	jalr	-834(ra) # 80001786 <copyinstr>
    80002ad0:	00054e63          	bltz	a0,80002aec <fetchstr+0x48>
  return strlen(buf);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	378080e7          	jalr	888(ra) # 80000e4e <strlen>
}
    80002ade:	70a2                	ld	ra,40(sp)
    80002ae0:	7402                	ld	s0,32(sp)
    80002ae2:	64e2                	ld	s1,24(sp)
    80002ae4:	6942                	ld	s2,16(sp)
    80002ae6:	69a2                	ld	s3,8(sp)
    80002ae8:	6145                	addi	sp,sp,48
    80002aea:	8082                	ret
    return -1;
    80002aec:	557d                	li	a0,-1
    80002aee:	bfc5                	j	80002ade <fetchstr+0x3a>

0000000080002af0 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	1000                	addi	s0,sp,32
    80002afa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	eee080e7          	jalr	-274(ra) # 800029ea <argraw>
    80002b04:	c088                	sw	a0,0(s1)
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6105                	addi	sp,sp,32
    80002b0e:	8082                	ret

0000000080002b10 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	e426                	sd	s1,8(sp)
    80002b18:	1000                	addi	s0,sp,32
    80002b1a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	ece080e7          	jalr	-306(ra) # 800029ea <argraw>
    80002b24:	e088                	sd	a0,0(s1)
}
    80002b26:	60e2                	ld	ra,24(sp)
    80002b28:	6442                	ld	s0,16(sp)
    80002b2a:	64a2                	ld	s1,8(sp)
    80002b2c:	6105                	addi	sp,sp,32
    80002b2e:	8082                	ret

0000000080002b30 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002b30:	7179                	addi	sp,sp,-48
    80002b32:	f406                	sd	ra,40(sp)
    80002b34:	f022                	sd	s0,32(sp)
    80002b36:	ec26                	sd	s1,24(sp)
    80002b38:	e84a                	sd	s2,16(sp)
    80002b3a:	1800                	addi	s0,sp,48
    80002b3c:	84ae                	mv	s1,a1
    80002b3e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b40:	fd840593          	addi	a1,s0,-40
    80002b44:	00000097          	auipc	ra,0x0
    80002b48:	fcc080e7          	jalr	-52(ra) # 80002b10 <argaddr>
  return fetchstr(addr, buf, max);
    80002b4c:	864a                	mv	a2,s2
    80002b4e:	85a6                	mv	a1,s1
    80002b50:	fd843503          	ld	a0,-40(s0)
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	f50080e7          	jalr	-176(ra) # 80002aa4 <fetchstr>
}
    80002b5c:	70a2                	ld	ra,40(sp)
    80002b5e:	7402                	ld	s0,32(sp)
    80002b60:	64e2                	ld	s1,24(sp)
    80002b62:	6942                	ld	s2,16(sp)
    80002b64:	6145                	addi	sp,sp,48
    80002b66:	8082                	ret

0000000080002b68 <prompt_strace>:
    [SYS_close].numArgs = 1,
    [SYS_strace].numArgs = 1,
};

void prompt_strace(struct proc *p, int num)
{
    80002b68:	715d                	addi	sp,sp,-80
    80002b6a:	e486                	sd	ra,72(sp)
    80002b6c:	e0a2                	sd	s0,64(sp)
    80002b6e:	fc26                	sd	s1,56(sp)
    80002b70:	f84a                	sd	s2,48(sp)
    80002b72:	f44e                	sd	s3,40(sp)
    80002b74:	f052                	sd	s4,32(sp)
    80002b76:	ec56                	sd	s5,24(sp)
    80002b78:	0880                	addi	s0,sp,80
    80002b7a:	8a2a                	mv	s4,a0
    80002b7c:	892e                	mv	s2,a1
  printf("%d: syscall %s (", p->pid, syscall_info[num].name);
    80002b7e:	00459793          	slli	a5,a1,0x4
    80002b82:	00006497          	auipc	s1,0x6
    80002b86:	de648493          	addi	s1,s1,-538 # 80008968 <syscall_info>
    80002b8a:	94be                	add	s1,s1,a5
    80002b8c:	6090                	ld	a2,0(s1)
    80002b8e:	590c                	lw	a1,48(a0)
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	89850513          	addi	a0,a0,-1896 # 80008428 <states.0+0x160>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9f2080e7          	jalr	-1550(ra) # 8000058a <printf>
  int arg;
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80002ba0:	449c                	lw	a5,8(s1)
    80002ba2:	04f05d63          	blez	a5,80002bfc <prompt_strace+0x94>
    80002ba6:	4481                	li	s1,0
  {
    argint(i, &arg);
    printf((i == syscall_info[num].numArgs - 1) ? "%d" : "%d ", arg);
    80002ba8:	00491593          	slli	a1,s2,0x4
    80002bac:	00006917          	auipc	s2,0x6
    80002bb0:	dbc90913          	addi	s2,s2,-580 # 80008968 <syscall_info>
    80002bb4:	992e                	add	s2,s2,a1
    80002bb6:	00006997          	auipc	s3,0x6
    80002bba:	86298993          	addi	s3,s3,-1950 # 80008418 <states.0+0x150>
    80002bbe:	00006a97          	auipc	s5,0x6
    80002bc2:	862a8a93          	addi	s5,s5,-1950 # 80008420 <states.0+0x158>
    80002bc6:	a821                	j	80002bde <prompt_strace+0x76>
    80002bc8:	fbc42583          	lw	a1,-68(s0)
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9be080e7          	jalr	-1602(ra) # 8000058a <printf>
  for (int i = 0; i < syscall_info[num].numArgs; i++)
    80002bd4:	2485                	addiw	s1,s1,1
    80002bd6:	00892783          	lw	a5,8(s2)
    80002bda:	02f4d163          	bge	s1,a5,80002bfc <prompt_strace+0x94>
    argint(i, &arg);
    80002bde:	fbc40593          	addi	a1,s0,-68
    80002be2:	8526                	mv	a0,s1
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	f0c080e7          	jalr	-244(ra) # 80002af0 <argint>
    printf((i == syscall_info[num].numArgs - 1) ? "%d" : "%d ", arg);
    80002bec:	00892783          	lw	a5,8(s2)
    80002bf0:	37fd                	addiw	a5,a5,-1
    80002bf2:	854e                	mv	a0,s3
    80002bf4:	fc978ae3          	beq	a5,s1,80002bc8 <prompt_strace+0x60>
    80002bf8:	8556                	mv	a0,s5
    80002bfa:	b7f9                	j	80002bc8 <prompt_strace+0x60>
  }
  printf(") -> %d\n", p->trapframe->a0);
    80002bfc:	060a3783          	ld	a5,96(s4)
    80002c00:	7bac                	ld	a1,112(a5)
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	83e50513          	addi	a0,a0,-1986 # 80008440 <states.0+0x178>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	980080e7          	jalr	-1664(ra) # 8000058a <printf>
  return;
}
    80002c12:	60a6                	ld	ra,72(sp)
    80002c14:	6406                	ld	s0,64(sp)
    80002c16:	74e2                	ld	s1,56(sp)
    80002c18:	7942                	ld	s2,48(sp)
    80002c1a:	79a2                	ld	s3,40(sp)
    80002c1c:	7a02                	ld	s4,32(sp)
    80002c1e:	6ae2                	ld	s5,24(sp)
    80002c20:	6161                	addi	sp,sp,80
    80002c22:	8082                	ret

0000000080002c24 <syscall>:

void syscall(void)
{
    80002c24:	7179                	addi	sp,sp,-48
    80002c26:	f406                	sd	ra,40(sp)
    80002c28:	f022                	sd	s0,32(sp)
    80002c2a:	ec26                	sd	s1,24(sp)
    80002c2c:	e84a                	sd	s2,16(sp)
    80002c2e:	e44e                	sd	s3,8(sp)
    80002c30:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	d7a080e7          	jalr	-646(ra) # 800019ac <myproc>
    80002c3a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3c:	06053983          	ld	s3,96(a0)
    80002c40:	0a89b783          	ld	a5,168(s3)
    80002c44:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c48:	37fd                	addiw	a5,a5,-1
    80002c4a:	4755                	li	a4,21
    80002c4c:	02f76b63          	bltu	a4,a5,80002c82 <syscall+0x5e>
    80002c50:	00391713          	slli	a4,s2,0x3
    80002c54:	00006797          	auipc	a5,0x6
    80002c58:	8dc78793          	addi	a5,a5,-1828 # 80008530 <syscalls>
    80002c5c:	97ba                	add	a5,a5,a4
    80002c5e:	639c                	ld	a5,0(a5)
    80002c60:	c7b9                	beqz	a5,80002cae <syscall+0x8a>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c62:	9782                	jalr	a5
    80002c64:	06a9b823          	sd	a0,112(s3)
  {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }

  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && (p->strace_bit & (1 << num)))
    80002c68:	1704a783          	lw	a5,368(s1)
    80002c6c:	4127d7bb          	sraw	a5,a5,s2
    80002c70:	8b85                	andi	a5,a5,1
    80002c72:	c79d                	beqz	a5,80002ca0 <syscall+0x7c>
  {
    prompt_strace(p, num);
    80002c74:	85ca                	mv	a1,s2
    80002c76:	8526                	mv	a0,s1
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	ef0080e7          	jalr	-272(ra) # 80002b68 <prompt_strace>
  }
  return;
    80002c80:	a005                	j	80002ca0 <syscall+0x7c>
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80002c82:	86ca                	mv	a3,s2
    80002c84:	16050613          	addi	a2,a0,352
    80002c88:	590c                	lw	a1,48(a0)
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	7c650513          	addi	a0,a0,1990 # 80008450 <states.0+0x188>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8f8080e7          	jalr	-1800(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80002c9a:	70bc                	ld	a5,96(s1)
    80002c9c:	577d                	li	a4,-1
    80002c9e:	fbb8                	sd	a4,112(a5)
}
    80002ca0:	70a2                	ld	ra,40(sp)
    80002ca2:	7402                	ld	s0,32(sp)
    80002ca4:	64e2                	ld	s1,24(sp)
    80002ca6:	6942                	ld	s2,16(sp)
    80002ca8:	69a2                	ld	s3,8(sp)
    80002caa:	6145                	addi	sp,sp,48
    80002cac:	8082                	ret
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    80002cae:	86ca                	mv	a3,s2
    80002cb0:	16050613          	addi	a2,a0,352
    80002cb4:	590c                	lw	a1,48(a0)
    80002cb6:	00005517          	auipc	a0,0x5
    80002cba:	79a50513          	addi	a0,a0,1946 # 80008450 <states.0+0x188>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	8cc080e7          	jalr	-1844(ra) # 8000058a <printf>
    p->trapframe->a0 = -1;
    80002cc6:	70bc                	ld	a5,96(s1)
    80002cc8:	577d                	li	a4,-1
    80002cca:	fbb8                	sd	a4,112(a5)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && (p->strace_bit & (1 << num)))
    80002ccc:	00391713          	slli	a4,s2,0x3
    80002cd0:	00006797          	auipc	a5,0x6
    80002cd4:	86078793          	addi	a5,a5,-1952 # 80008530 <syscalls>
    80002cd8:	97ba                	add	a5,a5,a4
    80002cda:	639c                	ld	a5,0(a5)
    80002cdc:	d3f1                	beqz	a5,80002ca0 <syscall+0x7c>
    80002cde:	b769                	j	80002c68 <syscall+0x44>

0000000080002ce0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ce8:	fec40593          	addi	a1,s0,-20
    80002cec:	4501                	li	a0,0
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	e02080e7          	jalr	-510(ra) # 80002af0 <argint>
  exit(n);
    80002cf6:	fec42503          	lw	a0,-20(s0)
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	49a080e7          	jalr	1178(ra) # 80002194 <exit>
  return 0;  // not reached
}
    80002d02:	4501                	li	a0,0
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d0c:	1141                	addi	sp,sp,-16
    80002d0e:	e406                	sd	ra,8(sp)
    80002d10:	e022                	sd	s0,0(sp)
    80002d12:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
}
    80002d1c:	5908                	lw	a0,48(a0)
    80002d1e:	60a2                	ld	ra,8(sp)
    80002d20:	6402                	ld	s0,0(sp)
    80002d22:	0141                	addi	sp,sp,16
    80002d24:	8082                	ret

0000000080002d26 <sys_fork>:

uint64
sys_fork(void)
{
    80002d26:	1141                	addi	sp,sp,-16
    80002d28:	e406                	sd	ra,8(sp)
    80002d2a:	e022                	sd	s0,0(sp)
    80002d2c:	0800                	addi	s0,sp,16
  return fork();
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	038080e7          	jalr	56(ra) # 80001d66 <fork>
}
    80002d36:	60a2                	ld	ra,8(sp)
    80002d38:	6402                	ld	s0,0(sp)
    80002d3a:	0141                	addi	sp,sp,16
    80002d3c:	8082                	ret

0000000080002d3e <sys_wait>:

uint64
sys_wait(void)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d46:	fe840593          	addi	a1,s0,-24
    80002d4a:	4501                	li	a0,0
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	dc4080e7          	jalr	-572(ra) # 80002b10 <argaddr>
  return wait(p);
    80002d54:	fe843503          	ld	a0,-24(s0)
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	5e2080e7          	jalr	1506(ra) # 8000233a <wait>
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	6105                	addi	sp,sp,32
    80002d66:	8082                	ret

0000000080002d68 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d68:	7179                	addi	sp,sp,-48
    80002d6a:	f406                	sd	ra,40(sp)
    80002d6c:	f022                	sd	s0,32(sp)
    80002d6e:	ec26                	sd	s1,24(sp)
    80002d70:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d72:	fdc40593          	addi	a1,s0,-36
    80002d76:	4501                	li	a0,0
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	d78080e7          	jalr	-648(ra) # 80002af0 <argint>
  addr = myproc()->sz;
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	c2c080e7          	jalr	-980(ra) # 800019ac <myproc>
    80002d88:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d8a:	fdc42503          	lw	a0,-36(s0)
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	f7c080e7          	jalr	-132(ra) # 80001d0a <growproc>
    80002d96:	00054863          	bltz	a0,80002da6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d9a:	8526                	mv	a0,s1
    80002d9c:	70a2                	ld	ra,40(sp)
    80002d9e:	7402                	ld	s0,32(sp)
    80002da0:	64e2                	ld	s1,24(sp)
    80002da2:	6145                	addi	sp,sp,48
    80002da4:	8082                	ret
    return -1;
    80002da6:	54fd                	li	s1,-1
    80002da8:	bfcd                	j	80002d9a <sys_sbrk+0x32>

0000000080002daa <sys_sleep>:

uint64
sys_sleep(void)
{
    80002daa:	7139                	addi	sp,sp,-64
    80002dac:	fc06                	sd	ra,56(sp)
    80002dae:	f822                	sd	s0,48(sp)
    80002db0:	f426                	sd	s1,40(sp)
    80002db2:	f04a                	sd	s2,32(sp)
    80002db4:	ec4e                	sd	s3,24(sp)
    80002db6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002db8:	fcc40593          	addi	a1,s0,-52
    80002dbc:	4501                	li	a0,0
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	d32080e7          	jalr	-718(ra) # 80002af0 <argint>
  acquire(&tickslock);
    80002dc6:	00014517          	auipc	a0,0x14
    80002dca:	20a50513          	addi	a0,a0,522 # 80016fd0 <tickslock>
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	e08080e7          	jalr	-504(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002dd6:	00006917          	auipc	s2,0x6
    80002dda:	d5a92903          	lw	s2,-678(s2) # 80008b30 <ticks>
  while(ticks - ticks0 < n){
    80002dde:	fcc42783          	lw	a5,-52(s0)
    80002de2:	cf9d                	beqz	a5,80002e20 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002de4:	00014997          	auipc	s3,0x14
    80002de8:	1ec98993          	addi	s3,s3,492 # 80016fd0 <tickslock>
    80002dec:	00006497          	auipc	s1,0x6
    80002df0:	d4448493          	addi	s1,s1,-700 # 80008b30 <ticks>
    if(killed(myproc())){
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	bb8080e7          	jalr	-1096(ra) # 800019ac <myproc>
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	50c080e7          	jalr	1292(ra) # 80002308 <killed>
    80002e04:	ed15                	bnez	a0,80002e40 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e06:	85ce                	mv	a1,s3
    80002e08:	8526                	mv	a0,s1
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	256080e7          	jalr	598(ra) # 80002060 <sleep>
  while(ticks - ticks0 < n){
    80002e12:	409c                	lw	a5,0(s1)
    80002e14:	412787bb          	subw	a5,a5,s2
    80002e18:	fcc42703          	lw	a4,-52(s0)
    80002e1c:	fce7ece3          	bltu	a5,a4,80002df4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e20:	00014517          	auipc	a0,0x14
    80002e24:	1b050513          	addi	a0,a0,432 # 80016fd0 <tickslock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e62080e7          	jalr	-414(ra) # 80000c8a <release>
  return 0;
    80002e30:	4501                	li	a0,0
}
    80002e32:	70e2                	ld	ra,56(sp)
    80002e34:	7442                	ld	s0,48(sp)
    80002e36:	74a2                	ld	s1,40(sp)
    80002e38:	7902                	ld	s2,32(sp)
    80002e3a:	69e2                	ld	s3,24(sp)
    80002e3c:	6121                	addi	sp,sp,64
    80002e3e:	8082                	ret
      release(&tickslock);
    80002e40:	00014517          	auipc	a0,0x14
    80002e44:	19050513          	addi	a0,a0,400 # 80016fd0 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
      return -1;
    80002e50:	557d                	li	a0,-1
    80002e52:	b7c5                	j	80002e32 <sys_sleep+0x88>

0000000080002e54 <sys_kill>:

uint64
sys_kill(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e5c:	fec40593          	addi	a1,s0,-20
    80002e60:	4501                	li	a0,0
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	c8e080e7          	jalr	-882(ra) # 80002af0 <argint>
  return kill(pid);
    80002e6a:	fec42503          	lw	a0,-20(s0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	3fc080e7          	jalr	1020(ra) # 8000226a <kill>
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret

0000000080002e7e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e7e:	1101                	addi	sp,sp,-32
    80002e80:	ec06                	sd	ra,24(sp)
    80002e82:	e822                	sd	s0,16(sp)
    80002e84:	e426                	sd	s1,8(sp)
    80002e86:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e88:	00014517          	auipc	a0,0x14
    80002e8c:	14850513          	addi	a0,a0,328 # 80016fd0 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	d46080e7          	jalr	-698(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e98:	00006497          	auipc	s1,0x6
    80002e9c:	c984a483          	lw	s1,-872(s1) # 80008b30 <ticks>
  release(&tickslock);
    80002ea0:	00014517          	auipc	a0,0x14
    80002ea4:	13050513          	addi	a0,a0,304 # 80016fd0 <tickslock>
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	de2080e7          	jalr	-542(ra) # 80000c8a <release>
  return xticks;
}
    80002eb0:	02049513          	slli	a0,s1,0x20
    80002eb4:	9101                	srli	a0,a0,0x20
    80002eb6:	60e2                	ld	ra,24(sp)
    80002eb8:	6442                	ld	s0,16(sp)
    80002eba:	64a2                	ld	s1,8(sp)
    80002ebc:	6105                	addi	sp,sp,32
    80002ebe:	8082                	ret

0000000080002ec0 <sys_strace>:

uint64
sys_strace(void)
{
    80002ec0:	1101                	addi	sp,sp,-32
    80002ec2:	ec06                	sd	ra,24(sp)
    80002ec4:	e822                	sd	s0,16(sp)
    80002ec6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ec8:	fec40593          	addi	a1,s0,-20
    80002ecc:	4501                	li	a0,0
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	c22080e7          	jalr	-990(ra) # 80002af0 <argint>
  strace(n);
    80002ed6:	fec42503          	lw	a0,-20(s0)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	6ea080e7          	jalr	1770(ra) # 800025c4 <strace>
  return 0;
}
    80002ee2:	4501                	li	a0,0
    80002ee4:	60e2                	ld	ra,24(sp)
    80002ee6:	6442                	ld	s0,16(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret

0000000080002eec <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	e052                	sd	s4,0(sp)
    80002efa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002efc:	00005597          	auipc	a1,0x5
    80002f00:	6ec58593          	addi	a1,a1,1772 # 800085e8 <syscalls+0xb8>
    80002f04:	00014517          	auipc	a0,0x14
    80002f08:	0e450513          	addi	a0,a0,228 # 80016fe8 <bcache>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	c3a080e7          	jalr	-966(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f14:	0001c797          	auipc	a5,0x1c
    80002f18:	0d478793          	addi	a5,a5,212 # 8001efe8 <bcache+0x8000>
    80002f1c:	0001c717          	auipc	a4,0x1c
    80002f20:	33470713          	addi	a4,a4,820 # 8001f250 <bcache+0x8268>
    80002f24:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f28:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f2c:	00014497          	auipc	s1,0x14
    80002f30:	0d448493          	addi	s1,s1,212 # 80017000 <bcache+0x18>
    b->next = bcache.head.next;
    80002f34:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f36:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f38:	00005a17          	auipc	s4,0x5
    80002f3c:	6b8a0a13          	addi	s4,s4,1720 # 800085f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f40:	2b893783          	ld	a5,696(s2)
    80002f44:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f46:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f4a:	85d2                	mv	a1,s4
    80002f4c:	01048513          	addi	a0,s1,16
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	4c8080e7          	jalr	1224(ra) # 80004418 <initsleeplock>
    bcache.head.next->prev = b;
    80002f58:	2b893783          	ld	a5,696(s2)
    80002f5c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f5e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f62:	45848493          	addi	s1,s1,1112
    80002f66:	fd349de3          	bne	s1,s3,80002f40 <binit+0x54>
  }
}
    80002f6a:	70a2                	ld	ra,40(sp)
    80002f6c:	7402                	ld	s0,32(sp)
    80002f6e:	64e2                	ld	s1,24(sp)
    80002f70:	6942                	ld	s2,16(sp)
    80002f72:	69a2                	ld	s3,8(sp)
    80002f74:	6a02                	ld	s4,0(sp)
    80002f76:	6145                	addi	sp,sp,48
    80002f78:	8082                	ret

0000000080002f7a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f7a:	7179                	addi	sp,sp,-48
    80002f7c:	f406                	sd	ra,40(sp)
    80002f7e:	f022                	sd	s0,32(sp)
    80002f80:	ec26                	sd	s1,24(sp)
    80002f82:	e84a                	sd	s2,16(sp)
    80002f84:	e44e                	sd	s3,8(sp)
    80002f86:	1800                	addi	s0,sp,48
    80002f88:	892a                	mv	s2,a0
    80002f8a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f8c:	00014517          	auipc	a0,0x14
    80002f90:	05c50513          	addi	a0,a0,92 # 80016fe8 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	c42080e7          	jalr	-958(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f9c:	0001c497          	auipc	s1,0x1c
    80002fa0:	3044b483          	ld	s1,772(s1) # 8001f2a0 <bcache+0x82b8>
    80002fa4:	0001c797          	auipc	a5,0x1c
    80002fa8:	2ac78793          	addi	a5,a5,684 # 8001f250 <bcache+0x8268>
    80002fac:	02f48f63          	beq	s1,a5,80002fea <bread+0x70>
    80002fb0:	873e                	mv	a4,a5
    80002fb2:	a021                	j	80002fba <bread+0x40>
    80002fb4:	68a4                	ld	s1,80(s1)
    80002fb6:	02e48a63          	beq	s1,a4,80002fea <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fba:	449c                	lw	a5,8(s1)
    80002fbc:	ff279ce3          	bne	a5,s2,80002fb4 <bread+0x3a>
    80002fc0:	44dc                	lw	a5,12(s1)
    80002fc2:	ff3799e3          	bne	a5,s3,80002fb4 <bread+0x3a>
      b->refcnt++;
    80002fc6:	40bc                	lw	a5,64(s1)
    80002fc8:	2785                	addiw	a5,a5,1
    80002fca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	01c50513          	addi	a0,a0,28 # 80016fe8 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	cb6080e7          	jalr	-842(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fdc:	01048513          	addi	a0,s1,16
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	472080e7          	jalr	1138(ra) # 80004452 <acquiresleep>
      return b;
    80002fe8:	a8b9                	j	80003046 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fea:	0001c497          	auipc	s1,0x1c
    80002fee:	2ae4b483          	ld	s1,686(s1) # 8001f298 <bcache+0x82b0>
    80002ff2:	0001c797          	auipc	a5,0x1c
    80002ff6:	25e78793          	addi	a5,a5,606 # 8001f250 <bcache+0x8268>
    80002ffa:	00f48863          	beq	s1,a5,8000300a <bread+0x90>
    80002ffe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	cf81                	beqz	a5,8000301a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003004:	64a4                	ld	s1,72(s1)
    80003006:	fee49de3          	bne	s1,a4,80003000 <bread+0x86>
  panic("bget: no buffers");
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	5ee50513          	addi	a0,a0,1518 # 800085f8 <syscalls+0xc8>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	52e080e7          	jalr	1326(ra) # 80000540 <panic>
      b->dev = dev;
    8000301a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000301e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003022:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003026:	4785                	li	a5,1
    80003028:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	fbe50513          	addi	a0,a0,-66 # 80016fe8 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c58080e7          	jalr	-936(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000303a:	01048513          	addi	a0,s1,16
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	414080e7          	jalr	1044(ra) # 80004452 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003046:	409c                	lw	a5,0(s1)
    80003048:	cb89                	beqz	a5,8000305a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000304a:	8526                	mv	a0,s1
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6942                	ld	s2,16(sp)
    80003054:	69a2                	ld	s3,8(sp)
    80003056:	6145                	addi	sp,sp,48
    80003058:	8082                	ret
    virtio_disk_rw(b, 0);
    8000305a:	4581                	li	a1,0
    8000305c:	8526                	mv	a0,s1
    8000305e:	00003097          	auipc	ra,0x3
    80003062:	fe4080e7          	jalr	-28(ra) # 80006042 <virtio_disk_rw>
    b->valid = 1;
    80003066:	4785                	li	a5,1
    80003068:	c09c                	sw	a5,0(s1)
  return b;
    8000306a:	b7c5                	j	8000304a <bread+0xd0>

000000008000306c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003078:	0541                	addi	a0,a0,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	472080e7          	jalr	1138(ra) # 800044ec <holdingsleep>
    80003082:	cd01                	beqz	a0,8000309a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003084:	4585                	li	a1,1
    80003086:	8526                	mv	a0,s1
    80003088:	00003097          	auipc	ra,0x3
    8000308c:	fba080e7          	jalr	-70(ra) # 80006042 <virtio_disk_rw>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    panic("bwrite");
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	57650513          	addi	a0,a0,1398 # 80008610 <syscalls+0xe0>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	49e080e7          	jalr	1182(ra) # 80000540 <panic>

00000000800030aa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	e04a                	sd	s2,0(sp)
    800030b4:	1000                	addi	s0,sp,32
    800030b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b8:	01050913          	addi	s2,a0,16
    800030bc:	854a                	mv	a0,s2
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	42e080e7          	jalr	1070(ra) # 800044ec <holdingsleep>
    800030c6:	c92d                	beqz	a0,80003138 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c8:	854a                	mv	a0,s2
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	3de080e7          	jalr	990(ra) # 800044a8 <releasesleep>

  acquire(&bcache.lock);
    800030d2:	00014517          	auipc	a0,0x14
    800030d6:	f1650513          	addi	a0,a0,-234 # 80016fe8 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	afc080e7          	jalr	-1284(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030e2:	40bc                	lw	a5,64(s1)
    800030e4:	37fd                	addiw	a5,a5,-1
    800030e6:	0007871b          	sext.w	a4,a5
    800030ea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ec:	eb05                	bnez	a4,8000311c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ee:	68bc                	ld	a5,80(s1)
    800030f0:	64b8                	ld	a4,72(s1)
    800030f2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f4:	64bc                	ld	a5,72(s1)
    800030f6:	68b8                	ld	a4,80(s1)
    800030f8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	eee78793          	addi	a5,a5,-274 # 8001efe8 <bcache+0x8000>
    80003102:	2b87b703          	ld	a4,696(a5)
    80003106:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003108:	0001c717          	auipc	a4,0x1c
    8000310c:	14870713          	addi	a4,a4,328 # 8001f250 <bcache+0x8268>
    80003110:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003112:	2b87b703          	ld	a4,696(a5)
    80003116:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003118:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000311c:	00014517          	auipc	a0,0x14
    80003120:	ecc50513          	addi	a0,a0,-308 # 80016fe8 <bcache>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	b66080e7          	jalr	-1178(ra) # 80000c8a <release>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("brelse");
    80003138:	00005517          	auipc	a0,0x5
    8000313c:	4e050513          	addi	a0,a0,1248 # 80008618 <syscalls+0xe8>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	400080e7          	jalr	1024(ra) # 80000540 <panic>

0000000080003148 <bpin>:

void
bpin(struct buf *b) {
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	e9450513          	addi	a0,a0,-364 # 80016fe8 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	a7a080e7          	jalr	-1414(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003164:	40bc                	lw	a5,64(s1)
    80003166:	2785                	addiw	a5,a5,1
    80003168:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	e7e50513          	addi	a0,a0,-386 # 80016fe8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	b18080e7          	jalr	-1256(ra) # 80000c8a <release>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <bunpin>:

void
bunpin(struct buf *b) {
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003190:	00014517          	auipc	a0,0x14
    80003194:	e5850513          	addi	a0,a0,-424 # 80016fe8 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	a3e080e7          	jalr	-1474(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031a0:	40bc                	lw	a5,64(s1)
    800031a2:	37fd                	addiw	a5,a5,-1
    800031a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	e4250513          	addi	a0,a0,-446 # 80016fe8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	adc080e7          	jalr	-1316(ra) # 80000c8a <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	e04a                	sd	s2,0(sp)
    800031ca:	1000                	addi	s0,sp,32
    800031cc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ce:	00d5d59b          	srliw	a1,a1,0xd
    800031d2:	0001c797          	auipc	a5,0x1c
    800031d6:	4f27a783          	lw	a5,1266(a5) # 8001f6c4 <sb+0x1c>
    800031da:	9dbd                	addw	a1,a1,a5
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	d9e080e7          	jalr	-610(ra) # 80002f7a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e4:	0074f713          	andi	a4,s1,7
    800031e8:	4785                	li	a5,1
    800031ea:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ee:	14ce                	slli	s1,s1,0x33
    800031f0:	90d9                	srli	s1,s1,0x36
    800031f2:	00950733          	add	a4,a0,s1
    800031f6:	05874703          	lbu	a4,88(a4)
    800031fa:	00e7f6b3          	and	a3,a5,a4
    800031fe:	c69d                	beqz	a3,8000322c <bfree+0x6c>
    80003200:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003202:	94aa                	add	s1,s1,a0
    80003204:	fff7c793          	not	a5,a5
    80003208:	8f7d                	and	a4,a4,a5
    8000320a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	126080e7          	jalr	294(ra) # 80004334 <log_write>
  brelse(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e92080e7          	jalr	-366(ra) # 800030aa <brelse>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("freeing free block");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	3f450513          	addi	a0,a0,1012 # 80008620 <syscalls+0xf0>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	30c080e7          	jalr	780(ra) # 80000540 <panic>

000000008000323c <balloc>:
{
    8000323c:	711d                	addi	sp,sp,-96
    8000323e:	ec86                	sd	ra,88(sp)
    80003240:	e8a2                	sd	s0,80(sp)
    80003242:	e4a6                	sd	s1,72(sp)
    80003244:	e0ca                	sd	s2,64(sp)
    80003246:	fc4e                	sd	s3,56(sp)
    80003248:	f852                	sd	s4,48(sp)
    8000324a:	f456                	sd	s5,40(sp)
    8000324c:	f05a                	sd	s6,32(sp)
    8000324e:	ec5e                	sd	s7,24(sp)
    80003250:	e862                	sd	s8,16(sp)
    80003252:	e466                	sd	s9,8(sp)
    80003254:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003256:	0001c797          	auipc	a5,0x1c
    8000325a:	4567a783          	lw	a5,1110(a5) # 8001f6ac <sb+0x4>
    8000325e:	cff5                	beqz	a5,8000335a <balloc+0x11e>
    80003260:	8baa                	mv	s7,a0
    80003262:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003264:	0001cb17          	auipc	s6,0x1c
    80003268:	444b0b13          	addi	s6,s6,1092 # 8001f6a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000326e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003272:	6c89                	lui	s9,0x2
    80003274:	a061                	j	800032fc <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003276:	97ca                	add	a5,a5,s2
    80003278:	8e55                	or	a2,a2,a3
    8000327a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00001097          	auipc	ra,0x1
    80003284:	0b4080e7          	jalr	180(ra) # 80004334 <log_write>
        brelse(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	e20080e7          	jalr	-480(ra) # 800030aa <brelse>
  bp = bread(dev, bno);
    80003292:	85a6                	mv	a1,s1
    80003294:	855e                	mv	a0,s7
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	ce4080e7          	jalr	-796(ra) # 80002f7a <bread>
    8000329e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a0:	40000613          	li	a2,1024
    800032a4:	4581                	li	a1,0
    800032a6:	05850513          	addi	a0,a0,88
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a28080e7          	jalr	-1496(ra) # 80000cd2 <memset>
  log_write(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	080080e7          	jalr	128(ra) # 80004334 <log_write>
  brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	dec080e7          	jalr	-532(ra) # 800030aa <brelse>
}
    800032c6:	8526                	mv	a0,s1
    800032c8:	60e6                	ld	ra,88(sp)
    800032ca:	6446                	ld	s0,80(sp)
    800032cc:	64a6                	ld	s1,72(sp)
    800032ce:	6906                	ld	s2,64(sp)
    800032d0:	79e2                	ld	s3,56(sp)
    800032d2:	7a42                	ld	s4,48(sp)
    800032d4:	7aa2                	ld	s5,40(sp)
    800032d6:	7b02                	ld	s6,32(sp)
    800032d8:	6be2                	ld	s7,24(sp)
    800032da:	6c42                	ld	s8,16(sp)
    800032dc:	6ca2                	ld	s9,8(sp)
    800032de:	6125                	addi	sp,sp,96
    800032e0:	8082                	ret
    brelse(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	dc6080e7          	jalr	-570(ra) # 800030aa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ec:	015c87bb          	addw	a5,s9,s5
    800032f0:	00078a9b          	sext.w	s5,a5
    800032f4:	004b2703          	lw	a4,4(s6)
    800032f8:	06eaf163          	bgeu	s5,a4,8000335a <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003300:	0137d79b          	srliw	a5,a5,0x13
    80003304:	015787bb          	addw	a5,a5,s5
    80003308:	40d7d79b          	sraiw	a5,a5,0xd
    8000330c:	01cb2583          	lw	a1,28(s6)
    80003310:	9dbd                	addw	a1,a1,a5
    80003312:	855e                	mv	a0,s7
    80003314:	00000097          	auipc	ra,0x0
    80003318:	c66080e7          	jalr	-922(ra) # 80002f7a <bread>
    8000331c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331e:	004b2503          	lw	a0,4(s6)
    80003322:	000a849b          	sext.w	s1,s5
    80003326:	8762                	mv	a4,s8
    80003328:	faa4fde3          	bgeu	s1,a0,800032e2 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000332c:	00777693          	andi	a3,a4,7
    80003330:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003334:	41f7579b          	sraiw	a5,a4,0x1f
    80003338:	01d7d79b          	srliw	a5,a5,0x1d
    8000333c:	9fb9                	addw	a5,a5,a4
    8000333e:	4037d79b          	sraiw	a5,a5,0x3
    80003342:	00f90633          	add	a2,s2,a5
    80003346:	05864603          	lbu	a2,88(a2)
    8000334a:	00c6f5b3          	and	a1,a3,a2
    8000334e:	d585                	beqz	a1,80003276 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003350:	2705                	addiw	a4,a4,1
    80003352:	2485                	addiw	s1,s1,1
    80003354:	fd471ae3          	bne	a4,s4,80003328 <balloc+0xec>
    80003358:	b769                	j	800032e2 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000335a:	00005517          	auipc	a0,0x5
    8000335e:	2de50513          	addi	a0,a0,734 # 80008638 <syscalls+0x108>
    80003362:	ffffd097          	auipc	ra,0xffffd
    80003366:	228080e7          	jalr	552(ra) # 8000058a <printf>
  return 0;
    8000336a:	4481                	li	s1,0
    8000336c:	bfa9                	j	800032c6 <balloc+0x8a>

000000008000336e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000336e:	7179                	addi	sp,sp,-48
    80003370:	f406                	sd	ra,40(sp)
    80003372:	f022                	sd	s0,32(sp)
    80003374:	ec26                	sd	s1,24(sp)
    80003376:	e84a                	sd	s2,16(sp)
    80003378:	e44e                	sd	s3,8(sp)
    8000337a:	e052                	sd	s4,0(sp)
    8000337c:	1800                	addi	s0,sp,48
    8000337e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003380:	47ad                	li	a5,11
    80003382:	02b7e863          	bltu	a5,a1,800033b2 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003386:	02059793          	slli	a5,a1,0x20
    8000338a:	01e7d593          	srli	a1,a5,0x1e
    8000338e:	00b504b3          	add	s1,a0,a1
    80003392:	0504a903          	lw	s2,80(s1)
    80003396:	06091e63          	bnez	s2,80003412 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000339a:	4108                	lw	a0,0(a0)
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	ea0080e7          	jalr	-352(ra) # 8000323c <balloc>
    800033a4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033a8:	06090563          	beqz	s2,80003412 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033ac:	0524a823          	sw	s2,80(s1)
    800033b0:	a08d                	j	80003412 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033b2:	ff45849b          	addiw	s1,a1,-12
    800033b6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ba:	0ff00793          	li	a5,255
    800033be:	08e7e563          	bltu	a5,a4,80003448 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033c2:	08052903          	lw	s2,128(a0)
    800033c6:	00091d63          	bnez	s2,800033e0 <bmap+0x72>
      addr = balloc(ip->dev);
    800033ca:	4108                	lw	a0,0(a0)
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e70080e7          	jalr	-400(ra) # 8000323c <balloc>
    800033d4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033d8:	02090d63          	beqz	s2,80003412 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033dc:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033e0:	85ca                	mv	a1,s2
    800033e2:	0009a503          	lw	a0,0(s3)
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	b94080e7          	jalr	-1132(ra) # 80002f7a <bread>
    800033ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033f4:	02049713          	slli	a4,s1,0x20
    800033f8:	01e75593          	srli	a1,a4,0x1e
    800033fc:	00b784b3          	add	s1,a5,a1
    80003400:	0004a903          	lw	s2,0(s1)
    80003404:	02090063          	beqz	s2,80003424 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003408:	8552                	mv	a0,s4
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	ca0080e7          	jalr	-864(ra) # 800030aa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003412:	854a                	mv	a0,s2
    80003414:	70a2                	ld	ra,40(sp)
    80003416:	7402                	ld	s0,32(sp)
    80003418:	64e2                	ld	s1,24(sp)
    8000341a:	6942                	ld	s2,16(sp)
    8000341c:	69a2                	ld	s3,8(sp)
    8000341e:	6a02                	ld	s4,0(sp)
    80003420:	6145                	addi	sp,sp,48
    80003422:	8082                	ret
      addr = balloc(ip->dev);
    80003424:	0009a503          	lw	a0,0(s3)
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	e14080e7          	jalr	-492(ra) # 8000323c <balloc>
    80003430:	0005091b          	sext.w	s2,a0
      if(addr){
    80003434:	fc090ae3          	beqz	s2,80003408 <bmap+0x9a>
        a[bn] = addr;
    80003438:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000343c:	8552                	mv	a0,s4
    8000343e:	00001097          	auipc	ra,0x1
    80003442:	ef6080e7          	jalr	-266(ra) # 80004334 <log_write>
    80003446:	b7c9                	j	80003408 <bmap+0x9a>
  panic("bmap: out of range");
    80003448:	00005517          	auipc	a0,0x5
    8000344c:	20850513          	addi	a0,a0,520 # 80008650 <syscalls+0x120>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	0f0080e7          	jalr	240(ra) # 80000540 <panic>

0000000080003458 <iget>:
{
    80003458:	7179                	addi	sp,sp,-48
    8000345a:	f406                	sd	ra,40(sp)
    8000345c:	f022                	sd	s0,32(sp)
    8000345e:	ec26                	sd	s1,24(sp)
    80003460:	e84a                	sd	s2,16(sp)
    80003462:	e44e                	sd	s3,8(sp)
    80003464:	e052                	sd	s4,0(sp)
    80003466:	1800                	addi	s0,sp,48
    80003468:	89aa                	mv	s3,a0
    8000346a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000346c:	0001c517          	auipc	a0,0x1c
    80003470:	25c50513          	addi	a0,a0,604 # 8001f6c8 <itable>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	762080e7          	jalr	1890(ra) # 80000bd6 <acquire>
  empty = 0;
    8000347c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000347e:	0001c497          	auipc	s1,0x1c
    80003482:	26248493          	addi	s1,s1,610 # 8001f6e0 <itable+0x18>
    80003486:	0001e697          	auipc	a3,0x1e
    8000348a:	cea68693          	addi	a3,a3,-790 # 80021170 <log>
    8000348e:	a039                	j	8000349c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003490:	02090b63          	beqz	s2,800034c6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003494:	08848493          	addi	s1,s1,136
    80003498:	02d48a63          	beq	s1,a3,800034cc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000349c:	449c                	lw	a5,8(s1)
    8000349e:	fef059e3          	blez	a5,80003490 <iget+0x38>
    800034a2:	4098                	lw	a4,0(s1)
    800034a4:	ff3716e3          	bne	a4,s3,80003490 <iget+0x38>
    800034a8:	40d8                	lw	a4,4(s1)
    800034aa:	ff4713e3          	bne	a4,s4,80003490 <iget+0x38>
      ip->ref++;
    800034ae:	2785                	addiw	a5,a5,1
    800034b0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034b2:	0001c517          	auipc	a0,0x1c
    800034b6:	21650513          	addi	a0,a0,534 # 8001f6c8 <itable>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
      return ip;
    800034c2:	8926                	mv	s2,s1
    800034c4:	a03d                	j	800034f2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c6:	f7f9                	bnez	a5,80003494 <iget+0x3c>
    800034c8:	8926                	mv	s2,s1
    800034ca:	b7e9                	j	80003494 <iget+0x3c>
  if(empty == 0)
    800034cc:	02090c63          	beqz	s2,80003504 <iget+0xac>
  ip->dev = dev;
    800034d0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034d4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034d8:	4785                	li	a5,1
    800034da:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034de:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034e2:	0001c517          	auipc	a0,0x1c
    800034e6:	1e650513          	addi	a0,a0,486 # 8001f6c8 <itable>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	7a0080e7          	jalr	1952(ra) # 80000c8a <release>
}
    800034f2:	854a                	mv	a0,s2
    800034f4:	70a2                	ld	ra,40(sp)
    800034f6:	7402                	ld	s0,32(sp)
    800034f8:	64e2                	ld	s1,24(sp)
    800034fa:	6942                	ld	s2,16(sp)
    800034fc:	69a2                	ld	s3,8(sp)
    800034fe:	6a02                	ld	s4,0(sp)
    80003500:	6145                	addi	sp,sp,48
    80003502:	8082                	ret
    panic("iget: no inodes");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	16450513          	addi	a0,a0,356 # 80008668 <syscalls+0x138>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	034080e7          	jalr	52(ra) # 80000540 <panic>

0000000080003514 <fsinit>:
fsinit(int dev) {
    80003514:	7179                	addi	sp,sp,-48
    80003516:	f406                	sd	ra,40(sp)
    80003518:	f022                	sd	s0,32(sp)
    8000351a:	ec26                	sd	s1,24(sp)
    8000351c:	e84a                	sd	s2,16(sp)
    8000351e:	e44e                	sd	s3,8(sp)
    80003520:	1800                	addi	s0,sp,48
    80003522:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003524:	4585                	li	a1,1
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	a54080e7          	jalr	-1452(ra) # 80002f7a <bread>
    8000352e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003530:	0001c997          	auipc	s3,0x1c
    80003534:	17898993          	addi	s3,s3,376 # 8001f6a8 <sb>
    80003538:	02000613          	li	a2,32
    8000353c:	05850593          	addi	a1,a0,88
    80003540:	854e                	mv	a0,s3
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	7ec080e7          	jalr	2028(ra) # 80000d2e <memmove>
  brelse(bp);
    8000354a:	8526                	mv	a0,s1
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	b5e080e7          	jalr	-1186(ra) # 800030aa <brelse>
  if(sb.magic != FSMAGIC)
    80003554:	0009a703          	lw	a4,0(s3)
    80003558:	102037b7          	lui	a5,0x10203
    8000355c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003560:	02f71263          	bne	a4,a5,80003584 <fsinit+0x70>
  initlog(dev, &sb);
    80003564:	0001c597          	auipc	a1,0x1c
    80003568:	14458593          	addi	a1,a1,324 # 8001f6a8 <sb>
    8000356c:	854a                	mv	a0,s2
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	b4a080e7          	jalr	-1206(ra) # 800040b8 <initlog>
}
    80003576:	70a2                	ld	ra,40(sp)
    80003578:	7402                	ld	s0,32(sp)
    8000357a:	64e2                	ld	s1,24(sp)
    8000357c:	6942                	ld	s2,16(sp)
    8000357e:	69a2                	ld	s3,8(sp)
    80003580:	6145                	addi	sp,sp,48
    80003582:	8082                	ret
    panic("invalid file system");
    80003584:	00005517          	auipc	a0,0x5
    80003588:	0f450513          	addi	a0,a0,244 # 80008678 <syscalls+0x148>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	fb4080e7          	jalr	-76(ra) # 80000540 <panic>

0000000080003594 <iinit>:
{
    80003594:	7179                	addi	sp,sp,-48
    80003596:	f406                	sd	ra,40(sp)
    80003598:	f022                	sd	s0,32(sp)
    8000359a:	ec26                	sd	s1,24(sp)
    8000359c:	e84a                	sd	s2,16(sp)
    8000359e:	e44e                	sd	s3,8(sp)
    800035a0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035a2:	00005597          	auipc	a1,0x5
    800035a6:	0ee58593          	addi	a1,a1,238 # 80008690 <syscalls+0x160>
    800035aa:	0001c517          	auipc	a0,0x1c
    800035ae:	11e50513          	addi	a0,a0,286 # 8001f6c8 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	594080e7          	jalr	1428(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ba:	0001c497          	auipc	s1,0x1c
    800035be:	13648493          	addi	s1,s1,310 # 8001f6f0 <itable+0x28>
    800035c2:	0001e997          	auipc	s3,0x1e
    800035c6:	bbe98993          	addi	s3,s3,-1090 # 80021180 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ca:	00005917          	auipc	s2,0x5
    800035ce:	0ce90913          	addi	s2,s2,206 # 80008698 <syscalls+0x168>
    800035d2:	85ca                	mv	a1,s2
    800035d4:	8526                	mv	a0,s1
    800035d6:	00001097          	auipc	ra,0x1
    800035da:	e42080e7          	jalr	-446(ra) # 80004418 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035de:	08848493          	addi	s1,s1,136
    800035e2:	ff3498e3          	bne	s1,s3,800035d2 <iinit+0x3e>
}
    800035e6:	70a2                	ld	ra,40(sp)
    800035e8:	7402                	ld	s0,32(sp)
    800035ea:	64e2                	ld	s1,24(sp)
    800035ec:	6942                	ld	s2,16(sp)
    800035ee:	69a2                	ld	s3,8(sp)
    800035f0:	6145                	addi	sp,sp,48
    800035f2:	8082                	ret

00000000800035f4 <ialloc>:
{
    800035f4:	715d                	addi	sp,sp,-80
    800035f6:	e486                	sd	ra,72(sp)
    800035f8:	e0a2                	sd	s0,64(sp)
    800035fa:	fc26                	sd	s1,56(sp)
    800035fc:	f84a                	sd	s2,48(sp)
    800035fe:	f44e                	sd	s3,40(sp)
    80003600:	f052                	sd	s4,32(sp)
    80003602:	ec56                	sd	s5,24(sp)
    80003604:	e85a                	sd	s6,16(sp)
    80003606:	e45e                	sd	s7,8(sp)
    80003608:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360a:	0001c717          	auipc	a4,0x1c
    8000360e:	0aa72703          	lw	a4,170(a4) # 8001f6b4 <sb+0xc>
    80003612:	4785                	li	a5,1
    80003614:	04e7fa63          	bgeu	a5,a4,80003668 <ialloc+0x74>
    80003618:	8aaa                	mv	s5,a0
    8000361a:	8bae                	mv	s7,a1
    8000361c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000361e:	0001ca17          	auipc	s4,0x1c
    80003622:	08aa0a13          	addi	s4,s4,138 # 8001f6a8 <sb>
    80003626:	00048b1b          	sext.w	s6,s1
    8000362a:	0044d593          	srli	a1,s1,0x4
    8000362e:	018a2783          	lw	a5,24(s4)
    80003632:	9dbd                	addw	a1,a1,a5
    80003634:	8556                	mv	a0,s5
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	944080e7          	jalr	-1724(ra) # 80002f7a <bread>
    8000363e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003640:	05850993          	addi	s3,a0,88
    80003644:	00f4f793          	andi	a5,s1,15
    80003648:	079a                	slli	a5,a5,0x6
    8000364a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000364c:	00099783          	lh	a5,0(s3)
    80003650:	c3a1                	beqz	a5,80003690 <ialloc+0x9c>
    brelse(bp);
    80003652:	00000097          	auipc	ra,0x0
    80003656:	a58080e7          	jalr	-1448(ra) # 800030aa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365a:	0485                	addi	s1,s1,1
    8000365c:	00ca2703          	lw	a4,12(s4)
    80003660:	0004879b          	sext.w	a5,s1
    80003664:	fce7e1e3          	bltu	a5,a4,80003626 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003668:	00005517          	auipc	a0,0x5
    8000366c:	03850513          	addi	a0,a0,56 # 800086a0 <syscalls+0x170>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	f1a080e7          	jalr	-230(ra) # 8000058a <printf>
  return 0;
    80003678:	4501                	li	a0,0
}
    8000367a:	60a6                	ld	ra,72(sp)
    8000367c:	6406                	ld	s0,64(sp)
    8000367e:	74e2                	ld	s1,56(sp)
    80003680:	7942                	ld	s2,48(sp)
    80003682:	79a2                	ld	s3,40(sp)
    80003684:	7a02                	ld	s4,32(sp)
    80003686:	6ae2                	ld	s5,24(sp)
    80003688:	6b42                	ld	s6,16(sp)
    8000368a:	6ba2                	ld	s7,8(sp)
    8000368c:	6161                	addi	sp,sp,80
    8000368e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003690:	04000613          	li	a2,64
    80003694:	4581                	li	a1,0
    80003696:	854e                	mv	a0,s3
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	63a080e7          	jalr	1594(ra) # 80000cd2 <memset>
      dip->type = type;
    800036a0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036a4:	854a                	mv	a0,s2
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	c8e080e7          	jalr	-882(ra) # 80004334 <log_write>
      brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	9fa080e7          	jalr	-1542(ra) # 800030aa <brelse>
      return iget(dev, inum);
    800036b8:	85da                	mv	a1,s6
    800036ba:	8556                	mv	a0,s5
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	d9c080e7          	jalr	-612(ra) # 80003458 <iget>
    800036c4:	bf5d                	j	8000367a <ialloc+0x86>

00000000800036c6 <iupdate>:
{
    800036c6:	1101                	addi	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	e426                	sd	s1,8(sp)
    800036ce:	e04a                	sd	s2,0(sp)
    800036d0:	1000                	addi	s0,sp,32
    800036d2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d4:	415c                	lw	a5,4(a0)
    800036d6:	0047d79b          	srliw	a5,a5,0x4
    800036da:	0001c597          	auipc	a1,0x1c
    800036de:	fe65a583          	lw	a1,-26(a1) # 8001f6c0 <sb+0x18>
    800036e2:	9dbd                	addw	a1,a1,a5
    800036e4:	4108                	lw	a0,0(a0)
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	894080e7          	jalr	-1900(ra) # 80002f7a <bread>
    800036ee:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f0:	05850793          	addi	a5,a0,88
    800036f4:	40d8                	lw	a4,4(s1)
    800036f6:	8b3d                	andi	a4,a4,15
    800036f8:	071a                	slli	a4,a4,0x6
    800036fa:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036fc:	04449703          	lh	a4,68(s1)
    80003700:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003704:	04649703          	lh	a4,70(s1)
    80003708:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000370c:	04849703          	lh	a4,72(s1)
    80003710:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003714:	04a49703          	lh	a4,74(s1)
    80003718:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000371c:	44f8                	lw	a4,76(s1)
    8000371e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003720:	03400613          	li	a2,52
    80003724:	05048593          	addi	a1,s1,80
    80003728:	00c78513          	addi	a0,a5,12
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	602080e7          	jalr	1538(ra) # 80000d2e <memmove>
  log_write(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	bfe080e7          	jalr	-1026(ra) # 80004334 <log_write>
  brelse(bp);
    8000373e:	854a                	mv	a0,s2
    80003740:	00000097          	auipc	ra,0x0
    80003744:	96a080e7          	jalr	-1686(ra) # 800030aa <brelse>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6902                	ld	s2,0(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret

0000000080003754 <idup>:
{
    80003754:	1101                	addi	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	e426                	sd	s1,8(sp)
    8000375c:	1000                	addi	s0,sp,32
    8000375e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003760:	0001c517          	auipc	a0,0x1c
    80003764:	f6850513          	addi	a0,a0,-152 # 8001f6c8 <itable>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	46e080e7          	jalr	1134(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003770:	449c                	lw	a5,8(s1)
    80003772:	2785                	addiw	a5,a5,1
    80003774:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003776:	0001c517          	auipc	a0,0x1c
    8000377a:	f5250513          	addi	a0,a0,-174 # 8001f6c8 <itable>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	50c080e7          	jalr	1292(ra) # 80000c8a <release>
}
    80003786:	8526                	mv	a0,s1
    80003788:	60e2                	ld	ra,24(sp)
    8000378a:	6442                	ld	s0,16(sp)
    8000378c:	64a2                	ld	s1,8(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <ilock>:
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	e04a                	sd	s2,0(sp)
    8000379c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000379e:	c115                	beqz	a0,800037c2 <ilock+0x30>
    800037a0:	84aa                	mv	s1,a0
    800037a2:	451c                	lw	a5,8(a0)
    800037a4:	00f05f63          	blez	a5,800037c2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037a8:	0541                	addi	a0,a0,16
    800037aa:	00001097          	auipc	ra,0x1
    800037ae:	ca8080e7          	jalr	-856(ra) # 80004452 <acquiresleep>
  if(ip->valid == 0){
    800037b2:	40bc                	lw	a5,64(s1)
    800037b4:	cf99                	beqz	a5,800037d2 <ilock+0x40>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
    panic("ilock");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	ef650513          	addi	a0,a0,-266 # 800086b8 <syscalls+0x188>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d76080e7          	jalr	-650(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d2:	40dc                	lw	a5,4(s1)
    800037d4:	0047d79b          	srliw	a5,a5,0x4
    800037d8:	0001c597          	auipc	a1,0x1c
    800037dc:	ee85a583          	lw	a1,-280(a1) # 8001f6c0 <sb+0x18>
    800037e0:	9dbd                	addw	a1,a1,a5
    800037e2:	4088                	lw	a0,0(s1)
    800037e4:	fffff097          	auipc	ra,0xfffff
    800037e8:	796080e7          	jalr	1942(ra) # 80002f7a <bread>
    800037ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ee:	05850593          	addi	a1,a0,88
    800037f2:	40dc                	lw	a5,4(s1)
    800037f4:	8bbd                	andi	a5,a5,15
    800037f6:	079a                	slli	a5,a5,0x6
    800037f8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037fa:	00059783          	lh	a5,0(a1)
    800037fe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003802:	00259783          	lh	a5,2(a1)
    80003806:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000380a:	00459783          	lh	a5,4(a1)
    8000380e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003812:	00659783          	lh	a5,6(a1)
    80003816:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000381a:	459c                	lw	a5,8(a1)
    8000381c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000381e:	03400613          	li	a2,52
    80003822:	05b1                	addi	a1,a1,12
    80003824:	05048513          	addi	a0,s1,80
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	506080e7          	jalr	1286(ra) # 80000d2e <memmove>
    brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	878080e7          	jalr	-1928(ra) # 800030aa <brelse>
    ip->valid = 1;
    8000383a:	4785                	li	a5,1
    8000383c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000383e:	04449783          	lh	a5,68(s1)
    80003842:	fbb5                	bnez	a5,800037b6 <ilock+0x24>
      panic("ilock: no type");
    80003844:	00005517          	auipc	a0,0x5
    80003848:	e7c50513          	addi	a0,a0,-388 # 800086c0 <syscalls+0x190>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	cf4080e7          	jalr	-780(ra) # 80000540 <panic>

0000000080003854 <iunlock>:
{
    80003854:	1101                	addi	sp,sp,-32
    80003856:	ec06                	sd	ra,24(sp)
    80003858:	e822                	sd	s0,16(sp)
    8000385a:	e426                	sd	s1,8(sp)
    8000385c:	e04a                	sd	s2,0(sp)
    8000385e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003860:	c905                	beqz	a0,80003890 <iunlock+0x3c>
    80003862:	84aa                	mv	s1,a0
    80003864:	01050913          	addi	s2,a0,16
    80003868:	854a                	mv	a0,s2
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	c82080e7          	jalr	-894(ra) # 800044ec <holdingsleep>
    80003872:	cd19                	beqz	a0,80003890 <iunlock+0x3c>
    80003874:	449c                	lw	a5,8(s1)
    80003876:	00f05d63          	blez	a5,80003890 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	c2c080e7          	jalr	-980(ra) # 800044a8 <releasesleep>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6902                	ld	s2,0(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret
    panic("iunlock");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	e4050513          	addi	a0,a0,-448 # 800086d0 <syscalls+0x1a0>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	ca8080e7          	jalr	-856(ra) # 80000540 <panic>

00000000800038a0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a0:	7179                	addi	sp,sp,-48
    800038a2:	f406                	sd	ra,40(sp)
    800038a4:	f022                	sd	s0,32(sp)
    800038a6:	ec26                	sd	s1,24(sp)
    800038a8:	e84a                	sd	s2,16(sp)
    800038aa:	e44e                	sd	s3,8(sp)
    800038ac:	e052                	sd	s4,0(sp)
    800038ae:	1800                	addi	s0,sp,48
    800038b0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b2:	05050493          	addi	s1,a0,80
    800038b6:	08050913          	addi	s2,a0,128
    800038ba:	a021                	j	800038c2 <itrunc+0x22>
    800038bc:	0491                	addi	s1,s1,4
    800038be:	01248d63          	beq	s1,s2,800038d8 <itrunc+0x38>
    if(ip->addrs[i]){
    800038c2:	408c                	lw	a1,0(s1)
    800038c4:	dde5                	beqz	a1,800038bc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038c6:	0009a503          	lw	a0,0(s3)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	8f6080e7          	jalr	-1802(ra) # 800031c0 <bfree>
      ip->addrs[i] = 0;
    800038d2:	0004a023          	sw	zero,0(s1)
    800038d6:	b7dd                	j	800038bc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038d8:	0809a583          	lw	a1,128(s3)
    800038dc:	e185                	bnez	a1,800038fc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038de:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e2:	854e                	mv	a0,s3
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	de2080e7          	jalr	-542(ra) # 800036c6 <iupdate>
}
    800038ec:	70a2                	ld	ra,40(sp)
    800038ee:	7402                	ld	s0,32(sp)
    800038f0:	64e2                	ld	s1,24(sp)
    800038f2:	6942                	ld	s2,16(sp)
    800038f4:	69a2                	ld	s3,8(sp)
    800038f6:	6a02                	ld	s4,0(sp)
    800038f8:	6145                	addi	sp,sp,48
    800038fa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038fc:	0009a503          	lw	a0,0(s3)
    80003900:	fffff097          	auipc	ra,0xfffff
    80003904:	67a080e7          	jalr	1658(ra) # 80002f7a <bread>
    80003908:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000390a:	05850493          	addi	s1,a0,88
    8000390e:	45850913          	addi	s2,a0,1112
    80003912:	a021                	j	8000391a <itrunc+0x7a>
    80003914:	0491                	addi	s1,s1,4
    80003916:	01248b63          	beq	s1,s2,8000392c <itrunc+0x8c>
      if(a[j])
    8000391a:	408c                	lw	a1,0(s1)
    8000391c:	dde5                	beqz	a1,80003914 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000391e:	0009a503          	lw	a0,0(s3)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	89e080e7          	jalr	-1890(ra) # 800031c0 <bfree>
    8000392a:	b7ed                	j	80003914 <itrunc+0x74>
    brelse(bp);
    8000392c:	8552                	mv	a0,s4
    8000392e:	fffff097          	auipc	ra,0xfffff
    80003932:	77c080e7          	jalr	1916(ra) # 800030aa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003936:	0809a583          	lw	a1,128(s3)
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	882080e7          	jalr	-1918(ra) # 800031c0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003946:	0809a023          	sw	zero,128(s3)
    8000394a:	bf51                	j	800038de <itrunc+0x3e>

000000008000394c <iput>:
{
    8000394c:	1101                	addi	sp,sp,-32
    8000394e:	ec06                	sd	ra,24(sp)
    80003950:	e822                	sd	s0,16(sp)
    80003952:	e426                	sd	s1,8(sp)
    80003954:	e04a                	sd	s2,0(sp)
    80003956:	1000                	addi	s0,sp,32
    80003958:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395a:	0001c517          	auipc	a0,0x1c
    8000395e:	d6e50513          	addi	a0,a0,-658 # 8001f6c8 <itable>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	274080e7          	jalr	628(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396a:	4498                	lw	a4,8(s1)
    8000396c:	4785                	li	a5,1
    8000396e:	02f70363          	beq	a4,a5,80003994 <iput+0x48>
  ip->ref--;
    80003972:	449c                	lw	a5,8(s1)
    80003974:	37fd                	addiw	a5,a5,-1
    80003976:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003978:	0001c517          	auipc	a0,0x1c
    8000397c:	d5050513          	addi	a0,a0,-688 # 8001f6c8 <itable>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	30a080e7          	jalr	778(ra) # 80000c8a <release>
}
    80003988:	60e2                	ld	ra,24(sp)
    8000398a:	6442                	ld	s0,16(sp)
    8000398c:	64a2                	ld	s1,8(sp)
    8000398e:	6902                	ld	s2,0(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003994:	40bc                	lw	a5,64(s1)
    80003996:	dff1                	beqz	a5,80003972 <iput+0x26>
    80003998:	04a49783          	lh	a5,74(s1)
    8000399c:	fbf9                	bnez	a5,80003972 <iput+0x26>
    acquiresleep(&ip->lock);
    8000399e:	01048913          	addi	s2,s1,16
    800039a2:	854a                	mv	a0,s2
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	aae080e7          	jalr	-1362(ra) # 80004452 <acquiresleep>
    release(&itable.lock);
    800039ac:	0001c517          	auipc	a0,0x1c
    800039b0:	d1c50513          	addi	a0,a0,-740 # 8001f6c8 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2d6080e7          	jalr	726(ra) # 80000c8a <release>
    itrunc(ip);
    800039bc:	8526                	mv	a0,s1
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	ee2080e7          	jalr	-286(ra) # 800038a0 <itrunc>
    ip->type = 0;
    800039c6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ca:	8526                	mv	a0,s1
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	cfa080e7          	jalr	-774(ra) # 800036c6 <iupdate>
    ip->valid = 0;
    800039d4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	ace080e7          	jalr	-1330(ra) # 800044a8 <releasesleep>
    acquire(&itable.lock);
    800039e2:	0001c517          	auipc	a0,0x1c
    800039e6:	ce650513          	addi	a0,a0,-794 # 8001f6c8 <itable>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	1ec080e7          	jalr	492(ra) # 80000bd6 <acquire>
    800039f2:	b741                	j	80003972 <iput+0x26>

00000000800039f4 <iunlockput>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	1000                	addi	s0,sp,32
    800039fe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	e54080e7          	jalr	-428(ra) # 80003854 <iunlock>
  iput(ip);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	f42080e7          	jalr	-190(ra) # 8000394c <iput>
}
    80003a12:	60e2                	ld	ra,24(sp)
    80003a14:	6442                	ld	s0,16(sp)
    80003a16:	64a2                	ld	s1,8(sp)
    80003a18:	6105                	addi	sp,sp,32
    80003a1a:	8082                	ret

0000000080003a1c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a1c:	1141                	addi	sp,sp,-16
    80003a1e:	e422                	sd	s0,8(sp)
    80003a20:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a22:	411c                	lw	a5,0(a0)
    80003a24:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a26:	415c                	lw	a5,4(a0)
    80003a28:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a2a:	04451783          	lh	a5,68(a0)
    80003a2e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a32:	04a51783          	lh	a5,74(a0)
    80003a36:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a3a:	04c56783          	lwu	a5,76(a0)
    80003a3e:	e99c                	sd	a5,16(a1)
}
    80003a40:	6422                	ld	s0,8(sp)
    80003a42:	0141                	addi	sp,sp,16
    80003a44:	8082                	ret

0000000080003a46 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a46:	457c                	lw	a5,76(a0)
    80003a48:	0ed7e963          	bltu	a5,a3,80003b3a <readi+0xf4>
{
    80003a4c:	7159                	addi	sp,sp,-112
    80003a4e:	f486                	sd	ra,104(sp)
    80003a50:	f0a2                	sd	s0,96(sp)
    80003a52:	eca6                	sd	s1,88(sp)
    80003a54:	e8ca                	sd	s2,80(sp)
    80003a56:	e4ce                	sd	s3,72(sp)
    80003a58:	e0d2                	sd	s4,64(sp)
    80003a5a:	fc56                	sd	s5,56(sp)
    80003a5c:	f85a                	sd	s6,48(sp)
    80003a5e:	f45e                	sd	s7,40(sp)
    80003a60:	f062                	sd	s8,32(sp)
    80003a62:	ec66                	sd	s9,24(sp)
    80003a64:	e86a                	sd	s10,16(sp)
    80003a66:	e46e                	sd	s11,8(sp)
    80003a68:	1880                	addi	s0,sp,112
    80003a6a:	8b2a                	mv	s6,a0
    80003a6c:	8bae                	mv	s7,a1
    80003a6e:	8a32                	mv	s4,a2
    80003a70:	84b6                	mv	s1,a3
    80003a72:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a74:	9f35                	addw	a4,a4,a3
    return 0;
    80003a76:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a78:	0ad76063          	bltu	a4,a3,80003b18 <readi+0xd2>
  if(off + n > ip->size)
    80003a7c:	00e7f463          	bgeu	a5,a4,80003a84 <readi+0x3e>
    n = ip->size - off;
    80003a80:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a84:	0a0a8963          	beqz	s5,80003b36 <readi+0xf0>
    80003a88:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a8e:	5c7d                	li	s8,-1
    80003a90:	a82d                	j	80003aca <readi+0x84>
    80003a92:	020d1d93          	slli	s11,s10,0x20
    80003a96:	020ddd93          	srli	s11,s11,0x20
    80003a9a:	05890613          	addi	a2,s2,88
    80003a9e:	86ee                	mv	a3,s11
    80003aa0:	963a                	add	a2,a2,a4
    80003aa2:	85d2                	mv	a1,s4
    80003aa4:	855e                	mv	a0,s7
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	9c2080e7          	jalr	-1598(ra) # 80002468 <either_copyout>
    80003aae:	05850d63          	beq	a0,s8,80003b08 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ab2:	854a                	mv	a0,s2
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	5f6080e7          	jalr	1526(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003abc:	013d09bb          	addw	s3,s10,s3
    80003ac0:	009d04bb          	addw	s1,s10,s1
    80003ac4:	9a6e                	add	s4,s4,s11
    80003ac6:	0559f763          	bgeu	s3,s5,80003b14 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003aca:	00a4d59b          	srliw	a1,s1,0xa
    80003ace:	855a                	mv	a0,s6
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	89e080e7          	jalr	-1890(ra) # 8000336e <bmap>
    80003ad8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003adc:	cd85                	beqz	a1,80003b14 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ade:	000b2503          	lw	a0,0(s6)
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	498080e7          	jalr	1176(ra) # 80002f7a <bread>
    80003aea:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aec:	3ff4f713          	andi	a4,s1,1023
    80003af0:	40ec87bb          	subw	a5,s9,a4
    80003af4:	413a86bb          	subw	a3,s5,s3
    80003af8:	8d3e                	mv	s10,a5
    80003afa:	2781                	sext.w	a5,a5
    80003afc:	0006861b          	sext.w	a2,a3
    80003b00:	f8f679e3          	bgeu	a2,a5,80003a92 <readi+0x4c>
    80003b04:	8d36                	mv	s10,a3
    80003b06:	b771                	j	80003a92 <readi+0x4c>
      brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	5a0080e7          	jalr	1440(ra) # 800030aa <brelse>
      tot = -1;
    80003b12:	59fd                	li	s3,-1
  }
  return tot;
    80003b14:	0009851b          	sext.w	a0,s3
}
    80003b18:	70a6                	ld	ra,104(sp)
    80003b1a:	7406                	ld	s0,96(sp)
    80003b1c:	64e6                	ld	s1,88(sp)
    80003b1e:	6946                	ld	s2,80(sp)
    80003b20:	69a6                	ld	s3,72(sp)
    80003b22:	6a06                	ld	s4,64(sp)
    80003b24:	7ae2                	ld	s5,56(sp)
    80003b26:	7b42                	ld	s6,48(sp)
    80003b28:	7ba2                	ld	s7,40(sp)
    80003b2a:	7c02                	ld	s8,32(sp)
    80003b2c:	6ce2                	ld	s9,24(sp)
    80003b2e:	6d42                	ld	s10,16(sp)
    80003b30:	6da2                	ld	s11,8(sp)
    80003b32:	6165                	addi	sp,sp,112
    80003b34:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b36:	89d6                	mv	s3,s5
    80003b38:	bff1                	j	80003b14 <readi+0xce>
    return 0;
    80003b3a:	4501                	li	a0,0
}
    80003b3c:	8082                	ret

0000000080003b3e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b3e:	457c                	lw	a5,76(a0)
    80003b40:	10d7e863          	bltu	a5,a3,80003c50 <writei+0x112>
{
    80003b44:	7159                	addi	sp,sp,-112
    80003b46:	f486                	sd	ra,104(sp)
    80003b48:	f0a2                	sd	s0,96(sp)
    80003b4a:	eca6                	sd	s1,88(sp)
    80003b4c:	e8ca                	sd	s2,80(sp)
    80003b4e:	e4ce                	sd	s3,72(sp)
    80003b50:	e0d2                	sd	s4,64(sp)
    80003b52:	fc56                	sd	s5,56(sp)
    80003b54:	f85a                	sd	s6,48(sp)
    80003b56:	f45e                	sd	s7,40(sp)
    80003b58:	f062                	sd	s8,32(sp)
    80003b5a:	ec66                	sd	s9,24(sp)
    80003b5c:	e86a                	sd	s10,16(sp)
    80003b5e:	e46e                	sd	s11,8(sp)
    80003b60:	1880                	addi	s0,sp,112
    80003b62:	8aaa                	mv	s5,a0
    80003b64:	8bae                	mv	s7,a1
    80003b66:	8a32                	mv	s4,a2
    80003b68:	8936                	mv	s2,a3
    80003b6a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b6c:	00e687bb          	addw	a5,a3,a4
    80003b70:	0ed7e263          	bltu	a5,a3,80003c54 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b74:	00043737          	lui	a4,0x43
    80003b78:	0ef76063          	bltu	a4,a5,80003c58 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b7c:	0c0b0863          	beqz	s6,80003c4c <writei+0x10e>
    80003b80:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b82:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b86:	5c7d                	li	s8,-1
    80003b88:	a091                	j	80003bcc <writei+0x8e>
    80003b8a:	020d1d93          	slli	s11,s10,0x20
    80003b8e:	020ddd93          	srli	s11,s11,0x20
    80003b92:	05848513          	addi	a0,s1,88
    80003b96:	86ee                	mv	a3,s11
    80003b98:	8652                	mv	a2,s4
    80003b9a:	85de                	mv	a1,s7
    80003b9c:	953a                	add	a0,a0,a4
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	920080e7          	jalr	-1760(ra) # 800024be <either_copyin>
    80003ba6:	07850263          	beq	a0,s8,80003c0a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003baa:	8526                	mv	a0,s1
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	788080e7          	jalr	1928(ra) # 80004334 <log_write>
    brelse(bp);
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	4f4080e7          	jalr	1268(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bbe:	013d09bb          	addw	s3,s10,s3
    80003bc2:	012d093b          	addw	s2,s10,s2
    80003bc6:	9a6e                	add	s4,s4,s11
    80003bc8:	0569f663          	bgeu	s3,s6,80003c14 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bcc:	00a9559b          	srliw	a1,s2,0xa
    80003bd0:	8556                	mv	a0,s5
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	79c080e7          	jalr	1948(ra) # 8000336e <bmap>
    80003bda:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bde:	c99d                	beqz	a1,80003c14 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003be0:	000aa503          	lw	a0,0(s5)
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	396080e7          	jalr	918(ra) # 80002f7a <bread>
    80003bec:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bee:	3ff97713          	andi	a4,s2,1023
    80003bf2:	40ec87bb          	subw	a5,s9,a4
    80003bf6:	413b06bb          	subw	a3,s6,s3
    80003bfa:	8d3e                	mv	s10,a5
    80003bfc:	2781                	sext.w	a5,a5
    80003bfe:	0006861b          	sext.w	a2,a3
    80003c02:	f8f674e3          	bgeu	a2,a5,80003b8a <writei+0x4c>
    80003c06:	8d36                	mv	s10,a3
    80003c08:	b749                	j	80003b8a <writei+0x4c>
      brelse(bp);
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	49e080e7          	jalr	1182(ra) # 800030aa <brelse>
  }

  if(off > ip->size)
    80003c14:	04caa783          	lw	a5,76(s5)
    80003c18:	0127f463          	bgeu	a5,s2,80003c20 <writei+0xe2>
    ip->size = off;
    80003c1c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c20:	8556                	mv	a0,s5
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	aa4080e7          	jalr	-1372(ra) # 800036c6 <iupdate>

  return tot;
    80003c2a:	0009851b          	sext.w	a0,s3
}
    80003c2e:	70a6                	ld	ra,104(sp)
    80003c30:	7406                	ld	s0,96(sp)
    80003c32:	64e6                	ld	s1,88(sp)
    80003c34:	6946                	ld	s2,80(sp)
    80003c36:	69a6                	ld	s3,72(sp)
    80003c38:	6a06                	ld	s4,64(sp)
    80003c3a:	7ae2                	ld	s5,56(sp)
    80003c3c:	7b42                	ld	s6,48(sp)
    80003c3e:	7ba2                	ld	s7,40(sp)
    80003c40:	7c02                	ld	s8,32(sp)
    80003c42:	6ce2                	ld	s9,24(sp)
    80003c44:	6d42                	ld	s10,16(sp)
    80003c46:	6da2                	ld	s11,8(sp)
    80003c48:	6165                	addi	sp,sp,112
    80003c4a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c4c:	89da                	mv	s3,s6
    80003c4e:	bfc9                	j	80003c20 <writei+0xe2>
    return -1;
    80003c50:	557d                	li	a0,-1
}
    80003c52:	8082                	ret
    return -1;
    80003c54:	557d                	li	a0,-1
    80003c56:	bfe1                	j	80003c2e <writei+0xf0>
    return -1;
    80003c58:	557d                	li	a0,-1
    80003c5a:	bfd1                	j	80003c2e <writei+0xf0>

0000000080003c5c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c5c:	1141                	addi	sp,sp,-16
    80003c5e:	e406                	sd	ra,8(sp)
    80003c60:	e022                	sd	s0,0(sp)
    80003c62:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c64:	4639                	li	a2,14
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	13c080e7          	jalr	316(ra) # 80000da2 <strncmp>
}
    80003c6e:	60a2                	ld	ra,8(sp)
    80003c70:	6402                	ld	s0,0(sp)
    80003c72:	0141                	addi	sp,sp,16
    80003c74:	8082                	ret

0000000080003c76 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c76:	7139                	addi	sp,sp,-64
    80003c78:	fc06                	sd	ra,56(sp)
    80003c7a:	f822                	sd	s0,48(sp)
    80003c7c:	f426                	sd	s1,40(sp)
    80003c7e:	f04a                	sd	s2,32(sp)
    80003c80:	ec4e                	sd	s3,24(sp)
    80003c82:	e852                	sd	s4,16(sp)
    80003c84:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c86:	04451703          	lh	a4,68(a0)
    80003c8a:	4785                	li	a5,1
    80003c8c:	00f71a63          	bne	a4,a5,80003ca0 <dirlookup+0x2a>
    80003c90:	892a                	mv	s2,a0
    80003c92:	89ae                	mv	s3,a1
    80003c94:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c96:	457c                	lw	a5,76(a0)
    80003c98:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c9a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9c:	e79d                	bnez	a5,80003cca <dirlookup+0x54>
    80003c9e:	a8a5                	j	80003d16 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca0:	00005517          	auipc	a0,0x5
    80003ca4:	a3850513          	addi	a0,a0,-1480 # 800086d8 <syscalls+0x1a8>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003cb0:	00005517          	auipc	a0,0x5
    80003cb4:	a4050513          	addi	a0,a0,-1472 # 800086f0 <syscalls+0x1c0>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	888080e7          	jalr	-1912(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	24c1                	addiw	s1,s1,16
    80003cc2:	04c92783          	lw	a5,76(s2)
    80003cc6:	04f4f763          	bgeu	s1,a5,80003d14 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cca:	4741                	li	a4,16
    80003ccc:	86a6                	mv	a3,s1
    80003cce:	fc040613          	addi	a2,s0,-64
    80003cd2:	4581                	li	a1,0
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	d70080e7          	jalr	-656(ra) # 80003a46 <readi>
    80003cde:	47c1                	li	a5,16
    80003ce0:	fcf518e3          	bne	a0,a5,80003cb0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ce4:	fc045783          	lhu	a5,-64(s0)
    80003ce8:	dfe1                	beqz	a5,80003cc0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cea:	fc240593          	addi	a1,s0,-62
    80003cee:	854e                	mv	a0,s3
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	f6c080e7          	jalr	-148(ra) # 80003c5c <namecmp>
    80003cf8:	f561                	bnez	a0,80003cc0 <dirlookup+0x4a>
      if(poff)
    80003cfa:	000a0463          	beqz	s4,80003d02 <dirlookup+0x8c>
        *poff = off;
    80003cfe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d02:	fc045583          	lhu	a1,-64(s0)
    80003d06:	00092503          	lw	a0,0(s2)
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	74e080e7          	jalr	1870(ra) # 80003458 <iget>
    80003d12:	a011                	j	80003d16 <dirlookup+0xa0>
  return 0;
    80003d14:	4501                	li	a0,0
}
    80003d16:	70e2                	ld	ra,56(sp)
    80003d18:	7442                	ld	s0,48(sp)
    80003d1a:	74a2                	ld	s1,40(sp)
    80003d1c:	7902                	ld	s2,32(sp)
    80003d1e:	69e2                	ld	s3,24(sp)
    80003d20:	6a42                	ld	s4,16(sp)
    80003d22:	6121                	addi	sp,sp,64
    80003d24:	8082                	ret

0000000080003d26 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d26:	711d                	addi	sp,sp,-96
    80003d28:	ec86                	sd	ra,88(sp)
    80003d2a:	e8a2                	sd	s0,80(sp)
    80003d2c:	e4a6                	sd	s1,72(sp)
    80003d2e:	e0ca                	sd	s2,64(sp)
    80003d30:	fc4e                	sd	s3,56(sp)
    80003d32:	f852                	sd	s4,48(sp)
    80003d34:	f456                	sd	s5,40(sp)
    80003d36:	f05a                	sd	s6,32(sp)
    80003d38:	ec5e                	sd	s7,24(sp)
    80003d3a:	e862                	sd	s8,16(sp)
    80003d3c:	e466                	sd	s9,8(sp)
    80003d3e:	e06a                	sd	s10,0(sp)
    80003d40:	1080                	addi	s0,sp,96
    80003d42:	84aa                	mv	s1,a0
    80003d44:	8b2e                	mv	s6,a1
    80003d46:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d48:	00054703          	lbu	a4,0(a0)
    80003d4c:	02f00793          	li	a5,47
    80003d50:	02f70363          	beq	a4,a5,80003d76 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d54:	ffffe097          	auipc	ra,0xffffe
    80003d58:	c58080e7          	jalr	-936(ra) # 800019ac <myproc>
    80003d5c:	15853503          	ld	a0,344(a0)
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	9f4080e7          	jalr	-1548(ra) # 80003754 <idup>
    80003d68:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d6a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d6e:	4cb5                	li	s9,13
  len = path - s;
    80003d70:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d72:	4c05                	li	s8,1
    80003d74:	a87d                	j	80003e32 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d76:	4585                	li	a1,1
    80003d78:	4505                	li	a0,1
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	6de080e7          	jalr	1758(ra) # 80003458 <iget>
    80003d82:	8a2a                	mv	s4,a0
    80003d84:	b7dd                	j	80003d6a <namex+0x44>
      iunlockput(ip);
    80003d86:	8552                	mv	a0,s4
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	c6c080e7          	jalr	-916(ra) # 800039f4 <iunlockput>
      return 0;
    80003d90:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d92:	8552                	mv	a0,s4
    80003d94:	60e6                	ld	ra,88(sp)
    80003d96:	6446                	ld	s0,80(sp)
    80003d98:	64a6                	ld	s1,72(sp)
    80003d9a:	6906                	ld	s2,64(sp)
    80003d9c:	79e2                	ld	s3,56(sp)
    80003d9e:	7a42                	ld	s4,48(sp)
    80003da0:	7aa2                	ld	s5,40(sp)
    80003da2:	7b02                	ld	s6,32(sp)
    80003da4:	6be2                	ld	s7,24(sp)
    80003da6:	6c42                	ld	s8,16(sp)
    80003da8:	6ca2                	ld	s9,8(sp)
    80003daa:	6d02                	ld	s10,0(sp)
    80003dac:	6125                	addi	sp,sp,96
    80003dae:	8082                	ret
      iunlock(ip);
    80003db0:	8552                	mv	a0,s4
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	aa2080e7          	jalr	-1374(ra) # 80003854 <iunlock>
      return ip;
    80003dba:	bfe1                	j	80003d92 <namex+0x6c>
      iunlockput(ip);
    80003dbc:	8552                	mv	a0,s4
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	c36080e7          	jalr	-970(ra) # 800039f4 <iunlockput>
      return 0;
    80003dc6:	8a4e                	mv	s4,s3
    80003dc8:	b7e9                	j	80003d92 <namex+0x6c>
  len = path - s;
    80003dca:	40998633          	sub	a2,s3,s1
    80003dce:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dd2:	09acd863          	bge	s9,s10,80003e62 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dd6:	4639                	li	a2,14
    80003dd8:	85a6                	mv	a1,s1
    80003dda:	8556                	mv	a0,s5
    80003ddc:	ffffd097          	auipc	ra,0xffffd
    80003de0:	f52080e7          	jalr	-174(ra) # 80000d2e <memmove>
    80003de4:	84ce                	mv	s1,s3
  while(*path == '/')
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	01279763          	bne	a5,s2,80003df8 <namex+0xd2>
    path++;
    80003dee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	ff278de3          	beq	a5,s2,80003dee <namex+0xc8>
    ilock(ip);
    80003df8:	8552                	mv	a0,s4
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	998080e7          	jalr	-1640(ra) # 80003792 <ilock>
    if(ip->type != T_DIR){
    80003e02:	044a1783          	lh	a5,68(s4)
    80003e06:	f98790e3          	bne	a5,s8,80003d86 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e0a:	000b0563          	beqz	s6,80003e14 <namex+0xee>
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	dfd9                	beqz	a5,80003db0 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e14:	865e                	mv	a2,s7
    80003e16:	85d6                	mv	a1,s5
    80003e18:	8552                	mv	a0,s4
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	e5c080e7          	jalr	-420(ra) # 80003c76 <dirlookup>
    80003e22:	89aa                	mv	s3,a0
    80003e24:	dd41                	beqz	a0,80003dbc <namex+0x96>
    iunlockput(ip);
    80003e26:	8552                	mv	a0,s4
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	bcc080e7          	jalr	-1076(ra) # 800039f4 <iunlockput>
    ip = next;
    80003e30:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	01279763          	bne	a5,s2,80003e44 <namex+0x11e>
    path++;
    80003e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	ff278de3          	beq	a5,s2,80003e3a <namex+0x114>
  if(*path == 0)
    80003e44:	cb9d                	beqz	a5,80003e7a <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e46:	0004c783          	lbu	a5,0(s1)
    80003e4a:	89a6                	mv	s3,s1
  len = path - s;
    80003e4c:	8d5e                	mv	s10,s7
    80003e4e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e50:	01278963          	beq	a5,s2,80003e62 <namex+0x13c>
    80003e54:	dbbd                	beqz	a5,80003dca <namex+0xa4>
    path++;
    80003e56:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e58:	0009c783          	lbu	a5,0(s3)
    80003e5c:	ff279ce3          	bne	a5,s2,80003e54 <namex+0x12e>
    80003e60:	b7ad                	j	80003dca <namex+0xa4>
    memmove(name, s, len);
    80003e62:	2601                	sext.w	a2,a2
    80003e64:	85a6                	mv	a1,s1
    80003e66:	8556                	mv	a0,s5
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	ec6080e7          	jalr	-314(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e70:	9d56                	add	s10,s10,s5
    80003e72:	000d0023          	sb	zero,0(s10)
    80003e76:	84ce                	mv	s1,s3
    80003e78:	b7bd                	j	80003de6 <namex+0xc0>
  if(nameiparent){
    80003e7a:	f00b0ce3          	beqz	s6,80003d92 <namex+0x6c>
    iput(ip);
    80003e7e:	8552                	mv	a0,s4
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	acc080e7          	jalr	-1332(ra) # 8000394c <iput>
    return 0;
    80003e88:	4a01                	li	s4,0
    80003e8a:	b721                	j	80003d92 <namex+0x6c>

0000000080003e8c <dirlink>:
{
    80003e8c:	7139                	addi	sp,sp,-64
    80003e8e:	fc06                	sd	ra,56(sp)
    80003e90:	f822                	sd	s0,48(sp)
    80003e92:	f426                	sd	s1,40(sp)
    80003e94:	f04a                	sd	s2,32(sp)
    80003e96:	ec4e                	sd	s3,24(sp)
    80003e98:	e852                	sd	s4,16(sp)
    80003e9a:	0080                	addi	s0,sp,64
    80003e9c:	892a                	mv	s2,a0
    80003e9e:	8a2e                	mv	s4,a1
    80003ea0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea2:	4601                	li	a2,0
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	dd2080e7          	jalr	-558(ra) # 80003c76 <dirlookup>
    80003eac:	e93d                	bnez	a0,80003f22 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eae:	04c92483          	lw	s1,76(s2)
    80003eb2:	c49d                	beqz	s1,80003ee0 <dirlink+0x54>
    80003eb4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb6:	4741                	li	a4,16
    80003eb8:	86a6                	mv	a3,s1
    80003eba:	fc040613          	addi	a2,s0,-64
    80003ebe:	4581                	li	a1,0
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	b84080e7          	jalr	-1148(ra) # 80003a46 <readi>
    80003eca:	47c1                	li	a5,16
    80003ecc:	06f51163          	bne	a0,a5,80003f2e <dirlink+0xa2>
    if(de.inum == 0)
    80003ed0:	fc045783          	lhu	a5,-64(s0)
    80003ed4:	c791                	beqz	a5,80003ee0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed6:	24c1                	addiw	s1,s1,16
    80003ed8:	04c92783          	lw	a5,76(s2)
    80003edc:	fcf4ede3          	bltu	s1,a5,80003eb6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee0:	4639                	li	a2,14
    80003ee2:	85d2                	mv	a1,s4
    80003ee4:	fc240513          	addi	a0,s0,-62
    80003ee8:	ffffd097          	auipc	ra,0xffffd
    80003eec:	ef6080e7          	jalr	-266(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003ef0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef4:	4741                	li	a4,16
    80003ef6:	86a6                	mv	a3,s1
    80003ef8:	fc040613          	addi	a2,s0,-64
    80003efc:	4581                	li	a1,0
    80003efe:	854a                	mv	a0,s2
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	c3e080e7          	jalr	-962(ra) # 80003b3e <writei>
    80003f08:	1541                	addi	a0,a0,-16
    80003f0a:	00a03533          	snez	a0,a0
    80003f0e:	40a00533          	neg	a0,a0
}
    80003f12:	70e2                	ld	ra,56(sp)
    80003f14:	7442                	ld	s0,48(sp)
    80003f16:	74a2                	ld	s1,40(sp)
    80003f18:	7902                	ld	s2,32(sp)
    80003f1a:	69e2                	ld	s3,24(sp)
    80003f1c:	6a42                	ld	s4,16(sp)
    80003f1e:	6121                	addi	sp,sp,64
    80003f20:	8082                	ret
    iput(ip);
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	a2a080e7          	jalr	-1494(ra) # 8000394c <iput>
    return -1;
    80003f2a:	557d                	li	a0,-1
    80003f2c:	b7dd                	j	80003f12 <dirlink+0x86>
      panic("dirlink read");
    80003f2e:	00004517          	auipc	a0,0x4
    80003f32:	7d250513          	addi	a0,a0,2002 # 80008700 <syscalls+0x1d0>
    80003f36:	ffffc097          	auipc	ra,0xffffc
    80003f3a:	60a080e7          	jalr	1546(ra) # 80000540 <panic>

0000000080003f3e <namei>:

struct inode*
namei(char *path)
{
    80003f3e:	1101                	addi	sp,sp,-32
    80003f40:	ec06                	sd	ra,24(sp)
    80003f42:	e822                	sd	s0,16(sp)
    80003f44:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f46:	fe040613          	addi	a2,s0,-32
    80003f4a:	4581                	li	a1,0
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	dda080e7          	jalr	-550(ra) # 80003d26 <namex>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	6105                	addi	sp,sp,32
    80003f5a:	8082                	ret

0000000080003f5c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f5c:	1141                	addi	sp,sp,-16
    80003f5e:	e406                	sd	ra,8(sp)
    80003f60:	e022                	sd	s0,0(sp)
    80003f62:	0800                	addi	s0,sp,16
    80003f64:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f66:	4585                	li	a1,1
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	dbe080e7          	jalr	-578(ra) # 80003d26 <namex>
}
    80003f70:	60a2                	ld	ra,8(sp)
    80003f72:	6402                	ld	s0,0(sp)
    80003f74:	0141                	addi	sp,sp,16
    80003f76:	8082                	ret

0000000080003f78 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f78:	1101                	addi	sp,sp,-32
    80003f7a:	ec06                	sd	ra,24(sp)
    80003f7c:	e822                	sd	s0,16(sp)
    80003f7e:	e426                	sd	s1,8(sp)
    80003f80:	e04a                	sd	s2,0(sp)
    80003f82:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f84:	0001d917          	auipc	s2,0x1d
    80003f88:	1ec90913          	addi	s2,s2,492 # 80021170 <log>
    80003f8c:	01892583          	lw	a1,24(s2)
    80003f90:	02892503          	lw	a0,40(s2)
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	fe6080e7          	jalr	-26(ra) # 80002f7a <bread>
    80003f9c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f9e:	02c92683          	lw	a3,44(s2)
    80003fa2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa4:	02d05863          	blez	a3,80003fd4 <write_head+0x5c>
    80003fa8:	0001d797          	auipc	a5,0x1d
    80003fac:	1f878793          	addi	a5,a5,504 # 800211a0 <log+0x30>
    80003fb0:	05c50713          	addi	a4,a0,92
    80003fb4:	36fd                	addiw	a3,a3,-1
    80003fb6:	02069613          	slli	a2,a3,0x20
    80003fba:	01e65693          	srli	a3,a2,0x1e
    80003fbe:	0001d617          	auipc	a2,0x1d
    80003fc2:	1e660613          	addi	a2,a2,486 # 800211a4 <log+0x34>
    80003fc6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc8:	4390                	lw	a2,0(a5)
    80003fca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fcc:	0791                	addi	a5,a5,4
    80003fce:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fd0:	fed79ce3          	bne	a5,a3,80003fc8 <write_head+0x50>
  }
  bwrite(buf);
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	096080e7          	jalr	150(ra) # 8000306c <bwrite>
  brelse(buf);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	0ca080e7          	jalr	202(ra) # 800030aa <brelse>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff4:	0001d797          	auipc	a5,0x1d
    80003ff8:	1a87a783          	lw	a5,424(a5) # 8002119c <log+0x2c>
    80003ffc:	0af05d63          	blez	a5,800040b6 <install_trans+0xc2>
{
    80004000:	7139                	addi	sp,sp,-64
    80004002:	fc06                	sd	ra,56(sp)
    80004004:	f822                	sd	s0,48(sp)
    80004006:	f426                	sd	s1,40(sp)
    80004008:	f04a                	sd	s2,32(sp)
    8000400a:	ec4e                	sd	s3,24(sp)
    8000400c:	e852                	sd	s4,16(sp)
    8000400e:	e456                	sd	s5,8(sp)
    80004010:	e05a                	sd	s6,0(sp)
    80004012:	0080                	addi	s0,sp,64
    80004014:	8b2a                	mv	s6,a0
    80004016:	0001da97          	auipc	s5,0x1d
    8000401a:	18aa8a93          	addi	s5,s5,394 # 800211a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004020:	0001d997          	auipc	s3,0x1d
    80004024:	15098993          	addi	s3,s3,336 # 80021170 <log>
    80004028:	a00d                	j	8000404a <install_trans+0x56>
    brelse(lbuf);
    8000402a:	854a                	mv	a0,s2
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	07e080e7          	jalr	126(ra) # 800030aa <brelse>
    brelse(dbuf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	074080e7          	jalr	116(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403e:	2a05                	addiw	s4,s4,1
    80004040:	0a91                	addi	s5,s5,4
    80004042:	02c9a783          	lw	a5,44(s3)
    80004046:	04fa5e63          	bge	s4,a5,800040a2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404a:	0189a583          	lw	a1,24(s3)
    8000404e:	014585bb          	addw	a1,a1,s4
    80004052:	2585                	addiw	a1,a1,1
    80004054:	0289a503          	lw	a0,40(s3)
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	f22080e7          	jalr	-222(ra) # 80002f7a <bread>
    80004060:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004062:	000aa583          	lw	a1,0(s5)
    80004066:	0289a503          	lw	a0,40(s3)
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	f10080e7          	jalr	-240(ra) # 80002f7a <bread>
    80004072:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004074:	40000613          	li	a2,1024
    80004078:	05890593          	addi	a1,s2,88
    8000407c:	05850513          	addi	a0,a0,88
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	cae080e7          	jalr	-850(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004088:	8526                	mv	a0,s1
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	fe2080e7          	jalr	-30(ra) # 8000306c <bwrite>
    if(recovering == 0)
    80004092:	f80b1ce3          	bnez	s6,8000402a <install_trans+0x36>
      bunpin(dbuf);
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	0ec080e7          	jalr	236(ra) # 80003184 <bunpin>
    800040a0:	b769                	j	8000402a <install_trans+0x36>
}
    800040a2:	70e2                	ld	ra,56(sp)
    800040a4:	7442                	ld	s0,48(sp)
    800040a6:	74a2                	ld	s1,40(sp)
    800040a8:	7902                	ld	s2,32(sp)
    800040aa:	69e2                	ld	s3,24(sp)
    800040ac:	6a42                	ld	s4,16(sp)
    800040ae:	6aa2                	ld	s5,8(sp)
    800040b0:	6b02                	ld	s6,0(sp)
    800040b2:	6121                	addi	sp,sp,64
    800040b4:	8082                	ret
    800040b6:	8082                	ret

00000000800040b8 <initlog>:
{
    800040b8:	7179                	addi	sp,sp,-48
    800040ba:	f406                	sd	ra,40(sp)
    800040bc:	f022                	sd	s0,32(sp)
    800040be:	ec26                	sd	s1,24(sp)
    800040c0:	e84a                	sd	s2,16(sp)
    800040c2:	e44e                	sd	s3,8(sp)
    800040c4:	1800                	addi	s0,sp,48
    800040c6:	892a                	mv	s2,a0
    800040c8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ca:	0001d497          	auipc	s1,0x1d
    800040ce:	0a648493          	addi	s1,s1,166 # 80021170 <log>
    800040d2:	00004597          	auipc	a1,0x4
    800040d6:	63e58593          	addi	a1,a1,1598 # 80008710 <syscalls+0x1e0>
    800040da:	8526                	mv	a0,s1
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	a6a080e7          	jalr	-1430(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040e4:	0149a583          	lw	a1,20(s3)
    800040e8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040ea:	0109a783          	lw	a5,16(s3)
    800040ee:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040f4:	854a                	mv	a0,s2
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	e84080e7          	jalr	-380(ra) # 80002f7a <bread>
  log.lh.n = lh->n;
    800040fe:	4d34                	lw	a3,88(a0)
    80004100:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004102:	02d05663          	blez	a3,8000412e <initlog+0x76>
    80004106:	05c50793          	addi	a5,a0,92
    8000410a:	0001d717          	auipc	a4,0x1d
    8000410e:	09670713          	addi	a4,a4,150 # 800211a0 <log+0x30>
    80004112:	36fd                	addiw	a3,a3,-1
    80004114:	02069613          	slli	a2,a3,0x20
    80004118:	01e65693          	srli	a3,a2,0x1e
    8000411c:	06050613          	addi	a2,a0,96
    80004120:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004122:	4390                	lw	a2,0(a5)
    80004124:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004126:	0791                	addi	a5,a5,4
    80004128:	0711                	addi	a4,a4,4
    8000412a:	fed79ce3          	bne	a5,a3,80004122 <initlog+0x6a>
  brelse(buf);
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	f7c080e7          	jalr	-132(ra) # 800030aa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004136:	4505                	li	a0,1
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	ebc080e7          	jalr	-324(ra) # 80003ff4 <install_trans>
  log.lh.n = 0;
    80004140:	0001d797          	auipc	a5,0x1d
    80004144:	0407ae23          	sw	zero,92(a5) # 8002119c <log+0x2c>
  write_head(); // clear the log
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	e30080e7          	jalr	-464(ra) # 80003f78 <write_head>
}
    80004150:	70a2                	ld	ra,40(sp)
    80004152:	7402                	ld	s0,32(sp)
    80004154:	64e2                	ld	s1,24(sp)
    80004156:	6942                	ld	s2,16(sp)
    80004158:	69a2                	ld	s3,8(sp)
    8000415a:	6145                	addi	sp,sp,48
    8000415c:	8082                	ret

000000008000415e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	e04a                	sd	s2,0(sp)
    80004168:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000416a:	0001d517          	auipc	a0,0x1d
    8000416e:	00650513          	addi	a0,a0,6 # 80021170 <log>
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	a64080e7          	jalr	-1436(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000417a:	0001d497          	auipc	s1,0x1d
    8000417e:	ff648493          	addi	s1,s1,-10 # 80021170 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004182:	4979                	li	s2,30
    80004184:	a039                	j	80004192 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004186:	85a6                	mv	a1,s1
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffe097          	auipc	ra,0xffffe
    8000418e:	ed6080e7          	jalr	-298(ra) # 80002060 <sleep>
    if(log.committing){
    80004192:	50dc                	lw	a5,36(s1)
    80004194:	fbed                	bnez	a5,80004186 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004196:	5098                	lw	a4,32(s1)
    80004198:	2705                	addiw	a4,a4,1
    8000419a:	0007069b          	sext.w	a3,a4
    8000419e:	0027179b          	slliw	a5,a4,0x2
    800041a2:	9fb9                	addw	a5,a5,a4
    800041a4:	0017979b          	slliw	a5,a5,0x1
    800041a8:	54d8                	lw	a4,44(s1)
    800041aa:	9fb9                	addw	a5,a5,a4
    800041ac:	00f95963          	bge	s2,a5,800041be <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041b0:	85a6                	mv	a1,s1
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffe097          	auipc	ra,0xffffe
    800041b8:	eac080e7          	jalr	-340(ra) # 80002060 <sleep>
    800041bc:	bfd9                	j	80004192 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041be:	0001d517          	auipc	a0,0x1d
    800041c2:	fb250513          	addi	a0,a0,-78 # 80021170 <log>
    800041c6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	ac2080e7          	jalr	-1342(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041d0:	60e2                	ld	ra,24(sp)
    800041d2:	6442                	ld	s0,16(sp)
    800041d4:	64a2                	ld	s1,8(sp)
    800041d6:	6902                	ld	s2,0(sp)
    800041d8:	6105                	addi	sp,sp,32
    800041da:	8082                	ret

00000000800041dc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041dc:	7139                	addi	sp,sp,-64
    800041de:	fc06                	sd	ra,56(sp)
    800041e0:	f822                	sd	s0,48(sp)
    800041e2:	f426                	sd	s1,40(sp)
    800041e4:	f04a                	sd	s2,32(sp)
    800041e6:	ec4e                	sd	s3,24(sp)
    800041e8:	e852                	sd	s4,16(sp)
    800041ea:	e456                	sd	s5,8(sp)
    800041ec:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ee:	0001d497          	auipc	s1,0x1d
    800041f2:	f8248493          	addi	s1,s1,-126 # 80021170 <log>
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	9de080e7          	jalr	-1570(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004200:	509c                	lw	a5,32(s1)
    80004202:	37fd                	addiw	a5,a5,-1
    80004204:	0007891b          	sext.w	s2,a5
    80004208:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000420a:	50dc                	lw	a5,36(s1)
    8000420c:	e7b9                	bnez	a5,8000425a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000420e:	04091e63          	bnez	s2,8000426a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004212:	0001d497          	auipc	s1,0x1d
    80004216:	f5e48493          	addi	s1,s1,-162 # 80021170 <log>
    8000421a:	4785                	li	a5,1
    8000421c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	a6a080e7          	jalr	-1430(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004228:	54dc                	lw	a5,44(s1)
    8000422a:	06f04763          	bgtz	a5,80004298 <end_op+0xbc>
    acquire(&log.lock);
    8000422e:	0001d497          	auipc	s1,0x1d
    80004232:	f4248493          	addi	s1,s1,-190 # 80021170 <log>
    80004236:	8526                	mv	a0,s1
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	99e080e7          	jalr	-1634(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004240:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004244:	8526                	mv	a0,s1
    80004246:	ffffe097          	auipc	ra,0xffffe
    8000424a:	e7e080e7          	jalr	-386(ra) # 800020c4 <wakeup>
    release(&log.lock);
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	a3a080e7          	jalr	-1478(ra) # 80000c8a <release>
}
    80004258:	a03d                	j	80004286 <end_op+0xaa>
    panic("log.committing");
    8000425a:	00004517          	auipc	a0,0x4
    8000425e:	4be50513          	addi	a0,a0,1214 # 80008718 <syscalls+0x1e8>
    80004262:	ffffc097          	auipc	ra,0xffffc
    80004266:	2de080e7          	jalr	734(ra) # 80000540 <panic>
    wakeup(&log);
    8000426a:	0001d497          	auipc	s1,0x1d
    8000426e:	f0648493          	addi	s1,s1,-250 # 80021170 <log>
    80004272:	8526                	mv	a0,s1
    80004274:	ffffe097          	auipc	ra,0xffffe
    80004278:	e50080e7          	jalr	-432(ra) # 800020c4 <wakeup>
  release(&log.lock);
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
}
    80004286:	70e2                	ld	ra,56(sp)
    80004288:	7442                	ld	s0,48(sp)
    8000428a:	74a2                	ld	s1,40(sp)
    8000428c:	7902                	ld	s2,32(sp)
    8000428e:	69e2                	ld	s3,24(sp)
    80004290:	6a42                	ld	s4,16(sp)
    80004292:	6aa2                	ld	s5,8(sp)
    80004294:	6121                	addi	sp,sp,64
    80004296:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004298:	0001da97          	auipc	s5,0x1d
    8000429c:	f08a8a93          	addi	s5,s5,-248 # 800211a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042a0:	0001da17          	auipc	s4,0x1d
    800042a4:	ed0a0a13          	addi	s4,s4,-304 # 80021170 <log>
    800042a8:	018a2583          	lw	a1,24(s4)
    800042ac:	012585bb          	addw	a1,a1,s2
    800042b0:	2585                	addiw	a1,a1,1
    800042b2:	028a2503          	lw	a0,40(s4)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	cc4080e7          	jalr	-828(ra) # 80002f7a <bread>
    800042be:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042c0:	000aa583          	lw	a1,0(s5)
    800042c4:	028a2503          	lw	a0,40(s4)
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	cb2080e7          	jalr	-846(ra) # 80002f7a <bread>
    800042d0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042d2:	40000613          	li	a2,1024
    800042d6:	05850593          	addi	a1,a0,88
    800042da:	05848513          	addi	a0,s1,88
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	a50080e7          	jalr	-1456(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800042e6:	8526                	mv	a0,s1
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	d84080e7          	jalr	-636(ra) # 8000306c <bwrite>
    brelse(from);
    800042f0:	854e                	mv	a0,s3
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	db8080e7          	jalr	-584(ra) # 800030aa <brelse>
    brelse(to);
    800042fa:	8526                	mv	a0,s1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	dae080e7          	jalr	-594(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004304:	2905                	addiw	s2,s2,1
    80004306:	0a91                	addi	s5,s5,4
    80004308:	02ca2783          	lw	a5,44(s4)
    8000430c:	f8f94ee3          	blt	s2,a5,800042a8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004310:	00000097          	auipc	ra,0x0
    80004314:	c68080e7          	jalr	-920(ra) # 80003f78 <write_head>
    install_trans(0); // Now install writes to home locations
    80004318:	4501                	li	a0,0
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	cda080e7          	jalr	-806(ra) # 80003ff4 <install_trans>
    log.lh.n = 0;
    80004322:	0001d797          	auipc	a5,0x1d
    80004326:	e607ad23          	sw	zero,-390(a5) # 8002119c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	c4e080e7          	jalr	-946(ra) # 80003f78 <write_head>
    80004332:	bdf5                	j	8000422e <end_op+0x52>

0000000080004334 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004334:	1101                	addi	sp,sp,-32
    80004336:	ec06                	sd	ra,24(sp)
    80004338:	e822                	sd	s0,16(sp)
    8000433a:	e426                	sd	s1,8(sp)
    8000433c:	e04a                	sd	s2,0(sp)
    8000433e:	1000                	addi	s0,sp,32
    80004340:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004342:	0001d917          	auipc	s2,0x1d
    80004346:	e2e90913          	addi	s2,s2,-466 # 80021170 <log>
    8000434a:	854a                	mv	a0,s2
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	88a080e7          	jalr	-1910(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004354:	02c92603          	lw	a2,44(s2)
    80004358:	47f5                	li	a5,29
    8000435a:	06c7c563          	blt	a5,a2,800043c4 <log_write+0x90>
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	e2e7a783          	lw	a5,-466(a5) # 8002118c <log+0x1c>
    80004366:	37fd                	addiw	a5,a5,-1
    80004368:	04f65e63          	bge	a2,a5,800043c4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000436c:	0001d797          	auipc	a5,0x1d
    80004370:	e247a783          	lw	a5,-476(a5) # 80021190 <log+0x20>
    80004374:	06f05063          	blez	a5,800043d4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004378:	4781                	li	a5,0
    8000437a:	06c05563          	blez	a2,800043e4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000437e:	44cc                	lw	a1,12(s1)
    80004380:	0001d717          	auipc	a4,0x1d
    80004384:	e2070713          	addi	a4,a4,-480 # 800211a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004388:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438a:	4314                	lw	a3,0(a4)
    8000438c:	04b68c63          	beq	a3,a1,800043e4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004390:	2785                	addiw	a5,a5,1
    80004392:	0711                	addi	a4,a4,4
    80004394:	fef61be3          	bne	a2,a5,8000438a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004398:	0621                	addi	a2,a2,8
    8000439a:	060a                	slli	a2,a2,0x2
    8000439c:	0001d797          	auipc	a5,0x1d
    800043a0:	dd478793          	addi	a5,a5,-556 # 80021170 <log>
    800043a4:	97b2                	add	a5,a5,a2
    800043a6:	44d8                	lw	a4,12(s1)
    800043a8:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	d9c080e7          	jalr	-612(ra) # 80003148 <bpin>
    log.lh.n++;
    800043b4:	0001d717          	auipc	a4,0x1d
    800043b8:	dbc70713          	addi	a4,a4,-580 # 80021170 <log>
    800043bc:	575c                	lw	a5,44(a4)
    800043be:	2785                	addiw	a5,a5,1
    800043c0:	d75c                	sw	a5,44(a4)
    800043c2:	a82d                	j	800043fc <log_write+0xc8>
    panic("too big a transaction");
    800043c4:	00004517          	auipc	a0,0x4
    800043c8:	36450513          	addi	a0,a0,868 # 80008728 <syscalls+0x1f8>
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	174080e7          	jalr	372(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043d4:	00004517          	auipc	a0,0x4
    800043d8:	36c50513          	addi	a0,a0,876 # 80008740 <syscalls+0x210>
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	164080e7          	jalr	356(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043e4:	00878693          	addi	a3,a5,8
    800043e8:	068a                	slli	a3,a3,0x2
    800043ea:	0001d717          	auipc	a4,0x1d
    800043ee:	d8670713          	addi	a4,a4,-634 # 80021170 <log>
    800043f2:	9736                	add	a4,a4,a3
    800043f4:	44d4                	lw	a3,12(s1)
    800043f6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043f8:	faf609e3          	beq	a2,a5,800043aa <log_write+0x76>
  }
  release(&log.lock);
    800043fc:	0001d517          	auipc	a0,0x1d
    80004400:	d7450513          	addi	a0,a0,-652 # 80021170 <log>
    80004404:	ffffd097          	auipc	ra,0xffffd
    80004408:	886080e7          	jalr	-1914(ra) # 80000c8a <release>
}
    8000440c:	60e2                	ld	ra,24(sp)
    8000440e:	6442                	ld	s0,16(sp)
    80004410:	64a2                	ld	s1,8(sp)
    80004412:	6902                	ld	s2,0(sp)
    80004414:	6105                	addi	sp,sp,32
    80004416:	8082                	ret

0000000080004418 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004418:	1101                	addi	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	e04a                	sd	s2,0(sp)
    80004422:	1000                	addi	s0,sp,32
    80004424:	84aa                	mv	s1,a0
    80004426:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004428:	00004597          	auipc	a1,0x4
    8000442c:	33858593          	addi	a1,a1,824 # 80008760 <syscalls+0x230>
    80004430:	0521                	addi	a0,a0,8
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	714080e7          	jalr	1812(ra) # 80000b46 <initlock>
  lk->name = name;
    8000443a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000443e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004442:	0204a423          	sw	zero,40(s1)
}
    80004446:	60e2                	ld	ra,24(sp)
    80004448:	6442                	ld	s0,16(sp)
    8000444a:	64a2                	ld	s1,8(sp)
    8000444c:	6902                	ld	s2,0(sp)
    8000444e:	6105                	addi	sp,sp,32
    80004450:	8082                	ret

0000000080004452 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004452:	1101                	addi	sp,sp,-32
    80004454:	ec06                	sd	ra,24(sp)
    80004456:	e822                	sd	s0,16(sp)
    80004458:	e426                	sd	s1,8(sp)
    8000445a:	e04a                	sd	s2,0(sp)
    8000445c:	1000                	addi	s0,sp,32
    8000445e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004460:	00850913          	addi	s2,a0,8
    80004464:	854a                	mv	a0,s2
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	770080e7          	jalr	1904(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000446e:	409c                	lw	a5,0(s1)
    80004470:	cb89                	beqz	a5,80004482 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004472:	85ca                	mv	a1,s2
    80004474:	8526                	mv	a0,s1
    80004476:	ffffe097          	auipc	ra,0xffffe
    8000447a:	bea080e7          	jalr	-1046(ra) # 80002060 <sleep>
  while (lk->locked) {
    8000447e:	409c                	lw	a5,0(s1)
    80004480:	fbed                	bnez	a5,80004472 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004482:	4785                	li	a5,1
    80004484:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	526080e7          	jalr	1318(ra) # 800019ac <myproc>
    8000448e:	591c                	lw	a5,48(a0)
    80004490:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004492:	854a                	mv	a0,s2
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	7f6080e7          	jalr	2038(ra) # 80000c8a <release>
}
    8000449c:	60e2                	ld	ra,24(sp)
    8000449e:	6442                	ld	s0,16(sp)
    800044a0:	64a2                	ld	s1,8(sp)
    800044a2:	6902                	ld	s2,0(sp)
    800044a4:	6105                	addi	sp,sp,32
    800044a6:	8082                	ret

00000000800044a8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	e426                	sd	s1,8(sp)
    800044b0:	e04a                	sd	s2,0(sp)
    800044b2:	1000                	addi	s0,sp,32
    800044b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b6:	00850913          	addi	s2,a0,8
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	71a080e7          	jalr	1818(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffe097          	auipc	ra,0xffffe
    800044d2:	bf6080e7          	jalr	-1034(ra) # 800020c4 <wakeup>
  release(&lk->lk);
    800044d6:	854a                	mv	a0,s2
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7b2080e7          	jalr	1970(ra) # 80000c8a <release>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6902                	ld	s2,0(sp)
    800044e8:	6105                	addi	sp,sp,32
    800044ea:	8082                	ret

00000000800044ec <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ec:	7179                	addi	sp,sp,-48
    800044ee:	f406                	sd	ra,40(sp)
    800044f0:	f022                	sd	s0,32(sp)
    800044f2:	ec26                	sd	s1,24(sp)
    800044f4:	e84a                	sd	s2,16(sp)
    800044f6:	e44e                	sd	s3,8(sp)
    800044f8:	1800                	addi	s0,sp,48
    800044fa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044fc:	00850913          	addi	s2,a0,8
    80004500:	854a                	mv	a0,s2
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	6d4080e7          	jalr	1748(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450a:	409c                	lw	a5,0(s1)
    8000450c:	ef99                	bnez	a5,8000452a <holdingsleep+0x3e>
    8000450e:	4481                	li	s1,0
  release(&lk->lk);
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	778080e7          	jalr	1912(ra) # 80000c8a <release>
  return r;
}
    8000451a:	8526                	mv	a0,s1
    8000451c:	70a2                	ld	ra,40(sp)
    8000451e:	7402                	ld	s0,32(sp)
    80004520:	64e2                	ld	s1,24(sp)
    80004522:	6942                	ld	s2,16(sp)
    80004524:	69a2                	ld	s3,8(sp)
    80004526:	6145                	addi	sp,sp,48
    80004528:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452a:	0284a983          	lw	s3,40(s1)
    8000452e:	ffffd097          	auipc	ra,0xffffd
    80004532:	47e080e7          	jalr	1150(ra) # 800019ac <myproc>
    80004536:	5904                	lw	s1,48(a0)
    80004538:	413484b3          	sub	s1,s1,s3
    8000453c:	0014b493          	seqz	s1,s1
    80004540:	bfc1                	j	80004510 <holdingsleep+0x24>

0000000080004542 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004542:	1141                	addi	sp,sp,-16
    80004544:	e406                	sd	ra,8(sp)
    80004546:	e022                	sd	s0,0(sp)
    80004548:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000454a:	00004597          	auipc	a1,0x4
    8000454e:	22658593          	addi	a1,a1,550 # 80008770 <syscalls+0x240>
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	d6650513          	addi	a0,a0,-666 # 800212b8 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	5ec080e7          	jalr	1516(ra) # 80000b46 <initlock>
}
    80004562:	60a2                	ld	ra,8(sp)
    80004564:	6402                	ld	s0,0(sp)
    80004566:	0141                	addi	sp,sp,16
    80004568:	8082                	ret

000000008000456a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004574:	0001d517          	auipc	a0,0x1d
    80004578:	d4450513          	addi	a0,a0,-700 # 800212b8 <ftable>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	65a080e7          	jalr	1626(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004584:	0001d497          	auipc	s1,0x1d
    80004588:	d4c48493          	addi	s1,s1,-692 # 800212d0 <ftable+0x18>
    8000458c:	0001e717          	auipc	a4,0x1e
    80004590:	ce470713          	addi	a4,a4,-796 # 80022270 <disk>
    if(f->ref == 0){
    80004594:	40dc                	lw	a5,4(s1)
    80004596:	cf99                	beqz	a5,800045b4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004598:	02848493          	addi	s1,s1,40
    8000459c:	fee49ce3          	bne	s1,a4,80004594 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	d1850513          	addi	a0,a0,-744 # 800212b8 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
  return 0;
    800045b0:	4481                	li	s1,0
    800045b2:	a819                	j	800045c8 <filealloc+0x5e>
      f->ref = 1;
    800045b4:	4785                	li	a5,1
    800045b6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	d0050513          	addi	a0,a0,-768 # 800212b8 <ftable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6ca080e7          	jalr	1738(ra) # 80000c8a <release>
}
    800045c8:	8526                	mv	a0,s1
    800045ca:	60e2                	ld	ra,24(sp)
    800045cc:	6442                	ld	s0,16(sp)
    800045ce:	64a2                	ld	s1,8(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	1000                	addi	s0,sp,32
    800045de:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	cd850513          	addi	a0,a0,-808 # 800212b8 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5ee080e7          	jalr	1518(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045f0:	40dc                	lw	a5,4(s1)
    800045f2:	02f05263          	blez	a5,80004616 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045f6:	2785                	addiw	a5,a5,1
    800045f8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045fa:	0001d517          	auipc	a0,0x1d
    800045fe:	cbe50513          	addi	a0,a0,-834 # 800212b8 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	688080e7          	jalr	1672(ra) # 80000c8a <release>
  return f;
}
    8000460a:	8526                	mv	a0,s1
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6105                	addi	sp,sp,32
    80004614:	8082                	ret
    panic("filedup");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	16250513          	addi	a0,a0,354 # 80008778 <syscalls+0x248>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f22080e7          	jalr	-222(ra) # 80000540 <panic>

0000000080004626 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004626:	7139                	addi	sp,sp,-64
    80004628:	fc06                	sd	ra,56(sp)
    8000462a:	f822                	sd	s0,48(sp)
    8000462c:	f426                	sd	s1,40(sp)
    8000462e:	f04a                	sd	s2,32(sp)
    80004630:	ec4e                	sd	s3,24(sp)
    80004632:	e852                	sd	s4,16(sp)
    80004634:	e456                	sd	s5,8(sp)
    80004636:	0080                	addi	s0,sp,64
    80004638:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000463a:	0001d517          	auipc	a0,0x1d
    8000463e:	c7e50513          	addi	a0,a0,-898 # 800212b8 <ftable>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	594080e7          	jalr	1428(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000464a:	40dc                	lw	a5,4(s1)
    8000464c:	06f05163          	blez	a5,800046ae <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004650:	37fd                	addiw	a5,a5,-1
    80004652:	0007871b          	sext.w	a4,a5
    80004656:	c0dc                	sw	a5,4(s1)
    80004658:	06e04363          	bgtz	a4,800046be <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000465c:	0004a903          	lw	s2,0(s1)
    80004660:	0094ca83          	lbu	s5,9(s1)
    80004664:	0104ba03          	ld	s4,16(s1)
    80004668:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000466c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004670:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004674:	0001d517          	auipc	a0,0x1d
    80004678:	c4450513          	addi	a0,a0,-956 # 800212b8 <ftable>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	60e080e7          	jalr	1550(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004684:	4785                	li	a5,1
    80004686:	04f90d63          	beq	s2,a5,800046e0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000468a:	3979                	addiw	s2,s2,-2
    8000468c:	4785                	li	a5,1
    8000468e:	0527e063          	bltu	a5,s2,800046ce <fileclose+0xa8>
    begin_op();
    80004692:	00000097          	auipc	ra,0x0
    80004696:	acc080e7          	jalr	-1332(ra) # 8000415e <begin_op>
    iput(ff.ip);
    8000469a:	854e                	mv	a0,s3
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	2b0080e7          	jalr	688(ra) # 8000394c <iput>
    end_op();
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	b38080e7          	jalr	-1224(ra) # 800041dc <end_op>
    800046ac:	a00d                	j	800046ce <fileclose+0xa8>
    panic("fileclose");
    800046ae:	00004517          	auipc	a0,0x4
    800046b2:	0d250513          	addi	a0,a0,210 # 80008780 <syscalls+0x250>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	e8a080e7          	jalr	-374(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	bfa50513          	addi	a0,a0,-1030 # 800212b8 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5c4080e7          	jalr	1476(ra) # 80000c8a <release>
  }
}
    800046ce:	70e2                	ld	ra,56(sp)
    800046d0:	7442                	ld	s0,48(sp)
    800046d2:	74a2                	ld	s1,40(sp)
    800046d4:	7902                	ld	s2,32(sp)
    800046d6:	69e2                	ld	s3,24(sp)
    800046d8:	6a42                	ld	s4,16(sp)
    800046da:	6aa2                	ld	s5,8(sp)
    800046dc:	6121                	addi	sp,sp,64
    800046de:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046e0:	85d6                	mv	a1,s5
    800046e2:	8552                	mv	a0,s4
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	34c080e7          	jalr	844(ra) # 80004a30 <pipeclose>
    800046ec:	b7cd                	j	800046ce <fileclose+0xa8>

00000000800046ee <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ee:	715d                	addi	sp,sp,-80
    800046f0:	e486                	sd	ra,72(sp)
    800046f2:	e0a2                	sd	s0,64(sp)
    800046f4:	fc26                	sd	s1,56(sp)
    800046f6:	f84a                	sd	s2,48(sp)
    800046f8:	f44e                	sd	s3,40(sp)
    800046fa:	0880                	addi	s0,sp,80
    800046fc:	84aa                	mv	s1,a0
    800046fe:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004700:	ffffd097          	auipc	ra,0xffffd
    80004704:	2ac080e7          	jalr	684(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004708:	409c                	lw	a5,0(s1)
    8000470a:	37f9                	addiw	a5,a5,-2
    8000470c:	4705                	li	a4,1
    8000470e:	04f76763          	bltu	a4,a5,8000475c <filestat+0x6e>
    80004712:	892a                	mv	s2,a0
    ilock(f->ip);
    80004714:	6c88                	ld	a0,24(s1)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	07c080e7          	jalr	124(ra) # 80003792 <ilock>
    stati(f->ip, &st);
    8000471e:	fb840593          	addi	a1,s0,-72
    80004722:	6c88                	ld	a0,24(s1)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	2f8080e7          	jalr	760(ra) # 80003a1c <stati>
    iunlock(f->ip);
    8000472c:	6c88                	ld	a0,24(s1)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	126080e7          	jalr	294(ra) # 80003854 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004736:	46e1                	li	a3,24
    80004738:	fb840613          	addi	a2,s0,-72
    8000473c:	85ce                	mv	a1,s3
    8000473e:	05893503          	ld	a0,88(s2)
    80004742:	ffffd097          	auipc	ra,0xffffd
    80004746:	f2a080e7          	jalr	-214(ra) # 8000166c <copyout>
    8000474a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000474e:	60a6                	ld	ra,72(sp)
    80004750:	6406                	ld	s0,64(sp)
    80004752:	74e2                	ld	s1,56(sp)
    80004754:	7942                	ld	s2,48(sp)
    80004756:	79a2                	ld	s3,40(sp)
    80004758:	6161                	addi	sp,sp,80
    8000475a:	8082                	ret
  return -1;
    8000475c:	557d                	li	a0,-1
    8000475e:	bfc5                	j	8000474e <filestat+0x60>

0000000080004760 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004760:	7179                	addi	sp,sp,-48
    80004762:	f406                	sd	ra,40(sp)
    80004764:	f022                	sd	s0,32(sp)
    80004766:	ec26                	sd	s1,24(sp)
    80004768:	e84a                	sd	s2,16(sp)
    8000476a:	e44e                	sd	s3,8(sp)
    8000476c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000476e:	00854783          	lbu	a5,8(a0)
    80004772:	c3d5                	beqz	a5,80004816 <fileread+0xb6>
    80004774:	84aa                	mv	s1,a0
    80004776:	89ae                	mv	s3,a1
    80004778:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477a:	411c                	lw	a5,0(a0)
    8000477c:	4705                	li	a4,1
    8000477e:	04e78963          	beq	a5,a4,800047d0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004782:	470d                	li	a4,3
    80004784:	04e78d63          	beq	a5,a4,800047de <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004788:	4709                	li	a4,2
    8000478a:	06e79e63          	bne	a5,a4,80004806 <fileread+0xa6>
    ilock(f->ip);
    8000478e:	6d08                	ld	a0,24(a0)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	002080e7          	jalr	2(ra) # 80003792 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004798:	874a                	mv	a4,s2
    8000479a:	5094                	lw	a3,32(s1)
    8000479c:	864e                	mv	a2,s3
    8000479e:	4585                	li	a1,1
    800047a0:	6c88                	ld	a0,24(s1)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	2a4080e7          	jalr	676(ra) # 80003a46 <readi>
    800047aa:	892a                	mv	s2,a0
    800047ac:	00a05563          	blez	a0,800047b6 <fileread+0x56>
      f->off += r;
    800047b0:	509c                	lw	a5,32(s1)
    800047b2:	9fa9                	addw	a5,a5,a0
    800047b4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	09c080e7          	jalr	156(ra) # 80003854 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047c0:	854a                	mv	a0,s2
    800047c2:	70a2                	ld	ra,40(sp)
    800047c4:	7402                	ld	s0,32(sp)
    800047c6:	64e2                	ld	s1,24(sp)
    800047c8:	6942                	ld	s2,16(sp)
    800047ca:	69a2                	ld	s3,8(sp)
    800047cc:	6145                	addi	sp,sp,48
    800047ce:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047d0:	6908                	ld	a0,16(a0)
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	3c6080e7          	jalr	966(ra) # 80004b98 <piperead>
    800047da:	892a                	mv	s2,a0
    800047dc:	b7d5                	j	800047c0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047de:	02451783          	lh	a5,36(a0)
    800047e2:	03079693          	slli	a3,a5,0x30
    800047e6:	92c1                	srli	a3,a3,0x30
    800047e8:	4725                	li	a4,9
    800047ea:	02d76863          	bltu	a4,a3,8000481a <fileread+0xba>
    800047ee:	0792                	slli	a5,a5,0x4
    800047f0:	0001d717          	auipc	a4,0x1d
    800047f4:	a2870713          	addi	a4,a4,-1496 # 80021218 <devsw>
    800047f8:	97ba                	add	a5,a5,a4
    800047fa:	639c                	ld	a5,0(a5)
    800047fc:	c38d                	beqz	a5,8000481e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047fe:	4505                	li	a0,1
    80004800:	9782                	jalr	a5
    80004802:	892a                	mv	s2,a0
    80004804:	bf75                	j	800047c0 <fileread+0x60>
    panic("fileread");
    80004806:	00004517          	auipc	a0,0x4
    8000480a:	f8a50513          	addi	a0,a0,-118 # 80008790 <syscalls+0x260>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d32080e7          	jalr	-718(ra) # 80000540 <panic>
    return -1;
    80004816:	597d                	li	s2,-1
    80004818:	b765                	j	800047c0 <fileread+0x60>
      return -1;
    8000481a:	597d                	li	s2,-1
    8000481c:	b755                	j	800047c0 <fileread+0x60>
    8000481e:	597d                	li	s2,-1
    80004820:	b745                	j	800047c0 <fileread+0x60>

0000000080004822 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004822:	715d                	addi	sp,sp,-80
    80004824:	e486                	sd	ra,72(sp)
    80004826:	e0a2                	sd	s0,64(sp)
    80004828:	fc26                	sd	s1,56(sp)
    8000482a:	f84a                	sd	s2,48(sp)
    8000482c:	f44e                	sd	s3,40(sp)
    8000482e:	f052                	sd	s4,32(sp)
    80004830:	ec56                	sd	s5,24(sp)
    80004832:	e85a                	sd	s6,16(sp)
    80004834:	e45e                	sd	s7,8(sp)
    80004836:	e062                	sd	s8,0(sp)
    80004838:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000483a:	00954783          	lbu	a5,9(a0)
    8000483e:	10078663          	beqz	a5,8000494a <filewrite+0x128>
    80004842:	892a                	mv	s2,a0
    80004844:	8b2e                	mv	s6,a1
    80004846:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004848:	411c                	lw	a5,0(a0)
    8000484a:	4705                	li	a4,1
    8000484c:	02e78263          	beq	a5,a4,80004870 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004850:	470d                	li	a4,3
    80004852:	02e78663          	beq	a5,a4,8000487e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004856:	4709                	li	a4,2
    80004858:	0ee79163          	bne	a5,a4,8000493a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000485c:	0ac05d63          	blez	a2,80004916 <filewrite+0xf4>
    int i = 0;
    80004860:	4981                	li	s3,0
    80004862:	6b85                	lui	s7,0x1
    80004864:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004868:	6c05                	lui	s8,0x1
    8000486a:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000486e:	a861                	j	80004906 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004870:	6908                	ld	a0,16(a0)
    80004872:	00000097          	auipc	ra,0x0
    80004876:	22e080e7          	jalr	558(ra) # 80004aa0 <pipewrite>
    8000487a:	8a2a                	mv	s4,a0
    8000487c:	a045                	j	8000491c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000487e:	02451783          	lh	a5,36(a0)
    80004882:	03079693          	slli	a3,a5,0x30
    80004886:	92c1                	srli	a3,a3,0x30
    80004888:	4725                	li	a4,9
    8000488a:	0cd76263          	bltu	a4,a3,8000494e <filewrite+0x12c>
    8000488e:	0792                	slli	a5,a5,0x4
    80004890:	0001d717          	auipc	a4,0x1d
    80004894:	98870713          	addi	a4,a4,-1656 # 80021218 <devsw>
    80004898:	97ba                	add	a5,a5,a4
    8000489a:	679c                	ld	a5,8(a5)
    8000489c:	cbdd                	beqz	a5,80004952 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000489e:	4505                	li	a0,1
    800048a0:	9782                	jalr	a5
    800048a2:	8a2a                	mv	s4,a0
    800048a4:	a8a5                	j	8000491c <filewrite+0xfa>
    800048a6:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	8b4080e7          	jalr	-1868(ra) # 8000415e <begin_op>
      ilock(f->ip);
    800048b2:	01893503          	ld	a0,24(s2)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	edc080e7          	jalr	-292(ra) # 80003792 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048be:	8756                	mv	a4,s5
    800048c0:	02092683          	lw	a3,32(s2)
    800048c4:	01698633          	add	a2,s3,s6
    800048c8:	4585                	li	a1,1
    800048ca:	01893503          	ld	a0,24(s2)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	270080e7          	jalr	624(ra) # 80003b3e <writei>
    800048d6:	84aa                	mv	s1,a0
    800048d8:	00a05763          	blez	a0,800048e6 <filewrite+0xc4>
        f->off += r;
    800048dc:	02092783          	lw	a5,32(s2)
    800048e0:	9fa9                	addw	a5,a5,a0
    800048e2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048e6:	01893503          	ld	a0,24(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	f6a080e7          	jalr	-150(ra) # 80003854 <iunlock>
      end_op();
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	8ea080e7          	jalr	-1814(ra) # 800041dc <end_op>

      if(r != n1){
    800048fa:	009a9f63          	bne	s5,s1,80004918 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048fe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004902:	0149db63          	bge	s3,s4,80004918 <filewrite+0xf6>
      int n1 = n - i;
    80004906:	413a04bb          	subw	s1,s4,s3
    8000490a:	0004879b          	sext.w	a5,s1
    8000490e:	f8fbdce3          	bge	s7,a5,800048a6 <filewrite+0x84>
    80004912:	84e2                	mv	s1,s8
    80004914:	bf49                	j	800048a6 <filewrite+0x84>
    int i = 0;
    80004916:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004918:	013a1f63          	bne	s4,s3,80004936 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000491c:	8552                	mv	a0,s4
    8000491e:	60a6                	ld	ra,72(sp)
    80004920:	6406                	ld	s0,64(sp)
    80004922:	74e2                	ld	s1,56(sp)
    80004924:	7942                	ld	s2,48(sp)
    80004926:	79a2                	ld	s3,40(sp)
    80004928:	7a02                	ld	s4,32(sp)
    8000492a:	6ae2                	ld	s5,24(sp)
    8000492c:	6b42                	ld	s6,16(sp)
    8000492e:	6ba2                	ld	s7,8(sp)
    80004930:	6c02                	ld	s8,0(sp)
    80004932:	6161                	addi	sp,sp,80
    80004934:	8082                	ret
    ret = (i == n ? n : -1);
    80004936:	5a7d                	li	s4,-1
    80004938:	b7d5                	j	8000491c <filewrite+0xfa>
    panic("filewrite");
    8000493a:	00004517          	auipc	a0,0x4
    8000493e:	e6650513          	addi	a0,a0,-410 # 800087a0 <syscalls+0x270>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	bfe080e7          	jalr	-1026(ra) # 80000540 <panic>
    return -1;
    8000494a:	5a7d                	li	s4,-1
    8000494c:	bfc1                	j	8000491c <filewrite+0xfa>
      return -1;
    8000494e:	5a7d                	li	s4,-1
    80004950:	b7f1                	j	8000491c <filewrite+0xfa>
    80004952:	5a7d                	li	s4,-1
    80004954:	b7e1                	j	8000491c <filewrite+0xfa>

0000000080004956 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004956:	7179                	addi	sp,sp,-48
    80004958:	f406                	sd	ra,40(sp)
    8000495a:	f022                	sd	s0,32(sp)
    8000495c:	ec26                	sd	s1,24(sp)
    8000495e:	e84a                	sd	s2,16(sp)
    80004960:	e44e                	sd	s3,8(sp)
    80004962:	e052                	sd	s4,0(sp)
    80004964:	1800                	addi	s0,sp,48
    80004966:	84aa                	mv	s1,a0
    80004968:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496a:	0005b023          	sd	zero,0(a1)
    8000496e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004972:	00000097          	auipc	ra,0x0
    80004976:	bf8080e7          	jalr	-1032(ra) # 8000456a <filealloc>
    8000497a:	e088                	sd	a0,0(s1)
    8000497c:	c551                	beqz	a0,80004a08 <pipealloc+0xb2>
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	bec080e7          	jalr	-1044(ra) # 8000456a <filealloc>
    80004986:	00aa3023          	sd	a0,0(s4)
    8000498a:	c92d                	beqz	a0,800049fc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	15a080e7          	jalr	346(ra) # 80000ae6 <kalloc>
    80004994:	892a                	mv	s2,a0
    80004996:	c125                	beqz	a0,800049f6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004998:	4985                	li	s3,1
    8000499a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000499e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049a6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049aa:	00004597          	auipc	a1,0x4
    800049ae:	ade58593          	addi	a1,a1,-1314 # 80008488 <states.0+0x1c0>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	194080e7          	jalr	404(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049ba:	609c                	ld	a5,0(s1)
    800049bc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c0:	609c                	ld	a5,0(s1)
    800049c2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049c6:	609c                	ld	a5,0(s1)
    800049c8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049cc:	609c                	ld	a5,0(s1)
    800049ce:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d2:	000a3783          	ld	a5,0(s4)
    800049d6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049da:	000a3783          	ld	a5,0(s4)
    800049de:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e2:	000a3783          	ld	a5,0(s4)
    800049e6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ea:	000a3783          	ld	a5,0(s4)
    800049ee:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f2:	4501                	li	a0,0
    800049f4:	a025                	j	80004a1c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049f6:	6088                	ld	a0,0(s1)
    800049f8:	e501                	bnez	a0,80004a00 <pipealloc+0xaa>
    800049fa:	a039                	j	80004a08 <pipealloc+0xb2>
    800049fc:	6088                	ld	a0,0(s1)
    800049fe:	c51d                	beqz	a0,80004a2c <pipealloc+0xd6>
    fileclose(*f0);
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	c26080e7          	jalr	-986(ra) # 80004626 <fileclose>
  if(*f1)
    80004a08:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a0c:	557d                	li	a0,-1
  if(*f1)
    80004a0e:	c799                	beqz	a5,80004a1c <pipealloc+0xc6>
    fileclose(*f1);
    80004a10:	853e                	mv	a0,a5
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	c14080e7          	jalr	-1004(ra) # 80004626 <fileclose>
  return -1;
    80004a1a:	557d                	li	a0,-1
}
    80004a1c:	70a2                	ld	ra,40(sp)
    80004a1e:	7402                	ld	s0,32(sp)
    80004a20:	64e2                	ld	s1,24(sp)
    80004a22:	6942                	ld	s2,16(sp)
    80004a24:	69a2                	ld	s3,8(sp)
    80004a26:	6a02                	ld	s4,0(sp)
    80004a28:	6145                	addi	sp,sp,48
    80004a2a:	8082                	ret
  return -1;
    80004a2c:	557d                	li	a0,-1
    80004a2e:	b7fd                	j	80004a1c <pipealloc+0xc6>

0000000080004a30 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a30:	1101                	addi	sp,sp,-32
    80004a32:	ec06                	sd	ra,24(sp)
    80004a34:	e822                	sd	s0,16(sp)
    80004a36:	e426                	sd	s1,8(sp)
    80004a38:	e04a                	sd	s2,0(sp)
    80004a3a:	1000                	addi	s0,sp,32
    80004a3c:	84aa                	mv	s1,a0
    80004a3e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  if(writable){
    80004a48:	02090d63          	beqz	s2,80004a82 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a4c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a50:	21848513          	addi	a0,s1,536
    80004a54:	ffffd097          	auipc	ra,0xffffd
    80004a58:	670080e7          	jalr	1648(ra) # 800020c4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a5c:	2204b783          	ld	a5,544(s1)
    80004a60:	eb95                	bnez	a5,80004a94 <pipeclose+0x64>
    release(&pi->lock);
    80004a62:	8526                	mv	a0,s1
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	226080e7          	jalr	550(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	f7a080e7          	jalr	-134(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a76:	60e2                	ld	ra,24(sp)
    80004a78:	6442                	ld	s0,16(sp)
    80004a7a:	64a2                	ld	s1,8(sp)
    80004a7c:	6902                	ld	s2,0(sp)
    80004a7e:	6105                	addi	sp,sp,32
    80004a80:	8082                	ret
    pi->readopen = 0;
    80004a82:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a86:	21c48513          	addi	a0,s1,540
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	63a080e7          	jalr	1594(ra) # 800020c4 <wakeup>
    80004a92:	b7e9                	j	80004a5c <pipeclose+0x2c>
    release(&pi->lock);
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	1f4080e7          	jalr	500(ra) # 80000c8a <release>
}
    80004a9e:	bfe1                	j	80004a76 <pipeclose+0x46>

0000000080004aa0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa0:	711d                	addi	sp,sp,-96
    80004aa2:	ec86                	sd	ra,88(sp)
    80004aa4:	e8a2                	sd	s0,80(sp)
    80004aa6:	e4a6                	sd	s1,72(sp)
    80004aa8:	e0ca                	sd	s2,64(sp)
    80004aaa:	fc4e                	sd	s3,56(sp)
    80004aac:	f852                	sd	s4,48(sp)
    80004aae:	f456                	sd	s5,40(sp)
    80004ab0:	f05a                	sd	s6,32(sp)
    80004ab2:	ec5e                	sd	s7,24(sp)
    80004ab4:	e862                	sd	s8,16(sp)
    80004ab6:	1080                	addi	s0,sp,96
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	8aae                	mv	s5,a1
    80004abc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	eee080e7          	jalr	-274(ra) # 800019ac <myproc>
    80004ac6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	10c080e7          	jalr	268(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ad2:	0b405663          	blez	s4,80004b7e <pipewrite+0xde>
  int i = 0;
    80004ad6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ada:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ade:	21c48b93          	addi	s7,s1,540
    80004ae2:	a089                	j	80004b24 <pipewrite+0x84>
      release(&pi->lock);
    80004ae4:	8526                	mv	a0,s1
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	1a4080e7          	jalr	420(ra) # 80000c8a <release>
      return -1;
    80004aee:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004af0:	854a                	mv	a0,s2
    80004af2:	60e6                	ld	ra,88(sp)
    80004af4:	6446                	ld	s0,80(sp)
    80004af6:	64a6                	ld	s1,72(sp)
    80004af8:	6906                	ld	s2,64(sp)
    80004afa:	79e2                	ld	s3,56(sp)
    80004afc:	7a42                	ld	s4,48(sp)
    80004afe:	7aa2                	ld	s5,40(sp)
    80004b00:	7b02                	ld	s6,32(sp)
    80004b02:	6be2                	ld	s7,24(sp)
    80004b04:	6c42                	ld	s8,16(sp)
    80004b06:	6125                	addi	sp,sp,96
    80004b08:	8082                	ret
      wakeup(&pi->nread);
    80004b0a:	8562                	mv	a0,s8
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	5b8080e7          	jalr	1464(ra) # 800020c4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b14:	85a6                	mv	a1,s1
    80004b16:	855e                	mv	a0,s7
    80004b18:	ffffd097          	auipc	ra,0xffffd
    80004b1c:	548080e7          	jalr	1352(ra) # 80002060 <sleep>
  while(i < n){
    80004b20:	07495063          	bge	s2,s4,80004b80 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b24:	2204a783          	lw	a5,544(s1)
    80004b28:	dfd5                	beqz	a5,80004ae4 <pipewrite+0x44>
    80004b2a:	854e                	mv	a0,s3
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	7dc080e7          	jalr	2012(ra) # 80002308 <killed>
    80004b34:	f945                	bnez	a0,80004ae4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b36:	2184a783          	lw	a5,536(s1)
    80004b3a:	21c4a703          	lw	a4,540(s1)
    80004b3e:	2007879b          	addiw	a5,a5,512
    80004b42:	fcf704e3          	beq	a4,a5,80004b0a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b46:	4685                	li	a3,1
    80004b48:	01590633          	add	a2,s2,s5
    80004b4c:	faf40593          	addi	a1,s0,-81
    80004b50:	0589b503          	ld	a0,88(s3)
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	ba4080e7          	jalr	-1116(ra) # 800016f8 <copyin>
    80004b5c:	03650263          	beq	a0,s6,80004b80 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b60:	21c4a783          	lw	a5,540(s1)
    80004b64:	0017871b          	addiw	a4,a5,1
    80004b68:	20e4ae23          	sw	a4,540(s1)
    80004b6c:	1ff7f793          	andi	a5,a5,511
    80004b70:	97a6                	add	a5,a5,s1
    80004b72:	faf44703          	lbu	a4,-81(s0)
    80004b76:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b7a:	2905                	addiw	s2,s2,1
    80004b7c:	b755                	j	80004b20 <pipewrite+0x80>
  int i = 0;
    80004b7e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b80:	21848513          	addi	a0,s1,536
    80004b84:	ffffd097          	auipc	ra,0xffffd
    80004b88:	540080e7          	jalr	1344(ra) # 800020c4 <wakeup>
  release(&pi->lock);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	0fc080e7          	jalr	252(ra) # 80000c8a <release>
  return i;
    80004b96:	bfa9                	j	80004af0 <pipewrite+0x50>

0000000080004b98 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b98:	715d                	addi	sp,sp,-80
    80004b9a:	e486                	sd	ra,72(sp)
    80004b9c:	e0a2                	sd	s0,64(sp)
    80004b9e:	fc26                	sd	s1,56(sp)
    80004ba0:	f84a                	sd	s2,48(sp)
    80004ba2:	f44e                	sd	s3,40(sp)
    80004ba4:	f052                	sd	s4,32(sp)
    80004ba6:	ec56                	sd	s5,24(sp)
    80004ba8:	e85a                	sd	s6,16(sp)
    80004baa:	0880                	addi	s0,sp,80
    80004bac:	84aa                	mv	s1,a0
    80004bae:	892e                	mv	s2,a1
    80004bb0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	dfa080e7          	jalr	-518(ra) # 800019ac <myproc>
    80004bba:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	018080e7          	jalr	24(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc6:	2184a703          	lw	a4,536(s1)
    80004bca:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd2:	02f71763          	bne	a4,a5,80004c00 <piperead+0x68>
    80004bd6:	2244a783          	lw	a5,548(s1)
    80004bda:	c39d                	beqz	a5,80004c00 <piperead+0x68>
    if(killed(pr)){
    80004bdc:	8552                	mv	a0,s4
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	72a080e7          	jalr	1834(ra) # 80002308 <killed>
    80004be6:	e949                	bnez	a0,80004c78 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be8:	85a6                	mv	a1,s1
    80004bea:	854e                	mv	a0,s3
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	474080e7          	jalr	1140(ra) # 80002060 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf4:	2184a703          	lw	a4,536(s1)
    80004bf8:	21c4a783          	lw	a5,540(s1)
    80004bfc:	fcf70de3          	beq	a4,a5,80004bd6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c00:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c02:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c04:	05505463          	blez	s5,80004c4c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c08:	2184a783          	lw	a5,536(s1)
    80004c0c:	21c4a703          	lw	a4,540(s1)
    80004c10:	02f70e63          	beq	a4,a5,80004c4c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c14:	0017871b          	addiw	a4,a5,1
    80004c18:	20e4ac23          	sw	a4,536(s1)
    80004c1c:	1ff7f793          	andi	a5,a5,511
    80004c20:	97a6                	add	a5,a5,s1
    80004c22:	0187c783          	lbu	a5,24(a5)
    80004c26:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c2a:	4685                	li	a3,1
    80004c2c:	fbf40613          	addi	a2,s0,-65
    80004c30:	85ca                	mv	a1,s2
    80004c32:	058a3503          	ld	a0,88(s4)
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	a36080e7          	jalr	-1482(ra) # 8000166c <copyout>
    80004c3e:	01650763          	beq	a0,s6,80004c4c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c42:	2985                	addiw	s3,s3,1
    80004c44:	0905                	addi	s2,s2,1
    80004c46:	fd3a91e3          	bne	s5,s3,80004c08 <piperead+0x70>
    80004c4a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c4c:	21c48513          	addi	a0,s1,540
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	474080e7          	jalr	1140(ra) # 800020c4 <wakeup>
  release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	030080e7          	jalr	48(ra) # 80000c8a <release>
  return i;
}
    80004c62:	854e                	mv	a0,s3
    80004c64:	60a6                	ld	ra,72(sp)
    80004c66:	6406                	ld	s0,64(sp)
    80004c68:	74e2                	ld	s1,56(sp)
    80004c6a:	7942                	ld	s2,48(sp)
    80004c6c:	79a2                	ld	s3,40(sp)
    80004c6e:	7a02                	ld	s4,32(sp)
    80004c70:	6ae2                	ld	s5,24(sp)
    80004c72:	6b42                	ld	s6,16(sp)
    80004c74:	6161                	addi	sp,sp,80
    80004c76:	8082                	ret
      release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	010080e7          	jalr	16(ra) # 80000c8a <release>
      return -1;
    80004c82:	59fd                	li	s3,-1
    80004c84:	bff9                	j	80004c62 <piperead+0xca>

0000000080004c86 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c86:	1141                	addi	sp,sp,-16
    80004c88:	e422                	sd	s0,8(sp)
    80004c8a:	0800                	addi	s0,sp,16
    80004c8c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c8e:	8905                	andi	a0,a0,1
    80004c90:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c92:	8b89                	andi	a5,a5,2
    80004c94:	c399                	beqz	a5,80004c9a <flags2perm+0x14>
      perm |= PTE_W;
    80004c96:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c9a:	6422                	ld	s0,8(sp)
    80004c9c:	0141                	addi	sp,sp,16
    80004c9e:	8082                	ret

0000000080004ca0 <exec>:

int
exec(char *path, char **argv)
{
    80004ca0:	de010113          	addi	sp,sp,-544
    80004ca4:	20113c23          	sd	ra,536(sp)
    80004ca8:	20813823          	sd	s0,528(sp)
    80004cac:	20913423          	sd	s1,520(sp)
    80004cb0:	21213023          	sd	s2,512(sp)
    80004cb4:	ffce                	sd	s3,504(sp)
    80004cb6:	fbd2                	sd	s4,496(sp)
    80004cb8:	f7d6                	sd	s5,488(sp)
    80004cba:	f3da                	sd	s6,480(sp)
    80004cbc:	efde                	sd	s7,472(sp)
    80004cbe:	ebe2                	sd	s8,464(sp)
    80004cc0:	e7e6                	sd	s9,456(sp)
    80004cc2:	e3ea                	sd	s10,448(sp)
    80004cc4:	ff6e                	sd	s11,440(sp)
    80004cc6:	1400                	addi	s0,sp,544
    80004cc8:	892a                	mv	s2,a0
    80004cca:	dea43423          	sd	a0,-536(s0)
    80004cce:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	cda080e7          	jalr	-806(ra) # 800019ac <myproc>
    80004cda:	84aa                	mv	s1,a0

  begin_op();
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	482080e7          	jalr	1154(ra) # 8000415e <begin_op>

  if((ip = namei(path)) == 0){
    80004ce4:	854a                	mv	a0,s2
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	258080e7          	jalr	600(ra) # 80003f3e <namei>
    80004cee:	c93d                	beqz	a0,80004d64 <exec+0xc4>
    80004cf0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	aa0080e7          	jalr	-1376(ra) # 80003792 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cfa:	04000713          	li	a4,64
    80004cfe:	4681                	li	a3,0
    80004d00:	e5040613          	addi	a2,s0,-432
    80004d04:	4581                	li	a1,0
    80004d06:	8556                	mv	a0,s5
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	d3e080e7          	jalr	-706(ra) # 80003a46 <readi>
    80004d10:	04000793          	li	a5,64
    80004d14:	00f51a63          	bne	a0,a5,80004d28 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d18:	e5042703          	lw	a4,-432(s0)
    80004d1c:	464c47b7          	lui	a5,0x464c4
    80004d20:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d24:	04f70663          	beq	a4,a5,80004d70 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d28:	8556                	mv	a0,s5
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	cca080e7          	jalr	-822(ra) # 800039f4 <iunlockput>
    end_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	4aa080e7          	jalr	1194(ra) # 800041dc <end_op>
  }
  return -1;
    80004d3a:	557d                	li	a0,-1
}
    80004d3c:	21813083          	ld	ra,536(sp)
    80004d40:	21013403          	ld	s0,528(sp)
    80004d44:	20813483          	ld	s1,520(sp)
    80004d48:	20013903          	ld	s2,512(sp)
    80004d4c:	79fe                	ld	s3,504(sp)
    80004d4e:	7a5e                	ld	s4,496(sp)
    80004d50:	7abe                	ld	s5,488(sp)
    80004d52:	7b1e                	ld	s6,480(sp)
    80004d54:	6bfe                	ld	s7,472(sp)
    80004d56:	6c5e                	ld	s8,464(sp)
    80004d58:	6cbe                	ld	s9,456(sp)
    80004d5a:	6d1e                	ld	s10,448(sp)
    80004d5c:	7dfa                	ld	s11,440(sp)
    80004d5e:	22010113          	addi	sp,sp,544
    80004d62:	8082                	ret
    end_op();
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	478080e7          	jalr	1144(ra) # 800041dc <end_op>
    return -1;
    80004d6c:	557d                	li	a0,-1
    80004d6e:	b7f9                	j	80004d3c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	cfe080e7          	jalr	-770(ra) # 80001a70 <proc_pagetable>
    80004d7a:	8b2a                	mv	s6,a0
    80004d7c:	d555                	beqz	a0,80004d28 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7e:	e7042783          	lw	a5,-400(s0)
    80004d82:	e8845703          	lhu	a4,-376(s0)
    80004d86:	c735                	beqz	a4,80004df2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d88:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d8e:	6a05                	lui	s4,0x1
    80004d90:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d94:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d98:	6d85                	lui	s11,0x1
    80004d9a:	7d7d                	lui	s10,0xfffff
    80004d9c:	ac3d                	j	80004fda <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d9e:	00004517          	auipc	a0,0x4
    80004da2:	a1250513          	addi	a0,a0,-1518 # 800087b0 <syscalls+0x280>
    80004da6:	ffffb097          	auipc	ra,0xffffb
    80004daa:	79a080e7          	jalr	1946(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dae:	874a                	mv	a4,s2
    80004db0:	009c86bb          	addw	a3,s9,s1
    80004db4:	4581                	li	a1,0
    80004db6:	8556                	mv	a0,s5
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	c8e080e7          	jalr	-882(ra) # 80003a46 <readi>
    80004dc0:	2501                	sext.w	a0,a0
    80004dc2:	1aa91963          	bne	s2,a0,80004f74 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004dc6:	009d84bb          	addw	s1,s11,s1
    80004dca:	013d09bb          	addw	s3,s10,s3
    80004dce:	1f74f663          	bgeu	s1,s7,80004fba <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004dd2:	02049593          	slli	a1,s1,0x20
    80004dd6:	9181                	srli	a1,a1,0x20
    80004dd8:	95e2                	add	a1,a1,s8
    80004dda:	855a                	mv	a0,s6
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	280080e7          	jalr	640(ra) # 8000105c <walkaddr>
    80004de4:	862a                	mv	a2,a0
    if(pa == 0)
    80004de6:	dd45                	beqz	a0,80004d9e <exec+0xfe>
      n = PGSIZE;
    80004de8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dea:	fd49f2e3          	bgeu	s3,s4,80004dae <exec+0x10e>
      n = sz - i;
    80004dee:	894e                	mv	s2,s3
    80004df0:	bf7d                	j	80004dae <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df2:	4901                	li	s2,0
  iunlockput(ip);
    80004df4:	8556                	mv	a0,s5
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	bfe080e7          	jalr	-1026(ra) # 800039f4 <iunlockput>
  end_op();
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	3de080e7          	jalr	990(ra) # 800041dc <end_op>
  p = myproc();
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	ba6080e7          	jalr	-1114(ra) # 800019ac <myproc>
    80004e0e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e10:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e14:	6785                	lui	a5,0x1
    80004e16:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e18:	97ca                	add	a5,a5,s2
    80004e1a:	777d                	lui	a4,0xfffff
    80004e1c:	8ff9                	and	a5,a5,a4
    80004e1e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e22:	4691                	li	a3,4
    80004e24:	6609                	lui	a2,0x2
    80004e26:	963e                	add	a2,a2,a5
    80004e28:	85be                	mv	a1,a5
    80004e2a:	855a                	mv	a0,s6
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	5e4080e7          	jalr	1508(ra) # 80001410 <uvmalloc>
    80004e34:	8c2a                	mv	s8,a0
  ip = 0;
    80004e36:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e38:	12050e63          	beqz	a0,80004f74 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e3c:	75f9                	lui	a1,0xffffe
    80004e3e:	95aa                	add	a1,a1,a0
    80004e40:	855a                	mv	a0,s6
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	7f8080e7          	jalr	2040(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e4a:	7afd                	lui	s5,0xfffff
    80004e4c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e4e:	df043783          	ld	a5,-528(s0)
    80004e52:	6388                	ld	a0,0(a5)
    80004e54:	c925                	beqz	a0,80004ec4 <exec+0x224>
    80004e56:	e9040993          	addi	s3,s0,-368
    80004e5a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e5e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	fec080e7          	jalr	-20(ra) # 80000e4e <strlen>
    80004e6a:	0015079b          	addiw	a5,a0,1
    80004e6e:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e72:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e76:	13596663          	bltu	s2,s5,80004fa2 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7a:	df043d83          	ld	s11,-528(s0)
    80004e7e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e82:	8552                	mv	a0,s4
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	fca080e7          	jalr	-54(ra) # 80000e4e <strlen>
    80004e8c:	0015069b          	addiw	a3,a0,1
    80004e90:	8652                	mv	a2,s4
    80004e92:	85ca                	mv	a1,s2
    80004e94:	855a                	mv	a0,s6
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	7d6080e7          	jalr	2006(ra) # 8000166c <copyout>
    80004e9e:	10054663          	bltz	a0,80004faa <exec+0x30a>
    ustack[argc] = sp;
    80004ea2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ea6:	0485                	addi	s1,s1,1
    80004ea8:	008d8793          	addi	a5,s11,8
    80004eac:	def43823          	sd	a5,-528(s0)
    80004eb0:	008db503          	ld	a0,8(s11)
    80004eb4:	c911                	beqz	a0,80004ec8 <exec+0x228>
    if(argc >= MAXARG)
    80004eb6:	09a1                	addi	s3,s3,8
    80004eb8:	fb3c95e3          	bne	s9,s3,80004e62 <exec+0x1c2>
  sz = sz1;
    80004ebc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec0:	4a81                	li	s5,0
    80004ec2:	a84d                	j	80004f74 <exec+0x2d4>
  sp = sz;
    80004ec4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ec8:	00349793          	slli	a5,s1,0x3
    80004ecc:	f9078793          	addi	a5,a5,-112
    80004ed0:	97a2                	add	a5,a5,s0
    80004ed2:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ed6:	00148693          	addi	a3,s1,1
    80004eda:	068e                	slli	a3,a3,0x3
    80004edc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee4:	01597663          	bgeu	s2,s5,80004ef0 <exec+0x250>
  sz = sz1;
    80004ee8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eec:	4a81                	li	s5,0
    80004eee:	a059                	j	80004f74 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef0:	e9040613          	addi	a2,s0,-368
    80004ef4:	85ca                	mv	a1,s2
    80004ef6:	855a                	mv	a0,s6
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	774080e7          	jalr	1908(ra) # 8000166c <copyout>
    80004f00:	0a054963          	bltz	a0,80004fb2 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f04:	060bb783          	ld	a5,96(s7)
    80004f08:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f0c:	de843783          	ld	a5,-536(s0)
    80004f10:	0007c703          	lbu	a4,0(a5)
    80004f14:	cf11                	beqz	a4,80004f30 <exec+0x290>
    80004f16:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f18:	02f00693          	li	a3,47
    80004f1c:	a039                	j	80004f2a <exec+0x28a>
      last = s+1;
    80004f1e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f22:	0785                	addi	a5,a5,1
    80004f24:	fff7c703          	lbu	a4,-1(a5)
    80004f28:	c701                	beqz	a4,80004f30 <exec+0x290>
    if(*s == '/')
    80004f2a:	fed71ce3          	bne	a4,a3,80004f22 <exec+0x282>
    80004f2e:	bfc5                	j	80004f1e <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f30:	4641                	li	a2,16
    80004f32:	de843583          	ld	a1,-536(s0)
    80004f36:	160b8513          	addi	a0,s7,352
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	ee2080e7          	jalr	-286(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f42:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80004f46:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80004f4a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f4e:	060bb783          	ld	a5,96(s7)
    80004f52:	e6843703          	ld	a4,-408(s0)
    80004f56:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f58:	060bb783          	ld	a5,96(s7)
    80004f5c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f60:	85ea                	mv	a1,s10
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	baa080e7          	jalr	-1110(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6a:	0004851b          	sext.w	a0,s1
    80004f6e:	b3f9                	j	80004d3c <exec+0x9c>
    80004f70:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f74:	df843583          	ld	a1,-520(s0)
    80004f78:	855a                	mv	a0,s6
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	b92080e7          	jalr	-1134(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f82:	da0a93e3          	bnez	s5,80004d28 <exec+0x88>
  return -1;
    80004f86:	557d                	li	a0,-1
    80004f88:	bb55                	j	80004d3c <exec+0x9c>
    80004f8a:	df243c23          	sd	s2,-520(s0)
    80004f8e:	b7dd                	j	80004f74 <exec+0x2d4>
    80004f90:	df243c23          	sd	s2,-520(s0)
    80004f94:	b7c5                	j	80004f74 <exec+0x2d4>
    80004f96:	df243c23          	sd	s2,-520(s0)
    80004f9a:	bfe9                	j	80004f74 <exec+0x2d4>
    80004f9c:	df243c23          	sd	s2,-520(s0)
    80004fa0:	bfd1                	j	80004f74 <exec+0x2d4>
  sz = sz1;
    80004fa2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fa6:	4a81                	li	s5,0
    80004fa8:	b7f1                	j	80004f74 <exec+0x2d4>
  sz = sz1;
    80004faa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fae:	4a81                	li	s5,0
    80004fb0:	b7d1                	j	80004f74 <exec+0x2d4>
  sz = sz1;
    80004fb2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fb6:	4a81                	li	s5,0
    80004fb8:	bf75                	j	80004f74 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fba:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fbe:	e0843783          	ld	a5,-504(s0)
    80004fc2:	0017869b          	addiw	a3,a5,1
    80004fc6:	e0d43423          	sd	a3,-504(s0)
    80004fca:	e0043783          	ld	a5,-512(s0)
    80004fce:	0387879b          	addiw	a5,a5,56
    80004fd2:	e8845703          	lhu	a4,-376(s0)
    80004fd6:	e0e6dfe3          	bge	a3,a4,80004df4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fda:	2781                	sext.w	a5,a5
    80004fdc:	e0f43023          	sd	a5,-512(s0)
    80004fe0:	03800713          	li	a4,56
    80004fe4:	86be                	mv	a3,a5
    80004fe6:	e1840613          	addi	a2,s0,-488
    80004fea:	4581                	li	a1,0
    80004fec:	8556                	mv	a0,s5
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	a58080e7          	jalr	-1448(ra) # 80003a46 <readi>
    80004ff6:	03800793          	li	a5,56
    80004ffa:	f6f51be3          	bne	a0,a5,80004f70 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004ffe:	e1842783          	lw	a5,-488(s0)
    80005002:	4705                	li	a4,1
    80005004:	fae79de3          	bne	a5,a4,80004fbe <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005008:	e4043483          	ld	s1,-448(s0)
    8000500c:	e3843783          	ld	a5,-456(s0)
    80005010:	f6f4ede3          	bltu	s1,a5,80004f8a <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005014:	e2843783          	ld	a5,-472(s0)
    80005018:	94be                	add	s1,s1,a5
    8000501a:	f6f4ebe3          	bltu	s1,a5,80004f90 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000501e:	de043703          	ld	a4,-544(s0)
    80005022:	8ff9                	and	a5,a5,a4
    80005024:	fbad                	bnez	a5,80004f96 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005026:	e1c42503          	lw	a0,-484(s0)
    8000502a:	00000097          	auipc	ra,0x0
    8000502e:	c5c080e7          	jalr	-932(ra) # 80004c86 <flags2perm>
    80005032:	86aa                	mv	a3,a0
    80005034:	8626                	mv	a2,s1
    80005036:	85ca                	mv	a1,s2
    80005038:	855a                	mv	a0,s6
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	3d6080e7          	jalr	982(ra) # 80001410 <uvmalloc>
    80005042:	dea43c23          	sd	a0,-520(s0)
    80005046:	d939                	beqz	a0,80004f9c <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005048:	e2843c03          	ld	s8,-472(s0)
    8000504c:	e2042c83          	lw	s9,-480(s0)
    80005050:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005054:	f60b83e3          	beqz	s7,80004fba <exec+0x31a>
    80005058:	89de                	mv	s3,s7
    8000505a:	4481                	li	s1,0
    8000505c:	bb9d                	j	80004dd2 <exec+0x132>

000000008000505e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000505e:	7179                	addi	sp,sp,-48
    80005060:	f406                	sd	ra,40(sp)
    80005062:	f022                	sd	s0,32(sp)
    80005064:	ec26                	sd	s1,24(sp)
    80005066:	e84a                	sd	s2,16(sp)
    80005068:	1800                	addi	s0,sp,48
    8000506a:	892e                	mv	s2,a1
    8000506c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000506e:	fdc40593          	addi	a1,s0,-36
    80005072:	ffffe097          	auipc	ra,0xffffe
    80005076:	a7e080e7          	jalr	-1410(ra) # 80002af0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000507a:	fdc42703          	lw	a4,-36(s0)
    8000507e:	47bd                	li	a5,15
    80005080:	02e7eb63          	bltu	a5,a4,800050b6 <argfd+0x58>
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	928080e7          	jalr	-1752(ra) # 800019ac <myproc>
    8000508c:	fdc42703          	lw	a4,-36(s0)
    80005090:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdcc6a>
    80005094:	078e                	slli	a5,a5,0x3
    80005096:	953e                	add	a0,a0,a5
    80005098:	651c                	ld	a5,8(a0)
    8000509a:	c385                	beqz	a5,800050ba <argfd+0x5c>
    return -1;
  if(pfd)
    8000509c:	00090463          	beqz	s2,800050a4 <argfd+0x46>
    *pfd = fd;
    800050a0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050a4:	4501                	li	a0,0
  if(pf)
    800050a6:	c091                	beqz	s1,800050aa <argfd+0x4c>
    *pf = f;
    800050a8:	e09c                	sd	a5,0(s1)
}
    800050aa:	70a2                	ld	ra,40(sp)
    800050ac:	7402                	ld	s0,32(sp)
    800050ae:	64e2                	ld	s1,24(sp)
    800050b0:	6942                	ld	s2,16(sp)
    800050b2:	6145                	addi	sp,sp,48
    800050b4:	8082                	ret
    return -1;
    800050b6:	557d                	li	a0,-1
    800050b8:	bfcd                	j	800050aa <argfd+0x4c>
    800050ba:	557d                	li	a0,-1
    800050bc:	b7fd                	j	800050aa <argfd+0x4c>

00000000800050be <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050be:	1101                	addi	sp,sp,-32
    800050c0:	ec06                	sd	ra,24(sp)
    800050c2:	e822                	sd	s0,16(sp)
    800050c4:	e426                	sd	s1,8(sp)
    800050c6:	1000                	addi	s0,sp,32
    800050c8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ca:	ffffd097          	auipc	ra,0xffffd
    800050ce:	8e2080e7          	jalr	-1822(ra) # 800019ac <myproc>
    800050d2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d4:	0d850793          	addi	a5,a0,216
    800050d8:	4501                	li	a0,0
    800050da:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050dc:	6398                	ld	a4,0(a5)
    800050de:	cb19                	beqz	a4,800050f4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e0:	2505                	addiw	a0,a0,1
    800050e2:	07a1                	addi	a5,a5,8
    800050e4:	fed51ce3          	bne	a0,a3,800050dc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050e8:	557d                	li	a0,-1
}
    800050ea:	60e2                	ld	ra,24(sp)
    800050ec:	6442                	ld	s0,16(sp)
    800050ee:	64a2                	ld	s1,8(sp)
    800050f0:	6105                	addi	sp,sp,32
    800050f2:	8082                	ret
      p->ofile[fd] = f;
    800050f4:	01a50793          	addi	a5,a0,26
    800050f8:	078e                	slli	a5,a5,0x3
    800050fa:	963e                	add	a2,a2,a5
    800050fc:	e604                	sd	s1,8(a2)
      return fd;
    800050fe:	b7f5                	j	800050ea <fdalloc+0x2c>

0000000080005100 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005100:	715d                	addi	sp,sp,-80
    80005102:	e486                	sd	ra,72(sp)
    80005104:	e0a2                	sd	s0,64(sp)
    80005106:	fc26                	sd	s1,56(sp)
    80005108:	f84a                	sd	s2,48(sp)
    8000510a:	f44e                	sd	s3,40(sp)
    8000510c:	f052                	sd	s4,32(sp)
    8000510e:	ec56                	sd	s5,24(sp)
    80005110:	e85a                	sd	s6,16(sp)
    80005112:	0880                	addi	s0,sp,80
    80005114:	8b2e                	mv	s6,a1
    80005116:	89b2                	mv	s3,a2
    80005118:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000511a:	fb040593          	addi	a1,s0,-80
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	e3e080e7          	jalr	-450(ra) # 80003f5c <nameiparent>
    80005126:	84aa                	mv	s1,a0
    80005128:	14050f63          	beqz	a0,80005286 <create+0x186>
    return 0;

  ilock(dp);
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	666080e7          	jalr	1638(ra) # 80003792 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005134:	4601                	li	a2,0
    80005136:	fb040593          	addi	a1,s0,-80
    8000513a:	8526                	mv	a0,s1
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	b3a080e7          	jalr	-1222(ra) # 80003c76 <dirlookup>
    80005144:	8aaa                	mv	s5,a0
    80005146:	c931                	beqz	a0,8000519a <create+0x9a>
    iunlockput(dp);
    80005148:	8526                	mv	a0,s1
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	8aa080e7          	jalr	-1878(ra) # 800039f4 <iunlockput>
    ilock(ip);
    80005152:	8556                	mv	a0,s5
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	63e080e7          	jalr	1598(ra) # 80003792 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000515c:	000b059b          	sext.w	a1,s6
    80005160:	4789                	li	a5,2
    80005162:	02f59563          	bne	a1,a5,8000518c <create+0x8c>
    80005166:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcc94>
    8000516a:	37f9                	addiw	a5,a5,-2
    8000516c:	17c2                	slli	a5,a5,0x30
    8000516e:	93c1                	srli	a5,a5,0x30
    80005170:	4705                	li	a4,1
    80005172:	00f76d63          	bltu	a4,a5,8000518c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005176:	8556                	mv	a0,s5
    80005178:	60a6                	ld	ra,72(sp)
    8000517a:	6406                	ld	s0,64(sp)
    8000517c:	74e2                	ld	s1,56(sp)
    8000517e:	7942                	ld	s2,48(sp)
    80005180:	79a2                	ld	s3,40(sp)
    80005182:	7a02                	ld	s4,32(sp)
    80005184:	6ae2                	ld	s5,24(sp)
    80005186:	6b42                	ld	s6,16(sp)
    80005188:	6161                	addi	sp,sp,80
    8000518a:	8082                	ret
    iunlockput(ip);
    8000518c:	8556                	mv	a0,s5
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	866080e7          	jalr	-1946(ra) # 800039f4 <iunlockput>
    return 0;
    80005196:	4a81                	li	s5,0
    80005198:	bff9                	j	80005176 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000519a:	85da                	mv	a1,s6
    8000519c:	4088                	lw	a0,0(s1)
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	456080e7          	jalr	1110(ra) # 800035f4 <ialloc>
    800051a6:	8a2a                	mv	s4,a0
    800051a8:	c539                	beqz	a0,800051f6 <create+0xf6>
  ilock(ip);
    800051aa:	ffffe097          	auipc	ra,0xffffe
    800051ae:	5e8080e7          	jalr	1512(ra) # 80003792 <ilock>
  ip->major = major;
    800051b2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051b6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051ba:	4905                	li	s2,1
    800051bc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051c0:	8552                	mv	a0,s4
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	504080e7          	jalr	1284(ra) # 800036c6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ca:	000b059b          	sext.w	a1,s6
    800051ce:	03258b63          	beq	a1,s2,80005204 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051d2:	004a2603          	lw	a2,4(s4)
    800051d6:	fb040593          	addi	a1,s0,-80
    800051da:	8526                	mv	a0,s1
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	cb0080e7          	jalr	-848(ra) # 80003e8c <dirlink>
    800051e4:	06054f63          	bltz	a0,80005262 <create+0x162>
  iunlockput(dp);
    800051e8:	8526                	mv	a0,s1
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	80a080e7          	jalr	-2038(ra) # 800039f4 <iunlockput>
  return ip;
    800051f2:	8ad2                	mv	s5,s4
    800051f4:	b749                	j	80005176 <create+0x76>
    iunlockput(dp);
    800051f6:	8526                	mv	a0,s1
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	7fc080e7          	jalr	2044(ra) # 800039f4 <iunlockput>
    return 0;
    80005200:	8ad2                	mv	s5,s4
    80005202:	bf95                	j	80005176 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005204:	004a2603          	lw	a2,4(s4)
    80005208:	00003597          	auipc	a1,0x3
    8000520c:	5c858593          	addi	a1,a1,1480 # 800087d0 <syscalls+0x2a0>
    80005210:	8552                	mv	a0,s4
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	c7a080e7          	jalr	-902(ra) # 80003e8c <dirlink>
    8000521a:	04054463          	bltz	a0,80005262 <create+0x162>
    8000521e:	40d0                	lw	a2,4(s1)
    80005220:	00003597          	auipc	a1,0x3
    80005224:	5b858593          	addi	a1,a1,1464 # 800087d8 <syscalls+0x2a8>
    80005228:	8552                	mv	a0,s4
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	c62080e7          	jalr	-926(ra) # 80003e8c <dirlink>
    80005232:	02054863          	bltz	a0,80005262 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005236:	004a2603          	lw	a2,4(s4)
    8000523a:	fb040593          	addi	a1,s0,-80
    8000523e:	8526                	mv	a0,s1
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	c4c080e7          	jalr	-948(ra) # 80003e8c <dirlink>
    80005248:	00054d63          	bltz	a0,80005262 <create+0x162>
    dp->nlink++;  // for ".."
    8000524c:	04a4d783          	lhu	a5,74(s1)
    80005250:	2785                	addiw	a5,a5,1
    80005252:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	46e080e7          	jalr	1134(ra) # 800036c6 <iupdate>
    80005260:	b761                	j	800051e8 <create+0xe8>
  ip->nlink = 0;
    80005262:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005266:	8552                	mv	a0,s4
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	45e080e7          	jalr	1118(ra) # 800036c6 <iupdate>
  iunlockput(ip);
    80005270:	8552                	mv	a0,s4
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	782080e7          	jalr	1922(ra) # 800039f4 <iunlockput>
  iunlockput(dp);
    8000527a:	8526                	mv	a0,s1
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	778080e7          	jalr	1912(ra) # 800039f4 <iunlockput>
  return 0;
    80005284:	bdcd                	j	80005176 <create+0x76>
    return 0;
    80005286:	8aaa                	mv	s5,a0
    80005288:	b5fd                	j	80005176 <create+0x76>

000000008000528a <sys_dup>:
{
    8000528a:	7179                	addi	sp,sp,-48
    8000528c:	f406                	sd	ra,40(sp)
    8000528e:	f022                	sd	s0,32(sp)
    80005290:	ec26                	sd	s1,24(sp)
    80005292:	e84a                	sd	s2,16(sp)
    80005294:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005296:	fd840613          	addi	a2,s0,-40
    8000529a:	4581                	li	a1,0
    8000529c:	4501                	li	a0,0
    8000529e:	00000097          	auipc	ra,0x0
    800052a2:	dc0080e7          	jalr	-576(ra) # 8000505e <argfd>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052a8:	02054363          	bltz	a0,800052ce <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052ac:	fd843903          	ld	s2,-40(s0)
    800052b0:	854a                	mv	a0,s2
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	e0c080e7          	jalr	-500(ra) # 800050be <fdalloc>
    800052ba:	84aa                	mv	s1,a0
    return -1;
    800052bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052be:	00054863          	bltz	a0,800052ce <sys_dup+0x44>
  filedup(f);
    800052c2:	854a                	mv	a0,s2
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	310080e7          	jalr	784(ra) # 800045d4 <filedup>
  return fd;
    800052cc:	87a6                	mv	a5,s1
}
    800052ce:	853e                	mv	a0,a5
    800052d0:	70a2                	ld	ra,40(sp)
    800052d2:	7402                	ld	s0,32(sp)
    800052d4:	64e2                	ld	s1,24(sp)
    800052d6:	6942                	ld	s2,16(sp)
    800052d8:	6145                	addi	sp,sp,48
    800052da:	8082                	ret

00000000800052dc <sys_read>:
{
    800052dc:	7179                	addi	sp,sp,-48
    800052de:	f406                	sd	ra,40(sp)
    800052e0:	f022                	sd	s0,32(sp)
    800052e2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052e4:	fd840593          	addi	a1,s0,-40
    800052e8:	4505                	li	a0,1
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	826080e7          	jalr	-2010(ra) # 80002b10 <argaddr>
  argint(2, &n);
    800052f2:	fe440593          	addi	a1,s0,-28
    800052f6:	4509                	li	a0,2
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	7f8080e7          	jalr	2040(ra) # 80002af0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005300:	fe840613          	addi	a2,s0,-24
    80005304:	4581                	li	a1,0
    80005306:	4501                	li	a0,0
    80005308:	00000097          	auipc	ra,0x0
    8000530c:	d56080e7          	jalr	-682(ra) # 8000505e <argfd>
    80005310:	87aa                	mv	a5,a0
    return -1;
    80005312:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005314:	0007cc63          	bltz	a5,8000532c <sys_read+0x50>
  return fileread(f, p, n);
    80005318:	fe442603          	lw	a2,-28(s0)
    8000531c:	fd843583          	ld	a1,-40(s0)
    80005320:	fe843503          	ld	a0,-24(s0)
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	43c080e7          	jalr	1084(ra) # 80004760 <fileread>
}
    8000532c:	70a2                	ld	ra,40(sp)
    8000532e:	7402                	ld	s0,32(sp)
    80005330:	6145                	addi	sp,sp,48
    80005332:	8082                	ret

0000000080005334 <sys_write>:
{
    80005334:	7179                	addi	sp,sp,-48
    80005336:	f406                	sd	ra,40(sp)
    80005338:	f022                	sd	s0,32(sp)
    8000533a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000533c:	fd840593          	addi	a1,s0,-40
    80005340:	4505                	li	a0,1
    80005342:	ffffd097          	auipc	ra,0xffffd
    80005346:	7ce080e7          	jalr	1998(ra) # 80002b10 <argaddr>
  argint(2, &n);
    8000534a:	fe440593          	addi	a1,s0,-28
    8000534e:	4509                	li	a0,2
    80005350:	ffffd097          	auipc	ra,0xffffd
    80005354:	7a0080e7          	jalr	1952(ra) # 80002af0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005358:	fe840613          	addi	a2,s0,-24
    8000535c:	4581                	li	a1,0
    8000535e:	4501                	li	a0,0
    80005360:	00000097          	auipc	ra,0x0
    80005364:	cfe080e7          	jalr	-770(ra) # 8000505e <argfd>
    80005368:	87aa                	mv	a5,a0
    return -1;
    8000536a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000536c:	0007cc63          	bltz	a5,80005384 <sys_write+0x50>
  return filewrite(f, p, n);
    80005370:	fe442603          	lw	a2,-28(s0)
    80005374:	fd843583          	ld	a1,-40(s0)
    80005378:	fe843503          	ld	a0,-24(s0)
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	4a6080e7          	jalr	1190(ra) # 80004822 <filewrite>
}
    80005384:	70a2                	ld	ra,40(sp)
    80005386:	7402                	ld	s0,32(sp)
    80005388:	6145                	addi	sp,sp,48
    8000538a:	8082                	ret

000000008000538c <sys_close>:
{
    8000538c:	1101                	addi	sp,sp,-32
    8000538e:	ec06                	sd	ra,24(sp)
    80005390:	e822                	sd	s0,16(sp)
    80005392:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005394:	fe040613          	addi	a2,s0,-32
    80005398:	fec40593          	addi	a1,s0,-20
    8000539c:	4501                	li	a0,0
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	cc0080e7          	jalr	-832(ra) # 8000505e <argfd>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053a8:	02054463          	bltz	a0,800053d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	600080e7          	jalr	1536(ra) # 800019ac <myproc>
    800053b4:	fec42783          	lw	a5,-20(s0)
    800053b8:	07e9                	addi	a5,a5,26
    800053ba:	078e                	slli	a5,a5,0x3
    800053bc:	953e                	add	a0,a0,a5
    800053be:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800053c2:	fe043503          	ld	a0,-32(s0)
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	260080e7          	jalr	608(ra) # 80004626 <fileclose>
  return 0;
    800053ce:	4781                	li	a5,0
}
    800053d0:	853e                	mv	a0,a5
    800053d2:	60e2                	ld	ra,24(sp)
    800053d4:	6442                	ld	s0,16(sp)
    800053d6:	6105                	addi	sp,sp,32
    800053d8:	8082                	ret

00000000800053da <sys_fstat>:
{
    800053da:	1101                	addi	sp,sp,-32
    800053dc:	ec06                	sd	ra,24(sp)
    800053de:	e822                	sd	s0,16(sp)
    800053e0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053e2:	fe040593          	addi	a1,s0,-32
    800053e6:	4505                	li	a0,1
    800053e8:	ffffd097          	auipc	ra,0xffffd
    800053ec:	728080e7          	jalr	1832(ra) # 80002b10 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053f0:	fe840613          	addi	a2,s0,-24
    800053f4:	4581                	li	a1,0
    800053f6:	4501                	li	a0,0
    800053f8:	00000097          	auipc	ra,0x0
    800053fc:	c66080e7          	jalr	-922(ra) # 8000505e <argfd>
    80005400:	87aa                	mv	a5,a0
    return -1;
    80005402:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005404:	0007ca63          	bltz	a5,80005418 <sys_fstat+0x3e>
  return filestat(f, st);
    80005408:	fe043583          	ld	a1,-32(s0)
    8000540c:	fe843503          	ld	a0,-24(s0)
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	2de080e7          	jalr	734(ra) # 800046ee <filestat>
}
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	addi	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_link>:
{
    80005420:	7169                	addi	sp,sp,-304
    80005422:	f606                	sd	ra,296(sp)
    80005424:	f222                	sd	s0,288(sp)
    80005426:	ee26                	sd	s1,280(sp)
    80005428:	ea4a                	sd	s2,272(sp)
    8000542a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542c:	08000613          	li	a2,128
    80005430:	ed040593          	addi	a1,s0,-304
    80005434:	4501                	li	a0,0
    80005436:	ffffd097          	auipc	ra,0xffffd
    8000543a:	6fa080e7          	jalr	1786(ra) # 80002b30 <argstr>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005440:	10054e63          	bltz	a0,8000555c <sys_link+0x13c>
    80005444:	08000613          	li	a2,128
    80005448:	f5040593          	addi	a1,s0,-176
    8000544c:	4505                	li	a0,1
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	6e2080e7          	jalr	1762(ra) # 80002b30 <argstr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005458:	10054263          	bltz	a0,8000555c <sys_link+0x13c>
  begin_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	d02080e7          	jalr	-766(ra) # 8000415e <begin_op>
  if((ip = namei(old)) == 0){
    80005464:	ed040513          	addi	a0,s0,-304
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	ad6080e7          	jalr	-1322(ra) # 80003f3e <namei>
    80005470:	84aa                	mv	s1,a0
    80005472:	c551                	beqz	a0,800054fe <sys_link+0xde>
  ilock(ip);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	31e080e7          	jalr	798(ra) # 80003792 <ilock>
  if(ip->type == T_DIR){
    8000547c:	04449703          	lh	a4,68(s1)
    80005480:	4785                	li	a5,1
    80005482:	08f70463          	beq	a4,a5,8000550a <sys_link+0xea>
  ip->nlink++;
    80005486:	04a4d783          	lhu	a5,74(s1)
    8000548a:	2785                	addiw	a5,a5,1
    8000548c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	234080e7          	jalr	564(ra) # 800036c6 <iupdate>
  iunlock(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	3b8080e7          	jalr	952(ra) # 80003854 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a4:	fd040593          	addi	a1,s0,-48
    800054a8:	f5040513          	addi	a0,s0,-176
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	ab0080e7          	jalr	-1360(ra) # 80003f5c <nameiparent>
    800054b4:	892a                	mv	s2,a0
    800054b6:	c935                	beqz	a0,8000552a <sys_link+0x10a>
  ilock(dp);
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	2da080e7          	jalr	730(ra) # 80003792 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c0:	00092703          	lw	a4,0(s2)
    800054c4:	409c                	lw	a5,0(s1)
    800054c6:	04f71d63          	bne	a4,a5,80005520 <sys_link+0x100>
    800054ca:	40d0                	lw	a2,4(s1)
    800054cc:	fd040593          	addi	a1,s0,-48
    800054d0:	854a                	mv	a0,s2
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	9ba080e7          	jalr	-1606(ra) # 80003e8c <dirlink>
    800054da:	04054363          	bltz	a0,80005520 <sys_link+0x100>
  iunlockput(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	514080e7          	jalr	1300(ra) # 800039f4 <iunlockput>
  iput(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	462080e7          	jalr	1122(ra) # 8000394c <iput>
  end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cea080e7          	jalr	-790(ra) # 800041dc <end_op>
  return 0;
    800054fa:	4781                	li	a5,0
    800054fc:	a085                	j	8000555c <sys_link+0x13c>
    end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	cde080e7          	jalr	-802(ra) # 800041dc <end_op>
    return -1;
    80005506:	57fd                	li	a5,-1
    80005508:	a891                	j	8000555c <sys_link+0x13c>
    iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	4e8080e7          	jalr	1256(ra) # 800039f4 <iunlockput>
    end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	cc8080e7          	jalr	-824(ra) # 800041dc <end_op>
    return -1;
    8000551c:	57fd                	li	a5,-1
    8000551e:	a83d                	j	8000555c <sys_link+0x13c>
    iunlockput(dp);
    80005520:	854a                	mv	a0,s2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	4d2080e7          	jalr	1234(ra) # 800039f4 <iunlockput>
  ilock(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	266080e7          	jalr	614(ra) # 80003792 <ilock>
  ip->nlink--;
    80005534:	04a4d783          	lhu	a5,74(s1)
    80005538:	37fd                	addiw	a5,a5,-1
    8000553a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	186080e7          	jalr	390(ra) # 800036c6 <iupdate>
  iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	4aa080e7          	jalr	1194(ra) # 800039f4 <iunlockput>
  end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	c8a080e7          	jalr	-886(ra) # 800041dc <end_op>
  return -1;
    8000555a:	57fd                	li	a5,-1
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	70b2                	ld	ra,296(sp)
    80005560:	7412                	ld	s0,288(sp)
    80005562:	64f2                	ld	s1,280(sp)
    80005564:	6952                	ld	s2,272(sp)
    80005566:	6155                	addi	sp,sp,304
    80005568:	8082                	ret

000000008000556a <sys_unlink>:
{
    8000556a:	7151                	addi	sp,sp,-240
    8000556c:	f586                	sd	ra,232(sp)
    8000556e:	f1a2                	sd	s0,224(sp)
    80005570:	eda6                	sd	s1,216(sp)
    80005572:	e9ca                	sd	s2,208(sp)
    80005574:	e5ce                	sd	s3,200(sp)
    80005576:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005578:	08000613          	li	a2,128
    8000557c:	f3040593          	addi	a1,s0,-208
    80005580:	4501                	li	a0,0
    80005582:	ffffd097          	auipc	ra,0xffffd
    80005586:	5ae080e7          	jalr	1454(ra) # 80002b30 <argstr>
    8000558a:	18054163          	bltz	a0,8000570c <sys_unlink+0x1a2>
  begin_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	bd0080e7          	jalr	-1072(ra) # 8000415e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005596:	fb040593          	addi	a1,s0,-80
    8000559a:	f3040513          	addi	a0,s0,-208
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	9be080e7          	jalr	-1602(ra) # 80003f5c <nameiparent>
    800055a6:	84aa                	mv	s1,a0
    800055a8:	c979                	beqz	a0,8000567e <sys_unlink+0x114>
  ilock(dp);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	1e8080e7          	jalr	488(ra) # 80003792 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b2:	00003597          	auipc	a1,0x3
    800055b6:	21e58593          	addi	a1,a1,542 # 800087d0 <syscalls+0x2a0>
    800055ba:	fb040513          	addi	a0,s0,-80
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	69e080e7          	jalr	1694(ra) # 80003c5c <namecmp>
    800055c6:	14050a63          	beqz	a0,8000571a <sys_unlink+0x1b0>
    800055ca:	00003597          	auipc	a1,0x3
    800055ce:	20e58593          	addi	a1,a1,526 # 800087d8 <syscalls+0x2a8>
    800055d2:	fb040513          	addi	a0,s0,-80
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	686080e7          	jalr	1670(ra) # 80003c5c <namecmp>
    800055de:	12050e63          	beqz	a0,8000571a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e2:	f2c40613          	addi	a2,s0,-212
    800055e6:	fb040593          	addi	a1,s0,-80
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	68a080e7          	jalr	1674(ra) # 80003c76 <dirlookup>
    800055f4:	892a                	mv	s2,a0
    800055f6:	12050263          	beqz	a0,8000571a <sys_unlink+0x1b0>
  ilock(ip);
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	198080e7          	jalr	408(ra) # 80003792 <ilock>
  if(ip->nlink < 1)
    80005602:	04a91783          	lh	a5,74(s2)
    80005606:	08f05263          	blez	a5,8000568a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000560a:	04491703          	lh	a4,68(s2)
    8000560e:	4785                	li	a5,1
    80005610:	08f70563          	beq	a4,a5,8000569a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005614:	4641                	li	a2,16
    80005616:	4581                	li	a1,0
    80005618:	fc040513          	addi	a0,s0,-64
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	6b6080e7          	jalr	1718(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005624:	4741                	li	a4,16
    80005626:	f2c42683          	lw	a3,-212(s0)
    8000562a:	fc040613          	addi	a2,s0,-64
    8000562e:	4581                	li	a1,0
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	50c080e7          	jalr	1292(ra) # 80003b3e <writei>
    8000563a:	47c1                	li	a5,16
    8000563c:	0af51563          	bne	a0,a5,800056e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005640:	04491703          	lh	a4,68(s2)
    80005644:	4785                	li	a5,1
    80005646:	0af70863          	beq	a4,a5,800056f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	3a8080e7          	jalr	936(ra) # 800039f4 <iunlockput>
  ip->nlink--;
    80005654:	04a95783          	lhu	a5,74(s2)
    80005658:	37fd                	addiw	a5,a5,-1
    8000565a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	066080e7          	jalr	102(ra) # 800036c6 <iupdate>
  iunlockput(ip);
    80005668:	854a                	mv	a0,s2
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	38a080e7          	jalr	906(ra) # 800039f4 <iunlockput>
  end_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	b6a080e7          	jalr	-1174(ra) # 800041dc <end_op>
  return 0;
    8000567a:	4501                	li	a0,0
    8000567c:	a84d                	j	8000572e <sys_unlink+0x1c4>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	b5e080e7          	jalr	-1186(ra) # 800041dc <end_op>
    return -1;
    80005686:	557d                	li	a0,-1
    80005688:	a05d                	j	8000572e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000568a:	00003517          	auipc	a0,0x3
    8000568e:	15650513          	addi	a0,a0,342 # 800087e0 <syscalls+0x2b0>
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	eae080e7          	jalr	-338(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569a:	04c92703          	lw	a4,76(s2)
    8000569e:	02000793          	li	a5,32
    800056a2:	f6e7f9e3          	bgeu	a5,a4,80005614 <sys_unlink+0xaa>
    800056a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056aa:	4741                	li	a4,16
    800056ac:	86ce                	mv	a3,s3
    800056ae:	f1840613          	addi	a2,s0,-232
    800056b2:	4581                	li	a1,0
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	390080e7          	jalr	912(ra) # 80003a46 <readi>
    800056be:	47c1                	li	a5,16
    800056c0:	00f51b63          	bne	a0,a5,800056d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c4:	f1845783          	lhu	a5,-232(s0)
    800056c8:	e7a1                	bnez	a5,80005710 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ca:	29c1                	addiw	s3,s3,16
    800056cc:	04c92783          	lw	a5,76(s2)
    800056d0:	fcf9ede3          	bltu	s3,a5,800056aa <sys_unlink+0x140>
    800056d4:	b781                	j	80005614 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056d6:	00003517          	auipc	a0,0x3
    800056da:	12250513          	addi	a0,a0,290 # 800087f8 <syscalls+0x2c8>
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	e62080e7          	jalr	-414(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056e6:	00003517          	auipc	a0,0x3
    800056ea:	12a50513          	addi	a0,a0,298 # 80008810 <syscalls+0x2e0>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	e52080e7          	jalr	-430(ra) # 80000540 <panic>
    dp->nlink--;
    800056f6:	04a4d783          	lhu	a5,74(s1)
    800056fa:	37fd                	addiw	a5,a5,-1
    800056fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	fc4080e7          	jalr	-60(ra) # 800036c6 <iupdate>
    8000570a:	b781                	j	8000564a <sys_unlink+0xe0>
    return -1;
    8000570c:	557d                	li	a0,-1
    8000570e:	a005                	j	8000572e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005710:	854a                	mv	a0,s2
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	2e2080e7          	jalr	738(ra) # 800039f4 <iunlockput>
  iunlockput(dp);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	2d8080e7          	jalr	728(ra) # 800039f4 <iunlockput>
  end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	ab8080e7          	jalr	-1352(ra) # 800041dc <end_op>
  return -1;
    8000572c:	557d                	li	a0,-1
}
    8000572e:	70ae                	ld	ra,232(sp)
    80005730:	740e                	ld	s0,224(sp)
    80005732:	64ee                	ld	s1,216(sp)
    80005734:	694e                	ld	s2,208(sp)
    80005736:	69ae                	ld	s3,200(sp)
    80005738:	616d                	addi	sp,sp,240
    8000573a:	8082                	ret

000000008000573c <sys_open>:

uint64
sys_open(void)
{
    8000573c:	7131                	addi	sp,sp,-192
    8000573e:	fd06                	sd	ra,184(sp)
    80005740:	f922                	sd	s0,176(sp)
    80005742:	f526                	sd	s1,168(sp)
    80005744:	f14a                	sd	s2,160(sp)
    80005746:	ed4e                	sd	s3,152(sp)
    80005748:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000574a:	f4c40593          	addi	a1,s0,-180
    8000574e:	4505                	li	a0,1
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	3a0080e7          	jalr	928(ra) # 80002af0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005758:	08000613          	li	a2,128
    8000575c:	f5040593          	addi	a1,s0,-176
    80005760:	4501                	li	a0,0
    80005762:	ffffd097          	auipc	ra,0xffffd
    80005766:	3ce080e7          	jalr	974(ra) # 80002b30 <argstr>
    8000576a:	87aa                	mv	a5,a0
    return -1;
    8000576c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000576e:	0a07c963          	bltz	a5,80005820 <sys_open+0xe4>

  begin_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	9ec080e7          	jalr	-1556(ra) # 8000415e <begin_op>

  if(omode & O_CREATE){
    8000577a:	f4c42783          	lw	a5,-180(s0)
    8000577e:	2007f793          	andi	a5,a5,512
    80005782:	cfc5                	beqz	a5,8000583a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005784:	4681                	li	a3,0
    80005786:	4601                	li	a2,0
    80005788:	4589                	li	a1,2
    8000578a:	f5040513          	addi	a0,s0,-176
    8000578e:	00000097          	auipc	ra,0x0
    80005792:	972080e7          	jalr	-1678(ra) # 80005100 <create>
    80005796:	84aa                	mv	s1,a0
    if(ip == 0){
    80005798:	c959                	beqz	a0,8000582e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000579a:	04449703          	lh	a4,68(s1)
    8000579e:	478d                	li	a5,3
    800057a0:	00f71763          	bne	a4,a5,800057ae <sys_open+0x72>
    800057a4:	0464d703          	lhu	a4,70(s1)
    800057a8:	47a5                	li	a5,9
    800057aa:	0ce7ed63          	bltu	a5,a4,80005884 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	dbc080e7          	jalr	-580(ra) # 8000456a <filealloc>
    800057b6:	89aa                	mv	s3,a0
    800057b8:	10050363          	beqz	a0,800058be <sys_open+0x182>
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	902080e7          	jalr	-1790(ra) # 800050be <fdalloc>
    800057c4:	892a                	mv	s2,a0
    800057c6:	0e054763          	bltz	a0,800058b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ca:	04449703          	lh	a4,68(s1)
    800057ce:	478d                	li	a5,3
    800057d0:	0cf70563          	beq	a4,a5,8000589a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d4:	4789                	li	a5,2
    800057d6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057da:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057de:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e2:	f4c42783          	lw	a5,-180(s0)
    800057e6:	0017c713          	xori	a4,a5,1
    800057ea:	8b05                	andi	a4,a4,1
    800057ec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f0:	0037f713          	andi	a4,a5,3
    800057f4:	00e03733          	snez	a4,a4
    800057f8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057fc:	4007f793          	andi	a5,a5,1024
    80005800:	c791                	beqz	a5,8000580c <sys_open+0xd0>
    80005802:	04449703          	lh	a4,68(s1)
    80005806:	4789                	li	a5,2
    80005808:	0af70063          	beq	a4,a5,800058a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	046080e7          	jalr	70(ra) # 80003854 <iunlock>
  end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	9c6080e7          	jalr	-1594(ra) # 800041dc <end_op>

  return fd;
    8000581e:	854a                	mv	a0,s2
}
    80005820:	70ea                	ld	ra,184(sp)
    80005822:	744a                	ld	s0,176(sp)
    80005824:	74aa                	ld	s1,168(sp)
    80005826:	790a                	ld	s2,160(sp)
    80005828:	69ea                	ld	s3,152(sp)
    8000582a:	6129                	addi	sp,sp,192
    8000582c:	8082                	ret
      end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	9ae080e7          	jalr	-1618(ra) # 800041dc <end_op>
      return -1;
    80005836:	557d                	li	a0,-1
    80005838:	b7e5                	j	80005820 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000583a:	f5040513          	addi	a0,s0,-176
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	700080e7          	jalr	1792(ra) # 80003f3e <namei>
    80005846:	84aa                	mv	s1,a0
    80005848:	c905                	beqz	a0,80005878 <sys_open+0x13c>
    ilock(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	f48080e7          	jalr	-184(ra) # 80003792 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005852:	04449703          	lh	a4,68(s1)
    80005856:	4785                	li	a5,1
    80005858:	f4f711e3          	bne	a4,a5,8000579a <sys_open+0x5e>
    8000585c:	f4c42783          	lw	a5,-180(s0)
    80005860:	d7b9                	beqz	a5,800057ae <sys_open+0x72>
      iunlockput(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	190080e7          	jalr	400(ra) # 800039f4 <iunlockput>
      end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	970080e7          	jalr	-1680(ra) # 800041dc <end_op>
      return -1;
    80005874:	557d                	li	a0,-1
    80005876:	b76d                	j	80005820 <sys_open+0xe4>
      end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	964080e7          	jalr	-1692(ra) # 800041dc <end_op>
      return -1;
    80005880:	557d                	li	a0,-1
    80005882:	bf79                	j	80005820 <sys_open+0xe4>
    iunlockput(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	16e080e7          	jalr	366(ra) # 800039f4 <iunlockput>
    end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	94e080e7          	jalr	-1714(ra) # 800041dc <end_op>
    return -1;
    80005896:	557d                	li	a0,-1
    80005898:	b761                	j	80005820 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000589a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000589e:	04649783          	lh	a5,70(s1)
    800058a2:	02f99223          	sh	a5,36(s3)
    800058a6:	bf25                	j	800057de <sys_open+0xa2>
    itrunc(ip);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	ff6080e7          	jalr	-10(ra) # 800038a0 <itrunc>
    800058b2:	bfa9                	j	8000580c <sys_open+0xd0>
      fileclose(f);
    800058b4:	854e                	mv	a0,s3
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	d70080e7          	jalr	-656(ra) # 80004626 <fileclose>
    iunlockput(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	134080e7          	jalr	308(ra) # 800039f4 <iunlockput>
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	914080e7          	jalr	-1772(ra) # 800041dc <end_op>
    return -1;
    800058d0:	557d                	li	a0,-1
    800058d2:	b7b9                	j	80005820 <sys_open+0xe4>

00000000800058d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d4:	7175                	addi	sp,sp,-144
    800058d6:	e506                	sd	ra,136(sp)
    800058d8:	e122                	sd	s0,128(sp)
    800058da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	882080e7          	jalr	-1918(ra) # 8000415e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e4:	08000613          	li	a2,128
    800058e8:	f7040593          	addi	a1,s0,-144
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	242080e7          	jalr	578(ra) # 80002b30 <argstr>
    800058f6:	02054963          	bltz	a0,80005928 <sys_mkdir+0x54>
    800058fa:	4681                	li	a3,0
    800058fc:	4601                	li	a2,0
    800058fe:	4585                	li	a1,1
    80005900:	f7040513          	addi	a0,s0,-144
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	7fc080e7          	jalr	2044(ra) # 80005100 <create>
    8000590c:	cd11                	beqz	a0,80005928 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	0e6080e7          	jalr	230(ra) # 800039f4 <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	8c6080e7          	jalr	-1850(ra) # 800041dc <end_op>
  return 0;
    8000591e:	4501                	li	a0,0
}
    80005920:	60aa                	ld	ra,136(sp)
    80005922:	640a                	ld	s0,128(sp)
    80005924:	6149                	addi	sp,sp,144
    80005926:	8082                	ret
    end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	8b4080e7          	jalr	-1868(ra) # 800041dc <end_op>
    return -1;
    80005930:	557d                	li	a0,-1
    80005932:	b7fd                	j	80005920 <sys_mkdir+0x4c>

0000000080005934 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005934:	7135                	addi	sp,sp,-160
    80005936:	ed06                	sd	ra,152(sp)
    80005938:	e922                	sd	s0,144(sp)
    8000593a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	822080e7          	jalr	-2014(ra) # 8000415e <begin_op>
  argint(1, &major);
    80005944:	f6c40593          	addi	a1,s0,-148
    80005948:	4505                	li	a0,1
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	1a6080e7          	jalr	422(ra) # 80002af0 <argint>
  argint(2, &minor);
    80005952:	f6840593          	addi	a1,s0,-152
    80005956:	4509                	li	a0,2
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	198080e7          	jalr	408(ra) # 80002af0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005960:	08000613          	li	a2,128
    80005964:	f7040593          	addi	a1,s0,-144
    80005968:	4501                	li	a0,0
    8000596a:	ffffd097          	auipc	ra,0xffffd
    8000596e:	1c6080e7          	jalr	454(ra) # 80002b30 <argstr>
    80005972:	02054b63          	bltz	a0,800059a8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005976:	f6841683          	lh	a3,-152(s0)
    8000597a:	f6c41603          	lh	a2,-148(s0)
    8000597e:	458d                	li	a1,3
    80005980:	f7040513          	addi	a0,s0,-144
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	77c080e7          	jalr	1916(ra) # 80005100 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000598c:	cd11                	beqz	a0,800059a8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	066080e7          	jalr	102(ra) # 800039f4 <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	846080e7          	jalr	-1978(ra) # 800041dc <end_op>
  return 0;
    8000599e:	4501                	li	a0,0
}
    800059a0:	60ea                	ld	ra,152(sp)
    800059a2:	644a                	ld	s0,144(sp)
    800059a4:	610d                	addi	sp,sp,160
    800059a6:	8082                	ret
    end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	834080e7          	jalr	-1996(ra) # 800041dc <end_op>
    return -1;
    800059b0:	557d                	li	a0,-1
    800059b2:	b7fd                	j	800059a0 <sys_mknod+0x6c>

00000000800059b4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b4:	7135                	addi	sp,sp,-160
    800059b6:	ed06                	sd	ra,152(sp)
    800059b8:	e922                	sd	s0,144(sp)
    800059ba:	e526                	sd	s1,136(sp)
    800059bc:	e14a                	sd	s2,128(sp)
    800059be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c0:	ffffc097          	auipc	ra,0xffffc
    800059c4:	fec080e7          	jalr	-20(ra) # 800019ac <myproc>
    800059c8:	892a                	mv	s2,a0
  
  begin_op();
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	794080e7          	jalr	1940(ra) # 8000415e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d2:	08000613          	li	a2,128
    800059d6:	f6040593          	addi	a1,s0,-160
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	154080e7          	jalr	340(ra) # 80002b30 <argstr>
    800059e4:	04054b63          	bltz	a0,80005a3a <sys_chdir+0x86>
    800059e8:	f6040513          	addi	a0,s0,-160
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	552080e7          	jalr	1362(ra) # 80003f3e <namei>
    800059f4:	84aa                	mv	s1,a0
    800059f6:	c131                	beqz	a0,80005a3a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	d9a080e7          	jalr	-614(ra) # 80003792 <ilock>
  if(ip->type != T_DIR){
    80005a00:	04449703          	lh	a4,68(s1)
    80005a04:	4785                	li	a5,1
    80005a06:	04f71063          	bne	a4,a5,80005a46 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	e48080e7          	jalr	-440(ra) # 80003854 <iunlock>
  iput(p->cwd);
    80005a14:	15893503          	ld	a0,344(s2)
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	f34080e7          	jalr	-204(ra) # 8000394c <iput>
  end_op();
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	7bc080e7          	jalr	1980(ra) # 800041dc <end_op>
  p->cwd = ip;
    80005a28:	14993c23          	sd	s1,344(s2)
  return 0;
    80005a2c:	4501                	li	a0,0
}
    80005a2e:	60ea                	ld	ra,152(sp)
    80005a30:	644a                	ld	s0,144(sp)
    80005a32:	64aa                	ld	s1,136(sp)
    80005a34:	690a                	ld	s2,128(sp)
    80005a36:	610d                	addi	sp,sp,160
    80005a38:	8082                	ret
    end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	7a2080e7          	jalr	1954(ra) # 800041dc <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	b7ed                	j	80005a2e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	fac080e7          	jalr	-84(ra) # 800039f4 <iunlockput>
    end_op();
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	78c080e7          	jalr	1932(ra) # 800041dc <end_op>
    return -1;
    80005a58:	557d                	li	a0,-1
    80005a5a:	bfd1                	j	80005a2e <sys_chdir+0x7a>

0000000080005a5c <sys_exec>:

uint64
sys_exec(void)
{
    80005a5c:	7145                	addi	sp,sp,-464
    80005a5e:	e786                	sd	ra,456(sp)
    80005a60:	e3a2                	sd	s0,448(sp)
    80005a62:	ff26                	sd	s1,440(sp)
    80005a64:	fb4a                	sd	s2,432(sp)
    80005a66:	f74e                	sd	s3,424(sp)
    80005a68:	f352                	sd	s4,416(sp)
    80005a6a:	ef56                	sd	s5,408(sp)
    80005a6c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a6e:	e3840593          	addi	a1,s0,-456
    80005a72:	4505                	li	a0,1
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	09c080e7          	jalr	156(ra) # 80002b10 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a7c:	08000613          	li	a2,128
    80005a80:	f4040593          	addi	a1,s0,-192
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	0aa080e7          	jalr	170(ra) # 80002b30 <argstr>
    80005a8e:	87aa                	mv	a5,a0
    return -1;
    80005a90:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a92:	0c07c363          	bltz	a5,80005b58 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a96:	10000613          	li	a2,256
    80005a9a:	4581                	li	a1,0
    80005a9c:	e4040513          	addi	a0,s0,-448
    80005aa0:	ffffb097          	auipc	ra,0xffffb
    80005aa4:	232080e7          	jalr	562(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aa8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aac:	89a6                	mv	s3,s1
    80005aae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab0:	02000a13          	li	s4,32
    80005ab4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ab8:	00391513          	slli	a0,s2,0x3
    80005abc:	e3040593          	addi	a1,s0,-464
    80005ac0:	e3843783          	ld	a5,-456(s0)
    80005ac4:	953e                	add	a0,a0,a5
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	f8c080e7          	jalr	-116(ra) # 80002a52 <fetchaddr>
    80005ace:	02054a63          	bltz	a0,80005b02 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ad2:	e3043783          	ld	a5,-464(s0)
    80005ad6:	c3b9                	beqz	a5,80005b1c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ad8:	ffffb097          	auipc	ra,0xffffb
    80005adc:	00e080e7          	jalr	14(ra) # 80000ae6 <kalloc>
    80005ae0:	85aa                	mv	a1,a0
    80005ae2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ae6:	cd11                	beqz	a0,80005b02 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ae8:	6605                	lui	a2,0x1
    80005aea:	e3043503          	ld	a0,-464(s0)
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	fb6080e7          	jalr	-74(ra) # 80002aa4 <fetchstr>
    80005af6:	00054663          	bltz	a0,80005b02 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005afa:	0905                	addi	s2,s2,1
    80005afc:	09a1                	addi	s3,s3,8
    80005afe:	fb491be3          	bne	s2,s4,80005ab4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b02:	f4040913          	addi	s2,s0,-192
    80005b06:	6088                	ld	a0,0(s1)
    80005b08:	c539                	beqz	a0,80005b56 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b0a:	ffffb097          	auipc	ra,0xffffb
    80005b0e:	ede080e7          	jalr	-290(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b12:	04a1                	addi	s1,s1,8
    80005b14:	ff2499e3          	bne	s1,s2,80005b06 <sys_exec+0xaa>
  return -1;
    80005b18:	557d                	li	a0,-1
    80005b1a:	a83d                	j	80005b58 <sys_exec+0xfc>
      argv[i] = 0;
    80005b1c:	0a8e                	slli	s5,s5,0x3
    80005b1e:	fc0a8793          	addi	a5,s5,-64
    80005b22:	00878ab3          	add	s5,a5,s0
    80005b26:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2a:	e4040593          	addi	a1,s0,-448
    80005b2e:	f4040513          	addi	a0,s0,-192
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	16e080e7          	jalr	366(ra) # 80004ca0 <exec>
    80005b3a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3c:	f4040993          	addi	s3,s0,-192
    80005b40:	6088                	ld	a0,0(s1)
    80005b42:	c901                	beqz	a0,80005b52 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b44:	ffffb097          	auipc	ra,0xffffb
    80005b48:	ea4080e7          	jalr	-348(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4c:	04a1                	addi	s1,s1,8
    80005b4e:	ff3499e3          	bne	s1,s3,80005b40 <sys_exec+0xe4>
  return ret;
    80005b52:	854a                	mv	a0,s2
    80005b54:	a011                	j	80005b58 <sys_exec+0xfc>
  return -1;
    80005b56:	557d                	li	a0,-1
}
    80005b58:	60be                	ld	ra,456(sp)
    80005b5a:	641e                	ld	s0,448(sp)
    80005b5c:	74fa                	ld	s1,440(sp)
    80005b5e:	795a                	ld	s2,432(sp)
    80005b60:	79ba                	ld	s3,424(sp)
    80005b62:	7a1a                	ld	s4,416(sp)
    80005b64:	6afa                	ld	s5,408(sp)
    80005b66:	6179                	addi	sp,sp,464
    80005b68:	8082                	ret

0000000080005b6a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6a:	7139                	addi	sp,sp,-64
    80005b6c:	fc06                	sd	ra,56(sp)
    80005b6e:	f822                	sd	s0,48(sp)
    80005b70:	f426                	sd	s1,40(sp)
    80005b72:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b74:	ffffc097          	auipc	ra,0xffffc
    80005b78:	e38080e7          	jalr	-456(ra) # 800019ac <myproc>
    80005b7c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b7e:	fd840593          	addi	a1,s0,-40
    80005b82:	4501                	li	a0,0
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	f8c080e7          	jalr	-116(ra) # 80002b10 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b8c:	fc840593          	addi	a1,s0,-56
    80005b90:	fd040513          	addi	a0,s0,-48
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	dc2080e7          	jalr	-574(ra) # 80004956 <pipealloc>
    return -1;
    80005b9c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b9e:	0c054463          	bltz	a0,80005c66 <sys_pipe+0xfc>
  fd0 = -1;
    80005ba2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ba6:	fd043503          	ld	a0,-48(s0)
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	514080e7          	jalr	1300(ra) # 800050be <fdalloc>
    80005bb2:	fca42223          	sw	a0,-60(s0)
    80005bb6:	08054b63          	bltz	a0,80005c4c <sys_pipe+0xe2>
    80005bba:	fc843503          	ld	a0,-56(s0)
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	500080e7          	jalr	1280(ra) # 800050be <fdalloc>
    80005bc6:	fca42023          	sw	a0,-64(s0)
    80005bca:	06054863          	bltz	a0,80005c3a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bce:	4691                	li	a3,4
    80005bd0:	fc440613          	addi	a2,s0,-60
    80005bd4:	fd843583          	ld	a1,-40(s0)
    80005bd8:	6ca8                	ld	a0,88(s1)
    80005bda:	ffffc097          	auipc	ra,0xffffc
    80005bde:	a92080e7          	jalr	-1390(ra) # 8000166c <copyout>
    80005be2:	02054063          	bltz	a0,80005c02 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005be6:	4691                	li	a3,4
    80005be8:	fc040613          	addi	a2,s0,-64
    80005bec:	fd843583          	ld	a1,-40(s0)
    80005bf0:	0591                	addi	a1,a1,4
    80005bf2:	6ca8                	ld	a0,88(s1)
    80005bf4:	ffffc097          	auipc	ra,0xffffc
    80005bf8:	a78080e7          	jalr	-1416(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bfc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bfe:	06055463          	bgez	a0,80005c66 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c02:	fc442783          	lw	a5,-60(s0)
    80005c06:	07e9                	addi	a5,a5,26
    80005c08:	078e                	slli	a5,a5,0x3
    80005c0a:	97a6                	add	a5,a5,s1
    80005c0c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005c10:	fc042783          	lw	a5,-64(s0)
    80005c14:	07e9                	addi	a5,a5,26
    80005c16:	078e                	slli	a5,a5,0x3
    80005c18:	94be                	add	s1,s1,a5
    80005c1a:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005c1e:	fd043503          	ld	a0,-48(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	a04080e7          	jalr	-1532(ra) # 80004626 <fileclose>
    fileclose(wf);
    80005c2a:	fc843503          	ld	a0,-56(s0)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	9f8080e7          	jalr	-1544(ra) # 80004626 <fileclose>
    return -1;
    80005c36:	57fd                	li	a5,-1
    80005c38:	a03d                	j	80005c66 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c3a:	fc442783          	lw	a5,-60(s0)
    80005c3e:	0007c763          	bltz	a5,80005c4c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c42:	07e9                	addi	a5,a5,26
    80005c44:	078e                	slli	a5,a5,0x3
    80005c46:	97a6                	add	a5,a5,s1
    80005c48:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005c4c:	fd043503          	ld	a0,-48(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	9d6080e7          	jalr	-1578(ra) # 80004626 <fileclose>
    fileclose(wf);
    80005c58:	fc843503          	ld	a0,-56(s0)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	9ca080e7          	jalr	-1590(ra) # 80004626 <fileclose>
    return -1;
    80005c64:	57fd                	li	a5,-1
}
    80005c66:	853e                	mv	a0,a5
    80005c68:	70e2                	ld	ra,56(sp)
    80005c6a:	7442                	ld	s0,48(sp)
    80005c6c:	74a2                	ld	s1,40(sp)
    80005c6e:	6121                	addi	sp,sp,64
    80005c70:	8082                	ret
	...

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	c5ffc0ef          	jal	ra,8000291e <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c28080e7          	jalr	-984(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	97aa                	add	a5,a5,a0
    80005d7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	bf0080e7          	jalr	-1040(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5151b          	slliw	a0,a0,0xd
    80005d9c:	0c2017b7          	lui	a5,0xc201
    80005da0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005da2:	43c8                	lw	a0,4(a5)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bc8080e7          	jalr	-1080(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	04a7cc63          	blt	a5,a0,80005e38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001c797          	auipc	a5,0x1c
    80005de8:	48c78793          	addi	a5,a5,1164 # 80022270 <disk>
    80005dec:	97aa                	add	a5,a5,a0
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	ebb9                	bnez	a5,80005e48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005df4:	00451693          	slli	a3,a0,0x4
    80005df8:	0001c797          	auipc	a5,0x1c
    80005dfc:	47878793          	addi	a5,a5,1144 # 80022270 <disk>
    80005e00:	6398                	ld	a4,0(a5)
    80005e02:	9736                	add	a4,a4,a3
    80005e04:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e08:	6398                	ld	a4,0(a5)
    80005e0a:	9736                	add	a4,a4,a3
    80005e0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	4705                	li	a4,1
    80005e1c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e20:	0001c517          	auipc	a0,0x1c
    80005e24:	46850513          	addi	a0,a0,1128 # 80022288 <disk+0x18>
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	29c080e7          	jalr	668(ra) # 800020c4 <wakeup>
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret
    panic("free_desc 1");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	9e850513          	addi	a0,a0,-1560 # 80008820 <syscalls+0x2f0>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	700080e7          	jalr	1792(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	9e850513          	addi	a0,a0,-1560 # 80008830 <syscalls+0x300>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>

0000000080005e58 <virtio_disk_init>:
{
    80005e58:	1101                	addi	sp,sp,-32
    80005e5a:	ec06                	sd	ra,24(sp)
    80005e5c:	e822                	sd	s0,16(sp)
    80005e5e:	e426                	sd	s1,8(sp)
    80005e60:	e04a                	sd	s2,0(sp)
    80005e62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e64:	00003597          	auipc	a1,0x3
    80005e68:	9dc58593          	addi	a1,a1,-1572 # 80008840 <syscalls+0x310>
    80005e6c:	0001c517          	auipc	a0,0x1c
    80005e70:	52c50513          	addi	a0,a0,1324 # 80022398 <disk+0x128>
    80005e74:	ffffb097          	auipc	ra,0xffffb
    80005e78:	cd2080e7          	jalr	-814(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	4398                	lw	a4,0(a5)
    80005e82:	2701                	sext.w	a4,a4
    80005e84:	747277b7          	lui	a5,0x74727
    80005e88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e8c:	14f71b63          	bne	a4,a5,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	43dc                	lw	a5,4(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e98:	4709                	li	a4,2
    80005e9a:	14e79463          	bne	a5,a4,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	479c                	lw	a5,8(a5)
    80005ea4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea6:	12e79e63          	bne	a5,a4,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eaa:	100017b7          	lui	a5,0x10001
    80005eae:	47d8                	lw	a4,12(a5)
    80005eb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb2:	554d47b7          	lui	a5,0x554d4
    80005eb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eba:	12f71463          	bne	a4,a5,80005fe2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec6:	4705                	li	a4,1
    80005ec8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	470d                	li	a4,3
    80005ecc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ece:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ed4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3af>
    80005ed8:	8f75                	and	a4,a4,a3
    80005eda:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005edc:	472d                	li	a4,11
    80005ede:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ee0:	5bbc                	lw	a5,112(a5)
    80005ee2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ee6:	8ba1                	andi	a5,a5,8
    80005ee8:	10078563          	beqz	a5,80005ff2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ef4:	43fc                	lw	a5,68(a5)
    80005ef6:	2781                	sext.w	a5,a5
    80005ef8:	10079563          	bnez	a5,80006002 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	5bdc                	lw	a5,52(a5)
    80005f02:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f04:	10078763          	beqz	a5,80006012 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f08:	471d                	li	a4,7
    80005f0a:	10f77c63          	bgeu	a4,a5,80006022 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	bd8080e7          	jalr	-1064(ra) # 80000ae6 <kalloc>
    80005f16:	0001c497          	auipc	s1,0x1c
    80005f1a:	35a48493          	addi	s1,s1,858 # 80022270 <disk>
    80005f1e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	bc6080e7          	jalr	-1082(ra) # 80000ae6 <kalloc>
    80005f28:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	bbc080e7          	jalr	-1092(ra) # 80000ae6 <kalloc>
    80005f32:	87aa                	mv	a5,a0
    80005f34:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f36:	6088                	ld	a0,0(s1)
    80005f38:	cd6d                	beqz	a0,80006032 <virtio_disk_init+0x1da>
    80005f3a:	0001c717          	auipc	a4,0x1c
    80005f3e:	33e73703          	ld	a4,830(a4) # 80022278 <disk+0x8>
    80005f42:	cb65                	beqz	a4,80006032 <virtio_disk_init+0x1da>
    80005f44:	c7fd                	beqz	a5,80006032 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f46:	6605                	lui	a2,0x1
    80005f48:	4581                	li	a1,0
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	d88080e7          	jalr	-632(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f52:	0001c497          	auipc	s1,0x1c
    80005f56:	31e48493          	addi	s1,s1,798 # 80022270 <disk>
    80005f5a:	6605                	lui	a2,0x1
    80005f5c:	4581                	li	a1,0
    80005f5e:	6488                	ld	a0,8(s1)
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	d72080e7          	jalr	-654(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f68:	6605                	lui	a2,0x1
    80005f6a:	4581                	li	a1,0
    80005f6c:	6888                	ld	a0,16(s1)
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	d64080e7          	jalr	-668(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f76:	100017b7          	lui	a5,0x10001
    80005f7a:	4721                	li	a4,8
    80005f7c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f7e:	4098                	lw	a4,0(s1)
    80005f80:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f84:	40d8                	lw	a4,4(s1)
    80005f86:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f8a:	6498                	ld	a4,8(s1)
    80005f8c:	0007069b          	sext.w	a3,a4
    80005f90:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f94:	9701                	srai	a4,a4,0x20
    80005f96:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f9a:	6898                	ld	a4,16(s1)
    80005f9c:	0007069b          	sext.w	a3,a4
    80005fa0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fa4:	9701                	srai	a4,a4,0x20
    80005fa6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005faa:	4705                	li	a4,1
    80005fac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fae:	00e48c23          	sb	a4,24(s1)
    80005fb2:	00e48ca3          	sb	a4,25(s1)
    80005fb6:	00e48d23          	sb	a4,26(s1)
    80005fba:	00e48da3          	sb	a4,27(s1)
    80005fbe:	00e48e23          	sb	a4,28(s1)
    80005fc2:	00e48ea3          	sb	a4,29(s1)
    80005fc6:	00e48f23          	sb	a4,30(s1)
    80005fca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd2:	0727a823          	sw	s2,112(a5)
}
    80005fd6:	60e2                	ld	ra,24(sp)
    80005fd8:	6442                	ld	s0,16(sp)
    80005fda:	64a2                	ld	s1,8(sp)
    80005fdc:	6902                	ld	s2,0(sp)
    80005fde:	6105                	addi	sp,sp,32
    80005fe0:	8082                	ret
    panic("could not find virtio disk");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	86e50513          	addi	a0,a0,-1938 # 80008850 <syscalls+0x320>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	87e50513          	addi	a0,a0,-1922 # 80008870 <syscalls+0x340>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	88e50513          	addi	a0,a0,-1906 # 80008890 <syscalls+0x360>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	89e50513          	addi	a0,a0,-1890 # 800088b0 <syscalls+0x380>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	8ae50513          	addi	a0,a0,-1874 # 800088d0 <syscalls+0x3a0>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006032:	00003517          	auipc	a0,0x3
    80006036:	8be50513          	addi	a0,a0,-1858 # 800088f0 <syscalls+0x3c0>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	506080e7          	jalr	1286(ra) # 80000540 <panic>

0000000080006042 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006042:	7119                	addi	sp,sp,-128
    80006044:	fc86                	sd	ra,120(sp)
    80006046:	f8a2                	sd	s0,112(sp)
    80006048:	f4a6                	sd	s1,104(sp)
    8000604a:	f0ca                	sd	s2,96(sp)
    8000604c:	ecce                	sd	s3,88(sp)
    8000604e:	e8d2                	sd	s4,80(sp)
    80006050:	e4d6                	sd	s5,72(sp)
    80006052:	e0da                	sd	s6,64(sp)
    80006054:	fc5e                	sd	s7,56(sp)
    80006056:	f862                	sd	s8,48(sp)
    80006058:	f466                	sd	s9,40(sp)
    8000605a:	f06a                	sd	s10,32(sp)
    8000605c:	ec6e                	sd	s11,24(sp)
    8000605e:	0100                	addi	s0,sp,128
    80006060:	8aaa                	mv	s5,a0
    80006062:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006064:	00c52d03          	lw	s10,12(a0)
    80006068:	001d1d1b          	slliw	s10,s10,0x1
    8000606c:	1d02                	slli	s10,s10,0x20
    8000606e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006072:	0001c517          	auipc	a0,0x1c
    80006076:	32650513          	addi	a0,a0,806 # 80022398 <disk+0x128>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	b5c080e7          	jalr	-1188(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006082:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006084:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006086:	0001cb97          	auipc	s7,0x1c
    8000608a:	1eab8b93          	addi	s7,s7,490 # 80022270 <disk>
  for(int i = 0; i < 3; i++){
    8000608e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006090:	0001cc97          	auipc	s9,0x1c
    80006094:	308c8c93          	addi	s9,s9,776 # 80022398 <disk+0x128>
    80006098:	a08d                	j	800060fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000609a:	00fb8733          	add	a4,s7,a5
    8000609e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060a4:	0207c563          	bltz	a5,800060ce <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060a8:	2905                	addiw	s2,s2,1
    800060aa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800060ac:	05690c63          	beq	s2,s6,80006104 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060b2:	0001c717          	auipc	a4,0x1c
    800060b6:	1be70713          	addi	a4,a4,446 # 80022270 <disk>
    800060ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060bc:	01874683          	lbu	a3,24(a4)
    800060c0:	fee9                	bnez	a3,8000609a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	0705                	addi	a4,a4,1
    800060c6:	fe979be3          	bne	a5,s1,800060bc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060ca:	57fd                	li	a5,-1
    800060cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ce:	01205d63          	blez	s2,800060e8 <virtio_disk_rw+0xa6>
    800060d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060d4:	000a2503          	lw	a0,0(s4)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	cfe080e7          	jalr	-770(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	2d85                	addiw	s11,s11,1
    800060e2:	0a11                	addi	s4,s4,4
    800060e4:	ff2d98e3          	bne	s11,s2,800060d4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060e8:	85e6                	mv	a1,s9
    800060ea:	0001c517          	auipc	a0,0x1c
    800060ee:	19e50513          	addi	a0,a0,414 # 80022288 <disk+0x18>
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	f6e080e7          	jalr	-146(ra) # 80002060 <sleep>
  for(int i = 0; i < 3; i++){
    800060fa:	f8040a13          	addi	s4,s0,-128
{
    800060fe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006100:	894e                	mv	s2,s3
    80006102:	b77d                	j	800060b0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006104:	f8042503          	lw	a0,-128(s0)
    80006108:	00a50713          	addi	a4,a0,10
    8000610c:	0712                	slli	a4,a4,0x4

  if(write)
    8000610e:	0001c797          	auipc	a5,0x1c
    80006112:	16278793          	addi	a5,a5,354 # 80022270 <disk>
    80006116:	00e786b3          	add	a3,a5,a4
    8000611a:	01803633          	snez	a2,s8
    8000611e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006120:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006124:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006128:	f6070613          	addi	a2,a4,-160
    8000612c:	6394                	ld	a3,0(a5)
    8000612e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006130:	00870593          	addi	a1,a4,8
    80006134:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006136:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006138:	0007b803          	ld	a6,0(a5)
    8000613c:	9642                	add	a2,a2,a6
    8000613e:	46c1                	li	a3,16
    80006140:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006142:	4585                	li	a1,1
    80006144:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006148:	f8442683          	lw	a3,-124(s0)
    8000614c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006150:	0692                	slli	a3,a3,0x4
    80006152:	9836                	add	a6,a6,a3
    80006154:	058a8613          	addi	a2,s5,88
    80006158:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000615c:	0007b803          	ld	a6,0(a5)
    80006160:	96c2                	add	a3,a3,a6
    80006162:	40000613          	li	a2,1024
    80006166:	c690                	sw	a2,8(a3)
  if(write)
    80006168:	001c3613          	seqz	a2,s8
    8000616c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006170:	00166613          	ori	a2,a2,1
    80006174:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006178:	f8842603          	lw	a2,-120(s0)
    8000617c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006180:	00250693          	addi	a3,a0,2
    80006184:	0692                	slli	a3,a3,0x4
    80006186:	96be                	add	a3,a3,a5
    80006188:	58fd                	li	a7,-1
    8000618a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000618e:	0612                	slli	a2,a2,0x4
    80006190:	9832                	add	a6,a6,a2
    80006192:	f9070713          	addi	a4,a4,-112
    80006196:	973e                	add	a4,a4,a5
    80006198:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000619c:	6398                	ld	a4,0(a5)
    8000619e:	9732                	add	a4,a4,a2
    800061a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061a2:	4609                	li	a2,2
    800061a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ac:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061b0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061b4:	6794                	ld	a3,8(a5)
    800061b6:	0026d703          	lhu	a4,2(a3)
    800061ba:	8b1d                	andi	a4,a4,7
    800061bc:	0706                	slli	a4,a4,0x1
    800061be:	96ba                	add	a3,a3,a4
    800061c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061c8:	6798                	ld	a4,8(a5)
    800061ca:	00275783          	lhu	a5,2(a4)
    800061ce:	2785                	addiw	a5,a5,1
    800061d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061d8:	100017b7          	lui	a5,0x10001
    800061dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061e0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061e4:	0001c917          	auipc	s2,0x1c
    800061e8:	1b490913          	addi	s2,s2,436 # 80022398 <disk+0x128>
  while(b->disk == 1) {
    800061ec:	4485                	li	s1,1
    800061ee:	00b79c63          	bne	a5,a1,80006206 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061f2:	85ca                	mv	a1,s2
    800061f4:	8556                	mv	a0,s5
    800061f6:	ffffc097          	auipc	ra,0xffffc
    800061fa:	e6a080e7          	jalr	-406(ra) # 80002060 <sleep>
  while(b->disk == 1) {
    800061fe:	004aa783          	lw	a5,4(s5)
    80006202:	fe9788e3          	beq	a5,s1,800061f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006206:	f8042903          	lw	s2,-128(s0)
    8000620a:	00290713          	addi	a4,s2,2
    8000620e:	0712                	slli	a4,a4,0x4
    80006210:	0001c797          	auipc	a5,0x1c
    80006214:	06078793          	addi	a5,a5,96 # 80022270 <disk>
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000621e:	0001c997          	auipc	s3,0x1c
    80006222:	05298993          	addi	s3,s3,82 # 80022270 <disk>
    80006226:	00491713          	slli	a4,s2,0x4
    8000622a:	0009b783          	ld	a5,0(s3)
    8000622e:	97ba                	add	a5,a5,a4
    80006230:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006234:	854a                	mv	a0,s2
    80006236:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000623a:	00000097          	auipc	ra,0x0
    8000623e:	b9c080e7          	jalr	-1124(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006242:	8885                	andi	s1,s1,1
    80006244:	f0ed                	bnez	s1,80006226 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006246:	0001c517          	auipc	a0,0x1c
    8000624a:	15250513          	addi	a0,a0,338 # 80022398 <disk+0x128>
    8000624e:	ffffb097          	auipc	ra,0xffffb
    80006252:	a3c080e7          	jalr	-1476(ra) # 80000c8a <release>
}
    80006256:	70e6                	ld	ra,120(sp)
    80006258:	7446                	ld	s0,112(sp)
    8000625a:	74a6                	ld	s1,104(sp)
    8000625c:	7906                	ld	s2,96(sp)
    8000625e:	69e6                	ld	s3,88(sp)
    80006260:	6a46                	ld	s4,80(sp)
    80006262:	6aa6                	ld	s5,72(sp)
    80006264:	6b06                	ld	s6,64(sp)
    80006266:	7be2                	ld	s7,56(sp)
    80006268:	7c42                	ld	s8,48(sp)
    8000626a:	7ca2                	ld	s9,40(sp)
    8000626c:	7d02                	ld	s10,32(sp)
    8000626e:	6de2                	ld	s11,24(sp)
    80006270:	6109                	addi	sp,sp,128
    80006272:	8082                	ret

0000000080006274 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006274:	1101                	addi	sp,sp,-32
    80006276:	ec06                	sd	ra,24(sp)
    80006278:	e822                	sd	s0,16(sp)
    8000627a:	e426                	sd	s1,8(sp)
    8000627c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000627e:	0001c497          	auipc	s1,0x1c
    80006282:	ff248493          	addi	s1,s1,-14 # 80022270 <disk>
    80006286:	0001c517          	auipc	a0,0x1c
    8000628a:	11250513          	addi	a0,a0,274 # 80022398 <disk+0x128>
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	948080e7          	jalr	-1720(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006296:	10001737          	lui	a4,0x10001
    8000629a:	533c                	lw	a5,96(a4)
    8000629c:	8b8d                	andi	a5,a5,3
    8000629e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a4:	689c                	ld	a5,16(s1)
    800062a6:	0204d703          	lhu	a4,32(s1)
    800062aa:	0027d783          	lhu	a5,2(a5)
    800062ae:	04f70863          	beq	a4,a5,800062fe <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062b6:	6898                	ld	a4,16(s1)
    800062b8:	0204d783          	lhu	a5,32(s1)
    800062bc:	8b9d                	andi	a5,a5,7
    800062be:	078e                	slli	a5,a5,0x3
    800062c0:	97ba                	add	a5,a5,a4
    800062c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062c4:	00278713          	addi	a4,a5,2
    800062c8:	0712                	slli	a4,a4,0x4
    800062ca:	9726                	add	a4,a4,s1
    800062cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062d0:	e721                	bnez	a4,80006318 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062d2:	0789                	addi	a5,a5,2
    800062d4:	0792                	slli	a5,a5,0x4
    800062d6:	97a6                	add	a5,a5,s1
    800062d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062de:	ffffc097          	auipc	ra,0xffffc
    800062e2:	de6080e7          	jalr	-538(ra) # 800020c4 <wakeup>

    disk.used_idx += 1;
    800062e6:	0204d783          	lhu	a5,32(s1)
    800062ea:	2785                	addiw	a5,a5,1
    800062ec:	17c2                	slli	a5,a5,0x30
    800062ee:	93c1                	srli	a5,a5,0x30
    800062f0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062f4:	6898                	ld	a4,16(s1)
    800062f6:	00275703          	lhu	a4,2(a4)
    800062fa:	faf71ce3          	bne	a4,a5,800062b2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062fe:	0001c517          	auipc	a0,0x1c
    80006302:	09a50513          	addi	a0,a0,154 # 80022398 <disk+0x128>
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	984080e7          	jalr	-1660(ra) # 80000c8a <release>
}
    8000630e:	60e2                	ld	ra,24(sp)
    80006310:	6442                	ld	s0,16(sp)
    80006312:	64a2                	ld	s1,8(sp)
    80006314:	6105                	addi	sp,sp,32
    80006316:	8082                	ret
      panic("virtio_disk_intr status");
    80006318:	00002517          	auipc	a0,0x2
    8000631c:	5f050513          	addi	a0,a0,1520 # 80008908 <syscalls+0x3d8>
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	220080e7          	jalr	544(ra) # 80000540 <panic>
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
