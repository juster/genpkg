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
    tcmd = ""
    if (templcount > 0) {
        tcmd = templates[1]
        for (i=2; i<=templcount; i++) tcmd = tcmd "|" templates[i]
    }
    else tcmd = "cat"
        
    for (key in pbvars) {
        split(key, keys, SUBSEP)

        if (keys[2] != "len") continue
        name = keys[1]
        len  = pbvars[key]

        print name | tcmd
        for (i=1; i<=len; i++) print pbvars[name,i] | tcmd
        print "" | tcmd
    }

    if (optdepcount > 0) {
        print "optdepends" | tcmd
        for (name in optdeps) print optdeps[name] | tcmd
        print "" | tcmd
    }

    if (!seenpkgr) print "packager\n" packager "\n\n" | tcmd
}

function parsepbj (  cmd)
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

            remdep("depends", name)
            remdep("makedepends", name)
            remdep("checkdepends", name)
        }
        else {
            # We print the default packager if none was seen.
            if ($2 == "packager") seenpkgr = 1

            val = joinfields(3)
            pbvars[$2, ++pbvars[$2,"len"]] = val
        }
    }
    else if ($1 == "-") {
        if ($2 == "optdepends")
            die("cannot delete an optdep once it is created.")
        if (! remdep($2, $3)) {
            die("could not find " prefix " in " name)
        }
    }
    else if ($1 == "!") {
        cmd = joinfields(2)
        while ((ret = cmd | getline) > 0) parsepbj()
        if (ret == -1) die("failed to run $cmd")
        close(cmd)
    }
    else if ($1 == "|") {
        tcmd = joinfields(2)
        templates[++templcount] = tcmd
    }
    else if ($1 == "") ; # ignore blank lines
    else {
        print "ignoring line " FNR ": " $0 | "cat 1>&2"
    }
}

function die (msg)
{
    printf "%s:%s.%d:%s\n", PROG, FILENAME, FNR, msg | "cat 1>&2"
    exit 1
}

function joinfields (start, msg)
{
    msg = $(start++)
    while (start <= NF) msg = msg " " $(start++)
    return msg
}

function remdep (name, prefix)
{
    len = pbvars[name, "len"]
    if (len == 0) return 0

    for (i=1; i<=len; i++)
        if (pbvars[name, i] ~ "^" prefix) break

    if (i > len) return 0

    while (i < len) { pbvars[name, i] = pbvars[name, i+1]; i++ }
    delete pbvars[name, i]
    pbvars[name, "len"]--

    return 1
}

function optdepname (msgbeg)
{
    if (! match(msgbeg, "^[a-z_-]+:$"))
        die("bad optdepends name: " msgbeg)
    return substr(msgbeg, 1, RLENGTH-1)
}
