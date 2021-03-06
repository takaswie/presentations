% Linuxサウンドサブシステムのモバイルプラットフォーム向け低消費電力戦略
% 坂本 貴史
% \today

# 今回の話題
 - Linuxのサウンドサブシステムについて語ります
 - 文字ばかりです
 - 独自研究に基づいています
 - 諸事情(後述)により、今回の発表内容を英文レポートの形にまとめ、ALSAのコミュニティに公開するつもりです
 - 不明点等は気軽に質問してください

# 自己紹介
 - 坂本貴史
 - Ubuntu Japanese Teamメンバー(2010年から)
    - 主にフォーラム管理
    - たまに原稿書き
 - ALSAのアップストリームのコミッター
    - 一部のデバイスドライバー群のメンテナー
    - カーネル側のコア機能からユーザーランドのライブラリ、ツールまで手広く
 - ミラクル・リナックス株式会社所属(2014年から)
    - 組み込みソフトウェア部門で働いてる

# 今回の内容

以下のタイムテーブルを予定しています

1. モバイルプラットフォームの要件 (10分)
2. サウンドデバイス (5分)
3. Linuxのサウンドサブシステム (10分)
4. アプリケーション (5分)
5. プログラミングモデルの流行り廃り (10分)

# モバイルプラットフォームの要件
## とにかく消費電力を下げる
    - 二次電池の放電時間を可能な限り長くしたい
    - 発熱を下げたい
## 消費電力を下げるには
 - CPUをなるべく使わないよう、タスクを処理する

# CPU使用ケース
 - プロセスによる計算
 - カーネルによる計算
 - ハードウェア割り込み
 - ソフトウェア割り込み
 - メモリーアドレス間コピー

# 処理
## プロセスでの処理
 - 普段皆さんが実行しているあれやこれやの処理

## カーネルでの処理
 - ユーザーランドに対し、ハードウェアを抽象して見せるあれやこれやの処理
    - メモリー管理
    - スケジューラー
    - デバイスドライバー
    - タイマーサービス

# 割り込みサービスルーチン
## ハードウェア割り込みサービスルーチン
 - ハードウェアが状態を変更した時に呼ばれるコード
 - プロセスやカーネルにとっては、突然起こる事象
 - デバイスドライバ開発の文脈では、top halfとか呼ばれる

## ソフトウェア割り込みサービスルーチン
 - 大抵はハードウェア割り込みサービスルーチンからスケジュールされる処理
 - デバイスドライバ開発の文脈では、bottom halfとか呼ばれる

# メモリーアドレス間コピー
 - メモリーアクセスはCPU時間を使う

# CPUをなるべく使わない
 - 動作周波数を減らす
 - プログラムの特性に従い、別々なプロセッサにスケジュールする
    - Big.LITTLE戦略
 - ハードウェア割り込みを減らす
    - Dynamic Tick
 - Direct Memory Access(DMA)
    - メモリーアドレス間コピー処理をDMAコントローラーにオフロード
    - 大量のデータを処理する際に有効


# サウンドデバイス

## 音声を扱うためのデバイス
 - 通話
 - 音楽プレイヤー
 - 携帯レコーダー

## サウンドデバイスの作り
 - アナログ回路
 - コーデック
 - シリアルデータバス
 - コントローラー
 - ペリフェラルバス

# Intel High Definition Audio(HDA)の場合
 - アナログ回路
 - HDAコーデック
 - HDAシリアルバス
 - HDAコントローラー
    - PCH集積
    - SoC集積
 - PCI-Expressバス

# HDAじゃない場合(一例)
 - アナログ回路
 - Inter IC Sound(I2S)コーデック
 - I2Sシリアルバス
 - I2Sコントローラー
    - SoC集積
 - 何かのデータバス

# サウンドデバイスを使う方法
 - ペリフェラルバス越しにコントローラーを操作する
 - ペリフェラルバス越しにデータを送受信する
    - 秒間44.1kのPCMサンプルフレームとか
    - 44100 * 2 * 2 byte = 176400 bytes / sec

# データの送受信
 - Direct Media Accessを利用すると、CPUを使わずにペリフェラルにデータを送れる
 - 典型的な制御例
    - DMAコントローラーに処理を依頼
    - DMAコントローラーは処理を終えるとハードウェア割り込みを上げる
    - ハードウェア割り込みハンドラーから先で、再度処理を依頼
    - 大抵はソフトウェア割り込みハンドラー内

# サウンドデバイスドライバーの役割
 - ペリフェラルバスドライバーを使い、コントローラーを操作する
 - DMAドライバーフレームワークを使い、データを送受信する
 - それらを、ユーザースペースの要求に応じて行う


# Linuxのサウンドサブシステム

Advanced Linux Sound Architecture (ALSA)

 - ハードウェアベンダからソフトウェアハウスまで、色々な人が開発に参加
    - Cirrus Logic, Realtek 
    - TI, Marvel, NXP, Renesas
    - Intel, DELL
    - RedHat, SUSE, Google
    - 市井の普通のひと
 - オープンソースソフトウェア
    - カーネルランドとユーザーランドの実装を持つ

# サウンドデバイスドライバーフレームワーク
 - open/close
    - データ構造を持つメモリを割り当てる、開放する
 - hw\_param/hw\_free
    - ハードウェアのセットアップを行う、止める
 - prepare
    - データ送受信の準備を行う
 - trigger
    - データ送受信を始める、止める

# データ送受信処理
 - DMAするためのメモリーページを確保
 - 2つのコンテキストから扱う
 - アプリケーションのコンテキスト
    - プロセスの仮想メモリ空間にマップしとく
    - そのページを読み書きする
    - 読み書きしたらそのフレーム数をioctl(2)でドライバーに通知
 - 割り込みコンテキスト
    - ハードウェア割り込みをハンドル
    - 次の転送指示を出す
 - データ転送量とアプリケーション読み書きタイミングの同期が必要

# タイミング同期方法
 - DMA用メモリーページ内のPCMフレーム数を、「PCMバッファ」というアイディアで管理
 - PCMバッファ
    - バッファを複数の断片に分割（period）
    - 1回のDMA転送で、1 period相当のPCMフレームを送る
    - 転送を終えたフレーム位置(hw\_ptr)と、アプリケーションが処理をしたフレーム位置(sw\_ptr)とで管理
       - この2つの位置が期待通りでない場合、XRUNという状態になったと判断し、転送を強制終了


# アプリケーション

## サウンドサーバー
 - アプリケーションの音声出力を集約し、サウンドデバイスに送る
 - サウンドデバイスからの音声を、各アプリケーションに配送する
 - アプリケーションとのデータのやり取りは、共有メモリやプロセス間通信を使用

# サウンドサーバーの一例

## 普通のLinuxデスクトップ環境
 - PulseAudio
    - I/Oライブラリはalsa-lib
 - Jack Audio Connection Kitのjackサーバ
    - 設計が古い（後述）

## Chrome OS
 - Chromium OS Audio Server (CRAS)
 - I/Oライブラリはalsa-lib

## Android
 - 忘れた
 - I/Oライブラリはtinyalsa

# プログラミングモデルの流行り廃り

## 旧来のモデル
 - 2005年あたりまで
 - 1 period相当のPCMフレーム転送終了を待つようなモデル
    - Open Sound System由来のモデル
 - レイテンシー対策
    - 秒間のハードウェア割り込み回数を増やす
    - CPU時間の無駄遣い

# 最近のモデル
 - 2006年あたりから
 - 省電力の達成
    - ハードウェア割り込み数は増やさない
 - レイテンシー対策
    - ハードウェアによってはドライバが、転送済みフレーム数をほぼリアルタイムに返すことができる
    - PCMバッファのrewindを使い、sw\_ptrをperiod内でhw\_ptrギリギリまで巻き戻すことで達成
 - Time scheduling
    - period無視
    - hw\_ptr/sw\_ptr管理によるプロセスのブロックを行わない
    - プロセス側の都合がよいタイミングで読み書きを行う

# Rewindの制約
 - アプリケーションプロセスとハードウェア割り込みの実行は非同期
 - rewindした直後のハードウェア割り込み発生により、hw\_ptrが動いてXRUNを起こす可能性
 - すぐにXRUN起こさない程度にrewindするような機構が必要
    - DMAの1回の転送単位を把握しておく必要あり

# DMAの転送単位
 - DMAコントローラーや転送指示を出すドライバーによってまちまち
 - 単位となる値は、DMAEngine Slave APIが整理して提供
    - drivers/dma以下を参照
 - この情報を共有するためのALSAのkernel/userspaceインターフェイスが不足している?

# Rewind safeguard
 - PulseAudioのALSAモジュールが内部的に持つ値
 - rewindの補正値を、当てずっぽうで指定

# このモデルへの対応
 - 対応しているドライバがそんなに多くない
    - TI社のOMAP seriesのサウンドインターフェイス用ドライバ
    - TI社のAMxxxx seriesのサウンドインターフェイス用ドライバ
    - Marvel社のPXA seriesのサウンドインターフェイス用ドライバ
    - Marvel社のKirkwood seriesのサウンドインターフェイス用ドライバ
    - Intel社のHDA用ドライバ
    - C-Media社のCMI878x (Oxygen HD Audio)用ドライバ

# このモデルの難点
 - デバイスドライバの改良が必要
 - パケット志向なドライバに対しては手法が一般化されていない
    - USB Audio Device Classドライバ (USB)
    - IEC 61883-1/6ドライバ(IEEE 1394バス、TSN)
        - 私の悩みどころ

