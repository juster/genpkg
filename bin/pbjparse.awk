# pbjparse.awk
##
# Parse a PBJ data file and print a PBDATA datafile to STDOUT.
# Justin Davis <jrcd83@gmail.com>

BEGIN {
    templcount = 0 # number of templates that will be in the templates array
    PROG = "pbjparse"
}

{ parsepbj() }

END {
    if (templcount > 0) {
        tcmd = templates[1]
        for (i=2; i<=templcount; i++) tcmd = tcmd "|" templates[i]
    }
    else tcmd = "cat"

    for (name in pbcount) {
        len = pbcount[name]
        if (len == 0) continue

        print name | tcmd
        for (i=1; i<=len; i++) print pbvars[name, i] | tcmd
        print "" | tcmd
    }

    if (optdepcount > 0) {
        print "optdepends" | tcmd
        for (name in optdeps) print optdeps[name] | tcmd
        print "" | tcmd
    }

    if (!seenpkgr) {
        pkger = ENVIRON["PACKAGER"]
        if (pkger == "") pkger = "Anonymous"
        print "packager\n" pkger | tcmd
    }
}

function parsepbj (  cmd) # cmd is a "local" var
{
    # Ignore comments.
    sub(/#.*/, "")

    # Optdeps are special. In an annoying way.
    if ($1 == "+") {
        if ($2 == "optdepends") {
            msg = joinfields(3)

            ++optdepcount
            name = optdepname($3)
            optdeps[name] = msg
        }
        else {
            # We print the default packager if none was seen.
            pushval($2, joinfields(3))
        }
    }
    else if ($1 == "-") {
        if ($2 == "optdepends")
            die("cannot delete an optdep once it is created.")
        if (! remval($2, $3))
            die("could not find " $3 " in " $2 "'s values")
    }
    else if ($1 == "=") {
        if ($2 == "optdepends") die("cannot use '=' with optdepends.")
        remall($2)
        for (i=3; i<=NF; i++) pushval($2, $i)
    }
    else if ($1 == "!") {
        cmd = joinfields(2)
        while ((ret = cmd | getline) > 0) parsepbj()
        if (ret == -1) die("failed to run " cmd)
        close(cmd)
    }
    else if ($1 == "|") {
        templates[++templcount] = joinfields(2)
    }
    else if ($1 ~ /^[ \t]*$/) ; # ignore lines of whitespace
    else die("invalid input: " $0)
}

function die (msg)
{
    printf "%s: error: %s:%d %s\n", PROG, FILENAME, FNR, msg | "cat 1>&2"
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

function remval (field, prefix,  i, len)
{
    len = pbcount[field]
    if (len == 0) return 0

    for (i=1; i<=len; i++)
        if (pbvars[field, i] ~ "^" prefix) break

    if (i > len) return 0

    for ( ; i < len; i++) pbvars[field, i] = pbvars[field, i+1]
    delete pbvars[field, i]
    pbcount[field]--

    return 1
}

function optdepname (msgbeg)
{
    if (! match(msgbeg, "^[a-z_-]+:$"))
        die("bad optdepends name: " msgbeg)
    return substr(msgbeg, 1, RLENGTH-1)
}
