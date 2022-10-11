
user/_settickets:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    if (argc < 2)
   8:	4785                	li	a5,1
   a:	02a7d363          	bge	a5,a0,30 <main+0x30>
    {
        fprintf(2, "settickets: insufficient arguments passed\n");
        exit(1);
    }
    else if (argc > 2)
   e:	4789                	li	a5,2
  10:	02a7de63          	bge	a5,a0,4c <main+0x4c>
    {
        fprintf(2, "settickets: too many arguments passed\n");
  14:	00001597          	auipc	a1,0x1
  18:	86c58593          	addi	a1,a1,-1940 # 880 <malloc+0x11a>
  1c:	4509                	li	a0,2
  1e:	00000097          	auipc	ra,0x0
  22:	662080e7          	jalr	1634(ra) # 680 <fprintf>
        exit(1);
  26:	4505                	li	a0,1
  28:	00000097          	auipc	ra,0x0
  2c:	2e4080e7          	jalr	740(ra) # 30c <exit>
        fprintf(2, "settickets: insufficient arguments passed\n");
  30:	00001597          	auipc	a1,0x1
  34:	82058593          	addi	a1,a1,-2016 # 850 <malloc+0xea>
  38:	4509                	li	a0,2
  3a:	00000097          	auipc	ra,0x0
  3e:	646080e7          	jalr	1606(ra) # 680 <fprintf>
        exit(1);
  42:	4505                	li	a0,1
  44:	00000097          	auipc	ra,0x0
  48:	2c8080e7          	jalr	712(ra) # 30c <exit>
    }

    int numTickets = atoi(argv[1]);
  4c:	6588                	ld	a0,8(a1)
  4e:	00000097          	auipc	ra,0x0
  52:	1c4080e7          	jalr	452(ra) # 212 <atoi>
    int retval = settickets(numTickets);
  56:	00000097          	auipc	ra,0x0
  5a:	35e080e7          	jalr	862(ra) # 3b4 <settickets>
    if (retval)
  5e:	cd19                	beqz	a0,7c <main+0x7c>
    {
        fprintf(2, "settickets: system error. Try again\n");
  60:	00001597          	auipc	a1,0x1
  64:	84858593          	addi	a1,a1,-1976 # 8a8 <malloc+0x142>
  68:	4509                	li	a0,2
  6a:	00000097          	auipc	ra,0x0
  6e:	616080e7          	jalr	1558(ra) # 680 <fprintf>
        exit(1);
  72:	4505                	li	a0,1
  74:	00000097          	auipc	ra,0x0
  78:	298080e7          	jalr	664(ra) # 30c <exit>
    }
    exit(0);
  7c:	4501                	li	a0,0
  7e:	00000097          	auipc	ra,0x0
  82:	28e080e7          	jalr	654(ra) # 30c <exit>

0000000000000086 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  86:	1141                	addi	sp,sp,-16
  88:	e406                	sd	ra,8(sp)
  8a:	e022                	sd	s0,0(sp)
  8c:	0800                	addi	s0,sp,16
  extern int main();
  main();
  8e:	00000097          	auipc	ra,0x0
  92:	f72080e7          	jalr	-142(ra) # 0 <main>
  exit(0);
  96:	4501                	li	a0,0
  98:	00000097          	auipc	ra,0x0
  9c:	274080e7          	jalr	628(ra) # 30c <exit>

00000000000000a0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  a0:	1141                	addi	sp,sp,-16
  a2:	e422                	sd	s0,8(sp)
  a4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a6:	87aa                	mv	a5,a0
  a8:	0585                	addi	a1,a1,1
  aa:	0785                	addi	a5,a5,1
  ac:	fff5c703          	lbu	a4,-1(a1)
  b0:	fee78fa3          	sb	a4,-1(a5)
  b4:	fb75                	bnez	a4,a8 <strcpy+0x8>
    ;
  return os;
}
  b6:	6422                	ld	s0,8(sp)
  b8:	0141                	addi	sp,sp,16
  ba:	8082                	ret

00000000000000bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  bc:	1141                	addi	sp,sp,-16
  be:	e422                	sd	s0,8(sp)
  c0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  c2:	00054783          	lbu	a5,0(a0)
  c6:	cb91                	beqz	a5,da <strcmp+0x1e>
  c8:	0005c703          	lbu	a4,0(a1)
  cc:	00f71763          	bne	a4,a5,da <strcmp+0x1e>
    p++, q++;
  d0:	0505                	addi	a0,a0,1
  d2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  d4:	00054783          	lbu	a5,0(a0)
  d8:	fbe5                	bnez	a5,c8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  da:	0005c503          	lbu	a0,0(a1)
}
  de:	40a7853b          	subw	a0,a5,a0
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	addi	sp,sp,16
  e6:	8082                	ret

00000000000000e8 <strlen>:

uint
strlen(const char *s)
{
  e8:	1141                	addi	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ee:	00054783          	lbu	a5,0(a0)
  f2:	cf91                	beqz	a5,10e <strlen+0x26>
  f4:	0505                	addi	a0,a0,1
  f6:	87aa                	mv	a5,a0
  f8:	4685                	li	a3,1
  fa:	9e89                	subw	a3,a3,a0
  fc:	00f6853b          	addw	a0,a3,a5
 100:	0785                	addi	a5,a5,1
 102:	fff7c703          	lbu	a4,-1(a5)
 106:	fb7d                	bnez	a4,fc <strlen+0x14>
    ;
  return n;
}
 108:	6422                	ld	s0,8(sp)
 10a:	0141                	addi	sp,sp,16
 10c:	8082                	ret
  for(n = 0; s[n]; n++)
 10e:	4501                	li	a0,0
 110:	bfe5                	j	108 <strlen+0x20>

0000000000000112 <memset>:

void*
memset(void *dst, int c, uint n)
{
 112:	1141                	addi	sp,sp,-16
 114:	e422                	sd	s0,8(sp)
 116:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 118:	ca19                	beqz	a2,12e <memset+0x1c>
 11a:	87aa                	mv	a5,a0
 11c:	1602                	slli	a2,a2,0x20
 11e:	9201                	srli	a2,a2,0x20
 120:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 124:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 128:	0785                	addi	a5,a5,1
 12a:	fee79de3          	bne	a5,a4,124 <memset+0x12>
  }
  return dst;
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret

0000000000000134 <strchr>:

char*
strchr(const char *s, char c)
{
 134:	1141                	addi	sp,sp,-16
 136:	e422                	sd	s0,8(sp)
 138:	0800                	addi	s0,sp,16
  for(; *s; s++)
 13a:	00054783          	lbu	a5,0(a0)
 13e:	cb99                	beqz	a5,154 <strchr+0x20>
    if(*s == c)
 140:	00f58763          	beq	a1,a5,14e <strchr+0x1a>
  for(; *s; s++)
 144:	0505                	addi	a0,a0,1
 146:	00054783          	lbu	a5,0(a0)
 14a:	fbfd                	bnez	a5,140 <strchr+0xc>
      return (char*)s;
  return 0;
 14c:	4501                	li	a0,0
}
 14e:	6422                	ld	s0,8(sp)
 150:	0141                	addi	sp,sp,16
 152:	8082                	ret
  return 0;
 154:	4501                	li	a0,0
 156:	bfe5                	j	14e <strchr+0x1a>

0000000000000158 <gets>:

char*
gets(char *buf, int max)
{
 158:	711d                	addi	sp,sp,-96
 15a:	ec86                	sd	ra,88(sp)
 15c:	e8a2                	sd	s0,80(sp)
 15e:	e4a6                	sd	s1,72(sp)
 160:	e0ca                	sd	s2,64(sp)
 162:	fc4e                	sd	s3,56(sp)
 164:	f852                	sd	s4,48(sp)
 166:	f456                	sd	s5,40(sp)
 168:	f05a                	sd	s6,32(sp)
 16a:	ec5e                	sd	s7,24(sp)
 16c:	1080                	addi	s0,sp,96
 16e:	8baa                	mv	s7,a0
 170:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 172:	892a                	mv	s2,a0
 174:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 176:	4aa9                	li	s5,10
 178:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 17a:	89a6                	mv	s3,s1
 17c:	2485                	addiw	s1,s1,1
 17e:	0344d863          	bge	s1,s4,1ae <gets+0x56>
    cc = read(0, &c, 1);
 182:	4605                	li	a2,1
 184:	faf40593          	addi	a1,s0,-81
 188:	4501                	li	a0,0
 18a:	00000097          	auipc	ra,0x0
 18e:	19a080e7          	jalr	410(ra) # 324 <read>
    if(cc < 1)
 192:	00a05e63          	blez	a0,1ae <gets+0x56>
    buf[i++] = c;
 196:	faf44783          	lbu	a5,-81(s0)
 19a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 19e:	01578763          	beq	a5,s5,1ac <gets+0x54>
 1a2:	0905                	addi	s2,s2,1
 1a4:	fd679be3          	bne	a5,s6,17a <gets+0x22>
  for(i=0; i+1 < max; ){
 1a8:	89a6                	mv	s3,s1
 1aa:	a011                	j	1ae <gets+0x56>
 1ac:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ae:	99de                	add	s3,s3,s7
 1b0:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b4:	855e                	mv	a0,s7
 1b6:	60e6                	ld	ra,88(sp)
 1b8:	6446                	ld	s0,80(sp)
 1ba:	64a6                	ld	s1,72(sp)
 1bc:	6906                	ld	s2,64(sp)
 1be:	79e2                	ld	s3,56(sp)
 1c0:	7a42                	ld	s4,48(sp)
 1c2:	7aa2                	ld	s5,40(sp)
 1c4:	7b02                	ld	s6,32(sp)
 1c6:	6be2                	ld	s7,24(sp)
 1c8:	6125                	addi	sp,sp,96
 1ca:	8082                	ret

00000000000001cc <stat>:

int
stat(const char *n, struct stat *st)
{
 1cc:	1101                	addi	sp,sp,-32
 1ce:	ec06                	sd	ra,24(sp)
 1d0:	e822                	sd	s0,16(sp)
 1d2:	e426                	sd	s1,8(sp)
 1d4:	e04a                	sd	s2,0(sp)
 1d6:	1000                	addi	s0,sp,32
 1d8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1da:	4581                	li	a1,0
 1dc:	00000097          	auipc	ra,0x0
 1e0:	170080e7          	jalr	368(ra) # 34c <open>
  if(fd < 0)
 1e4:	02054563          	bltz	a0,20e <stat+0x42>
 1e8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ea:	85ca                	mv	a1,s2
 1ec:	00000097          	auipc	ra,0x0
 1f0:	178080e7          	jalr	376(ra) # 364 <fstat>
 1f4:	892a                	mv	s2,a0
  close(fd);
 1f6:	8526                	mv	a0,s1
 1f8:	00000097          	auipc	ra,0x0
 1fc:	13c080e7          	jalr	316(ra) # 334 <close>
  return r;
}
 200:	854a                	mv	a0,s2
 202:	60e2                	ld	ra,24(sp)
 204:	6442                	ld	s0,16(sp)
 206:	64a2                	ld	s1,8(sp)
 208:	6902                	ld	s2,0(sp)
 20a:	6105                	addi	sp,sp,32
 20c:	8082                	ret
    return -1;
 20e:	597d                	li	s2,-1
 210:	bfc5                	j	200 <stat+0x34>

0000000000000212 <atoi>:

int
atoi(const char *s)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 218:	00054683          	lbu	a3,0(a0)
 21c:	fd06879b          	addiw	a5,a3,-48
 220:	0ff7f793          	zext.b	a5,a5
 224:	4625                	li	a2,9
 226:	02f66863          	bltu	a2,a5,256 <atoi+0x44>
 22a:	872a                	mv	a4,a0
  n = 0;
 22c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 22e:	0705                	addi	a4,a4,1
 230:	0025179b          	slliw	a5,a0,0x2
 234:	9fa9                	addw	a5,a5,a0
 236:	0017979b          	slliw	a5,a5,0x1
 23a:	9fb5                	addw	a5,a5,a3
 23c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 240:	00074683          	lbu	a3,0(a4)
 244:	fd06879b          	addiw	a5,a3,-48
 248:	0ff7f793          	zext.b	a5,a5
 24c:	fef671e3          	bgeu	a2,a5,22e <atoi+0x1c>
  return n;
}
 250:	6422                	ld	s0,8(sp)
 252:	0141                	addi	sp,sp,16
 254:	8082                	ret
  n = 0;
 256:	4501                	li	a0,0
 258:	bfe5                	j	250 <atoi+0x3e>

000000000000025a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 25a:	1141                	addi	sp,sp,-16
 25c:	e422                	sd	s0,8(sp)
 25e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 260:	02b57463          	bgeu	a0,a1,288 <memmove+0x2e>
    while(n-- > 0)
 264:	00c05f63          	blez	a2,282 <memmove+0x28>
 268:	1602                	slli	a2,a2,0x20
 26a:	9201                	srli	a2,a2,0x20
 26c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 270:	872a                	mv	a4,a0
      *dst++ = *src++;
 272:	0585                	addi	a1,a1,1
 274:	0705                	addi	a4,a4,1
 276:	fff5c683          	lbu	a3,-1(a1)
 27a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 27e:	fee79ae3          	bne	a5,a4,272 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret
    dst += n;
 288:	00c50733          	add	a4,a0,a2
    src += n;
 28c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 28e:	fec05ae3          	blez	a2,282 <memmove+0x28>
 292:	fff6079b          	addiw	a5,a2,-1
 296:	1782                	slli	a5,a5,0x20
 298:	9381                	srli	a5,a5,0x20
 29a:	fff7c793          	not	a5,a5
 29e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2a0:	15fd                	addi	a1,a1,-1
 2a2:	177d                	addi	a4,a4,-1
 2a4:	0005c683          	lbu	a3,0(a1)
 2a8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ac:	fee79ae3          	bne	a5,a4,2a0 <memmove+0x46>
 2b0:	bfc9                	j	282 <memmove+0x28>

00000000000002b2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b2:	1141                	addi	sp,sp,-16
 2b4:	e422                	sd	s0,8(sp)
 2b6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2b8:	ca05                	beqz	a2,2e8 <memcmp+0x36>
 2ba:	fff6069b          	addiw	a3,a2,-1
 2be:	1682                	slli	a3,a3,0x20
 2c0:	9281                	srli	a3,a3,0x20
 2c2:	0685                	addi	a3,a3,1
 2c4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2c6:	00054783          	lbu	a5,0(a0)
 2ca:	0005c703          	lbu	a4,0(a1)
 2ce:	00e79863          	bne	a5,a4,2de <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d2:	0505                	addi	a0,a0,1
    p2++;
 2d4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2d6:	fed518e3          	bne	a0,a3,2c6 <memcmp+0x14>
  }
  return 0;
 2da:	4501                	li	a0,0
 2dc:	a019                	j	2e2 <memcmp+0x30>
      return *p1 - *p2;
 2de:	40e7853b          	subw	a0,a5,a4
}
 2e2:	6422                	ld	s0,8(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret
  return 0;
 2e8:	4501                	li	a0,0
 2ea:	bfe5                	j	2e2 <memcmp+0x30>

00000000000002ec <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e406                	sd	ra,8(sp)
 2f0:	e022                	sd	s0,0(sp)
 2f2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2f4:	00000097          	auipc	ra,0x0
 2f8:	f66080e7          	jalr	-154(ra) # 25a <memmove>
}
 2fc:	60a2                	ld	ra,8(sp)
 2fe:	6402                	ld	s0,0(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret

0000000000000304 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 304:	4885                	li	a7,1
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <exit>:
.global exit
exit:
 li a7, SYS_exit
 30c:	4889                	li	a7,2
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <wait>:
.global wait
wait:
 li a7, SYS_wait
 314:	488d                	li	a7,3
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31c:	4891                	li	a7,4
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <read>:
.global read
read:
 li a7, SYS_read
 324:	4895                	li	a7,5
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <write>:
.global write
write:
 li a7, SYS_write
 32c:	48c1                	li	a7,16
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <close>:
.global close
close:
 li a7, SYS_close
 334:	48d5                	li	a7,21
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <kill>:
.global kill
kill:
 li a7, SYS_kill
 33c:	4899                	li	a7,6
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <exec>:
.global exec
exec:
 li a7, SYS_exec
 344:	489d                	li	a7,7
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <open>:
.global open
open:
 li a7, SYS_open
 34c:	48bd                	li	a7,15
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 354:	48c5                	li	a7,17
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35c:	48c9                	li	a7,18
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 364:	48a1                	li	a7,8
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <link>:
.global link
link:
 li a7, SYS_link
 36c:	48cd                	li	a7,19
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 374:	48d1                	li	a7,20
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37c:	48a5                	li	a7,9
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <dup>:
.global dup
dup:
 li a7, SYS_dup
 384:	48a9                	li	a7,10
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38c:	48ad                	li	a7,11
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 394:	48b1                	li	a7,12
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 39c:	48b5                	li	a7,13
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a4:	48b9                	li	a7,14
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <strace>:
.global strace
strace:
 li a7, SYS_strace
 3ac:	48d9                	li	a7,22
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 3b4:	48dd                	li	a7,23
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3bc:	48e1                	li	a7,24
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 3c4:	48e9                	li	a7,26
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 3cc:	48e5                	li	a7,25
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d4:	1101                	addi	sp,sp,-32
 3d6:	ec06                	sd	ra,24(sp)
 3d8:	e822                	sd	s0,16(sp)
 3da:	1000                	addi	s0,sp,32
 3dc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e0:	4605                	li	a2,1
 3e2:	fef40593          	addi	a1,s0,-17
 3e6:	00000097          	auipc	ra,0x0
 3ea:	f46080e7          	jalr	-186(ra) # 32c <write>
}
 3ee:	60e2                	ld	ra,24(sp)
 3f0:	6442                	ld	s0,16(sp)
 3f2:	6105                	addi	sp,sp,32
 3f4:	8082                	ret

00000000000003f6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3f6:	7139                	addi	sp,sp,-64
 3f8:	fc06                	sd	ra,56(sp)
 3fa:	f822                	sd	s0,48(sp)
 3fc:	f426                	sd	s1,40(sp)
 3fe:	f04a                	sd	s2,32(sp)
 400:	ec4e                	sd	s3,24(sp)
 402:	0080                	addi	s0,sp,64
 404:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 406:	c299                	beqz	a3,40c <printint+0x16>
 408:	0805c963          	bltz	a1,49a <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 40c:	2581                	sext.w	a1,a1
  neg = 0;
 40e:	4881                	li	a7,0
 410:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 414:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 416:	2601                	sext.w	a2,a2
 418:	00000517          	auipc	a0,0x0
 41c:	51850513          	addi	a0,a0,1304 # 930 <digits>
 420:	883a                	mv	a6,a4
 422:	2705                	addiw	a4,a4,1
 424:	02c5f7bb          	remuw	a5,a1,a2
 428:	1782                	slli	a5,a5,0x20
 42a:	9381                	srli	a5,a5,0x20
 42c:	97aa                	add	a5,a5,a0
 42e:	0007c783          	lbu	a5,0(a5)
 432:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 436:	0005879b          	sext.w	a5,a1
 43a:	02c5d5bb          	divuw	a1,a1,a2
 43e:	0685                	addi	a3,a3,1
 440:	fec7f0e3          	bgeu	a5,a2,420 <printint+0x2a>
  if(neg)
 444:	00088c63          	beqz	a7,45c <printint+0x66>
    buf[i++] = '-';
 448:	fd070793          	addi	a5,a4,-48
 44c:	00878733          	add	a4,a5,s0
 450:	02d00793          	li	a5,45
 454:	fef70823          	sb	a5,-16(a4)
 458:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 45c:	02e05863          	blez	a4,48c <printint+0x96>
 460:	fc040793          	addi	a5,s0,-64
 464:	00e78933          	add	s2,a5,a4
 468:	fff78993          	addi	s3,a5,-1
 46c:	99ba                	add	s3,s3,a4
 46e:	377d                	addiw	a4,a4,-1
 470:	1702                	slli	a4,a4,0x20
 472:	9301                	srli	a4,a4,0x20
 474:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 478:	fff94583          	lbu	a1,-1(s2)
 47c:	8526                	mv	a0,s1
 47e:	00000097          	auipc	ra,0x0
 482:	f56080e7          	jalr	-170(ra) # 3d4 <putc>
  while(--i >= 0)
 486:	197d                	addi	s2,s2,-1
 488:	ff3918e3          	bne	s2,s3,478 <printint+0x82>
}
 48c:	70e2                	ld	ra,56(sp)
 48e:	7442                	ld	s0,48(sp)
 490:	74a2                	ld	s1,40(sp)
 492:	7902                	ld	s2,32(sp)
 494:	69e2                	ld	s3,24(sp)
 496:	6121                	addi	sp,sp,64
 498:	8082                	ret
    x = -xx;
 49a:	40b005bb          	negw	a1,a1
    neg = 1;
 49e:	4885                	li	a7,1
    x = -xx;
 4a0:	bf85                	j	410 <printint+0x1a>

00000000000004a2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a2:	7119                	addi	sp,sp,-128
 4a4:	fc86                	sd	ra,120(sp)
 4a6:	f8a2                	sd	s0,112(sp)
 4a8:	f4a6                	sd	s1,104(sp)
 4aa:	f0ca                	sd	s2,96(sp)
 4ac:	ecce                	sd	s3,88(sp)
 4ae:	e8d2                	sd	s4,80(sp)
 4b0:	e4d6                	sd	s5,72(sp)
 4b2:	e0da                	sd	s6,64(sp)
 4b4:	fc5e                	sd	s7,56(sp)
 4b6:	f862                	sd	s8,48(sp)
 4b8:	f466                	sd	s9,40(sp)
 4ba:	f06a                	sd	s10,32(sp)
 4bc:	ec6e                	sd	s11,24(sp)
 4be:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c0:	0005c903          	lbu	s2,0(a1)
 4c4:	18090f63          	beqz	s2,662 <vprintf+0x1c0>
 4c8:	8aaa                	mv	s5,a0
 4ca:	8b32                	mv	s6,a2
 4cc:	00158493          	addi	s1,a1,1
  state = 0;
 4d0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d2:	02500a13          	li	s4,37
 4d6:	4c55                	li	s8,21
 4d8:	00000c97          	auipc	s9,0x0
 4dc:	400c8c93          	addi	s9,s9,1024 # 8d8 <malloc+0x172>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4e0:	02800d93          	li	s11,40
  putc(fd, 'x');
 4e4:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4e6:	00000b97          	auipc	s7,0x0
 4ea:	44ab8b93          	addi	s7,s7,1098 # 930 <digits>
 4ee:	a839                	j	50c <vprintf+0x6a>
        putc(fd, c);
 4f0:	85ca                	mv	a1,s2
 4f2:	8556                	mv	a0,s5
 4f4:	00000097          	auipc	ra,0x0
 4f8:	ee0080e7          	jalr	-288(ra) # 3d4 <putc>
 4fc:	a019                	j	502 <vprintf+0x60>
    } else if(state == '%'){
 4fe:	01498d63          	beq	s3,s4,518 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 502:	0485                	addi	s1,s1,1
 504:	fff4c903          	lbu	s2,-1(s1)
 508:	14090d63          	beqz	s2,662 <vprintf+0x1c0>
    if(state == 0){
 50c:	fe0999e3          	bnez	s3,4fe <vprintf+0x5c>
      if(c == '%'){
 510:	ff4910e3          	bne	s2,s4,4f0 <vprintf+0x4e>
        state = '%';
 514:	89d2                	mv	s3,s4
 516:	b7f5                	j	502 <vprintf+0x60>
      if(c == 'd'){
 518:	11490c63          	beq	s2,s4,630 <vprintf+0x18e>
 51c:	f9d9079b          	addiw	a5,s2,-99
 520:	0ff7f793          	zext.b	a5,a5
 524:	10fc6e63          	bltu	s8,a5,640 <vprintf+0x19e>
 528:	f9d9079b          	addiw	a5,s2,-99
 52c:	0ff7f713          	zext.b	a4,a5
 530:	10ec6863          	bltu	s8,a4,640 <vprintf+0x19e>
 534:	00271793          	slli	a5,a4,0x2
 538:	97e6                	add	a5,a5,s9
 53a:	439c                	lw	a5,0(a5)
 53c:	97e6                	add	a5,a5,s9
 53e:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 540:	008b0913          	addi	s2,s6,8
 544:	4685                	li	a3,1
 546:	4629                	li	a2,10
 548:	000b2583          	lw	a1,0(s6)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	ea8080e7          	jalr	-344(ra) # 3f6 <printint>
 556:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 558:	4981                	li	s3,0
 55a:	b765                	j	502 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 55c:	008b0913          	addi	s2,s6,8
 560:	4681                	li	a3,0
 562:	4629                	li	a2,10
 564:	000b2583          	lw	a1,0(s6)
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e8c080e7          	jalr	-372(ra) # 3f6 <printint>
 572:	8b4a                	mv	s6,s2
      state = 0;
 574:	4981                	li	s3,0
 576:	b771                	j	502 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 578:	008b0913          	addi	s2,s6,8
 57c:	4681                	li	a3,0
 57e:	866a                	mv	a2,s10
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e70080e7          	jalr	-400(ra) # 3f6 <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	bf85                	j	502 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 594:	008b0793          	addi	a5,s6,8
 598:	f8f43423          	sd	a5,-120(s0)
 59c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a0:	03000593          	li	a1,48
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e2e080e7          	jalr	-466(ra) # 3d4 <putc>
  putc(fd, 'x');
 5ae:	07800593          	li	a1,120
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	e20080e7          	jalr	-480(ra) # 3d4 <putc>
 5bc:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5be:	03c9d793          	srli	a5,s3,0x3c
 5c2:	97de                	add	a5,a5,s7
 5c4:	0007c583          	lbu	a1,0(a5)
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	e0a080e7          	jalr	-502(ra) # 3d4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d2:	0992                	slli	s3,s3,0x4
 5d4:	397d                	addiw	s2,s2,-1
 5d6:	fe0914e3          	bnez	s2,5be <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5da:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5de:	4981                	li	s3,0
 5e0:	b70d                	j	502 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e2:	008b0913          	addi	s2,s6,8
 5e6:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5ea:	02098163          	beqz	s3,60c <vprintf+0x16a>
        while(*s != 0){
 5ee:	0009c583          	lbu	a1,0(s3)
 5f2:	c5ad                	beqz	a1,65c <vprintf+0x1ba>
          putc(fd, *s);
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	dde080e7          	jalr	-546(ra) # 3d4 <putc>
          s++;
 5fe:	0985                	addi	s3,s3,1
        while(*s != 0){
 600:	0009c583          	lbu	a1,0(s3)
 604:	f9e5                	bnez	a1,5f4 <vprintf+0x152>
        s = va_arg(ap, char*);
 606:	8b4a                	mv	s6,s2
      state = 0;
 608:	4981                	li	s3,0
 60a:	bde5                	j	502 <vprintf+0x60>
          s = "(null)";
 60c:	00000997          	auipc	s3,0x0
 610:	2c498993          	addi	s3,s3,708 # 8d0 <malloc+0x16a>
        while(*s != 0){
 614:	85ee                	mv	a1,s11
 616:	bff9                	j	5f4 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 618:	008b0913          	addi	s2,s6,8
 61c:	000b4583          	lbu	a1,0(s6)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	db2080e7          	jalr	-590(ra) # 3d4 <putc>
 62a:	8b4a                	mv	s6,s2
      state = 0;
 62c:	4981                	li	s3,0
 62e:	bdd1                	j	502 <vprintf+0x60>
        putc(fd, c);
 630:	85d2                	mv	a1,s4
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	da0080e7          	jalr	-608(ra) # 3d4 <putc>
      state = 0;
 63c:	4981                	li	s3,0
 63e:	b5d1                	j	502 <vprintf+0x60>
        putc(fd, '%');
 640:	85d2                	mv	a1,s4
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	d90080e7          	jalr	-624(ra) # 3d4 <putc>
        putc(fd, c);
 64c:	85ca                	mv	a1,s2
 64e:	8556                	mv	a0,s5
 650:	00000097          	auipc	ra,0x0
 654:	d84080e7          	jalr	-636(ra) # 3d4 <putc>
      state = 0;
 658:	4981                	li	s3,0
 65a:	b565                	j	502 <vprintf+0x60>
        s = va_arg(ap, char*);
 65c:	8b4a                	mv	s6,s2
      state = 0;
 65e:	4981                	li	s3,0
 660:	b54d                	j	502 <vprintf+0x60>
    }
  }
}
 662:	70e6                	ld	ra,120(sp)
 664:	7446                	ld	s0,112(sp)
 666:	74a6                	ld	s1,104(sp)
 668:	7906                	ld	s2,96(sp)
 66a:	69e6                	ld	s3,88(sp)
 66c:	6a46                	ld	s4,80(sp)
 66e:	6aa6                	ld	s5,72(sp)
 670:	6b06                	ld	s6,64(sp)
 672:	7be2                	ld	s7,56(sp)
 674:	7c42                	ld	s8,48(sp)
 676:	7ca2                	ld	s9,40(sp)
 678:	7d02                	ld	s10,32(sp)
 67a:	6de2                	ld	s11,24(sp)
 67c:	6109                	addi	sp,sp,128
 67e:	8082                	ret

0000000000000680 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 680:	715d                	addi	sp,sp,-80
 682:	ec06                	sd	ra,24(sp)
 684:	e822                	sd	s0,16(sp)
 686:	1000                	addi	s0,sp,32
 688:	e010                	sd	a2,0(s0)
 68a:	e414                	sd	a3,8(s0)
 68c:	e818                	sd	a4,16(s0)
 68e:	ec1c                	sd	a5,24(s0)
 690:	03043023          	sd	a6,32(s0)
 694:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 698:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 69c:	8622                	mv	a2,s0
 69e:	00000097          	auipc	ra,0x0
 6a2:	e04080e7          	jalr	-508(ra) # 4a2 <vprintf>
}
 6a6:	60e2                	ld	ra,24(sp)
 6a8:	6442                	ld	s0,16(sp)
 6aa:	6161                	addi	sp,sp,80
 6ac:	8082                	ret

00000000000006ae <printf>:

void
printf(const char *fmt, ...)
{
 6ae:	711d                	addi	sp,sp,-96
 6b0:	ec06                	sd	ra,24(sp)
 6b2:	e822                	sd	s0,16(sp)
 6b4:	1000                	addi	s0,sp,32
 6b6:	e40c                	sd	a1,8(s0)
 6b8:	e810                	sd	a2,16(s0)
 6ba:	ec14                	sd	a3,24(s0)
 6bc:	f018                	sd	a4,32(s0)
 6be:	f41c                	sd	a5,40(s0)
 6c0:	03043823          	sd	a6,48(s0)
 6c4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c8:	00840613          	addi	a2,s0,8
 6cc:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6d0:	85aa                	mv	a1,a0
 6d2:	4505                	li	a0,1
 6d4:	00000097          	auipc	ra,0x0
 6d8:	dce080e7          	jalr	-562(ra) # 4a2 <vprintf>
}
 6dc:	60e2                	ld	ra,24(sp)
 6de:	6442                	ld	s0,16(sp)
 6e0:	6125                	addi	sp,sp,96
 6e2:	8082                	ret

00000000000006e4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e4:	1141                	addi	sp,sp,-16
 6e6:	e422                	sd	s0,8(sp)
 6e8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ea:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ee:	00001797          	auipc	a5,0x1
 6f2:	9127b783          	ld	a5,-1774(a5) # 1000 <freep>
 6f6:	a02d                	j	720 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f8:	4618                	lw	a4,8(a2)
 6fa:	9f2d                	addw	a4,a4,a1
 6fc:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 700:	6398                	ld	a4,0(a5)
 702:	6310                	ld	a2,0(a4)
 704:	a83d                	j	742 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 706:	ff852703          	lw	a4,-8(a0)
 70a:	9f31                	addw	a4,a4,a2
 70c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 70e:	ff053683          	ld	a3,-16(a0)
 712:	a091                	j	756 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 714:	6398                	ld	a4,0(a5)
 716:	00e7e463          	bltu	a5,a4,71e <free+0x3a>
 71a:	00e6ea63          	bltu	a3,a4,72e <free+0x4a>
{
 71e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 720:	fed7fae3          	bgeu	a5,a3,714 <free+0x30>
 724:	6398                	ld	a4,0(a5)
 726:	00e6e463          	bltu	a3,a4,72e <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72a:	fee7eae3          	bltu	a5,a4,71e <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 72e:	ff852583          	lw	a1,-8(a0)
 732:	6390                	ld	a2,0(a5)
 734:	02059813          	slli	a6,a1,0x20
 738:	01c85713          	srli	a4,a6,0x1c
 73c:	9736                	add	a4,a4,a3
 73e:	fae60de3          	beq	a2,a4,6f8 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 742:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 746:	4790                	lw	a2,8(a5)
 748:	02061593          	slli	a1,a2,0x20
 74c:	01c5d713          	srli	a4,a1,0x1c
 750:	973e                	add	a4,a4,a5
 752:	fae68ae3          	beq	a3,a4,706 <free+0x22>
    p->s.ptr = bp->s.ptr;
 756:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 758:	00001717          	auipc	a4,0x1
 75c:	8af73423          	sd	a5,-1880(a4) # 1000 <freep>
}
 760:	6422                	ld	s0,8(sp)
 762:	0141                	addi	sp,sp,16
 764:	8082                	ret

0000000000000766 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 766:	7139                	addi	sp,sp,-64
 768:	fc06                	sd	ra,56(sp)
 76a:	f822                	sd	s0,48(sp)
 76c:	f426                	sd	s1,40(sp)
 76e:	f04a                	sd	s2,32(sp)
 770:	ec4e                	sd	s3,24(sp)
 772:	e852                	sd	s4,16(sp)
 774:	e456                	sd	s5,8(sp)
 776:	e05a                	sd	s6,0(sp)
 778:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 77a:	02051493          	slli	s1,a0,0x20
 77e:	9081                	srli	s1,s1,0x20
 780:	04bd                	addi	s1,s1,15
 782:	8091                	srli	s1,s1,0x4
 784:	0014899b          	addiw	s3,s1,1
 788:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 78a:	00001517          	auipc	a0,0x1
 78e:	87653503          	ld	a0,-1930(a0) # 1000 <freep>
 792:	c515                	beqz	a0,7be <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 794:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 796:	4798                	lw	a4,8(a5)
 798:	02977f63          	bgeu	a4,s1,7d6 <malloc+0x70>
 79c:	8a4e                	mv	s4,s3
 79e:	0009871b          	sext.w	a4,s3
 7a2:	6685                	lui	a3,0x1
 7a4:	00d77363          	bgeu	a4,a3,7aa <malloc+0x44>
 7a8:	6a05                	lui	s4,0x1
 7aa:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7ae:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b2:	00001917          	auipc	s2,0x1
 7b6:	84e90913          	addi	s2,s2,-1970 # 1000 <freep>
  if(p == (char*)-1)
 7ba:	5afd                	li	s5,-1
 7bc:	a895                	j	830 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7be:	00001797          	auipc	a5,0x1
 7c2:	85278793          	addi	a5,a5,-1966 # 1010 <base>
 7c6:	00001717          	auipc	a4,0x1
 7ca:	82f73d23          	sd	a5,-1990(a4) # 1000 <freep>
 7ce:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d4:	b7e1                	j	79c <malloc+0x36>
      if(p->s.size == nunits)
 7d6:	02e48c63          	beq	s1,a4,80e <malloc+0xa8>
        p->s.size -= nunits;
 7da:	4137073b          	subw	a4,a4,s3
 7de:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e0:	02071693          	slli	a3,a4,0x20
 7e4:	01c6d713          	srli	a4,a3,0x1c
 7e8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ea:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ee:	00001717          	auipc	a4,0x1
 7f2:	80a73923          	sd	a0,-2030(a4) # 1000 <freep>
      return (void*)(p + 1);
 7f6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7fa:	70e2                	ld	ra,56(sp)
 7fc:	7442                	ld	s0,48(sp)
 7fe:	74a2                	ld	s1,40(sp)
 800:	7902                	ld	s2,32(sp)
 802:	69e2                	ld	s3,24(sp)
 804:	6a42                	ld	s4,16(sp)
 806:	6aa2                	ld	s5,8(sp)
 808:	6b02                	ld	s6,0(sp)
 80a:	6121                	addi	sp,sp,64
 80c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 80e:	6398                	ld	a4,0(a5)
 810:	e118                	sd	a4,0(a0)
 812:	bff1                	j	7ee <malloc+0x88>
  hp->s.size = nu;
 814:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 818:	0541                	addi	a0,a0,16
 81a:	00000097          	auipc	ra,0x0
 81e:	eca080e7          	jalr	-310(ra) # 6e4 <free>
  return freep;
 822:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 826:	d971                	beqz	a0,7fa <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 828:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82a:	4798                	lw	a4,8(a5)
 82c:	fa9775e3          	bgeu	a4,s1,7d6 <malloc+0x70>
    if(p == freep)
 830:	00093703          	ld	a4,0(s2)
 834:	853e                	mv	a0,a5
 836:	fef719e3          	bne	a4,a5,828 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 83a:	8552                	mv	a0,s4
 83c:	00000097          	auipc	ra,0x0
 840:	b58080e7          	jalr	-1192(ra) # 394 <sbrk>
  if(p == (char*)-1)
 844:	fd5518e3          	bne	a0,s5,814 <malloc+0xae>
        return 0;
 848:	4501                	li	a0,0
 84a:	bf45                	j	7fa <malloc+0x94>
