% Untitled presentation
% Takashi SAKAMOTO (坂本 貴史)
% \today

This is written for Audio Mini conference 2018. For my convenience, this
presentation includes two themes.

1. Integrating the ALSA control core
2. Another approach to produce language bindings by GObject Introspection.

This presentation is available in my github repository.

 * https://github.com/takaswie/presentations/

# Integrating the ALSA control core

## issues for which I work

 * Obsolete 'dimen' member in container for information to an element
 * Limitation on a container for value array to an element
 * User-defined element set left by finished process
 * Restriction for the number of user-defined control element set per sound card

## Obsolete 'dimen' member in container for information to an element

 * `struct snd_ctl_elem_info` has `dimen` member but nowadays it's useless.

 * [alsa-lib][PATCH v2 0/2] ctl: deprecate APIs of dimension information
     * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-November/127359.html
 * A plan to obsolete 'dimen' member in 'struct snd_ctl_elem_info'.
     * https://github.com/takaswie/presentations/blob/master/20171027/contents.md
 * Let's mark this as `deprecated` in UAPI header

## Limitation on a container for value array to an element

 * The number of items in value array of `struct snd_ctl_elem_value` has limitation.
     * 64:  for integer64 type
     * 128: integer/enumerated type
     * 512: bytes type
 * Some developers would like to program their drivers to handle more number of items.
     * [RFC] [ALSA][CONTROL] Added 2 ioctls for reading/writing values of multiple controls in one go (at once)
         * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-February/117506.html
 * Stop abusing TLV feature, developers in ALSA SoC part

## Planned roadmap 1/4

 * Refactoring compat layer
     * Handle different structure layout for System V ABI
         * intel386
         * the other 32 bit machine
         * 64 bit machine
     * System V ABI for intel386 has 4 byte alignment quirk to 8 byte type
         * Typical 32 bit ABIs use 8 byte alignment.
     * [alsa-devel] [PATCH 00/24] ALSA: ctl: refactoring compat layer
         * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-November/127996.html
     * https://github.com/takaswie/sound/commits/topic/ctl-compat-refactoring

## Planned roadmap 2/4

 * Refactoring handlers of ioctl command
     * Not yet posted.
         * .rodata section against .text section
         * allocation in kernel stack or kernel logical address space
     * different requestors
         * by compat layer in kernel space
         * by kernel driver in kernel space
         * by user processes in user space
     * https://github.com/takaswie/sound/commits/topic/ctl-ioctl-refactoring

## Planned roadmap 3/4

 * Handle larger data via ELEM_READ/ELEM_WRITE
     * Not yet prepared.
     * use kernel virtual space, instead of kernel logical space
         * currently memdup_user() is used (slab allocator in kernel logical space)
         * page fault is allowed in process context
     * structure layout issue
         * unused tstamp member in tail of the structure, can be obsoleted
         * unused SNDRV_CTL_ELEM_ACCESS_TIMESTAMP flag can be obsoleted

## struct snd_ctl_elem_value

```
struct snd_ctl_elem_value {
  struct snd_ctl_elem_id id;
  unsigned int indirect: 1;
  union {
    ...
  } value;
  struct timespec tstamp;
  unsigned char reserved[128-sizeof(struct timespec)];
};
```

## Planned roadmap 4/4

 * band-aid for ALSA SoC part
     * just use SND_SOC_BYTES
     * [PATCH] Revert "ASoC: core: mark SND_SOC_BYTES_EXT as deprecated"
         * http://mailman.alsa-project.org/pipermail/alsa-devel/2016-September/112774.html
     * deprecate SND_SOC_BYTES_TLV
 * it's the worst idea to upload binary blob via ALSA control character device
     * even if it includes initialization data for coefficiencies
     * use hwdep interface for this purpose, anyway

## User-defined element set left by finished process

 * ALSA control core has a feature called as `user-defined element set`
 * [RFC][PATCH 0/2] ALSA: control: limit life time of user-defined element set
     * http://mailman.alsa-project.org/pipermail/alsa-devel/2016-September/112525.html
 * A new access flag might be introduced
     * SNDRV_CTL_ELEM_ACCESS_OWNER_BOUND?
     * need to keep logical meaning of SNDRV_CTL_IOCTL_ELEM_LOCK/UNLOCK operations

## Restriction for the number of user-defined control element set per sound card

 * As of v4.20, one sound card instance can have 32 sets of control element set
 * This is a bit small to register control element sets required for some devices
     * audio and music units on IEEE 1394 bus for studio purpose;
       e.g. solo/mute/gain/balance for multiplexer inputs to multiplexer outputs up to 32 channels

# Another approach to produce language bindings by GObject Introspection.

## PyAlsa

 * Application of binding framework of Python
 * http://git.alsa-project.org/?p=alsa-python.git
 * A first commit was done in Feb 2007, by Jaroslav Kysela (cb4dccc16547).

## GObject Introspection (gi)

 * https://gi.readthedocs.io/en/latest/
 * GObject introspection is a middleware layer between C libraries (using
   GObject) and language bindings.
 * The C library can be scanned at compile time and generate metadata files,
   in addition to the actual native C library.
 * Then language bindings can read this metadata and automatically provide
   bindings to call into the C library.

## Existent bindings for any languages based on g-i
 * Python 2/3: PyGObject
    * https://pygobject.readthedocs.io/
 * Ruby: ruby-gnome2
    * http://ruby-gnome2.osdn.jp/
 * Lua: lgi
    * https://github.com/pavouk/lgi
 * JavaScript: GJs
    * https://gitlab.gnome.org/GNOME/gjs/wikis/Home
 * and so on

## An example; libhinawa and hinawa-utils

 * I'm an author of modules in ALSA firewire stack (`sound/firewire/*`)
    * Application of IEEE 1394, IEEE 1212, IEC 61883-1/6, AV/C commands defined
      by 1394TA and many vendor-specific protocols
 * There's few tools to assist my work
 * I need to build tools to assist this work.
 * [alsa-devel] hinawa-utils v0.1.0 and libhinawa v1.0.0 release
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2018-August/139448.html

## mockup; alsa-gi

 * https://github.com/takaswie/alsa-gi
 * an application of `asound.h` and `asequencer.h` in Linux UAPI
 * I developed this to test my work to fix ALSA ctl/seq core
 * I'm not active because no time to it
