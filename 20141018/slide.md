% ALSA=仮想マシン（の一部）
% 坂本 貴史
% \today
 
# 今日の話題
 
Linuxのサウンドサブシステムについて語ります。

前半
  : ALSAの概要
後半
  : 前回からの進捗

# 自己紹介

坂本 貴史 (さかもと たかし)
takaswie@Twitter

自然2001。12年前はこの教室で講義を受けてました。
学位は地球科学で取りました。計算機数学とかやったことないです。

ミラクルリナックス株式会社所属。サイネージ製品と車載製品の開発に関与してます。


# ALSA

Advanced Linux Sound Architectureのこと。

Linuxのサウンドサブシステムを担当。

ノートPCやスマートフォンで音声が入出力できるのは、だいたいこれのおかげ。


# サウンドデバイス

意外といろんな種類がある。

接続バス
 : PCI/PCI-Expressバス、USB、FireWire、ISAバス、SoCの周辺バス

主要な機能
 : 音声出入力、MIDI信号入出力

用途
 : 音声の視聴、レコーディング、楽器、通話


# 実例



# オペレーティングシステムの役割1

1.1.1 拡張マシンとしてのオペレーティング・システム
オペレーティング・システムは、ディスク装置を意識させないようにファイルというインターフェイスを提供しているのと同様、割り込み、タイマ、メモリ管理、その他低レベルの機能にまつわる負担からプログラマを開放してくれる。どの場合もユーザーに与えられたオペレーティング・システムの抽象化は、その下にあるハードウェアより簡単で使いやすい。
したがって、オペレーティング・システムの機能は、ユーザーに拡張マシン(extended machine)またはその下のハードウェアよりプログラムしやすい仮想マシン(virtual machine)を提供することであると言える。

(ANDREW S. TANENBAUM (1989) 『 MINIX オペレーティングシステム ) 』坂本文 監修、大西照代 翻訳、アスキー出版局)


# オペレーティングシステムの役割2

1.1.2 リソース管理プログラムとしてのオペレーティング・システム

複数のユーザーが1つのコンピューターを共用している時、メモリ、I/O、デバイス、その他のリソースの保護と管理の必要性がさらに高まることは明らかである。つまり、このような側面からのオペレーティング・システムの仕事は、誰がどのリソースを使っているのかを記録し、リソースに対する要求に応じてその仕様を認め、アカウントを取り、また同じリソースに対して異なるプログラムやユーザーから出された要求を調整することである。

(ANDREW S. TANENBAUM (1989) 『 MINIX オペレーティングシステム ) 』坂本文 監修、大西照代 翻訳、アスキー出版局)


# ALSAの主要な役割

低レベルの機能にまつわる負担からプログラマを解放
 : カーネルにサウンドデバイスドライバを提供
ハードウェアの抽象化
 : ユーザープログラムにALSAライブラリを通じてAPIを提供
サウンドデバイスというリソースの管理
 : ALSAコアを通じてサウンドデバイスのリソースを管理

サウンドデバイスを扱うソフトウェアのためのアーキテクチャ
 = Advanced Linux Sound Architecture


# ALSAのコンセプト

扱うデータ:
- パルス符号変調(PCM)で標本化した音声データ
- MIDIメッセージ

入出力:
- バイト単位のread/writeは適さないので、ほとんどすべての入出力をioctlでやる。
- フレームを入出力の単位とする。たいていは44.1kHz相当の標本


# ALSAの最小のPCMアプリケーション

$ cat minimal.c

#include <sound/asound.h>

int main(void)
{
	snd_pcm_t handle;
	snd_pcm_hw_params_t params;
	snd_pcm_sframes_t frames;
	char buf[20];

	snd_pcm_open(&handle, "default", SND_PCM_STREAM_PLAYBACK, 0);

	snd_pcm_hw_params_set_format(handle, &params, SND_PCM_FORMAT_S16);
	snd_pcm_hw_params_set_rate(handle, &params, 44100, 0);
	snd_pcm_hw_params_set_channels(handle, &params, 2, 0);
	snd_pcm_hw_params(handle, &params);

	for (i = 0; i < 44100; i++) {
		frames = 10;
		snd_pcm_writei(handle, buf, 10);
	}

	snd_pcm_drain();
	snd_pcm_close();
}

$ gcc -o ./minimal ./minimal.c -lasound


# ALSAライブラリ

ALSA PCM plugin-chain


# ALSAの主要なキャラクタデバイス

/dev/snd/controlC%i
  : Mixer/hcontrol/controlインターフェイス
/dev/snd/pcmC%iD%ip{c,p}
  : PCMインターフェイス
/dev/snd/hwdepC%iD%i
  : hardware dependentインターフェイス
/dev/snd/midiC%iD%i
  : RawMidiインターフェイス
/dev/snd/seq
  : Sequencerインターフェイス
/dev/snd/timer
  : Timerインターフェイス


# ALSAのカーネルランド

ALSA Core
ALSA Drivers
Linux subsystems



# タイムテーブル
 
- Linuxの開発プロセス (10分)
- 私がやったこと (5分)
- マージに至る活動 (10分)
- 質疑など (5分)
 

# Linuxの開発プロセス - 開発サイクル
 
「前の」、「今の」、「次の」バージョンと表現したとき、以下のようになります。

0週
  :  前のバージョンをリリースします。今のバージョンのマージウィンドウを開始します。
0〜2週
  :  この間、新機能がpullされます。
2週
  :  マージウィンドウを閉鎖します。今のバージョンのrc1をリリースします。
2週〜N-1週
  :  この間、バグ修正がpullされ、だいたい1週間おきにrcをリリースします。
N-1週
  :  今のバージョンのrc(N-1)をリリースします。
N週
  :  今のバージョンをリリースします。次のバージョンのマージウィンドウを開始します。

# Linuxの開発プロセス - サブシステム

- 機能別にサブシステムに分割されています
- それぞれのサブシステムを開発するプロジェクトがあります

例えば

- Scheduler
- Memory management
- Networking
- Filesystems
- Read-Copy update (RCU)
- ...
- IEEE1394 bus
- Sound

# Linuxの開発プロセス - サブシステムのメンテナ

## サブシステムにはメンテナがいる

- サブシステム内の開発をまとめる役割を果します
- 開発者から送られたパッチは、メンテナがマージするかどうかを決定します
- マージウィンドウが開いたら、メンテナがLinusにpull requestを出します
- Linusがrequestをackし、treeにマージします
- メンテナはあらかじめ、Linusとの信頼関係を築いているため、拒否されることは珍しいようです

# Linuxの開発プロセス - 開発者の活動

- 典型的には、サブシステム開発プロジェクトのメーリングリストで活動します
- 自分が書いたパッチのマージに向け、メンテナや他の開発者を説得します
- RFC (Request for comment) を出し、他の開発者の反応を見ることが有効です
- 他の人が投げたパッチをレビューすると喜ばれます


# 私がやったこと

- サウンドサブシステム
- ALSA firewire stackの開発
- firewireのプロトコルスタック
- プロトコルスタックの実装
- ドライバの実装

# 私がやったこと - サウンドサブシステム

私が活動しているサブシステムは、Linuxのサウンドサブシステムです。Advanced Linux Sound Architecture (ALSA) と言います。

- サウンドデバイスドライバをカーネルランドに持ちます
- システムに複数のキャラクタデバイスを設けます。
- ライブラリを通じてAPIを提供し、キャラクタデバイスに対するファイル操作を抽象化します(alsa-lib)

# 私がやったこと - ALSA firewire stackの開発

2000年から2010年にかけて、IEEE1394バスに接続するサウンドデバイスがいくつも発売されています。IEEE1394は一般的に、firewireとも呼ばれます。

ALSAのコードのうち、IEEE1394バスに関係するものを、開発者間でALSA firewire stackと呼んでいます。

# 私がやったこと - firewireのプロトコルスタック

![プロトコルスタックの比較(概略)](./img/stack.svg.eps)

IEEE1394バスに接続するサウンドデバイスは、パケットでデータを送受信します。

# 私がやったこと - プロトコルスタックの実装

ALSA firewire stackは、上位のプロトコルをサポートします。

しかし2013年時点で、プロトコルの仕様のうち、多くのデバイスが必要とするものをサポートしていませんでした。

そこで、サポートの強化を行いました。具体的には、ライブラリモジュールの開発です。

snd-firewire-lib
  : プロトコルの処理を行うヘルパ関数を含むライブラリモジュール


# 私がやったこと - ドライバの実装

また、ライブラリモジュールを使うALSAのドライバを2つ開発し、70〜80モデルを新たにサポートしました。

snd-fireworks
  : Echo Audio社のFireworksデバイスモジュールのドライバ
snd-bebob
  : BridgeCo AG社(現ArchWave AG社)のBeBoBシリーズを適用したデバイスチップのドライバ

# 開発の初期

2013年1月〜2013年8月

目標は、デバイス仕様を把握することと、自分の活動をアピールすることです。

- ライブラリモジュールの拡張
- ドライバの作成
- Linux firewire subsystemのバグ

# 開発の初期 - ドライバ用ライブラリの拡張

## 2013/04/28 Takashi Sakamoto wrote:

[alsa-devel] [PATCH 0/3] snd-firewire-lib: add handling CMP output connection

~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-April/061559.html~

[alsa-devel] [PATCH 0/4] snd-firewire-lib: add handling AMDTP receive stream

~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-April/061562.html~

既存のライブラリモジュールに、不足機能を追加するパッチを投稿しました。ALSAのfirewire stackのメンテナであるClemens Ladischがコメントをくれ、以降は彼とのやりとりが中心になります。


# 開発の初期 - ドライバの作成

## 2013/06/01 Takashi Sakamoto wrote:

[alsa-devel] [PATCH 0/2] snd-firewire-lib: add MIDI stream support

~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-June/062610.html~

[alsa-devel] [PATCH 0/8] [RFC] new driver for Echo Audio's Fireworks based devices

~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-June/062614.html~

fireworksドライバを書き上げてRFCしました。

このとき、このドライバがサポートするデバイスチップ(fireworks)が、規格外の挙動を持つことがわかります。様々なワークアラウンドをライブラリモジュールに加えましたが、この規格外の挙動が、その後の開発を長引かせる原因となります。


# 開発の初期 - Linux firewire subsystemのバグ

## 2013/05/06 Takashi Sakamoto wrote:  

> How to get driver\_data of struct ieee1394\_device\_id in kernel driver module?  
~http://sourceforge.net/p/linux1394/mailman/message/30896844/~

この投稿の結果、Linux firewire subsystemが、各デバイスドライバに対し、大きな影響のあるバグを持つことが判明します。そして、カーネルAPIを変更する修正がLinux 3.11にマージされました。

このカーネルを使うUbuntu 13.10がリリースされるまで、カーネルでの開発はお休みすることにしました。

# 開発の中期

2013年9月〜2014年1月

目標は、パッチセットの最終候補を作成し、テスターを募ることです。

- 別なデバイスチップの調査
- ドライバのブラッシュアップ
- 既存実装のリグレッションテスト
- 最終RFCとCFT

# 開発の中期 - 別なデバイスチップとドライバ

Ubuntu 13.10が2013/10/13にリリースされたので、開発を再開しました。

fireworksは規格外の挙動を持ちます。ライブラリモジュールの妥当性を判断するために、ある程度規格に準拠したリファレンス実装を必要としました。そこで、ユーザーランドドライバ開発プロジェクトのコードを調べ、良さそうなデバイスチップを選び、それを搭載したデバイスを入手してパケットを調査し、もうひとつのドライバを書きました。

なおこの時期、活動が評価されたからか、そのプロジェクト(FFADO)に勧誘されて、そちらでもコミッタになりました。


# 開発の中期 - ドライバのブラッシュアップ

## 2013/11/23 Takashi Sakamoto wrote:

[alsa-devel] [RFC][PATCH 00/17] Enhancement for firewire-lib
~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-November/069163.html~

[alsa-devel] [RFC][PATCH 00/13] bebob: a new driver for BridgeCo BeBoB based device
~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-November/069183.html~

## 2013/12/11 Takashi Sakamoto wrote:

[alsa-devel] [PATCH v2 0/8][RFC] a driver for Fireworks based devices

~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-February/073498.html~

この時期に、コミットするドライバの形が決まりました。


# 開発の中期 - 既存実装のリグレッションテスト

## 2013/12/20 Takashi Sakamoto wrote:

[alsa-devel] [RFC v2][PATCH 00/38] Enhancement for support of some firewire devices

~http://mailman.alsa-project.org/pipermail/alsa-devel/2013-December/070424.html~

## 2013/01/05 Takashi Sakamoto wrote:

[alsa-devel] [RFC][PATCH 0/8] A new driver for OXFW970/971 based devices

~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-January/070705.html~

OXFWは既存のドライバを手直しして、新しいデバイスをサポートできるようにしたものです。データを扱う部分はほぼそのままであり、ライブラリモジュールが既存のドライバにリグレッションを起こさないことを確認できました。


# 開発の中期 - 最終RFCとCFT

## 2014/01/29 Takashi Sakamoto wrote:

[alsa-devel] [RFC v3] [PATCH 00/52] Enhancement for support of firewire devices

~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-January/071820.html~

[LAD] Call for testing (final): ALSA driver for some firewire devices

~http://linuxaudio.org/mailarchive/lad/2014/1/29/204035~


最終候補のテスト依頼を出しました。テスターの報告から、複数のプロセスから同時にアクセスされた時に、カーネルスペースを破壊するバグが判明しました。

# 開発の後期

2014年2月〜2014年6月

目標は、ALSAの上流にマージされるよう、コミュニケーションすることです。

- 影響のあるプロジェクトとの調整
- 3.14 のマージウィンドウの閉鎖
- マージリクエスト 1 〜 3
- 3.15 のマージウィンドウの閉鎖
- マージリクエスト 4
- メンテナの緩い同意
- topic/firewire ブランチ
- 0day kernel testing
- testing backendのレポートへの対応
- sound.gitのfor-nextへ

# 開発の後期 - 影響のあるプロジェクトとの調整

いくつかのユーザーランドプロジェクトに影響を与えることがわかりましたので、開発者メーリングリストに参加して調整を行いました。

PulseAudioとの調整 (pulseaudio-discuss)
  : ユーザーランドからALSAを通じてfirewireデバイスが見えるようになると、PulseAudioが警告をたくさん出す問題を報告
FFADOとの調整 (ffado-devel)
  : ALSAがデバイスを使用している際に、FFADOのアプリケーションが実行できなくなるパッチを投稿
Jack Audio Connection Kitとの調整 (jack-devel)
  : ALSA経由でもFfADO経由でもfirewireデバイスが使えるようになることを報告
Linux firewire subsystemとの調整 (linux1394-devel)
  : エキスポートされているカーネルAPIのプロトタイプを、公開ヘッダに移すよう要求

# 開発の後期 - 3.14のマージウィンドウの閉鎖

## Linux 3.13
> 2014/01/19 Linus Tovals wrote:  
Anyway, with this, the merge window for 3.14 is obviously open.
~https://lkml.org/lkml/2014/1/19/148~

## Linux 3.14-rc1 is out

> 2014/02/02 Linus Tovals wrote:  
Hey, it was a normal two-week merge window, and it's closed now.
~https://lkml.org/lkml/2014/2/2/176~

関連するプロジェクトとの調整も終ったので、次の3.15のマージウィンドウを目指します。

# 開発の後期 - マージリクエスト 1〜3

## Enhancement of support for Firewire devices

- [2014/02/28] [GIT PULL][PATCH 00/39] ~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-February/073446.html~
- [2014/03/05] [GIT PULL][PATCH 00/39 v2] ~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-February/073498.html~
- [2014/03/21] [PATCH 00/44 v3] ~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-March/074624.html~

いろいろなアドバイスやコメントをもらえました。

- コードのバグの指摘
- コーディングのテクニカルなアドバイス。例えばコンパイル時計算の活用、ループ中のインデックスにエイリアスを使ってオブジェクトコードを減らす、など
- コードの可読性の向上
- カーネルランドのコードの作法

# 開発の後期 - 3.15のマージウィンドウの閉鎖

## Linux 3.14 out

> 2014/03/30 Linux Tovals wrote:  
So 3.14 is out there, and the merge window for 3.15 is thus open.
~https://lkml.org/lkml/2014/3/30/336~

## Linux 3.15 rc1 out, merge window closed

> 2014/04/13 Linux Tovals wrote:  
It's been two weeks since 3.14 was released, and -rc1 of 3.15 is now tagged and pushed out, ... , Which means that the merge window is closed, and people should send me fixes only.
~https://lkml.org/lkml/2014/4/13/121~

間に合わなかった。

# 開発の後期 - マージリクエスト4

3.16のマージウィンドウにターゲットを変更しました。

## [alsa-devel] [PATCH 00/49 v4] Enhancement for support of Firewire devices

> 2014/04/25 Takashi Sakamoto wrote:  
This 49 patchset is to update previous series:
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-April/075841.html~

# 開発の後期 - メンテナの緩い同意

1ヶ月後

> 2014/05/25 Takashi Sakamoto wrote:  
Any reactions for this patchset?
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-May/077051.html~

> 2013/05/26 Clemens Ladisch wrote:  
I think all patches deserve testing in the -next tree. 
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-May/077071.html~


# 開発の後期 - topic/firewireブランチ

> 2014/05/26 Takashi Iwai wrote:  
Meanwhile I applied the patches to topic/firewire branch and put to my build test bot.  I'll merge the branch to for-next tomorrow if no one gives objections.
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-May/077084.html~

sound.gitに、topic/firewireブランチが設けられました。
~http://git.kernel.org/cgit/linux/kernel/git/tiwai/sound.git/log/?h=topic/firewire~

# 開発の後期 - 0day kernel testing


- Linuxカーネルのビルド及びブートのリグレッションテストを行う自動ボット
- 2012年あたりに作られた
- IntelのOpen Source Technology Centerにある
- 複数台のサーバーでたくさんのサーバーインスタンスを常時稼働
- 全ブランチに対し、様々なカーネルオプションを適用し、commit-by-commitテストを行う
- エラーや警告はすぐにパッチ作成者に送られる

0day kernel testing back-end (2012/05/17)

~https://lkml.org/lkml/2012/5/17/126~

KS2012: Kernel build/boot testing (2012/09/05)

~http://lwn.net/Articles/514278/~

# 開発の後期 - testing backendのレポートへの対応

## [kbuild] [sound:topic/firewire 18/49] sound/firewire/amdtp.c:199 amdtp\_stream\_set\_parameters() warn: we never enter this loop

> 2014/05/26 kbuild test robot wrote:  
sound/firewire/amdtp.c:199 amdtp\_stream\_set\_parameters() warn: we never enter this loop   
sound/firewire/amdtp.c:199 amdtp\_stream\_set\_parameters() warn: unsigned 'sfc' is never less than zero.   
sound/firewire/amdtp.c:199 amdtp\_stream\_set\_parameters() warn: unsigned 'sfc' is never less than zero.   

~https://lists.01.org/pipermail/kbuild/2014-May/001429.html~

こんなメールが15通くらい届いたので、翌日に修正パッチをポスト。

# 開発の後期 - sound.gitのfor-nextへ
予定通り、2014/05/27にsound.gitのfor-nextブランチへマージされました。

~http://git.kernel.org/cgit/linux/kernel/git/tiwai/sound.git/commit/?h=for-next&id=a58bdba749b36069ec372da9c9fd16017b6c0b47~

# マージ以降

2014年6月

目標は、Linuxへのマージを見届けることです。

- マージウィンドウオープン
- Linusへのプルリクエスト
- コードの軽微な修正
- Linusへのプルリクエスト
- マージウィンドウの閉鎖

# マージ以降 - マージウィンドウオープン

## Linux 3.15-rc8 ... and merge window for 3.16

> 2014/06/01 Linus Tovals wrote:  
Let's try something new. I suspect most people are ready to start the merge window, and we could try how it would be to overlap the first week of the merge window with the last week of the previous release.
~https://lkml.org/lkml/2014/6/1/264~

Linux 3.16のマージウィンドウが開きました。普段とは異なり、2週間のうち1週間は、前のバージョン(Linux 3.15)のリリースマネジメントと重複しました。

# マージ以降 - Linusへのプルリクエスト

## [GIT PULL] sound updates for 3.16-rc1

> 2014/06/04 Takashi Iwai wrote:  
Linus,
please pull sound fixes for v3.16-rc1 from:
git://git.kernel.org/pub/scm/linux/kernel/git/tiwai/sound.git tags/sound-3.16-rc1
The topmost commit is 16088cb6c02d0b766b9b8d7edff98da7f1c93205

サブシステムメンテナがLinux上流へ、サウンドサブシステムの更新をpull。このコミットのコメントに誤りがあったので、事前に訂正依頼を出しました。

~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-June/077450.html~

# マージ以降 - コードの軽微な修正

[alsa-devel] [PATCH] firewire-lib: Use IEC 61883-6 compliant labels for Raw Audio data
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-June/077326.html~

[alsa-devel] [PATCH] firewire-lib: Remove a comment about restriction of asynchronous operation
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-June/077377.html~

[alsa-devel] [PATCH 0/6] Fix some minor issues for Fireworks/BeBoB drivers
~http://mailman.alsa-project.org/pipermail/alsa-devel/2014-June/077416.html~

Linux 3.16-rc1が公開される前に、もう一度コードの見直しをしました。以前の状態から引き継いたバグ、意味不明なコメント、無意味なコードを修正。

# マージ以降 - Linusへのプルリクエスト

## [GIT PULL] sound fixes for 3.16-rc1

> 2014/06/03 Takashi Iwai wrote:  
Linus,
please pull sound fixes for v3.16-rc1 from:
git://git.kernel.org/pub/scm/linux/kernel/git/tiwai/sound.git tags/sound-fix-3.16-rc1
The topmost commit is 8a02b164d4bfac108bfe37e98108bff1e062bd3d

サウンドサブシステムのメンテナがLinuxの上流へ、サウンドサブシステムのバグ修正のプルリクエスト。

# マージ以降 - マージウィンドウの閉鎖

## Linux 3.16-rc1 - merge window closed

> 2014/06/15 Linux Tovals wrote:  
So it's been two weeks since the merge window opened, and rc1 is out
there and thus the merge window is closed.
~https://lkml.org/lkml/2014/6/16/1~

マージウィンドウが閉じ、3.16-rc1がリリースされました。

# まとめ

Linuxとそのサブシステムの間で、開発サイクルがどのように進められるかを、実体験を踏まえて説明しました。
 
なお、18ヶ月の活動で約420パッチを投稿、うち約230パッチは2014年に入ってからのものです。
