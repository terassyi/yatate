function zssh
    if test (count $argv) -ne 1
        echo "Usage: zssh <host>/<org>/<repo>"
        return 1
    end
    set -l host (string replace -r '/.*' '' $argv[1])
    set -l path (string replace -r '^[^/]*/' '' $argv[1])
    zed "ssh://$host/~/workspace/github.com/$path"
end
