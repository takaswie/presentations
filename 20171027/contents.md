% Obsolete  'dimen' member. Rewrite 'aplay'
% Takashi SAKAMOTO (坂本 貴史)
% \today

This is written for Audio Mini Summit 2017. For my convenience, this
presentation includes two themes.

# A plan to obsolete 'dimen' member in 'struct snd\_ctl\_elem\_info'.

## Background

 * In ALSA control interface, 'struct snd\_ctl\_elem\_info' is used to deliver
   information about each of control element. This structure represents
   identical information, attribute information and so on.
 * This structure has 'dimen' member. This member has a supplement information
   that drivers expect userspace applications to handle control elements
   as multi-level dimension.

## Issues

 * At present, the 'dimen' member is used only by drivers for PCI devices
   produced by Echo Digital Audio corp. The member is quite model-specific and
   it loses a concept which ALSA control interface should have; i.e.
   general-purposes.
 * For the above issue, I posted a commit to generalize its usage.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2016-July/109831.html
 * However, the drivers uses the member with inconsistent ways. This also
   loses a requirement which ALSA control interface should have; i.e.
   consistency.
 * I realize the above by a report from users, then post a revert commit.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-September/125846.html

## My proposal

 * Let's obsolete 'dimen' member step by step in future kernel releases between
   v4.15 and v4.21.

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

 * TBA

## Control elements with dimen information on echo drivers

 * TBA

## Current implemetation of 'echomixer'

 * TBA
 * Patchset will be available soon.

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
    * Support timer-based scheduling scenario.
    * Obsolete some options.

 * The new program is named as 'axfer' and added independent of 'aplay'.
 * RFCv3 was posted.
    * http://mailman.alsa-project.org/pipermail/alsa-devel/2017-October/125961.html
 * Patchset is available in my github repository
    * https://github.com/takaswie/alsa-utils/tree/topic/axfer

## A structured shape

 * TBA

## Unit tests

 * TBA

## Support timer-based scheduling scenario

 * TBA

## Obsoleted options

 * TBA
