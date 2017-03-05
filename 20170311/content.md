% Skylake世代以降のIntel HDAドライバ事情
% 坂本 貴史
  Ubuntu Japanese Team
% \today

## Ubuntu とは

 * オペレーティングシステムの名前であり、開発プロジェクトの名前でもあります。
 * パソコンやサーバーにインストールして使います。
 * 一部のスマートフォンやタブレットにインストールすることもできます。
 * インストールすると、いろいろなソフトウェアを利用できるようになります。
 * オープンソースソフトウェアです。

## 今日の話題

 * Ubuntu の音声機能の一部について、よりハードウェアに近い箇所を語ります。

![Ubuntuのサウンドアプレット](img/sound-applet.png)

## 今日の内容

0. サウンドデバイスとは
1. HDAとは
2. ALSAとは
3. ALSAの既存のHDAドライバ
4. ASoCとは
5. ASoC のSST ドライバ
6. UbuntuにおけるSkylake世代以降のHDAドライバ
7. まとめ

この資料はhttps://github.com/takaswie/presentations にあります。

## 免責事項

 * 個人研究による見解であり、内容の妥当性は検証されていません。

## サウンドデバイスとは

 * 音声を扱うデバイスのこと
 * 音楽を聞いたり、電話したりするときに使う
 * 内部的にはこんな構造をしている

<!--![サウンドデバイスの構造](img/device-internal.svg.eps)-->

## HDAとは

 * サウンドデバイスの論理構造と通信仕様の一種。
 * 2004年にIntel 社が仕様を策定し公開。
 * ほぼすべてのPCと、一部のスマートフォンに採用。
 * 特徴
    * コントローラー仕様とコーデック仕様を分離。
    * コントローラーはコーデックに対し、その論理構造を問い合わせることで、どのように操作可能かを把握する。
    * 通信は48.0kHzで駆動するHDAシリアルバス越しに行う

<!--![HDAの設計](img/hda-spec.svg.eps)-->

## HDAのむつかしさ

 * Intel社以外のベンダーがデバイス開発に参加
    * コントローラー側 (VIA社、Creative Technology社など)
    * コーデック側 (Analog Device社、Cirrus Logic社、Realtek社、Conexant社など)
    * Intel社以外のメーカーも自社製品に採用 (NEC社、Fujitsu社、Panasonic社、Dell社、Lenovo社、HP社など)
 * 多様性に起因する問題
    * コントローラーのバグや仕様外動作
    * コーデックの内部論理構造のバグ
    * コーデックの仕様外実装
    * ACPIテーブル上の情報のバグ

## 身近なところにあるHDAの問題

 * Ubuntu日本語フォーラムにたくさん報告がある。
    * [HDA-Intel (IDT92HD81) でマイクが使えない](https://forums.ubuntulinux.jp/viewtopic.php?pid=91714)
    * [イアホンを挿入してもスピーカーから音が出続けてしまう](https://forums.ubuntulinux.jp/viewtopic.php?pid=100488)
    * [Let's note NX3上のubuntu16.04でサウンドが鳴らない](https://forums.ubuntulinux.jp/viewtopic.php?pid=113255)
    * [NEC　VersaProで音が出ません。](https://forums.ubuntulinux.jp/viewtopic.php?id=15850)
    * [ubuntuでPC内の録音について](https://forums.ubuntulinux.jp/viewtopic.php?id=15987)
    * [サウンド設定内の出力内のデバイスの設定にスピーカー、イヤフォン選択肢がありません。](https://forums.ubuntulinux.jp/viewtopic.php?id=14721)
    * [Ubuntu15.04 CF-W8 音がならない](https://forums.ubuntulinux.jp/viewtopic.php?id=18872)
 * Linuxのサウンドデバイスドライバーが、多様性に起因する問題を解決できないのが原因。

<!-- 閑話休題 -->

## ALSAとは

 * Linux向けのソフトウェアスタックのひとつ。
    * Linuxシステムのカーネルランドにある。
    * 様々なサウンドデバイスドライバを含む。
    * それを利用するアプリケーションの仲立ちをする。
 * 現状、音声機能にとっては、Linuxにおける唯一のもの。
    * Ubuntu でももちろん利用。
    * Android の音声機能の低層でもある。
 * Takashi Iwai (SUSE) さんがサブシステムメンテナ。

## ALSAの既存のHDAドライバ

 * 2004年あたりに、PCIデバイスとして開発がスタート。
 * 開発者
    * Intel社所属の人
    * コーデック開発ベンダー所属の人
    * サブシステムメンテナ
    * 市井の普通のひと
 * 3度ほど大規模リファクタリング。
    * 直近は2013年。
    * quirkオプションの多くの挙動が変更に。

## ALSAのHDAドライバの実体

 * カーネルのローダブルなモジュール群
    * snd-hda-intel.ko
    * snd-hda-codec.ko
    * snd-hda-codec-\*.ko
 * lsmod(8) を実行すれば確認できる。

```
$ lsmod | grep hda
snd_hda_codec_hdmi     45056 1
snd_hda_codec_conexant 24576 1
snd_hda_codec_generic  73728 1 snd_hda_codec_conexant
snd_hda_intel          36864 3
snd_hda_codec         135168 4 snd_hda_intel,...
snd_hda_core           86016 7 snd_hda_intel,...

```

## ALSAのHDAドライバのソース

 * Linux カーネルのソースの sound/pci/hda 以下にある。
    * https://git.kernel.org/cgit/linux/kernel/git/tiwai/sound.git/tree/sound/pci/hda
 * 問題があったら直せるけど、開発には慣れと情報が必要。
    * ALSAの開発に参加ができる人かつそのマシンのユーザーが少ないと、自然とサポートが不十分になる。
    * 実例として、Panasonic のLet's Noteシリーズが挙げられる。

<!-- 閑話休題 -->

## もうひとつのHDAドライバ

 * ALSA にはもうひとつのHDAドライバがある
 * ALSA の組み込み装置向けドライバスタック(ASoC)に基づく。
    * Mark Brown (Linaro) がこの部分のメンテナ
    * 日本人開発者として、Kuninori Morimoto (Renesas electronics) さんがいる。
 * Intel社の開発者いわく、今後はこっちが本命だとか。
    * ALSAのupstream で合意されたわけではない気がする。

## ASoCとは

 * ALSA の一部であり、組み込み装置向けドライバスタック
 * 多彩なデバイスに対応しつつコードを共通化するために、モジュールの粒度が細かい
 * デバイス依存コードを排除するために、Device Tree に対応

## ASoC のSST ドライバ

 * Intel 社のSmart Sound Technology (SST) に対応するドライバ。
    * HDAも扱えるし、別なシリアルデータ通信方法(I2S, TDM)も扱える。
    * Digital Signal Processor (DSP) も扱える。
 * 元々はIntel 社の組み込みプラットフォーム向けに開発された。
    * 普通のパソコンへも対応可能なよう設計されている。

## UbuntuにおけるSkylake世代以降のHDAドライバ

 * Ubuntu 16.04 時点で、述べた2種類のドライバ(HDA/SST)がロードされるようになった。
 * 現在は動作条件が揃わないので、ASoCのSSTドライバは動作しない。
    * 近い将来、HDAドライバを置き換えるようになるかも。

```
$ lsmod | grep soc
snd_soc_skl       65536 0
snd_soc_skl_ipc   45056 1 snd_soc_skl
snd_soc_sst_ipc   16384 1 snd_soc_skl_ipc
snd_soc_sst_dsp   32768 1 snd_soc_skl_ipc
snd_hda_ext_core  28672 1 snd_soc_skl
snd_soc_sst_match 16384 1 snd_soc_skl
snd_soc_core     233472 1 snd_soc_skl
snd_compress      20480 1 snd_soc_core
ac97_bus          16384 1 snd_soc_core
snd_pcm_dmaengine 16384 1 snd_soc_core
snd_hda_core      86016 7 snd_hda_intel,...
```

## SSTドライバの事情

 * デバイスの内部情報を、バイナリーの形式で与えなければならない。
  * ドライバがバイナリーパーサーを持つ。
 * バイナリーはALSA のTopology インターフェイスフォーマットで記述する。
    * 2015年にコンポーザーがalsa-lib に実装された。
    * テキストファイルからバイナリを生成。
 * 使っているデバイスに合ったバイナリを生成してインストールする必要あり。
    * バイナリはファイル名で特定される。
    * 各種Linuxディストリビューターおよびメーカーとの協力が不可欠。

## まとめ
 * Intel 社は2種類のサウンド機能ソリューションを持つ。
    * HDA
    * SST
 * それに対応し、ALSAも2種類のサウンドデバイスドライバを持つ。
 * 将来的にはSSTドライバが主流になるけれど、Ubuntuにとってはまだ先の話。
