% ALSAの過去と現在そして開発メンバーについて
% Takashi SAKAMOTO (坂本 貴史)
% \today

# 自己紹介

 * 2013年からALSAプロジェクトにパッチ送ってる
 * ALSAプロジェクトでは「IEC 61883-1/6エンジン」と、それを採用したデバイス群の
   ドライバーにコミット
    * IEEE 1394バス接続
    * 10ドライバーを書いて、メインラインにマージ(2013年〜現在)
 * ALSAプロジェクトのコア機能にもコミット

# ALSA

 * Advanced Linux Sound Architecture
 * Linuxのサブシステムのひとつとして、Linux sound subsystemnとも呼ばれる

# ALSAの主要機能

 * 仮想機械の構成要素として、デバイスとの間で音声のサンプリングデータを
   転送するための共通インターフェイスを、プロセスに提供する
 * オペレーティングシステムの構成要素として、音声のサンプリングデータを
   扱うデバイスに関し、システム資源を管理する

# 開発体制

 * 1998年頃、開発が始まったっぽい
 * 2003年頃にmainline入り
    * それまではout-of-treeで開発
 * コミュニティーベース
    * ハードウェアベンダーに所属する開発者が大半
    * プライベートで開発に関与する人は極少数
 * 特徴
    * 特定ベンダーに偏ることなく、ベンダー中立の度合いを高く維持

# サブシステムメンテナー

 * 〜2008: Jaroslav Kysela (Red Hat)
 * 〜2019: Takashi Iwai (SUSE)

# ユーザースペース向けインターフェイス

 * ALSAがシステムに追加するキャラクターデバイスに対するioctl(2)実行
 * 主要なものは、PCMキャラクターデバイス
    * /dev/snd/pcmC0D0p
 * 他にも6つほどインターフェイスを提供
 * それぞれのインターフェイスを使い、デバイスを表現する状態機械を制御
 * ここがALSAの中心部分
    * カーネル内の「sound/core」

# サポートされているデバイス

 * 汎用ペリフェラルバス上にあり、音声向けシリアルバスを扱う
   インターフェイスデバイス
    * Inter-IC Sound(I2S)インターフェイス
    * Time Division Multiplexing(TDM)インターフェイス
    * High Definition Audio (HDA)インターフェイス
 * 汎用ペリフェラルバス上にあり、音声サンプリングデータを送受信するデバイス
    * HDMIやDisplayPortの音声機能
    * USB Audio Deviceを実装したインターフェイス
    * IEEE 1394バス上にあるAudio and Musicユニット
 * 大抵の場合、ペリフェラルバス上のデータ転送にDirect Media Access(DMA)を使用

# 組み込みプラットフォーム向け機能(ASoC)

 * ALSAの内部にある、ある種独立したコード群
 * 音声向けシリアルバスの先にある、各種ICのドライバーを提供
    * AD/DA変換コーデック
    * Digital Signal Processor
 * 音声ICとインターフェイスの接続を含め、統一して操作可能とする
 * 2006年あたりから開発スタート
 * Mark Brown (linaro)がメンテナー

# 参加している開発者

 * CPUベンダーやSoCベンダー所属
    * Intel社、Renesas社、AMD社、NVIDIA社、Texus Instruments社、NXP社、Samsung社
 * ICベンダー所属
    * Cirrus Logic社、STマイクロ社、Realtek社
 * ハードウェアベンダー所属
    * Google社、Xiaomi社、Infradead
 * 組み込み向けディストリビューションベンダー所属
    * Linaro社、Bootlin社、Mentor社、Windriver社、Collabora社
 * ディストリビューションベンダー所属
    * Red Hat社、SUSE社、Canonical社
 * 個人

# 常時活動してるのはほんの数名

 * メンテナー
 * ベンダー所属の開発者
    * Cirrus Logic社、Intel社
 * わたしと師匠

# 主なカバー領域

 * サブシステムメンテナー
    * 共通フレームワーク
    * Intel HDAコントローラードライバー
 * ベンダー所属の開発者
    * 自社製品が関係するところ
 * ユーザースペースとのインターフェイスとユーザースペース実装
    * Jaroslav Kysela
    * わたし

# サポートを得るには

 * コミュニティ運営はメーリングリストが中心
    * alsa-devel@alsa-project.org
 * 最近、github.comにalsa-projectチームを作成
    * ユーザーランドの実装に関するマージリクエスト受け付け
    * ユーザーランドの実装に関するバグのトラッキングに利用
