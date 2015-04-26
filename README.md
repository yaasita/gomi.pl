# これは何

次のゴミ当番をメールで通知してくれるスクリプト

# 特徴

- toban.txtを編集するだけの簡単設定
- perlとsendmailコマンドがあれば大抵動く(多分)
- ゴミ当番は回数が同じならランダムに決まる(飽きさせない工夫)
- 名前の通り、ゴミコード

# 使い方

1. toban.txtを編集して、名前と回数入れる
1. gomi.plの`$send_address`を編集して送りたいメールアドレスにする
1. cronか何かで月曜日に動かす

# Docker

    docker run -d -p 22 yaasita/docker-gomi.pl /usr/bin/supervisord

https://registry.hub.docker.com/u/yaasita/docker-gomi.pl/
