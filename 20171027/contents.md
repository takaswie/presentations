% Obsolete  'dimen' member. Rewrite 'aplay'
% Takashi SAKAMOTO (坂本 貴史)
% \today

This is written for Audio Mini Summit 2017. For my convenience, this
presentation includes two themes.

1. A plan to obsolete 'dimen' member in 'struct snd\_ctl\_elem\_info'.
2. Rewrite 'aplay' and support timer-based scheduling scenario

This presentation is available in my github repository.

 * https://github.com/takaswie/presentations/

# A plan to obsolete 'dimen' member in 'struct snd\_ctl\_elem\_info'.

## Background

 * In ALSA control interface, 'struct snd\_ctl\_elem\_info' is used to deliver
   information about each of control element. This structure represents
   identical information, attribute information and so on.
 * This structure has 'dimen' member. This member has a supplement information
   that drivers expect userspace applications to handle control elements
   as multi-level dimension.

## Issues

 * At present, the 'dimen' member is only used by drivers for PCI devices
   produced by Echo Digital Audio corp. The member is quite model-specific and
   it loses a concept which ALSA control interface should have; i.e.
   general-purposes.
    * And we can judge that 'echomixer' is a sole application which uses dimen
      information in userspace.
 * For the above issue, I posted a commit to generalize its usage for the other
   applications.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2016-July/109831.html
 * However, the drivers uses the member with inconsistent ways. This also
   loses a requirement which ALSA control interface should have; i.e.
   consistency.
 * I realize the above by a report from users, then post a revert commit.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-September/125846.html

## My proposal

 * Let's obsolete 'dimen' member from 'struct snd\_ctl\_elem\_info' step by step
   in future kernel releases between v4.15 and v4.21.

    1. (v4.15) modify 'echomixer' program so that it's independent of some
       alsa-lib APIs in which the 'dimen' member is used.
    2. (v4.15) add 'deprecated' message on comments for the above alsa-lib APIs.
    3. (v4.15) remove codes from test programs in alsa-lib, where the above
       alsa-lib APIs are used.
    4. (v4.19) remove codes related to the 'dimen' member from PCI drivers for
       devices produced by Echo Digital Audio corp as the modified 'echomixer'
       is disseminated.
    5. (v4.21) remove codes related to the 'dimen' member from ALSA control
       core.
    6. (v4.21) remove the 'dimen' member from asound.h and bump up interface
       version.

## Layout of 'struct snd\_ctl\_elem\_info'

```
struct snd_ctl_elem_info {
  struct snd_ctl_elem_id id;
  snd_ctl_elem_type_t type;
  unsigned int access;
  unsigned int count;
  __kernel_pid_t owner;
  union {
    ...
    unsigned char reserved[128];
  } value;
  union {
    unsigned short d[4];
    unsigned short *d_ptr;
  } dimen;
  unsigned char reserved[64-4*sizeof(unsigned short)];
};
```

## Control elements with dimen information added by echoaudio drivers

Current implementation of the drivers have three control element sets with
dimension information:

 * 'Monitor Mixer Volume' (type: integer)
 * 'VMixer Volume' (type: integer)
 * 'VU-meters' (type: boolean)

For details of their implementation, read a commit 51db452df07b('Revert "ALSA:
echoaudio: purge contradictions between dimension matrix members and total
number of members"'). Elements in these three sets include contradiction
about their way to parse dimension information.

## Redundant information on an element added by echoaudio drivers

* These drivers add another element set named as 'Channels info'. An element in
  this set has redundant information of the dimen information.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-August/124968.html
* This element is available for all of sound card instances added by echo
  drivers.
* For echoaudio drivers and echomixer, we can obsolete usage of dimen
  information with the redundant information.

# Rewrite 'aplay' and support timer-based scheduling scenario

## Background

 * Before 2000, 'aplay' program was added into alsa-utils repository.
 * Nowadays, this tool is referred typically as a sample program of ALSA PCM
   interface or alsa-lib PCM APIs.
 * Some vendors might use it as a part of test for drivers.

## Issues

 * This program is not enough structured. This costs expensive in a point of
   maintenance effort.
 * It supports several file formats; RIFF/Wave, AU and VOC, however
   implementations are not enough good. It loses interoperability between
   different environments.
 * It's not written by typical ways for device I/O on Unix environment; poll
   wait then perform I/O.
 * It has some unpractical options, especially for position tests.
 * It doesn't support 'timer-based scheduling' scenario introduced by PulseAudio
   developers in a recent decade. This is not good to test no-period-wakeup
   feature of drivers.

## My proposal

 * Let's rewrite 'aplay'.
    * Integrate for a structured shape.
    * Add unit tests for file formats.
    * Use poll before performing I/O, according to operation types.
    * Obsolete some options.
    * Support timer-based scheduling scenario.

 * The new program is named as 'axfer' and added independent of 'aplay'.
 * RFCv3 was posted.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-October/125961.html
 * Patchset is available in my github repository
    * https://github.com/takaswie/alsa-utils/tree/topic/axfer

## A structured shape

The new program consists of three parts (modules):
 * xfer
    * a module to transfer data frames as a data stream. At present, alsa-lib
      (libasoud2) backend is just supported for several I/O scenario.
 * container
    * a module to write/read data frames to/from a file.
 * mapper
    * a module to demux a data stream to each files, or mux a data stream
      with each of files.

```
(cdev) <-> xfer <-> mapper <-> container <-> (file)
```

## Unit tests

```
$ make check
```

 * Simple tests are available for container/mapper modules.
 * The tests performs:
    * One test case has own set of parameters such as rate, data frame count.
    * Prepare a buffer and fill it with random values.
    * Write the data frame from the above buffer to file via container module.
    * Prepare a buffer.
    * Read the data frame from the file to the above buffer via container module.
    * Compare contents on these two buffers.
    * For mapper module, test includes two cases for single/multiple containers.
 * I note that it takes a long time to test many cases.

## Options planned to be obsoleted

 * In points of practicality and reduction of maintenance effort, several
   options should be obsoleted.
    * displaying volume unit by teminal control code (-V, --vumeter)
    * generate filename with strftime and an additional format (--use-strftime)
    * pause control via key events (-i, --interactive)
    * configure channel map for PCM substream (-m, --chmap)
    * generate PID file (--process-id-file)
    * check hw\_ptr/appl\_ptr in each iteration (--test-position/--test-coef)
 * At RFCv3, these options are still available, except for position check.

## Support timer-based scheduling scenario

 * '--sched-type' is newly added. Give '=timer' to this option for this purpose.
 * For details of this scenario, please read my comment in a patch of this
   series.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-October/125994.html
 * In the above comment, some issues are addressed, which already mentioned in
   ALSA upstream.

## Issues of ALSA PCM interface

 * In this work, I faced several problems of ALSA PCM interface

1. burst-ness and granularity of data transmission to calculate yielding time
2. rewinding operation and XRUN (underrun), invalidation
3. synchronization of status of PCM substream between hw/kernel/userspace

## burst-ness and granularity of data transmission to calculate yielding time

* When run axfer with timer-based scheduling scenario, you can often see below
  lines.

```
Wake up but not enough space: 1160 1152 23
Wake up but not enough space: 481 473 9
Wake up but not enough space: 1063 1048 22
```

* This means that the program got any processor but planned number of data
  frames are not available yet.
* When working with strace(1) and timeofday option (-tt), the lapse of time is
  surely as much as planned number of data frames.
* This is due to the burst-ness. The value differs depending on hardware.
* As already mentioned in alsa-devel, we need an additional feature in ALSA
  PCM interface to retrieve the value.

## rewinding operation and XRUN (underrun), invalidation

* At present, this program utilize rewinding operation to reduce latency between
  queueing data frames and actual procedure for data transmission. This is done
  just after starting PCM substream and fill whole buffer with data frames for
  zero samples.
* PulseAudio developers already found that we need to have a space for this
  case. When rewinding operation is done to get appl\_ptr back as much as
  'avail' space, underrun occurs because data transmission runs constantly.
* For the space, at present, this program uses 32 data frames as hard-coded
  value.
* This value is speculative and there might be a need for ALSA PCM interface to
  deliver safe value from drivers to applications.

## synchronization of status of PCM substream between hw/kernel/userspace

 * In current ALSA PCM interface, there's no better way to perform below three
   tasks in one call:
    1. inquire current position of data transmission to hardware (hwsync)
    2. copying status of PCM substream to ioctl buffer.
    3. synchronizing status of PCM substream between kernel/userspace explicitly,
       even if page mapping is available for status/control data of PCM
       substream.
 * The above should be done within lock primitive in kernel space because
   atomicity is not guranteed between operations in kernel space and operations
   in user space.
 * When working for ALSA PCM interface v2.0.14, I and Iwai-san realized the
   necessity for a new ioctl command to status/control data sync. This is for
   item 1. and 3, in my understanding.
