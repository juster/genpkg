# pbjparse.awk
##
# Parse a .pbj data file and print a PKGMETA data file to stdout.
# Justin Davis <jrcd83@gmail.com>

BEGIN { PROG = "pbjparse" }

{ sub(/#.*/, "") }

$1 == "+" { pushval($2, joinfields(3)); next }

$1 == "-" { remval($2, $3); next }

$1 == "<" {
    i = findval($2, $3)
    stack[++stacklen] = pbvars[$2, i]
    remelem($2, i)
    next
}

$1 == ">" {
    if (stacklen < 1)
        die("No values on the stack. Make sure you use '<' first.")
    pushval($2, stack[stacklen--])
    next
}

$1 == "=" {
    if ($2 == "optdepends") die("cannot use '=' with optdepends.")
    remall($2)
    for (i=3; i<=NF; i++) pushval($2, $i)
    next
}

$1 == "!" {
    cmd = joinfields(2)
    while ((ret = cmd | getline) > 0) parsepbj()
    if (ret == -1) die("failed to run " cmd)
    close(cmd)
    next
}

$1 == "|" { pbpipes[++pipecount] = joinfields(2); next }

# ignore lines of whitespace
$1 !~ /^[ \t]*$/ { die("invalid input: " $0) }

END {
    OFS = "\n"
    writemakepb()

    for (name in pbcount) {
        len = pbcount[name]
        if (len == 0) continue

        print name
        for (i=1; i<=len; i++) print pbvars[name, i]
        print ""
    }

    if (!seenpkgr) {
        pkger = ENVIRON["PACKAGER"]
        if (pkger == "") pkger = "Anonymous"
        print "packager\n" pkger
    }
}

function die (msg)
{
    printf "%s: error line %d: %s\n", PROG, FNR, msg | "cat 1>&2"
    exit 1
}

function joinfields (start, msg)
{
    msg = $(start++)
    while (start <= NF) msg = msg " " $(start++)
    return msg
}

function remall (field)
{
    pbcount[field] = 0
}

function pushval (field, val)
{
    if (field == "packager") seenpkgr = 1
    pbvars[field, ++pbcount[field]] = val
}

function remval (field, prefix)
{
    remelem(field, findval(field, prefix))
}

function remelem (field, i,  len)
{
    # TODO: error check if "i" is in bounds?
    len = pbcount[field]
    for (len = pbcount[field]; i < len; i++)
        pbvars[field, i] = pbvars[field, i+1]
    delete pbvars[field, i]
    pbcount[field]--
}

function findval (field, prefix,  i, len)
{
    len = pbcount[field]
    if (len == 0) die(field " is empty!")

    for (i=1; i<=len; i++) if (pbvars[field, i] ~ "^" prefix) break
    if (i > len) die("could not find " prefix " in " field "'s values")
    return i
}

function writemakepb ()
{
    tcmd = pbpipes[1]
    for (i = 2; i <= pipecount; i++) tcmd = tcmd " | \\\n    " pbpipes[i]
    print "#!/bin/sh" > "makepb"
    print "PATH=" ENVIRON["PATH"] > "makepb"
    print "cat PKGMETA | " tcmd > "makepb"
    close("makepb")
    system("chmod +x makepb")
}
