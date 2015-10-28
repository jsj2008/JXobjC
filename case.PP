# 1 "case.c"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "case.c"
# 1 "case.m"
struct bintime {
 long sec;
 long frac;
};


int __poop__(const struct bintime _bt)
{
 return ((_bt.sec << 32) + (_bt.frac >> 32));
}
