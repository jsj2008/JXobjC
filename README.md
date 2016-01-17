# JX Objective-C #

![JX Objective-C Logo](doc/nlogotyp.png)

### Overview ###

**JX Objective-C** is a powerful development suite implementing the programming
language Objective-C *(JX)* (abbreviated **JXobjC**.) It is a derivative
project of David Stes' *Portable Object Compiler*, and is the reference
implementation of the JXobjC language.

JX Objective-C several components: firstly a compiler, `jxobjc`, which provides
a complete implementation of the Objective-C *(JX)* language, and which is
itself written in JXobjC. The compiler assists the programmer, and is designed
to act as a friend and assistant, offering clear explanations when an issue
is encountered.

A standard library, **Object Kit**, forms the second component. This provides
a class library equipped with a comprehensive world of objects, allowing the
creation of powerful programmes and libraries. Classes are provided for working
with containers, threads, messaging, networking, and more.
The Object Kit containers subsuite is derived from the design of the
*IC-Pak 101*, the standard library for the historic Stepstone Objective-C. The
overall design of the Object Kit is informed primarily by that of
*SmallTalk-80*'s famously acclaimed standard library.

### Language ###

Objective-C *(JX)* is a programming language in the *Kayian School* of
object-orientation. It bears most similarity to SmallTalk-80, often considered
to be the pinnacle of programming language design.

#### Core Philosophy ####

> *Objects [are] like biological cells, or individual computers on a network,
able to communicate with messages.* - Dr. Alan Kay, father of the Kayian School
of object-orientation

Objective-C *(JX)* is, thus, an Object Oriented language with the capital
**O**. This does not preclude functionality associated with other schools of
language design. Being a language built atop the foundation of C, it is
possible to write as much C in procedural-imperative form inline as desired.
Blocks act as the *lambda expressions* of functional languages, and methods
are provided in Object Kit that resemble typically-functional forms, such as
`collect:`, which is akin to `map()`, or `select:`, akin to `filter()`.

To describe JXobjC then as an object-oriented and functional language is not
'wrong' so to speak. It does, however, miss the point. JXobjC is not a
collection of paradigms acting as means to an end. The design is an end unto
itself. The object is to provide a language human in its nature, well-adapted
to the common understanding of all people, regardless of their local culture.

This is not a goal in-line with many traditionalist approaches to programming
language design, though it does imply the use of some such techniques pioneered
there. Our goal is not to make a friendlier code, but to abolish it.

#### Radical Humanism ####

> *In the age of the individual's liquidation, the question of individuality
must be raised anew.* - Theodor Adorno, critical theorist

The programmer today is an alienated being. The trade is unique in its
ideology; one hears a claim that "*programming must be taught in primary
school*," and moments later, that "*not everyone is able to program, and that's
simply the nature of things*." Programmers at once complain about being
overworked and underpaid, and decry unionisation.

Perhaps this contradictory nature in tech has some relation to the modern trend
of the programming language as an oppressor and terrorist of the programmer,
the compiler as super-ego, destroying hopes and dreams in a flurry of typing
errors and complaints.

Objective-C *(JX)* stands firmly opposed to this trend of deprecating the
human, bestowing the compiler with God-like powers to harm the user. The
purpose of JXobjC is to facilitate the realisation of the programmer's dreams.
The creative energy of the programmer must not be impeded, and suggestions are
to be made without unwilling imposition of them.

Further, there is a trend in programming languages to restrict the user not
only in technical meaning-form, but even in style, in aesthetic. Some languages
even so far as to impose specific bracketing styles on the user! JXobjC does
not now and never will endorse such measures, which serve to alienate the
programmer from their individuality, turning them into a cog in a machine
instead.

#### Objects ####

> *Instead of the bit-grinding processor brutalising data structures, we have
a universe of well-behaved objects that courteously ask each other to carry out
their desires.* - Dan Ingalls

In line with the humanist vision outlined, Objective-C *(JX)* utilises the model
of computation that grew in Xerox's PARC in the development of SmallTalk. The
programmer no longer is forced to set out demands on how they wish to do all
they say, but is able to instead guide the autonomous Objects in their actions,
outlining *what* they want, rather than *how*.

The object is not a mere abstract data-type, but an autonomous actor, an
individual. It does not have 'functions invoked' upon it, but receives messages.
This is an essential aspect of the Kayian object-orientation. It is a
reproduction of human society. The object, like a person, is not an open box
ready to be leered at or manipulated. It is to be communicated with. The
programme forms a micro-society.

The messaging forms the key component of the Kayian late-binding. All
functionality may change. The compiler does not destroy the messages, turning
them into lookups at pre-calculated offsets, but asks the object to respond to a
message instead. This allows for the object to alter how it responds to a
message.

As a practical example, this is used in the Key-Value Observing feature, which
allows an object to request another object to let it know when some property of
it changes. A variation of the property setting message implementation is
swapped-in when an object asks to observe another, and this then performs the
notifying as necessary. When the object is not observed, no such efforts are
expended in deciding whether other objects should be notified.

### Compiling ###

Instructions are available in `doc/compile.md` detailing compilation on various
platforms. In general, the process simply involves running `kmk`.

Before you can build the JX Objective-C compiler, you will need to build and
install the bootstrap package. This is available in the **Releases** section of
the GitHub page.