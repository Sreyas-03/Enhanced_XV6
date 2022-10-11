
user/_set_priority:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    if (argc < 3)
   c:	4789                	li	a5,2
   e:	02a7d463          	bge	a5,a0,36 <main+0x36>
  12:	84ae                	mv	s1,a1
    {
        fprintf(2, "set_priority: insufficient arguments passed\n");
        exit(1);
    }
    else if (argc > 3)
  14:	478d                	li	a5,3
  16:	02a7de63          	bge	a5,a0,52 <main+0x52>
    {
        fprintf(2, "set_priority: too many arguments passed\n");
  1a:	00001597          	auipc	a1,0x1
  1e:	88658593          	addi	a1,a1,-1914 # 8a0 <malloc+0x11c>
  22:	4509                	li	a0,2
  24:	00000097          	auipc	ra,0x0
  28:	67a080e7          	jalr	1658(ra) # 69e <fprintf>
        exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	2fc080e7          	jalr	764(ra) # 32a <exit>
        fprintf(2, "set_priority: insufficient arguments passed\n");
  36:	00001597          	auipc	a1,0x1
  3a:	83a58593          	addi	a1,a1,-1990 # 870 <malloc+0xec>
  3e:	4509                	li	a0,2
  40:	00000097          	auipc	ra,0x0
  44:	65e080e7          	jalr	1630(ra) # 69e <fprintf>
        exit(1);
  48:	4505                	li	a0,1
  4a:	00000097          	auipc	ra,0x0
  4e:	2e0080e7          	jalr	736(ra) # 32a <exit>
    }

    int newSP = atoi(argv[1]);
  52:	6588                	ld	a0,8(a1)
  54:	00000097          	auipc	ra,0x0
  58:	1dc080e7          	jalr	476(ra) # 230 <atoi>
  5c:	892a                	mv	s2,a0
    int pid = atoi(argv[2]);
  5e:	6888                	ld	a0,16(s1)
  60:	00000097          	auipc	ra,0x0
  64:	1d0080e7          	jalr	464(ra) # 230 <atoi>
  68:	84aa                	mv	s1,a0
    int retval = set_priority(newSP, pid);
  6a:	85aa                	mv	a1,a0
  6c:	854a                	mv	a0,s2
  6e:	00000097          	auipc	ra,0x0
  72:	36c080e7          	jalr	876(ra) # 3da <set_priority>
    if (retval == -1)
  76:	57fd                	li	a5,-1
  78:	00f50763          	beq	a0,a5,86 <main+0x86>
    {
        fprintf(2, "set_priority: Given pid (%d) does not exist\n", pid);
        exit(1);
    }
    exit(0);
  7c:	4501                	li	a0,0
  7e:	00000097          	auipc	ra,0x0
  82:	2ac080e7          	jalr	684(ra) # 32a <exit>
        fprintf(2, "set_priority: Given pid (%d) does not exist\n", pid);
  86:	8626                	mv	a2,s1
  88:	00001597          	auipc	a1,0x1
  8c:	84858593          	addi	a1,a1,-1976 # 8d0 <malloc+0x14c>
  90:	4509                	li	a0,2
  92:	00000097          	auipc	ra,0x0
  96:	60c080e7          	jalr	1548(ra) # 69e <fprintf>
        exit(1);
  9a:	4505                	li	a0,1
  9c:	00000097          	auipc	ra,0x0
  a0:	28e080e7          	jalr	654(ra) # 32a <exit>

00000000000000a4 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  a4:	1141                	addi	sp,sp,-16
  a6:	e406                	sd	ra,8(sp)
  a8:	e022                	sd	s0,0(sp)
  aa:	0800                	addi	s0,sp,16
  extern int main();
  main();
  ac:	00000097          	auipc	ra,0x0
  b0:	f54080e7          	jalr	-172(ra) # 0 <main>
  exit(0);
  b4:	4501                	li	a0,0
  b6:	00000097          	auipc	ra,0x0
  ba:	274080e7          	jalr	628(ra) # 32a <exit>

00000000000000be <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  be:	1141                	addi	sp,sp,-16
  c0:	e422                	sd	s0,8(sp)
  c2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c4:	87aa                	mv	a5,a0
  c6:	0585                	addi	a1,a1,1
  c8:	0785                	addi	a5,a5,1
  ca:	fff5c703          	lbu	a4,-1(a1)
  ce:	fee78fa3          	sb	a4,-1(a5)
  d2:	fb75                	bnez	a4,c6 <strcpy+0x8>
    ;
  return os;
}
  d4:	6422                	ld	s0,8(sp)
  d6:	0141                	addi	sp,sp,16
  d8:	8082                	ret

00000000000000da <strcmp>:

int
strcmp(const char *p, const char *q)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  e0:	00054783          	lbu	a5,0(a0)
  e4:	cb91                	beqz	a5,f8 <strcmp+0x1e>
  e6:	0005c703          	lbu	a4,0(a1)
  ea:	00f71763          	bne	a4,a5,f8 <strcmp+0x1e>
    p++, q++;
  ee:	0505                	addi	a0,a0,1
  f0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  f2:	00054783          	lbu	a5,0(a0)
  f6:	fbe5                	bnez	a5,e6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  f8:	0005c503          	lbu	a0,0(a1)
}
  fc:	40a7853b          	subw	a0,a5,a0
 100:	6422                	ld	s0,8(sp)
 102:	0141                	addi	sp,sp,16
 104:	8082                	ret

0000000000000106 <strlen>:

uint
strlen(const char *s)
{
 106:	1141                	addi	sp,sp,-16
 108:	e422                	sd	s0,8(sp)
 10a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 10c:	00054783          	lbu	a5,0(a0)
 110:	cf91                	beqz	a5,12c <strlen+0x26>
 112:	0505                	addi	a0,a0,1
 114:	87aa                	mv	a5,a0
 116:	4685                	li	a3,1
 118:	9e89                	subw	a3,a3,a0
 11a:	00f6853b          	addw	a0,a3,a5
 11e:	0785                	addi	a5,a5,1
 120:	fff7c703          	lbu	a4,-1(a5)
 124:	fb7d                	bnez	a4,11a <strlen+0x14>
    ;
  return n;
}
 126:	6422                	ld	s0,8(sp)
 128:	0141                	addi	sp,sp,16
 12a:	8082                	ret
  for(n = 0; s[n]; n++)
 12c:	4501                	li	a0,0
 12e:	bfe5                	j	126 <strlen+0x20>

0000000000000130 <memset>:

void*
memset(void *dst, int c, uint n)
{
 130:	1141                	addi	sp,sp,-16
 132:	e422                	sd	s0,8(sp)
 134:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 136:	ca19                	beqz	a2,14c <memset+0x1c>
 138:	87aa                	mv	a5,a0
 13a:	1602                	slli	a2,a2,0x20
 13c:	9201                	srli	a2,a2,0x20
 13e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 142:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 146:	0785                	addi	a5,a5,1
 148:	fee79de3          	bne	a5,a4,142 <memset+0x12>
  }
  return dst;
}
 14c:	6422                	ld	s0,8(sp)
 14e:	0141                	addi	sp,sp,16
 150:	8082                	ret

0000000000000152 <strchr>:

char*
strchr(const char *s, char c)
{
 152:	1141                	addi	sp,sp,-16
 154:	e422                	sd	s0,8(sp)
 156:	0800                	addi	s0,sp,16
  for(; *s; s++)
 158:	00054783          	lbu	a5,0(a0)
 15c:	cb99                	beqz	a5,172 <strchr+0x20>
    if(*s == c)
 15e:	00f58763          	beq	a1,a5,16c <strchr+0x1a>
  for(; *s; s++)
 162:	0505                	addi	a0,a0,1
 164:	00054783          	lbu	a5,0(a0)
 168:	fbfd                	bnez	a5,15e <strchr+0xc>
      return (char*)s;
  return 0;
 16a:	4501                	li	a0,0
}
 16c:	6422                	ld	s0,8(sp)
 16e:	0141                	addi	sp,sp,16
 170:	8082                	ret
  return 0;
 172:	4501                	li	a0,0
 174:	bfe5                	j	16c <strchr+0x1a>

0000000000000176 <gets>:

char*
gets(char *buf, int max)
{
 176:	711d                	addi	sp,sp,-96
 178:	ec86                	sd	ra,88(sp)
 17a:	e8a2                	sd	s0,80(sp)
 17c:	e4a6                	sd	s1,72(sp)
 17e:	e0ca                	sd	s2,64(sp)
 180:	fc4e                	sd	s3,56(sp)
 182:	f852                	sd	s4,48(sp)
 184:	f456                	sd	s5,40(sp)
 186:	f05a                	sd	s6,32(sp)
 188:	ec5e                	sd	s7,24(sp)
 18a:	1080                	addi	s0,sp,96
 18c:	8baa                	mv	s7,a0
 18e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 190:	892a                	mv	s2,a0
 192:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 194:	4aa9                	li	s5,10
 196:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 198:	89a6                	mv	s3,s1
 19a:	2485                	addiw	s1,s1,1
 19c:	0344d863          	bge	s1,s4,1cc <gets+0x56>
    cc = read(0, &c, 1);
 1a0:	4605                	li	a2,1
 1a2:	faf40593          	addi	a1,s0,-81
 1a6:	4501                	li	a0,0
 1a8:	00000097          	auipc	ra,0x0
 1ac:	19a080e7          	jalr	410(ra) # 342 <read>
    if(cc < 1)
 1b0:	00a05e63          	blez	a0,1cc <gets+0x56>
    buf[i++] = c;
 1b4:	faf44783          	lbu	a5,-81(s0)
 1b8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1bc:	01578763          	beq	a5,s5,1ca <gets+0x54>
 1c0:	0905                	addi	s2,s2,1
 1c2:	fd679be3          	bne	a5,s6,198 <gets+0x22>
  for(i=0; i+1 < max; ){
 1c6:	89a6                	mv	s3,s1
 1c8:	a011                	j	1cc <gets+0x56>
 1ca:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1cc:	99de                	add	s3,s3,s7
 1ce:	00098023          	sb	zero,0(s3)
  return buf;
}
 1d2:	855e                	mv	a0,s7
 1d4:	60e6                	ld	ra,88(sp)
 1d6:	6446                	ld	s0,80(sp)
 1d8:	64a6                	ld	s1,72(sp)
 1da:	6906                	ld	s2,64(sp)
 1dc:	79e2                	ld	s3,56(sp)
 1de:	7a42                	ld	s4,48(sp)
 1e0:	7aa2                	ld	s5,40(sp)
 1e2:	7b02                	ld	s6,32(sp)
 1e4:	6be2                	ld	s7,24(sp)
 1e6:	6125                	addi	sp,sp,96
 1e8:	8082                	ret

00000000000001ea <stat>:

int
stat(const char *n, struct stat *st)
{
 1ea:	1101                	addi	sp,sp,-32
 1ec:	ec06                	sd	ra,24(sp)
 1ee:	e822                	sd	s0,16(sp)
 1f0:	e426                	sd	s1,8(sp)
 1f2:	e04a                	sd	s2,0(sp)
 1f4:	1000                	addi	s0,sp,32
 1f6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1f8:	4581                	li	a1,0
 1fa:	00000097          	auipc	ra,0x0
 1fe:	170080e7          	jalr	368(ra) # 36a <open>
  if(fd < 0)
 202:	02054563          	bltz	a0,22c <stat+0x42>
 206:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 208:	85ca                	mv	a1,s2
 20a:	00000097          	auipc	ra,0x0
 20e:	178080e7          	jalr	376(ra) # 382 <fstat>
 212:	892a                	mv	s2,a0
  close(fd);
 214:	8526                	mv	a0,s1
 216:	00000097          	auipc	ra,0x0
 21a:	13c080e7          	jalr	316(ra) # 352 <close>
  return r;
}
 21e:	854a                	mv	a0,s2
 220:	60e2                	ld	ra,24(sp)
 222:	6442                	ld	s0,16(sp)
 224:	64a2                	ld	s1,8(sp)
 226:	6902                	ld	s2,0(sp)
 228:	6105                	addi	sp,sp,32
 22a:	8082                	ret
    return -1;
 22c:	597d                	li	s2,-1
 22e:	bfc5                	j	21e <stat+0x34>

0000000000000230 <atoi>:

int
atoi(const char *s)
{
 230:	1141                	addi	sp,sp,-16
 232:	e422                	sd	s0,8(sp)
 234:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 236:	00054683          	lbu	a3,0(a0)
 23a:	fd06879b          	addiw	a5,a3,-48
 23e:	0ff7f793          	zext.b	a5,a5
 242:	4625                	li	a2,9
 244:	02f66863          	bltu	a2,a5,274 <atoi+0x44>
 248:	872a                	mv	a4,a0
  n = 0;
 24a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 24c:	0705                	addi	a4,a4,1
 24e:	0025179b          	slliw	a5,a0,0x2
 252:	9fa9                	addw	a5,a5,a0
 254:	0017979b          	slliw	a5,a5,0x1
 258:	9fb5                	addw	a5,a5,a3
 25a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 25e:	00074683          	lbu	a3,0(a4)
 262:	fd06879b          	addiw	a5,a3,-48
 266:	0ff7f793          	zext.b	a5,a5
 26a:	fef671e3          	bgeu	a2,a5,24c <atoi+0x1c>
  return n;
}
 26e:	6422                	ld	s0,8(sp)
 270:	0141                	addi	sp,sp,16
 272:	8082                	ret
  n = 0;
 274:	4501                	li	a0,0
 276:	bfe5                	j	26e <atoi+0x3e>

0000000000000278 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 278:	1141                	addi	sp,sp,-16
 27a:	e422                	sd	s0,8(sp)
 27c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 27e:	02b57463          	bgeu	a0,a1,2a6 <memmove+0x2e>
    while(n-- > 0)
 282:	00c05f63          	blez	a2,2a0 <memmove+0x28>
 286:	1602                	slli	a2,a2,0x20
 288:	9201                	srli	a2,a2,0x20
 28a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 28e:	872a                	mv	a4,a0
      *dst++ = *src++;
 290:	0585                	addi	a1,a1,1
 292:	0705                	addi	a4,a4,1
 294:	fff5c683          	lbu	a3,-1(a1)
 298:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 29c:	fee79ae3          	bne	a5,a4,290 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2a0:	6422                	ld	s0,8(sp)
 2a2:	0141                	addi	sp,sp,16
 2a4:	8082                	ret
    dst += n;
 2a6:	00c50733          	add	a4,a0,a2
    src += n;
 2aa:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ac:	fec05ae3          	blez	a2,2a0 <memmove+0x28>
 2b0:	fff6079b          	addiw	a5,a2,-1
 2b4:	1782                	slli	a5,a5,0x20
 2b6:	9381                	srli	a5,a5,0x20
 2b8:	fff7c793          	not	a5,a5
 2bc:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2be:	15fd                	addi	a1,a1,-1
 2c0:	177d                	addi	a4,a4,-1
 2c2:	0005c683          	lbu	a3,0(a1)
 2c6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ca:	fee79ae3          	bne	a5,a4,2be <memmove+0x46>
 2ce:	bfc9                	j	2a0 <memmove+0x28>

00000000000002d0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d6:	ca05                	beqz	a2,306 <memcmp+0x36>
 2d8:	fff6069b          	addiw	a3,a2,-1
 2dc:	1682                	slli	a3,a3,0x20
 2de:	9281                	srli	a3,a3,0x20
 2e0:	0685                	addi	a3,a3,1
 2e2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e4:	00054783          	lbu	a5,0(a0)
 2e8:	0005c703          	lbu	a4,0(a1)
 2ec:	00e79863          	bne	a5,a4,2fc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2f0:	0505                	addi	a0,a0,1
    p2++;
 2f2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f4:	fed518e3          	bne	a0,a3,2e4 <memcmp+0x14>
  }
  return 0;
 2f8:	4501                	li	a0,0
 2fa:	a019                	j	300 <memcmp+0x30>
      return *p1 - *p2;
 2fc:	40e7853b          	subw	a0,a5,a4
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret
  return 0;
 306:	4501                	li	a0,0
 308:	bfe5                	j	300 <memcmp+0x30>

000000000000030a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e406                	sd	ra,8(sp)
 30e:	e022                	sd	s0,0(sp)
 310:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 312:	00000097          	auipc	ra,0x0
 316:	f66080e7          	jalr	-154(ra) # 278 <memmove>
}
 31a:	60a2                	ld	ra,8(sp)
 31c:	6402                	ld	s0,0(sp)
 31e:	0141                	addi	sp,sp,16
 320:	8082                	ret

0000000000000322 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 322:	4885                	li	a7,1
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <exit>:
.global exit
exit:
 li a7, SYS_exit
 32a:	4889                	li	a7,2
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <wait>:
.global wait
wait:
 li a7, SYS_wait
 332:	488d                	li	a7,3
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 33a:	4891                	li	a7,4
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <read>:
.global read
read:
 li a7, SYS_read
 342:	4895                	li	a7,5
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <write>:
.global write
write:
 li a7, SYS_write
 34a:	48c1                	li	a7,16
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <close>:
.global close
close:
 li a7, SYS_close
 352:	48d5                	li	a7,21
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <kill>:
.global kill
kill:
 li a7, SYS_kill
 35a:	4899                	li	a7,6
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <exec>:
.global exec
exec:
 li a7, SYS_exec
 362:	489d                	li	a7,7
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <open>:
.global open
open:
 li a7, SYS_open
 36a:	48bd                	li	a7,15
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 372:	48c5                	li	a7,17
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 37a:	48c9                	li	a7,18
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 382:	48a1                	li	a7,8
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <link>:
.global link
link:
 li a7, SYS_link
 38a:	48cd                	li	a7,19
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 392:	48d1                	li	a7,20
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 39a:	48a5                	li	a7,9
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3a2:	48a9                	li	a7,10
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3aa:	48ad                	li	a7,11
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3b2:	48b1                	li	a7,12
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3ba:	48b5                	li	a7,13
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3c2:	48b9                	li	a7,14
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <strace>:
.global strace
strace:
 li a7, SYS_strace
 3ca:	48d9                	li	a7,22
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 3d2:	48dd                	li	a7,23
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3da:	48e1                	li	a7,24
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 3e2:	48e9                	li	a7,26
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 3ea:	48e5                	li	a7,25
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f2:	1101                	addi	sp,sp,-32
 3f4:	ec06                	sd	ra,24(sp)
 3f6:	e822                	sd	s0,16(sp)
 3f8:	1000                	addi	s0,sp,32
 3fa:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3fe:	4605                	li	a2,1
 400:	fef40593          	addi	a1,s0,-17
 404:	00000097          	auipc	ra,0x0
 408:	f46080e7          	jalr	-186(ra) # 34a <write>
}
 40c:	60e2                	ld	ra,24(sp)
 40e:	6442                	ld	s0,16(sp)
 410:	6105                	addi	sp,sp,32
 412:	8082                	ret

0000000000000414 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 414:	7139                	addi	sp,sp,-64
 416:	fc06                	sd	ra,56(sp)
 418:	f822                	sd	s0,48(sp)
 41a:	f426                	sd	s1,40(sp)
 41c:	f04a                	sd	s2,32(sp)
 41e:	ec4e                	sd	s3,24(sp)
 420:	0080                	addi	s0,sp,64
 422:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 424:	c299                	beqz	a3,42a <printint+0x16>
 426:	0805c963          	bltz	a1,4b8 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42a:	2581                	sext.w	a1,a1
  neg = 0;
 42c:	4881                	li	a7,0
 42e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 432:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 434:	2601                	sext.w	a2,a2
 436:	00000517          	auipc	a0,0x0
 43a:	52a50513          	addi	a0,a0,1322 # 960 <digits>
 43e:	883a                	mv	a6,a4
 440:	2705                	addiw	a4,a4,1
 442:	02c5f7bb          	remuw	a5,a1,a2
 446:	1782                	slli	a5,a5,0x20
 448:	9381                	srli	a5,a5,0x20
 44a:	97aa                	add	a5,a5,a0
 44c:	0007c783          	lbu	a5,0(a5)
 450:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 454:	0005879b          	sext.w	a5,a1
 458:	02c5d5bb          	divuw	a1,a1,a2
 45c:	0685                	addi	a3,a3,1
 45e:	fec7f0e3          	bgeu	a5,a2,43e <printint+0x2a>
  if(neg)
 462:	00088c63          	beqz	a7,47a <printint+0x66>
    buf[i++] = '-';
 466:	fd070793          	addi	a5,a4,-48
 46a:	00878733          	add	a4,a5,s0
 46e:	02d00793          	li	a5,45
 472:	fef70823          	sb	a5,-16(a4)
 476:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 47a:	02e05863          	blez	a4,4aa <printint+0x96>
 47e:	fc040793          	addi	a5,s0,-64
 482:	00e78933          	add	s2,a5,a4
 486:	fff78993          	addi	s3,a5,-1
 48a:	99ba                	add	s3,s3,a4
 48c:	377d                	addiw	a4,a4,-1
 48e:	1702                	slli	a4,a4,0x20
 490:	9301                	srli	a4,a4,0x20
 492:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 496:	fff94583          	lbu	a1,-1(s2)
 49a:	8526                	mv	a0,s1
 49c:	00000097          	auipc	ra,0x0
 4a0:	f56080e7          	jalr	-170(ra) # 3f2 <putc>
  while(--i >= 0)
 4a4:	197d                	addi	s2,s2,-1
 4a6:	ff3918e3          	bne	s2,s3,496 <printint+0x82>
}
 4aa:	70e2                	ld	ra,56(sp)
 4ac:	7442                	ld	s0,48(sp)
 4ae:	74a2                	ld	s1,40(sp)
 4b0:	7902                	ld	s2,32(sp)
 4b2:	69e2                	ld	s3,24(sp)
 4b4:	6121                	addi	sp,sp,64
 4b6:	8082                	ret
    x = -xx;
 4b8:	40b005bb          	negw	a1,a1
    neg = 1;
 4bc:	4885                	li	a7,1
    x = -xx;
 4be:	bf85                	j	42e <printint+0x1a>

00000000000004c0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4c0:	7119                	addi	sp,sp,-128
 4c2:	fc86                	sd	ra,120(sp)
 4c4:	f8a2                	sd	s0,112(sp)
 4c6:	f4a6                	sd	s1,104(sp)
 4c8:	f0ca                	sd	s2,96(sp)
 4ca:	ecce                	sd	s3,88(sp)
 4cc:	e8d2                	sd	s4,80(sp)
 4ce:	e4d6                	sd	s5,72(sp)
 4d0:	e0da                	sd	s6,64(sp)
 4d2:	fc5e                	sd	s7,56(sp)
 4d4:	f862                	sd	s8,48(sp)
 4d6:	f466                	sd	s9,40(sp)
 4d8:	f06a                	sd	s10,32(sp)
 4da:	ec6e                	sd	s11,24(sp)
 4dc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4de:	0005c903          	lbu	s2,0(a1)
 4e2:	18090f63          	beqz	s2,680 <vprintf+0x1c0>
 4e6:	8aaa                	mv	s5,a0
 4e8:	8b32                	mv	s6,a2
 4ea:	00158493          	addi	s1,a1,1
  state = 0;
 4ee:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4f0:	02500a13          	li	s4,37
 4f4:	4c55                	li	s8,21
 4f6:	00000c97          	auipc	s9,0x0
 4fa:	412c8c93          	addi	s9,s9,1042 # 908 <malloc+0x184>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4fe:	02800d93          	li	s11,40
  putc(fd, 'x');
 502:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 504:	00000b97          	auipc	s7,0x0
 508:	45cb8b93          	addi	s7,s7,1116 # 960 <digits>
 50c:	a839                	j	52a <vprintf+0x6a>
        putc(fd, c);
 50e:	85ca                	mv	a1,s2
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	ee0080e7          	jalr	-288(ra) # 3f2 <putc>
 51a:	a019                	j	520 <vprintf+0x60>
    } else if(state == '%'){
 51c:	01498d63          	beq	s3,s4,536 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 520:	0485                	addi	s1,s1,1
 522:	fff4c903          	lbu	s2,-1(s1)
 526:	14090d63          	beqz	s2,680 <vprintf+0x1c0>
    if(state == 0){
 52a:	fe0999e3          	bnez	s3,51c <vprintf+0x5c>
      if(c == '%'){
 52e:	ff4910e3          	bne	s2,s4,50e <vprintf+0x4e>
        state = '%';
 532:	89d2                	mv	s3,s4
 534:	b7f5                	j	520 <vprintf+0x60>
      if(c == 'd'){
 536:	11490c63          	beq	s2,s4,64e <vprintf+0x18e>
 53a:	f9d9079b          	addiw	a5,s2,-99
 53e:	0ff7f793          	zext.b	a5,a5
 542:	10fc6e63          	bltu	s8,a5,65e <vprintf+0x19e>
 546:	f9d9079b          	addiw	a5,s2,-99
 54a:	0ff7f713          	zext.b	a4,a5
 54e:	10ec6863          	bltu	s8,a4,65e <vprintf+0x19e>
 552:	00271793          	slli	a5,a4,0x2
 556:	97e6                	add	a5,a5,s9
 558:	439c                	lw	a5,0(a5)
 55a:	97e6                	add	a5,a5,s9
 55c:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 55e:	008b0913          	addi	s2,s6,8
 562:	4685                	li	a3,1
 564:	4629                	li	a2,10
 566:	000b2583          	lw	a1,0(s6)
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	ea8080e7          	jalr	-344(ra) # 414 <printint>
 574:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 576:	4981                	li	s3,0
 578:	b765                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 57a:	008b0913          	addi	s2,s6,8
 57e:	4681                	li	a3,0
 580:	4629                	li	a2,10
 582:	000b2583          	lw	a1,0(s6)
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e8c080e7          	jalr	-372(ra) # 414 <printint>
 590:	8b4a                	mv	s6,s2
      state = 0;
 592:	4981                	li	s3,0
 594:	b771                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 596:	008b0913          	addi	s2,s6,8
 59a:	4681                	li	a3,0
 59c:	866a                	mv	a2,s10
 59e:	000b2583          	lw	a1,0(s6)
 5a2:	8556                	mv	a0,s5
 5a4:	00000097          	auipc	ra,0x0
 5a8:	e70080e7          	jalr	-400(ra) # 414 <printint>
 5ac:	8b4a                	mv	s6,s2
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	bf85                	j	520 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5b2:	008b0793          	addi	a5,s6,8
 5b6:	f8f43423          	sd	a5,-120(s0)
 5ba:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5be:	03000593          	li	a1,48
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	e2e080e7          	jalr	-466(ra) # 3f2 <putc>
  putc(fd, 'x');
 5cc:	07800593          	li	a1,120
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	e20080e7          	jalr	-480(ra) # 3f2 <putc>
 5da:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5dc:	03c9d793          	srli	a5,s3,0x3c
 5e0:	97de                	add	a5,a5,s7
 5e2:	0007c583          	lbu	a1,0(a5)
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	e0a080e7          	jalr	-502(ra) # 3f2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5f0:	0992                	slli	s3,s3,0x4
 5f2:	397d                	addiw	s2,s2,-1
 5f4:	fe0914e3          	bnez	s2,5dc <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5f8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	b70d                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 600:	008b0913          	addi	s2,s6,8
 604:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 608:	02098163          	beqz	s3,62a <vprintf+0x16a>
        while(*s != 0){
 60c:	0009c583          	lbu	a1,0(s3)
 610:	c5ad                	beqz	a1,67a <vprintf+0x1ba>
          putc(fd, *s);
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	dde080e7          	jalr	-546(ra) # 3f2 <putc>
          s++;
 61c:	0985                	addi	s3,s3,1
        while(*s != 0){
 61e:	0009c583          	lbu	a1,0(s3)
 622:	f9e5                	bnez	a1,612 <vprintf+0x152>
        s = va_arg(ap, char*);
 624:	8b4a                	mv	s6,s2
      state = 0;
 626:	4981                	li	s3,0
 628:	bde5                	j	520 <vprintf+0x60>
          s = "(null)";
 62a:	00000997          	auipc	s3,0x0
 62e:	2d698993          	addi	s3,s3,726 # 900 <malloc+0x17c>
        while(*s != 0){
 632:	85ee                	mv	a1,s11
 634:	bff9                	j	612 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 636:	008b0913          	addi	s2,s6,8
 63a:	000b4583          	lbu	a1,0(s6)
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	db2080e7          	jalr	-590(ra) # 3f2 <putc>
 648:	8b4a                	mv	s6,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	bdd1                	j	520 <vprintf+0x60>
        putc(fd, c);
 64e:	85d2                	mv	a1,s4
 650:	8556                	mv	a0,s5
 652:	00000097          	auipc	ra,0x0
 656:	da0080e7          	jalr	-608(ra) # 3f2 <putc>
      state = 0;
 65a:	4981                	li	s3,0
 65c:	b5d1                	j	520 <vprintf+0x60>
        putc(fd, '%');
 65e:	85d2                	mv	a1,s4
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	d90080e7          	jalr	-624(ra) # 3f2 <putc>
        putc(fd, c);
 66a:	85ca                	mv	a1,s2
 66c:	8556                	mv	a0,s5
 66e:	00000097          	auipc	ra,0x0
 672:	d84080e7          	jalr	-636(ra) # 3f2 <putc>
      state = 0;
 676:	4981                	li	s3,0
 678:	b565                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 67a:	8b4a                	mv	s6,s2
      state = 0;
 67c:	4981                	li	s3,0
 67e:	b54d                	j	520 <vprintf+0x60>
    }
  }
}
 680:	70e6                	ld	ra,120(sp)
 682:	7446                	ld	s0,112(sp)
 684:	74a6                	ld	s1,104(sp)
 686:	7906                	ld	s2,96(sp)
 688:	69e6                	ld	s3,88(sp)
 68a:	6a46                	ld	s4,80(sp)
 68c:	6aa6                	ld	s5,72(sp)
 68e:	6b06                	ld	s6,64(sp)
 690:	7be2                	ld	s7,56(sp)
 692:	7c42                	ld	s8,48(sp)
 694:	7ca2                	ld	s9,40(sp)
 696:	7d02                	ld	s10,32(sp)
 698:	6de2                	ld	s11,24(sp)
 69a:	6109                	addi	sp,sp,128
 69c:	8082                	ret

000000000000069e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69e:	715d                	addi	sp,sp,-80
 6a0:	ec06                	sd	ra,24(sp)
 6a2:	e822                	sd	s0,16(sp)
 6a4:	1000                	addi	s0,sp,32
 6a6:	e010                	sd	a2,0(s0)
 6a8:	e414                	sd	a3,8(s0)
 6aa:	e818                	sd	a4,16(s0)
 6ac:	ec1c                	sd	a5,24(s0)
 6ae:	03043023          	sd	a6,32(s0)
 6b2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6ba:	8622                	mv	a2,s0
 6bc:	00000097          	auipc	ra,0x0
 6c0:	e04080e7          	jalr	-508(ra) # 4c0 <vprintf>
}
 6c4:	60e2                	ld	ra,24(sp)
 6c6:	6442                	ld	s0,16(sp)
 6c8:	6161                	addi	sp,sp,80
 6ca:	8082                	ret

00000000000006cc <printf>:

void
printf(const char *fmt, ...)
{
 6cc:	711d                	addi	sp,sp,-96
 6ce:	ec06                	sd	ra,24(sp)
 6d0:	e822                	sd	s0,16(sp)
 6d2:	1000                	addi	s0,sp,32
 6d4:	e40c                	sd	a1,8(s0)
 6d6:	e810                	sd	a2,16(s0)
 6d8:	ec14                	sd	a3,24(s0)
 6da:	f018                	sd	a4,32(s0)
 6dc:	f41c                	sd	a5,40(s0)
 6de:	03043823          	sd	a6,48(s0)
 6e2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e6:	00840613          	addi	a2,s0,8
 6ea:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ee:	85aa                	mv	a1,a0
 6f0:	4505                	li	a0,1
 6f2:	00000097          	auipc	ra,0x0
 6f6:	dce080e7          	jalr	-562(ra) # 4c0 <vprintf>
}
 6fa:	60e2                	ld	ra,24(sp)
 6fc:	6442                	ld	s0,16(sp)
 6fe:	6125                	addi	sp,sp,96
 700:	8082                	ret

0000000000000702 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 702:	1141                	addi	sp,sp,-16
 704:	e422                	sd	s0,8(sp)
 706:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 708:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70c:	00001797          	auipc	a5,0x1
 710:	8f47b783          	ld	a5,-1804(a5) # 1000 <freep>
 714:	a02d                	j	73e <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 716:	4618                	lw	a4,8(a2)
 718:	9f2d                	addw	a4,a4,a1
 71a:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71e:	6398                	ld	a4,0(a5)
 720:	6310                	ld	a2,0(a4)
 722:	a83d                	j	760 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 724:	ff852703          	lw	a4,-8(a0)
 728:	9f31                	addw	a4,a4,a2
 72a:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 72c:	ff053683          	ld	a3,-16(a0)
 730:	a091                	j	774 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 732:	6398                	ld	a4,0(a5)
 734:	00e7e463          	bltu	a5,a4,73c <free+0x3a>
 738:	00e6ea63          	bltu	a3,a4,74c <free+0x4a>
{
 73c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 73e:	fed7fae3          	bgeu	a5,a3,732 <free+0x30>
 742:	6398                	ld	a4,0(a5)
 744:	00e6e463          	bltu	a3,a4,74c <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 748:	fee7eae3          	bltu	a5,a4,73c <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 74c:	ff852583          	lw	a1,-8(a0)
 750:	6390                	ld	a2,0(a5)
 752:	02059813          	slli	a6,a1,0x20
 756:	01c85713          	srli	a4,a6,0x1c
 75a:	9736                	add	a4,a4,a3
 75c:	fae60de3          	beq	a2,a4,716 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 760:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 764:	4790                	lw	a2,8(a5)
 766:	02061593          	slli	a1,a2,0x20
 76a:	01c5d713          	srli	a4,a1,0x1c
 76e:	973e                	add	a4,a4,a5
 770:	fae68ae3          	beq	a3,a4,724 <free+0x22>
    p->s.ptr = bp->s.ptr;
 774:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 776:	00001717          	auipc	a4,0x1
 77a:	88f73523          	sd	a5,-1910(a4) # 1000 <freep>
}
 77e:	6422                	ld	s0,8(sp)
 780:	0141                	addi	sp,sp,16
 782:	8082                	ret

0000000000000784 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 784:	7139                	addi	sp,sp,-64
 786:	fc06                	sd	ra,56(sp)
 788:	f822                	sd	s0,48(sp)
 78a:	f426                	sd	s1,40(sp)
 78c:	f04a                	sd	s2,32(sp)
 78e:	ec4e                	sd	s3,24(sp)
 790:	e852                	sd	s4,16(sp)
 792:	e456                	sd	s5,8(sp)
 794:	e05a                	sd	s6,0(sp)
 796:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 798:	02051493          	slli	s1,a0,0x20
 79c:	9081                	srli	s1,s1,0x20
 79e:	04bd                	addi	s1,s1,15
 7a0:	8091                	srli	s1,s1,0x4
 7a2:	0014899b          	addiw	s3,s1,1
 7a6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7a8:	00001517          	auipc	a0,0x1
 7ac:	85853503          	ld	a0,-1960(a0) # 1000 <freep>
 7b0:	c515                	beqz	a0,7dc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b4:	4798                	lw	a4,8(a5)
 7b6:	02977f63          	bgeu	a4,s1,7f4 <malloc+0x70>
 7ba:	8a4e                	mv	s4,s3
 7bc:	0009871b          	sext.w	a4,s3
 7c0:	6685                	lui	a3,0x1
 7c2:	00d77363          	bgeu	a4,a3,7c8 <malloc+0x44>
 7c6:	6a05                	lui	s4,0x1
 7c8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7cc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d0:	00001917          	auipc	s2,0x1
 7d4:	83090913          	addi	s2,s2,-2000 # 1000 <freep>
  if(p == (char*)-1)
 7d8:	5afd                	li	s5,-1
 7da:	a895                	j	84e <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7dc:	00001797          	auipc	a5,0x1
 7e0:	83478793          	addi	a5,a5,-1996 # 1010 <base>
 7e4:	00001717          	auipc	a4,0x1
 7e8:	80f73e23          	sd	a5,-2020(a4) # 1000 <freep>
 7ec:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ee:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f2:	b7e1                	j	7ba <malloc+0x36>
      if(p->s.size == nunits)
 7f4:	02e48c63          	beq	s1,a4,82c <malloc+0xa8>
        p->s.size -= nunits;
 7f8:	4137073b          	subw	a4,a4,s3
 7fc:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7fe:	02071693          	slli	a3,a4,0x20
 802:	01c6d713          	srli	a4,a3,0x1c
 806:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 808:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 80c:	00000717          	auipc	a4,0x0
 810:	7ea73a23          	sd	a0,2036(a4) # 1000 <freep>
      return (void*)(p + 1);
 814:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 818:	70e2                	ld	ra,56(sp)
 81a:	7442                	ld	s0,48(sp)
 81c:	74a2                	ld	s1,40(sp)
 81e:	7902                	ld	s2,32(sp)
 820:	69e2                	ld	s3,24(sp)
 822:	6a42                	ld	s4,16(sp)
 824:	6aa2                	ld	s5,8(sp)
 826:	6b02                	ld	s6,0(sp)
 828:	6121                	addi	sp,sp,64
 82a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 82c:	6398                	ld	a4,0(a5)
 82e:	e118                	sd	a4,0(a0)
 830:	bff1                	j	80c <malloc+0x88>
  hp->s.size = nu;
 832:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 836:	0541                	addi	a0,a0,16
 838:	00000097          	auipc	ra,0x0
 83c:	eca080e7          	jalr	-310(ra) # 702 <free>
  return freep;
 840:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 844:	d971                	beqz	a0,818 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 846:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 848:	4798                	lw	a4,8(a5)
 84a:	fa9775e3          	bgeu	a4,s1,7f4 <malloc+0x70>
    if(p == freep)
 84e:	00093703          	ld	a4,0(s2)
 852:	853e                	mv	a0,a5
 854:	fef719e3          	bne	a4,a5,846 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 858:	8552                	mv	a0,s4
 85a:	00000097          	auipc	ra,0x0
 85e:	b58080e7          	jalr	-1192(ra) # 3b2 <sbrk>
  if(p == (char*)-1)
 862:	fd5518e3          	bne	a0,s5,832 <malloc+0xae>
        return 0;
 866:	4501                	li	a0,0
 868:	bf45                	j	818 <malloc+0x94>
