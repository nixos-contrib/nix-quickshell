.pragma library

// How well a text answers the query, 0 for not at all: the start of the text, the start of a word, a part of a word, and, only
// when fuzzy is asked, the letters of the query in order, as the initials of a name ("ffx" for Firefox). The longer texts, the
// comments, are only matched as they are, or everything would match
function score(query, text, fuzzy) {
    if (!text)
        return 0;
    const t = text.toLowerCase();
    const i = t.indexOf(query);
    if (i === 0)
        return 3;
    if (i > 0) {
        const before = t[i - 1];
        return (before === " " || before === "-" || before === "_" || before === ".") ? 2 : 1;
    }
    if (!fuzzy)
        return 0;
    let at = 0;
    for (const c of query) {
        at = t.indexOf(c, at);
        if (at < 0)
            return 0;
        at++;
    }
    return 0.3;
}
