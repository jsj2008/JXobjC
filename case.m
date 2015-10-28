struct bintime
{
    long sec;
    long frac;
};

int __poop__ (const struct bintime _bt)
{
    return ((_bt.sec << 32) + (_bt.frac >> 32));
}