package tomei

// darwin-tools: docker と gcloud は tomei のバグで現在インストール不可
// - docker: tgz アーカイブ形式が未サポート (known-issues.md)
// - gcloud: アーカイブ内の相対シンボリンク展開失敗 (known-issues.md)
// tomei 修正後に戻す
